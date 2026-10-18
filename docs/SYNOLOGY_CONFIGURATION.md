# Synology NAS configuration

**Current deployment status (18 October 2026):** The live Synology container migration is complete. The authoritative clean deployment checkout is `/volume1/docker/ESP32-EFIS-staging`; the older `/volume1/docker/ESP32-EFIS` checkout has a damaged Git HEAD and must not be reset or used for `git pull`. Some persistent resources intentionally remain under the older path. All currently deployed Compose projects use explicit `lollipop-*` container names, not the obsolete `esp32-efis-*` naming convention. See `LOLLIPOP-POST-CUTOVER-ACCEPTANCE-20261018.md` and `LOLLIPOP-COMPOSE-PROJECT-ISOLATION.md`.

## Current host layout

Docker is `/usr/local/bin/docker` and Git is `/usr/local/git/bin/git` on this NAS. The account stack is `lollipop-account` and `lollipop-account-db` (project `lollipop-account`); the original PostgreSQL volume remains `esp32-efis_efis-account-db`. Account HTTP is bound to `127.0.0.1:8091`. OTA firmware files remain under `/volume1/docker/ESP32-EFIS/ota-server/public` by an explicit private `OTA_PUBLIC_DIR` override. The OTA admin signing key remains outside Git. Preserve both paths and all external volumes during maintenance.

The active service inventory and rebuild/rollback instructions are in `LOLLIPOP-CONTAINER-OPERATIONS-GUIDE.md`. Do not run `docker compose down -v`, use the damaged checkout for Git operations, or start two PostgreSQL instances against the same volume.

## Account runtime configuration

Maintain `/volume1/docker/ESP32-EFIS-staging/account-service/.env` from `.env.example`, mode 600. Required values are `POSTGRES_DB`, `POSTGRES_USER`, a long random `POSTGRES_PASSWORD`, a long random `SESSION_SECRET`, `PUBLIC_BASE_URL`, and SMTP settings (`SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_FROM`, `SMTP_SSL`). `EMAIL_VERIFY_MINUTES=30` is the current verification lifetime. `ENABLE_DEV_RESET=1` is permitted only on the controlled development system and MUST be 0 in production. Real passwords/secrets never belong in Git.

Current development public origin is `https://granvillehouse.synology.me:8450`. DSM Reverse Proxy terminates TLS on HTTPS port 8450 and forwards HTTP to `127.0.0.1:8091`. The router forwards external TCP 8450 to the NAS for this development deployment. Do not expose 8091. Production should use a canonical HTTPS hostname on port 443 rather than requiring a customer router rule.

## Email and mobile authentication

SMTP sends verification, password-reset and reauthentication mail. Initial verified-account QR login exchanges a five-minute single-use challenge for a 90-day mobile session. Only SHA-256 hashes of challenges and session tokens are stored by the service. iOS stores the raw session in Keychain; Android stores an AES-GCM encrypted session using an Android Keystore key. `/v1/me` validates a session and `/v1/logout` revokes it. At hard 90-day expiry the app requests a fresh single-use email login challenge; the user can scan its QR or use the same-phone deep link.

Development deep links currently use `efisservice://login?code=...`. Production should migrate to associated Universal Links / Android App Links to prevent custom-scheme interception.

## Rebuild and verification

For deployed stacks, use the clean staging checkout and the per-stack commands in `LOLLIPOP-CONTAINER-OPERATIONS-GUIDE.md`. Historical rebuild scripts may encode obsolete paths or project names and must be reviewed before execution. After deployment require account `/healthz` to return HTTP 200 locally and through the public TLS route. Back up the PostgreSQL volume before destructive DSM/storage maintenance.

## DSM/network checklist

- Docker/Container Manager installed and able to pull required base images.
- Clean deployment checkout at `/volume1/docker/ESP32-EFIS-staging`; original firmware directory retained.
- Account `.env` present, secret and not committed.
- Persistent database volume `esp32-efis_efis-account-db` retained.
- DSM reverse proxy: HTTPS 8450 -> HTTP `127.0.0.1:8091` for development.
- Valid TLS certificate assigned to the development hostname.
- External TCP 8450 forwarded only for the present development environment.
- SMTP outbound access to the configured provider.
- NAS clock/NTP correct; token expiry depends on accurate UTC time.
- `ENABLE_DEV_RESET=0` before production/public release.
- Never expose PostgreSQL, private licence signer, or loopback application ports directly.
