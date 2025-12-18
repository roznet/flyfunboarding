"""
Fly Fun Boarding API - FastAPI Application Entry Point
"""
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from app.config import settings
from app.database.connection import engine
from app.core.exceptions import register_exception_handlers
from sqlalchemy import text


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan - startup and shutdown events."""
    # Startup: verify database connection
    async with engine.begin() as conn:
        await conn.execute(text("SELECT 1"))
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
from app.routers import airline, aircraft, passenger, flight, ticket, settings, status

app.include_router(airline.router, prefix="/v1/airline", tags=["airline"])

# System-level routers (no airline prefix)
app.include_router(status.router, prefix="/v1/status", tags=["status"])

# Airport router (public, no auth required)
from app.routers import airport
app.include_router(airport.router, prefix="/v1/airport", tags=["airport"])

# Boarding Pass routers
from app.routers import boarding_pass
app.include_router(
    boarding_pass.router,
    prefix="/v1/airline/{airline_identifier}/boardingpass",
    tags=["boardingpass"],
)
app.include_router(
    boarding_pass.public_router,
    prefix="/v1/boardingpass",
    tags=["boardingpass"],
)

# Airline-scoped routers (require airline_identifier in path)
app.include_router(
    aircraft.router,
    prefix="/v1/airline/{airline_identifier}/aircraft",
    tags=["aircraft"],
)
app.include_router(
    passenger.router,
    prefix="/v1/airline/{airline_identifier}/passenger",
    tags=["passenger"],
)
app.include_router(
    flight.router,
    prefix="/v1/airline/{airline_identifier}/flight",
    tags=["flight"],
)
app.include_router(
    ticket.router,
    prefix="/v1/airline/{airline_identifier}/ticket",
    tags=["ticket"],
)
app.include_router(
    settings.router,
    prefix="/v1/airline/{airline_identifier}/settings",
    tags=["settings"],
)

# TODO: Add remaining routers as they are implemented
# from app.routers import (
#     flight, ticket, settings as settings_router,
#     boarding_pass, airport, status, db, pages
# )
#
# app.include_router(flight.router, prefix="/v1/airline/{airline_identifier}/flight", tags=["flight"])
# app.include_router(ticket.router, prefix="/v1/airline/{airline_identifier}/ticket", tags=["ticket"])
# app.include_router(settings_router.router, prefix="/v1/airline/{airline_identifier}/settings", tags=["settings"])
# app.include_router(boarding_pass.router, prefix="/v1/airline/{airline_identifier}/boardingpass", tags=["boardingpass"])
# app.include_router(airport.router, prefix="/v1/airport", tags=["airport"])
# app.include_router(status.router, prefix="/v1/status", tags=["status"])
# app.include_router(db.router, prefix="/v1/db", tags=["db"])
#
# # Direct boarding pass access (no airline prefix - determines airline from ticket)
# app.include_router(boarding_pass.public_router, prefix="/v1/boardingpass", tags=["boardingpass"])
#
# # Web pages (user-facing HTML - no auth required)
# app.include_router(pages.router, tags=["pages"])

# Web pages (user-facing HTML - no auth required)
from app.routers import pages
app.include_router(pages.router, prefix="/pages", tags=["pages"])

# Static files (images, CSS, JS)
# Resolve the "static" directory relative to this file so it works regardless
# of current working directory (pytest discovery, uvicorn from project root, etc).
BASE_DIR = Path(__file__).resolve().parent.parent  # server/app -> server
STATIC_DIR = BASE_DIR / "static"
if STATIC_DIR.exists():
    app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")


@app.get("/health")
async def health_check():
    """Health check endpoint for load balancers and monitoring."""
    return {"status": "healthy"}


@app.get("/")
async def root():
    """Root endpoint - API information."""
    return {
        "name": "Fly Fun Boarding API",
        "version": "1.0.0",
        "status": "running",
        "framework": "FastAPI",
    }

