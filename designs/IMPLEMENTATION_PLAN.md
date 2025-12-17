# Implementation Plan: PHP to Python/FastAPI Migration

**Status**: Ready for Implementation  
**Date**: 2024-12-XX  
**Based on**: `MIGRATION_DESIGN.md`

## Executive Summary

This document provides a formal, step-by-step implementation plan for migrating the Fly Fun Boarding server from PHP to Python/FastAPI. The plan is organized into phases with clear deliverables, dependencies, and acceptance criteria.

## Prerequisites

Before starting implementation, ensure:
- ✅ Python 3.13 installed
- ✅ MySQL 8.0 database accessible
- ✅ Access to existing PHP codebase for reference
- ✅ `euro_aip` library available at `~/Developer/public/rzflight/euro_aip/`
- ✅ Apple Wallet certificates and keys available
- ✅ Test database or ability to create one

## Phase 1: Foundation & Infrastructure

**Goal**: Set up project structure, configuration, and database connectivity.

### 1.1 Project Structure Setup
**Deliverable**: Complete `server/` directory structure matching design

**Tasks**:
- [ ] Create `server/` directory structure (as per Section 1 of MIGRATION_DESIGN.md)
- [ ] Create `pyproject.toml` with all dependencies
- [ ] Create `.env.sample` template
- [ ] Create `.gitignore` (ensure `.env` is ignored)
- [ ] Create `README.md` with setup instructions

**Acceptance Criteria**:
- All directories exist: `app/`, `app/database/`, `app/models/`, `app/schemas/`, `app/routers/`, `app/services/`, `app/core/`, `templates/`, `static/`, `tests/`
- `pyproject.toml` includes all dependencies from Appendix A
- `.env.sample` includes all configuration variables from Appendix B

### 1.2 Configuration System
**Deliverable**: Working configuration loader using `pydantic-settings`

**Tasks**:
- [ ] Create `app/config.py` with `Settings` class
- [ ] Implement all configuration fields (DB, PKPass, paths, security, logging)
- [ ] Test loading from `.env` file
- [ ] Test environment variable overrides

**Acceptance Criteria**:
- `from app.config import settings` works
- All paths resolve correctly (relative to BASE_DIR)
- Type validation works (e.g., `DB_PORT` must be int)
- `.env` file loading works

### 1.3 Database Connection
**Deliverable**: Async database connection with SQLAlchemy Core

**Tasks**:
- [ ] Create `app/database/connection.py`
- [ ] Implement async engine with `aiomysql`
- [ ] Implement `get_db()` dependency
- [ ] Test connection to MySQL database
- [ ] Implement connection pooling configuration

**Acceptance Criteria**:
- Can connect to MySQL database
- Connection pool works (test with multiple concurrent requests)
- `get_db()` dependency works in FastAPI route
- Health check endpoint can verify database connectivity

### 1.4 Database Table Definitions
**Deliverable**: SQLAlchemy Core table definitions matching existing MySQL schema

**Tasks**:
- [ ] Create `app/database/tables.py`
- [ ] Define all tables: `Airlines`, `Settings`, `Aircrafts`, `Passengers`, `Flights`, `Tickets`
- [ ] Match exact column names, types, and constraints from PHP schema
- [ ] Include foreign keys with CASCADE deletes
- [ ] Include `modified` timestamps with auto-update
- [ ] Verify table definitions match existing database schema

**Acceptance Criteria**:
- All table definitions exist
- Column names match PHP schema exactly
- Foreign key relationships match
- Can query existing database tables using these definitions

**Files to Create**:
- `server/app/database/connection.py`
- `server/app/database/tables.py`

## Phase 2: Core Services & Patterns

**Goal**: Implement reusable patterns and core business logic.

### 2.1 Base JSON Model
**Deliverable**: PHP-compatible JSON serialization base class

**Tasks**:
- [ ] Create `app/models/base.py`
- [ ] Implement `BaseJsonModel` with `exclude_defaults=True`
- [ ] Implement `timedelta_to_iso8601()` function
- [ ] Implement `to_json()` method matching PHP behavior
- [ ] Implement `unique_identifier()` hook pattern
- [ ] Test with sample model (verify defaults are excluded)

**Acceptance Criteria**:
- DateTime serializes as ISO 8601 ('c' format)
- DateInterval/timedelta serializes as ISO 8601 duration (PT2H30M0S)
- Fields with default values are excluded from JSON
- `unique_identifier()` pattern works

**Files to Create**:
- `server/app/models/base.py`

### 2.2 Generic Repository Pattern
**Deliverable**: Reusable repository implementing PHP `MyFlyFunDb` patterns

**Tasks**:
- [ ] Create `app/database/repository.py`
- [ ] Implement `BaseRepository` generic class
- [ ] Implement `get_by_identifier()` (airline-scoped)
- [ ] Implement `direct_get_by_identifier()` (no airline scope)
- [ ] Implement `list_all()` (airline-scoped)
- [ ] Implement `list_with_stats()` (with JOINs for counts)
- [ ] Implement `create_or_update()` (upsert pattern)
- [ ] Implement `delete_by_identifier()`
- [ ] Create concrete repositories: `AircraftRepository`, `PassengerRepository`, `FlightRepository`, `TicketRepository`, `AirlineRepository`
- [ ] Test with sample data

**Acceptance Criteria**:
- All CRUD operations work
- Airline scoping works correctly
- `list_with_stats()` produces correct JOIN queries
- `create_or_update()` handles upserts correctly
- `direct_get_by_identifier()` bypasses airline scope

**Files to Create**:
- `server/app/database/repository.py`

### 2.3 Authentication Dependencies
**Deliverable**: FastAPI dependency injection for airline authentication

**Tasks**:
- [ ] Create `app/dependencies.py`
- [ ] Implement `AirlineContext` class
- [ ] Implement `get_airline_context()` dependency
- [ ] Implement `get_system_auth()` dependency
- [ ] Create type aliases: `CurrentAirline`, `SystemAuth`, `DbSession`
- [ ] Test authentication flow (valid/invalid tokens)

**Acceptance Criteria**:
- `CurrentAirline` dependency extracts airline from path
- Bearer token validation works
- Returns 401 for invalid tokens
- Returns 404 for non-existent airlines
- `SystemAuth` validates SECRET correctly

**Files to Create**:
- `server/app/dependencies.py`

### 2.4 Signature Service
**Deliverable**: Cryptographic operations matching PHP `Signature.php`

**Tasks**:
- [ ] Create `app/services/signature_service.py`
- [ ] Implement RSA key loading from `keys/` directory
- [ ] Implement `signature_digest()` method
- [ ] Implement `verify_signature_digest()` method
- [ ] Support `USE_PUBLIC_KEY_SIGNATURE` flag
- [ ] Test with existing PHP-generated signatures (verify compatibility)

**Acceptance Criteria**:
- Can sign data and verify signatures
- Key file format compatible with PHP
- Signature format matches PHP output
- Works with both secret-based and RSA signatures

**Files to Create**:
- `server/app/services/signature_service.py`

### 2.5 PKPass Service
**Deliverable**: Apple Wallet PKPass generation using `passes-rs-py`

**Tasks**:
- [ ] Install `passes-rs-py` library
- [ ] Create `app/services/pkpass_service.py`
- [ ] Implement pass.json structure generation
- [ ] Implement image handling (logo, icon, etc.)
- [ ] Implement localization (en, fr, de, es)
- [ ] Implement signing with Apple certificate
- [ ] Implement ZIP packaging
- [ ] Test generated `.pkpass` files open in Apple Wallet

**Acceptance Criteria**:
- Generates valid `.pkpass` files
- Files open successfully in Apple Wallet
- Localization works for all languages
- Images are included correctly
- Signatures are valid

**Files to Create**:
- `server/app/services/pkpass_service.py`

### 2.6 Airport Service
**Deliverable**: Airport data access via `euro_aip` library

**Tasks**:
- [ ] Install `euro_aip` library (editable or path dependency)
- [ ] Create `app/services/airport_service.py`
- [ ] Implement model loading (cached or singleton)
- [ ] Implement airport lookup by ICAO
- [ ] Implement country filtering
- [ ] Test with sample queries

**Acceptance Criteria**:
- Can load `EuroAipModel` from `airports.db`
- Can query airports by ICAO code
- Can filter by country
- Never accesses SQLite directly

**Files to Create**:
- `server/app/services/airport_service.py`

### 2.7 Exception Handling
**Deliverable**: Standardized error responses

**Tasks**:
- [ ] Create `app/core/exceptions.py`
- [ ] Implement custom exception classes: `APIError`, `NotFoundError`, `AuthenticationError`, `AuthorizationError`
- [ ] Implement `register_exception_handlers()` function
- [ ] Register handlers in `app/main.py`
- [ ] Test error responses match JSON format

**Acceptance Criteria**:
- All errors return JSON: `{"detail": "...", "status_code": ...}`
- Validation errors are user-friendly
- 500 errors don't leak internal details

**Files to Create**:
- `server/app/core/exceptions.py`

## Phase 3: Domain Models & Schemas

**Goal**: Create Pydantic models matching PHP data structures.

### 3.1 Domain Models
**Deliverable**: Pydantic models inheriting from `BaseJsonModel`

**Tasks**:
- [ ] Create `app/models/airline.py` (Airline model)
- [ ] Create `app/models/aircraft.py` (Aircraft model)
- [ ] Create `app/models/passenger.py` (Passenger model)
- [ ] Create `app/models/flight.py` (Flight model)
- [ ] Create `app/models/ticket.py` (Ticket model)
- [ ] Create `app/models/settings.py` (Settings model)
- [ ] Create `app/models/stats.py` (Stats model)
- [ ] Each model should:
  - Inherit from `BaseJsonModel`
  - Define fields matching PHP `$jsonKeys`
  - Set default values matching PHP `$jsonValuesOptionalDefaults`
  - Implement `unique_identifier()` if needed

**Acceptance Criteria**:
- All models serialize to JSON matching PHP output
- Default values are excluded correctly
- DateTime/DateInterval format correctly
- Can validate from JSON data

**Files to Create**:
- `server/app/models/airline.py`
- `server/app/models/aircraft.py`
- `server/app/models/passenger.py`
- `server/app/models/flight.py`
- `server/app/models/ticket.py`
- `server/app/models/settings.py`
- `server/app/models/stats.py`

### 3.2 API Schemas
**Deliverable**: Request/response schemas for API endpoints

**Tasks**:
- [ ] Create `app/schemas/airline.py` (AirlineCreate, AirlineResponse)
- [ ] Create `app/schemas/aircraft.py` (AircraftCreate, AircraftResponse)
- [ ] Create `app/schemas/passenger.py` (PassengerCreate, PassengerResponse)
- [ ] Create `app/schemas/flight.py` (FlightCreate, FlightResponse, FlightPlan)
- [ ] Create `app/schemas/ticket.py` (TicketCreate, TicketResponse, TicketVerify)
- [ ] Create `app/schemas/common.py` (ErrorResponse, etc.)

**Acceptance Criteria**:
- Request schemas validate input correctly
- Response schemas match PHP JSON output structure
- Field aliases work (e.g., `seatNumber` vs `seat_number`)

**Files to Create**:
- `server/app/schemas/airline.py`
- `server/app/schemas/aircraft.py`
- `server/app/schemas/passenger.py`
- `server/app/schemas/flight.py`
- `server/app/schemas/ticket.py`
- `server/app/schemas/common.py`

## Phase 4: API Endpoints

**Goal**: Implement all API endpoints matching PHP functionality.

### 4.1 Main Application Setup
**Deliverable**: FastAPI app with all routers registered

**Tasks**:
- [ ] Create `app/main.py`
- [ ] Implement lifespan events (startup/shutdown)
- [ ] Register exception handlers
- [ ] Include all routers with correct prefixes
- [ ] Mount static files
- [ ] Implement `/health` endpoint

**Acceptance Criteria**:
- App starts without errors
- All routers are registered
- Health check works
- Static files are served

**Files to Create**:
- `server/app/main.py`

### 4.2 Airline Router
**Deliverable**: Airline management endpoints

**Tasks**:
- [ ] Create `app/routers/airline.py`
- [ ] Implement `POST /v1/airline/create`
- [ ] Implement `GET /v1/airline/{airline_identifier}`
- [ ] Implement `GET /v1/airline/{airline_identifier}/keys`
- [ ] Implement `DELETE /v1/airline/{airline_identifier}` (if needed)
- [ ] Test with sample data

**Acceptance Criteria**:
- All endpoints return correct JSON structure
- Authentication works
- JSON output matches PHP exactly

**Files to Create**:
- `server/app/routers/airline.py`

### 4.3 Aircraft Router
**Deliverable**: Aircraft CRUD endpoints

**Tasks**:
- [ ] Create `app/routers/aircraft.py`
- [ ] Implement `POST /v1/airline/{airline_identifier}/aircraft/create`
- [ ] Implement `GET /v1/airline/{airline_identifier}/aircraft/list` (with stats)
- [ ] Implement `GET /v1/airline/{airline_identifier}/aircraft/{aircraft_identifier}`
- [ ] Implement `GET /v1/airline/{airline_identifier}/aircraft/{aircraft_identifier}/flights`
- [ ] Implement `DELETE /v1/airline/{airline_identifier}/aircraft/{aircraft_identifier}`
- [ ] Test with sample data

**Acceptance Criteria**:
- All endpoints work
- Stats queries return correct counts
- JSON output matches PHP

**Files to Create**:
- `server/app/routers/aircraft.py`

### 4.4 Passenger Router
**Deliverable**: Passenger CRUD endpoints

**Tasks**:
- [ ] Create `app/routers/passenger.py`
- [ ] Implement `POST /v1/airline/{airline_identifier}/passenger/create`
- [ ] Implement `GET /v1/airline/{airline_identifier}/passenger/list` (with stats)
- [ ] Implement `GET /v1/airline/{airline_identifier}/passenger/{passenger_identifier}`
- [ ] Implement `GET /v1/airline/{airline_identifier}/passenger/{passenger_identifier}/tickets`
- [ ] Implement `DELETE /v1/airline/{airline_identifier}/passenger/{passenger_identifier}` (if needed)
- [ ] Test with sample data

**Files to Create**:
- `server/app/routers/passenger.py`

### 4.5 Flight Router
**Deliverable**: Flight planning and management endpoints

**Tasks**:
- [ ] Create `app/routers/flight.py`
- [ ] Implement `POST /v1/airline/{airline_identifier}/flight/plan/{aircraft_identifier}`
- [ ] Implement `POST /v1/airline/{airline_identifier}/flight/amend/{flight_identifier}`
- [ ] Implement `GET /v1/airline/{airline_identifier}/flight/list` (with stats)
- [ ] Implement `GET /v1/airline/{airline_identifier}/flight/{flight_identifier}`
- [ ] Implement `GET /v1/airline/{airline_identifier}/flight/{flight_identifier}/tickets`
- [ ] Implement `DELETE /v1/airline/{airline_identifier}/flight/{flight_identifier}`
- [ ] Implement `POST /v1/airline/{airline_identifier}/flight/check/{flight_identifier}` (mark as TODO if functionality unclear)
- [ ] Test with sample data

**Files to Create**:
- `server/app/routers/flight.py`

### 4.6 Ticket Router
**Deliverable**: Ticket issuance and verification endpoints

**Tasks**:
- [ ] Create `app/routers/ticket.py`
- [ ] Implement `POST /v1/airline/{airline_identifier}/ticket/issue/{flight_identifier}/{passenger_identifier}`
- [ ] Implement `GET /v1/airline/{airline_identifier}/ticket/list`
- [ ] Implement `GET /v1/airline/{airline_identifier}/ticket/{ticket_identifier}`
- [ ] Implement `DELETE /v1/airline/{airline_identifier}/ticket/{ticket_identifier}`
- [ ] Implement `POST /v1/airline/{airline_identifier}/ticket/verify`
- [ ] Test ticket signature generation and verification

**Acceptance Criteria**:
- Ticket signatures match PHP format
- Verification works with PHP-generated signatures

**Files to Create**:
- `server/app/routers/ticket.py`

### 4.7 Boarding Pass Router
**Deliverable**: PKPass generation endpoints

**Tasks**:
- [ ] Create `app/routers/boarding_pass.py`
- [ ] Implement authenticated router:
  - `GET /v1/airline/{airline_identifier}/boardingpass/{ticket_identifier}`
  - `GET /v1/airline/{airline_identifier}/boardingpass/{ticket_identifier}?debug`
- [ ] Implement public router:
  - `GET /v1/boardingpass/{ticket_identifier}` (no airline prefix)
- [ ] Test PKPass generation
- [ ] Test debug mode returns JSON

**Acceptance Criteria**:
- Generated `.pkpass` files are valid
- Debug mode returns pass.json structure
- Public endpoint works without airline auth

**Files to Create**:
- `server/app/routers/boarding_pass.py`

### 4.8 Settings Router
**Deliverable**: Airline settings management

**Tasks**:
- [ ] Create `app/routers/settings.py`
- [ ] Implement `GET /v1/airline/{airline_identifier}/settings`
- [ ] Implement `POST /v1/airline/{airline_identifier}/settings`
- [ ] Test color format conversions

**Files to Create**:
- `server/app/routers/settings.py`

### 4.9 Status & DB Routers
**Deliverable**: System endpoints

**Tasks**:
- [ ] Create `app/routers/status.py`
- [ ] Implement `GET /v1/status` (with database health check)
- [ ] Create `app/routers/db.py`
- [ ] Implement `POST /v1/db/setup` (system auth required)
- [ ] Test database setup creates all tables

**Files to Create**:
- `server/app/routers/status.py`
- `server/app/routers/db.py`

### 4.10 Airport Router
**Deliverable**: Airport information endpoint (optional)

**Tasks**:
- [ ] Create `app/routers/airport.py`
- [ ] Implement `GET /v1/airport/{icao_code}` (if needed)
- [ ] Use `airport_service` with `euro_aip`

**Files to Create**:
- `server/app/routers/airport.py`

## Phase 5: Web Pages

**Goal**: Migrate user-facing HTML pages.

### 5.1 Localization
**Deliverable**: Language detection and localization

**Tasks**:
- [ ] Create `app/core/localization.py`
- [ ] Implement `get_language()` (query param → Accept-Language header → IP fallback)
- [ ] Implement `get_localized_strings()` for en, fr, de, es
- [ ] Test language detection

**Files to Create**:
- `server/app/core/localization.py`

### 5.2 Templates
**Deliverable**: Jinja2 templates for HTML pages

**Tasks**:
- [ ] Copy disclaimer files to `templates/disclaimers/`
- [ ] Create `templates/base.html`
- [ ] Create `templates/boarding_pass.html`
- [ ] Create `templates/boarding_pass_card.html`
- [ ] Test template rendering

**Files to Create**:
- `server/templates/base.html`
- `server/templates/boarding_pass.html`
- `server/templates/boarding_pass_card.html`
- `server/templates/disclaimers/disclaimer_en.html`
- `server/templates/disclaimers/disclaimer_fr.html`
- `server/templates/disclaimers/disclaimer_de.html`
- `server/templates/disclaimers/disclaimer_es.html`

### 5.3 Static Files
**Deliverable**: Static assets (images, CSS, JS)

**Tasks**:
- [ ] Copy images from `../images/` to `server/static/images/`
- [ ] Copy `qrcode.min.js` or configure CDN link
- [ ] Test static file serving

### 5.4 Pages Router
**Deliverable**: User-facing HTML endpoints

**Tasks**:
- [ ] Create `app/routers/pages.py`
- [ ] Implement `GET /pages/yourBoardingPass?ticket={id}&lang={lang}`
- [ ] Implement `GET /pages/airports?which={which}&country={country}`
- [ ] Test pages render correctly
- [ ] Test language switching

**Files to Create**:
- `server/app/routers/pages.py`

## Phase 6: Testing

**Goal**: Comprehensive test coverage.

### 6.1 Test Infrastructure
**Deliverable**: Pytest setup with fixtures

**Tasks**:
- [ ] Create `tests/conftest.py`
- [ ] Implement test database fixture
- [ ] Implement test client fixture
- [ ] Implement sample data fixtures
- [ ] Set up test database schema

**Files to Create**:
- `server/tests/conftest.py`

### 6.2 Unit Tests
**Deliverable**: Tests for services and utilities

**Tasks**:
- [ ] Test `BaseJsonModel` serialization
- [ ] Test repository CRUD operations
- [ ] Test signature service
- [ ] Test PKPass service
- [ ] Test airport service

**Files to Create**:
- `server/tests/test_models.py`
- `server/tests/test_repository.py`
- `server/tests/test_signature.py`
- `server/tests/test_pkpass.py`

### 6.3 Integration Tests
**Deliverable**: API endpoint tests

**Tasks**:
- [ ] Create test files for each router
- [ ] Test all endpoints from `tests/test.zsh`
- [ ] Verify JSON output matches PHP
- [ ] Test error cases (404, 401, 400)
- [ ] Test authentication

**Files to Create**:
- `server/tests/test_airline.py`
- `server/tests/test_aircraft.py`
- `server/tests/test_passenger.py`
- `server/tests/test_flight.py`
- `server/tests/test_ticket.py`
- `server/tests/test_boarding_pass.py`

### 6.4 Test Execution
**Deliverable**: All tests passing

**Tasks**:
- [ ] Run full test suite
- [ ] Fix any failing tests
- [ ] Verify test coverage (aim for 80%+)
- [ ] Document test execution process

## Phase 7: Docker & Deployment

**Goal**: Containerization and deployment configuration.

### 7.1 Dockerfile
**Deliverable**: Production-ready Docker image

**Tasks**:
- [ ] Create `server/Dockerfile`
- [ ] Use multi-stage build (optional, for smaller image)
- [ ] Install dependencies from `pyproject.toml`
- [ ] Copy application code
- [ ] Copy static files and templates
- [ ] Set up health check
- [ ] Test Docker build

**Files to Create**:
- `server/Dockerfile`

### 7.2 Docker Compose
**Deliverable**: Local development and production configurations

**Tasks**:
- [ ] Create `server/docker-compose.yml` (development)
- [ ] Create `server/docker-compose.prod.yml` (production)
- [ ] Configure volume mounts
- [ ] Configure environment variables
- [ ] Test local development setup

**Files to Create**:
- `server/docker-compose.yml`
- `server/docker-compose.prod.yml`

### 7.3 Caddy Configuration
**Deliverable**: Reverse proxy configuration

**Tasks**:
- [ ] Create `server/Caddyfile`
- [ ] Configure reverse proxy to FastAPI
- [ ] Configure automatic HTTPS
- [ ] Configure health checks
- [ ] Configure logging
- [ ] Test with Docker Compose

**Files to Create**:
- `server/Caddyfile`

## Phase 8: Documentation & Finalization

**Goal**: Complete documentation and prepare for deployment.

### 8.1 Documentation
**Deliverable**: Complete project documentation

**Tasks**:
- [ ] Update `server/README.md` with:
  - Setup instructions
  - Development workflow
  - Testing instructions
  - Deployment guide
- [ ] Document environment variables
- [ ] Document API endpoints (OpenAPI docs auto-generated)

### 8.2 Code Review
**Deliverable**: Code quality and consistency

**Tasks**:
- [ ] Run linter (ruff)
- [ ] Run type checker (mypy)
- [ ] Review code for Pythonic best practices
- [ ] Ensure no code duplication
- [ ] Verify all abstractions are used correctly

### 8.3 Pre-Deployment Checklist
**Deliverable**: Ready for test server deployment

**Tasks**:
- [ ] All tests passing
- [ ] All endpoints implemented
- [ ] JSON output matches PHP (byte-for-byte where possible)
- [ ] Docker image builds successfully
- [ ] Health checks work
- [ ] Logging configured
- [ ] Error handling tested

## Implementation Order Recommendation

**Suggested Sequence** (can be parallelized where dependencies allow):

1. **Week 1**: Phase 1 (Foundation) + Phase 2.1-2.3 (Base patterns)
2. **Week 2**: Phase 2.4-2.7 (Services) + Phase 3 (Models)
3. **Week 3**: Phase 4.1-4.6 (Core API endpoints)
4. **Week 4**: Phase 4.7-4.10 (Remaining endpoints) + Phase 5 (Web pages)
5. **Week 5**: Phase 6 (Testing) + Phase 7 (Docker)
6. **Week 6**: Phase 8 (Documentation) + Test server deployment

## Success Criteria

The migration is considered complete when:

- ✅ All endpoints from `tests/test.zsh` are implemented
- ✅ All endpoints return JSON matching PHP output structure
- ✅ All tests pass (unit + integration)
- ✅ PKPass generation produces valid `.pkpass` files
- ✅ Web pages render correctly with localization
- ✅ Docker image builds and runs successfully
- ✅ Health checks pass
- ✅ Code passes linting and type checking
- ✅ Documentation is complete

## Risk Mitigation

**Potential Issues & Solutions**:

1. **JSON Serialization Mismatch**
   - **Risk**: PHP and Python produce different JSON
   - **Mitigation**: Extensive testing, byte-for-byte comparison where possible

2. **PKPass Library Compatibility**
   - **Risk**: `passes-rs-py` doesn't match PHP behavior exactly
   - **Mitigation**: Test early, have `py-pkpass` as fallback

3. **Database Schema Differences**
   - **Risk**: Table definitions don't match existing schema
   - **Mitigation**: Verify against actual database, test with existing data

4. **Performance Issues**
   - **Risk**: Python implementation slower than PHP
   - **Mitigation**: Profile early, optimize hot paths, use async properly

5. **Missing Functionality**
   - **Risk**: Some PHP behavior not documented
   - **Mitigation**: Test against PHP endpoints, compare outputs

## Next Steps

1. **Review this plan** with team
2. **Set up development environment** (Phase 1.1)
3. **Begin Phase 1** implementation
4. **Daily standups** to track progress
5. **Weekly reviews** of completed phases

---

**Ready for Implementation**: ✅ Yes

All architectural decisions are finalized, patterns are defined, and the plan is comprehensive. The implementation can begin immediately with Phase 1.

