# Fly Fun Boarding API - Python/FastAPI Backend

This is the Python/FastAPI implementation of the Fly Fun Boarding server, migrating from PHP.

## Quick Start

### Prerequisites

- Python 3.13+
- MySQL 8.0 database
- Access to certificates, keys, and airport database

### Setup

1. **Create virtual environment**:
   ```bash
   cd server
   python3.13 -m venv venv
   source venv/bin/activate  # On macOS/Linux
   # or
   venv\Scripts\activate  # On Windows
   ```

2. **Install dependencies**:
   ```bash
   pip install -e ".[dev]"
   ```

3. **Configure environment**:
   ```bash
   cp .env.sample .env
   # Edit .env with your database credentials and paths
   ```

4. **Install euro_aip library** (local dependency):
   ```bash
   pip install -e ~/Developer/public/rzflight/euro_aip/
   ```

5. **Run the application**:
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

6. **Access the API**:
   - API: http://localhost:8000
   - Health check: http://localhost:8000/health
   - OpenAPI docs: http://localhost:8000/docs

## Project Structure

```
server/
├── app/                    # Application package
│   ├── main.py            # FastAPI app entry point
│   ├── config.py          # Configuration (pydantic-settings)
│   ├── dependencies.py    # FastAPI dependencies (auth, db)
│   ├── database/          # Database layer
│   │   ├── connection.py # Engine and session management
│   │   ├── tables.py      # SQLAlchemy Core table definitions
│   │   └── repository.py  # Generic repository pattern
│   ├── models/            # Domain models (Pydantic)
│   ├── schemas/           # API request/response schemas
│   ├── routers/           # API route handlers
│   ├── services/          # Business logic services
│   └── core/              # Core utilities
├── templates/             # Jinja2 HTML templates
├── static/                # Static files (images, CSS, JS)
├── tests/                 # Test suite
└── pyproject.toml        # Dependencies and project config
```

## Development

### Running Tests

```bash
pytest
```

### Code Quality

```bash
# Linting
ruff check .

# Type checking
mypy app/
```

### Environment Variables

See `.env.sample` for all available configuration options.

Key variables:
- `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` - Database connection
- `SECRET` - System authentication secret
- `CERTIFICATE_PATH`, `CERTIFICATE_PASSWORD`, `WWDR_PATH` - Apple Wallet certificates
- `KEYS_PATH` - Directory for RSA keys
- `AIRPORT_DB_PATH` - Path to airports.db (used by euro_aip)

## Architecture

- **Database**: SQLAlchemy Core (NOT ORM) - type-safe query building
- **Authentication**: FastAPI dependency injection
- **PKPass**: `passes-rs-py` library
- **Airport Data**: `euro_aip` library (never read airports.db directly)

See `designs/MIGRATION_DESIGN.md` for complete architecture documentation.

## Migration Status

See `designs/IMPLEMENTATION_PLAN.md` for detailed implementation progress.
