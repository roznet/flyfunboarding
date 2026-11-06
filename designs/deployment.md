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
- **Caddy**: Docker container with host networking (`shared-infra/caddy/` in the private `digitalocean` repo). Site configs in that repo's `flyfun.aero/etc/caddy/sites-enabled/`
- **Docker network**: `shared-services` (external) connects app containers to shared MySQL

## Docker Setup

### Dockerfile (`server/Dockerfile`)

Multi-stage build:
1. **Builder** — Python 3.13-slim, installs deps into `/opt/venv`
2. **Runtime** — Python 3.13-slim, copies venv + app code, runs as non-root `appuser`

```
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### docker-compose.yml

One compose file, `server/docker-compose.yml`, used in prod (`~/flyfunboarding/server`) and locally. There is no separate prod file.

```yaml
services:
  flyfunboarding-api:
    env_file:
      - path: .env.secrets      # secrets, passed verbatim; compose fails if it is missing
        required: true
    environment:                # non-secret: container paths + ${...} from .env
      DB_HOST: shared-mysql     # Docker DNS resolves to MySQL container
      CERTIFICATE_PATH: /app/certs/certificate.pem
      KEYS_PATH: /app/keys
      # ... DB_USER, DB_NAME, DEBUG, LOG_LEVEL, CORS_ORIGINS, USE_PUBLIC_KEY_SIGNATURE
    ports: ["127.0.0.1:8010:8000"]  # Localhost only; Caddy handles external
    networks: [shared-services]
    volumes:
      - ../certs:/app/certs:ro
      - ../keys:/app/keys       # read-write: the server creates per-airline key pairs
      - ../images:/app/images:ro
```

### Configuration and secrets

Two files in `server/`, both gitignored and dockerignored:

| File | Contents | How it reaches the container |
|------|----------|------------------------------|
| `.env` | Plain config (`DB_USER`, `DB_NAME`, `DEBUG`, `LOG_LEVEL`, `CORS_ORIGINS`, `USE_PUBLIC_KEY_SIGNATURE`) plus host paths for running outside Docker | Compose reads it automatically for the `${...}` values in `environment:`. Never passed whole: its host paths (`CERTIFICATE_PATH`, `KEYS_PATH`, ...) must not override the container paths |
| `.env.secrets` | `DB_PASSWORD`, `SECRET`, `CERTIFICATE_PASSWORD`. Sops-encrypted in the config repo, installed mode 600 by syncfiles | `env_file:` (verbatim, no `${...}` interpolation in the compose file) |

Rules:
- **Never put a secret in `environment:` or behind `${...}`.** Interpolation only reads `.env`, so a secret there would need `--env-file` flags on every command, and without them it silently blanks.
- **Single-quote secret values** in `.env.secrets` (`SECRET='...'`). Compose expands `$VAR`/`${VAR}` in unquoted and double-quoted `env_file` values. Don't escape with `$$` and don't use backslashes, because compose and python-dotenv disagree on both. Details are in `.env.secrets.sample`.
- Outside Docker, `Settings` (`app/config.py`) reads `server/.env` and then `server/.env.secrets`, resolved from `server/` whatever the current directory. `.env.secrets` wins on duplicate keys, and real environment variables beat both. Dotenv interpolation is disabled, so `$` in a value is literal. Covered by `tests/test_config.py`.
- The server refuses to start (lifespan check) if `DB_PASSWORD` or `SECRET` is empty, so a missing `.env.secrets` shows up as a crash loop in `docker compose logs`, not a silently insecure server. An empty `SECRET` would otherwise let `Bearer ` with no token pass system auth.

### Build & Deploy

```bash
cd ~/flyfunboarding/server
git pull
docker compose up -d --build
docker compose logs -f  # Check startup
```

No `--env-file` flags and no `-f`. A config-only change (`.env` or `.env.secrets`) needs `docker compose up -d` without `--build`. `restart` does not re-read env files.

### Secret files read at runtime

All of these must be encrypted in the config repo and backed up:

| File (host) | Read by | Purpose |
|-------------|---------|---------|
| `server/.env.secrets` | compose `env_file` | `DB_PASSWORD`, `SECRET` (QR `secret_hash` + system Bearer token), `CERTIFICATE_PASSWORD` (only used for a `.p12`; empty in prod) |
| `certs/certificate.key` | `boarding_pass_service._get_key_path()` | **Pass signing private key.** The key path is derived from `CERTIFICATE_PATH`: `certificate.pem` becomes `certificate.key` (it falls back to `certificate.pem` itself if no `.key` exists). It must be an unencrypted PEM, because `passes-rs-py` gets no password |
| `certs/certificate.pem` | `_get_cert_path()` | Pass Type ID certificate (public, but needed) |
| `certs/AppleWWDRCA.pem` | `WWDR_PATH` | Apple intermediate (public, re-downloadable) |
| `keys/<apple_identifier>.pem` | `SignatureService` | Per-airline RSA private keys, **created by the server** at airline registration (hence the rw mount). Used for QR signatures when `USE_PUBLIC_KEY_SIGNATURE=true`. Losing them invalidates that airline's signatures |
| `keys/<apple_identifier>.pub` | `SignatureService` | Matching public keys |

`certs/Certificates.p12` is **not** read at runtime. It is only a backup of cert + key.

## Caddy Configuration

Per-site configs in the private `digitalocean` repo, `flyfun.aero/etc/caddy/sites-enabled/`, mounted read-only into the Caddy container at `/etc/caddy/`:

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

Validates, then reloads with no downtime. No sudo needed:

```bash
cd ~/digitalocean && git pull && shared-infra/caddy/reload.sh
```

### Config Management

Configs are edited locally in `~/Developer/private/digitalocean/flyfun.aero/etc/caddy/sites-enabled/`, committed and pushed, then deployed with the reload command above. `syncfiles` no longer deploys them.

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
    └── docker-compose.yml  # Mounts certs/images :ro, keys/ rw
```

`Certificates.p12` may also sit in `certs/` as a backup bundle (cert + key) from the original Keychain export. The server does not read it: `CERTIFICATE_PATH` points at `certificate.pem`, and the P12 extraction path in `boarding_pass_service.py` only runs if `CERTIFICATE_PATH` ends in `.p12`.

#### Renewing the Pass Type ID Certificate

The Pass Type ID certificate (`pass.net.ro-z.flyfunboardingpass`) is valid for one year. Apple emails about 30 days before expiry. After it expires, newly generated passes fail to install in Wallet; passes already in Wallet keep working. Last renewed 2026-10-28, next expiry **2027-11-27**.

Reuse the existing private key so only `certificate.pem` changes (no P12 re-export, no `CERTIFICATE_PASSWORD` change):

```bash
# 1. On the droplet: CSR from the existing key
cd ~/flyfunboarding/certs
openssl req -new -key certificate.key -out pass.csr \
  -subj "/emailAddress=brice.rosenzweig@gmail.com/CN=Brice Rosenzweig/C=GB"
```

2. In the Apple Developer portal: Certificates → **+** → *Pass Type ID Certificate* → select `pass.net.ro-z.flyfunboardingpass` → upload `pass.csr` → download `pass.cer`.

```bash
# 3. Convert (Apple delivers DER) and verify it pairs with the key
openssl x509 -inform DER -in pass.cer -out certificate.pem.new
openssl x509 -in certificate.pem.new -noout -pubkey | openssl sha256
openssl pkey -in certificate.key -pubout | openssl sha256      # must match
openssl x509 -in certificate.pem.new -noout -subject -enddate

# 4. Swap and restart
cp -p certificate.pem certificate.pem.exp-<old-expiry-date>
mv certificate.pem.new certificate.pem
cd ../server && docker compose restart
```

5. Test: generate a boarding pass from the iOS app and add it to Wallet.

**WWDR intermediate**: the pass cert is issued by WWDR **G4**, while `AppleWWDRCA.pem` on the droplet is **G6**. Wallet accepts passes signed this way (verified 2026-10-28). If passes ever start failing after a renewal, first try replacing it with the G4 intermediate from `https://www.apple.com/certificateauthority/AppleWWDRCAG4.cer` (convert with `openssl x509 -inform DER`).

## Deployment Gotchas

These are real issues encountered during the PHP-to-Python migration. Each one caused production failures.

### 1. Caddy Port Sync

**Symptom**: POST returns 405 with `chroma-trace-id` header.
**Cause**: Caddy config still pointed to old port (8001 = chromadb) instead of new port (8010 = flyfunboarding).
**Fix**: After changing port in docker-compose, must update the Caddy config AND reload (`shared-infra/caddy/reload.sh`).
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
**Fix**: Set `USE_PUBLIC_KEY_SIGNATURE=false` in the droplet's `.env` and recreate the container (`docker compose up -d` — no rebuild needed, env vars are runtime).
**Lesson**: Match the PHP production config values, not the defaults. The simplified hash-only mode is sufficient and produces scannable QR codes.

## Health Checks

- **Docker healthcheck**: `curl -f http://localhost:8000/health` (every 30s)
- **Application**: `GET /health` returns `{"status": "ok"}`
- **Database**: `GET /api/v1/status` checks if Airlines table exists

## Logs

```bash
# Container logs
docker compose logs -f

# Caddy logs
docker logs -f caddy
```
