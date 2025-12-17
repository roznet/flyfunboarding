"""
Passenger domain model.

Matches PHP Passenger class structure and JSON serialization.
"""
from typing import Optional
from pydantic import Field
from app.models.base import BaseJsonModel
from app.models.stats import Stats


class Passenger(BaseJsonModel):
    """
    Passenger model matching PHP Passenger class.

    JSON keys match PHP $jsonKeys:
    - formattedName: Optional[str]
    - firstName: Optional[str] (not in JSON keys, but in PHP class)
    - middleName: Optional[str] (not in JSON keys, but in PHP class)
    - lastName: Optional[str] (not in JSON keys, but in PHP class)
    - apple_identifier: str
    - stats: list[Stats] (default [], excluded from JSON)
    - passenger_id: int (default -1, excluded from JSON)
    - passenger_identifier: str (default "", excluded from JSON)
    """
    formatted_name: Optional[str] = Field(None, alias="formattedName")
    first_name: Optional[str] = Field(None, alias="firstName")
    middle_name: Optional[str] = Field(None, alias="middleName")
    last_name: Optional[str] = Field(None, alias="lastName")
    apple_identifier: str

    # Fields with defaults (excluded from JSON)
    passenger_id: int = Field(-1, alias="passengerId")
    passenger_identifier: str = Field("", alias="passengerIdentifier")
    stats: list[Stats] = Field([], alias="stats")

    def unique_identifier(self) -> dict:
        """Add passenger identifiers to JSON output if not default."""
        result = {}
        if self.passenger_id != -1:
            result["passenger_id"] = self.passenger_id
        if self.passenger_identifier:
            result["passenger_identifier"] = self.passenger_identifier
        if self.stats:
            result["stats"] = [stat.to_json() for stat in self.stats]
        return result

