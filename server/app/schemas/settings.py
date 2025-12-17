"""
API schemas for Settings endpoints.
"""
from typing import Optional
from pydantic import BaseModel, Field


class SettingsUpdate(BaseModel):
    """Schema for updating settings."""
    background_color: Optional[str] = Field(None, alias="backgroundColor")
    foreground_color: Optional[str] = Field(None, alias="foregroundColor")
    label_color: Optional[str] = Field(None, alias="labelColor")
    custom_label: Optional[str] = Field(None, alias="customLabel")
    custom_label_enabled: Optional[bool] = Field(None, alias="customLabelEnabled")

    class Config:
        populate_by_name = True


class SettingsResponse(BaseModel):
    """Schema for settings API responses."""
    background_color: str = Field(..., alias="backgroundColor")
    foreground_color: str = Field(..., alias="foregroundColor")
    label_color: str = Field(..., alias="labelColor")
    custom_label: str = Field(..., alias="customLabel")
    custom_label_enabled: bool = Field(..., alias="customLabelEnabled")

    class Config:
        populate_by_name = True

