# RedOne live running-partition confirmation — 18 October 2026

**Physical board:** ESP32-S3 rev0.2, MAC `3c:0f:02:d6:1f:dc`; USB `/dev/cu.usbmodem1101`.

**Result: independently confirmed running and selected partition `ota_0` (Partition A).** No flash write, erase, eFuse change, manual boot selection, recovery boot or Partition B deployment was performed. Opening USB serial caused `USB_UART_CHIP_RESET`, a normal reset with no firmware change.

## Evidence observed from live USB console

- Bootloader: ESP-IDF v5.4.4, build Oct 17 2026 19:35:12.
- Partition table: `recovery` factory at `0x20000` length `0x100000`; `ota_0` at `0x120000` length `0x300000`; `ota_1` at `0x420000` length `0x300000`.
- Bootloader: `Loaded app from partition at offset 0x120000`.
- App: `Project name: efis_boot_lab`.
- App: `EFIS BOOT LAB — IMAGE B — 1.1.0`.
- App: `Running partition: ota_0, next update: ota_1`.
- After sending only read-only `status` on USB: `BOOT_LAB: running=ota_0 selected=ota_0`.
- Heartbeats 1–5 observed, indicating that the bench application continued running during the observation.

**Important:** `IMAGE B` is the image's compiled display label and does **not** indicate that flash Partition B is running. The authoritative live partition is `ota_0` from the bootloader and `esp_ota_get_running_partition()`. Fixing label/slot presentation is a future software UX task, not a reason to write the device.

## Remaining limitations

The factory recovery partition's bytes and ESP image checksum/hash were previously verified, but **factory recovery has not been booted**. Neither signed update staging, a trusted persistent build floor, nor live rollback under interruption has been validated. No physical Partition B write is authorised by this observation. **Partition B remains NO-GO.**

Next: prepare a supervised, explicitly authorised factory recovery boot/return-to-A procedure with preflight evidence and stop conditions. Do not assume factory fallback will automatically work merely because the recovery image parses correctly.
