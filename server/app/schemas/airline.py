"""
Airline API request/response schemas.
"""
from typing import Optional
from pydantic import Field
from app.models.base import BaseJsonModel


class AirlineCreate(BaseJsonModel):
    """Request schema for creating/updating an airline."""

    apple_identifier: str = Field(..., description="Apple identifier for authentication")
    airline_name: Optional[str] = Field(None, description="Airline name")


class AirlineResponse(BaseJsonModel):
    """Response schema for airline data."""

    airline_id: int
    airline_identifier: str
    apple_identifier: str
    airline_name: Optional[str] = None

