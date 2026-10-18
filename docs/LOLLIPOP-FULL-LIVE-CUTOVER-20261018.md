# Lollipop Synology Compose isolation: production migration report — 18 October 2026

## Running services migrated

All **previously running** production service groups have been migrated to isolated Compose projects, except the already-isolated `lollipop-redone-simulator`, which was left running. The migrated service names are `lollipop-efis-ota`, `lollipop-efis-ota-admin`, `lollipop-account`, `lollipop-account-db`, `lollipop-efis-license-service`, `lollipop-efis-web-simulator`, and `lollipop-redone-local-license-gateway`. Original containers were stopped and retained under `*-legacy` names where applicable.

## Verified

- OTA and OTA admin: Docker health healthy; OTA `/efis/manifest.json` and `/efis/manifest.signed.json` HTTP 200; original firmware bind directory and private signing key preserved.
- Account: `/healthz` HTTP 200; PostgreSQL healthy and still using original `esp32-efis_efis-account-db` volume, with one existing user record; backup restored in a separate isolated container before migration.
- Licensing: `/health` HTTP 200 and Docker healthy; retained `esp32-efis_license_keys` volume.
- Web simulator: `/api/state` HTTP 200 and Docker healthy; retained `esp32-efis_efis_sim_state` volume; both `efis-license` and `ota-server_default` networks connected.
- Local licence gateway: host-network container started and remained running; no explicit Docker healthcheck or external device-level validation.
- RedOne simulator: pre-existing isolated project remained running without changes.

## Not deployed, not falsely counted as migrated

The `lollipop-license-signer` and `lollipop-support` stacks were **not running before migration**. Their required production secrets/configuration are not present in either staging or the previous live checkout: no signer private key or signer `.env`, no support `.env`. Support Compose has insecure placeholder database password and no configured `DATABASE_URL`/`ADMIN_TOKEN`. These are unprovisioned features, **not** safe to start with default credentials. They require deliberate secret provisioning and acceptance tests before activation.

## Outstanding acceptance

A real authenticated account login, email verification, password reset, full external reverse-proxy access, firmware signature validation by a physical device, and gateway LAN discovery have not been exercised. Existing rollback containers and persistent volumes must be retained. The original live Git checkout has a damaged HEAD and must not be reset or overwritten; the clean staging checkout is the deployable source. The physical EFIS board was not modified.
