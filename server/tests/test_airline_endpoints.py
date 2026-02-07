"""
Test airline endpoints using httpx.

These tests match the endpoints from tests/test.zsh:
- POST /v1/airline/create
- GET /v1/airline/{airline_identifier}
- GET /v1/airline/{airline_identifier}/keys
"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_health_check(client: AsyncClient):
    """Test the health check endpoint."""
    response = await client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    print("✅ Health check passed")


@pytest.mark.asyncio
async def test_create_airline(client: AsyncClient):
    """Test creating an airline (requires SECRET in .env)."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    response = await client.post(
        "/api/v1/airline/create",
        json={
            "apple_identifier": "test.apple.id.123",
            "airline_name": "Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert "airline_identifier" in data
    assert data["apple_identifier"] == "test.apple.id.123"
    print(f"✅ Created airline: {data['airline_identifier']}")


@pytest.mark.asyncio
async def test_get_airline(client: AsyncClient):
    """Test getting an airline by identifier."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # First create an airline
    create_response = await client.post(
        "/api/v1/airline/create",
        json={
            "apple_identifier": "test.get.airline.123",
            "airline_name": "Get Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if create_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = create_response.json()["airline_identifier"]
    apple_identifier = create_response.json()["apple_identifier"]
    
    # Now get it
    response = await client.get(
        f"/api/v1/airline/{airline_identifier}",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["airline_identifier"] == airline_identifier
    assert data["apple_identifier"] == apple_identifier
    print(f"✅ Retrieved airline: {airline_identifier}")


@pytest.mark.asyncio
async def test_get_airline_keys(client: AsyncClient):
    """Test getting airline's public keys."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline first
    create_response = await client.post(
        "/api/v1/airline/create",
        json={
            "apple_identifier": "test.keys.airline.123",
            "airline_name": "Keys Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if create_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = create_response.json()["airline_identifier"]
    apple_identifier = create_response.json()["apple_identifier"]
    
    # Get keys
    response = await client.get(
        f"/api/v1/airline/{airline_identifier}/keys",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    # Keys endpoint should return an array (even if empty for now)
    assert isinstance(data, list)
    print(f"✅ Retrieved keys for airline: {airline_identifier}")


@pytest.mark.asyncio
async def test_airline_authentication_failure(client: AsyncClient):
    """Test that invalid bearer token returns 401."""
    from app.config import settings

    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")

    # First create a valid airline
    create_response = await client.post(
        "/api/v1/airline/create",
        json={
            "apple_identifier": "test.auth.failure.123",
            "airline_name": "Auth Failure Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )

    if create_response.status_code != 200:
        pytest.skip("Could not create test airline")

    airline_identifier = create_response.json()["airline_identifier"]

    # Now try to access it with an INVALID token
    response = await client.get(
        f"/api/v1/airline/{airline_identifier}",
        headers={"Authorization": "Bearer wrong_token"}
    )

    assert response.status_code == 401
    data = response.json()
    assert "Invalid Bearer Token" in data["detail"]
    print("✅ Authentication failure handled correctly")

