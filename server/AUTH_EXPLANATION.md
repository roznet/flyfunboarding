# Authentication System Explanation

## Two Types of Authentication

### 1. System Authentication (SECRET)
**When to use:** System-level operations
**Token:** `SECRET` from `.env` file
**Example:** `e8633ca0c72283dab6b86bf08bd7058e5273dc76604bac06dd8d28558bdaa625`

**Endpoints that use System Auth:**
- `POST /v1/airline/create` - Create a new airline
- `POST /v1/db/setup` - Database setup (if implemented)

**How it works:**
```python
# In app/dependencies.py -> get_system_auth()
token = authorization.removeprefix("Bearer ")
if token != settings.SECRET:  # Compare with .env SECRET
    raise HTTPException(401, "Invalid system token")
```

**Example curl:**
```bash
curl -X POST http://localhost:8001/v1/airline/create \
  -H "Authorization: Bearer e8633ca0c72283dab6b86bf08bd7058e5273dc76604bac06dd8d28558bdaa625" \
  -H "Content-Type: application/json" \
  -d '{"apple_identifier": "test.airline.123", "airline_name": "Test Airline"}'
```

---

### 2. Airline Authentication (apple_identifier)
**When to use:** Airline-scoped operations
**Token:** The airline's `apple_identifier` (stored in database)
**Example:** `001088.73b13a9e6be34ca89cf8b19628a87315.1521`

**Endpoints that use Airline Auth:**
- `GET /v1/airline/{airline_identifier}/aircraft/list`
- `POST /v1/airline/{airline_identifier}/aircraft/create`
- `GET /v1/airline/{airline_identifier}/flight/list`
- `POST /v1/airline/{airline_identifier}/flight/plan/{aircraft_identifier}`
- `POST /v1/airline/{airline_identifier}/ticket/issue/{flight_identifier}/{passenger_identifier}`
- etc.

**How it works:**
```python
# In app/dependencies.py -> get_airline_context()
1. Extract airline_identifier from URL: /v1/airline/{airline_identifier}/...
2. Look up airline in database using airline_identifier
3. Get airline's apple_identifier from json_data
4. Compare: token == airline.apple_identifier
```

**Example curl:**
```bash
# First, get the airline_identifier (SHA1 hash of apple_identifier)
# Then use the apple_identifier as the Bearer token:
curl -X GET http://localhost:8001/v1/airline/e8da4a10f16146e0fea48326c993594280c078c2/aircraft/list \
  -H "Authorization: Bearer 001088.73b13a9e6be34ca89cf8b19628a87315.1521"
```

---

## How to Find Your Tokens

### System SECRET
```bash
# Check .env file
grep SECRET server/.env

# Or check what Python loads:
cd server && source ../venv/bin/activate
python -c "from app.config import settings; print(settings.SECRET)"
```

### Airline apple_identifier
```bash
# After creating an airline, the apple_identifier is in the response:
curl -X POST http://localhost:8001/v1/airline/create \
  -H "Authorization: Bearer YOUR_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"apple_identifier": "my.airline.id", "airline_name": "My Airline"}'

# Response includes:
# {
#   "apple_identifier": "my.airline.id",  <-- This is your airline token!
#   "airline_identifier": "abc123...",     <-- This goes in the URL
#   ...
# }
```

---

## Summary Table

| Endpoint Type | Auth Type | Token Source | Example Token |
|--------------|-----------|--------------|---------------|
| System operations | System SECRET | `.env` file | `e8633ca0c72283...` |
| Airline operations | apple_identifier | Database (from airline creation) | `001088.73b13a9e...` |

---

## PHP vs Python

**PHP:**
- System operations: No auth check (we added it in Python for security)
- Airline operations: `$airline->validate()` checks `Bearer token == $airline->apple_identifier`

**Python:**
- System operations: `SystemAuth` dependency checks `token == settings.SECRET`
- Airline operations: `CurrentAirline` dependency checks `token == airline.apple_identifier`



