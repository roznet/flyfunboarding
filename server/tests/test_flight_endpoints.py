"""
Test flight endpoints using httpx.

These tests match the endpoints from tests/test.zsh:
- POST /v1/airline/{airline_identifier}/flight/plan/{aircraft_identifier}
- GET /v1/airline/{airline_identifier}/flight/list
- GET /v1/airline/{airline_identifier}/flight/{flight_identifier}
- GET /v1/airline/{airline_identifier}/flight/{flight_identifier}/tickets
- DELETE /v1/airline/{airline_identifier}/flight/{flight_identifier}
- POST /v1/airline/{airline_identifier}/flight/check/{flight_identifier}
"""
import pytest
from httpx import AsyncClient
from datetime import datetime, timedelta


@pytest.mark.asyncio
async def test_plan_flight(client: AsyncClient):
    """Test planning/creating a flight (requires airline and aircraft)."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # First create an airline
    airline_response = await client.post(
        "/api/v1/airline/create",
        json={
            "apple_identifier": "test.flight.airline.123",
            "airline_name": "Flight Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Create an aircraft
    aircraft_response = await client.post(
        f"/api/v1/airline/{airline_identifier}/aircraft/create",
        json={
            "registration": "N12345",
            "type": "Cessna 172"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if aircraft_response.status_code != 200:
        pytest.skip("Could not create test aircraft")
    
    aircraft_identifier = aircraft_response.json()["aircraft_identifier"]
    
    # Plan a flight
    scheduled_date = (datetime.now() + timedelta(days=1)).isoformat()
    response = await client.post(
        f"/api/v1/airline/{airline_identifier}/flight/plan/{aircraft_identifier}",
        json={
            "origin": {
                "icao": "EGLL",
                "timezone_identifier": "Europe/London"
            },
            "destination": {
                "icao": "KJFK",
                "timezone_identifier": "America/New_York"
            },
            "gate": "A12",
            "flightNumber": "FF123",
            "scheduledDepartureDate": scheduled_date
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert "flight_identifier" in data
    assert data["gate"] == "A12"
    assert data["flightNumber"] == "FF123"
    assert "origin" in data
    assert "destination" in data
    assert "aircraft" in data
    print(f"✅ Created flight: {data['flight_identifier']}")


@pytest.mark.asyncio
async def test_list_flights(client: AsyncClient):
    """Test listing flights."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/api/v1/airline/create",
        json={
            "apple_identifier": "test.list.flights.123",
            "airline_name": "List Flights Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Create aircraft
    aircraft_response = await client.post(
        f"/api/v1/airline/{airline_identifier}/aircraft/create",
        json={
            "registration": "N99999",
            "type": "Piper PA-28"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if aircraft_response.status_code != 200:
        pytest.skip("Could not create test aircraft")
    
    aircraft_identifier = aircraft_response.json()["aircraft_identifier"]
    
    # Create a couple of flights
    scheduled_date = (datetime.now() + timedelta(days=1)).isoformat()
    for i in range(2):
        await client.post(
            f"/api/v1/airline/{airline_identifier}/flight/plan/{aircraft_identifier}",
            json={
                "origin": {
                    "icao": "EGLL",
                    "timezone_identifier": "Europe/London"
                },
                "destination": {
                    "icao": "KJFK",
                    "timezone_identifier": "America/New_York"
                },
                "gate": f"A{i+1}",
                "flightNumber": f"FF{i+1}",
                "scheduledDepartureDate": scheduled_date
            },
            headers={"Authorization": f"Bearer {apple_identifier}"}
        )
    
    # List flights
    response = await client.get(
        f"/api/v1/airline/{airline_identifier}/flight/list",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 2
    print(f"✅ Listed {len(data)} flights")


@pytest.mark.asyncio
async def test_get_flight(client: AsyncClient):
    """Test getting a flight by identifier."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/api/v1/airline/create",
        json={
            "apple_identifier": "test.get.flight.123",
            "airline_name": "Get Flight Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Create aircraft
    aircraft_response = await client.post(
        f"/api/v1/airline/{airline_identifier}/aircraft/create",
        json={
            "registration": "N77777",
            "type": "Beechcraft Bonanza"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if aircraft_response.status_code != 200:
        pytest.skip("Could not create test aircraft")
    
    aircraft_identifier = aircraft_response.json()["aircraft_identifier"]
    
    # Create flight
    scheduled_date = (datetime.now() + timedelta(days=1)).isoformat()
    create_response = await client.post(
        f"/api/v1/airline/{airline_identifier}/flight/plan/{aircraft_identifier}",
        json={
            "origin": {
                "icao": "EGLL",
                "timezone_identifier": "Europe/London"
            },
            "destination": {
                "icao": "KJFK",
                "timezone_identifier": "America/New_York"
            },
            "gate": "B15",
            "flightNumber": "FF456",
            "scheduledDepartureDate": scheduled_date
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if create_response.status_code != 200:
        pytest.skip("Could not create test flight")
    
    flight_identifier = create_response.json()["flight_identifier"]
    
    # Get flight
    response = await client.get(
        f"/api/v1/airline/{airline_identifier}/flight/{flight_identifier}",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["flight_identifier"] == flight_identifier
    assert data["gate"] == "B15"
    assert data["flightNumber"] == "FF456"
    print(f"✅ Retrieved flight: {flight_identifier}")


@pytest.mark.asyncio
async def test_get_flight_not_found(client: AsyncClient):
    """Test getting a non-existent flight returns 404."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/api/v1/airline/create",
        json={
            "apple_identifier": "test.notfound.flight.123",
            "airline_name": "Not Found Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Try to get non-existent flight
    response = await client.get(
        f"/api/v1/airline/{airline_identifier}/flight/nonexistent123",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 404
    data = response.json()
    assert "not found" in data["detail"].lower()
    print("✅ Not found error handled correctly")


@pytest.mark.asyncio
async def test_list_flight_tickets(client: AsyncClient):
    """Test listing tickets for a flight."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/api/v1/airline/create",
        json={
            "apple_identifier": "test.flight.tickets.123",
            "airline_name": "Flight Tickets Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Create aircraft
    aircraft_response = await client.post(
        f"/api/v1/airline/{airline_identifier}/aircraft/create",
        json={
            "registration": "N55555",
            "type": "Cessna 182"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if aircraft_response.status_code != 200:
        pytest.skip("Could not create test aircraft")
    
    aircraft_identifier = aircraft_response.json()["aircraft_identifier"]
    
    # Create flight
    scheduled_date = (datetime.now() + timedelta(days=1)).isoformat()
    flight_response = await client.post(
        f"/api/v1/airline/{airline_identifier}/flight/plan/{aircraft_identifier}",
        json={
            "origin": {
                "icao": "EGLL",
                "timezone_identifier": "Europe/London"
            },
            "destination": {
                "icao": "KJFK",
                "timezone_identifier": "America/New_York"
            },
            "gate": "C20",
            "flightNumber": "FF789",
            "scheduledDepartureDate": scheduled_date
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if flight_response.status_code != 200:
        pytest.skip("Could not create test flight")
    
    flight_identifier = flight_response.json()["flight_identifier"]
    
    # List tickets (should be empty for now)
    response = await client.get(
        f"/api/v1/airline/{airline_identifier}/flight/{flight_identifier}/tickets",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    # Should be empty since we haven't created any tickets yet
    assert len(data) == 0
    print(f"✅ Listed tickets for flight (empty list as expected)")


@pytest.mark.asyncio
async def test_delete_flight(client: AsyncClient):
    """Test deleting a flight."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/api/v1/airline/create",
        json={
            "apple_identifier": "test.delete.flight.123",
            "airline_name": "Delete Flight Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Create aircraft
    aircraft_response = await client.post(
        f"/api/v1/airline/{airline_identifier}/aircraft/create",
        json={
            "registration": "N44444",
            "type": "Cessna 152"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if aircraft_response.status_code != 200:
        pytest.skip("Could not create test aircraft")
    
    aircraft_identifier = aircraft_response.json()["aircraft_identifier"]
    
    # Create flight
    scheduled_date = (datetime.now() + timedelta(days=1)).isoformat()
    create_response = await client.post(
        f"/api/v1/airline/{airline_identifier}/flight/plan/{aircraft_identifier}",
        json={
            "origin": {
                "icao": "EGLL",
                "timezone_identifier": "Europe/London"
            },
            "destination": {
                "icao": "KJFK",
                "timezone_identifier": "America/New_York"
            },
            "gate": "D25",
            "flightNumber": "FF999",
            "scheduledDepartureDate": scheduled_date
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if create_response.status_code != 200:
        pytest.skip("Could not create test flight")
    
    flight_identifier = create_response.json()["flight_identifier"]
    
    # Delete flight
    response = await client.delete(
        f"/api/v1/airline/{airline_identifier}/flight/{flight_identifier}",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == 1
    assert data["flight_identifier"] == flight_identifier
    print(f"✅ Deleted flight: {flight_identifier}")


@pytest.mark.asyncio
async def test_check_flight(client: AsyncClient):
    """Test checking/validating a flight."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/api/v1/airline/create",
        json={
            "apple_identifier": "test.check.flight.123",
            "airline_name": "Check Flight Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Create aircraft
    aircraft_response = await client.post(
        f"/api/v1/airline/{airline_identifier}/aircraft/create",
        json={
            "registration": "N33333",
            "type": "Cessna 172"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if aircraft_response.status_code != 200:
        pytest.skip("Could not create test aircraft")
    
    aircraft_identifier = aircraft_response.json()["aircraft_identifier"]
    
    # Create flight
    scheduled_date = (datetime.now() + timedelta(days=1)).isoformat()
    create_response = await client.post(
        f"/api/v1/airline/{airline_identifier}/flight/plan/{aircraft_identifier}",
        json={
            "origin": {
                "icao": "EGLL",
                "timezone_identifier": "Europe/London"
            },
            "destination": {
                "icao": "KJFK",
                "timezone_identifier": "America/New_York"
            },
            "gate": "E30",
            "flightNumber": "FF111",
            "scheduledDepartureDate": scheduled_date
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if create_response.status_code != 200:
        pytest.skip("Could not create test flight")
    
    flight_identifier = create_response.json()["flight_identifier"]
    
    # Check flight
    response = await client.post(
        f"/api/v1/airline/{airline_identifier}/flight/check/{flight_identifier}",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["flight_identifier"] == flight_identifier
    assert data["gate"] == "E30"
    assert data["flightNumber"] == "FF111"
    print(f"✅ Checked flight: {flight_identifier}")


@pytest.mark.asyncio
async def test_flight_authentication_failure(client: AsyncClient):
    """Test that invalid bearer token returns 401."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/api/v1/airline/create",
        json={
            "apple_identifier": "test.auth.flight.123",
            "airline_name": "Auth Flight Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    
    # Try to access with invalid token
    response = await client.get(
        f"/api/v1/airline/{airline_identifier}/flight/list",
        headers={"Authorization": "Bearer wrong_token"}
    )
    
    assert response.status_code == 401
    data = response.json()
    assert "Invalid Bearer Token" in data["detail"]
    print("✅ Authentication failure handled correctly")

