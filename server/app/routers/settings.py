"""
Settings API router.

Matches PHP SettingsController endpoints.
"""
from fastapi import APIRouter, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.dialects.mysql import insert as mysql_insert

from app.dependencies import CurrentAirline, DbSession
from app.database.tables import settings as settings_table
from app.schemas.settings import SettingsUpdate, SettingsResponse
from app.models.settings import Settings

router = APIRouter()


@router.get("", response_model=SettingsResponse)
async def get_settings(
    airline: CurrentAirline,
    db: DbSession,
):
    """
    Get airline settings.
    
    Matches PHP: GET /v1/airline/{airline_identifier}/settings
    Returns default settings if none exist.
    """
    # Query settings from database
    query = select(settings_table).where(
        settings_table.c.airline_id == airline.airline_id
    )
    result = await db.execute(query)
    row = result.fetchone()
    
    if row:
        # Settings exist, parse JSON
        settings_dict = dict(row._mapping)
        json_data = settings_dict.get("json_data", {})
        settings = Settings.model_validate(json_data)
    else:
        # No settings exist, return defaults
        settings = Settings()
    
    # Use model_dump to ensure all fields are included (not to_json which excludes defaults)
    return settings.model_dump(by_alias=True)


@router.post("", response_model=SettingsResponse, status_code=status.HTTP_200_OK)
async def update_settings(
    settings_update: SettingsUpdate,
    airline: CurrentAirline,
    db: DbSession,
):
    """
    Update airline settings.
    
    Matches PHP: POST /v1/airline/{airline_identifier}/settings
    Merges provided values with existing settings (or defaults).
    """
    # Get current settings (or defaults)
    query = select(settings_table).where(
        settings_table.c.airline_id == airline.airline_id
    )
    result = await db.execute(query)
    row = result.fetchone()
    
    if row:
        # Existing settings - merge with update
        settings_dict = dict(row._mapping)
        current_json = settings_dict.get("json_data", {})
        current_settings = Settings.model_validate(current_json)
    else:
        # No existing settings - start with defaults
        current_settings = Settings()
    
    # Update with provided values (only non-None values)
    update_dict = settings_update.model_dump(exclude_unset=True, by_alias=True)
    current_dict = current_settings.model_dump(by_alias=True)
    current_dict.update(update_dict)
    
    # Create updated settings object
    updated_settings = Settings.model_validate(current_dict)
    
    # Save to database
    json_data = updated_settings.model_dump(by_alias=True)
    stmt = mysql_insert(settings_table).values(
        airline_id=airline.airline_id,
        json_data=json_data,
    )
    stmt = stmt.on_duplicate_key_update(json_data=json_data)
    await db.execute(stmt)
    await db.commit()
    
    # Use model_dump to ensure all fields are included (not to_json which excludes defaults)
    return updated_settings.model_dump(by_alias=True)

