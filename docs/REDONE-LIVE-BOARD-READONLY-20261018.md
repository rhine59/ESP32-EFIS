# RedOne live physical board — read-only checkpoint (18 October 2026)

**Status: diagnostic evidence only; physical Partition B NO-GO.** No flash write, erase, eFuse programming or OTA boot selection was performed. esptool reset the board after serial commands.

## Board identity observed over USB

- Serial port `/dev/cu.usbmodem1101`
- ESP32-S3 rev 0.2, 8 MB PSRAM, 16 MB SPI flash
- MAC `3c:0f:02:d6:1f:dc`
- esptool v4.12.0, ESP-IDF environment v5.4.4

## Backup and sampled flash evidence

- Existing ignored backup: `hardware/board-backups/esp32s3-3c0f02d61fdc-20261018-fullflash.bin`, 16,777,216 bytes.
- Backup SHA-256: `e1a901cd87a961fe28c946981ddb909bd6e014873cbd9c67357c535f7ec7aa80` (matches previously recorded checksum).
- Live 4 KiB partition-table sample at `0x8000` matched corresponding backup bytes exactly; sample SHA-256 `36fd233e12141908e348a58b563a8c65e225264d3e5f9c9ed7715ab61bcf6ea8`.
- Live 4 KiB factory recovery sample at `0x20000` matched corresponding backup bytes exactly; sample SHA-256 `18afe2931573efee6fcf4abf9c43c520ed8537facfb17a666f8658ba4d10275e`. The sampled header starts with ESP image magic `0xe9`; **bootability not established**.
- Samples were stored under `/tmp` on the Mac; full backup remains ignored and uncommitted. This is **not** a full live-flash comparison.

## Live security status

Read-only `esptool get_security_info` reported secure boot disabled, flash encryption disabled, `SPI_BOOT_CRYPT_CNT=0x0`. No eFuse provisioning was attempted.

## Remaining gates

1. Read-only OTA metadata/current boot slot inspection with trusted live firmware telemetry; confirm whether `GET /boot-health` is actually present on this physical image.
2. Validate whole recovery image signature/format and separately prove actual recovery boot on a supervised ground bench, with a known-good restore path.
3. Test signed manifest acceptance/rejection and on-device verified image identity.
4. Complete trustworthy version-floor implementation and live boot-health/rollback evidence.
5. Conduct physical interruption matrix and obtain separate explicit approval before any Partition B write.

**Decision: NO-GO.** Do not interpret matched sampled bytes or a valid image header as proof of functional factory recovery.
