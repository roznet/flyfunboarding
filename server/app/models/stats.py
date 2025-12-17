"""
Stats domain model.

Matches PHP Stats class structure and JSON serialization.
"""
from datetime import datetime
from typing import Optional
from app.models.base import BaseJsonModel


class Stats(BaseJsonModel):
    """
    Stats model matching PHP Stats class.

    JSON keys match PHP $jsonKeys:
    - table: str
    - count: int
    - last: Optional[datetime] (default None, excluded from JSON)
    """
    table: str
    count: int
    last: Optional[datetime] = None

