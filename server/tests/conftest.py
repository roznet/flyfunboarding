"""
Pytest configuration and fixtures for async tests.

This file ensures proper event loop and database connection management.
"""
import pytest
from typing import AsyncGenerator

from httpx import AsyncClient, ASGITransport

from app.main import app


@pytest.fixture(scope="session")
async def client() -> AsyncGenerator[AsyncClient, None]:
    """
    Create an async HTTP client for testing.

    Session-scoped to share the same client (and event loop) across all tests.
    This prevents the "attached to a different loop" errors.
    """
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test"
    ) as ac:
        yield ac
