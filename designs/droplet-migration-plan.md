# Droplet Migration Plan: boarding.flyfun.aero

Migration of flyfunboarding from PHP on the old droplet (ro-z.net) to Python/FastAPI on the new droplet (flyfun.aero / connect.flyfun.aero).

## Architecture

### Old Setup (ro-z.net / 159.65.93.140)
- Apache reverse proxy (native)
- Native MySQL
- PHP flyfunboarding at `flyfun.aero/boarding/api/`

### New Setup (connect.flyfun.aero / 161.35.35.15)
- Caddy reverse proxy (systemctl service)
- Docker MySQL (`shared-mysql` on `shared-services` network)
- Python/FastAPI container at `boarding.flyfun.aero`

### URL Structure (new)

| Path | Purpose | Versioned |
|------|---------|-----------|
| `/api/v1/...` | API endpoints | Yes (from `settings.API_VERSION`) |
| `/pages/...` | Passenger-facing HTML | No |
| `/static/...` | Static assets | No |
| `/health` | Infrastructure health check | No |
| `/api` | API discovery (versions, endpoints) | No |

### Port Assignments (new droplet)

| Port | Service |
|------|---------|
| 8000 | maps.flyfun.aero |
| 8001 | boarding.flyfun.aero |
| 8002 | mcp.flyfun.aero |
| 8080 | ro-z.net (WordPress) |

### iOS App Configuration

`secrets.json` uses separate keys for base URL and API version:
```json
{
    "flyfun_base_url": "https://boarding.flyfun.aero",
    "flyfun_api_version": "v1"
}
```

`Secrets.swift` builds:
- `flyfunApiUrl` = `{base_url}/api/{version}/`
- `flyfunPagesUrl` = `{base_url}/pages/`

## Prerequisites (already done)

- DNS: `boarding.flyfun.aero` A record pointing to 161.35.35.15
- shared-infra MySQL running on new droplet
- WordPress migrated to new droplet
- Code changes: API prefix from config, iOS URL config split, Caddy site config created
- Port 8001 assigned (avoids conflict with maps on 8000)

## Migration Steps

### Phase 1: Local - Commit & Push

On **Mac**:

1. Commit the flyfunboarding repo changes:
   - `server/app/config.py` - added `api_prefix` property
   - `server/app/main.py` - route prefixes from config, `/api` discovery endpoint
   - `server/docker-compose.yml` / `docker-compose.prod.yml` - health checks, port binding
   - `server/Dockerfile` - health check uses `/health`
   - `server/tests/` - all paths updated to `/api/v1/`
   - `app/flyfunboarding/Source/Secrets.swift` - split URL config
   - `app/flyfunboarding/Source/Ticket.swift` - uses `flyfunPagesUrl`
   - `app/flyfunboarding/Source/RemoteService.swift` - uses `flyfunApiUrl`
   - `app/flyfunboarding/secrets.json` / `secrets.sample.json` - new key structure

2. Commit the digitalocean repo changes:
   - `flyfun.aero/etc/caddy/sites-enabled/boarding.flyfun.aero.caddy`

3. Push both repos.

### Phase 2: New Droplet - Database Setup

4. Create the `flyfunboarding` database and user in shared-mysql:
   ```bash
   sudo docker exec -it shared-mysql mysql -u root -p
   ```
   ```sql
   CREATE DATABASE IF NOT EXISTS flyfunboarding
     CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   CREATE USER IF NOT EXISTS 'flyfunboarding'@'%'
     IDENTIFIED BY '<secure_password>';
   GRANT ALL PRIVILEGES ON flyfunboarding.* TO 'flyfunboarding'@'%';
   FLUSH PRIVILEGES;
   ```
   Note: if the user already exists from the init script (with `CHANGE_THIS_PASSWORD`),
   use `ALTER USER 'flyfunboarding'@'%' IDENTIFIED BY '<secure_password>';` instead.

### Phase 3: Old Droplet - Export Data

5. Export the flyfunboarding database:
   ```bash
   mysqldump -u root -p flyfunboarding > ~/flyfunboarding_dump.sql
   ```

6. Transfer to new droplet:
   ```bash
   scp ~/flyfunboarding_dump.sql brice@161.35.35.15:~/
   ```

### Phase 4: New Droplet - Import Data

7. Import into shared-mysql:
   ```bash
   sudo docker exec -i shared-mysql mysql -u root -p flyfunboarding < ~/flyfunboarding_dump.sql
   ```

### Phase 5: New Droplet - Clone & Copy Secrets

8. Clone the repo:
   ```bash
   cd ~
   git clone https://github.com/roznet/flyfunboarding.git
   ```

9. Copy keys from old droplet (RSA key pairs for airline signatures):
   ```bash
   # From old droplet:
   scp /path/to/keys/*.pem /path/to/keys/*.pub brice@161.35.35.15:~/flyfunboarding/keys/
   ```

10. Copy certs from old droplet (Apple Wallet PKPass signing):
    ```bash
    # From old droplet:
    scp /path/to/certs/Certificates.p12 /path/to/certs/AppleWWDRCA.pem \
        brice@161.35.35.15:~/flyfunboarding/certs/
    ```

Note: `images/` directory is tracked in git and will be present after clone.
Only `keys/` (gitignored) and `certs/` (not tracked) need manual copying.

### Phase 6: New Droplet - Configure & Start Container

11. Create `.env` in `~/flyfunboarding/server/`:
    ```bash
    cat > ~/flyfunboarding/server/.env << 'EOF'
    DB_USER=flyfunboarding
    DB_PASSWORD=<secure_password>
    DB_NAME=flyfunboarding
    SECRET=<same_secret_as_old_server>
    USE_PUBLIC_KEY_SIGNATURE=true
    CERTIFICATE_PASSWORD=<p12_password>
    DEBUG=false
    LOG_LEVEL=INFO
    CORS_ORIGINS=*
    EOF
    ```
    **Important:** `SECRET` must match the old server so existing ticket signatures remain valid.

12. Build and start:
    ```bash
    cd ~/flyfunboarding/server
    sudo docker compose -f docker-compose.prod.yml up -d --build
    ```

13. Verify container is healthy:
    ```bash
    sudo docker ps
    curl http://localhost:8001/health
    curl http://localhost:8001/api
    ```

### Phase 7: New Droplet - Caddy Config

14. Pull and sync the Caddy config:
    ```bash
    cd ~/digitalocean/flyfun.aero
    git pull
    syncfiles push --execute
    sudo systemctl reload caddy
    ```

### Phase 8: Verify via HTTPS

15. Test public endpoints:
    ```bash
    curl https://boarding.flyfun.aero/health
    curl https://boarding.flyfun.aero/api
    curl https://boarding.flyfun.aero/api/v1/status
    ```

### Phase 9: iOS App Test

16. On Mac, build the iOS app with the updated `secrets.json` and test all flows:
    - Airline registration/login
    - Aircraft CRUD
    - Flight planning
    - Passenger management
    - Ticket issuance
    - Boarding pass generation (PKPass)
    - Boarding pass web page (pages endpoint)
    - QR code signature verification

## Parallel Operation

Both servers run simultaneously during testing:

| Server | URL | Stack |
|--------|-----|-------|
| Old (production) | `flyfun.aero/boarding/api/` | PHP on ro-z.net |
| New (staging) | `boarding.flyfun.aero/api/v1/` | Python/FastAPI on flyfun.aero |

Same database content, same keys, same SECRET - both servers handle the same data.
The iOS app switches between them by changing `flyfun_base_url` in `secrets.json`.

## Post-Migration (future)

Once the new server is validated:

1. Update `secrets.json` in the production iOS app build to use `boarding.flyfun.aero`
2. Submit app update to App Store (or use TestFlight for staged rollout)
3. Monitor for issues
4. Disable the old PHP server on ro-z.net
5. Optionally redirect `flyfun.aero/boarding/api/` to `boarding.flyfun.aero/api/v1/`

## Key Files Reference

| File | Purpose |
|------|---------|
| `server/app/config.py` | `API_VERSION` setting, `api_prefix` property |
| `server/app/main.py` | Route registration using `API` prefix variable |
| `server/docker-compose.prod.yml` | Production container config (port 8001) |
| `server/app/services/signature_service.py` | RSA key management (mirrors PHP `Signature.php`) |
| `app/flyfunboarding/Source/Secrets.swift` | URL construction from config keys |
| `flyfun.aero/etc/caddy/sites-enabled/boarding.flyfun.aero.caddy` | Caddy reverse proxy config |
| `shared-infra/init-scripts/01-create-flyfunboarding-db.sql` | DB init (first-run only) |
