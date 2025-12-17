"""
Aircraft domain model.

Matches PHP Aircraft class structure and JSON serialization.
"""
from typing import Optional
from app.models.base import BaseJsonModel
from app.models.stats import Stats


class Aircraft(BaseJsonModel):
    """
    Aircraft model matching PHP Aircraft class.

    JSON keys match PHP $jsonKeys:
    - registration: str
    - type: str
    - stats: list[Stats] (default [], excluded from JSON)
    - aircraft_id: int (default -1, excluded from JSON)
    - aircraft_identifier: str (default "", excluded from JSON)
    """
    registration: str
    type: str

    # Fields with defaults (excluded from JSON)
    aircraft_id: int = -1
    aircraft_identifier: str = ""
    stats: list[Stats] = []

    def unique_identifier(self) -> dict:
        """Add aircraft identifiers to JSON output if not default."""
        result = {}
        if self.aircraft_id != -1:
            result["aircraft_id"] = self.aircraft_id
        if self.aircraft_identifier:
            result["aircraft_identifier"] = self.aircraft_identifier
        if self.stats:
            result["stats"] = [stat.to_json() for stat in self.stats]
        return result

