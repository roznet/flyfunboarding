"""
Airport API router.

Matches PHP AirportController endpoints.
"""
from fastapi import APIRouter, HTTPException, Query, status
from typing import Optional

from app.services.airport_service import AirportService

router = APIRouter()


@router.get("")
async def get_airport_by_icao(icao: Optional[str] = Query(None, description="ICAO code")):
    """
    Get airport information by ICAO code.
    
    Matches PHP: GET /v1/airport?icao=XXXX
    """
    if not icao:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Bad Request, Airport not found"
        )
    
    airport_info = AirportService.get_airport_by_icao(icao)
    
    if not airport_info:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Bad Request, Airport not found"
        )
    
    return airport_info


@router.get("/info/{icao}")
async def get_airport_info(icao: str):
    """
    Get airport information by ICAO code (path-based).
    
    Matches PHP: GET /v1/airport/info/{icao}
    """
    airport_info = AirportService.get_airport_by_icao(icao)
    
    if not airport_info:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Bad Request, Airport not found"
        )
    
    return airport_info

