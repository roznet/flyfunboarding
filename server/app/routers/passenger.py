"""
Passenger API router.

Matches PHP PassengerController endpoints.
"""
from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.dialects.mysql import insert as mysql_insert
import uuid

from app.dependencies import CurrentAirline, DbSession
from app.database.tables import passengers, tickets
from app.schemas.passenger import PassengerCreate, PassengerResponse
from app.models.passenger import Passenger
from app.core.exceptions import NotFoundError

router = APIRouter()


def passenger_identifier_from_apple_identifier(apple_identifier: str) -> str:
    """
    Generate passenger identifier from Apple identifier.
    
    PHP uses UUIDs (36 characters) for identifiers.
    The database column has DEFAULT (uuid()), but we generate it explicitly
    to ensure consistency and allow lookups.
    """
    # Use UUID4 for unique identifiers (matches PHP's uuid() default)
    return str(uuid.uuid4())


@router.post("/create", response_model=PassengerResponse, status_code=status.HTTP_200_OK)
async def create_passenger(
    passenger_data: PassengerCreate,
    airline: CurrentAirline,
    db: DbSession,
):
    """
    Create or update a passenger.
    
    Matches PHP: POST /v1/airline/{airline_identifier}/passenger/create
    """
    passenger_identifier = passenger_identifier_from_apple_identifier(passenger_data.apple_identifier)
    
    json_data = {
        "formattedName": passenger_data.formatted_name,
        "firstName": passenger_data.first_name,
        "middleName": passenger_data.middle_name,
        "lastName": passenger_data.last_name,
        "apple_identifier": passenger_data.apple_identifier,
    }
    
    stmt = mysql_insert(passengers).values(
        airline_id=airline.airline_id,
        passenger_identifier=passenger_identifier,
        json_data=json_data,
    )
    stmt = stmt.on_duplicate_key_update(json_data=json_data)
    await db.execute(stmt)
    await db.commit()
    
    # Fetch the created/updated passenger
    query = select(
        passengers.c.passenger_id,
        passengers.c.passenger_identifier,
        passengers.c.json_data,
        passengers.c.airline_id,
        passengers.c.modified,
    ).where(
        passengers.c.passenger_identifier == passenger_identifier,
        passengers.c.airline_id == airline.airline_id,
    )
    result = await db.execute(query)
    row = result.fetchone()
    
    if not row:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to create passenger",
        )
    
    passenger_dict = dict(row._mapping)
    passenger_json = passenger_dict.get("json_data", {})
    passenger_json["passenger_id"] = passenger_dict["passenger_id"]
    passenger_json["passenger_identifier"] = passenger_dict["passenger_identifier"]
    passenger = Passenger.model_validate(passenger_json)
    return passenger.to_json()


@router.get("/list")
async def list_passengers(
    airline: CurrentAirline,
    db: DbSession,
):
    """
    List all passengers with stats.
    
    Matches PHP: GET /v1/airline/{airline_identifier}/passenger/list
    """
    from app.database.repository import PassengerRepository
    
    repo = PassengerRepository(passengers, Passenger)
    results = await repo.list_with_stats(airline.airline_id, db, [tickets])
    
    # Convert to model and return JSON
    passenger_list = []
    for row_dict in results:
        json_data = row_dict.get("json_data", {})
        json_data["passenger_id"] = row_dict.get("passenger_id")
        json_data["passenger_identifier"] = row_dict.get("passenger_identifier")
        # Add stats
        stats = []
        if "tickets_count" in row_dict:
            stats.append({
                "table": "Tickets",
                "count": row_dict.get("tickets_count", 0),
                "last": row_dict.get("tickets_last"),
            })
        json_data["stats"] = stats
        passenger = Passenger.model_validate(json_data)
        passenger_list.append(passenger.to_json())
    
    return passenger_list


@router.get("/{passenger_identifier}", response_model=PassengerResponse)
async def get_passenger(
    passenger_identifier: str,
    airline: CurrentAirline,
    db: DbSession,
):
    """
    Get passenger by identifier.
    
    Matches PHP: GET /v1/airline/{airline_identifier}/passenger/{passenger_identifier}
    """
    from app.database.repository import PassengerRepository
    
    repo = PassengerRepository(passengers, Passenger)
    passenger = await repo.get_by_identifier(passenger_identifier, airline.airline_id, db)
    
    if not passenger:
        raise NotFoundError("Passenger", passenger_identifier)
    
    return passenger.to_json()


@router.get("/{passenger_identifier}/tickets")
async def list_passenger_tickets(
    passenger_identifier: str,
    airline: CurrentAirline,
    db: DbSession,
):
    """
    List tickets for a passenger.
    
    Matches PHP: GET /v1/airline/{airline_identifier}/passenger/{passenger_identifier}/tickets
    """
    from app.database.repository import PassengerRepository, TicketRepository
    from app.models.ticket import Ticket
    
    # Get passenger to get passenger_id
    passenger_repo = PassengerRepository(passengers, Passenger)
    passenger = await passenger_repo.get_by_identifier(passenger_identifier, airline.airline_id, db)
    
    if not passenger:
        raise NotFoundError("Passenger", passenger_identifier)
    
    # List tickets for this passenger
    query = select(tickets).where(
        tickets.c.passenger_id == passenger.passenger_id,
        tickets.c.airline_id == airline.airline_id,
    )
    result = await db.execute(query)
    rows = result.fetchall()
    
    ticket_repo = TicketRepository(tickets, Ticket)
    tickets_list = [ticket_repo._row_to_model(row) for row in rows]
    
    return [ticket.to_json() for ticket in tickets_list]

