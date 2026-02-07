# Fly Fun Boarding

> iOS + FastAPI app for issuing boarding passes with Apple Wallet PKPass generation

## Architecture Docs

### server-architecture
FastAPI server: layers (config → database → repository → models → routers → services), auth system, PHP-compatible JSON serialization.
Key exports: `app`, `settings`, `BaseJsonModel`, `BaseRepository`
→ Full doc: server-architecture.md

### deployment
Infrastructure on DigitalOcean: Docker, Caddy reverse proxy, certificate handling, environment setup, and hard-won deployment gotchas.
→ Full doc: deployment.md

### ios-server-contract
API contract between iOS app and server: URL construction, auth patterns, JSON field naming, date formats, and boarding pass sharing.
→ Full doc: ios-server-contract.md

## Historical (Migration)

### droplet-migration-plan
Step-by-step migration from PHP/ro-z.net to Python/flyfun.aero. Completed Feb 2026.
→ Full doc: droplet-migration-plan.md

### MIGRATION_DESIGN
Original PHP-to-Python migration design. Superseded by actual implementation.
→ Full doc: MIGRATION_DESIGN.md

### IMPLEMENTATION_PLAN
Phase-by-phase implementation checklist. All phases complete.
→ Full doc: IMPLEMENTATION_PLAN.md
