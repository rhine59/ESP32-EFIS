# RedOne OTA release readiness

The ESP32-S3 N16R2 has 16 MB flash. The firmware's prior default used a single factory app partition, which **cannot** provide A/B OTA rollback. `firmware/partitions.csv` defines two 3 MB OTA application slots, OTA selection data and a coredump area. `sdkconfig.defaults` now selects this table and ESP-IDF bootloader rollback.

**Not approved for aircraft installation.** A partition-table change cannot be safely deployed as an application-only OTA to a device already running the factory-only table. Existing devices require an explicitly planned USB/service migration that backs up device identity, NVS/licensing/calibration and confirms bootloader, partition-table and app compatibility. Never attempt a remote partition-table rewrite using the app-only OTA endpoint.

Before release approval: (1) reproducible clean ESP-IDF build from pinned Git commit, physical target and no QEMU/simulation; (2) verify resulting partition CSV/binary, bootloader and app sizes; (3) bench flash a sacrificial development unit and test both OTA slots; (4) prove interrupted transfer, boot failure and automatic rollback; (5) verify signing, device authentication and anti-rollback compatibility; (6) explicitly approve publication. The existing published `2.4.1-test.1` is a simulator payload, not valid RedOne firmware. Keep phone Push/Activate/Rollback disabled.
