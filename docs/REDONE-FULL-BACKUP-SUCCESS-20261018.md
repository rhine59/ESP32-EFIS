# RedOne verified fresh full-flash backup — 18 October 2026

**Result: PASS for complete read-only backup. Physical recovery boot and Partition B deployment remain NO-GO.**

The ESP32-S3 (MAC `3c:0f:02:d6:1f:dc`) was read in sixteen contiguous 1 MiB chunks at 921600 baud using `hardware/boot-recovery-lab/tools/backup_flash_chunks.py`. Each chunk required a successful esptool return, exact 1 MiB length, matching board MAC in esptool output and a recorded SHA-256 before assembly. The assembled 16,777,216-byte backup is stored locally at ignored `hardware/board-backups/redone-pre-recovery-20261018-fullflash.bin`, permission 0600. **Never commit or share the binary; it contains NVS secrets.**

**Full backup SHA-256:** `cca94c604a405a8aa137f3978de4ec4531c7d9cec6ff5542f295f7da1f80a7b3`.

Independent local consistency checks passed:

- Backup `0xf000`–`0x10fff` equals the separately read fresh OTA snapshot byte-for-byte; SHA-256 `9286d32b483e20b5a2e2217aead6e76c8378be80762174844a4c383497e081d9`, selecting `ota_0`.
- Backup `0x20000`–`0x11ffff` equals the earlier separately read complete factory recovery partition byte-for-byte.
- Backup first 1 MiB equals the earlier independent read `/tmp/redone-first-1m.bin` byte-for-byte.
- Offline rescue preflight passes for the assembled backup and current OTA snapshot.

These checks verify successful capture and consistency across reads, **not** that restoring flash is safe or that factory recovery boots. The backup process never wrote firmware, OTA selection, NVS or eFuses.

**Remaining gate:** independent physical or expendable-device rehearsal of OTA-selection-only rescue and explicit supervised approval for factory boot's OTA metadata erase. Physical recovery boot and Partition B remain NO-GO.
