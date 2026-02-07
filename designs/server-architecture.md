# Server Architecture

FastAPI server for issuing boarding passes with Apple Wallet PKPass generation. Migrated from PHP, preserving the same MySQL schema and JSON serialization behavior.

## Stack

- **Framework**: FastAPI (async)
- **Database**: MySQL via SQLAlchemy Core + aiomysql (async)
- **Models**: Pydantic v2 with PHP-compatible JSON serialization
- **PKPass**: `passes-rs-py` (Rust-based Apple Wallet pass generator)
- **Crypto**: RSA key pairs per airline for ticket signatures
- **Templates**: Jinja2 for passenger-facing HTML pages

## Layers

```
config.py → Settings (env vars, paths, API version)
    ↓
database/connection.py → async engine, get_db() dependency
database/tables.py → SQLAlchemy Core table definitions
database/repository.py → BaseRepository<T> with airline scoping
    ↓
models/*.py → Pydantic models (BaseJsonModel with PHP-compat serialization)
schemas/*.py → Request/response validation schemas
    ↓
dependencies.py → Auth (CurrentAirline, SystemAuth, DbSession)
    ↓
routers/*.py → API endpoints
services/*.py → Business logic (BoardingPassService, SignatureService, AirportService)
core/*.py → Exceptions, localization
```

## Config (`app/config.py`)

`Settings` extends `pydantic_settings.BaseSettings`, loaded from `.env`:

| Setting | Default | Purpose |
|---------|---------|---------|
| `DB_HOST/PORT/USER/PASSWORD/NAME` | localhost:3306/flyfunboarding | MySQL connection |
| `CERTIFICATE_PATH` | certs/certificate.pem | Apple Wallet signing cert |
| `CERTIFICATE_PASSWORD` | "" | P12 password (if using P12) |
| `KEYS_PATH` | keys/ | RSA key pair storage |
| `IMAGES_PATH` | images/ | PKPass icon/logo images |
| `SECRET` | "" | Shared secret for ticket hashing |
| `USE_PUBLIC_KEY_SIGNATURE` | True | Enable RSA ticket signatures |
| `API_VERSION` | v1 | Builds `api_prefix` → `/api/v1` |

## Database

### Tables (`database/tables.py`)

All entity tables follow the same pattern: numeric `_id` (PK), string `_identifier` (UUID, unique), `airline_id` (FK), `json_data` (JSON column), `modified` (timestamp).

- **Airlines** — root entity. `airline_identifier` = SHA1 of `apple_identifier`.
- **Settings** — one-to-one with Airlines. Colors, custom label config.
- **Aircrafts** — registration, type. FK to Airlines.
- **Passengers** — names, apple_identifier. FK to Airlines.
- **Flights** — origin/destination/gate/aircraft/departure. FK to Airlines + Aircrafts.
- **Tickets** — passenger + flight + seat. FK to Airlines + Passengers + Flights.

### Repository Pattern (`database/repository.py`)

`BaseRepository<T>` provides airline-scoped CRUD:
- `get_by_identifier(identifier, airline_id, db)` — most lookups
- `direct_get_by_identifier(identifier, db)` — public endpoints (no airline scoping)
- `list_with_stats(airline_id, db, join_tables)` — list with COUNT/MAX from related tables
- `create_or_update(data, airline_id, db)` — MySQL `INSERT ... ON DUPLICATE KEY UPDATE`

Concrete: `AircraftRepository`, `PassengerRepository`, `FlightRepository`, `TicketRepository`.

## Models (`app/models/`)

### BaseJsonModel (`models/base.py`)

All models extend `BaseJsonModel` which provides PHP-compatible serialization:
- `to_json()` — excludes fields matching defaults (matches PHP `JsonHelper::toJson()`)
- `unique_identifier()` — override to add extra fields (e.g., IDs)
- DateTime → ISO 8601 with timezone (`+00:00` appended to naive datetimes)
- timedelta → ISO 8601 duration (`PT2H30M0S`)
- Fields use camelCase aliases to match PHP JSON keys

### Key Models

- **Airline** — `airline_name`, `apple_identifier`
- **Aircraft** — `registration`, `type`
- **Passenger** — `formatted_name`, `first_name`, `middle_name`, `last_name`, `apple_identifier`
- **Flight** — `origin` (Airport), `destination` (Airport), `gate`, `flight_number`, `aircraft` (Aircraft), `scheduled_departure_date`
- **Ticket** — `passenger` (Passenger), `flight` (Flight), `seat_number`, `custom_label_value`
- **Airport** — `icao`, with methods: `get_info()`, `get_location()`, `get_map_url()`, `fit_name(maxlen)`
- **Settings** — `background_color`, `foreground_color`, `label_color`, `custom_label`, `custom_label_enabled`

## Auth System (`app/dependencies.py`)

Authentication is per-route via FastAPI dependency injection (not middleware).

### CurrentAirline
Extracts `airline_identifier` from URL path + Bearer token from header. Validates token matches the airline's `apple_identifier` in the database. Returns `AirlineContext(airline_id, airline_identifier, airline_data)`.

### SystemAuth
Validates Bearer token matches `settings.SECRET`. Used for admin/system endpoints.

### No Auth
`airline/create` and public `boardingpass/` endpoints require no authentication. The `apple_identifier` from Apple Sign In is the credential for registration.

## Routers (`app/routers/`)

### Route Registration (`main.py`)

All API routes use `settings.api_prefix` (default `/api/v1`):

```
/api/v1/airline — airline management (create = no auth)
/api/v1/airline/{id}/aircraft — aircraft CRUD (airline auth)
/api/v1/airline/{id}/passenger — passenger CRUD (airline auth)
/api/v1/airline/{id}/flight — flight planning (airline auth)
/api/v1/airline/{id}/ticket — ticket issuance (airline auth)
/api/v1/airline/{id}/settings — airline settings (airline auth)
/api/v1/airline/{id}/boardingpass — PKPass download (airline auth)
/api/v1/boardingpass — PKPass download (public, no auth)
/api/v1/airport — airport info lookup (public)
/api/v1/status — health check
/pages — HTML pages (public)
/static — static files
/health — infra health check
```

### Key Endpoints

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | `airline/create` | None | Register airline (Apple Sign In) |
| POST | `aircraft/create` | Airline | Create/update aircraft |
| POST | `passenger/create` | Airline | Create/update passenger |
| POST | `flight/plan/{aircraft_id}` | Airline | Plan a flight |
| POST | `ticket/issue/{flight_id}/{passenger_id}` | Airline | Issue ticket |
| POST | `ticket/verify` | Airline | Verify ticket signature |
| GET | `boardingpass/{ticket_id}` | Public | Download PKPass file |
| GET | `/pages/yourBoardingPass/{ticket_id}` | Public | Boarding pass HTML page |

## Services (`app/services/`)

### BoardingPassService
Builds Apple Wallet PKPass files. Assembles pass.json with header/primary/secondary/auxiliary/back fields, QR barcode with cryptographic signature, location triggers at origin/destination airports. Uses `passes-rs-py` to generate the `.pkpass` zip.

### SignatureService
RSA key management per airline. Creates/loads key pairs from `KEYS_PATH/{base_name}.pem/.pub`. Produces signature digests combining SHA256 hash (using SECRET) and optional RSA signature for ticket verification.

### AirportService
Singleton wrapping `euro_aip.sources.DatabaseSource` for airport lookups by ICAO code. Returns name, location, timezone, country, links.

## Core (`app/core/`)

### Exceptions
`NotFoundError`, `AuthenticationError`, `AuthorizationError` with consistent JSON responses. Registered via `register_exception_handlers(app)`.

### Localization
Language detection: query param → Accept-Language → IP geolocation (ipwho.is) → default `en`. Supports en/fr/de/es. Used by boarding pass HTML page for field labels and disclaimers.

## Key Design Decisions

1. **JSON columns** — Entity data lives in `json_data`, IDs in separate columns. Matches PHP schema.
2. **Exclude defaults** — `to_json()` omits fields matching defaults, matching PHP `JsonHelper`.
3. **camelCase aliases** — Python uses `snake_case`, JSON uses `camelCase` via Pydantic aliases.
4. **Naive datetime handling** — MySQL stores naive datetimes; code appends `+00:00` for ISO 8601 compliance (iOS requires timezone in ISO 8601).
5. **Embedded objects** — Tickets embed full passenger + flight objects in `json_data` (denormalized for fast reads).
6. **P12 extraction** — If cert is `.p12`, extracts PEM cert and key at runtime using `cryptography` library.
