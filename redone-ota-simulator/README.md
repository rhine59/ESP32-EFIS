# RedOne network OTA simulator

**Simulation only:** separate from production OTA service. It rejects ESP images (0xE9 header), only accepts the known 4096-byte simulator B fixture with an exact SHA-256 digest. It never writes firmware or connects to an ESP32.

Run: `docker compose -f redone-ota-simulator/compose.yml up -d --build`.
By default the API listens only on the Docker host loopback at `127.0.0.1:8193`; it is not exposed to the public Internet or directly reachable from an iPhone. Use an authenticated LAN-only proxy or controlled development tunnel when adding iOS connectivity. Never expose it on the production OTA hostname.

API: `GET /health`, `GET /api/status`, `GET /api/fixtures`, `GET /api/fixtures/B/download`; `POST /api/transfer/reset`, `POST /api/transfer/chunk` with `X-Offset` byte offset (supports resume), `POST /api/verify`, `POST /api/activate`, `POST /api/rollback`, `POST /api/reset`.

State is in-memory and resets on container restart. This is a test endpoint, not a secure firmware update service; keep it isolated and do not treat successful simulator validation as hardware validation.

## Synology public simulator (October 2026)

The test-only service is exposed through a dedicated HTTPS reverse proxy at
`https://lollipop.granvillehouse.synology.me:8449` with a valid TLS certificate.
The Docker port remains bound to `127.0.0.1:8193`. All `/api/*` requests require
`Authorization: Bearer <token>`; the token is stored in a private `.env` on
Synology and must never be committed to Git or embedded in the iOS app.
`/health` is intentionally unauthenticated and exposes only simulator health.

**Acceptance record:** An iPhone user confirmed successful connection,
fixture download, transfer, verification, activation of B and rollback to A.
An independent authenticated API read after the test reported active partition
A, no staged partition, 4096 received bytes, `verified=false` and
`rollback_available=false`. This confirms the final state, not independent
observation of each intermediate step.

**Recovery tests:** `cd redone-ota-simulator && python3 -m unittest -q test_server`
checks normal deployment and rollback, corrupt-image rejection, incorrect
chunk offsets, authentication enforcement, interrupted transfer/resume and
resetting a partial transfer. The simulator is in-memory: restarting its
container discards pending transfer state.

**Limitations:** A public HTTPS endpoint increases attack surface. Restrict
and monitor access, use a strong secret and rotate it if exposed. The simulator
has no rate limiter or persistent audit trail yet. None of these results
constitute validation of real ESP32 firmware flashing or boot recovery.
