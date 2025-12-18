"""
Airport service for airport data access.

Uses euro_aip library (DO NOT read airports.db directly).
Matches PHP Airport class behavior.
"""
from typing import Optional
from pathlib import Path
import logging

from app.config import settings

logger = logging.getLogger(__name__)


class AirportService:
    """
    Airport data service using euro_aip library.
    
    Matches PHP Airport class functionality:
    - Lookup by ICAO code
    - Get airport information (name, location, country, etc.)
    - Get map URLs
    
    Uses DatabaseSource from euro_aip.sources for read-only access to airports.db.
    """
    
    _source = None  # Cached DatabaseSource instance
    
    @classmethod
    def _get_source(cls):
        """
        Get or create DatabaseSource instance (singleton pattern).
        
        Returns:
            DatabaseSource instance, or None if unavailable
        """
        if cls._source is None:
            try:
                # Import from euro_aip.sources (where DatabaseSource is actually defined)
                from euro_aip.sources import DatabaseSource
                
                airport_db_path = Path(settings.AIRPORT_DB_PATH)
                if not airport_db_path.exists():
                    logger.warning(f"Airport database not found at {airport_db_path}")
                    return None
                
                cls._source = DatabaseSource(str(airport_db_path))
            except ImportError as e:
                logger.warning(f"Could not import euro_aip library: {e}. Airport data will not be available.")
                cls._source = None
            except Exception as e:
                logger.error(f"Error initializing DatabaseSource: {e}")
                cls._source = None
        
        return cls._source
    
    @classmethod
    def get_airport_by_icao(cls, icao: str) -> Optional[dict]:
        """
        Get airport information by ICAO code.
        
        Matches PHP: Airport->getInfo()
        
        Args:
            icao: ICAO code (e.g., 'EGLL')
            
        Returns:
            Dictionary with airport information, or None if not found
        """
        source = cls._get_source()
        if source is None:
            return None
        
        try:
            # Normalize ICAO to uppercase
            icao = icao.upper()
            
            # Query airport by ICAO using DatabaseSource
            airports = source.get_airports(where=f"ident = '{icao}'")
            
            if airports and len(airports) > 0:
                airport = airports[0]
                # Convert Airport object to dictionary format matching PHP structure
                return {
                    'ident': airport.ident,
                    'name': airport.name,
                    'municipality': airport.municipality,
                    'iso_country': airport.iso_country,
                    'latitude_deg': airport.latitude_deg,
                    'longitude_deg': airport.longitude_deg,
                    'elevation_ft': airport.elevation_ft,
                    'iata_code': airport.iata_code,
                    'type': airport.type,
                }
        except Exception as e:
            logger.error(f"Error getting airport {icao}: {e}")
            return None
        
        return None
    
    @classmethod
    def get_map_url(cls, icao: str) -> Optional[str]:
        """
        Get Google Maps URL for airport location.
        
        Matches PHP: Airport->getMapURL()
        
        Args:
            icao: ICAO code
            
        Returns:
            Google Maps URL, or None if airport not found
        """
        info = cls.get_airport_by_icao(icao)
        if not info or not info.get('latitude_deg') or not info.get('longitude_deg'):
            return None
        
        lat = info['latitude_deg']
        lon = info['longitude_deg']
        return f"https://www.google.com/maps/place/{lat},{lon}"
    
    @classmethod
    def get_city(cls, icao: str) -> Optional[str]:
        """
        Get airport city/municipality.
        
        Matches PHP: Airport->getCity()
        
        Args:
            icao: ICAO code
            
        Returns:
            City name, or None
        """
        info = cls.get_airport_by_icao(icao)
        return info.get('municipality') if info else None
    
    @classmethod
    def get_country(cls, icao: str) -> Optional[str]:
        """
        Get airport country code.
        
        Matches PHP: Airport->getCountry()
        
        Args:
            icao: ICAO code
            
        Returns:
            ISO country code, or None
        """
        info = cls.get_airport_by_icao(icao)
        return info.get('iso_country') if info else None
    
    @classmethod
    def get_location(cls, icao: str) -> Optional[dict[str, float]]:
        """
        Get airport coordinates.
        
        Matches PHP: Airport->getLocation()
        
        Args:
            icao: ICAO code
            
        Returns:
            Dictionary with 'latitude' and 'longitude', or None
        """
        info = cls.get_airport_by_icao(icao)
        if not info or not info.get('latitude_deg') or not info.get('longitude_deg'):
            return None
        
        return {
            'latitude': float(info['latitude_deg']),
            'longitude': float(info['longitude_deg'])
        }
    
    @classmethod
    def list_airports_by_country(cls, country_code: str) -> list[dict]:
        """
        List airports by country code.
        
        Args:
            country_code: ISO country code (e.g., 'FR', 'GB')
            
        Returns:
            List of airport dictionaries
        """
        source = cls._get_source()
        if source is None:
            return []
        
        try:
            # Query airports by country using DatabaseSource
            airports = source.get_airports(where=f"iso_country = '{country_code}'")
            
            result = []
            for airport in airports:
                result.append({
                    'ident': airport.ident,
                    'name': airport.name,
                    'municipality': airport.municipality,
                    'iso_country': airport.iso_country,
                    'latitude_deg': airport.latitude_deg,
                    'longitude_deg': airport.longitude_deg,
                    'elevation_ft': airport.elevation_ft,
                    'iata_code': airport.iata_code,
                    'type': airport.type,
                })
            return result
        except Exception as e:
            logger.error(f"Error listing airports for country {country_code}: {e}")
            return []

