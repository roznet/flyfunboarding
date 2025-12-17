"""
API schemas for Airport (used in Flight).
"""
from typing import Optional
from pydantic import BaseModel, Field


class AirportSchema(BaseModel):
    """Schema for airport data in flight."""
    icao: str
    timezone_identifier: Optional[str] = Field(default="", alias="timezone_identifier")

    class Config:
        populate_by_name = True

