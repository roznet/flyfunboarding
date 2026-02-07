"""
Test status endpoints using httpx.

These tests match the PHP StatusController:
- GET /v1/status
"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_status(client: AsyncClient):
    """Test getting database status."""
    response = await client.get("/api/v1/status")
    
    # Should return 200 if database is accessible
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert "message" in data
    assert data["status"] is True
    assert data["message"] == "OK"
    print("✅ Status check passed")


@pytest.mark.asyncio
async def test_status_returns_correct_format(client: AsyncClient):
    """Test that status returns the correct JSON format."""
    response = await client.get("/api/v1/status")
    
    assert response.status_code == 200
    data = response.json()
    # Verify structure matches PHP output
    assert isinstance(data["status"], bool)
    assert isinstance(data["message"], str)
    assert data["status"] is True
    print("✅ Status format is correct")

