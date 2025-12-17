"""
Quick test to verify database connection and basic setup.
"""
import asyncio
import sys
from pathlib import Path

# Add server directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.config import settings
from app.database.connection import engine
from sqlalchemy import text


async def test_database_connection():
    """Test that we can connect to the database."""
    print("🔌 Testing database connection...")
    print(f"   Database: {settings.DB_NAME}@{settings.DB_HOST}:{settings.DB_PORT}")
    print(f"   User: {settings.DB_USER}")
    
    try:
        async with engine.begin() as conn:
            result = await conn.execute(text("SELECT 1 as test"))
            row = result.fetchone()
            if row and row[0] == 1:
                print("   ✅ Database connection successful!")
                return True
            else:
                print("   ❌ Connection failed: Unexpected result")
                return False
    except Exception as e:
        print(f"   ❌ Database connection failed: {e}")
        return False


async def test_table_access():
    """Test that we can query the Airlines table."""
    print("\n📊 Testing table access...")
    try:
        from sqlalchemy import select, text
        from app.database.tables import airlines
        
        async with engine.begin() as conn:
            # Test 1: Check if table exists
            result = await conn.execute(
                text("SHOW TABLES LIKE 'Airlines'")
            )
            table_exists = result.fetchone() is not None
            
            if not table_exists:
                print("   ⚠️  Airlines table not found (database might be empty)")
                return False
            
            # Test 2: Try to query the table
            query = select(airlines).limit(1)
            result = await conn.execute(query)
            count = len(list(result.fetchall()))
            
            print(f"   ✅ Airlines table accessible (found {count} row(s))")
            return True
    except Exception as e:
        print(f"   ❌ Table access failed: {e}")
        return False


async def main():
    """Run all connection tests."""
    print("=" * 50)
    print("Database Connection Tests")
    print("=" * 50)
    
    try:
        conn_ok = await test_database_connection()
        table_ok = await test_table_access()
        
        print("\n" + "=" * 50)
        if conn_ok and table_ok:
            print("✅ All tests passed! Ready to test API endpoints.")
            return 0
        else:
            print("❌ Some tests failed. Check your .env configuration.")
            return 1
    finally:
        # Properly close the engine to avoid event loop warnings
        await engine.dispose()


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)

