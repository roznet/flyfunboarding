"""
Test ticket endpoints using httpx.

These tests match the endpoints from tests/test.zsh:
- POST /v1/airline/{airline_identifier}/ticket/issue/{flight_identifier}/{passenger_identifier}
- GET /v1/airline/{airline_identifier}/ticket/list
- GET /v1/airline/{airline_identifier}/ticket/{ticket_identifier}
- DELETE /v1/airline/{airline_identifier}/ticket/{ticket_identifier}
- POST /v1/airline/{airline_identifier}/ticket/verify
"""
import pytest
from httpx import AsyncClient
from datetime import datetime, timedelta


@pytest.mark.asyncio
async def test_issue_ticket(client: AsyncClient):
    """Test issuing a ticket (requires airline, flight, and passenger)."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.ticket.airline.123",
            "airline_name": "Ticket Test Airline"
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
            "registration": "N12345",
            "type": "Cessna 172"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if aircraft_response.status_code != 200:
        pytest.skip("Could not create test aircraft")
    
    aircraft_identifier = aircraft_response.json()["aircraft_identifier"]
    
    # Create flight
    scheduled_date = (datetime.now() + timedelta(days=1)).isoformat()
    flight_response = await client.post(
        f"/v1/airline/{airline_identifier}/flight/plan/{aircraft_identifier}",
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
    
    if flight_response.status_code != 200:
        pytest.skip("Could not create test flight")
    
    flight_identifier = flight_response.json()["flight_identifier"]
    
    # Create passenger
    passenger_response = await client.post(
        f"/v1/airline/{airline_identifier}/passenger/create",
        json={
            "formattedName": "John Doe",
            "firstName": "John",
            "lastName": "Doe",
            "apple_identifier": "passenger.apple.id.123"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if passenger_response.status_code != 200:
        pytest.skip("Could not create test passenger")
    
    passenger_identifier = passenger_response.json()["passenger_identifier"]
    
    # Issue ticket
    response = await client.post(
        f"/v1/airline/{airline_identifier}/ticket/issue/{flight_identifier}/{passenger_identifier}",
        json={
            "seatNumber": "12A",
            "customLabelValue": "1"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert "ticket_identifier" in data
    assert data["seatNumber"] == "12A"
    assert "passenger" in data
    assert "flight" in data
    print(f"✅ Issued ticket: {data['ticket_identifier']}")


@pytest.mark.asyncio
async def test_list_tickets(client: AsyncClient):
    """Test listing tickets."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.list.tickets.123",
            "airline_name": "List Tickets Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Create aircraft, flight, and passenger
    aircraft_response = await client.post(
        f"/v1/airline/{airline_identifier}/aircraft/create",
        json={
            "registration": "N99999",
            "type": "Piper PA-28"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if aircraft_response.status_code != 200:
        pytest.skip("Could not create test aircraft")
    
    aircraft_identifier = aircraft_response.json()["aircraft_identifier"]
    
    scheduled_date = (datetime.now() + timedelta(days=1)).isoformat()
    flight_response = await client.post(
        f"/v1/airline/{airline_identifier}/flight/plan/{aircraft_identifier}",
        json={
            "origin": {"icao": "EGLL", "timezone_identifier": "Europe/London"},
            "destination": {"icao": "KJFK", "timezone_identifier": "America/New_York"},
            "gate": "B15",
            "flightNumber": "FF456",
            "scheduledDepartureDate": scheduled_date
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if flight_response.status_code != 200:
        pytest.skip("Could not create test flight")
    
    flight_identifier = flight_response.json()["flight_identifier"]
    
    passenger_response = await client.post(
        f"/v1/airline/{airline_identifier}/passenger/create",
        json={
            "formattedName": "Jane Smith",
            "firstName": "Jane",
            "lastName": "Smith",
            "apple_identifier": "jane.apple.id.123"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if passenger_response.status_code != 200:
        pytest.skip("Could not create test passenger")
    
    passenger_identifier = passenger_response.json()["passenger_identifier"]
    
    # Issue a couple of tickets (on different flights or passengers)
    for i in range(2):
        await client.post(
            f"/v1/airline/{airline_identifier}/ticket/issue/{flight_identifier}/{passenger_identifier}",
            json={
                "seatNumber": f"{i+1}A",
                "customLabelValue": "1"
            },
            headers={"Authorization": f"Bearer {apple_identifier}"}
        )
    
    # List tickets
    response = await client.get(
        f"/v1/airline/{airline_identifier}/ticket/list",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    # Note: Only one ticket per passenger per flight, so we might have 1 or 2 depending on if they're on same flight
    assert len(data) >= 1
    print(f"✅ Listed {len(data)} tickets")


@pytest.mark.asyncio
async def test_get_ticket(client: AsyncClient):
    """Test getting a ticket by identifier."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.get.ticket.123",
            "airline_name": "Get Ticket Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Create aircraft, flight, and passenger
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
    
    scheduled_date = (datetime.now() + timedelta(days=1)).isoformat()
    flight_response = await client.post(
        f"/v1/airline/{airline_identifier}/flight/plan/{aircraft_identifier}",
        json={
            "origin": {"icao": "EGLL", "timezone_identifier": "Europe/London"},
            "destination": {"icao": "KJFK", "timezone_identifier": "America/New_York"},
            "gate": "C20",
            "flightNumber": "FF789",
            "scheduledDepartureDate": scheduled_date
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if flight_response.status_code != 200:
        pytest.skip("Could not create test flight")
    
    flight_identifier = flight_response.json()["flight_identifier"]
    
    passenger_response = await client.post(
        f"/v1/airline/{airline_identifier}/passenger/create",
        json={
            "formattedName": "Bob Johnson",
            "firstName": "Bob",
            "lastName": "Johnson",
            "apple_identifier": "bob.apple.id.123"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if passenger_response.status_code != 200:
        pytest.skip("Could not create test passenger")
    
    passenger_identifier = passenger_response.json()["passenger_identifier"]
    
    # Issue ticket
    create_response = await client.post(
        f"/v1/airline/{airline_identifier}/ticket/issue/{flight_identifier}/{passenger_identifier}",
        json={
            "seatNumber": "15B",
            "customLabelValue": "2"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if create_response.status_code != 200:
        pytest.skip("Could not create test ticket")
    
    ticket_identifier = create_response.json()["ticket_identifier"]
    
    # Get ticket
    response = await client.get(
        f"/v1/airline/{airline_identifier}/ticket/{ticket_identifier}",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["ticket_identifier"] == ticket_identifier
    assert data["seatNumber"] == "15B"
    assert "passenger" in data
    assert "flight" in data
    print(f"✅ Retrieved ticket: {ticket_identifier}")


@pytest.mark.asyncio
async def test_get_ticket_not_found(client: AsyncClient):
    """Test getting a non-existent ticket returns 404."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.notfound.ticket.123",
            "airline_name": "Not Found Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Try to get non-existent ticket
    response = await client.get(
        f"/v1/airline/{airline_identifier}/ticket/nonexistent123",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 404
    data = response.json()
    assert "not found" in data["detail"].lower()
    print("✅ Not found error handled correctly")


@pytest.mark.asyncio
async def test_delete_ticket(client: AsyncClient):
    """Test deleting a ticket."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.delete.ticket.123",
            "airline_name": "Delete Ticket Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Create aircraft, flight, and passenger
    aircraft_response = await client.post(
        f"/v1/airline/{airline_identifier}/aircraft/create",
        json={
            "registration": "N55555",
            "type": "Cessna 182"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if aircraft_response.status_code != 200:
        pytest.skip("Could not create test aircraft")
    
    aircraft_identifier = aircraft_response.json()["aircraft_identifier"]
    
    scheduled_date = (datetime.now() + timedelta(days=1)).isoformat()
    flight_response = await client.post(
        f"/v1/airline/{airline_identifier}/flight/plan/{aircraft_identifier}",
        json={
            "origin": {"icao": "EGLL", "timezone_identifier": "Europe/London"},
            "destination": {"icao": "KJFK", "timezone_identifier": "America/New_York"},
            "gate": "D25",
            "flightNumber": "FF999",
            "scheduledDepartureDate": scheduled_date
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if flight_response.status_code != 200:
        pytest.skip("Could not create test flight")
    
    flight_identifier = flight_response.json()["flight_identifier"]
    
    passenger_response = await client.post(
        f"/v1/airline/{airline_identifier}/passenger/create",
        json={
            "formattedName": "Alice Brown",
            "firstName": "Alice",
            "lastName": "Brown",
            "apple_identifier": "alice.apple.id.123"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if passenger_response.status_code != 200:
        pytest.skip("Could not create test passenger")
    
    passenger_identifier = passenger_response.json()["passenger_identifier"]
    
    # Issue ticket
    create_response = await client.post(
        f"/v1/airline/{airline_identifier}/ticket/issue/{flight_identifier}/{passenger_identifier}",
        json={
            "seatNumber": "20C",
            "customLabelValue": "3"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if create_response.status_code != 200:
        pytest.skip("Could not create test ticket")
    
    ticket_identifier = create_response.json()["ticket_identifier"]
    
    # Delete ticket
    response = await client.delete(
        f"/v1/airline/{airline_identifier}/ticket/{ticket_identifier}",
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == 1
    assert data["ticket_identifier"] == ticket_identifier
    print(f"✅ Deleted ticket: {ticket_identifier}")


@pytest.mark.asyncio
async def test_verify_ticket(client: AsyncClient):
    """Test verifying a ticket with signature digest."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.verify.ticket.123",
            "airline_name": "Verify Ticket Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    apple_identifier = airline_response.json()["apple_identifier"]
    
    # Create aircraft, flight, and passenger
    aircraft_response = await client.post(
        f"/v1/airline/{airline_identifier}/aircraft/create",
        json={
            "registration": "N33333",
            "type": "Cessna 172"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if aircraft_response.status_code != 200:
        pytest.skip("Could not create test aircraft")
    
    aircraft_identifier = aircraft_response.json()["aircraft_identifier"]
    
    scheduled_date = (datetime.now() + timedelta(days=1)).isoformat()
    flight_response = await client.post(
        f"/v1/airline/{airline_identifier}/flight/plan/{aircraft_identifier}",
        json={
            "origin": {"icao": "EGLL", "timezone_identifier": "Europe/London"},
            "destination": {"icao": "KJFK", "timezone_identifier": "America/New_York"},
            "gate": "E30",
            "flightNumber": "FF111",
            "scheduledDepartureDate": scheduled_date
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if flight_response.status_code != 200:
        pytest.skip("Could not create test flight")
    
    flight_identifier = flight_response.json()["flight_identifier"]
    
    passenger_response = await client.post(
        f"/v1/airline/{airline_identifier}/passenger/create",
        json={
            "formattedName": "Charlie Wilson",
            "firstName": "Charlie",
            "lastName": "Wilson",
            "apple_identifier": "charlie.apple.id.123"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if passenger_response.status_code != 200:
        pytest.skip("Could not create test passenger")
    
    passenger_identifier = passenger_response.json()["passenger_identifier"]
    
    # Issue ticket
    create_response = await client.post(
        f"/v1/airline/{airline_identifier}/ticket/issue/{flight_identifier}/{passenger_identifier}",
        json={
            "seatNumber": "25D",
            "customLabelValue": "1"
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    if create_response.status_code != 200:
        pytest.skip("Could not create test ticket")
    
    ticket_identifier = create_response.json()["ticket_identifier"]
    
    # Get signature digest for the ticket
    from app.services.signature_service import SignatureService
    signature_service = SignatureService(apple_identifier)
    signature_digest = signature_service.signature_digest(ticket_identifier)
    
    # Verify ticket
    response = await client.post(
        f"/v1/airline/{airline_identifier}/ticket/verify",
        json={
            "ticket": ticket_identifier,
            "signatureDigest": signature_digest
        },
        headers={"Authorization": f"Bearer {apple_identifier}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["ticket_identifier"] == ticket_identifier
    assert data["seatNumber"] == "25D"
    print(f"✅ Verified ticket: {ticket_identifier}")


@pytest.mark.asyncio
async def test_ticket_authentication_failure(client: AsyncClient):
    """Test that invalid bearer token returns 401."""
    from app.config import settings
    
    if not settings.SECRET:
        pytest.skip("SECRET not configured in .env")
    
    # Create airline
    airline_response = await client.post(
        "/v1/airline/create",
        json={
            "apple_identifier": "test.auth.ticket.123",
            "airline_name": "Auth Ticket Test Airline"
        },
        headers={"Authorization": f"Bearer {settings.SECRET}"}
    )
    
    if airline_response.status_code != 200:
        pytest.skip("Could not create test airline")
    
    airline_identifier = airline_response.json()["airline_identifier"]
    
    # Try to access with invalid token
    response = await client.get(
        f"/v1/airline/{airline_identifier}/ticket/list",
        headers={"Authorization": "Bearer wrong_token"}
    )
    
    assert response.status_code == 401
    data = response.json()
    assert "Invalid Bearer Token" in data["detail"]
    print("✅ Authentication failure handled correctly")

