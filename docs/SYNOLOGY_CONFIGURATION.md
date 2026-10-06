# Synology NAS configuration

Status: development configuration validated 6 October 2026. Repository: `ESP32-EFIS`; Docker Compose project prefix is permanently `esp32-efis`.

## Host layout

Clone/copy the authoritative Git tree to `/volume1/docker/ESP32-EFIS`. Docker is normally `/usr/local/bin/docker` on DSM. Rebuild scripts detect normal PATH first and then this DSM path. Do not rename individual containers: Compose generates names under the `esp32-efis` project prefix.

The account stack consists of `esp32-efis-account-1` and `esp32-efis-db-1`. PostgreSQL data is persisted in the explicitly named volume `esp32-efis_efis-account-db`; do not delete this volume during rebuilds. The account HTTP listener is deliberately loopback-only at `127.0.0.1:8091`.

## Account runtime configuration

Create `/volume1/docker/ESP32-EFIS/account-service/.env` from `.env.example`, mode 600. Required values are `POSTGRES_DB`, `POSTGRES_USER`, a long random `POSTGRES_PASSWORD`, a long random `SESSION_SECRET`, `PUBLIC_BASE_URL`, and SMTP settings (`SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_FROM`, `SMTP_SSL`). `EMAIL_VERIFY_MINUTES=30` is the current verification lifetime. `ENABLE_DEV_RESET=1` is permitted only on the controlled development system and MUST be 0 in production. Real passwords/secrets never belong in Git.

Current development public origin is `https://granvillehouse.synology.me:8450`. DSM Reverse Proxy terminates TLS on HTTPS port 8450 and forwards HTTP to `127.0.0.1:8091`. The router forwards external TCP 8450 to the NAS for this development deployment. Do not expose 8091. Production should use a canonical HTTPS hostname on port 443 rather than requiring a customer router rule.

## Email and mobile authentication

SMTP sends verification, password-reset and reauthentication mail. Initial verified-account QR login exchanges a five-minute single-use challenge for a 90-day mobile session. Only SHA-256 hashes of challenges and session tokens are stored by the service. iOS stores the raw session in Keychain; Android stores an AES-GCM encrypted session using an Android Keystore key. `/v1/me` validates a session and `/v1/logout` revokes it. At hard 90-day expiry the app requests a fresh single-use email login challenge; the user can scan its QR or use the same-phone deep link.

Development deep links currently use `efisservice://login?code=...`. Production should migrate to associated Universal Links / Android App Links to prevent custom-scheme interception.

## Rebuild and verification

From the repository root on the NAS run `scripts/rebuild-synology.sh /volume1/docker/ESP32-EFIS`. It validates and rebuilds account, licence, web simulator and local gateway stacks without `--remove-orphans`. For account-only changes use `scripts/build-account-service.sh`. After deployment require account `/healthz` to return HTTP 200 locally and through the public TLS route. Back up the PostgreSQL volume before destructive DSM/storage maintenance.

## DSM/network checklist

- Docker/Container Manager installed and able to pull required base images.
- Repository at `/volume1/docker/ESP32-EFIS`.
- Account `.env` present, secret and not committed.
- Persistent database volume `esp32-efis_efis-account-db` retained.
- DSM reverse proxy: HTTPS 8450 -> HTTP `127.0.0.1:8091` for development.
- Valid TLS certificate assigned to the development hostname.
- External TCP 8450 forwarded only for the present development environment.
- SMTP outbound access to the configured provider.
- NAS clock/NTP correct; token expiry depends on accurate UTC time.
- `ENABLE_DEV_RESET=0` before production/public release.
- Never expose PostgreSQL, private licence signer, or loopback application ports directly.
