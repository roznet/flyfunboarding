"""
Test aircraft endpoints using httpx.

These tests match the endpoints from tests/test.zsh:
- POST /v1/airline/{airline_identifier}/aircraft/create
- GET /v1/airline/{airline_identifier}/aircraft/list
- GET /v1/airline/{airline_identifier}/aircraft/{aircraft_identifier}
- GET /v1/airline/{airline_identifier}/aircraft/{aircraft_identifier}/flights
"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_aircraft(client: AsyncClient):
    """Test creating an aircraft (requires airline)."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # First create an airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.aircraft.airline.123",
            "airline_name": "Aircraft Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Create aircraft
    response = await client.post(
        f"/v1/airline/{airline_identifier}/aircraft/create",
        json={
            "registration": "N12345",
            "type": "Cessna 172"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert "aircraft_identifier" in data
    assert data["registration"] == "N12345"
    assert data["type"] == "Cessna 172"
    print(f"✅ Created aircraft: {data['aircraft_identifier']}")


@pytest.mark.asyncio
async def test_list_aircrafts(client: AsyncClient):
    """Test listing aircrafts."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.list.aircrafts.123",
            "airline_name": "List Aircrafts Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Create a couple of aircrafts
    for i in range(2):
        await client.post(
            f"/v1/airline/{airline_identifier}/aircraft/create",
            json={
                "registration": f"N{i+1}2345",
                "type": f"Cessna {172+i}"
            },
            headers={"Authorization": f"Bearer {apple_identifier}"}
        )
    
    # List aircrafts
    response = await client.get(
        f"/v1/airline/{airline_identifier}/aircraft/list",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 2
    print(f"✅ Listed {len(data)} aircrafts")


@pytest.mark.asyncio
async def test_get_aircraft(client: AsyncClient):
    """Test getting an aircraft by identifier."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.get.aircraft.123",
            "airline_name": "Get Aircraft Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Create aircraft
    create_response = await client.post(
        f"/v1/airline/{airline_identifier}/aircraft/create",
        json={
            "registration": "N99999",
            "type": "Piper PA-28"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if create_response.status_code != 200:
        pytest.skip("Could not create test aircraft")
    
    aircraft_identifier = create_response.json()["aircraft_identifier"]
    
    # Get aircraft
    response = await client.get(
        f"/v1/airline/{airline_identifier}/aircraft/{aircraft_identifier}",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["aircraft_identifier"] == aircraft_identifier
    assert data["registration"] == "N99999"
    assert data["type"] == "Piper PA-28"
    print(f"✅ Retrieved aircraft: {aircraft_identifier}")


@pytest.mark.asyncio
async def test_get_aircraft_not_found(client: AsyncClient):
    """Test getting a non-existent aircraft returns 404."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.notfound.aircraft.123",
            "airline_name": "Not Found Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Try to get non-existent aircraft
    response = await client.get(
        f"/v1/airline/{airline_identifier}/aircraft/nonexistent123",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 404
    data = response.json()
    assert "not found" in data["detail"].lower()
    print("✅ Not found error handled correctly")


@pytest.mark.asyncio
async def test_list_aircraft_flights(client: AsyncClient):
    """Test listing flights for an aircraft."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.aircraft.flights.123",
            "airline_name": "Aircraft Flights Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Create aircraft
    aircraft_response = await client.post(
        f"/v1/airline/{airline_identifier}/aircraft/create",
        json={
            "registration": "N77777",
            "type": "Beechcraft Bonanza"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if aircraft_response.status_code != 200:
        pytest.skip("Could not create test aircraft")
    
    aircraft_identifier = aircraft_response.json()["aircraft_identifier"]
    
    # List flights (should be empty for now)
    response = await client.get(
        f"/v1/airline/{airline_identifier}/aircraft/{aircraft_identifier}/flights",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    # Should be empty since we haven't created any flights yet
    assert len(data) == 0
    print(f"✅ Listed flights for aircraft (empty list as expected)")


@pytest.mark.asyncio
async def test_aircraft_authentication_failure(client: AsyncClient):
    """Test that invalid bearer token returns 401."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.auth.aircraft.123",
            "airline_name": "Auth Aircraft Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    
    # Try to access with invalid token
    response = await client.get(
        f"/v1/airline/{airline_identifier}/aircraft/list",
        headers={"Authorization": "Bearer wrong_token"}
    )
    
    assert response.status_code == 401
    data = response.json()
    assert "Invalid Bearer Token" in data["detail"]
    print("✅ Authentication failure handled correctly")

