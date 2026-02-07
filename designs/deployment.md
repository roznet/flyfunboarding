# Deployment

Infrastructure setup for the Python/FastAPI server on DigitalOcean, including Docker, Caddy reverse proxy, certificate handling, and hard-won deployment lessons.

## Infrastructure

### Droplets

| Droplet | Hostname | Purpose |
|---------|----------|---------|
| Old | ro-z.net | Apache, native MySQL, PHP server (legacy) |
| New | flyfun.aero | Caddy (system), Docker containers |

### Port Assignments (flyfun.aero)

| Port | Service | Caddy Site |
|------|---------|------------|
| 8000 | maps.flyfun.aero | maps.flyfun.aero |
| 8001 | chromadb | (internal) |
| 8002 | mcp.flyfun.aero | mcp.flyfun.aero |
| 8010 | flyfunboarding-api | boarding.flyfun.aero |
| 8080 | ro-z.net WordPress | ro-z.net |

### Shared Infrastructure

- **MySQL**: Runs in Docker container `shared-mysql` on `shared-services` network
- **Caddy**: System service (`systemctl`), not containerized. Configs in `/etc/caddy/sites-enabled/`
- **Docker network**: `shared-services` (external) connects app containers to shared MySQL

## Docker Setup

### Dockerfile (`server/Dockerfile`)

Multi-stage build:
1. **Builder** — Python 3.13-slim, installs deps into `/opt/venv`
2. **Runtime** — Python 3.13-slim, copies venv + app code, runs as non-root `appuser`

```
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### docker-compose.prod.yml

```yaml
services:
  flyfunboarding-api:
    ports: ["127.0.0.1:8010:8000"]  # Localhost only; Caddy handles external
    networks: [shared-services]
    volumes:
      - ../certs:/app/certs:ro
      - ../keys:/app/keys:ro
      - ../images:/app/images:ro
    environment:
      DB_HOST: shared-mysql  # Docker DNS resolves to MySQL container
```

Environment variables from `.env` file (not committed): `DB_USER`, `DB_PASSWORD`, `SECRET`, `CERTIFICATE_PASSWORD`.

### Build & Deploy

```bash
cd ~/flyfunboarding/server
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d
docker compose -f docker-compose.prod.yml logs -f  # Check startup
```

## Caddy Configuration

Per-site configs in `/etc/caddy/sites-enabled/`:

```
# boarding.flyfun.aero.caddy
boarding.flyfun.aero {
    reverse_proxy localhost:8010
}
```

Main Caddy config imports all site configs:
```
import /etc/caddy/sites-enabled/*.caddy
```

### Reloading

```bash
sudo systemctl reload caddy
```

### Config Management

Configs are maintained locally in `~/Developer/private/digitalocean/flyfun.aero/etc/caddy/sites-enabled/` and pushed to the droplet using `syncfiles`:

```bash
syncfiles push --execute  # Push configs and execute reload commands
```

## Certificate Setup

### Apple Wallet Signing

The PKPass generator needs a PEM certificate and private key extracted from the Apple-provided P12 file.

#### Extract from P12

```bash
# Extract certificate (clean PEM, no bag attributes)
openssl pkcs12 -in certificate.p12 -clcerts -nokeys -out certificate.pem

# Extract private key (clean PEM, no bag attributes)
openssl pkcs12 -in certificate.p12 -nocerts -nodes -out certificate.key
```

**Critical**: Use `-clcerts -nokeys` and `-nocerts -nodes` flags. A raw `-nodes` dump includes "Bag Attributes" metadata that `passes-rs-py` cannot parse (causes "PEM error in post-encapsulation boundary").

#### File Layout on Droplet

```
~/flyfunboarding/
├── certs/
│   ├── certificate.pem    # Apple Wallet signing cert
│   ├── certificate.key    # Private key
│   └── AppleWWDRCA.pem    # Apple WWDR intermediate cert
├── keys/                  # RSA key pairs (auto-generated per airline)
├── images/                # PKPass icons and logos
└── server/
    └── docker-compose.prod.yml  # Mounts certs/keys/images as :ro volumes
```

## Deployment Gotchas

These are real issues encountered during the PHP-to-Python migration. Each one caused production failures.

### 1. Caddy Port Sync

**Symptom**: POST returns 405 with `chroma-trace-id` header.
**Cause**: Caddy config still pointed to old port (8001 = chromadb) instead of new port (8010 = flyfunboarding).
**Fix**: After changing port in docker-compose, must re-sync Caddy config AND reload (`sudo systemctl reload caddy`).
**Lesson**: Always verify the response headers when debugging routing. A `chroma-trace-id` header means you're hitting ChromaDB, not your app.

### 2. Airline Registration Has No Auth

**Symptom**: iOS app gets 401 on `POST /api/v1/airline/create`.
**Cause**: Python endpoint had `SystemAuth` dependency, but iOS sends no Authorization header for registration.
**Fix**: Remove `SystemAuth` from `create_airline`. The `apple_identifier` from Apple Sign In is the credential — the SECRET should never be in the app bundle.
**Lesson**: Check the PHP source to see which endpoints required auth. Registration is unauthenticated by design.

### 3. ISO 8601 Dates Need Timezone

**Symptom**: iOS app can't decode passenger/aircraft lists. Error: "Expected date string to be ISO8601-formatted."
**Cause**: MySQL stores naive datetimes. Python's `isoformat()` on naive datetimes omits timezone. iOS's `.iso8601` decoder requires it.
**Fix**: Append `+00:00` to naive datetimes. Applied in `BaseJsonModel.json_encoders` and `_format_iso8601()` helpers in routers.
**Lesson**: PHP's `DateTime->format('c')` always includes timezone. Python doesn't. Always check.

### 4. Use Root-Relative URLs Behind Proxy

**Symptom**: Mixed content errors — browser blocks `http://` resources on `https://` page.
**Cause**: `request.base_url` returns `http://` when behind Caddy HTTPS proxy (no X-Forwarded-Proto handling).
**Fix**: Use root-relative paths (start with `/`) instead of absolute URLs built from `request.base_url`.
**Lesson**: Never build absolute URLs from `request.base_url` in templates. Use `/static/...`, `/pages/...`, `/api/v1/...`.

### 5. PEM Certificate Formatting

**Symptom**: PKPass generation fails with "PEM error in post-encapsulation boundary".
**Cause**: PEM file has "Bag Attributes" metadata from raw `openssl pkcs12 -nodes` export.
**Fix**: Use `-clcerts -nokeys` for cert extraction, `-nocerts -nodes` for key extraction. These flags produce clean PEM without bag attributes.
**Lesson**: The `passes-rs-py` Rust library is strict about PEM format. No extra metadata allowed.

### 6. PKPass Barcodes Field

**Symptom**: Boarding pass appears in Apple Wallet but has no QR code.
**Cause**: `passes-rs-py` reads `barcodes` (plural array), ignoring the deprecated `barcode` (singular object).
**Fix**: Include both `barcode` (for older clients) and `barcodes: [barcode]` (for passes-rs-py and modern clients).
**Lesson**: Apple's PassKit spec has both fields. The singular `barcode` is deprecated; always include the plural `barcodes` array.

### 7. Path-Based URLs for iOS

**Symptom**: Boarding pass page returns 404.
**Cause**: iOS builds `/pages/yourBoardingPass/{id}` (path segment), but Python route only had query param `?ticket={id}`. PHP used Apache rewrite rules.
**Fix**: Add path-based route `/yourBoardingPass/{ticket_identifier}` that delegates to the query-param handler.
**Lesson**: Check how iOS constructs URLs (in `Ticket.swift`) and ensure the server has matching routes.

### 8. USE_PUBLIC_KEY_SIGNATURE Must Match PHP Config

**Symptom**: QR code on boarding pass is too dense for the scanner to read.
**Cause**: Droplet `.env` had `USE_PUBLIC_KEY_SIGNATURE=true` (the default), but PHP production ran with `false`. With `true`, the QR payload is ~502 bytes (includes 344-char base64 RSA signature). With `false`, it's ~170 bytes (hash only).
**Fix**: Set `USE_PUBLIC_KEY_SIGNATURE=false` in the droplet's `.env` and restart the container (`docker compose up -d` — no rebuild needed, env vars are runtime).
**Lesson**: Match the PHP production config values, not the defaults. The simplified hash-only mode is sufficient and produces scannable QR codes.

## Health Checks

- **Docker healthcheck**: `curl -f http://localhost:8000/health` (every 30s)
- **Application**: `GET /health` returns `{"status": "ok"}`
- **Database**: `GET /api/v1/status` checks if Airlines table exists

## Logs

```bash
# Container logs
docker compose -f docker-compose.prod.yml logs -f

# Caddy logs
sudo journalctl -u caddy -f
```
