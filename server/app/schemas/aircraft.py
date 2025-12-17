"""
API schemas for Aircraft endpoints.
"""
from typing import Optional
from pydantic import BaseModel, Field


class AircraftCreate(BaseModel):
    """Schema for creating/updating an aircraft."""
    registration: str = Field(..., description="Aircraft registration")
    type: str = Field(..., description="Aircraft type")


class AircraftResponse(BaseModel):
    """Schema for aircraft API responses."""
    registration: str
    type: str
    aircraft_id: Optional[int] = None
    aircraft_identifier: Optional[str] = None
    stats: Optional[list] = None

