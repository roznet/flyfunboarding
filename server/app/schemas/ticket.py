"""
API schemas for Ticket endpoints.
"""
from typing import Optional
from pydantic import BaseModel, Field
from app.schemas.passenger import PassengerResponse
from app.schemas.flight import FlightResponse


class TicketCreate(BaseModel):
    """Schema for creating a ticket."""
    seat_number: str = Field(..., alias="seatNumber")
    custom_label_value: Optional[str] = Field(default="1", alias="customLabelValue")

    class Config:
        populate_by_name = True


class TicketResponse(BaseModel):
    """Schema for ticket API responses."""
    passenger: PassengerResponse
    flight: FlightResponse
    seat_number: str = Field(..., alias="seatNumber")
    custom_label_value: Optional[str] = Field(None, alias="customLabelValue")
    ticket_id: Optional[int] = None
    flight_id: Optional[int] = None
    passenger_id: Optional[int] = None
    ticket_identifier: Optional[str] = None

    class Config:
        populate_by_name = True


class TicketVerify(BaseModel):
    """Schema for ticket verification."""
    ticket: str
    signature_digest: Optional[dict] = Field(None, alias="signatureDigest")
    signature: Optional[dict] = None  # Legacy format

    class Config:
        populate_by_name = True

