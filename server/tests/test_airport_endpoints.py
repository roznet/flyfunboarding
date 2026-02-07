"""
Test airport endpoints using httpx.

These tests match the PHP AirportController:
- GET /v1/airport?icao=XXXX
- GET /v1/airport/info/{icao}
"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_airport_by_query_param(client: AsyncClient):
    """Test getting airport by ICAO query parameter."""
    from app.services.airport_service import AirportService
    
    # Skip if airport service is not available
    if AirportService._get_source() is None:
        pytest.skip("Airport service not available (euro_aip library not installed or database not found)")
    
    # Test with a well-known airport (London Heathrow)
    response = await client.get("/api/v1/airport", params={"icao": "EGLL"})
    
    assert response.status_code == 200
    data = response.json()
    assert data["ident"] == "EGLL"
    assert "name" in data
    assert "municipality" in data
    assert "iso_country" in data
    assert "latitude_deg" in data
    assert "longitude_deg" in data
    print(f"✅ Retrieved airport: {data['name']}")


@pytest.mark.asyncio
async def test_get_airport_by_path(client: AsyncClient):
    """Test getting airport by ICAO path parameter."""
    from app.services.airport_service import AirportService
    
    # Skip if airport service is not available
    if AirportService._get_source() is None:
        pytest.skip("Airport service not available (euro_aip library not installed or database not found)")
    
    # Test with another well-known airport (JFK)
    response = await client.get("/api/v1/airport/info/KJFK")
    
    assert response.status_code == 200
    data = response.json()
    assert data["ident"] == "KJFK"
    assert "name" in data
    assert "municipality" in data
    print(f"✅ Retrieved airport: {data['name']}")


@pytest.mark.asyncio
async def test_get_airport_not_found_query(client: AsyncClient):
    """Test getting non-existent airport via query param."""
    response = await client.get("/api/v1/airport", params={"icao": "XXXX"})
    
    assert response.status_code == 400
    data = response.json()
    assert "not found" in data["detail"].lower()
    print("✅ Not found error handled correctly (query param)")


@pytest.mark.asyncio
async def test_get_airport_not_found_path(client: AsyncClient):
    """Test getting non-existent airport via path."""
    response = await client.get("/api/v1/airport/info/XXXX")
    
    assert response.status_code == 400
    data = response.json()
    assert "not found" in data["detail"].lower()
    print("✅ Not found error handled correctly (path)")


@pytest.mark.asyncio
async def test_get_airport_missing_icao(client: AsyncClient):
    """Test getting airport without ICAO parameter."""
    response = await client.get("/api/v1/airport")
    
    assert response.status_code == 400
    data = response.json()
    assert "not found" in data["detail"].lower()
    print("✅ Missing ICAO parameter handled correctly")


@pytest.mark.asyncio
async def test_get_airport_case_insensitive(client: AsyncClient):
    """Test that ICAO codes are case-insensitive."""
    from app.services.airport_service import AirportService
    
    # Skip if airport service is not available
    if AirportService._get_source() is None:
        pytest.skip("Airport service not available (euro_aip library not installed or database not found)")
    
    # Test with lowercase
    response_lower = await client.get("/api/v1/airport/info/egll")
    assert response_lower.status_code == 200
    data_lower = response_lower.json()
    
    # Test with uppercase
    response_upper = await client.get("/api/v1/airport/info/EGLL")
    assert response_upper.status_code == 200
    data_upper = response_upper.json()
    
    # Should return same airport
    assert data_lower["ident"] == data_upper["ident"]
    print("✅ Case-insensitive ICAO handling works")

