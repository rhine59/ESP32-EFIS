# RedOne read-only backup retry — 18 October 2026

**Physical factory recovery boot remains NO-GO.** USB `/dev/cu.usbmodem1101`, ESP32-S3 rev0.2, MAC `3c:0f:02:d6:1f:dc`.

- No competing esptool/serial-monitor process was found before tests.
- 921600 baud read of 64 KiB at `0x120000` using `--before no_reset` succeeded in 0.7 s transfer; the existing flasher stub was already running.
- Two 16 MiB full-flash read attempts stalled during `Connecting...` and were terminated; neither produced a complete new backup.
- A 1 MiB read from `0x0` using default reset succeeded in 13.1 s transfer, SHA-256 `cabf46fc57f7e2856ba0594ebf58324010d3654e3f3aee031e41aebc1e9f7ddc`, stored temporarily at `/tmp/redone-first-1m.bin`.
- A subsequent full 16 MiB read again stalled at `Connecting...` and was terminated. This confirms an intermittent connection/handshake issue independent of the requested transfer size, not an established throughput bottleneck.

No flash write, OTA selection change, eFuse operation or recovery boot was performed. Existing complete backup and fresh OTA metadata snapshot remain unchanged. Next: investigate USB-Serial/JTAG reset/handshake stability, physical cable/port, and whether staged 1 MiB reads with identity verification are reliable enough for a complete verified backup. Do not assemble a partial file and claim it is complete. **NO-GO**.
