"""
Boarding Pass API router.

Matches PHP BoardingPassController endpoints.
"""
from fastapi import APIRouter, HTTPException, Query, status, Response
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
import io

from app.dependencies import CurrentAirline, DbSession
from app.database.tables import tickets
from app.models.ticket import Ticket
from app.models.settings import Settings
from app.models.airline import Airline
from app.core.exceptions import NotFoundError
from app.services.boarding_pass_service import BoardingPassService
from app.database.repository import TicketRepository

router = APIRouter()
public_router = APIRouter()


async def _get_boarding_pass_data(
    ticket_identifier: str,
    airline_id: int,
    airline_identifier: str,
    airline_data: dict,
    db: AsyncSession,
) -> dict:
    """
    Helper function to get boarding pass JSON data.
    Used by both regular and debug endpoints.
    """
    # Get ticket
    ticket_repo = TicketRepository(tickets, Ticket)
    ticket = await ticket_repo.get_by_identifier(ticket_identifier, airline_id, db)
    
    if not ticket:
        raise NotFoundError("Ticket", ticket_identifier)
    
    # Get airline settings
    from app.database.tables import settings as settings_table
    from sqlalchemy import select
    
    query = select(settings_table).where(settings_table.c.airline_id == airline_id)
    result = await db.execute(query)
    row = result.fetchone()
    
    airline_settings = None
    if row:
        settings_dict = dict(row._mapping)
        json_data = settings_dict.get("json_data", {})
        airline_settings = Settings.model_validate(json_data)
    else:
        airline_settings = Settings()  # Use defaults
    
    # Create airline model
    airline_model = Airline.model_validate(airline_data)
    airline_model.airline_id = airline_id
    airline_model.airline_identifier = airline_identifier
    
    # Create boarding pass service
    boarding_pass_service = BoardingPassService(
        ticket=ticket,
        airline=airline_model,
        airline_settings=airline_settings
    )
    
    return boarding_pass_service.get_pass_data()


@router.get("/{ticket_identifier}/debug")
async def get_boarding_pass_debug(
    ticket_identifier: str,
    airline: CurrentAirline = None,
    db: DbSession = None,
):
    """
    Get boarding pass JSON data (debug mode) - path-based alternative to ?debug.
    
    Returns the JSON structure being built for the PKPass file.
    Path: GET /v1/airline/{airline_identifier}/boardingpass/{ticket_identifier}/debug
    """
    pass_data = await _get_boarding_pass_data(
        ticket_identifier,
        airline.airline_id,
        airline.airline_identifier,
        airline.airline_data,
        db
    )
    return pass_data


@router.get("/{ticket_identifier}")
async def get_boarding_pass(
    ticket_identifier: str,
    debug: bool = Query(False, description="Return JSON instead of PKPass file"),
    airline: CurrentAirline = None,
    db: DbSession = None,
):
    """
    Get boarding pass as PKPass file or JSON (debug mode via query param).
    
    Matches PHP: GET /v1/airline/{airline_identifier}/boardingpass/{ticket_identifier}
    Matches PHP: GET /v1/airline/{airline_identifier}/boardingpass/{ticket_identifier}?debug
    
    Note: For path-based debug, use /{ticket_identifier}/debug instead of ?debug=true
    """
    if debug:
        # Return JSON (debug mode via query param - for backwards compatibility)
        pass_data = await _get_boarding_pass_data(
            ticket_identifier,
            airline.airline_id,
            airline.airline_identifier,
            airline.airline_data,
            db
        )
        return pass_data
    else:
        # Generate and return PKPass file
        # Get ticket to create service
        ticket_repo = TicketRepository(tickets, Ticket)
        ticket = await ticket_repo.get_by_identifier(ticket_identifier, airline.airline_id, db)
        
        if not ticket:
            raise NotFoundError("Ticket", ticket_identifier)
        
        # Get airline settings
        from app.database.tables import settings as settings_table
        from sqlalchemy import select
        
        query = select(settings_table).where(settings_table.c.airline_id == airline.airline_id)
        result = await db.execute(query)
        row = result.fetchone()
        
        airline_settings = None
        if row:
            settings_dict = dict(row._mapping)
            json_data = settings_dict.get("json_data", {})
            airline_settings = Settings.model_validate(json_data)
        else:
            airline_settings = Settings()  # Use defaults
        
        # Create airline model
        airline_data = airline.airline_data
        airline_model = Airline.model_validate(airline_data)
        airline_model.airline_id = airline.airline_id
        airline_model.airline_identifier = airline.airline_identifier
        
        # Create boarding pass service
        boarding_pass_service = BoardingPassService(
            ticket=ticket,
            airline=airline_model,
            airline_settings=airline_settings
        )
        
        try:
            pkpass_bytes = boarding_pass_service.create_pass()
            
            return Response(
                content=pkpass_bytes,
                media_type="application/vnd.apple.pkpass",
                headers={
                    "Content-Disposition": 'attachment; filename="boardingpass.pkpass"'
                }
            )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to generate boarding pass: {str(e)}"
            )


async def _get_public_boarding_pass_data(
    ticket_identifier: str,
    db: AsyncSession,
) -> dict:
    """
    Helper function to get public boarding pass JSON data.
    Used by both regular and debug endpoints.
    """
    # Get ticket (direct get - no airline filtering)
    from sqlalchemy import select
    
    query = select(
        tickets.c.ticket_id,
        tickets.c.ticket_identifier,
        tickets.c.passenger_id,
        tickets.c.flight_id,
        tickets.c.json_data,
        tickets.c.airline_id,
        tickets.c.modified,
    ).where(tickets.c.ticket_identifier == ticket_identifier)
    
    result = await db.execute(query)
    row = result.fetchone()
    
    if not row:
        raise NotFoundError("Ticket", ticket_identifier)
    
    ticket_dict = dict(row._mapping)
    ticket_json = ticket_dict.get("json_data", {})
    ticket_json["ticket_id"] = ticket_dict["ticket_id"]
    ticket_json["ticket_identifier"] = ticket_dict["ticket_identifier"]
    ticket_json["flight_id"] = ticket_dict["flight_id"]
    ticket_json["passenger_id"] = ticket_dict["passenger_id"]
    ticket = Ticket.model_validate(ticket_json)
    
    # Get airline from ticket's airline_id
    from app.database.tables import airlines
    
    airline_query = select(airlines).where(airlines.c.airline_id == ticket_dict["airline_id"])
    airline_result = await db.execute(airline_query)
    airline_row = airline_result.fetchone()
    
    if not airline_row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Airline not found"
        )
    
    airline_dict = dict(airline_row._mapping)
    airline_json = airline_dict.get("json_data", {})
    airline_model = Airline.model_validate(airline_json)
    airline_model.airline_id = airline_dict["airline_id"]
    airline_model.airline_identifier = airline_dict["airline_identifier"]
    
    # Get airline settings
    from app.database.tables import settings as settings_table
    
    settings_query = select(settings_table).where(
        settings_table.c.airline_id == airline_model.airline_id
    )
    settings_result = await db.execute(settings_query)
    settings_row = settings_result.fetchone()
    
    airline_settings = None
    if settings_row:
        settings_dict = dict(settings_row._mapping)
        settings_json = settings_dict.get("json_data", {})
        airline_settings = Settings.model_validate(settings_json)
    else:
        airline_settings = Settings()  # Use defaults
    
    # Create boarding pass service
    boarding_pass_service = BoardingPassService(
        ticket=ticket,
        airline=airline_model,
        airline_settings=airline_settings
    )
    
    return boarding_pass_service.get_pass_data()


@public_router.get("/{ticket_identifier}/debug")
async def get_public_boarding_pass_debug(
    ticket_identifier: str,
    db: DbSession = None,
):
    """
    Public boarding pass JSON data (debug mode) - path-based alternative to ?debug.
    
    Returns the JSON structure being built for the PKPass file.
    Path: GET /v1/boardingpass/{ticket_identifier}/debug
    No airline authentication required.
    """
    pass_data = await _get_public_boarding_pass_data(ticket_identifier, db)
    return pass_data


@public_router.get("/{ticket_identifier}")
async def get_public_boarding_pass(
    ticket_identifier: str,
    debug: bool = Query(False, description="Return JSON instead of PKPass file"),
    db: DbSession = None,
):
    """
    Public boarding pass endpoint - no airline auth required.
    Airline is determined from the ticket itself.
    
    Matches PHP: GET /v1/boardingpass/{ticket_identifier}
    Used for user-facing links.
    
    Note: For path-based debug, use /{ticket_identifier}/debug instead of ?debug=true
    """
    if debug:
        # Return JSON (debug mode via query param - for backwards compatibility)
        pass_data = await _get_public_boarding_pass_data(ticket_identifier, db)
        return pass_data
    else:
        # Generate and return PKPass file
        # Get ticket to create service
        from sqlalchemy import select
        
        query = select(
            tickets.c.ticket_id,
            tickets.c.ticket_identifier,
            tickets.c.passenger_id,
            tickets.c.flight_id,
            tickets.c.json_data,
            tickets.c.airline_id,
            tickets.c.modified,
        ).where(tickets.c.ticket_identifier == ticket_identifier)
        
        result = await db.execute(query)
        row = result.fetchone()
        
        if not row:
            raise NotFoundError("Ticket", ticket_identifier)
        
        ticket_dict = dict(row._mapping)
        ticket_json = ticket_dict.get("json_data", {})
        ticket_json["ticket_id"] = ticket_dict["ticket_id"]
        ticket_json["ticket_identifier"] = ticket_dict["ticket_identifier"]
        ticket_json["flight_id"] = ticket_dict["flight_id"]
        ticket_json["passenger_id"] = ticket_dict["passenger_id"]
        ticket = Ticket.model_validate(ticket_json)
        
        # Get airline from ticket's airline_id
        from app.database.tables import airlines
        
        airline_query = select(airlines).where(airlines.c.airline_id == ticket_dict["airline_id"])
        airline_result = await db.execute(airline_query)
        airline_row = airline_result.fetchone()
        
        if not airline_row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Airline not found"
            )
        
        airline_dict = dict(airline_row._mapping)
        airline_json = airline_dict.get("json_data", {})
        airline_model = Airline.model_validate(airline_json)
        airline_model.airline_id = airline_dict["airline_id"]
        airline_model.airline_identifier = airline_dict["airline_identifier"]
        
        # Get airline settings
        from app.database.tables import settings as settings_table
        
        settings_query = select(settings_table).where(
            settings_table.c.airline_id == airline_model.airline_id
        )
        settings_result = await db.execute(settings_query)
        settings_row = settings_result.fetchone()
        
        airline_settings = None
        if settings_row:
            settings_dict = dict(settings_row._mapping)
            settings_json = settings_dict.get("json_data", {})
            airline_settings = Settings.model_validate(settings_json)
        else:
            airline_settings = Settings()  # Use defaults
        
        # Create boarding pass service
        boarding_pass_service = BoardingPassService(
            ticket=ticket,
            airline=airline_model,
            airline_settings=airline_settings
        )
        
        try:
            pkpass_bytes = boarding_pass_service.create_pass()
            
            return Response(
                content=pkpass_bytes,
                media_type="application/vnd.apple.pkpass",
                headers={
                    "Content-Disposition": 'attachment; filename="boardingpass.pkpass"'
                }
            )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to generate boarding pass: {str(e)}"
            )

