"""
Pages router for user-facing HTML pages.

Matches PHP pages functionality:
- yourBoardingPass.php - Display boarding pass with disclaimer
"""
from fastapi import APIRouter, Request, Query, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from pathlib import Path
from typing import Optional

from app.dependencies import DbSession
from app.database.tables import tickets, airlines, settings as settings_table
from app.models.ticket import Ticket
from app.models.airline import Airline
from app.models.settings import Settings
from app.core.localization import get_chosen_language, get_localized_strings, get_available_languages
from app.core.exceptions import NotFoundError
from app.services.boarding_pass_service import BoardingPassService
from app.services.signature_service import SignatureService

router = APIRouter()

# Templates directory (relative to server directory)
from pathlib import Path
TEMPLATES_DIR = Path(__file__).parent.parent.parent / "templates"
templates = Jinja2Templates(directory=str(TEMPLATES_DIR))


@router.get("/yourBoardingPass/{ticket_identifier}", response_class=HTMLResponse)
async def your_boarding_pass_by_path(
    request: Request,
    ticket_identifier: str,
    lang: Optional[str] = Query(None, description="Language code"),
    db: DbSession = None,
):
    """Path-based boarding pass page: /pages/yourBoardingPass/{ticket_identifier}"""
    return await your_boarding_pass(request, ticket=ticket_identifier, lang=lang, db=db)


@router.get("/yourBoardingPass", response_class=HTMLResponse)
async def your_boarding_pass(
    request: Request,
    ticket: Optional[str] = Query(None, pattern="^[a-zA-Z0-9-]+$", description="Ticket identifier"),
    lang: Optional[str] = Query(None, description="Language code"),
    db: DbSession = None,
):
    """
    Display boarding pass HTML page with disclaimer and 'Add to Apple Wallet' button.
    
    Matches PHP: GET /pages/yourBoardingPass?ticket={ticket_identifier}&lang={lang}
    
    Features:
    - Language detection (query param → Accept-Language → IP geolocation)
    - Boarding pass card display
    - Disclaimer in selected language
    - QR code generation (client-side)
    - PKPass download link
    """
    # Get chosen language
    language = await get_chosen_language(request, lang_query=lang)
    
    # Get localized strings
    localized_strings = get_localized_strings(language)
    available_languages = get_available_languages()
    
    # Use root-relative paths for static files (works behind Caddy HTTPS proxy)
    root_path = ""
    
    # Default values
    ticket_obj = None
    airline_obj = None
    airline_settings = None
    boarding_pass_service = None
    ticket_signature = None
    pkpass_url = None
    airline_name = "FlyFun Airline"
    pass_background_color = "rgb(189,144,71)"
    pass_foreground_color = "rgb(255,255,255)"
    pass_label_color = "rgb(255,255,255)"
    disclaimer_content = None
    
    # If ticket parameter provided, load ticket and boarding pass
    if ticket:
        # Get ticket (direct get - no airline filtering, like PHP directGetTicket)
        query = select(
            tickets.c.ticket_id,
            tickets.c.ticket_identifier,
            tickets.c.passenger_id,
            tickets.c.flight_id,
            tickets.c.json_data,
            tickets.c.airline_id,
            tickets.c.modified,
        ).where(tickets.c.ticket_identifier == ticket)
        
        result = await db.execute(query)
        row = result.fetchone()
        
        if row:
            ticket_dict = dict(row._mapping)
            ticket_json = ticket_dict.get("json_data", {})
            ticket_json["ticket_id"] = ticket_dict["ticket_id"]
            ticket_json["ticket_identifier"] = ticket_dict["ticket_identifier"]
            ticket_json["flight_id"] = ticket_dict["flight_id"]
            ticket_json["passenger_id"] = ticket_dict["passenger_id"]
            ticket_obj = Ticket.model_validate(ticket_json)
            
            # Get airline from ticket's airline_id
            airline_query = select(
                airlines.c.airline_id,
                airlines.c.airline_identifier,
                airlines.c.json_data,
            ).where(airlines.c.airline_id == ticket_dict["airline_id"])
            airline_result = await db.execute(airline_query)
            airline_row = airline_result.fetchone()
            
            if airline_row:
                airline_dict = dict(airline_row._mapping)
                airline_json = airline_dict.get("json_data", {})
                airline_obj = Airline.model_validate(airline_json)
                airline_obj.airline_id = airline_dict["airline_id"]
                airline_obj.airline_identifier = airline_dict["airline_identifier"]
                airline_name = airline_obj.airline_name
                
                # Get airline settings
                settings_query = select(settings_table).where(
                    settings_table.c.airline_id == airline_obj.airline_id
                )
                settings_result = await db.execute(settings_query)
                settings_row = settings_result.fetchone()
                
                if settings_row:
                    settings_dict = dict(settings_row._mapping)
                    settings_json = settings_dict.get("json_data", {})
                    airline_settings = Settings.model_validate(settings_json)
                else:
                    airline_settings = Settings()  # Use defaults
                
                # Override colors from settings
                pass_background_color = airline_settings.background_color
                pass_foreground_color = airline_settings.foreground_color
                pass_label_color = airline_settings.label_color
                
                # Create boarding pass service
                boarding_pass_service = BoardingPassService(
                    ticket=ticket_obj,
                    airline=airline_obj
                )
                
                # Get ticket signature for QR code
                signature_service = SignatureService(airline_obj.apple_identifier)
                ticket_signature = ticket_obj.signature(signature_service)
                
                # Build PKPass URL (public endpoint)
                from app.config import settings
                pkpass_url = f"{settings.api_prefix}/boardingpass/{ticket}"
    
    # Load disclaimer content
    disclaimer_file = Path("templates/disclaimers") / f"disclaimer_{language}.html"
    if disclaimer_file.exists():
        disclaimer_content = disclaimer_file.read_text(encoding='utf-8')
    
    # Render template
    return templates.TemplateResponse(
        "boarding_pass.html",
        {
            "request": request,
            "language": language,
            "localized_strings": localized_strings,
            "available_languages": available_languages,
            "root_path": root_path,
            "ticket": ticket_obj,
            "flight": ticket_obj.flight if ticket_obj else None,
            "airline_name": airline_name,
            "airline_settings": airline_settings.model_dump(by_alias=True) if airline_settings else None,
            "boarding_pass_service": boarding_pass_service,
            "ticket_signature": ticket_signature,
            "pkpass_url": pkpass_url,
            "pass_background_color": pass_background_color,
            "pass_foreground_color": pass_foreground_color,
            "pass_label_color": pass_label_color,
            "disclaimer_content": disclaimer_content,
        }
    )

