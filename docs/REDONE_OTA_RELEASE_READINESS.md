# RedOne OTA release readiness

The ESP32-S3 N16R2 has 16 MB flash. The previous default had only one factory application, and the first OTA layout had only two normal slots. Neither meets the agreed **three-application** recovery architecture.

`firmware/partitions.csv` now reserves:

| Partition | Offset | Size | Role |
| --- | --- | --- | --- |
| `recovery` (`factory`) | `0x20000` | 1 MiB | Independent minimal recovery application, separately built and protected from ordinary OTA |
| `ota_0` | `0x120000` | 3 MiB | Normal EFIS A |
| `ota_1` | `0x420000` | 3 MiB | Normal EFIS B |

The partition table also contains NVS, OTA selection data, PHY initialization and a coredump area. The factory subtype is a *bootloader-supported fallback location*, not proof of a working recovery system. A minimal recovery app, authenticated recovery transport, boot-selection policy (including deliberate recovery entry), and tests of both normal slots failing are **not yet implemented**. ESP-IDF A/B rollback alone does not guarantee entry into recovery if both normal images fail. Recovery must not be overwritten by a normal OTA.

**Critical build rule:** `idf.py flash` with the main EFIS application must not be used as a production provisioning procedure until the correct OTA slot and recovery image are explicitly selected and validated. A separate factory-provisioning procedure must install the bootloader, partition table, minimal recovery image, and normal EFIS application in the correct partitions.

**Not approved for aircraft installation.** A partition-table change cannot be safely deployed as an application-only OTA to a device already running the factory-only table. Existing devices require an explicitly planned USB/service migration that backs up device identity, NVS/licensing/calibration and confirms bootloader, partition-table and app compatibility. Never attempt a remote partition-table rewrite using the app-only OTA endpoint.

Before release approval: (1) reproducible clean ESP-IDF build from pinned Git commit, physical target and no QEMU/simulation; (2) separately build minimal recovery firmware and confirm partition layout, bootloader and app sizes; (3) bench-provision a sacrificial development unit with all three images; (4) test both OTA slots, interrupted transfer, boot failure, automatic rollback and explicit recovery entry; (5) verify signing, device authentication and anti-rollback compatibility; (6) explicitly approve publication. The existing published `2.4.1-test.1` is a simulator payload, not valid RedOne firmware. Keep phone Push/Activate/Rollback disabled.
