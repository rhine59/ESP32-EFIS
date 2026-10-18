# Live OTA selection record decoding — 18 October 2026

**Source:** 8 KiB read-only dump from physical RedOne at flash `0xf000`, SHA-256 `9286d32b483e20b5a2e2217aead6e76c8378be80762174844a4c383497e081d9`. **Partition B remains NO-GO.**

Decoded using ESP-IDF v5.4.4 `esp_ota_select_entry_t`: sequence at offset 0, OTA state at 24, CRC at 28. CRC uses `esp_rom_crc32_le(UINT32_MAX, sequence_bytes, 4)` (equivalent to Python `zlib.crc32(seq_bytes, 0xffffffff)`). Both 4 KiB sectors have matching CRC and `ESP_OTA_IMG_VALID` (state 2).

| Sector offset | Sequence | State | CRC valid | OTA slot |
| --- | ---: | --- | --- | --- |
| 0 | 4 | VALID | yes | ota_1 / Partition B |
| 0x1000 | 5 | VALID | yes | ota_0 / Partition A |

With two OTA slots, `(sequence - 1) % 2` maps sequence 5 to `ota_0`. The newest selectable OTA record therefore indicates **Partition A selected for boot**. This does **not** independently prove which application is currently executing, nor does it demonstrate recovery bootability. Read-only firmware `GET /status` would provide `esp_ota_get_running_partition()` if the endpoint is deployed and the device is reachable/authenticated; it was not queried here. The Mac was not associated with a Wi-Fi network at this checkpoint. No credentials were read or disclosed.

Reproduce offline: `python3 hardware/boot-recovery-lab/tools/decode_otadata.py /path/to/otadata-8192.bin`.

**Next:** establish live authenticated running-partition telemetry without changing Wi-Fi configuration or firmware; otherwise plan a supervised serial-console observation. No boot-selection writes authorised.
