"""
Database connection and session management.

Uses SQLAlchemy Core with async aiomysql driver.
"""
import os
from sqlalchemy.ext.asyncio import (
    create_async_engine,
    AsyncSession,
    async_sessionmaker,
)
from sqlalchemy.pool import NullPool

from app.config import settings


# Use NullPool for testing to avoid event loop issues
# NullPool creates a new connection for each request (no pooling)
_is_testing = os.environ.get("PYTEST_CURRENT_TEST") is not None

if _is_testing:
    # Testing: disable pooling to avoid event loop conflicts
    engine = create_async_engine(
        settings.get_database_url(),
        poolclass=NullPool,
        echo=settings.DEBUG,
    )
else:
    # Production: use connection pooling
    engine = create_async_engine(
        settings.get_database_url(),
        pool_pre_ping=True,  # Verify connections before using
        pool_size=10,  # Connection pool size
        max_overflow=20,
        echo=settings.DEBUG,  # Log SQL queries in debug mode
    )

# Session factory
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


async def get_db() -> AsyncSession:
    """
    FastAPI dependency for database sessions.

    Usage:
        @router.get("/endpoint")
        async def endpoint(db: AsyncSession = Depends(get_db)):
            ...
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()

