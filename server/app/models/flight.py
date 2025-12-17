"""
Flight domain model.

Matches PHP Flight class structure and JSON serialization.
"""
from datetime import datetime
from typing import Optional
from pydantic import Field
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
    flight_number: str = Field(..., alias="flightNumber")
    aircraft: Aircraft
    scheduled_departure_date: datetime = Field(..., alias="scheduledDepartureDate")

    # Fields with defaults (excluded from JSON)
    flight_id: int = Field(-1, alias="flightId")
    flight_identifier: str = Field("", alias="flightIdentifier")
    aircraft_id: int = Field(-1, alias="aircraftId")
    stats: list[Stats] = Field([], alias="stats")

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

    def has_flight_number(self) -> bool:
        """
        Check if flight has a valid flight number.
        
        Matches PHP: Flight->hasFlightNumber()
        """
        return (
            self.flight_number is not None
            and self.flight_number != ""
            and self.flight_number != self.aircraft.registration
        )

    def format_scheduled_departure_date(self) -> str:
        """
        Format scheduled departure date with timezone.
        
        Matches PHP: Flight->formatScheduledDepartureDate()
        Returns: 'D M d, H:i' format (e.g., 'Wed Jun 19, 08:00')
        """
        from datetime import timezone
        from zoneinfo import ZoneInfo
        
        date_to_display = self.scheduled_departure_date
        
        # Apply timezone if origin has timezone_identifier
        if self.origin.timezone_identifier:
            try:
                tz = ZoneInfo(self.origin.timezone_identifier)
                # Convert to timezone-aware if needed
                if date_to_display.tzinfo is None:
                    date_to_display = date_to_display.replace(tzinfo=timezone.utc)
                date_to_display = date_to_display.astimezone(tz)
            except Exception:
                # If timezone is invalid, use as-is
                pass
        
        # Format: 'D M d, H:i' (e.g., 'Wed Jun 19, 08:00')
        return date_to_display.strftime('%a %b %d, %H:%M')

