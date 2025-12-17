"""
Airport domain model.

Matches PHP Airport class structure and JSON serialization.
"""
from typing import Optional
from app.models.base import BaseJsonModel


class Airport(BaseJsonModel):
    """
    Airport model matching PHP Airport class.

    JSON keys match PHP $jsonKeys:
    - icao: str
    - timezone_identifier: str (default "", excluded from JSON)
    """
    icao: str
    timezone_identifier: str = ""

