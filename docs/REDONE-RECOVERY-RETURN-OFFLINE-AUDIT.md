# RedOne factory recovery return-to-A — offline evidence audit

**Result:** all offline checks pass; **physical factory recovery boot NOT authorised**, Partition B **NO-GO**.

## Exact deployed recovery image

The 814,160-byte local `firmware/recovery/build/redone_recovery.bin` matches the beginning of the entire live 1 MiB factory partition byte-for-byte. The live partition also matches the corresponding portion of the original full-flash backup. Whole-partition SHA-256: `5ec003355adea49738eace6bf7b262b90a5f6fa9a90b3fc156604faf24ac42fa`.

## Source-confirmed return capability

`firmware/recovery/main/main.c` contains USB commands `status`, `test`, `bootA`, `bootB`, `help`. `bootA` calls `boot_slot(0)`, which locates `ESP_PARTITION_SUBTYPE_APP_OTA_0`, reads its app description, calls `esp_ota_set_boot_partition(p)` and restarts. This is a **real return-to-A implementation** in the deployed recovery image, but its physical runtime behaviour remains untested.

The installed ESP-IDF 5.4.4 `esp_ota_set_boot_partition(factory)` implementation erases `otadata` before factory boot. Returning with `bootA` would rewrite OTA selection metadata, so the procedure must account for persistent state change and power interruption.

## Preflight automation

`hardware/boot-recovery-lab/tools/recovery_return_preflight.py` checks source evidence, build-image/live-flash prefix equality, backup match and the factory boot OTA erase semantics. It **always** returns `safe_to_execute_factory_boot=false` and `return_to_a_physically_tested=false`, even if all offline checks pass. No device access or flash writes occur. Unit tests cover incomplete evidence and complete evidence fail-closed cases.

## Physical test prerequisites still outstanding

Fresh full-flash backup immediately before execution; offline, identity-checked rescue plan for OTA selection; operator physically at grounded bench; explicit approval for the irreversible-in-session OTA metadata erase; live console capture and tested abort conditions. No factory boot was performed in this audit.
