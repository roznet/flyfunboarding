"""
Airline management endpoints.

Matches PHP AirlineController functionality.
"""
from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.dialects.mysql import insert as mysql_insert
import hashlib

from app.dependencies import CurrentAirline, DbSession, SystemAuth
from app.database.tables import airlines
from app.schemas.airline import AirlineCreate, AirlineResponse
from app.models.airline import Airline
from app.core.exceptions import NotFoundError

router = APIRouter()


def airline_identifier_from_apple_identifier(apple_identifier: str) -> str:
    """
    Generate airline identifier from Apple identifier.

    Matches PHP: hash('sha1', $identifier)
    """
    return hashlib.sha1(apple_identifier.encode()).hexdigest()


@router.post("/create", response_model=AirlineResponse, status_code=status.HTTP_200_OK)
async def create_airline(
    airline_data: AirlineCreate,
    db: DbSession,
    system_auth: SystemAuth,
):
    """
    Create or update airline from Apple identifier.

    Matches PHP: POST /v1/airline/create
    Requires system authentication (SECRET).
    """
    # Generate airline_identifier from apple_identifier
    airline_identifier = airline_identifier_from_apple_identifier(
        airline_data.apple_identifier
    )

    # Prepare JSON data for storage
    json_data = {
        "apple_identifier": airline_data.apple_identifier,
        "airline_name": airline_data.airline_name,
    }

    # MySQL INSERT ... ON DUPLICATE KEY UPDATE
    stmt = mysql_insert(airlines).values(
        airline_identifier=airline_identifier,
        json_data=json_data,
    )
    stmt = stmt.on_duplicate_key_update(json_data=json_data)

    await db.execute(stmt)
    await db.commit()

    # Retrieve the created/updated airline
    query = select(airlines).where(
        airlines.c.airline_identifier == airline_identifier
    )
    result = await db.execute(query)
    row = result.fetchone()

    if not row:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid Airline",
        )

    # Convert to model
    airline_dict = dict(row._mapping)
    airline_json = airline_dict.get("json_data", {})
    airline_json["airline_id"] = airline_dict["airline_id"]
    airline_json["airline_identifier"] = airline_dict["airline_identifier"]

    airline = Airline.model_validate(airline_json)
    return airline.to_json()


@router.get("/{airline_identifier}", response_model=AirlineResponse)
async def get_airline(
    airline: CurrentAirline,
    db: DbSession,
):
    """
    Get airline by identifier.

    Matches PHP: GET /v1/airline/{airline_identifier}
    Authentication handled by CurrentAirline dependency.
    """
    # Airline is already validated and loaded by dependency
    airline_model = Airline.model_validate(
        {
            **airline.airline_data,
            "airline_id": airline.airline_id,
            "airline_identifier": airline.airline_identifier,
        }
    )
    return airline_model.to_json()


@router.get("/{airline_identifier}/keys")
async def get_airline_keys(
    airline: CurrentAirline,
    db: DbSession,
):
    """
    Get airline's public keys.

    Matches PHP: GET /v1/airline/{airline_identifier}/keys
    """
    # TODO: Implement signature service and return public keys
    # For now, return empty array to match structure
    return []


@router.delete("/{airline_identifier}", status_code=status.HTTP_200_OK)
async def delete_airline(
    airline: CurrentAirline,
    db: DbSession,
):
    """
    Delete airline.

    Matches PHP: DELETE /v1/airline/{airline_identifier}
    """
    from sqlalchemy import delete

    stmt = delete(airlines).where(airlines.c.airline_id == airline.airline_id)
    await db.execute(stmt)
    await db.commit()

    return {
        "status": 1,
        "airline_identifier": airline.airline_identifier,
    }

