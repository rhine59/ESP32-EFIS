# ESP32 EFIS — Project activity and validation status

**Status date:** 16 September 2026

This is the project-level validation record. The project remains experimental **supplementary/non-primary**. Missing/invalid/stale real data fails obviously; synthetic data is never an automatic fallback. Build/simulation success is not physical validation.

## Current development gate

Physical hardware activity remains paused until prototype hardware is available. Active software work includes QEMU regression, Swift parity, documentation, pure estimator/calculation tests, static safety review, and the OTA server/user-flow work described below.

## Validation vocabulary

| Status | Meaning |
|---|---|
| **ACCEPTED — QEMU** | Deterministic firmware/emulator behaviour reviewed at 480×480. |
| **SYNCED — SWIFT** | Swift represents accepted behaviour/scenario; not authoritative pixel renderer. |
| **COMPILE-VALIDATED** | ESP32 target compiled; no physical operation implied. |
| **IMPLEMENTED — UNVALIDATED** | Code exists; required runtime/physical validation not performed. |
| **DESIGNED / NOT IMPLEMENTED** | Architecture documented but operational target code absent. |
| **PLANNED / PENDING HARDWARE** | Requires physical hardware. |
| **PARKED** | Intentionally held. |

## Completed / current activities

| Function | State | Validation |
|---|---|---|
| Safety model | supplementary/non-primary; explicit simulation; fail-obvious validity | **DOCUMENTED** |
| QEMU RGB565 backend | native 480×480 virtual display | **ACCEPTED — QEMU** |
| Horizon | accepted pitch/bank geometry, ladder, bank scale, `ATT FAIL` | **ACCEPTED — QEMU; SYNCED — SWIFT** |
| Altimeter | three pointers, digital altitude, >10k hatch, Kollsman, `ALT FAIL` | **ACCEPTED — QEMU; SYNCED — SWIFT** |
| Compass | rotating card, wrap, heading bug, `HEADING FAIL` | **ACCEPTED — QEMU; SYNCED — SWIFT** |
| QNH/storage | 950–1050 hPa, 1 hPa, NVS-backed setting | **SOFTWARE/QEMU ACCEPTED; ENCODER PENDING** |
| Pressure calculation | validated calculation path | **SIMULATION-TESTED; BMP585 INPUT PENDING** |
| BMI088 SPI/diagnostics | engineering-unit acquisition + commissioning log path | **COMPILE-VALIDATED; HARDWARE PENDING** |
| Attitude estimator | gyro/gravity complementary estimator, plausibility/staleness gates | **COMPILE-VALIDATED; PHYSICAL TUNING PENDING** |
| BMI088 live display gate | withheld until physical axes/signs verified | **IMPLEMENTED SAFETY GATE** |
| Swift instrument simulator | adaptive instruments/manual/AUTO/failure/acceptance scenarios | **SOFTWARE OPERATIONAL; PARITY MAINTAINED** |
| Phone/network simulator | hotspot credentials, HTTPS manifest config and staged connectivity UI | **IMPLEMENTED — SWIFT; REAL ESP32 NETWORK PENDING** |
| OTA user simulator | auto-download preference, manual Download, verified Ready, explicit `ACTIVATE & REBOOT`, success/rollback | **IMPLEMENTED — SWIFT; PHYSICAL OTA PENDING** |
| OTA Docker origin | loopback nginx read-only public-origin backend | **IMPLEMENTED — SYNLOGY DEPLOYMENT UNVALIDATED** |
| OTA Docker admin | private dashboard, staged releases, per-release metadata/hash, explicit Publish/republish/delete | **IMPLEMENTED — SYNLOGY DEPLOYMENT UNVALIDATED** |
| OTA CLI staging helper | versioned binary copy + SHA-256 + metadata; cannot publish | **IMPLEMENTED — RUNTIME UNVALIDATED** |
| OTA A/B ESP32 client | dual-slot/write/boot/self-test/rollback design | **DESIGNED / NOT IMPLEMENTED ON ESP32** |
| OTA security | HTTPS + signed-image design; Secure Boot/flash encryption later | **DESIGNED / LATER HARDENING** |
| Enclosure CAD | development case/carriers/fit gauge | **DESIGNED; PHYSICAL FIT PENDING** |
| Carrier PCB | architecture/pins | **PARKED** |

## Definitive OTA policy

**Stage → Publish → Download → Activate.** Admin upload/stage never publishes. Publish changes the public manifest. EFIS auto-download may download/verify only in maintenance context. **Activation/reboot is always explicit.** First boot must self-test and either mark the candidate known-good or rollback. See `OTA_IMAGE_ADMIN.md`, `OTA_USER_SCENARIO.md`, `PHONE_NETWORK_AND_PUBLIC_OTA.md`, `REMOTE_UPDATES.md` and `../ota-server/README.md`.

## Accepted emulator sequences

Horizon: level, ±10/±20 pitch, ±30/±60 bank, combined attitude, failure/recovery. Altimeter: representative 0–12,500 ft values, sweep, failure/recovery and QNH exercises. Compass: cardinal/intercardinal headings, 350→010 wrap, rotation, failure/recovery with deterministic 060° bug. Full details remain in `SIMULATION.md`.

## Remaining work

| Function | Work / validation required | Status |
|---|---|---|
| Swift parity | keep instrument/network/OTA scenarios aligned with firmware policy | **ACTIVE SOFTWARE TASK** |
| OTA server deployment | build/run both containers on Synology; private admin access; public TLS/DNS/reverse-proxy external test | **IMPLEMENTED / DEPLOYMENT PENDING** |
| OTA ESP32 Phase 1 | freeze A/B partition sizes; manifest/parser/state machine; persisted auto-download policy | **DESIGNED / SOFTWARE CANDIDATE** |
| OTA ESP32 Phase 2 | maintenance Wi-Fi + HTTPS writer + explicit activation + boot confirmation | **PENDING HARDWARE** |
| OTA interruption/rollback | A↔B, Wi-Fi/power loss, corrupt image, crash/self-test rollback, NVS compatibility, USB recovery | **PENDING HARDWARE** |
| OTA security | signed releases/verification; later Secure Boot/flash encryption; eFuse anti-rollback deferred | **DESIGNED / LATER HARDENING** |
| BMI088 axes/bias/tuning/live connection | physical orientation, stationary/dynamic data, estimator tuning | **PENDING HARDWARE** |
| BMP585/static/live altitude | physical driver, pressure validation, plumbing, failure/staleness | **PENDING HARDWARE** |
| RM3100/calibration/heading | acquisition, hard/soft iron, installation alignment, tilt compensation | **PENDING HARDWARE** |
| MCP23008/PEC09/NVS | physical interaction/persistence | **PENDING HARDWARE** |
| LCD/backlight/PSRAM/power | physical bring-up, stress, thermal/electrical checks | **PENDING HARDWARE** |
| Enclosure/EMI/vibration/thermal | physical and powered installation tests | **PENDING HARDWARE** |
| Aircraft ground/airborne comparison | only after all preceding gates | **FUTURE / BLOCKED** |
| Carrier PCB | resume after prototype interfaces proven | **PARKED** |

## Hardware-resumption gate

Inventory/inspection → ESP32/display/power → BMI088 axis mapping → estimator validation → BMP585/static → encoder → RM3100/calibration → integrated failure/staleness → **real OTA download/activation/interruption/rollback** → enclosure/thermal/vibration → aircraft ground testing. Never infer airborne readiness from compilation, Docker, Swift or QEMU results.

## Documentation rule

Every functional change updates relevant code documentation/project status in the same stage. Validation statements must identify the layer: compile, QEMU, Swift, Docker runtime, electronics bench, physical fixture, aircraft ground or airborne.
