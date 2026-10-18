# RedOne physical OTA metadata and complete recovery-image audit — 18 October 2026

**Result:** read-only evidence collected; **Partition B NO-GO**. No flash writes, erases, eFuse changes, boot-slot selection or recovery boot attempted. Serial reads cause automatic board reset.

## Read-only live OTA data

- USB `/dev/cu.usbmodem1101`, ESP32-S3 rev0.2, MAC `3c:0f:02:d6:1f:dc`.
- Read 8,192 bytes from `otadata` at `0xf000`, SHA-256 `9286d32b483e20b5a2e2217aead6e76c8378be80762174844a4c383497e081d9`.
- Entry at offset 0: sequence 4, OTA state raw `0x709d68a8`; entry at 0x1000: sequence 5, OTA state raw `0xc8210fcd`.
- **Caution:** these raw values are at offset 28, which is the OTA selection CRC field in the ESP-IDF `esp_ota_select_entry_t`, **not** the OTA state. OTA state is at offset 24; a separate parser is required to assess validity and state. Do not infer a confirmed boot from raw sequence values alone.
- Sequence 5 maps to `ota_0` for two OTA slots if it is the newest *valid* record; this is a conditional boot-selection inference, not live `esp_ota_get_running_partition()` telemetry.
- Live `otadata` differs from the earlier backup, so the backup is not a current boot-state snapshot.

## Complete factory recovery partition

- Read the complete 1,048,576-byte factory partition at `0x20000` into a local temporary file.
- SHA-256: `5ec003355adea49738eace6bf7b262b90a5f6fa9a90b3fc156604faf24ac42fa`.
- **Entire 1 MiB partition matches** the corresponding original full-flash backup region byte-for-byte.
- `esptool image_info` parsed six segments, valid checksum `0x2d`, and valid validation hash `9b240871b09d731d3278fa63065fe0b960cc0e9e51f04a47b4bd4caa550609fe`.
- The image is structurally valid and its bytes match backup; this does **not** prove bootability, functionality, cryptographic authenticity, protected immutability or compatibility with future eFuse anti-rollback.

## Next gates

Decode and validate OTA selection records and obtain read-only running-partition evidence, then design a supervised factory recovery boot test with an explicit return-to-A plan. No boot-selection mutation until separately approved. Do not enable Secure Boot, flash encryption or hardware anti-rollback on this existing board.
