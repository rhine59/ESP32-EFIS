# RedOne minimal recovery (development)

This is a **separate ESP-IDF application** for the `recovery` / `factory` partition in `../partitions.csv`. It provides a USB serial maintenance console, identifies both normal application slots, and permits deliberate selection of an existing valid application. It does not display flight information, run a Wi-Fi access point, or accept network firmware uploads.

Build with `source scripts/efis-env.sh` from repository root, then `cd firmware/recovery && idf.py -B build build`. The generated `redone_recovery.bin` must be provisioned at **0x20000** only as part of a validated, explicit three-image factory flash procedure. Do not use `idf.py flash` to provision this standalone project: its default app offset is not necessarily the recovery partition offset. Do not use this image in the phone OTA path.

**Limitations:** Recovery-entry boot selection, authenticated USB reflash, and recovery from two corrupted application slots are not implemented or hardware tested. A USB serial console is not a substitute for a complete independent reflash mechanism. `bootA`/`bootB` only select images whose application description can be read; the ESP-IDF bootloader must still validate them. Production access controls and secure boot/flash encryption policy require design review.

## Hardware diagnostic suite (first implementation)

Send `test` over the recovery USB serial console to receive a versioned JSON report containing ten test categories. Each reports `PASS`, `WARN`, `FAIL` or `SKIP` with a reason. Flash size and heap availability are measured; NVS partition presence is checked non-destructively and reported WARN because no integrity/write verification is performed. All tests requiring unimplemented drivers, calibrated ADC channels, external sensors, operator interaction or a Wi-Fi stack are SKIP, not PASS. Do not mistake this report for completed hardware acceptance testing.

Lollipop's Devices → Recovery hardware diagnostics screen understands this schema and shows per-test results. The proposed `GET /api/recovery/diagnostics` is **not served by this USB-only recovery firmware**; the app reports unavailable until a properly authenticated recovery Wi-Fi service is implemented. Never expose an unauthenticated maintenance API on an aircraft device. The screen is currently an integration scaffold, not a working wireless connection.

## Wi-Fi diagnostics bench integration (not production secure)

The recovery image now contains a **read-only** SoftAP diagnostics endpoint: `GET http://192.168.4.1/api/recovery/diagnostics`. It accepts the `X-RedOne-Recovery-Token` header and returns the same JSON as the USB `test` command. Lollipop's Devices → Recovery hardware diagnostics view can retrieve and display it.

The AP is **fail-closed**: Wi-Fi does not start unless the existing NVS partition contains namespace `recovery` with two string keys: `ap_password` (16–63 characters) and `api_token` (32–64 characters). Provision unique random values using a trusted factory/service NVS provisioning workflow; never hard-code or commit device secrets. A factory provisioning utility, QR credential exchange, automatic phone joining, and persistent Keychain storage have **not** been built yet. The AP uses `RedOne_<12-hex-digit Wi-Fi MAC>`, WPA2-PSK, channel 6, and one client.

**Security restriction:** The current HTTP request carries a bearer token in plaintext at the application layer. WPA2 protects over-the-air traffic, but this is not an independently secure session. This is suitable only for physically controlled bench integration, not operational deployment. Before production, add device-authenticated encrypted transport, session expiry and replay protection, secure credential rotation, and a factory provisioning procedure. Do not enable any firmware-upload or activation endpoint until these controls and independent image signature verification are in place.

The endpoint reads the current diagnostics snapshot; it does not initiate interactive tests, stream progress, or export historical reports. No physical hardware or iPhone-to-RedOne end-to-end connection has been validated yet.
