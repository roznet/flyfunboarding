"""
Airport domain model.

Matches PHP Airport class structure and JSON serialization.
"""
from typing import Optional
from app.models.base import BaseJsonModel
from app.services.airport_service import AirportService


class Airport(BaseJsonModel):
    """
    Airport model matching PHP Airport class.

    JSON keys match PHP $jsonKeys:
    - icao: str
    - timezone_identifier: str (default "", excluded from JSON)
    """
    icao: str
    timezone_identifier: str = ""

    def get_info(self) -> Optional[dict]:
        """
        Get airport information from AirportService.
        
        Matches PHP: Airport->getInfo()
        """
        return AirportService.get_airport_by_icao(self.icao)

    def get_name(self) -> Optional[str]:
        """
        Get airport name.
        
        Matches PHP: Airport->getName()
        """
        info = self.get_info()
        return info.get('name') if info else None

    def get_city(self) -> Optional[str]:
        """
        Get airport city/municipality.
        
        Matches PHP: Airport->getCity()
        """
        info = self.get_info()
        return info.get('municipality') if info else None

    def get_location(self) -> Optional[dict[str, float]]:
        """
        Get airport location (latitude, longitude).
        
        Matches PHP: Airport->getLocation()
        """
        return AirportService.get_location(self.icao)

    def get_map_url(self) -> Optional[str]:
        """
        Get Google Maps URL for airport.
        
        Matches PHP: Airport->getMapURL()
        """
        return AirportService.get_map_url(self.icao)

    def fit_name(self, maxlen: int) -> str:
        """
        Get airport name or city that fits within maxlen.
        
        Matches PHP: Airport->fitName()
        """
        name = self.get_name() or ""
        city = self.get_city() or ""
        
        if len(name) < maxlen:
            return name
        elif len(city) < maxlen:
            return city
        return name

