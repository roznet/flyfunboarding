"""
Base model with PHP-compatible JSON serialization.

Matches behavior of PHP's JsonHelper::toJson().
"""
from datetime import datetime, timedelta
from typing import Any
from pydantic import BaseModel, ConfigDict


def timedelta_to_iso8601(td: timedelta) -> str:
    """Convert Python timedelta to ISO 8601 duration format (PT2H30M0S)."""
    total_seconds = int(td.total_seconds())
    hours = total_seconds // 3600
    minutes = (total_seconds % 3600) // 60
    seconds = total_seconds % 60
    return f"PT{hours}H{minutes}M{seconds}S"


def iso8601_to_timedelta(duration: str) -> timedelta:
    """Parse ISO 8601 duration (PT2H30M0S) to timedelta."""
    import re

    match = re.match(r"PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?", duration)
    if not match:
        raise ValueError(f"Invalid ISO 8601 duration: {duration}")
    hours = int(match.group(1) or 0)
    minutes = int(match.group(2) or 0)
    seconds = int(match.group(3) or 0)
    return timedelta(hours=hours, minutes=minutes, seconds=seconds)


class BaseJsonModel(BaseModel):
    """
    Base model with PHP-compatible JSON serialization.

    Key behaviors matching PHP JsonHelper:
    - Excludes fields that match their default values
    - DateTime serialized as ISO 8601 ('c' format in PHP)
    - DateInterval serialized as ISO 8601 duration (PT2H30M0S)
    - Supports uniqueIdentifier() pattern for extra fields
    """

    model_config = ConfigDict(
        populate_by_name=True,  # Allow both field name and alias
        use_enum_values=True,
        json_encoders={
            datetime: lambda v: (v.isoformat() + "+00:00" if v.tzinfo is None else v.isoformat()) if v else None,
            timedelta: timedelta_to_iso8601,
        },
    )

    def to_json(self) -> dict[str, Any]:
        """
        PHP-compatible JSON serialization.

        Matches behavior of PHP's JsonHelper::toJson().
        """
        # Exclude defaults to match PHP behavior
        data = self.model_dump(
            exclude_defaults=True,
            by_alias=True,
            mode="json",  # Use JSON-compatible types
        )

        # Merge unique_identifier fields if method exists
        if hasattr(self, "unique_identifier"):
            data.update(self.unique_identifier())

        return data

    def unique_identifier(self) -> dict[str, Any]:
        """
        Override in subclasses to add extra fields to JSON output.

        Matches PHP's uniqueIdentifier() pattern.
        """
        return {}

