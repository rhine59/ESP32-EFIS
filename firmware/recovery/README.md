# RedOne minimal recovery (development)

This is a **separate ESP-IDF application** for the `recovery` / `factory` partition in `../partitions.csv`. It provides a USB serial maintenance console, identifies both normal application slots, and permits deliberate selection of an existing valid application. It does not display flight information, run a Wi-Fi access point, or accept network firmware uploads.

Build with `source scripts/efis-env.sh` from repository root, then `cd firmware/recovery && idf.py -B build build`. The generated `redone_recovery.bin` must be provisioned at **0x20000** only as part of a validated, explicit three-image factory flash procedure. Do not use `idf.py flash` to provision this standalone project: its default app offset is not necessarily the recovery partition offset. Do not use this image in the phone OTA path.

**Limitations:** Recovery-entry boot selection, authenticated USB reflash, and recovery from two corrupted application slots are not implemented or hardware tested. A USB serial console is not a substitute for a complete independent reflash mechanism. `bootA`/`bootB` only select images whose application description can be read; the ESP-IDF bootloader must still validate them. Production access controls and secure boot/flash encryption policy require design review.

## Hardware diagnostic suite (first implementation)

Send `test` over the recovery USB serial console to receive a versioned JSON report containing ten test categories. Each reports `PASS`, `WARN`, `FAIL` or `SKIP` with a reason. Flash size and heap availability are measured; NVS partition presence is checked non-destructively and reported WARN because no integrity/write verification is performed. All tests requiring unimplemented drivers, calibrated ADC channels, external sensors, operator interaction or a Wi-Fi stack are SKIP, not PASS. Do not mistake this report for completed hardware acceptance testing.

Lollipop's Devices → Recovery hardware diagnostics screen understands this schema and shows per-test results. The proposed `GET /api/recovery/diagnostics` is **not served by this USB-only recovery firmware**; the app reports unavailable until a properly authenticated recovery Wi-Fi service is implemented. Never expose an unauthenticated maintenance API on an aircraft device. The screen is currently an integration scaffold, not a working wireless connection.
