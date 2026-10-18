# RedOne full-flash backup performance and connectivity diagnostics

**18 October 2026. Physical factory boot remains NO-GO.**

A non-mutating 64 KiB test read at 921600 baud completed in 0.8 seconds of transfer (reported 647.5 kbit/s), with ESP32-S3 rev0.2 and MAC `3c:0f:02:d6:1f:dc`. A subsequent 16 MiB read stalled at `Connecting...` on two attempts; both were stopped. A subsequent read-only `chip_id` connected normally at 921600 baud. This suggests intermittent serial connection/bootloader handshake rather than proof of slow flash throughput. It does not establish a root cause.

The existing complete 16 MiB backup is intact, but its OTA selection metadata is stale. A fresh 8 KiB OTA metadata read is valid and stored outside Git. **A fresh full 16 MiB backup is still missing.** Do not proceed with factory boot or a flash rescue.

Next safe actions: inspect USB cable/port reliability and any concurrent serial-monitor process; repeat a read-only 64 KiB connection test; then retry a full read with progress logged and verify exact length, SHA-256 and current OTA selection. Keep full backup out of Git, permissions 0600, because NVS contains credentials. Avoid `idf.py flash`, OTA metadata erases and all firmware writes.
