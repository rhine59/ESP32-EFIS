# RedOne single-board recovery validation plan

**18 October 2026 — user has elected to continue using the existing ESP32-S3 only. Preparation and read-only verification only; destructive test NOT YET AUTHORISED.**

## Fresh live check

- ESP32-S3 rev0.2, MAC `3c:0f:02:d6:1f:dc`, USB `/dev/cu.usbmodem1101`.
- Fresh read-only 8 KiB OTA snapshot: `hardware/board-backups/redone-one-board-live-otadata-20261018.bin` (ignored, private, not in Git), SHA-256 `9286d32b483e20b5a2e2217aead6e76c8378be80762174844a4c383497e081d9`.
- Both OTA entries CRC-valid, seq4 selects B and seq5 selects A; current selection `ota_0`. Snapshot byte-for-byte matches verified 16 MiB full backup `cca94c604a405a8aa137f3978de4ec4531c7d9cec6ff5542f295f7da1f80a7b3`.
- This snapshot proves *selected* OTA slot, not independently that the app is currently running. The prior live console observation confirmed running A.

## Single-board risk acceptance required

The installed ESP-IDF `esp_ota_set_boot_partition(factory)` erases the entire 8 KiB OTA selection partition. This is a **persistent flash mutation**; if recovery USB is inaccessible or the return command fails, RedOne may require ROM bootloader rescue or hardware intervention. There is no independent spare device and no physical rescue rehearsal. A valid backup and offline simulation do not eliminate this risk.

## Proposed staged procedure, not an execution instruction

1. Verify ground-bench stable power, no aircraft connection, USB/BOOT access and no flight reliance. Reconfirm live MAC, partition table, factory image hash and current running/selected slot; capture logs.
2. Confirm the fresh complete flash backup and separately read OTA snapshot remain accessible and hash-valid. Protect NVS credentials; do not copy backups into Git.
3. Independent reviewer/operator examines the **exact** narrowly scoped OTA-selection-only rescue procedure and its flash offsets. Never use `idf.py flash`, full-chip erase, or a full-image restore as a first resort. Rescue write would require its own explicit authorization.
4. Only after separate explicit informed approval, execute a controlled factory-boot selection on the existing board. Treat it as an irreversible-for-the-moment metadata erase, not a harmless temporary switch.
5. Confirm the factory bootloader offset `0x20000`, factory app identity and read-only recovery status. If recovery is reachable, use its reviewed `bootA` operation only under the approved test scope; then verify bootloader returns to `0x120000` and app reports running and selected A.
6. Read back OTA metadata and compare its valid selection. If anything unexpected occurs, stop. Do not improvise flash writes, eFuse operations or other boot selections.

## Decision

The user has approved **using one board as the development constraint**, not yet specifically approved erasing its OTA metadata or accepting a possible unbootable device. No factory boot or host flash write is authorized by this document. A separate confirmation is required before the first destructive operation. Partition B remains NO-GO.
