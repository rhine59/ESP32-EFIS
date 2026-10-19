# RedOne: use existing ESP32-S3 attached to Mac — 19 October 2026

**User hardware constraint:** use the existing ESP32-S3 on `/dev/cu.usbmodem101`; do not make a second ESP32 board or external secure element a prerequisite for continuing development. The port was present on the Mac on 19 October 2026; port presence alone does not prove firmware identity or health.

## Approved non-destructive work on the existing board

1. Collect serial output without changing boot selection, resetting the board or writing flash, when the port is available and not held by another process.
2. Use the existing RedOne Wi-Fi `/status` endpoint with provisioned credentials, and treat `/boot-health` HTTP 404 as a missing firmware feature, not a passing health check.
3. Exercise signed-release and build-floor checks off-device, compile updated firmware and run host simulations; compare read-only partition inventory against existing backups.
4. Keep the current known-good recovery image, `ota_0` application and OTA selection metadata intact.

## Built-in ESP32-S3 security architecture

ESP32-S3 secure boot, flash encryption and hardware anti-rollback eFuses are available in principle, but currently disabled on this board. An eFuse `secure_version` is an irreversible, limited security-epoch mechanism, **not** a per-release build counter. Do not provision it during ordinary development. There is currently no installed, hardware-backed per-build floor; missing trusted state must fail closed. A separately authenticated secure element is an optional future hardware revision, not a dependency for read-only diagnostics, iPhone preflight or simulated OTA policy work.

## Required approval boundary

No generic `idf.py flash`, factory recovery write, OTA B write, boot-selection change, eFuse burn, flash encryption or secure boot provisioning. Any physical firmware write requires a separate, explicitly scoped approval and evidence-based readiness assessment; a generic "go" does not authorise it. Physical Partition B remains **NO-GO**.
