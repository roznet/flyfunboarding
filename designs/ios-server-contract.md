# iOS–Server Contract

API contract between the iOS app and the FastAPI server. Covers URL construction, authentication, JSON serialization, date formats, and boarding pass sharing.

## URL Construction

### iOS Side (`Secrets.swift`)

The app reads `flyfun_base_url` and `flyfun_api_version` from `secrets.json`:

```swift
// API: {base_url}/api/{version}/
var flyfunApiUrl: URL {
    URL(string: "\(flyfunBaseUrlString)/api/\(flyfunApiVersion)/")!
}

// Pages: {base_url}/pages/
var flyfunPagesUrl: URL {
    URL(string: "\(flyfunBaseUrlString)/pages/")!
}
```

`secrets.json` example:
```json
{
    "flyfun_base_url": "https://boarding.flyfun.aero",
    "flyfun_api_version": "v1"
}
```

### URL Building (`RemoteService.swift`)

All API calls build paths relative to `flyfunApiUrl`:

```swift
// With airline scope:
"airline/{airlineIdentifier}/{resource}/{action}"

// Without airline scope (registration):
"airline/create"
```

Using `URL(string: path, relativeTo: baseUrl)` — paths must NOT start with `/`.

### Server Side (`config.py`)

```python
api_prefix = f"/api/{API_VERSION}"  # → "/api/v1"
```

Routes registered as `f"{api_prefix}/airline"`, `f"{api_prefix}/boardingpass"`, etc.

## Authentication

### Pattern

Bearer token in `Authorization` header. The token IS the airline's `apple_identifier` (from Apple Sign In).

```swift
// iOS
request.setValue("Bearer \(airline.appleIdentifier)", forHTTPHeaderField: "Authorization")
```

```python
# Server (dependencies.py)
token = credentials.credentials  # From HTTPBearer
airline = db.query(where apple_identifier == token)
```

### Per-Endpoint Auth

| Endpoint | Auth | iOS Behavior |
|----------|------|-------------|
| `POST airline/create` | **None** | `requireAirline: false` — no Authorization header |
| `GET airline/{id}` | Bearer | Sends `airline.authorizationBearer` |
| All `aircraft/*`, `passenger/*`, `flight/*`, `ticket/*` | Bearer | Sends `airline.authorizationBearer` |
| `GET boardingpass/{ticket_id}` (public) | **None** | N/A (opened in browser) |
| `GET /pages/yourBoardingPass/{id}` | **None** | Opened in Safari/WebView |

**Critical**: `airline/create` must NOT require auth. The `apple_identifier` is the credential itself, sent in the POST body. The app has no token before registration.

## JSON Serialization

### Field Naming

Server uses camelCase aliases matching PHP's original JSON output:

| Python Field | JSON Key | iOS Property |
|-------------|----------|-------------|
| `airline_name` | `airlineName` | `airlineName` |
| `apple_identifier` | `appleIdentifier` | `appleIdentifier` |
| `flight_number` | `flightNumber` | `flightNumber` |
| `seat_number` | `seatNumber` | `seatNumber` |
| `scheduled_departure_date` | `scheduledDepartureDate` | `scheduledDepartureDate` |
| `formatted_name` | `formattedName` | `formattedName` |
| `aircraft_id` | `aircraft_id` | `aircraft_id` |
| `airline_id` | `airline_id` | `airlineId` |

### Exclude Defaults

Server's `BaseJsonModel.to_json()` excludes fields matching their defaults (`exclude_defaults=True`). This matches PHP's `JsonHelper::toJson()`. iOS must handle optional/missing fields.

### Encoder/Decoder

```swift
// iOS
static let decoder: JSONDecoder = {
    let rv = JSONDecoder()
    rv.dateDecodingStrategy = .iso8601
    return rv
}()

static let encoder: JSONEncoder = {
    let rv = JSONEncoder()
    rv.dateEncodingStrategy = .iso8601
    return rv
}()
```

## Date Formats

### Requirements

iOS uses `.iso8601` date decoding, which **requires** a timezone suffix. All dates from the server must include timezone info.

### Server Rules

1. **Model serialization** (`BaseJsonModel.json_encoders`): Appends `+00:00` to naive datetimes
2. **Stats dates** (routers): Use `_format_iso8601()` helper on `last` fields from MySQL JOINs
3. **Flight dates**: `scheduledDepartureDate` stored as ISO string in `json_data`

```python
# Helper used in routers (passenger.py, aircraft.py, flight.py)
def _format_iso8601(dt: datetime | None) -> str | None:
    if dt is None:
        return None
    return dt.isoformat() + "+00:00" if dt.tzinfo is None else dt.isoformat()
```

### Format Examples

```
Good:  "2024-06-19T08:00:00+00:00"  ← iOS can decode
Bad:   "2024-06-19T08:00:00"         ← iOS rejects (no timezone)
```

## API Endpoints (iOS → Server)

### Airline

```
POST  airline/create                              → Airline
GET   airline/{airlineIdentifier}                  → Airline
GET   airline/{airlineIdentifier}/keys             → Airline.Keys
DELETE airline/{airlineIdentifier}                  → Bool
GET   airline/{airlineIdentifier}/settings         → Airline.Settings
POST  airline/{airlineIdentifier}/settings         → Airline.Settings
```

### Aircraft

```
POST  airline/{id}/aircraft/create                 → Aircraft
GET   airline/{id}/aircraft/list                   → [Aircraft]
GET   airline/{id}/aircraft/{aircraftId}            → Aircraft
GET   airline/{id}/aircraft/{aircraftId}/flights    → [Flight]
DELETE airline/{id}/aircraft/{aircraftId}            → Bool
```

### Passenger

```
POST  airline/{id}/passenger/create                → Passenger
GET   airline/{id}/passenger/list                  → [Passenger]
GET   airline/{id}/passenger/{passengerId}          → Passenger
GET   airline/{id}/passenger/{passengerId}/tickets  → [Ticket]
```

### Flight

```
POST  airline/{id}/flight/plan/{aircraftId}        → Flight
POST  airline/{id}/flight/amend/{flightId}         → Flight
GET   airline/{id}/flight/list                     → [Flight]
GET   airline/{id}/flight/{flightId}               → Flight
GET   airline/{id}/flight/{flightId}/tickets       → [Ticket]
POST  airline/{id}/flight/check/{flightId}         → Flight
DELETE airline/{id}/flight/{flightId}               → Bool
```

### Ticket

```
POST  airline/{id}/ticket/issue/{flightId}/{passengerId} → Ticket
GET   airline/{id}/ticket/list                           → [Ticket]
GET   airline/{id}/ticket/{ticketId}                     → Ticket
POST  airline/{id}/ticket/verify                         → Ticket
DELETE airline/{id}/ticket/{ticketId}                     → Bool
```

## Boarding Pass Sharing

### Flow

1. iOS creates a share URL: `{pagesUrl}/yourBoardingPass/{ticketIdentifier}`
2. Recipient opens URL in Safari
3. Server renders HTML page with boarding pass card, QR code, and "Add to Apple Wallet" button
4. "Add to Wallet" button links to: `{apiPrefix}/boardingpass/{ticketIdentifier}`
5. Server generates PKPass file and returns it as `application/vnd.apple.pkpass`

### URL Patterns

```
# Boarding pass HTML page (path-based, used by iOS)
GET /pages/yourBoardingPass/{ticket_identifier}?lang=fr

# Boarding pass HTML page (query-param, legacy)
GET /pages/yourBoardingPass?ticket={ticket_identifier}&lang=fr

# PKPass download (public, no auth)
GET /api/v1/boardingpass/{ticket_identifier}

# PKPass download (authenticated, airline-scoped)
GET /api/v1/airline/{id}/boardingpass/{ticket_identifier}
```

### iOS URL Construction (`Ticket.swift`)

```swift
var disclaimerUrl: URL {
    URL(string: "yourBoardingPass/\(identifier)", relativeTo: Secrets.shared.flyfunPagesUrl)!
}

var downloadPassUrl: URL {
    URL(string: "boardingPass/\(identifier)", relativeTo: Secrets.shared.flyfunApiUrl)!
}
```

## Stats Format

List endpoints (`aircraft/list`, `passenger/list`, `flight/list`) include stats from related tables:

```json
{
    "stats": [
        {
            "table": "Flights",
            "count": 3,
            "last": "2024-06-19T08:00:00+00:00"
        }
    ]
}
```

The `last` field is a datetime that MUST include timezone (see Date Formats above).

## Ticket Signature

QR codes on boarding passes contain a signed ticket payload:

```json
{
    "ticket": "{ticket_identifier}",
    "signatureDigest": {
        "hash": "SHA256(SECRET + ticket_identifier)",
        "signature": "RSA_SIGN(ticket_identifier)",
        "publicKey": "base64_encoded_public_key"
    }
}
```

Verification via `POST ticket/verify` checks both the hash (using shared SECRET) and RSA signature (using stored public key).
