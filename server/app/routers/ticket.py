"""
Ticket API router.

Matches PHP TicketController endpoints.
"""
from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.dialects.mysql import insert as mysql_insert
import uuid

from app.dependencies import CurrentAirline, DbSession
from app.database.tables import tickets, flights, passengers
from app.schemas.ticket import TicketCreate, TicketResponse, TicketVerify
from app.models.ticket import Ticket
from app.models.flight import Flight
from app.models.passenger import Passenger
from app.core.exceptions import NotFoundError
from app.services.signature_service import SignatureService

router = APIRouter()


def ticket_identifier_from_data() -> str:
    """
    Generate ticket identifier.
    
    PHP uses UUIDs (36 characters) for identifiers.
    The database column has DEFAULT (uuid()), but we generate it explicitly
    to ensure consistency and allow lookups.
    """
    # Use UUID4 for unique identifiers (matches PHP's uuid() default)
    return str(uuid.uuid4())


@router.post("/issue/{flight_identifier}/{passenger_identifier}", response_model=TicketResponse, status_code=status.HTTP_200_OK)
async def issue_ticket(
    flight_identifier: str,
    passenger_identifier: str,
    ticket_data: TicketCreate,
    airline: CurrentAirline,
    db: DbSession,
):
    """
    Issue a ticket for a passenger on a flight.
    
    Matches PHP: POST /v1/airline/{airline_identifier}/ticket/issue/{flight_identifier}/{passenger_identifier}
    
    Note: Only one ticket per passenger per flight is allowed.
    """
    from app.database.repository import FlightRepository, PassengerRepository
    
    # Get flight and passenger
    flight_repo = FlightRepository(flights, Flight)
    passenger_repo = PassengerRepository(passengers, Passenger)
    
    flight = await flight_repo.get_by_identifier(flight_identifier, airline.airline_id, db)
    passenger = await passenger_repo.get_by_identifier(passenger_identifier, airline.airline_id, db)
    
    if not flight:
        raise NotFoundError("Flight", flight_identifier)
    if not passenger:
        raise NotFoundError("Passenger", passenger_identifier)
    
    # Check for existing ticket (only one ticket per passenger per flight)
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
        tickets.c.passenger_id == passenger.passenger_id,
        tickets.c.airline_id == airline.airline_id,
    )
    result = await db.execute(query)
    existing_row = result.fetchone()
    
    ticket_identifier = None
    ticket_id = None
    
    if existing_row:
        # Use existing ticket
        existing_dict = dict(existing_row._mapping)
        ticket_identifier = existing_dict.get("ticket_identifier")
        ticket_id = existing_dict.get("ticket_id")
    else:
        # Generate new ticket identifier
        ticket_identifier = ticket_identifier_from_data()
    
    # Build JSON data - include flight and passenger in the JSON
    json_data = {
        "passenger": passenger.to_json(),
        "flight": flight.to_json(),
        "seatNumber": ticket_data.seat_number,
        "customLabelValue": ticket_data.custom_label_value or "1",
    }
    
    # Prepare insert/update data
    insert_data = {
        "airline_id": airline.airline_id,
        "flight_id": flight.flight_id,
        "passenger_id": passenger.passenger_id,
        "json_data": json_data,
    }
    
    if ticket_identifier:
        insert_data["ticket_identifier"] = ticket_identifier
    if ticket_id:
        insert_data["ticket_id"] = ticket_id
    
    stmt = mysql_insert(tickets).values(**insert_data)
    stmt = stmt.on_duplicate_key_update(json_data=json_data)
    await db.execute(stmt)
    await db.commit()
    
    # Fetch the created/updated ticket
    query = select(
        tickets.c.ticket_id,
        tickets.c.ticket_identifier,
        tickets.c.passenger_id,
        tickets.c.flight_id,
        tickets.c.json_data,
        tickets.c.airline_id,
        tickets.c.modified,
    ).where(
        tickets.c.ticket_identifier == ticket_identifier,
        tickets.c.airline_id == airline.airline_id,
    )
    result = await db.execute(query)
    row = result.fetchone()
    
    if not row:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to create ticket",
        )
    
    ticket_dict = dict(row._mapping)
    ticket_json = ticket_dict.get("json_data", {})
    ticket_json["ticket_id"] = ticket_dict["ticket_id"]
    ticket_json["ticket_identifier"] = ticket_dict["ticket_identifier"]
    ticket_json["flight_id"] = ticket_dict["flight_id"]
    ticket_json["passenger_id"] = ticket_dict["passenger_id"]
    ticket = Ticket.model_validate(ticket_json)
    return ticket.to_json()


@router.get("/list")
async def list_tickets(
    airline: CurrentAirline,
    db: DbSession,
):
    """
    List all tickets for the airline.
    
    Matches PHP: GET /v1/airline/{airline_identifier}/ticket/list
    """
    from app.database.repository import TicketRepository
    
    repo = TicketRepository(tickets, Ticket)
    ticket_list = await repo.list_all(airline.airline_id, db)
    
    return [ticket.to_json() for ticket in ticket_list]


@router.get("/{ticket_identifier}", response_model=TicketResponse)
async def get_ticket(
    ticket_identifier: str,
    airline: CurrentAirline,
    db: DbSession,
):
    """
    Get ticket by identifier.
    
    Matches PHP: GET /v1/airline/{airline_identifier}/ticket/{ticket_identifier}
    """
    from app.database.repository import TicketRepository
    
    repo = TicketRepository(tickets, Ticket)
    ticket = await repo.get_by_identifier(ticket_identifier, airline.airline_id, db)
    
    if not ticket:
        raise NotFoundError("Ticket", ticket_identifier)
    
    return ticket.to_json()


@router.delete("/{ticket_identifier}", status_code=status.HTTP_200_OK)
async def delete_ticket(
    ticket_identifier: str,
    airline: CurrentAirline,
    db: DbSession,
):
    """
    Delete a ticket by identifier.
    
    Matches PHP: DELETE /v1/airline/{airline_identifier}/ticket/{ticket_identifier}
    """
    from app.database.repository import TicketRepository
    
    repo = TicketRepository(tickets, Ticket)
    success = await repo.delete_by_identifier(ticket_identifier, airline.airline_id, db)
    
    if not success:
        raise NotFoundError("Ticket", ticket_identifier)
    
    return {"status": 1, "ticket_identifier": ticket_identifier}


@router.post("/verify", response_model=TicketResponse, status_code=status.HTTP_200_OK)
async def verify_ticket(
    verify_data: TicketVerify,
    airline: CurrentAirline,
    db: DbSession,
):
    """
    Verify a ticket using signature digest.
    
    Matches PHP: POST /v1/airline/{airline_identifier}/ticket/verify
    """
    from app.database.repository import TicketRepository
    
    # Get ticket by identifier
    ticket_identifier = verify_data.ticket
    repo = TicketRepository(tickets, Ticket)
    ticket = await repo.get_by_identifier(ticket_identifier, airline.airline_id, db)
    
    if not ticket:
        raise NotFoundError("Ticket", ticket_identifier)
    
    # Verify signature digest
    signature_digest = verify_data.signature_digest or verify_data.signature
    if not signature_digest:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Missing signature digest",
        )
    
    # Get signature service for the airline
    from app.dependencies import get_airline_context
    airline_data = airline.airline_data
    apple_identifier = airline_data.get("apple_identifier", "")
    
    signature_service = SignatureService(apple_identifier)
    is_valid = signature_service.verify_signature_digest(ticket_identifier, signature_digest)
    
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Ticket not valid",
        )
    
    return ticket.to_json()

