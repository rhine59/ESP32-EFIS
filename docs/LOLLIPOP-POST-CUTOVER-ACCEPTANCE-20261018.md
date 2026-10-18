# Lollipop production post-cutover acceptance — 18 October 2026

## Passed

- All eight running containers have expected explicit `lollipop-*` names and separate Compose project labels: account (API and DB), OTA (download and admin), licence, web simulator, local gateway, and the pre-existing RedOne simulator.
- Docker health is healthy for OTA download/admin, account PostgreSQL, licence, and web simulator. Account API and local gateway do not have configured Docker health checks but remain running.
- NAS loopback HTTP 200: account `/healthz`, `/login`, `/register`, `/forgot-password`, `/reset-password?token=invalid-test`; licence `/health`; simulator `/api/state` and `/`; OTA admin `/healthz`; OTA `/efis/manifest.json` and `/efis/manifest.signed.json`.
- External volumes and mounts retained, including account PostgreSQL, licence keys, simulator state, published firmware and OTA signing key. Web simulator is on both shared `efis-license` and `ota-server_default` networks.
- Mac local test suite: 60 boot/recovery lab tests pass; Compose container naming validator passes.
- Existing legacy containers retained stopped for rollback. No physical EFIS firmware operation performed.

## Not verified or not provisioned

- Actual authenticated user login, password-reset email delivery and consumption, email verification, phone-app login, external reverse-proxy routing, public TLS certificates, physical EFIS OTA signature verification, and LAN gateway discovery require real credentials/devices or live end-to-end exercises. A GET of a reset page is **not** a password reset test.
- `license-signer` and `support-service` were not deployed before the migration and lack production private keys/tokens/configuration. Do not create fake credentials or start support with its default placeholder password. These remain explicitly unprovisioned, not failed migrations.
- The existing live checkout has damaged Git HEAD; use the clean staging checkout as deployment source. Keep backup, volumes, signing keys, and legacy containers until functional acceptance.

## Deployment disposition

**PASS** for isolation of all previously running Docker services, health endpoints, data continuity and rollback retention. **PENDING** for user authentication/email and device/external network end-to-end acceptance, and provisioning of two optional inactive stacks.
