"""
Flight API router.

Matches PHP FlightController endpoints.
"""
from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.dialects.mysql import insert as mysql_insert
import uuid

from app.dependencies import CurrentAirline, DbSession
from app.database.tables import flights, aircrafts, tickets
from app.schemas.flight import FlightCreate, FlightResponse
from app.models.flight import Flight
from app.models.aircraft import Aircraft
from app.core.exceptions import NotFoundError

router = APIRouter()


def flight_identifier_from_data(flight_data: dict) -> str:
    """
    Generate flight identifier.
    
    PHP uses UUIDs (36 characters) for identifiers.
    The database column has DEFAULT (uuid()), but we generate it explicitly
    to ensure consistency and allow lookups.
    """
    # Use UUID4 for unique identifiers (matches PHP's uuid() default)
    return str(uuid.uuid4())


@router.post("/plan/{aircraft_identifier}", response_model=FlightResponse, status_code=status.HTTP_200_OK)
async def plan_flight(
    aircraft_identifier: str,
    flight_data: FlightCreate,
    airline: CurrentAirline,
    db: DbSession,
):
    """
    Create or plan a flight for an aircraft.
    
    Matches PHP: POST /v1/airline/{airline_identifier}/flight/plan/{aircraft_identifier}
    """
    from app.database.repository import AircraftRepository
    
    # Get the aircraft
    aircraft_repo = AircraftRepository(aircrafts, Aircraft)
    # First try by identifier (Python tests / new clients)
    aircraft = await aircraft_repo.get_by_identifier(
        aircraft_identifier, airline.airline_id, db
    )

    # For backwards compatibility with PHP, also support numeric aircraft_id
    # used in the original /flight/plan/{aircraft_id} endpoint.
    if not aircraft:
        try:
            aircraft_id = int(aircraft_identifier)
        except ValueError:
            aircraft_id = None

        if aircraft_id is not None:
            aircraft = await aircraft_repo.get_by_id(
                aircraft_id, airline.airline_id, db
            )
    
    if not aircraft:
        raise NotFoundError("Aircraft", aircraft_identifier)
    
    # Generate flight identifier
    flight_identifier = flight_identifier_from_data(flight_data.model_dump())
    
    # Build JSON data - include aircraft in the JSON
    json_data = {
        "origin": flight_data.origin.model_dump(by_alias=True),
        "destination": flight_data.destination.model_dump(by_alias=True),
        "gate": flight_data.gate,
        "flightNumber": flight_data.flight_number,
        "aircraft": aircraft.to_json(),
        "scheduledDepartureDate": flight_data.scheduled_departure_date.isoformat(),
    }
    
    stmt = mysql_insert(flights).values(
        airline_id=airline.airline_id,
        aircraft_id=aircraft.aircraft_id,
        flight_identifier=flight_identifier,
        json_data=json_data,
    )
    stmt = stmt.on_duplicate_key_update(json_data=json_data)
    await db.execute(stmt)
    await db.commit()
    
    # Fetch the created/updated flight
    query = select(
        flights.c.flight_id,
        flights.c.flight_identifier,
        flights.c.aircraft_id,
        flights.c.json_data,
        flights.c.airline_id,
        flights.c.modified,
    ).where(
        flights.c.flight_identifier == flight_identifier,
        flights.c.airline_id == airline.airline_id,
    )
    result = await db.execute(query)
    row = result.fetchone()
    
    if not row:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to create flight",
        )
    
    flight_dict = dict(row._mapping)
    flight_json = flight_dict.get("json_data", {})
    flight_json["flight_id"] = flight_dict["flight_id"]
    flight_json["flight_identifier"] = flight_dict["flight_identifier"]
    flight_json["aircraft_id"] = flight_dict["aircraft_id"]
    flight = Flight.model_validate(flight_json)
    return flight.to_json()


@router.get("/list")
async def list_flights(
    airline: CurrentAirline,
    db: DbSession,
):
    """
    List all flights with stats.
    
    Matches PHP: GET /v1/airline/{airline_identifier}/flight/list
    """
    from app.database.repository import FlightRepository
    from sqlalchemy import select, func as sql_func
    
    # Custom query for flights with stats that includes aircraft_id
    table_ref = flights
    select_cols = [
        table_ref.c.flight_id,
        table_ref.c.flight_identifier,
        table_ref.c.aircraft_id,  # Include aircraft_id for flights
        table_ref.c.json_data,
        table_ref.c.airline_id,
        table_ref.c.modified,
        sql_func.count(tickets.c.ticket_id).label("tickets_count"),
        sql_func.max(tickets.c.modified).label("tickets_last"),
    ]
    
    query = select(*select_cols).select_from(table_ref)
    query = query.outerjoin(tickets, table_ref.c.flight_id == tickets.c.flight_id)
    query = query.where(table_ref.c.airline_id == airline.airline_id)
    query = query.group_by(table_ref.c.flight_id)
    
    result = await db.execute(query)
    results = [dict(row._mapping) for row in result.fetchall()]
    
    # Convert to model and return JSON
    flight_list = []
    for row_dict in results:
        json_data = row_dict.get("json_data", {})
        json_data["flight_id"] = row_dict.get("flight_id")
        json_data["flight_identifier"] = row_dict.get("flight_identifier")
        json_data["aircraft_id"] = row_dict.get("aircraft_id", -1)
        # Add stats
        stats = []
        if "tickets_count" in row_dict and row_dict.get("tickets_count", 0) > 0:
            stats.append({
                "table": "Tickets",
                "count": row_dict.get("tickets_count", 0),
                "last": row_dict.get("tickets_last"),
            })
        json_data["stats"] = stats
        flight = Flight.model_validate(json_data)
        flight_list.append(flight.to_json())
    
    return flight_list


@router.get("/{flight_identifier}", response_model=FlightResponse)
async def get_flight(
    flight_identifier: str,
    airline: CurrentAirline,
    db: DbSession,
):
    """
    Get flight by identifier.
    
    Matches PHP: GET /v1/airline/{airline_identifier}/flight/{flight_identifier}
    """
    from app.database.repository import FlightRepository
    
    repo = FlightRepository(flights, Flight)
    flight = await repo.get_by_identifier(flight_identifier, airline.airline_id, db)
    
    if not flight:
        raise NotFoundError("Flight", flight_identifier)
    
    return flight.to_json()


@router.get("/{flight_identifier}/tickets")
async def list_flight_tickets(
    flight_identifier: str,
    airline: CurrentAirline,
    db: DbSession,
):
    """
    List tickets for a flight.
    
    Matches PHP: GET /v1/airline/{airline_identifier}/flight/{flight_identifier}/tickets
    """
    from app.database.repository import FlightRepository, TicketRepository
    from app.models.ticket import Ticket
    
    # Get flight to get flight_id
    flight_repo = FlightRepository(flights, Flight)
    flight = await flight_repo.get_by_identifier(flight_identifier, airline.airline_id, db)
    
    if not flight:
        raise NotFoundError("Flight", flight_identifier)
    
    # List tickets for this flight
    query = select(
        tickets.c.ticket_id,
        tickets.c.ticket_identifier,
        tickets.c.passenger_id,
        tickets.c.flight_id,
        tickets.c.json_data,
        tickets.c.airline_id,
        tickets.c.modified,
    ).where(
        tickets.c.flight_id == flight.flight_id,
        tickets.c.airline_id == airline.airline_id,
    )
    result = await db.execute(query)
    rows = result.fetchall()
    
    ticket_repo = TicketRepository(tickets, Ticket)
    tickets_list = [ticket_repo._row_to_model(row) for row in rows]
    
    return [ticket.to_json() for ticket in tickets_list]


@router.delete("/{flight_identifier}", status_code=status.HTTP_200_OK)
async def delete_flight(
    flight_identifier: str,
    airline: CurrentAirline,
    db: DbSession,
):
    """
    Delete a flight by identifier.
    
    Matches PHP: DELETE /v1/airline/{airline_identifier}/flight/{flight_identifier}
    """
    from app.database.repository import FlightRepository
    
    repo = FlightRepository(flights, Flight)
    success = await repo.delete_by_identifier(flight_identifier, airline.airline_id, db)
    
    if not success:
        raise NotFoundError("Flight", flight_identifier)
    
    return {"status": 1, "flight_identifier": flight_identifier}


@router.post("/check/{flight_identifier}", response_model=FlightResponse, status_code=status.HTTP_200_OK)
async def check_flight(
    flight_identifier: str,
    airline: CurrentAirline,
    db: DbSession,
):
    """
    Check a flight (validate flight data).
    
    Matches PHP: POST /v1/airline/{airline_identifier}/flight/check/{flight_identifier}
    """
    from app.database.repository import FlightRepository
    
    repo = FlightRepository(flights, Flight)
    flight = await repo.get_by_identifier(flight_identifier, airline.airline_id, db)
    
    if not flight:
        raise NotFoundError("Flight", flight_identifier)
    
    # For now, just return the flight (PHP might do additional validation)
    return flight.to_json()

