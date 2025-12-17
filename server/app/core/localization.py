"""
Localization service for language detection and string translation.

Matches PHP language detection logic from yourBoardingPass.php.
"""
import httpx
from typing import Optional
from fastapi import Request
import logging

logger = logging.getLogger(__name__)

# Language codes mapped to country codes (matches PHP $languages_codes)
LANGUAGE_COUNTRY_MAP = {
    'en': ['US', 'GB', 'AU', 'CA', 'NZ'],
    'fr': ['FR', 'BE', 'CA', 'CH', 'LU', 'MC', 'SN', 'TD', 'TG', 'TN', 'YT'],
    'de': ['DE', 'AT', 'CH', 'LI', 'LU', 'BE'],
    'es': ['ES', 'MX', 'GT', 'HN', 'SV', 'NI', 'CR', 'PA', 'VE', 'CO', 'EC', 'PE', 'BO', 'PY', 'UY', 'AR', 'PR', 'CU', 'DO', 'CL'],
}

# Language display names (matches PHP $languages_text)
LANGUAGE_NAMES = {
    'en': 'English',
    'fr': 'Français',
    'de': 'Deutsch',
    'es': 'Español',
}

# Supported languages (languages that have disclaimer files)
SUPPORTED_LANGUAGES = ['en', 'fr', 'de', 'es']


def language_has_disclaimer(language: str) -> bool:
    """
    Check if a language has a disclaimer file.
    
    Matches PHP: language_has_disclaimer()
    """
    return language in SUPPORTED_LANGUAGES


async def get_chosen_language(
    request: Request,
    lang_query: Optional[str] = None,
    default_language: str = 'en'
) -> str:
    """
    Get chosen language based on query param, Accept-Language header, or IP geolocation.
    
    Matches PHP: get_chosen_language()
    
    Priority:
    1. Query parameter `lang`
    2. Accept-Language header
    3. IP geolocation (via ipwho.is)
    4. Default language
    
    Args:
        request: FastAPI Request object
        lang_query: Optional language from query parameter
        default_language: Default language if detection fails
    
    Returns:
        Language code (e.g., 'en', 'fr', 'de', 'es')
    """
    # Priority 1: Query parameter
    if lang_query and language_has_disclaimer(lang_query):
        return lang_query
    
    # Priority 2: Accept-Language header
    accept_language = request.headers.get('Accept-Language', '')
    if accept_language:
        # Parse Accept-Language header (e.g., "en-US,en;q=0.9,fr;q=0.8")
        # Take first 2 characters
        lang_from_header = accept_language.split(',')[0].split(';')[0].strip()[:2].lower()
        if language_has_disclaimer(lang_from_header):
            return lang_from_header
    
    # Priority 3: IP geolocation
    try:
        client_ip = request.client.host if request.client else None
        if client_ip:
            # Use ipwho.is API (same as PHP)
            async with httpx.AsyncClient(timeout=2.0) as client:
                response = await client.get(f"http://ipwho.is/{client_ip}")
                if response.status_code == 200:
                    data = response.json()
                    country_code = data.get('country_code')
                    if country_code:
                        # Check if country code maps to a language
                        for lang, countries in LANGUAGE_COUNTRY_MAP.items():
                            if country_code in countries:
                                return lang
    except Exception as e:
        logger.warning(f"IP geolocation failed: {e}")
    
    # Fallback to default
    return default_language


def get_localized_strings(language: str) -> dict[str, str]:
    """
    Get localized strings for a language.
    
    Uses BoardingPassService locale_strings() method.
    
    Args:
        language: Language code (e.g., 'en', 'fr')
    
    Returns:
        Dictionary of localized strings
    """
    # Use the same locale strings as BoardingPassService
    defs = {
        'fr': {
            'Flight': 'Vol',
            'Aircraft': 'Avion',
            'Gate': 'Porte',
            'Departs': 'Départ',
            'Arrives': 'Arrivée',
            'Passenger': 'Passager',
            'Seat': 'Siège',
            'I agree to the terms and conditions below': 'J\'accepte les termes et conditions ci-dessous',
        },
        'en': {
            'Flight': 'Flight',
            'Aircraft': 'Aircraft',
            'Gate': 'Gate',
            'Departs': 'Departs',
            'Arrives': 'Arrives',
            'Passenger': 'Passenger',
            'Seat': 'Seat',
            'I agree to the terms and conditions below': 'I agree to the terms and conditions below',
        },
        'de': {
            'Flight': 'Flug',
            'Aircraft': 'Flugzeug',
            'Gate': 'Tor',
            'Departs': 'Abflug',
            'Arrives': 'Ankunft',
            'Passenger': 'Passagier',
            'Seat': 'Sitz',
            'I agree to the terms and conditions below': 'Ich stimme den unten stehenden Bedingungen zu',
        },
        'es': {
            'Flight': 'Vuelo',
            'Aircraft': 'Avión',
            'Gate': 'Puerta',
            'Departs': 'Sale',
            'Arrives': 'Llega',
            'Passenger': 'Pasajero',
            'Seat': 'Asiento',
            'I agree to the terms and conditions below': 'Acepto los términos y condiciones a continuación',
        },
    }
    return defs.get(language, {})


def get_available_languages() -> dict[str, str]:
    """
    Get all available languages with their display names.
    
    Returns:
        Dictionary mapping language codes to display names
    """
    return LANGUAGE_NAMES.copy()

