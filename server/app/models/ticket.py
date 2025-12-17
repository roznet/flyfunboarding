"""
Ticket domain model.

Matches PHP Ticket class structure and JSON serialization.
"""
from typing import Optional
from app.models.base import BaseJsonModel
from app.models.passenger import Passenger
from app.models.flight import Flight


class Ticket(BaseJsonModel):
    """
    Ticket model matching PHP Ticket class.

    JSON keys match PHP $jsonKeys:
    - passenger: Passenger
    - flight: Flight
    - seatNumber: str
    - customLabelValue: str (default "", excluded from JSON)
    - ticket_id: int (default -1, excluded from JSON)
    - flight_id: int (default -1, excluded from JSON)
    - passenger_id: int (default -1, excluded from JSON)
    - ticket_identifier: str (default "", excluded from JSON)
    """
    passenger: Passenger
    flight: Flight
    seat_number: str

    # Fields with defaults (excluded from JSON)
    ticket_id: int = -1
    flight_id: int = -1
    passenger_id: int = -1
    ticket_identifier: str = ""
    custom_label_value: str = ""

    def unique_identifier(self) -> dict:
        """Add ticket identifiers to JSON output if not default."""
        result = {}
        if self.ticket_id != -1:
            result["ticket_id"] = self.ticket_id
        if self.flight_id != -1:
            result["flight_id"] = self.flight_id
        if self.passenger_id != -1:
            result["passenger_id"] = self.passenger_id
        if self.ticket_identifier:
            result["ticket_identifier"] = self.ticket_identifier
        if self.custom_label_value:
            result["customLabelValue"] = self.custom_label_value
        return result

