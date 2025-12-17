"""
Test settings endpoints using httpx.

These tests match the endpoints from PHP SettingsController:
- GET /v1/airline/{airline_identifier}/settings
- POST /v1/airline/{airline_identifier}/settings
"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_settings_defaults(client: AsyncClient):
    """Test getting default settings when none exist."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.settings.defaults.123",
            "airline_name": "Settings Defaults Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Get settings (should return defaults)
    response = await client.get(
        f"/v1/airline/{airline_identifier}/settings",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["backgroundColor"] == "rgb(189,144,71)"
    assert data["foregroundColor"] == "rgb(0,0,0)"
    assert data["labelColor"] == "rgb(255,255,255)"
    assert data["customLabel"] == "Boarding Group"
    assert data["customLabelEnabled"] is True
    print("✅ Retrieved default settings")


@pytest.mark.asyncio
async def test_update_settings(client: AsyncClient):
    """Test updating settings."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.update.settings.123",
            "airline_name": "Update Settings Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Update settings
    response = await client.post(
        f"/v1/airline/{airline_identifier}/settings",
        json={
            "backgroundColor": "rgb(255,0,0)",
            "customLabel": "Priority Boarding",
            "customLabelEnabled": False
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["backgroundColor"] == "rgb(255,0,0)"
    assert data["customLabel"] == "Priority Boarding"
    assert data["customLabelEnabled"] is False
    # Other fields should remain at defaults
    assert data["foregroundColor"] == "rgb(0,0,0)"
    assert data["labelColor"] == "rgb(255,255,255)"
    print("✅ Updated settings")
    
    # Verify by getting settings again
    get_response = await client.get(
        f"/v1/airline/{airline_identifier}/settings",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert get_response.status_code == 200
    get_data = get_response.json()
    assert get_data["backgroundColor"] == "rgb(255,0,0)"
    assert get_data["customLabel"] == "Priority Boarding"
    assert get_data["customLabelEnabled"] is False
    print("✅ Verified settings persisted")


@pytest.mark.asyncio
async def test_update_settings_partial(client: AsyncClient):
    """Test partial update of settings (only some fields)."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.partial.settings.123",
            "airline_name": "Partial Settings Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # First, set some custom values
    await client.post(
        f"/v1/airline/{airline_identifier}/settings",
        json={
            "backgroundColor": "rgb(0,255,0)",
            "foregroundColor": "rgb(255,255,255)",
            "customLabel": "VIP"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    # Then update only one field
    response = await client.post(
        f"/v1/airline/{airline_identifier}/settings",
        json={
            "customLabel": "Updated VIP"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    # Updated field
    assert data["customLabel"] == "Updated VIP"
    # Previously set fields should remain
    assert data["backgroundColor"] == "rgb(0,255,0)"
    assert data["foregroundColor"] == "rgb(255,255,255)"
    # Default fields should remain
    assert data["labelColor"] == "rgb(255,255,255)"
    assert data["customLabelEnabled"] is True
    print("✅ Partial update worked correctly")


@pytest.mark.asyncio
async def test_settings_authentication_failure(client: AsyncClient):
    """Test that invalid bearer token returns 401."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.auth.settings.123",
            "airline_name": "Auth Settings Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    
    # Try to access with invalid token
    response = await client.get(
        f"/v1/airline/{airline_identifier}/settings",
        headers={"Authorization": "Bearer wrong_token"}
    )
    
    assert response.status_code == 401
    data = response.json()
    assert "Invalid Bearer Token" in data["detail"]
    print("✅ Authentication failure handled correctly")

