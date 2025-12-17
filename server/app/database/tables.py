"""
SQLAlchemy Core table definitions.

Matches the existing MySQL schema exactly - no schema changes.
"""
from sqlalchemy import (
    Table,
    Column,
    Integer,
    String,
    JSON,
    ForeignKey,
    TIMESTAMP,
    MetaData,
)
from sqlalchemy.sql import func

metadata = MetaData()

# Table configuration matching PHP $standardTables
TABLE_CONFIG = {
    "Aircrafts": {"links": []},
    "Passengers": {"links": []},
    "Flights": {"links": ["Aircrafts"]},
    "Tickets": {"links": ["Passengers", "Flights"]},
}

# Airlines table (no airline_id foreign key - it's the root entity)
airlines = Table(
    "Airlines",
    metadata,
    Column("airline_id", Integer, primary_key=True, autoincrement=True),
    Column("airline_identifier", String(255), unique=True, nullable=False),
    Column("json_data", JSON),
    Column("modified", TIMESTAMP, server_default=func.now(), onupdate=func.now()),
)

# Settings table (one-to-one with Airlines)
settings = Table(
    "Settings",
    metadata,
    Column(
        "airline_id",
        Integer,
        ForeignKey("Airlines.airline_id", ondelete="CASCADE"),
        primary_key=True,
    ),
    Column("json_data", JSON),
)

# Aircrafts table
aircrafts = Table(
    "Aircrafts",
    metadata,
    Column("aircraft_id", Integer, primary_key=True, autoincrement=True),
    Column("aircraft_identifier", String(36), unique=True, nullable=False),
    Column("json_data", JSON),
    Column(
        "airline_id",
        Integer,
        ForeignKey("Airlines.airline_id", ondelete="CASCADE"),
        nullable=False,
    ),
    Column("modified", TIMESTAMP, server_default=func.now(), onupdate=func.now()),
)

# Passengers table
passengers = Table(
    "Passengers",
    metadata,
    Column("passenger_id", Integer, primary_key=True, autoincrement=True),
    Column("passenger_identifier", String(36), unique=True, nullable=False),
    Column("json_data", JSON),
    Column(
        "airline_id",
        Integer,
        ForeignKey("Airlines.airline_id", ondelete="CASCADE"),
        nullable=False,
    ),
    Column("modified", TIMESTAMP, server_default=func.now(), onupdate=func.now()),
)

# Flights table
flights = Table(
    "Flights",
    metadata,
    Column("flight_id", Integer, primary_key=True, autoincrement=True),
    Column("flight_identifier", String(36), unique=True, nullable=False),
    Column(
        "aircraft_id",
        Integer,
        ForeignKey("Aircrafts.aircraft_id", ondelete="CASCADE"),
        nullable=False,
    ),
    Column("json_data", JSON),
    Column(
        "airline_id",
        Integer,
        ForeignKey("Airlines.airline_id", ondelete="CASCADE"),
        nullable=False,
    ),
    Column("modified", TIMESTAMP, server_default=func.now(), onupdate=func.now()),
)

# Tickets table
tickets = Table(
    "Tickets",
    metadata,
    Column("ticket_id", Integer, primary_key=True, autoincrement=True),
    Column("ticket_identifier", String(36), unique=True, nullable=False),
    Column(
        "passenger_id",
        Integer,
        ForeignKey("Passengers.passenger_id", ondelete="CASCADE"),
        nullable=False,
    ),
    Column(
        "flight_id",
        Integer,
        ForeignKey("Flights.flight_id", ondelete="CASCADE"),
        nullable=False,
    ),
    Column("json_data", JSON),
    Column(
        "airline_id",
        Integer,
        ForeignKey("Airlines.airline_id", ondelete="CASCADE"),
        nullable=False,
    ),
    Column("modified", TIMESTAMP, server_default=func.now(), onupdate=func.now()),
)

# BoardingPasses table (if it exists in schema)
boarding_passes = Table(
    "BoardingPasses",
    metadata,
    Column("boarding_pass_id", Integer, primary_key=True, autoincrement=True),
    Column(
        "ticket_id",
        Integer,
        ForeignKey("Tickets.ticket_id", ondelete="CASCADE"),
        nullable=False,
    ),
    Column("json_data", JSON),
    Column("modified", TIMESTAMP, server_default=func.now(), onupdate=func.now()),
)

