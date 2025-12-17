"""
API schemas for Passenger endpoints.
"""
from typing import Optional
from pydantic import BaseModel, Field


class PassengerCreate(BaseModel):
    """Schema for creating/updating a passenger."""
    formatted_name: Optional[str] = Field(None, alias="formattedName")
    first_name: Optional[str] = Field(None, alias="firstName")
    middle_name: Optional[str] = Field(None, alias="middleName")
    last_name: Optional[str] = Field(None, alias="lastName")
    apple_identifier: str = Field(..., alias="apple_identifier")

    class Config:
        populate_by_name = True


class PassengerResponse(BaseModel):
    """Schema for passenger API responses."""
    formatted_name: Optional[str] = Field(None, alias="formattedName")
    first_name: Optional[str] = Field(None, alias="firstName")
    middle_name: Optional[str] = Field(None, alias="middleName")
    last_name: Optional[str] = Field(None, alias="lastName")
    apple_identifier: str
    passenger_id: Optional[int] = None
    passenger_identifier: Optional[str] = None
    stats: Optional[list] = None

    class Config:
        populate_by_name = True

