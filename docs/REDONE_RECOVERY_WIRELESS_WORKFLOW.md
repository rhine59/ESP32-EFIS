# RedOne recovery — Lollipop-first wireless maintenance

## Approved implementation sequence

1. Recovery Wi-Fi commissioning and authenticated maintenance API.
2. Firmware transfer to the inactive A/B slot, device-side Ed25519 verification, SHA-256 and hardware/version checks.
3. Hardware diagnostics and report collection.
4. Controlled activation, health confirmation and rollback.
5. Physical recovery entry and fault-injection validation.

## Lollipop user experience

Lollipop is the primary maintenance console. A normal session joins `RedOne_<MAC>` recovery Wi-Fi, authenticates with a device-bound commissioning credential, identifies the recovery firmware and presents the diagnostics dashboard. It can run all ten hardware test categories, show per-test PASS/WARN/FAIL/SKIP, measured values, explanations and timestamps, and export the signed or integrity-protected report. The recovery device owns the authoritative result; the phone never fabricates a successful test. Tests requiring operator action display explicit prompts and confirmations. Tests requiring unavailable external devices report SKIP.

## API contract (proposed; not yet implemented)

- `GET /api/recovery/status` — recovery version, hardware ID, available slots, authenticated session status.
- `POST /api/recovery/diagnostics/runs` — initiate a diagnostic run (session authenticated, rate limited).
- `GET /api/recovery/diagnostics/runs/{id}` — run progress and per-test results.
- `GET /api/recovery/diagnostics/runs/{id}/report` — complete exportable JSON report.
- `POST /api/recovery/firmware/uploads` — begin verified upload into inactive slot only.
- `GET /api/recovery/firmware/slots` — inspect installed image state.
- `POST /api/recovery/firmware/activate` — authenticated, explicitly confirmed activation.

The current Lollipop `GET /api/recovery/diagnostics` is a read-only integration scaffold. It must be adapted to the authenticated run/report API when the server exists.

## Security and resilience gates

Never expose unauthenticated firmware, partition selection or hardware-control endpoints. Use per-device commissioning credentials and replay-resistant sessions, not a shared bench password. Recovery must independently validate signed firmware; no client-supplied flag may bypass verification. Maintain last-known-good slot and protect factory recovery from normal OTA. USB remains a service fallback if the Wi-Fi radio or credentials fail. A hardware-level recovery-entry path is mandatory if both normal applications fail. Logs must not expose credentials or sensitive identifiers. Use transport protection or an equivalent authenticated, integrity-protected protocol appropriate to ESP32 SoftAP; Wi-Fi WPA alone is not authorization.

## Current implementation status

- Separate factory recovery firmware: implemented, builds.
- USB diagnostics JSON: implemented with real memory/flash checks, NVS presence warning, unsupported tests SKIP.
- Lollipop per-test results view: implemented, builds; not yet connected to a running wireless recovery server.
- Recovery Wi-Fi, authenticated API, report retrieval/export, hardware drivers, firmware transfer, activation/rollback, and physical entry: **not yet implemented or hardware validated**.
