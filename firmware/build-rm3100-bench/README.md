# RM3100 bench firmware image — 17 October 2026

**NOT FOR FLIGHT / NOT HARDWARE VALIDATED.** This is an ESP32-S3 EFIS firmware binary compiled for bench diagnostics only. It must not be deployed as an operational aircraft instrument.

- Image: `esp32_efis.bin` (application partition only; not a full flash image)
- ESP-IDF: 5.4.4; target: ESP32-S3
- RM3100 diagnostic enabled, I2C address 0x20; QEMU and bench simulation disabled
- Compiled from a temporary integration tree using the committed RM3100 driver and EFIS integration source, not from this repository checkout as a single revision. Do not claim reproducible release provenance.
- SHA-256: `527f0286db627fc332cfeb2c5c4da8b0d261c4683bfaaaf718e48a36b3808848`
- Compilation: PASS; hardware communication and flashing: NOT TESTED.
- Build record: `docs/RM3100-ESP-IDF-PORT-AND-VALIDATION.md`

For a reproducible firmware release, build from a clean, pinned repository commit, archive the matching bootloader and partition table, and validate on actual hardware. This application binary alone is not sufficient for a fresh device flash.
