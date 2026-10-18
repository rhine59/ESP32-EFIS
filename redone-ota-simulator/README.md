# RedOne network OTA simulator

**Simulation only:** separate from production OTA service. It rejects ESP images (0xE9 header), only accepts the known 4096-byte simulator B fixture with an exact SHA-256 digest. It never writes firmware or connects to an ESP32.

Run: `docker compose -f redone-ota-simulator/compose.yml up -d --build`.
By default the API listens only on the Docker host loopback at `127.0.0.1:8193`; it is not exposed to the public Internet or directly reachable from an iPhone. Use an authenticated LAN-only proxy or controlled development tunnel when adding iOS connectivity. Never expose it on the production OTA hostname.

API: `GET /health`, `GET /api/status`, `GET /api/fixtures`, `GET /api/fixtures/B/download`; `POST /api/transfer/reset`, `POST /api/transfer/chunk` with `X-Offset` byte offset (supports resume), `POST /api/verify`, `POST /api/activate`, `POST /api/rollback`, `POST /api/reset`.

State is in-memory and resets on container restart. This is a test endpoint, not a secure firmware update service; keep it isolated and do not treat successful simulator validation as hardware validation.
