"""
Flight domain model.

Matches PHP Flight class structure and JSON serialization.
"""
from datetime import datetime
from typing import Optional
from app.models.base import BaseJsonModel
from app.models.airport import Airport
from app.models.aircraft import Aircraft
from app.models.stats import Stats


class Flight(BaseJsonModel):
    """
    Flight model matching PHP Flight class.

    JSON keys match PHP $jsonKeys:
    - origin: Airport
    - destination: Airport
    - gate: str
    - flightNumber: str
    - aircraft: Aircraft
    - scheduledDepartureDate: datetime
    - stats: list[Stats] (default [], excluded from JSON)
    - flight_id: int (default -1, excluded from JSON)
    - flight_identifier: str (default "", excluded from JSON)
    """
    origin: Airport
    destination: Airport
    gate: str
    flight_number: str
    aircraft: Aircraft
    scheduled_departure_date: datetime

    # Fields with defaults (excluded from JSON)
    flight_id: int = -1
    flight_identifier: str = ""
    aircraft_id: int = -1
    stats: list[Stats] = []

    def unique_identifier(self) -> dict:
        """Add flight identifiers to JSON output if not default."""
        result = {}
        if self.flight_id != -1:
            result["flight_id"] = self.flight_id
        if self.flight_identifier:
            result["flight_identifier"] = self.flight_identifier
        if self.aircraft_id != -1:
            result["aircraft_id"] = self.aircraft_id
        if self.stats:
            result["stats"] = [stat.to_json() for stat in self.stats]
        return result

