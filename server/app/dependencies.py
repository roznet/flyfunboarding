"""
FastAPI dependencies for authentication and database sessions.

Uses dependency injection instead of middleware for better type safety and testability.
"""
from typing import Annotated
from fastapi import Depends, Header, Path, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.connection import get_db
from app.database.tables import airlines
from sqlalchemy import select


class AirlineContext:
    """Authenticated airline context for request."""

    def __init__(self, airline_id: int, airline_identifier: str, airline_data: dict):
        self.airline_id = airline_id
        self.airline_identifier = airline_identifier
        self.airline_data = airline_data  # JSON data from database


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
            detail="Invalid Bearer Token",
        )

    token = authorization.removeprefix("Bearer ")

    # Query airline from database
    query = select(airlines).where(
        airlines.c.airline_identifier == airline_identifier
    )
    result = await db.execute(query)
    row = result.fetchone()

    if not row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Airline not found",
        )

    airline_dict = dict(row._mapping)
    airline_json = airline_dict.get("json_data", {})
    apple_identifier = airline_json.get("apple_identifier", "")

    if apple_identifier != token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Bearer Token",
        )

    return AirlineContext(
        airline_id=airline_dict["airline_id"],
        airline_identifier=airline_identifier,
        airline_data=airline_json,
    )


async def get_system_auth(
    authorization: Annotated[str | None, Header()] = None,
) -> bool:
    """Dependency for system-level authentication (db setup, etc.)."""
    from app.config import settings

    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="System authentication required",
        )

    token = authorization.removeprefix("Bearer ")
    if token != settings.SECRET:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid system token",
        )

    return True


# Type aliases for cleaner router signatures
CurrentAirline = Annotated[AirlineContext, Depends(get_airline_context)]
SystemAuth = Annotated[bool, Depends(get_system_auth)]
DbSession = Annotated[AsyncSession, Depends(get_db)]

