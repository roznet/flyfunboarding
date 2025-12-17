"""Domain models - Pydantic BaseModels with PHP-compatible serialization."""

from app.models.airline import Airline
from app.models.aircraft import Aircraft
from app.models.passenger import Passenger
from app.models.flight import Flight
from app.models.ticket import Ticket
from app.models.settings import Settings
from app.models.stats import Stats
from app.models.airport import Airport

__all__ = [
    "Airline",
    "Aircraft",
    "Passenger",
    "Flight",
    "Ticket",
    "Settings",
    "Stats",
    "Airport",
]
