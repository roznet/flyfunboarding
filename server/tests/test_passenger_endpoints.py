"""
Test passenger endpoints using httpx.

These tests match the endpoints from tests/test.zsh:
- POST /v1/airline/{airline_identifier}/passenger/create
- GET /v1/airline/{airline_identifier}/passenger/list
- GET /v1/airline/{airline_identifier}/passenger/{passenger_identifier}
- GET /v1/airline/{airline_identifier}/passenger/{passenger_identifier}/tickets
"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_passenger(client: AsyncClient):
    """Test creating a passenger (requires airline)."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # First create an airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.passenger.airline.123",
            "airline_name": "Passenger Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Create passenger
    response = await client.post(
        f"/v1/airline/{airline_identifier}/passenger/create",
        json={
            "formattedName": "John Doe",
            "firstName": "John",
            "lastName": "Doe",
            "apple_identifier": "passenger.apple.id.123"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert "passenger_identifier" in data
    assert data["formattedName"] == "John Doe"
    assert data["apple_identifier"] == "passenger.apple.id.123"
    print(f"✅ Created passenger: {data['passenger_identifier']}")


@pytest.mark.asyncio
async def test_list_passengers(client: AsyncClient):
    """Test listing passengers."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.list.passengers.123",
            "airline_name": "List Passengers Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Create a couple of passengers
    for i in range(2):
        await client.post(
            f"/v1/airline/{airline_identifier}/passenger/create",
            json={
                "formattedName": f"Passenger {i+1}",
                "firstName": f"First{i+1}",
                "lastName": f"Last{i+1}",
                "apple_identifier": f"passenger.apple.id.{i+1}"
            },
            headers={"Authorization": f"Bearer {apple_identifier}"}
        )
    
    # List passengers
    response = await client.get(
        f"/v1/airline/{airline_identifier}/passenger/list",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 2
    print(f"✅ Listed {len(data)} passengers")


@pytest.mark.asyncio
async def test_get_passenger(client: AsyncClient):
    """Test getting a passenger by identifier."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.get.passenger.123",
            "airline_name": "Get Passenger Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Create passenger
    create_response = await client.post(
        f"/v1/airline/{airline_identifier}/passenger/create",
        json={
            "formattedName": "Jane Smith",
            "firstName": "Jane",
            "middleName": "Middle",
            "lastName": "Smith",
            "apple_identifier": "jane.apple.id.123"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if create_response.status_code != 200:
        pytest.skip("Could not create test passenger")
    
    passenger_identifier = create_response.json()["passenger_identifier"]
    
    # Get passenger
    response = await client.get(
        f"/v1/airline/{airline_identifier}/passenger/{passenger_identifier}",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["passenger_identifier"] == passenger_identifier
    assert data["formattedName"] == "Jane Smith"
    assert data["firstName"] == "Jane"
    assert data["lastName"] == "Smith"
    print(f"✅ Retrieved passenger: {passenger_identifier}")


@pytest.mark.asyncio
async def test_get_passenger_not_found(client: AsyncClient):
    """Test getting a non-existent passenger returns 404."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.notfound.passenger.123",
            "airline_name": "Not Found Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Try to get non-existent passenger
    response = await client.get(
        f"/v1/airline/{airline_identifier}/passenger/nonexistent123",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 404
    data = response.json()
    assert "not found" in data["detail"].lower()
    print("✅ Not found error handled correctly")


@pytest.mark.asyncio
async def test_list_passenger_tickets(client: AsyncClient):
    """Test listing tickets for a passenger."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.passenger.tickets.123",
            "airline_name": "Passenger Tickets Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Create passenger
    passenger_response = await client.post(
        f"/v1/airline/{airline_identifier}/passenger/create",
        json={
            "formattedName": "Ticket Holder",
            "firstName": "Ticket",
            "lastName": "Holder",
            "apple_identifier": "ticket.holder.apple.id.123"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if passenger_response.status_code != 200:
        pytest.skip("Could not create test passenger")
    
    passenger_identifier = passenger_response.json()["passenger_identifier"]
    
    # List tickets (should be empty for now)
    response = await client.get(
        f"/v1/airline/{airline_identifier}/passenger/{passenger_identifier}/tickets",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    # Should be empty since we haven't created any tickets yet
    assert len(data) == 0
    print(f"✅ Listed tickets for passenger (empty list as expected)")


@pytest.mark.asyncio
async def test_passenger_authentication_failure(client: AsyncClient):
    """Test that invalid bearer token returns 401."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.auth.passenger.123",
            "airline_name": "Auth Passenger Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    
    # Try to access with invalid token
    response = await client.get(
        f"/v1/airline/{airline_identifier}/passenger/list",
        headers={"Authorization": "Bearer wrong_token"}
    )
    
    assert response.status_code == 401
    data = response.json()
    assert "Invalid Bearer Token" in data["detail"]
    print("✅ Authentication failure handled correctly")

