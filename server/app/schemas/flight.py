"""
API schemas for Flight endpoints.
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field
from app.schemas.airport import AirportSchema
from app.schemas.aircraft import AircraftResponse


class FlightCreate(BaseModel):
    """Schema for creating/updating a flight."""
    origin: AirportSchema
    destination: AirportSchema
    gate: str
    flight_number: str = Field(..., alias="flightNumber")
    aircraft: AircraftResponse
    scheduled_departure_date: datetime = Field(..., alias="scheduledDepartureDate")

    class Config:
        populate_by_name = True


class FlightResponse(BaseModel):
    """Schema for flight API responses."""
    origin: AirportSchema
    destination: AirportSchema
    gate: str
    flight_number: str = Field(..., alias="flightNumber")
    aircraft: AircraftResponse
    scheduled_departure_date: datetime = Field(..., alias="scheduledDepartureDate")
    flight_id: Optional[int] = None
    flight_identifier: Optional[str] = None
    aircraft_id: Optional[int] = None
    stats: Optional[list] = None

    class Config:
        populate_by_name = True


class FlightCheck(BaseModel):
    """Schema for flight check endpoint."""
    # This will be validated against the flight data
    pass

