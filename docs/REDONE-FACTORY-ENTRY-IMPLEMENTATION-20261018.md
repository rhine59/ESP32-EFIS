# RedOne factory recovery entry — installed firmware capability check

**18 October 2026 — physical entry not performed; operator authorised factory test but direct host flash erase requires separate informed confirmation.**

Inspected the currently installed Partition A boot-lab source (`hardware/boot-recovery-lab/main/main.c`) and factory recovery source (`firmware/recovery/main/main.c`). The normal Partition A USB console has `status` and `provision`, and optional `boot0`/`boot1` behind `REDONE_UNSAFE_MANUAL_BOOT_SELECTION`. It has **no `bootFactory` command**. Factory recovery's `bootA` is only available *after* the factory image is running.

A normal-app call to `esp_ota_set_boot_partition(factory)` would erase the full 8 KiB OTA selection area, but there is no such call exposed by the installed normal-app USB console. Entering factory without reflashing firmware therefore requires a host-side operation affecting exactly `0xf000`–`0x10fff`. The potential host-side operation is a destructive erase, not merely a reboot, and must not touch NVS, factory, OTA A, OTA B or the partition table. **No command for this operation has been executed.**

The verified full backup SHA-256 is `cca94c604a405a8aa137f3978de4ec4531c7d9cec6ff5542f295f7da1f80a7b3`. The fresh live OTA metadata SHA-256 is `9286d32b483e20b5a2e2217aead6e76c8378be80762174844a4c383497e081d9`, selecting A. Factory image structurally matches the backup, but its physical boot/USB command availability is untested. Host-side OTA-only restoration is also untested.

**Decision required:** separately authorise a *direct host-side erase of only the 8 KiB OTA selection partition* on this sole board, accepting possible loss of normal boot and need for ROM bootloader rescue. Until that specific action is approved, no flash writes, boot changes, eFuse operations, firmware flashing or factory boot. Partition B remains NO-GO.
