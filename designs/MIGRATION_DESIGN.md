# Migration Design Document: PHP to Python/FastAPI

## Executive Summary

This document outlines the design for migrating the Fly Fun Boarding server from PHP to Python/FastAPI. The migration will maintain API compatibility with the existing iOS app while modernizing the backend architecture. **This is a complete replacement** - the PHP server will be decommissioned after successful migration.

### Key Architectural Decisions

1. **Database**: SQLAlchemy Core (NOT ORM) - Type-safe query building without ORM complexity
2. **PKPass Library**: `passes-rs-py` - Rust-based, high-performance library
3. **Database Schema**: No changes - Python backend operates on existing MySQL schema unchanged (no Alembic migrations)
4. **Airport Data**: Use `euro_aip` library - **DO NOT read airports.db directly**
5. **Configuration**: `.env` files with `pydantic-settings` - Secure, Docker-friendly
6. **Web Pages**: Public, read-only, no authentication required (`/pages/*`)
7. **Error Format**: Standardized JSON error responses
8. **Logging**: Python `logging` module, configurable via `.env` (file or stdout)
9. **Static Files**: All in `server/static/` (images copied from `../images/`, use CDN for `qrcode.min.js` if needed)
10. **CORS**: Not needed - iOS app doesn't use CORS, web pages are same-origin
11. **Health Check**: Includes database connectivity check
12. **Language Detection**: Modern approach using `Accept-Language` header parsing with optional IP geolocation fallback
13. **Flight Check Endpoint**: Marked as "To be implemented" (verify functionality)

**Key Advantages**: 
- The iOS app already uses path-based routing (`/v1/airline/{id}/...`), which FastAPI supports natively. The current Apache server remaps these to query parameters due to Apache's routing limitations, but FastAPI can use the original path structure directly - no iOS app changes required!
- **Docker deployment** ensures portability across any server environment
- **Caddy reverse proxy** provides automatic SSL certificate management
- **Big bang migration** strategy: All endpoints implemented and tested on test server before production cutover

## Current Architecture Analysis

### 1. Technology Stack

**Current (PHP):**
- PHP 7.3+ backend
- MySQL 8.0 database
- Custom routing/dispatching system
- JSON-based data storage (JSON columns in MySQL)
- Apple Wallet PKPass generation (using PHP PKPass library)
- OpenSSL for cryptographic signatures
- mysqli for database access

**Proposed (Python/FastAPI):**
- Python 3.13 backend (matches dev and production environments)
- FastAPI framework
- MySQL 8.0 database (maintained)
- **Database Approach**: SQLAlchemy Core (query building) + raw SQL for complex queries
- PKPass library: `passes-rs-py` ✅
- `cryptography` library for OpenSSL operations
- `pydantic` for data validation and serialization
- Async/await support for better performance
- Configuration management via `.env` file (with `.env.sample` template) using `pydantic-settings`
- Code location: `server/` directory (separate from PHP `api/` directory)
- **Docker deployment** for portability and consistency across environments
- **Caddy reverse proxy** for SSL/TLS termination and routing

### 2. Current Architecture Components

#### 2.1 Routing System
- **Current**: Custom `Dispatch.php` class that:
  - Parses URL segments
  - Handles versioning (v1)
  - Extracts airline identifier from URL path
  - Maps to controller/action based on URL structure
  - Supports HTTP method-specific actions (e.g., `index_get`, `index_post`)
  - **Note**: iOS app uses path-based routing, but Apache remaps to query parameters (`?url=...`) due to Apache routing limitations

**Actual Routes (as used by iOS app):**
```
/v1/airline/{identifier}/controller/action
/v1/controller/action
```

**Apache Remapping (current server):**
```
/api/index.php?url=v1/airline/{identifier}/controller/action
```

#### 2.2 Controllers
All controllers extend base `Controller` class with common utilities:
- `AircraftController` - Aircraft CRUD operations
- `AirlineController` - Airline management and authentication
- `AirportController` - Airport data (uses `euro_aip` library, NOT direct database access)
- `BoardingPassController` - PKPass generation
- `FlightController` - Flight planning and management
- `PassengerController` - Passenger CRUD operations
- `TicketController` - Ticket issuance and verification
- `SettingsController` - Airline settings management
- `StatusController` - System status
- `DbController` - Database setup/management
- `KeysController` - Public key management

#### 2.3 Data Models
Models use JSON serialization pattern:
- `Aircraft` - Aircraft registration and details
- `Airline` - Airline information and authentication
- `Airport` - Airport data (from `euro_aip` library, NOT from airports.db directly)
- `Flight` - Flight details (origin, destination, times, aircraft)
- `Passenger` - Passenger information
- `Ticket` - Links passenger to flight with seat number
- `BoardingPass` - PKPass generation logic
- `Settings` - Airline-specific settings (colors, labels, etc.)

#### 2.4 Database Layer
- **Current**: `MyFlyFunDb` singleton class
- Uses JSON columns for flexible schema
- Tables: Airlines, Settings, Aircrafts, Passengers, Flights, Tickets, BoardingPasses
- Foreign key relationships with CASCADE deletes
- UUID identifiers for most entities
- Airline-scoped data (all entities belong to an airline)
- **Migration Constraint**: The new Python/FastAPI backend **must operate on this existing MySQL schema** without structural changes so that PHP and Python can (if needed) point at the same database during migration and rollback. All SQLAlchemy models and raw SQL must therefore be designed to match the current tables/columns exactly (including `json_data` JSON columns, `{entity}_id` integer PKs, `{entity}_identifier` UUID-style strings, `airline_id` scoping, and `modified` timestamps).

**Database Schema Pattern:**
```sql
CREATE TABLE {Entity}s (
    {entity}_id INT AUTO_INCREMENT PRIMARY KEY,
    {entity}_identifier VARCHAR(36) UNIQUE DEFAULT (uuid()),
    json_data JSON,
    airline_id INT NOT NULL,
    modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (airline_id) REFERENCES Airlines(airline_id) ON DELETE CASCADE
)
```

#### 2.5 Authentication & Authorization
- Bearer token authentication using Apple identifier
- Airline-scoped operations (airline_id set after authentication)
- System-level operations use secret key
- Public/private key pairs for ticket signatures

#### 2.6 PKPass Generation
- Uses PHP PKPass library
- Requires Apple certificate and WWDR certificate
- Generates signed .pkpass files
- Includes localization (en, fr, de, es)
- Customizable colors and branding per airline

## Proposed FastAPI Architecture

### 1. Project Structure

**Decisions Made**:
- ✅ **Database**: SQLAlchemy Core (query building) + raw SQL for complex queries
- ✅ **Code Location**: `server/` directory (separate from PHP `api/` directory)
- ✅ **Python Version**: 3.13 (matches dev and production environments)
- ✅ **PKPass Library**: `passes-rs-py`

```
server/
├── pyproject.toml          # Modern Python packaging (replaces requirements.txt)
├── .env                    # Environment variables (not in git)
├── .env.sample             # Environment variables template
├── README.md               # Setup and development instructions
├── .gitignore              # Git ignore rules
├── Dockerfile              # Docker container definition
├── docker-compose.yml      # Docker Compose configuration (optional)
├── Caddyfile               # Caddy reverse proxy configuration
│
├── app/                    # Application package
│   ├── __init__.py
│   ├── main.py             # FastAPI app entry point
│   ├── config.py           # Configuration loader (pydantic-settings)
│   ├── dependencies.py     # Shared FastAPI dependencies (airline auth, db session)
│   │
│   ├── database/           # Database layer
│   │   ├── __init__.py
│   │   ├── connection.py   # Engine, async session factory
│   │   ├── tables.py       # SQLAlchemy Core table definitions
│   │   └── repository.py   # Generic CRUD repository pattern
│   │
│   ├── models/             # Domain models (Pydantic BaseModels)
│   │   ├── __init__.py
│   │   ├── base.py         # BaseJsonModel with PHP-compatible serialization
│   │   ├── aircraft.py
│   │   ├── airline.py
│   │   ├── flight.py
│   │   ├── passenger.py
│   │   ├── ticket.py
│   │   ├── settings.py
│   │   └── stats.py
│   │
│   ├── schemas/            # API request/response schemas
│   │   ├── __init__.py
│   │   ├── aircraft.py
│   │   ├── airline.py
│   │   ├── flight.py
│   │   ├── passenger.py
│   │   ├── ticket.py
│   │   └── common.py       # Shared response schemas (errors, pagination)
│   │
│   ├── routers/            # API route handlers
│   │   ├── __init__.py
│   │   ├── aircraft.py
│   │   ├── airline.py
│   │   ├── airport.py
│   │   ├── boarding_pass.py
│   │   ├── flight.py
│   │   ├── passenger.py
│   │   ├── ticket.py
│   │   ├── settings.py
│   │   ├── status.py
│   │   ├── db.py
│   │   └── pages.py        # Web pages (HTML) for boarding pass display
│   │
│   ├── services/           # Business logic layer
│   │   ├── __init__.py
│   │   ├── pkpass_service.py     # PKPass generation
│   │   ├── signature_service.py  # Cryptographic operations
│   │   └── airport_service.py    # Airport data via euro_aip
│   │
│   └── core/               # Core utilities
│       ├── __init__.py
│       ├── exceptions.py   # Custom HTTP exceptions
│       ├── json_helper.py  # PHP-compatible JSON serialization
│       └── localization.py # Language detection (babel)
│
├── templates/              # Jinja2 HTML templates
│   ├── base.html
│   ├── boarding_pass.html
│   ├── boarding_pass_card.html
│   └── disclaimers/
│       ├── disclaimer_en.html
│       ├── disclaimer_fr.html
│       ├── disclaimer_de.html
│       └── disclaimer_es.html
│
├── static/                 # Static files (served by FastAPI)
│   ├── css/
│   ├── js/
│   │   └── qrcode.min.js
│   └── images/
│       ├── logo.png
│       ├── logo@2x.png
│       ├── icon.png
│       ├── icon@2x.png
│       └── AddToApple/
│           ├── en/
│           ├── fr/
│           ├── de/
│           └── es/
│
└── tests/                  # Test suite
    ├── __init__.py
    ├── conftest.py         # Pytest fixtures
    ├── test_airline.py
    ├── test_aircraft.py
    ├── test_flight.py
    ├── test_passenger.py
    ├── test_ticket.py
    └── test_boarding_pass.py
```

### 2. FastAPI Implementation Details

#### 2.1 Main Application (`app/main.py`)

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from app.config import settings
from app.database.connection import engine
from app.routers import (
    aircraft, airline, airport, boarding_pass,
    flight, passenger, ticket, settings as settings_router,
    status, db, pages
)
from app.core.exceptions import register_exception_handlers


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan - startup and shutdown events."""
    # Startup: verify database connection
    async with engine.begin() as conn:
        await conn.execute("SELECT 1")
    yield
    # Shutdown: dispose engine
    await engine.dispose()


app = FastAPI(
    title="Fly Fun Boarding API",
    version="1.0.0",
    description="API for Fly Fun Boarding app",
    lifespan=lifespan,
)

# Register custom exception handlers
register_exception_handlers(app)

# Note: CORS not needed - iOS app doesn't use CORS, web pages are same-origin

# Include routers
# Note: Using path-based routing directly (iOS app already uses paths, Apache was remapping to query params)
app.include_router(airline.router, prefix="/v1/airline", tags=["airline"])
app.include_router(aircraft.router, prefix="/v1/airline/{airline_identifier}/aircraft", tags=["aircraft"])
app.include_router(flight.router, prefix="/v1/airline/{airline_identifier}/flight", tags=["flight"])
app.include_router(passenger.router, prefix="/v1/airline/{airline_identifier}/passenger", tags=["passenger"])
app.include_router(ticket.router, prefix="/v1/airline/{airline_identifier}/ticket", tags=["ticket"])
app.include_router(boarding_pass.router, prefix="/v1/airline/{airline_identifier}/boardingpass", tags=["boardingpass"])
app.include_router(settings_router.router, prefix="/v1/airline/{airline_identifier}/settings", tags=["settings"])
app.include_router(airport.router, prefix="/v1/airport", tags=["airport"])
app.include_router(status.router, prefix="/v1/status", tags=["status"])
app.include_router(db.router, prefix="/v1/db", tags=["db"])

# Direct boarding pass access (no airline prefix - determines airline from ticket)
app.include_router(boarding_pass.public_router, prefix="/v1/boardingpass", tags=["boardingpass"])

# Web pages (user-facing HTML - no auth required)
app.include_router(pages.router, tags=["pages"])

# Static files (images, CSS, JS)
app.mount("/static", StaticFiles(directory="static"), name="static")


@app.get("/health")
async def health_check():
    """Health check endpoint for load balancers and monitoring."""
    return {"status": "healthy"}
```

#### 2.2 Database Layer

**Three Approaches Compared:**

**Option A: SQLAlchemy ORM (Full ORM)**
- **Pros**: 
  - Models as Python classes with relationships
  - Automatic object-relational mapping
  - Type safety with IDE autocomplete
  - Alembic migrations
- **Cons**: 
  - Steep learning curve (sessions, relationships, async patterns)
  - More abstraction (harder to see actual SQL)
  - Overkill if you don't need object mapping
  - Your data is mostly in JSON columns anyway, so ORM mapping is less useful

**Option B: SQLAlchemy Core (Recommended)** ✅
- **Pros**:
  - **Query building in Python** (type-safe, composable, but still SQL-like)
  - **Table metadata** (define schema once, reuse everywhere)
  - **Connection pooling** built-in
  - **Transaction management** (context managers)
  - **No object mapping** - you work with dicts/rows (perfect for JSON columns!)
  - **Much simpler than ORM** - just query building, no sessions/relationships
  - **Async support** with `aiomysql` backend
  - **Best of both worlds**: Type safety + explicit SQL control
- **Cons**:
  - Still need to learn SQLAlchemy expression language (but simpler than ORM)
  - Slightly more verbose than raw SQL strings
- **Perfect fit for this project**: You have fixed schema, JSON columns, and want type-safe queries without ORM complexity

**Option C: Raw aiomysql (Pure SQL)**
- **Pros**:
  - Closest to current PHP approach
  - Full control - you write exact SQL
  - Minimal dependencies
  - Easy to understand if you know SQL
- **Cons**:
  - No query building (string concatenation for dynamic queries)
  - No type safety
  - More boilerplate (connection management, parameter binding)
  - Easier to introduce SQL injection bugs if not careful

**Decision: SQLAlchemy Core** ✅
- Use SQLAlchemy Core for query building and table definitions
- Work with dicts/rows (not ORM objects) - perfect for JSON column pattern
- Use `aiomysql` as async backend
- Provides type-safe query building without ORM complexity
- Still allows raw SQL when needed (via `text()`)
- Matches your use case: fixed schema, JSON storage, explicit control

#### 2.3 Authentication via Dependency Injection (Recommended)

**Why Dependency Injection over Middleware:**
- ✅ Type-safe: IDE autocomplete and type checking
- ✅ Testable: Easy to mock in unit tests
- ✅ Explicit: Clear which endpoints require auth
- ✅ Flexible: Different auth requirements per endpoint

```python
# app/dependencies.py
from typing import Annotated
from fastapi import Depends, Header, Path, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.connection import get_db
from app.database.repository import AirlineRepository
from app.models.airline import Airline


class AirlineContext:
    """Authenticated airline context for request."""
    def __init__(self, airline: Airline, airline_id: int):
        self.airline = airline
        self.airline_id = airline_id


async def get_airline_context(
    airline_identifier: Annotated[str, Path(description="Airline identifier from URL")],
    authorization: Annotated[str | None, Header()] = None,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> AirlineContext:
    """
    Dependency that validates airline authentication.
    Extracts airline_identifier from path and validates Bearer token.
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Bearer Token"
        )

    token = authorization.removeprefix("Bearer ")

    repo = AirlineRepository(db)
    airline = await repo.get_by_identifier(airline_identifier)

    if not airline:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Airline not found"
        )

    if airline.apple_identifier != token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Bearer Token"
        )

    return AirlineContext(airline, airline.airline_id)


async def get_system_auth(
    authorization: Annotated[str | None, Header()] = None,
) -> bool:
    """Dependency for system-level authentication (db setup, etc.)."""
    from app.config import settings

    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="System authentication required")

    token = authorization.removeprefix("Bearer ")
    if token != settings.SECRET:
        raise HTTPException(status_code=401, detail="Invalid system token")

    return True


# Type aliases for cleaner router signatures
CurrentAirline = Annotated[AirlineContext, Depends(get_airline_context)]
SystemAuth = Annotated[bool, Depends(get_system_auth)]
DbSession = Annotated[AsyncSession, Depends(get_db)]
```

**Usage in Routers:**
```python
# app/routers/aircraft.py
from fastapi import APIRouter
from app.dependencies import CurrentAirline, DbSession
from app.schemas.aircraft import AircraftCreate, AircraftResponse

router = APIRouter()

@router.post("/create", response_model=AircraftResponse)
async def create_aircraft(
    aircraft_data: AircraftCreate,
    airline: CurrentAirline,  # Auth happens automatically via dependency
    db: DbSession,
):
    """Create a new aircraft for the authenticated airline."""
    # airline.airline_id is available here
    # airline.airline is the full Airline object
    ...

@router.get("/list", response_model=list[AircraftResponse])
async def list_aircraft(
    airline: CurrentAirline,
    db: DbSession,
):
    """List all aircraft for the authenticated airline."""
    ...
```

**Public Endpoints (No Auth):**
```python
# app/routers/boarding_pass.py
from fastapi import APIRouter

router = APIRouter()  # Authenticated routes
public_router = APIRouter()  # Public routes (no auth)

@public_router.get("/{ticket_identifier}")
async def get_public_boarding_pass(
    ticket_identifier: str,
    db: DbSession,
):
    """
    Public boarding pass endpoint - no airline auth required.
    Airline is determined from the ticket itself (directGet pattern).
    """
    # Use directGet pattern - bypasses airline_id filtering
    ticket = await ticket_repo.direct_get_by_identifier(ticket_identifier, db)
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    ...
```

#### 2.4 Model Definitions

**Pydantic Schemas** (for request/response validation):
```python
# schemas/ticket.py
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class TicketBase(BaseModel):
    seat_number: str
    custom_label_value: Optional[str] = ""

class TicketCreate(TicketBase):
    passenger_identifier: str
    flight_identifier: str

class TicketResponse(TicketBase):
    ticket_id: int
    ticket_identifier: str
    passenger: dict
    flight: dict
```

**Database Table Definitions** (SQLAlchemy Core - NOT ORM):
```python
# database.py - Table definitions using SQLAlchemy Core
from sqlalchemy import Table, Column, Integer, String, JSON, ForeignKey, TIMESTAMP, MetaData
from sqlalchemy.sql import func

metadata = MetaData()

# Define tables as Table objects (not ORM classes)
tickets = Table(
    'Tickets', metadata,
    Column('ticket_id', Integer, primary_key=True, autoincrement=True),
    Column('ticket_identifier', String(36), unique=True),
    Column('json_data', JSON),
    Column('passenger_id', Integer, ForeignKey('Passengers.passenger_id', ondelete='CASCADE')),
    Column('flight_id', Integer, ForeignKey('Flights.flight_id', ondelete='CASCADE')),
    Column('airline_id', Integer, ForeignKey('Airlines.airline_id', ondelete='CASCADE')),
    Column('modified', TIMESTAMP, server_default=func.now(), onupdate=func.now())
)

# Similar table definitions for other entities:
# airlines = Table('Airlines', metadata, ...)
# passengers = Table('Passengers', metadata, ...)
# flights = Table('Flights', metadata, ...)
# etc.
```

**Key Points**:
- ✅ **No ORM classes** - We use `Table()` definitions, not `class Ticket(Base)`
- ✅ **No relationships** - We work with dicts/rows, not ORM objects
- ✅ **Table metadata** - Define schema once, use everywhere for type-safe queries
- ✅ **Works with dicts** - Perfect for JSON column pattern (no object mapping needed)

#### 2.5 Service Layer

**Database Repository** (using SQLAlchemy Core):
```python
# services/ticket_repository.py
from typing import Optional, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, insert, update
from database import tickets  # Table definition from database.py
from schemas.ticket import TicketCreate

class TicketRepository:
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create_or_update_ticket(
        self, 
        ticket_data: TicketCreate,
        airline_id: int
    ) -> Dict[str, Any]:
        # Implementation using SQLAlchemy Core
        # Returns dict (not ORM object)
        stmt = insert(tickets).values(
            ticket_identifier=ticket_data.ticket_identifier,
            json_data=ticket_data.model_dump(),
            airline_id=airline_id,
            # ... other fields
        ).on_duplicate_key_update(
            json_data=ticket_data.model_dump()
        )
        await self.db.execute(stmt)
        await self.db.commit()
        # Return as dict
        return await self.get_ticket_by_identifier(ticket_data.ticket_identifier, airline_id)
    
    async def get_ticket_by_identifier(
        self,
        ticket_identifier: str,
        airline_id: int
    ) -> Optional[Dict[str, Any]]:
        # Query using SQLAlchemy Core - returns dict
        query = select(tickets).where(
            tickets.c.ticket_identifier == ticket_identifier,
            tickets.c.airline_id == airline_id
        )
        result = await self.db.execute(query)
        row = result.fetchone()
        if not row:
            return None
        # Convert row to dict
        return dict(row._mapping)
```

**PKPass Service:**
```python
# services/pkpass_service.py
from models.ticket import Ticket
from pathlib import Path
import zipfile
import json

class PKPassService:
    def __init__(self, cert_path: str, cert_password: str, wwdr_path: str):
        self.cert_path = cert_path
        self.cert_password = cert_password
        self.wwdr_path = wwdr_path
    
    def generate_pkpass(self, ticket: Ticket) -> bytes:
        # Generate pass.json
        # Add images
        # Sign with certificate
        # Create ZIP file
        # Return bytes
        pass
```

#### 2.6 Router Implementation

```python
# routers/ticket.py
from fastapi import APIRouter, Depends, HTTPException, Request
from typing import List
from schemas.ticket import TicketCreate, TicketResponse
from services.database_service import DatabaseService
from database import get_db

router = APIRouter()

@router.post("/issue", response_model=TicketResponse)
async def issue_ticket(
    flight_identifier: str,
    passenger_identifier: str,
    ticket_data: TicketCreate,
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    airline_id = request.state.airline_id
    
    # Get flight and passenger
    # Create ticket
    # Return ticket
    pass

@router.get("/{ticket_identifier}", response_model=TicketResponse)
async def get_ticket(
    ticket_identifier: str,
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    airline_id = request.state.airline_id
    # Retrieve and return ticket
    pass
```

#### 2.7 Web Pages (User-Facing HTML)

**Current**: PHP pages in `pages/` directory that render HTML boarding passes:
- `yourBoardingPass.php` - Main page with disclaimer and boarding pass display
- `walletPass.php` - Boarding pass HTML rendering component
- `airports.php` - Airport information lookup
- Disclaimer files in multiple languages (`disclaimer_en.html`, `disclaimer_fr.html`, etc.)

**Solution**: FastAPI with Jinja2 templates for HTML rendering

**Implementation** (`routers/pages.py`):
```python
from fastapi import APIRouter, Request, Query, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from services.database_service import DatabaseService
from utils.localization import get_language, get_localized_strings
from pathlib import Path

router = APIRouter()
templates = Jinja2Templates(directory="templates")

@router.get("/pages/yourBoardingPass", response_class=HTMLResponse)
async def your_boarding_pass(
    request: Request,
    ticket: str = Query(..., regex="^[a-zA-Z0-9]+$"),
    lang: str = Query(None)
):
    """Display boarding pass HTML page with disclaimer and 'Add to Apple Wallet' button."""
    # Get ticket (no airline auth required for public viewing)
    db_service = DatabaseService(await get_db())
    ticket_obj = await db_service.direct_get_ticket(ticket)
    
    if not ticket_obj:
        raise HTTPException(status_code=404, detail="Ticket not found")
    
    # Detect language (from query param, Accept-Language header, or IP geolocation)
    # Implementation: Use Accept-Language header primarily, with optional IP geolocation fallback
    # Use babel.core.Locale.negotiate() for header parsing
    language = get_language(lang, request)
    
    # Get localized strings
    localized_strings = get_localized_strings(language)
    
    # Get boarding pass data
    from services.pkpass_service import PKPassService
    pkpass_service = PKPassService()
    boarding_pass_data = pkpass_service.get_pass_data(ticket_obj)
    
    # Generate PKPass URL
    airline_identifier = ticket_obj.airline.airline_identifier
    pkpass_url = f"/v1/airline/{airline_identifier}/boardingpass/{ticket}"
    
    return templates.TemplateResponse(
        "boarding_pass.html",
        {
            "request": request,
            "ticket": ticket_obj,
            "boarding_pass": boarding_pass_data,
            "language": language,
            "localized_strings": localized_strings,
            "pkpass_url": pkpass_url,
            "root_path": "/"  # For static assets
        }
    )

@router.get("/pages/airports", response_class=HTMLResponse)
async def airports_page(
    request: Request,
    which: str = Query("customs"),
    country: str = Query("FR")
):
    """Display airport information lookup page."""
    # Use euro_aip library to query airport data
    # DO NOT read airports.db directly - use EuroAipModel API
    from euro_aip.models import EuroAipModel
    model = EuroAipModel.from_file(settings.AIRPORT_DB_PATH)
    # Query using model.airports collection API
    pass
```

**Template Structure** (`templates/boarding_pass.html`):
```jinja2
{% extends "base.html" %}

{% block content %}
<div class="language-switcher">
    <div class="logo-container">
        <img src="{{ root_path }}/static/images/logo.png" alt="logo" width="100">
        <span class="logo-text">Fly Fun</span>
    </div>
    <div class="language-buttons">
        {% for lang_code, lang_name in available_languages %}
        <a href="?ticket={{ ticket.ticket_identifier }}&lang={{ lang_code }}">{{ lang_name }}</a>
        {% endfor %}
    </div>
</div>

{% if ticket %}
    {% include "boarding_pass_card.html" %}
    
    <div class="acknowledge">
        <form>
            <label>
                <input type="checkbox" id="agree-checkbox" value="1" checked>
                {{ localized_strings['I agree to the terms and conditions below'] }}
            </label>
            <a id="submit-link" href="{{ pkpass_url }}" download>
                <img id="submit-img" src="{{ root_path }}/static/images/AddToApple/{{ language }}/badge.svg" 
                     alt="Add to Apple Wallet" width="100">
            </a>
        </form>
    </div>
{% endif %}

<div class="disclaimer">
    {% include "disclaimer_" + language + ".html" %}
</div>
{% endblock %}
```

**Key Features**:
- ✅ **Language Detection**:
  - Primary: Query parameter (`?lang=en`)
  - Secondary: `Accept-Language` HTTP header (use `babel.core.Locale.negotiate()`)
  - Optional fallback: IP geolocation (use modern service like `ipapi.co` or `ip-api.com` with `httpx`)
- ✅ **Localization**: Multi-language support (en, fr, de, es) matching PHP implementation
- ✅ **QR Code Generation**: Client-side using `qrcode.min.js` (same as PHP)
- ✅ **Static File Serving**: Images, CSS, JS served via FastAPI StaticFiles
- ✅ **Disclaimer Files**: HTML disclaimer files in multiple languages
- ✅ **Airline Branding**: Colors and styling from airline settings
- ✅ **PKPass Download**: Link to generate and download `.pkpass` file

**Dependencies**:
- `jinja2` - Template engine
- `python-multipart` - For form handling (already in requirements)
- Static file serving built into FastAPI

### 3. Key Migration Considerations

#### 3.1 URL Routing Compatibility

**Status**: ✅ **No compatibility issues** - The iOS app already uses path-based routing!

**Current Situation**: 
- iOS app sends requests to path-based URLs: `/v1/airline/{identifier}/controller/action`
- Apache server remaps these to query parameters (`?url=...`) because Apache doesn't support direct path routing
- FastAPI natively supports path-based routing, so we can use the original path structure directly

**Solution**: 
- Use FastAPI's native path-based routing (Option B)
- No iOS app changes required
- Cleaner, more RESTful API design
- Direct mapping: `/v1/airline/{airline_identifier}/controller/action`

#### 3.2 JSON Serialization

**Current**: Custom `JsonHelper` class with a sophisticated serialization pattern:
- Models define `$jsonKeys` static array mapping field names to types
- Models define `$jsonValuesOptionalDefaults` for default values
- Special handling for `DateTime` (ISO 8601 format: `'c'` format)
- Special handling for `DateInterval` (ISO 8601 duration: `'PT%hH%iM%sS'`)
- Nested object serialization (e.g., `'Aircraft'`, `'Airport'`)
- Typed array serialization (e.g., `'array<Stats>'`)
- **Omits fields with default values** from JSON output (important!)
- Some models have `uniqueIdentifier()` method that adds extra fields to JSON

**Key Differences to Handle**:
1. **Default Value Omission**: PHP omits fields that match defaults (e.g., `flight_id: -1` is omitted). Pydantic includes all fields by default.
2. **DateTime Format**: PHP uses ISO 8601 (`'c'` format = `2023-12-25T10:30:00+00:00`). Python's `datetime.isoformat()` produces the same format.
3. **DateInterval Format**: PHP uses ISO 8601 duration (`PT2H30M`). Python needs custom serialization.
4. **Nested Objects**: PHP recursively serializes nested objects. Pydantic handles this automatically.
5. **Type System**: PHP uses string type hints (`'string'`, `'integer'`, `'DateTime'`). Pydantic uses Python types.

**Solution**: 
- Use Pydantic models with custom serializers for DateTime/DateInterval
- Implement `exclude_defaults=True` in Pydantic serialization to match PHP behavior
- Create custom JSON encoder for DateInterval (ISO 8601 duration format)
- Ensure DateTime serialization matches PHP's `'c'` format exactly
- Test JSON output matches PHP output byte-for-byte for compatibility

**Pythonic Abstraction** (`app/models/base.py`):
```python
from datetime import datetime, timedelta
from typing import Any
from pydantic import BaseModel, ConfigDict


def timedelta_to_iso8601(td: timedelta) -> str:
    """Convert Python timedelta to ISO 8601 duration format (PT2H30M0S)."""
    total_seconds = int(td.total_seconds())
    hours = total_seconds // 3600
    minutes = (total_seconds % 3600) // 60
    seconds = total_seconds % 60
    return f"PT{hours}H{minutes}M{seconds}S"


def iso8601_to_timedelta(duration: str) -> timedelta:
    """Parse ISO 8601 duration (PT2H30M0S) to timedelta."""
    import re
    match = re.match(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?', duration)
    if not match:
        raise ValueError(f"Invalid ISO 8601 duration: {duration}")
    hours = int(match.group(1) or 0)
    minutes = int(match.group(2) or 0)
    seconds = int(match.group(3) or 0)
    return timedelta(hours=hours, minutes=minutes, seconds=seconds)


class BaseJsonModel(BaseModel):
    """
    Base model with PHP-compatible JSON serialization.

    Key behaviors matching PHP JsonHelper:
    - Excludes fields that match their default values
    - DateTime serialized as ISO 8601 ('c' format in PHP)
    - DateInterval serialized as ISO 8601 duration (PT2H30M0S)
    - Supports uniqueIdentifier() pattern for extra fields
    """

    model_config = ConfigDict(
        populate_by_name=True,  # Allow both field name and alias
        use_enum_values=True,
        json_encoders={
            datetime: lambda v: v.isoformat() if v else None,
            timedelta: timedelta_to_iso8601,
        },
    )

    def to_json(self) -> dict[str, Any]:
        """
        PHP-compatible JSON serialization.
        Matches behavior of PHP's JsonHelper::toJson().
        """
        # Exclude defaults to match PHP behavior
        data = self.model_dump(
            exclude_defaults=True,
            by_alias=True,
            mode='json',  # Use JSON-compatible types
        )

        # Merge unique_identifier fields if method exists
        if hasattr(self, 'unique_identifier'):
            data.update(self.unique_identifier())

        return data

    def unique_identifier(self) -> dict[str, Any]:
        """
        Override in subclasses to add extra fields to JSON output.
        Matches PHP's uniqueIdentifier() pattern.
        """
        return {}


# Example usage
class Aircraft(BaseJsonModel):
    registration: str
    type: str
    aircraft_id: int = -1  # Default -1, will be excluded from JSON
    aircraft_identifier: str = ""  # Default "", will be excluded from JSON
    stats: list["Stats"] = []

    def unique_identifier(self) -> dict[str, Any]:
        """Add computed fields to JSON output."""
        return {"display_name": f"{self.registration} ({self.type})"}
```

**Key Implementation Notes:**
- `exclude_defaults=True` matches PHP's behavior of omitting fields with default values
- `by_alias=True` uses field aliases if defined (e.g., `seatNumber` vs `seat_number`)
- `mode='json'` ensures datetime/timedelta are serialized using custom encoders
- Override `unique_identifier()` for PHP's `uniqueIdentifier()` pattern

**Example PHP JSON Output**:
```json
{
  "registration": "N123AB",
  "type": "Cirrus SR22",
  "stats": [
    {"count": 5, "last": "2023-12-25T10:30:00+00:00", "table": "Flights"}
  ]
}
```
Note: `aircraft_id: -1` and `aircraft_identifier: ""` are **omitted** because they match defaults.

**Python Pydantic Equivalent**:
```python
from pydantic import BaseModel, Field
from datetime import datetime, timedelta
from typing import Optional, List

def timedelta_to_iso8601_duration(td: timedelta) -> str:
    """Convert Python timedelta to ISO 8601 duration format (PT2H30M)."""
    total_seconds = int(td.total_seconds())
    hours = total_seconds // 3600
    minutes = (total_seconds % 3600) // 60
    seconds = total_seconds % 60
    
    parts = []
    if hours:
        parts.append(f"{hours}H")
    if minutes:
        parts.append(f"{minutes}M")
    if seconds:
        parts.append(f"{seconds}S")
    
    return "PT" + "".join(parts) if parts else "PT0S"

class Stats(BaseModel):
    count: int
    last: Optional[datetime] = None
    table: str

class Aircraft(BaseModel):
    registration: str
    type: str
    aircraft_id: int = Field(default=-1, exclude=True)  # Exclude default
    aircraft_identifier: str = Field(default="", exclude=True)  # Exclude default
    stats: List[Stats] = Field(default_factory=list)
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat(),  # Matches PHP 'c' format
            timedelta: timedelta_to_iso8601_duration  # Matches PHP DateInterval format
        }
        
    def model_dump(self, exclude_defaults=True, **kwargs):
        # This ensures defaults are excluded like PHP
        return super().model_dump(exclude_defaults=True, **kwargs)
```

#### 3.3 Database Access Pattern

**Current**: Singleton `MyFlyFunDb::$shared` with static methods.

**Solution**:
- Use FastAPI dependency injection for database sessions.
- Create a **database repository layer** that centralizes patterns currently implemented in `MyFlyFunDb`:
  - A small metadata map (table → links, identifier field, id field) that replaces the PHP `$standardTables` / `$tableCreationOrder` logic.
  - Generic helpers for `create_or_update`, `list`, `list_stats`, `get_by_identifier`, `get_by_id`, and `delete`, parameterized by table.
  - A single implementation of the “stats” pattern (`COUNT` + `MAX(modified)` joins) used by `listStats` in PHP, instead of re-writing those queries per router.
- Maintain `airline_id` scoping through dependency injection (via `CurrentAirline` dependency) and pass it into repository calls so that every query is automatically airline-scoped, avoiding duplication of `WHERE airline_id = ...` logic.

**SQLAlchemy Core Example** (what this looks like in practice):

```python
# database.py - Database connection and table definitions
from sqlalchemy import Table, Column, Integer, String, JSON, ForeignKey, TIMESTAMP, MetaData, create_engine
from sqlalchemy.sql import func
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from config import settings

# Create async engine with aiomysql
DATABASE_URL = f"mysql+aiomysql://{settings.DB_USER}:{settings.DB_PASSWORD}@{settings.DB_HOST}:{settings.DB_PORT}/{settings.DB_NAME}"
engine = create_async_engine(
    DATABASE_URL,
    pool_pre_ping=True,  # Verify connections before using
    pool_size=10,  # Connection pool size
    max_overflow=20
)

# Session factory
AsyncSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

# Dependency for FastAPI
async def get_db() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()

# Table definitions (schema metadata)
metadata = MetaData()

tickets = Table(
    'Tickets', metadata,
    Column('ticket_id', Integer, primary_key=True, autoincrement=True),
    Column('ticket_identifier', String(36), unique=True),
    Column('json_data', JSON),
    Column('passenger_id', Integer, ForeignKey('Passengers.passenger_id', ondelete='CASCADE')),
    Column('flight_id', Integer, ForeignKey('Flights.flight_id', ondelete='CASCADE')),
    Column('airline_id', Integer, ForeignKey('Airlines.airline_id', ondelete='CASCADE')),
    Column('modified', TIMESTAMP, server_default=func.now(), onupdate=func.now())
)

# services/ticket_repository.py - Repository using SQLAlchemy Core
from sqlalchemy import select, insert, update
from sqlalchemy.ext.asyncio import AsyncSession

class TicketRepository:
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def get_by_identifier(self, ticket_identifier: str, airline_id: int) -> dict | None:
        # Type-safe query building - still looks like SQL!
        query = select(tickets).where(
            tickets.c.ticket_identifier == ticket_identifier,
            tickets.c.airline_id == airline_id
        )
        result = await self.db.execute(query)
        row = result.fetchone()
        if not row:
            return None
        # Returns dict-like row (not ORM object)
        return dict(row._mapping)
    
    async def create_or_update(self, ticket_data: dict, airline_id: int) -> dict:
        # INSERT ... ON DUPLICATE KEY UPDATE
        stmt = insert(tickets).values(
            json_data=ticket_data,
            airline_id=airline_id,
            # ... other fields
        ).on_duplicate_key_update(
            json_data=ticket_data
        )
        await self.db.execute(stmt)
        await self.db.commit()
        # Return the created/updated row
        return await self.get_by_identifier(ticket_data['ticket_identifier'], airline_id)
    
    async def list_with_stats(self, airline_id: int) -> list[dict]:
        # Complex JOIN query - still type-safe and composable
        from sqlalchemy import func as sql_func
        from database import passengers  # another table definition
        
        query = select(
            tickets.c.ticket_id,
            tickets.c.json_data,
            sql_func.count(passengers.c.passenger_id).label('passenger_count'),
            sql_func.max(passengers.c.modified).label('passenger_last')
        ).select_from(
            tickets.join(passengers, tickets.c.passenger_id == passengers.c.passenger_id)
        ).where(
            tickets.c.airline_id == airline_id
        ).group_by(tickets.c.ticket_id)
        
        result = await self.db.execute(query)
        return [dict(row._mapping) for row in result]
```

**Key Benefits of SQLAlchemy Core for This Project**:
- ✅ **Table definitions are reusable** - define once, use everywhere
- ✅ **Query building is type-safe** - IDE autocomplete, catch typos at dev time
- ✅ **Still explicit SQL** - you see exactly what query is built
- ✅ **Works with dicts/rows** - perfect for JSON column pattern (no object mapping needed)
- ✅ **Connection pooling built-in** - no manual pool management
- ✅ **Much simpler than ORM** - no sessions, relationships, lazy loading complexity
- ✅ **Can still use raw SQL** when needed: `await db.execute(text("SELECT ..."))`

**Side-by-Side Comparison: Same Query in Both Approaches**

**Example: Get ticket by identifier**

**SQLAlchemy Core** (Python code → SQL):
```python
from sqlalchemy import select

# Python code that builds SQL
query = select(tickets).where(
    tickets.c.ticket_identifier == ticket_identifier,
    tickets.c.airline_id == airline_id
)
result = await db.execute(query)
row = result.fetchone()
# SQLAlchemy converts the Python above into:
# SELECT * FROM Tickets WHERE ticket_identifier = ? AND airline_id = ?
```

**Raw aiomysql** (Direct SQL strings):
```python
# You write the SQL string yourself
sql = """
    SELECT * FROM Tickets 
    WHERE ticket_identifier = %s AND airline_id = %s
"""
async with pool.acquire() as conn:
    async with conn.cursor() as cursor:
        await cursor.execute(sql, (ticket_identifier, airline_id))
        row = await cursor.fetchone()
```

**Key Difference**:
- **SQLAlchemy Core**: Write Python expressions (`tickets.c.ticket_identifier == identifier`), SQLAlchemy generates the SQL
- **Raw aiomysql**: Write SQL strings directly (`"SELECT * FROM Tickets WHERE ..."`)

**Why SQLAlchemy Core is Better for Dynamic Queries**:

**SQLAlchemy Core** (composable, type-safe):
```python
# Build query conditionally - still type-safe!
query = select(tickets)
if airline_id:
    query = query.where(tickets.c.airline_id == airline_id)
if ticket_identifier:
    query = query.where(tickets.c.ticket_identifier == ticket_identifier)
# IDE knows tickets.c.airline_id exists, catches typos
```

**Raw aiomysql** (string concatenation, error-prone):
```python
# Build SQL string manually - easy to make mistakes
sql = "SELECT * FROM Tickets WHERE 1=1"
params = []
if airline_id:
    sql += " AND airline_id = %s"  # Typo? No IDE help!
    params.append(airline_id)
if ticket_identifier:
    sql += " AND ticket_identifer = %s"  # Oops, typo! Only caught at runtime
    params.append(ticket_identifier)
```

**Bottom Line**:
- **SQLAlchemy Core**: Python code that looks SQL-like, converts to SQL automatically. Type-safe, composable, IDE-friendly.
- **Raw aiomysql**: Write SQL strings directly. Full control, but no type safety, more boilerplate, easier to make mistakes.

#### 3.3.1 Generic Repository Pattern

Port the PHP `$standardTables` pattern to a reusable Python repository:

**Table Definitions** (`app/database/tables.py`):
```python
from sqlalchemy import Table, Column, Integer, String, JSON, ForeignKey, TIMESTAMP, MetaData
from sqlalchemy.sql import func

metadata = MetaData()

# Table configuration matching PHP $standardTables
TABLE_CONFIG = {
    "Aircrafts": {"links": []},
    "Passengers": {"links": []},
    "Flights": {"links": ["Aircrafts"]},
    "Tickets": {"links": ["Passengers", "Flights"]},
}

airlines = Table(
    "Airlines", metadata,
    Column("airline_id", Integer, primary_key=True, autoincrement=True),
    Column("airline_identifier", String(255), unique=True),
    Column("json_data", JSON),
    Column("modified", TIMESTAMP, server_default=func.now(), onupdate=func.now()),
)

settings = Table(
    "Settings", metadata,
    Column("airline_id", Integer, ForeignKey("Airlines.airline_id", ondelete="CASCADE"), primary_key=True),
    Column("json_data", JSON),
)

aircrafts = Table(
    "Aircrafts", metadata,
    Column("aircraft_id", Integer, primary_key=True, autoincrement=True),
    Column("aircraft_identifier", String(36), unique=True, server_default=func.uuid()),
    Column("json_data", JSON),
    Column("airline_id", Integer, ForeignKey("Airlines.airline_id", ondelete="CASCADE"), nullable=False),
    Column("modified", TIMESTAMP, server_default=func.now(), onupdate=func.now()),
)

passengers = Table(
    "Passengers", metadata,
    Column("passenger_id", Integer, primary_key=True, autoincrement=True),
    Column("passenger_identifier", String(36), unique=True, server_default=func.uuid()),
    Column("json_data", JSON),
    Column("airline_id", Integer, ForeignKey("Airlines.airline_id", ondelete="CASCADE"), nullable=False),
    Column("modified", TIMESTAMP, server_default=func.now(), onupdate=func.now()),
)

flights = Table(
    "Flights", metadata,
    Column("flight_id", Integer, primary_key=True, autoincrement=True),
    Column("flight_identifier", String(36), unique=True, server_default=func.uuid()),
    Column("aircraft_id", Integer, ForeignKey("Aircrafts.aircraft_id", ondelete="CASCADE"), nullable=False),
    Column("json_data", JSON),
    Column("airline_id", Integer, ForeignKey("Airlines.airline_id", ondelete="CASCADE"), nullable=False),
    Column("modified", TIMESTAMP, server_default=func.now(), onupdate=func.now()),
)

tickets = Table(
    "Tickets", metadata,
    Column("ticket_id", Integer, primary_key=True, autoincrement=True),
    Column("ticket_identifier", String(36), unique=True, server_default=func.uuid()),
    Column("passenger_id", Integer, ForeignKey("Passengers.passenger_id", ondelete="CASCADE"), nullable=False),
    Column("flight_id", Integer, ForeignKey("Flights.flight_id", ondelete="CASCADE"), nullable=False),
    Column("json_data", JSON),
    Column("airline_id", Integer, ForeignKey("Airlines.airline_id", ondelete="CASCADE"), nullable=False),
    Column("modified", TIMESTAMP, server_default=func.now(), onupdate=func.now()),
)
```

**Generic Repository** (`app/database/repository.py`):
```python
from typing import TypeVar, Generic, Any
from sqlalchemy import Table, select, insert, delete, func as sql_func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.dialects.mysql import insert as mysql_insert

T = TypeVar("T")


class BaseRepository(Generic[T]):
    """
    Generic repository implementing PHP MyFlyFunDb patterns.
    Provides CRUD operations with airline scoping.
    """

    def __init__(self, table: Table, model_class: type[T]):
        self.table = table
        self.model_class = model_class
        self._table_name = table.name
        self._id_column = f"{table.name[:-1].lower()}_id"  # e.g., "aircraft_id"
        self._identifier_column = f"{table.name[:-1].lower()}_identifier"  # e.g., "aircraft_identifier"

    async def get_by_identifier(
        self, identifier: str, airline_id: int, db: AsyncSession
    ) -> T | None:
        """Get entity by identifier (scoped to airline)."""
        query = select(self.table).where(
            self.table.c[self._identifier_column] == identifier,
            self.table.c.airline_id == airline_id,
        )
        result = await db.execute(query)
        row = result.fetchone()
        return self._row_to_model(row) if row else None

    async def direct_get_by_identifier(
        self, identifier: str, db: AsyncSession
    ) -> T | None:
        """
        Get entity by identifier WITHOUT airline scoping.
        Used for public endpoints (e.g., boarding pass display).
        Matches PHP directGet() pattern.
        """
        query = select(self.table).where(
            self.table.c[self._identifier_column] == identifier
        )
        result = await db.execute(query)
        row = result.fetchone()
        return self._row_to_model(row) if row else None

    async def list_all(
        self, airline_id: int, db: AsyncSession
    ) -> list[T]:
        """List all entities for airline."""
        query = select(self.table).where(
            self.table.c.airline_id == airline_id
        )
        result = await db.execute(query)
        return [self._row_to_model(row) for row in result.fetchall()]

    async def list_with_stats(
        self, airline_id: int, db: AsyncSession, join_tables: list[Table]
    ) -> list[dict[str, Any]]:
        """
        List entities with COUNT and MAX(modified) stats from related tables.
        Matches PHP listStats() pattern.
        """
        table_ref = self.table
        select_cols = [table_ref]

        joins = []
        for join_table in join_tables:
            join_id = f"{join_table.name[:-1].lower()}_id"
            count_alias = f"{join_table.name.lower()}_count"
            last_alias = f"{join_table.name.lower()}_last"

            select_cols.extend([
                sql_func.count(join_table.c[join_id]).label(count_alias),
                sql_func.max(join_table.c.modified).label(last_alias),
            ])
            joins.append((join_table, table_ref.c[self._id_column] == join_table.c[self._id_column]))

        query = select(*select_cols).select_from(table_ref)
        for join_table, condition in joins:
            query = query.outerjoin(join_table, condition)

        query = query.where(table_ref.c.airline_id == airline_id)
        query = query.group_by(table_ref.c[self._id_column])

        result = await db.execute(query)
        return [dict(row._mapping) for row in result.fetchall()]

    async def create_or_update(
        self, data: dict[str, Any], airline_id: int, db: AsyncSession
    ) -> T:
        """
        Create or update entity (upsert).
        Matches PHP createOrUpdate() pattern.
        """
        insert_data = {
            "json_data": data,
            "airline_id": airline_id,
        }

        # Add identifier if provided
        if self._identifier_column in data:
            insert_data[self._identifier_column] = data[self._identifier_column]

        # MySQL INSERT ... ON DUPLICATE KEY UPDATE
        stmt = mysql_insert(self.table).values(**insert_data)
        stmt = stmt.on_duplicate_key_update(json_data=data)

        await db.execute(stmt)
        await db.commit()

        # Retrieve the created/updated entity
        identifier = data.get(self._identifier_column)
        if identifier:
            return await self.get_by_identifier(identifier, airline_id, db)
        return None

    async def delete_by_identifier(
        self, identifier: str, airline_id: int, db: AsyncSession
    ) -> bool:
        """Delete entity by identifier."""
        stmt = delete(self.table).where(
            self.table.c[self._identifier_column] == identifier,
            self.table.c.airline_id == airline_id,
        )
        result = await db.execute(stmt)
        await db.commit()
        return result.rowcount > 0

    def _row_to_model(self, row) -> T:
        """Convert database row to model instance."""
        if row is None:
            return None
        row_dict = dict(row._mapping)
        json_data = row_dict.get("json_data", {})
        # Merge identifiers into json_data
        json_data[self._id_column] = row_dict.get(self._id_column)
        json_data[self._identifier_column] = row_dict.get(self._identifier_column)
        return self.model_class.model_validate(json_data)


# Concrete repositories
class AircraftRepository(BaseRepository["Aircraft"]):
    def __init__(self):
        from app.database.tables import aircrafts
        from app.models.aircraft import Aircraft
        super().__init__(aircrafts, Aircraft)


class PassengerRepository(BaseRepository["Passenger"]):
    def __init__(self):
        from app.database.tables import passengers
        from app.models.passenger import Passenger
        super().__init__(passengers, Passenger)


class FlightRepository(BaseRepository["Flight"]):
    def __init__(self):
        from app.database.tables import flights
        from app.models.flight import Flight
        super().__init__(flights, Flight)


class TicketRepository(BaseRepository["Ticket"]):
    def __init__(self):
        from app.database.tables import tickets
        from app.models.ticket import Ticket
        super().__init__(tickets, Ticket)
```

**Usage in Routers:**
```python
from app.database.repository import AircraftRepository
from app.database.tables import flights

@router.get("/list")
async def list_aircraft(airline: CurrentAirline, db: DbSession):
    repo = AircraftRepository()
    # List with flight count and last flight date
    return await repo.list_with_stats(airline.airline_id, db, [flights])
```

#### 3.4 PKPass Generation

**Challenge**: PHP PKPass library needs Python equivalent.

**Solution Options**:

1. **`passes-rs-py`** (Recommended) ✅:
   - Rust-based library with Python bindings (high performance)
   - Comprehensive: read, parse, build, sign, package `.pkpass` files
   - Supports all Wallet Pass standard features
   - Well-documented with examples and API references
   - Install: `pip install passes-rs-py`
   - **Pros**: Fast, feature-complete, actively maintained, high performance
   - **Cons**: Requires Rust runtime (handled by pip install)

2. **`py-pkpass`** (Alternative):
   - Pure Python solution available on PyPI
   - Direct pass generation without filesystem storage
   - Supports password-less keys
   - Includes validation of fields and passes
   - Install: `pip install py-pkpass`
   - **Pros**: Pure Python, simple API, no external dependencies
   - **Cons**: May have fewer features, less performance

3. **Custom Implementation**:
   - Port PHP PKPass library logic to Python
   - Create pass.json structure
   - Add images and localization files
   - Sign with Apple certificate using `cryptography` library
   - Create ZIP archive
   - **Pros**: Full control, matches PHP behavior exactly
   - **Cons**: More maintenance, need to implement all features

**Recommendation**: Use `passes-rs-py` for best performance and feature completeness. If it doesn't meet specific needs, evaluate `py-pkpass` or consider custom implementation.

#### 3.5 Signature/Cryptography

**Current**: OpenSSL operations in PHP.

**Solution**:
- Use Python `cryptography` library
- Maintain same RSA key generation and signing algorithms
- Ensure key file format compatibility
- Mirror the behavior of `Signature.php` via a `SignatureService`:
  - Keys are stored under the same `keys/` directory, using the same `{baseName}.pem` / `{baseName}.pub` convention.
  - Support both secret-based hashes and optional RSA signatures, controlled by a `USE_PUBLIC_KEY_SIGNATURE` config flag (matching `use_public_key_signature` in PHP).
  - Provide high-level methods like `signature_digest(data)` and `verify_signature_digest(data, digest)` that wrap the hash and signature logic in one place.
- Keep `Ticket` and `Airline` Python models thin: they should delegate to `SignatureService` for `signature()` / `verify()` behavior instead of duplicating hashing or key-handling logic.

#### 3.6 Airport Database Access

**Current**: PHP reads from SQLite `airports.db` file directly using PDO.

**Solution**:
- **DO NOT read `airports.db` directly** - use the `euro_aip` library instead
- The `euro_aip` library provides a modern query API for airport data
- All airport information, runways, procedures, AIP data, and border crossings should come from `EuroAipModel`
- Library location: `~/Developer/public/rzflight/euro_aip/`
- Documentation: See `~/Developer/public/rzflight/euro_aip/designs/models_query_api_documentation.md`

**Installation** (local library - not on PyPI):
```bash
# Option 1: Install as editable package (recommended for development)
pip install -e ~/Developer/public/rzflight/euro_aip/

# Option 2: Add to pyproject.toml as path dependency
# [project]
# dependencies = [
#     "euro-aip @ file:///Users/brice/Developer/public/rzflight/euro_aip"
# ]

# Option 3: For Docker deployment, copy or mount the library
# COPY --from=euro_aip /app /app/euro_aip
# Or use git submodule in the server directory
```

**Note**: Since `euro_aip` is a local/private library, ensure it's available in the deployment environment. Consider:
- Publishing to a private PyPI server
- Using git submodules
- Bundling the library code in the Docker image

**Implementation**:
```python
from euro_aip.models import EuroAipModel
from pathlib import Path
from config import settings

# Load model (one-time or cached)
model = EuroAipModel.from_file(settings.AIRPORT_DB_PATH)

# Query airports using collection API
airport = model.airports['EGLL']  # Dict-style lookup by ICAO
french_airports = model.airports.by_country("FR").all()
airports_with_ils = model.airports.with_approach_type("ILS").all()

# Access airport data
if airport:
    runways = airport.runways
    procedures = airport.procedures
    aip_data = airport.aip_entries
```

**Key Points**:
- ✅ Use `EuroAipModel.from_file()` to load the model
- ✅ Use collection API (`model.airports`, `model.procedures`) for queries
- ✅ Dict-style access: `model.airports['ICAO']` for single lookups
- ✅ Filter methods: `.by_country()`, `.with_runways()`, `.with_approach_type()`, etc.
- ❌ **Never** use direct SQLite queries on `airports.db`
- ❌ **Never** use `sqlite3` or `aiosqlite` to read the database directly

#### 3.7 Airline Authentication

**Current**: Bearer token = Apple identifier, validated per request.

**Solution**:
- Use FastAPI dependency injection (see Section 2.3) - `get_airline_context()` dependency
- Dependency extracts airline_identifier from URL path parameter
- Validates bearer token matches airline's apple_identifier
- Returns `AirlineContext` object with airline and airline_id
- **Public endpoints** (no auth dependency):
  - `/health` endpoint
  - `/v1/status` endpoint
  - `/pages/*` routes (web pages are public, read-only)
  - `/static/*` routes (static files)
  - `/v1/boardingpass/{ticket_id}` (public router, determines airline from ticket)

### 4. Migration Strategy

#### Phase 1: Setup & Infrastructure
1. Set up Python/FastAPI project structure
2. Configure database connection (MySQL)
3. Implement configuration management
4. Set up development environment
5. Create database table definitions (SQLAlchemy Core - Table objects, not ORM models)

#### Phase 2: Core Services
1. Implement dependency injection for airline authentication (`app/dependencies.py`)
2. Implement database connection and table definitions (`app/database/`)
3. Implement generic repository pattern (`app/database/repository.py`)
4. Implement signature service (`app/services/signature_service.py`)
5. Implement PKPass service (`app/services/pkpass_service.py`)
6. Implement airport service using euro_aip (`app/services/airport_service.py`)

#### Phase 3: API Endpoints (Develop in Parallel)
1. **Airline endpoints** (critical for auth)
2. **Aircraft endpoints**
3. **Passenger endpoints**
4. **Flight endpoints**
5. **Ticket endpoints**
6. **BoardingPass endpoints**
7. **Settings endpoints**
8. **Status/Db endpoints**

#### Phase 4: Testing & Validation
1. Unit tests for services
2. Integration tests for API endpoints
3. End-to-end tests with iOS app
4. Performance testing
5. Security audit

#### Phase 5: Deployment
1. **Docker Setup**: Create Dockerfile and docker-compose.yml
2. **Caddy Configuration**: Set up Caddy reverse proxy with automatic SSL
3. **Test Server Deployment**: Deploy to test/staging server
4. **Comprehensive Testing**: Full endpoint testing on test server
5. **Production Migration**: Big bang cutover to production server
6. **PHP Server Decommission**: Remove PHP server after successful migration

**Deployment Decisions** ✅ **FINALIZED**:
- **Server Setup**: ✅ **Independent Docker container** - Completely separate from PHP server
- **Process Manager**: ✅ **Docker** - Containerized deployment for portability
- **Reverse Proxy**: ✅ **Caddy** - Automatic SSL certificate management and reverse proxy
- **Port Configuration**: ✅ **8000** (internal container port, Caddy handles external routing)
- **SSL/TLS**: ✅ **Caddy automatic certificates** - Let's Encrypt via Caddy
- **Migration Strategy**: ✅ **Big Bang** - All endpoints implemented, tested on test server, then production cutover
- **Monitoring**: Logging, metrics, error tracking setup

### 5. Technology Choices

#### 5.1 FastAPI Framework
- **Why**: Modern, fast, async support, automatic OpenAPI docs
- **Alternatives**: Flask, Django REST Framework, Starlette

#### 5.2 Database Layer
- **Recommended**: **SQLAlchemy Core** (not full ORM) with aiomysql
- **Why**: 
  - Type-safe query building without ORM complexity
  - Table metadata for schema definition
  - Connection pooling and transaction management built-in
  - Works with dicts/rows (perfect for JSON column pattern)
  - Much simpler learning curve than full ORM
  - Still allows raw SQL when needed
- **Alternatives**: 
  - Full SQLAlchemy ORM (if you want object mapping - not needed here)
  - Raw aiomysql (if you prefer pure SQL strings)

#### 5.3 PKPass Library
- **Chosen**: `passes-rs-py` ✅
- **Why**:
  - Rust-based with Python bindings (high performance)
  - Comprehensive: read, parse, build, sign, package `.pkpass` files
  - Supports all Wallet Pass standard features
  - Well-documented with examples
  - Install: `pip install passes-rs-py`
- **Alternatives** (if needed):
  - `py-pkpass` - Pure Python solution (fallback option)
  - Custom implementation - Only if libraries don't meet specific needs

#### 5.4 Configuration Management
- **Recommended**: `pydantic-settings` with `.env` files
- **Why**: 
  - Type-safe configuration with validation
  - Environment variable support (works with Docker, cloud deployments)
  - `.env` files for local development (gitignored)
  - `.env.sample` template for documentation
  - Automatic type conversion and validation

#### 5.5 Testing Framework
- **Recommended**: `pytest` with `httpx` for async testing
- **Why**: Industry standard, excellent async support

### 6. API Compatibility Matrix

**Complete endpoint mapping** (based on `tests/test.zsh` and controller analysis):

| PHP Endpoint | FastAPI Equivalent | HTTP Method | Compatibility |
|-------------|-------------------|-------------|---------------|
| **Database & Status** |
| `v1/db/setup` | `POST /v1/db/setup` | POST | ✅ Full |
| `v1/status` | `GET /v1/status` | GET | ✅ Full |
| **Airline** |
| `v1/airline/create` | `POST /v1/airline/create` | POST | ✅ Full |
| `v1/airline/{id}` | `GET /v1/airline/{id}` | GET | ✅ Full |
| `v1/airline/{id}/keys` | `GET /v1/airline/{id}/keys` | GET | ✅ Full |
| `v1/airline/{id}` | `DELETE /v1/airline/{id}` | DELETE | ✅ Full |
| **Aircraft** |
| `v1/airline/{id}/aircraft/create` | `POST /v1/airline/{id}/aircraft/create` | POST | ✅ Full |
| `v1/airline/{id}/aircraft/list` | `GET /v1/airline/{id}/aircraft/list` | GET | ✅ Full |
| `v1/airline/{id}/aircraft/{aircraft_id}` | `GET /v1/airline/{id}/aircraft/{aircraft_id}` | GET | ✅ Full |
| `v1/airline/{id}/aircraft/{aircraft_id}/flights` | `GET /v1/airline/{id}/aircraft/{aircraft_id}/flights` | GET | ✅ Full |
| `v1/airline/{id}/aircraft/{aircraft_id}` | `DELETE /v1/airline/{id}/aircraft/{aircraft_id}` | DELETE | ✅ Full |
| **Passenger** |
| `v1/airline/{id}/passenger/create` | `POST /v1/airline/{id}/passenger/create` | POST | ✅ Full |
| `v1/airline/{id}/passenger/list` | `GET /v1/airline/{id}/passenger/list` | GET | ✅ Full |
| `v1/airline/{id}/passenger/{passenger_id}` | `GET /v1/airline/{id}/passenger/{passenger_id}` | GET | ✅ Full |
| `v1/airline/{id}/passenger/{passenger_id}/tickets` | `GET /v1/airline/{id}/passenger/{passenger_id}/tickets` | GET | ✅ Full |
| **Flight** |
| `v1/airline/{id}/flight/plan/{aircraft_id}` | `POST /v1/airline/{id}/flight/plan/{aircraft_id}` | POST | ✅ Full |
| `v1/airline/{id}/flight/amend/{flight_id}` | `POST /v1/airline/{id}/flight/amend/{flight_id}` | POST | ✅ Full |
| `v1/airline/{id}/flight/list` | `GET /v1/airline/{id}/flight/list` | GET | ✅ Full |
| `v1/airline/{id}/flight/{flight_id}` | `GET /v1/airline/{id}/flight/{flight_id}` | GET | ✅ Full |
| `v1/airline/{id}/flight/{flight_id}/tickets` | `GET /v1/airline/{id}/flight/{flight_id}/tickets` | GET | ✅ Full |
| `v1/airline/{id}/flight/{flight_id}` | `DELETE /v1/airline/{id}/flight/{flight_id}` | DELETE | ✅ Full |
| `v1/airline/{id}/flight/check/{flight_id}` | `POST /v1/airline/{id}/flight/check/{flight_id}` | POST | ⚠️ To be implemented |
| **Ticket** |
| `v1/airline/{id}/ticket/issue/{flight_id}/{passenger_id}` | `POST /v1/airline/{id}/ticket/issue/{flight_id}/{passenger_id}` | POST | ✅ Full |
| `v1/airline/{id}/ticket/list` | `GET /v1/airline/{id}/ticket/list` | GET | ✅ Full |
| `v1/airline/{id}/ticket/{ticket_id}` | `GET /v1/airline/{id}/ticket/{ticket_id}` | GET | ✅ Full |
| `v1/airline/{id}/ticket/{ticket_id}` | `DELETE /v1/airline/{id}/ticket/{ticket_id}` | DELETE | ✅ Full |
| `v1/airline/{id}/ticket/verify` | `POST /v1/airline/{id}/ticket/verify` | POST | ✅ Full |
| **Boarding Pass** |
| `v1/airline/{id}/boardingpass/{ticket_id}` | `GET /v1/airline/{id}/boardingpass/{ticket_id}` | GET | ✅ Full |
| `v1/airline/{id}/boardingpass/{ticket_id}?debug` | `GET /v1/airline/{id}/boardingpass/{ticket_id}?debug` | GET | ✅ Full |
| `v1/boardingpass/{ticket_id}` | `GET /v1/boardingpass/{ticket_id}` | GET | ✅ Full (used for user-facing links, determines airline from ticket)
| **Web Pages (HTML)** |
| `pages/yourBoardingPass?ticket={id}` | `GET /pages/yourBoardingPass?ticket={id}` | GET | ✅ Full |
| `pages/airports` | `GET /pages/airports` | GET | ✅ Full |
| **Settings** |
| `v1/airline/{id}/settings` | `GET /v1/airline/{id}/settings` | GET | ✅ Full |
| `v1/airline/{id}/settings` | `POST /v1/airline/{id}/settings` | POST | ✅ Full |
| **Airport** |
| `v1/airport/{icao}` | `GET /v1/airport/{icao}` | GET | ⚠️ If implemented |

**Note**: All endpoints maintain **100% JSON response compatibility** with PHP version. See Section 10.1 for detailed test coverage requirements.

### 7. Potential Challenges & Solutions

#### Challenge 1: URL Routing Differences
- **Status**: ✅ **Resolved** - No issue!
- **Clarification**: iOS app already uses path-based routing; Apache was remapping to query params
- **Solution**: FastAPI will use native path-based routing matching the iOS app's original paths

#### Challenge 2: JSON Serialization Differences
- **Issue**: PHP uses custom `JsonHelper` with specific behaviors:
  - Omits fields matching default values (e.g., `flight_id: -1` is omitted)
  - Custom DateTime/DateInterval formatting
  - Recursive nested object serialization
  - `uniqueIdentifier()` method adds extra fields
- **Solution**: 
  - Use Pydantic with `exclude_defaults=True` to match PHP behavior
  - Create custom serializers for DateTime (ISO 8601 'c' format) and DateInterval (ISO 8601 duration)
  - Implement `uniqueIdentifier()` equivalent in Pydantic models
  - Test JSON output matches PHP output exactly

#### Challenge 3: PKPass Generation
- **Issue**: Need Python library for Apple Wallet PKPass generation
- **Solution Options**:
  1. **`passes-rs-py`** (Recommended) ✅:
     - Rust-based with Python bindings (high performance)
     - Comprehensive: read, parse, build, sign, package `.pkpass` files
     - Supports all Wallet Pass features
     - Well-documented with examples
     - Install: `pip install passes-rs-py`
  2. **`py-pkpass`** (Alternative):
     - Pure Python solution available on PyPI
     - Direct pass generation without filesystem storage
     - Supports password-less keys and validation
     - Simple, well-documented API
     - Install: `pip install py-pkpass`
  3. **Custom Implementation**:
     - Port PHP PKPass library logic
     - Full control but more maintenance
- **Recommendation**: Start with `passes-rs-py` for best performance and feature completeness. If it doesn't meet specific needs, evaluate `py-pkpass` or consider custom implementation.

#### Challenge 4: Database Connection Pooling
- **Issue**: PHP uses persistent connections, Python needs pooling
- **Solution**: Use async connection pool (aiomysql)

#### Challenge 5: File System Operations
- **Issue**: Key files, certificates, images need consistent paths
- **Solution**: 
  - Created `.env` and `.env.sample` for environment-based configuration management
  - All file paths defined in config (certificates, keys, images, airport DB)
  - Use `pathlib.Path` for cross-platform path handling
  - Maintain same directory structure as PHP version for easy migration
  - Config uses BASE_DIR relative paths for portability

### 8. Performance Considerations

#### Advantages of FastAPI:
- Async/await support for I/O operations
- Better connection pooling
- Automatic request validation
- Built-in OpenAPI documentation

#### Optimization Opportunities:
- Database query optimization
- Caching for airport data
- Async PKPass generation
- Connection pooling

### 9. Security Considerations

1. **Authentication**: Maintain same bearer token mechanism
2. **SQL Injection**: Use parameterized queries (SQLAlchemy handles this)
3. **Certificate Security**: Secure storage of Apple certificates
4. **Key Management**: Secure storage of private keys
5. **Input Validation**: Pydantic automatic validation
6. **Web Pages Security**: 
   - Web pages (`/pages/*`) are publicly accessible (read-only, no authentication required)
   - Ticket identifiers are sufficiently random/secure
   - No write operations allowed from web pages
   - Consider rate limiting for production deployment
7. **Error Responses**: Standardize on JSON error format for all API endpoints
   ```json
   {"detail": "Error message", "status_code": 400}
   ```

#### 9.1 Error Handling Implementation

**Custom Exception Classes** (`app/core/exceptions.py`):
```python
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from pydantic import ValidationError


class APIError(Exception):
    """Base API error with status code and detail."""
    def __init__(self, status_code: int, detail: str):
        self.status_code = status_code
        self.detail = detail


class NotFoundError(APIError):
    """Resource not found (404)."""
    def __init__(self, resource: str, identifier: str):
        super().__init__(404, f"{resource} '{identifier}' not found")


class AuthenticationError(APIError):
    """Authentication failed (401)."""
    def __init__(self, detail: str = "Invalid Bearer Token"):
        super().__init__(401, detail)


class AuthorizationError(APIError):
    """Authorization failed (403)."""
    def __init__(self, detail: str = "Access denied"):
        super().__init__(403, detail)


def register_exception_handlers(app: FastAPI) -> None:
    """Register custom exception handlers for consistent error responses."""

    @app.exception_handler(APIError)
    async def api_error_handler(request: Request, exc: APIError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": exc.detail, "status_code": exc.status_code}
        )

    @app.exception_handler(HTTPException)
    async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": exc.detail, "status_code": exc.status_code}
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(
        request: Request, exc: RequestValidationError
    ) -> JSONResponse:
        """Handle Pydantic validation errors with user-friendly messages."""
        errors = []
        for error in exc.errors():
            field = ".".join(str(x) for x in error["loc"][1:])  # Skip 'body' prefix
            errors.append(f"{field}: {error['msg']}")
        return JSONResponse(
            status_code=422,
            content={
                "detail": "; ".join(errors),
                "status_code": 422,
                "errors": exc.errors()  # Include full error details for debugging
            }
        )

    @app.exception_handler(Exception)
    async def generic_exception_handler(request: Request, exc: Exception) -> JSONResponse:
        """Catch-all for unexpected errors."""
        import logging
        logging.exception("Unhandled exception")
        return JSONResponse(
            status_code=500,
            content={"detail": "Internal server error", "status_code": 500}
        )
```

**Usage in Routers:**
```python
from app.core.exceptions import NotFoundError, AuthenticationError

@router.get("/{aircraft_identifier}")
async def get_aircraft(
    aircraft_identifier: str,
    airline: CurrentAirline,
    db: DbSession,
):
    aircraft = await repo.get_by_identifier(aircraft_identifier, airline.airline_id, db)
    if not aircraft:
        raise NotFoundError("Aircraft", aircraft_identifier)
    return aircraft
```

### 10. Testing Strategy

1. **Unit Tests**: Services, utilities, models
2. **Integration Tests**: API endpoints with test database
3. **E2E Tests**: Full flow with iOS app
4. **Load Tests**: Performance under load
5. **Security Tests**: Authentication, authorization, input validation
6. **Location**: Python tests live in the top-level `tests/` directory and use `pytest`, `pytest-asyncio`, and `httpx` for async endpoint testing.

**Logging Strategy**:
- Use Python's built-in `logging` module
- Log level configurable via `.env` (`LOG_LEVEL`)
- Output destination configurable via `.env` (`LOG_FILE` for file, or stdout if not set)
- Format: Structured logging (JSON format recommended for production)
- Log all API requests with timing, status codes, and errors

#### 10.1 Comprehensive Test Coverage Matrix

Based on the existing test suite (`tests/test.zsh`) and controller analysis, the following endpoints **must** be implemented and tested. This serves as the complete checklist for migration validation:

**Database Management:**
- ✅ `POST /v1/db/setup` - Initialize database tables (system auth required)
- ✅ `GET /v1/status` - Health check endpoint (includes database connectivity check)

**Airline Endpoints:**
- ✅ `POST /v1/airline/create` - Create or update airline (from Apple identifier)
- ✅ `GET /v1/airline/{airline_identifier}` - Get airline by identifier
- ✅ `GET /v1/airline/{airline_identifier}/keys` - Get airline's public keys
- ✅ `DELETE /v1/airline/{airline_identifier}` - Delete airline (if implemented)

**Aircraft Endpoints:**
- ✅ `POST /v1/airline/{airline_identifier}/aircraft/create` - Create aircraft
- ✅ `GET /v1/airline/{airline_identifier}/aircraft/list` - List all aircraft (with stats)
- ✅ `GET /v1/airline/{airline_identifier}/aircraft/{aircraft_identifier}` - Get specific aircraft
- ✅ `GET /v1/airline/{airline_identifier}/aircraft/{aircraft_identifier}/flights` - Get flights for aircraft
- ✅ `DELETE /v1/airline/{airline_identifier}/aircraft/{aircraft_identifier}` - Delete aircraft

**Passenger Endpoints:**
- ✅ `POST /v1/airline/{airline_identifier}/passenger/create` - Create passenger
- ✅ `GET /v1/airline/{airline_identifier}/passenger/list` - List all passengers (with stats)
- ✅ `GET /v1/airline/{airline_identifier}/passenger/{passenger_identifier}` - Get specific passenger
- ✅ `GET /v1/airline/{airline_identifier}/passenger/{passenger_identifier}/tickets` - Get tickets for passenger
- ✅ `DELETE /v1/airline/{airline_identifier}/passenger/{passenger_identifier}` - Delete passenger (if implemented)

**Flight Endpoints:**
- ✅ `POST /v1/airline/{airline_identifier}/flight/plan/{aircraft_identifier}` - Plan/create flight
- ✅ `POST /v1/airline/{airline_identifier}/flight/amend/{flight_identifier}` - Update existing flight
- ✅ `GET /v1/airline/{airline_identifier}/flight/list` - List all flights (with stats)
- ✅ `GET /v1/airline/{airline_identifier}/flight/{flight_identifier}` - Get specific flight
- ✅ `GET /v1/airline/{airline_identifier}/flight/{flight_identifier}/tickets` - Get tickets for flight
- ✅ `DELETE /v1/airline/{airline_identifier}/flight/{flight_identifier}` - Delete flight
- ⚠️ `POST /v1/airline/{airline_identifier}/flight/check/{flight_identifier}` - Check flight (to be implemented - verify functionality)

**Ticket Endpoints:**
- ✅ `POST /v1/airline/{airline_identifier}/ticket/issue/{flight_identifier}/{passenger_identifier}` - Issue ticket
- ✅ `GET /v1/airline/{airline_identifier}/ticket/list` - List all tickets
- ✅ `GET /v1/airline/{airline_identifier}/ticket/{ticket_identifier}` - Get specific ticket
- ✅ `DELETE /v1/airline/{airline_identifier}/ticket/{ticket_identifier}` - Delete ticket
- ✅ `POST /v1/airline/{airline_identifier}/ticket/verify` - Verify ticket signature

**Boarding Pass Endpoints:**
- ✅ `GET /v1/airline/{airline_identifier}/boardingpass/{ticket_identifier}` - Generate PKPass file
- ✅ `GET /v1/airline/{airline_identifier}/boardingpass/{ticket_identifier}?debug` - Get PKPass JSON (debug mode)
- ✅ `GET /v1/boardingpass/{ticket_identifier}` - Direct boarding pass (no airline prefix - used for user-facing links, airline determined from ticket)

**Web Pages (User-Facing HTML):**
- ✅ `GET /pages/yourBoardingPass?ticket={ticket_identifier}` - Display boarding pass HTML page
  - Shows disclaimer in detected language
  - Displays boarding pass card with QR code
  - "Add to Apple Wallet" button (links to PKPass download)
  - Language switcher (en, fr, de, es)
- ✅ `GET /pages/yourBoardingPass?ticket={ticket_identifier}&lang={lang}` - Display with specific language
- ✅ `GET /pages/airports` - Airport information lookup page
- ✅ Static file serving: `/static/images/`, `/static/js/`, `/static/css/`

**Settings Endpoints:**
- ✅ `GET /v1/airline/{airline_identifier}/settings` - Get airline settings
- ✅ `POST /v1/airline/{airline_identifier}/settings` - Update airline settings

**Airport Endpoints:**
- ✅ `GET /v1/airport/{icao_code}` - Get airport information (if implemented)

**Test Data Requirements:**
- Sample JSON files in `app/flyfunboarding/Preview Content/`:
  - `sample_airline.json`
  - `sample_aircraft.json`, `sample_aircraft_2.json`
  - `sample_passenger.json`, `sample_passenger_2.json`
  - `sample_flight.json`, `sample_flights.json`
  - `sample_ticket.json`
  - `sample_validate.json`

**Test Execution Strategy:**
1. **Sequential Flow**: Tests should follow the dependency order:
   - Setup DB → Create Airline → Create Aircraft → Create Passengers → Plan Flight → Issue Ticket → Generate Boarding Pass
2. **Isolation**: Each test should be able to run independently (cleanup or use unique identifiers)
3. **Response Validation**: 
   - Verify JSON structure matches PHP output exactly
   - Verify default value omission (fields with `-1` or `""` should be excluded)
   - Verify DateTime formatting (ISO 8601 'c' format)
   - Verify nested object serialization
4. **Error Cases**: Test 404, 401, 400 responses for invalid inputs
5. **Authentication**: Test with valid/invalid bearer tokens
6. **PKPass Validation**: Verify generated `.pkpass` file structure and signature

**Python Test Implementation Example:**
```python
# tests/test_ticket_endpoints.py
import pytest
from httpx import AsyncClient
from main import app

@pytest.mark.asyncio
async def test_issue_ticket(airline_id, flight_id, passenger_id):
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post(
            f"/v1/airline/{airline_id}/ticket/issue/{flight_id}/{passenger_id}",
            json={"seatNumber": "12A", "customLabelValue": "1"},
            headers={"Authorization": f"Bearer {bearer_token}"}
        )
        assert response.status_code == 200
        data = response.json()
        assert "ticket_identifier" in data
        assert data["seatNumber"] == "12A"
        # Verify defaults are omitted
        assert "ticket_id" not in data or data["ticket_id"] != -1
```

**Migration Validation Checklist:**
- [ ] All endpoints from test.zsh implemented
- [ ] All endpoints return identical JSON structure to PHP version
- [ ] All endpoints handle authentication correctly
- [ ] All endpoints handle error cases (404, 401, 400)
- [ ] PKPass generation produces valid `.pkpass` files
- [ ] Ticket verification works with signature digests
- [ ] Stats queries (list with JOINs) return correct counts and timestamps
- [ ] CASCADE deletes work correctly (delete airline → deletes all related data)
- [ ] JSON serialization matches PHP output byte-for-byte

### 11. Deployment Considerations

**Deployment Architecture**:
- **Docker-based**: Application runs in Docker container for portability
- **Caddy Reverse Proxy**: Handles SSL/TLS termination and routing to FastAPI
- **Independent Server**: Complete replacement of PHP server (no parallel running)
- **Big Bang Migration**: All endpoints implemented and tested before production cutover

**Implementation Details**:

1. **Docker Configuration**:
   - Dockerfile for FastAPI application
   - docker-compose.yml for orchestration (if needed)
   - Environment variables for configuration
   - Volume mounts for certificates, keys, and images
   - Health checks for container monitoring

2. **Caddy Configuration**:
   - Automatic SSL certificate management (Let's Encrypt)
   - Reverse proxy to FastAPI container (port 8000)
   - HTTP to HTTPS redirect
   - Request logging
   - Error handling

3. **Environment Variables**: All secrets in environment (Docker secrets or env files)
4. **Monitoring**: Logging, metrics, error tracking
5. **Note**: No database migrations needed - schema remains unchanged
6. **Test Server**: Deploy to test server first for validation before production

### 12. Rollback Plan

**Big Bang Migration Strategy**:
1. **Pre-Migration**: PHP server remains running until FastAPI is fully tested
2. **Test Server Validation**: Complete testing on test server before production
3. **Production Cutover**: Switch DNS/routing to FastAPI server when ready
4. **Rollback Option**: Keep PHP server available for 24-48 hours post-migration
   - If critical issues arise, can quickly switch back to PHP
   - DNS/routing can be reverted to PHP server
5. **Post-Migration**: After successful validation period, PHP server is decommissioned

**Risk Mitigation**:
- Comprehensive testing on test server before production
- Database backup before migration
- Monitor error rates and performance closely after cutover
- Keep PHP server running (but not receiving traffic) for quick rollback if needed

## Next Steps

1. **Review & Approval**: Review this design document
2. **Proof of Concept**: Implement one endpoint (e.g., airline) to validate approach
3. **Detailed Planning**: Break down into tasks and estimate effort
4. **Development**: Implement all endpoints (Phases 1-3)
5. **Testing**: Comprehensive testing at each phase
6. **Docker Setup**: Create Dockerfile and docker-compose.yml
7. **Caddy Configuration**: Set up Caddy reverse proxy configuration
8. **Test Server Deployment**: Deploy to test server and validate all endpoints
9. **Production Migration**: Big bang cutover to production server
10. **PHP Decommission**: Remove PHP server after successful migration validation

## Appendix

### A. Dependencies (`pyproject.toml`)

**Modern Python packaging** using `pyproject.toml` (PEP 621) instead of `requirements.txt`:

```toml
[project]
name = "flyfun-boarding-api"
version = "1.0.0"
description = "Fly Fun Boarding API - FastAPI backend"
readme = "README.md"
requires-python = ">=3.13"
license = {text = "MIT"}
authors = [
    {name = "Your Name", email = "you@example.com"}
]

dependencies = [
    # Web Framework
    "fastapi>=0.115.0",
    "uvicorn[standard]>=0.32.0",

    # Database
    "sqlalchemy>=2.0.36",     # Using SQLAlchemy Core (query building), not full ORM
    "aiomysql>=0.2.0",        # Async MySQL driver

    # Data Validation & Serialization
    "pydantic>=2.10.0",
    "pydantic-settings>=2.6.0",

    # PKPass Generation
    "passes-rs-py>=0.1.0",    # Rust-based, high-performance PKPass library

    # Cryptography
    "cryptography>=44.0.0",

    # Utilities
    "python-multipart>=0.0.12",
    "python-dotenv>=1.0.0",

    # Language Detection & Templates
    "babel>=2.16.0",          # Internationalization with Accept-Language parsing
    "jinja2>=3.1.4",          # HTML template engine for web pages

    # HTTP Client (for health checks, external APIs)
    "httpx>=0.28.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.3.0",
    "pytest-asyncio>=0.24.0",
    "httpx>=0.28.0",          # For async testing
    "ruff>=0.8.0",            # Fast Python linter
    "mypy>=1.13.0",           # Type checking
]

[project.scripts]
# Optional: CLI entry point
flyfun-api = "app.main:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["app"]

[tool.ruff]
target-version = "py313"
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM"]  # Common rules + import sorting

[tool.mypy]
python_version = "3.13"
strict = true
plugins = ["pydantic.mypy"]

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
```

**Installation:**
```bash
# Development install (editable)
pip install -e ".[dev]"

# Production install
pip install .

# Or using uv (faster)
uv pip install -e ".[dev]"
```

**Benefits of `pyproject.toml`:**
- ✅ Single source of truth for project metadata
- ✅ PEP 621 standard (works with pip, uv, poetry, hatch)
- ✅ Optional dependencies for dev/test
- ✅ Tool configuration (ruff, mypy, pytest) in one file
- ✅ Proper package structure for imports (`from app.config import settings`)

### B. Configuration

**Environment-based Configuration** (Recommended):
- Copy `server/.env.sample` to `server/.env`
- Update values in `.env` with your actual credentials and paths
- Never commit `.env` to version control (add to `.gitignore`)
- `.env.sample` serves as documentation and template

**Configuration Loading** (`server/config.py`):
```python
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional

class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore"
    )
    
    # Base directory (for relative paths)
    BASE_DIR: Path = Path(__file__).parent.parent
    
    # Apple Wallet PKPass Configuration
    CERTIFICATE_PATH: Path = BASE_DIR / "certs" / "certificate.pem"
    CERTIFICATE_PASSWORD: str = ""
    WWDR_PATH: Path = BASE_DIR / "certs" / "AppleWWDRCA.pem"
    
    # Database Configuration
    DB_HOST: str = "localhost"
    DB_PORT: int = 3306
    DB_USER: str = ""
    DB_PASSWORD: str = ""
    DB_NAME: str = "flyfunboarding"

# File Paths
    KEYS_PATH: Path = BASE_DIR / "keys"
    IMAGES_PATH: Path = BASE_DIR / "images"
    AIRPORT_DB_PATH: Path = BASE_DIR / "data" / "airports.db"  # Used by euro_aip library

# Security
    SECRET: str = ""
    USE_PUBLIC_KEY_SIGNATURE: bool = True
    
    # API Configuration
    API_VERSION: str = "v1"
    DEBUG: bool = False
    
    # CORS Configuration
    CORS_ORIGINS: str = "*"  # Comma-separated list, or "*" for all
    
    # Logging Configuration
    LOG_LEVEL: str = "INFO"
    LOG_FILE: Optional[Path] = BASE_DIR / "logs" / "api.log"
    
    @property
    def cors_origins_list(self) -> list[str]:
        """Parse CORS_ORIGINS into a list."""
        if self.CORS_ORIGINS == "*":
            return ["*"]
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]

# Global settings instance
settings = Settings()
```

**Environment Variables Template** (`.env.sample`):
```bash
# ============================================
# Fly Fun Boarding API Configuration
# ============================================
# Copy this file to .env and update with your actual values
# Never commit .env to version control

# ============================================
# Database Configuration
# ============================================
DB_HOST=localhost
DB_PORT=3306
DB_USER=your_db_user
DB_PASSWORD=your_db_password
DB_NAME=flyfunboarding

# ============================================
# Apple Wallet PKPass Configuration
# ============================================
# Paths can be absolute or relative to BASE_DIR (server/ directory)
CERTIFICATE_PATH=../certs/certificate.pem
CERTIFICATE_PASSWORD=
WWDR_PATH=../certs/AppleWWDRCA.pem

# ============================================
# File Paths
# ============================================
# Paths relative to BASE_DIR (server/ directory)
KEYS_PATH=../keys
IMAGES_PATH=../images
AIRPORT_DB_PATH=../data/airports.db  # Used by euro_aip library (DO NOT read directly)

# ============================================
# Security
# ============================================
# Secret key for system-level authentication
SECRET=your-secret-key-here
USE_PUBLIC_KEY_SIGNATURE=true

# ============================================
# API Configuration
# ============================================
API_VERSION=v1
DEBUG=false

# ============================================
# CORS Configuration
# ============================================
# Comma-separated list of allowed origins, or "*" for all
CORS_ORIGINS=*

# ============================================
# Logging Configuration
# ============================================
LOG_LEVEL=INFO
LOG_FILE=../logs/api.log
```

**Usage in Code**:
```python
# In any module
from config import settings

# Access configuration
db_url = f"mysql+aiomysql://{settings.DB_USER}:{settings.DB_PASSWORD}@{settings.DB_HOST}:{settings.DB_PORT}/{settings.DB_NAME}"
cert_path = settings.CERTIFICATE_PATH
```

**Gitignore Entry** (`.gitignore`):
```gitignore
# Environment variables
.env
.env.local
.env.*.local

# Never commit actual credentials
```

**Benefits of `.env` Approach**:
- ✅ **Standard practice**: Widely used in Python projects
- ✅ **Docker-friendly**: Environment variables work seamlessly with containers
- ✅ **Type-safe**: `pydantic-settings` validates and converts types automatically
- ✅ **Secure**: `.env` is gitignored, `.env.sample` documents required variables
- ✅ **Flexible**: Can override with actual environment variables in production
- ✅ **Portable**: Works the same in development, Docker, and cloud deployments

### C. Example FastAPI Router

See detailed implementation examples in the proposed project structure above.

### D. Docker Deployment Configuration

**Dockerfile** (`server/Dockerfile`):
```dockerfile
FROM python:3.13-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install uv for faster package installation (optional)
# RUN pip install uv

# Copy project files
COPY pyproject.toml .
COPY app/ ./app/

# Install dependencies
RUN pip install --no-cache-dir .

# Copy static files and templates
COPY static/ ./static/
COPY templates/ ./templates/

# Expose port
EXPOSE 8000

# Health check using curl (more reliable than Python import)
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run application with production settings
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

**Multi-stage build for smaller image** (optional):
```dockerfile
# Build stage
FROM python:3.13-slim AS builder

WORKDIR /app
COPY pyproject.toml .
RUN pip install --no-cache-dir build && python -m build --wheel

# Runtime stage
FROM python:3.13-slim

WORKDIR /app

# Install only runtime dependencies
COPY --from=builder /app/dist/*.whl .
RUN pip install --no-cache-dir *.whl && rm *.whl

# Copy static files
COPY static/ ./static/
COPY templates/ ./templates/

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

**docker-compose.yml** (for local development):
```yaml
services:
  api:
    build:
      context: ./server
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    volumes:
      # Development: mount source for hot reload
      - ./server/app:/app/app:ro
      - ./server/static:/app/static:ro
      - ./server/templates:/app/templates:ro
      # Certificates and keys (read-only)
      - ./certs:/app/certs:ro
      - ./keys:/app/keys:ro
      - ./data:/app/data:ro
    env_file:
      - ./server/.env
    environment:
      # Override for development
      - DEBUG=true
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 15s
    # For development with auto-reload:
    command: ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

**docker-compose.prod.yml** (for production):
```yaml
services:
  api:
    build:
      context: ./server
      dockerfile: Dockerfile
    expose:
      - "8000"  # Only expose to caddy, not externally
    env_file:
      - ./server/.env
    volumes:
      - ./certs:/app/certs:ro
      - ./keys:/app/keys:ro
      - ./data:/app/data:ro
    restart: always
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 512M

  caddy:
    image: caddy:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./server/Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      - api
    restart: always

volumes:
  caddy_data:
  caddy_config:
```

### E. Caddy Configuration

**Caddyfile** (for production):
```caddyfile
# Production domain
api.flyfunboarding.com {
    # Reverse proxy to FastAPI container
    reverse_proxy localhost:8000 {
        # Health check
        health_uri /health
        health_interval 30s
        health_timeout 10s
        
        # Headers
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }
    
    # Automatic HTTPS (Let's Encrypt)
    # Caddy automatically obtains and renews certificates
    
    # Logging
    log {
        output file /var/log/caddy/api.log
        format json
    }
    
    # Error handling
    handle_errors {
        respond "{err.status_code} {err.status_text}"
    }
}

# HTTP to HTTPS redirect
http://api.flyfunboarding.com {
    redir https://api.flyfunboarding.com{uri} permanent
}
```

**Caddy with Docker** (Caddyfile location):
- Place Caddyfile in `/etc/caddy/Caddyfile` (or appropriate location)
- Or use Caddy Docker image with volume mount for Caddyfile
- Caddy automatically handles certificate provisioning and renewal

**Caddy Docker Setup** (if running Caddy in Docker):
```yaml
version: '3.8'

services:
  caddy:
    image: caddy:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    restart: unless-stopped

  api:
    build: ./server
    # ... (as above)
    # No need to expose ports externally, Caddy handles that

volumes:
  caddy_data:
  caddy_config:
```

**Key Caddy Features Used**:
- **Automatic HTTPS**: Caddy automatically obtains and renews Let's Encrypt certificates
- **Reverse Proxy**: Routes requests to FastAPI container
- **Health Checks**: Monitors FastAPI health endpoint
- **Logging**: Request/response logging
- **HTTP to HTTPS Redirect**: Automatic redirect for security

