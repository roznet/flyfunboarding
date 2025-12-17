"""
Airline domain model.

Matches PHP Airline class structure and JSON serialization.
"""
from typing import Optional
from app.models.base import BaseJsonModel


class Airline(BaseJsonModel):
    """
    Airline model matching PHP Airline class.

    JSON keys match PHP $jsonKeys:
    - airline_id: int (default -1, excluded from JSON)
    - airline_identifier: str (default "", excluded from JSON)
    - apple_identifier: str
    - name: Optional[str]
    """

    # Fields that match PHP $jsonKeys
    airline_name: Optional[str] = None  # PHP uses airline_name, not name
    apple_identifier: str

    # Fields with defaults (excluded from JSON)
    airline_id: int = -1
    airline_identifier: str = ""

    def unique_identifier(self) -> dict:
        """Add airline identifiers to JSON output if not default."""
        result = {}
        if self.airline_id != -1:
            result["airline_id"] = self.airline_id
        if self.airline_identifier:
            result["airline_identifier"] = self.airline_identifier
        return result

