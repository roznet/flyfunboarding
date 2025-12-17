"""
Generic repository pattern implementing PHP MyFlyFunDb patterns.

Provides CRUD operations with airline scoping.
"""
from typing import TypeVar, Generic, Any
from sqlalchemy import Table, select, insert, delete, func as sql_func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.dialects.mysql import insert as mysql_insert

T = TypeVar("T")


class BaseRepository(Generic[T]):
    """
    Generic repository implementing PHP MyFlyFunDb patterns.

    Provides CRUD operations with airline scoping.
    """

    def __init__(self, table: Table, model_class: type[T]):
        self.table = table
        self.model_class = model_class
        self._table_name = table.name
        # Derive column names from table name (e.g., "Aircrafts" -> "aircraft_id", "aircraft_identifier")
        table_singular = table.name[:-1].lower()  # Remove 's' and lowercase
        self._id_column = f"{table_singular}_id"
        self._identifier_column = f"{table_singular}_identifier"

    async def get_by_identifier(
        self, identifier: str, airline_id: int, db: AsyncSession
    ) -> T | None:
        """Get entity by identifier (scoped to airline)."""
        # Explicitly select only the columns that exist in the table
        query = select(
            self.table.c[self._id_column],
            self.table.c[self._identifier_column],
            self.table.c.json_data,
            self.table.c.airline_id,
            self.table.c.modified,
        ).where(
            self.table.c[self._identifier_column] == identifier,
            self.table.c.airline_id == airline_id,
        )
        result = await db.execute(query)
        row = result.fetchone()
        return self._row_to_model(row) if row else None

    async def direct_get_by_identifier(
        self, identifier: str, db: AsyncSession
    ) -> T | None:
        """
        Get entity by identifier WITHOUT airline scoping.

        Used for public endpoints (e.g., boarding pass display).
        Matches PHP directGet() pattern.
        """
        # Explicitly select only the columns that exist in the table
        query = select(
            self.table.c[self._id_column],
            self.table.c[self._identifier_column],
            self.table.c.json_data,
            self.table.c.airline_id,
            self.table.c.modified,
        ).where(
            self.table.c[self._identifier_column] == identifier
        )
        result = await db.execute(query)
        row = result.fetchone()
        return self._row_to_model(row) if row else None

    async def list_all(
        self, airline_id: int, db: AsyncSession
    ) -> list[T]:
        """List all entities for airline."""
        # Explicitly select only the columns that exist in the table
        query = select(
            self.table.c[self._id_column],
            self.table.c[self._identifier_column],
            self.table.c.json_data,
            self.table.c.airline_id,
            self.table.c.modified,
        ).where(
            self.table.c.airline_id == airline_id
        )
        result = await db.execute(query)
        return [self._row_to_model(row) for row in result.fetchall()]

    async def list_with_stats(
        self, airline_id: int, db: AsyncSession, join_tables: list[Table]
    ) -> list[dict[str, Any]]:
        """
        List entities with COUNT and MAX(modified) stats from related tables.

        Matches PHP listStats() pattern.
        """
        table_ref = self.table
        # Explicitly select only the columns that exist in the table
        select_cols = [
            table_ref.c[self._id_column],
            table_ref.c[self._identifier_column],
            table_ref.c.json_data,
            table_ref.c.airline_id,
            table_ref.c.modified,
        ]

        joins = []
        for join_table in join_tables:
            # Derive join column name (e.g., "Aircrafts" -> "aircraft_id")
            join_table_singular = join_table.name[:-1].lower()
            join_id = f"{join_table_singular}_id"
            count_alias = f"{join_table.name.lower()}_count"
            last_alias = f"{join_table.name.lower()}_last"

            select_cols.extend([
                sql_func.count(join_table.c[join_id]).label(count_alias),
                sql_func.max(join_table.c.modified).label(last_alias),
            ])
            joins.append(
                (join_table, table_ref.c[self._id_column] == join_table.c[join_id])
            )

        query = select(*select_cols).select_from(table_ref)
        for join_table, condition in joins:
            query = query.outerjoin(join_table, condition)

        query = query.where(table_ref.c.airline_id == airline_id)
        query = query.group_by(table_ref.c[self._id_column])

        result = await db.execute(query)
        return [dict(row._mapping) for row in result.fetchall()]

    async def create_or_update(
        self, data: dict[str, Any], airline_id: int, db: AsyncSession
    ) -> T | None:
        """
        Create or update entity (upsert).

        Matches PHP createOrUpdate() pattern.
        """
        insert_data = {
            "json_data": data,
            "airline_id": airline_id,
        }

        # Add identifier if provided
        if self._identifier_column in data:
            insert_data[self._identifier_column] = data[self._identifier_column]

        # MySQL INSERT ... ON DUPLICATE KEY UPDATE
        stmt = mysql_insert(self.table).values(**insert_data)
        stmt = stmt.on_duplicate_key_update(json_data=data)

        await db.execute(stmt)
        await db.commit()

        # Retrieve the created/updated entity
        identifier = data.get(self._identifier_column)
        if identifier:
            return await self.get_by_identifier(identifier, airline_id, db)
        return None

    async def delete_by_identifier(
        self, identifier: str, airline_id: int, db: AsyncSession
    ) -> bool:
        """Delete entity by identifier."""
        stmt = delete(self.table).where(
            self.table.c[self._identifier_column] == identifier,
            self.table.c.airline_id == airline_id,
        )
        result = await db.execute(stmt)
        await db.commit()
        return result.rowcount > 0

    def _row_to_model(self, row) -> T | None:
        """Convert database row to model instance."""
        if row is None:
            return None
        row_dict = dict(row._mapping)
        json_data = row_dict.get("json_data", {})
        # Merge identifiers into json_data
        json_data[self._id_column] = row_dict.get(self._id_column)
        json_data[self._identifier_column] = row_dict.get(self._identifier_column)
        return self.model_class.model_validate(json_data)


# Concrete repositories
class AircraftRepository(BaseRepository):
    """Repository for Aircraft entities."""
    pass


class PassengerRepository(BaseRepository):
    """Repository for Passenger entities."""
    pass


class FlightRepository(BaseRepository):
    """Repository for Flight entities."""
    pass


class TicketRepository(BaseRepository):
    """Repository for Ticket entities."""
    pass

