# RedOne simulator-only deployment fixtures

These two deterministic payloads are **not ESP32 firmware** and **must never be flashed to physical hardware**. They are intentionally invalid as ESP32 application images. Use them to test the simulated OTA sequence: discover, download, verify SHA-256, stage, activate, confirm the active version changed, and rollback to A.

| Fixture | Version | Bytes | SHA-256 |
|---|---|---:|---|
| `redone-0.1.0-sim-A.bin` | `0.1.0-sim-A` | 4096 | `aa0621fe57d4b5d6831c963c0e5c52b693493e9d7e6585797826bc80c6a4c06d` |
| `redone-0.1.1-sim-B.bin` | `0.1.1-sim-B` | 4096 | `f9acbce913f72c1c235a1fb11e7eb766737bb4a12765132153df2646aaee97df` |

Regenerate with `sh ota-server/scripts/make-simulator-test-image.sh VERSION OUTPUT` from the repository root. Validate with `shasum -a 256 ota-server/test-fixtures/redone-ota/*.bin`.

**Important:** These are transport fixtures for the simulator harness, not signed production releases. The iOS Update EFIS screen enforces trusted signed manifests and flashable firmware checks; it should reject these binaries rather than offer them for real-device deployment. Do not publish these to the production RedOne firmware feed or weaken iOS verification to accept them. Use the isolated OTA admin harness or a dedicated simulation-only publisher/feed for end-to-end deployment testing.
