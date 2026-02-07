"""
Aircraft API router.

Matches PHP AircraftController endpoints.
"""
from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.dialects.mysql import insert as mysql_insert
import uuid

from datetime import datetime

from app.dependencies import CurrentAirline, DbSession
from app.database.tables import aircrafts, flights
from app.schemas.aircraft import AircraftCreate, AircraftResponse
from app.models.aircraft import Aircraft
from app.core.exceptions import NotFoundError

router = APIRouter()


def _format_iso8601(dt: datetime | None) -> str | None:
    """Format datetime as ISO 8601 with timezone (matches PHP DateTime->format('c'))."""
    if dt is None:
        return None
    return dt.isoformat() + "+00:00" if dt.tzinfo is None else dt.isoformat()


def aircraft_identifier_from_registration(registration: str) -> str:
    """
    Generate aircraft identifier from registration.
    
    PHP uses UUIDs (36 characters) for identifiers.
    The database column has DEFAULT (uuid()), but we generate it explicitly
    to ensure consistency and allow lookups.
    """
    # Use UUID4 for unique identifiers (matches PHP's uuid() default)
    return str(uuid.uuid4())


@router.post("/create", response_model=AircraftResponse, status_code=status.HTTP_200_OK)
async def create_aircraft(
    aircraft_data: AircraftCreate,
    airline: CurrentAirline,
    db: DbSession,
):
    """
    Create or update an aircraft.
    
    Matches PHP: POST /v1/airline/{airline_identifier}/aircraft/create
    """
    aircraft_identifier = aircraft_identifier_from_registration(aircraft_data.registration)
    
    json_data = {
        "registration": aircraft_data.registration,
        "type": aircraft_data.type,
    }
    
    stmt = mysql_insert(aircrafts).values(
        airline_id=airline.airline_id,
        aircraft_identifier=aircraft_identifier,
        json_data=json_data,
    )
    stmt = stmt.on_duplicate_key_update(
        json_data=json_data,
    )
    await db.execute(stmt)
    await db.commit()
    
    # Fetch the created/updated aircraft
    query = select(
        aircrafts.c.aircraft_id,
        aircrafts.c.aircraft_identifier,
        aircrafts.c.json_data,
        aircrafts.c.airline_id,
        aircrafts.c.modified,
    ).where(
        aircrafts.c.aircraft_identifier == aircraft_identifier,
        aircrafts.c.airline_id == airline.airline_id,
    )
    result = await db.execute(query)
    row = result.fetchone()
    
    if not row:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to create aircraft",
        )
    
    aircraft_dict = dict(row._mapping)
    aircraft_json = aircraft_dict.get("json_data", {})
    aircraft_json["aircraft_id"] = aircraft_dict["aircraft_id"]
    aircraft_json["aircraft_identifier"] = aircraft_dict["aircraft_identifier"]
    aircraft = Aircraft.model_validate(aircraft_json)
    return aircraft.to_json()


@router.get("/list")
async def list_aircrafts(
    airline: CurrentAirline,
    db: DbSession,
):
    """
    List all aircrafts with stats.
    
    Matches PHP: GET /v1/airline/{airline_identifier}/aircraft/list
    """
    from app.database.repository import AircraftRepository
    
    repo = AircraftRepository(aircrafts, Aircraft)
    results = await repo.list_with_stats(airline.airline_id, db, [flights])
    
    # Convert to model and return JSON
    aircraft_list = []
    for row_dict in results:
        # Extract json_data and merge with identifiers
        json_data = row_dict.get("json_data", {})
        json_data["aircraft_id"] = row_dict.get("aircraft_id")
        json_data["aircraft_identifier"] = row_dict.get("aircraft_identifier")
        # Add stats
        stats = []
        if "flights_count" in row_dict:
            stats.append({
                "table": "Flights",
                "count": row_dict.get("flights_count", 0),
                "last": _format_iso8601(row_dict.get("flights_last")),
            })
        json_data["stats"] = stats
        aircraft = Aircraft.model_validate(json_data)
        aircraft_list.append(aircraft.to_json())
    
    return aircraft_list


@router.get("/{aircraft_identifier}", response_model=AircraftResponse)
async def get_aircraft(
    aircraft_identifier: str,
    airline: CurrentAirline,
    db: DbSession,
):
    """
    Get aircraft by identifier.
    
    Matches PHP: GET /v1/airline/{airline_identifier}/aircraft/{aircraft_identifier}
    """
    from app.database.repository import AircraftRepository
    
    repo = AircraftRepository(aircrafts, Aircraft)
    aircraft = await repo.get_by_identifier(aircraft_identifier, airline.airline_id, db)
    
    if not aircraft:
        raise NotFoundError("Aircraft", aircraft_identifier)
    
    return aircraft.to_json()


@router.get("/{aircraft_identifier}/flights")
async def list_aircraft_flights(
    aircraft_identifier: str,
    airline: CurrentAirline,
    db: DbSession,
):
    """
    List flights for an aircraft.
    
    Matches PHP: GET /v1/airline/{airline_identifier}/aircraft/{aircraft_identifier}/flights
    """
    from app.database.repository import AircraftRepository, FlightRepository
    from app.models.flight import Flight
    
    # Get aircraft to get aircraft_id
    aircraft_repo = AircraftRepository(aircrafts, Aircraft)
    aircraft = await aircraft_repo.get_by_identifier(aircraft_identifier, airline.airline_id, db)
    
    if not aircraft:
        raise NotFoundError("Aircraft", aircraft_identifier)
    
    # List flights for this aircraft
    query = select(flights).where(
        flights.c.aircraft_id == aircraft.aircraft_id,
        flights.c.airline_id == airline.airline_id,
    )
    result = await db.execute(query)
    rows = result.fetchall()
    
    flight_repo = FlightRepository(flights, Flight)
    flights_list = [flight_repo._row_to_model(row) for row in rows]
    
    return [flight.to_json() for flight in flights_list]

