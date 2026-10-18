# Physical RedOne factory recovery boot test — preparation only

**Status: NOT AUTHORISED FOR EXECUTION.** This document is a procedure design, not permission to modify the physical device. RedOne is the only identified board. Partition B remains **NO-GO**.

## Why the test is not a simple reversible boot switch

In installed ESP-IDF v5.4.4 `components/app_update/esp_ota_ops.c`, `esp_ota_set_boot_partition(factory)` validates the factory image and then calls `esp_partition_erase_range()` over the **entire `otadata` partition** (`0xf000`–`0x10fff`). This changes persistent flash and removes both validated OTA selection records. A factory app that does not implement an independently tested route back to `ota_0` could strand the board in recovery. Never claim this is a no-write test.

## Evidence already acquired

- Physical board ESP32-S3 rev0.2, MAC `3c:0f:02:d6:1f:dc`, 16 MiB flash.
- Full flash backup is available locally and matches its recorded SHA-256. It contains NVS secrets; never commit, print, distribute or copy it into diagnostics.
- Entire live factory recovery region `0x20000`–`0x11ffff` matches the backup and parses as a structurally valid ESP32 image; **recovery boot/function not proven**.
- Live `otadata` records are CRC-valid, both `VALID`, latest sequence 5 selects `ota_0`.
- Live bootloader loaded app from `0x120000`; running app reported `running=ota_0 selected=ota_0` and produced heartbeats.

## Preconditions before requesting approval for an actual boot

1. Ground bench only; external stable power and physical USB connection; aircraft disconnected and no flight reliance.
2. Record fresh board MAC, running/selected slot, app version, OTA state, flash size and live recovery image hash. Fail closed if any mismatch.
3. Obtain a **new full-flash backup** immediately before the test, store it outside Git, hash it, and verify a restore path on the Mac. Keep NVS and credentials private.
4. Verify factory recovery's *actual* USB/HTTP management capabilities without assuming that the normal `efis_boot_lab` console is available in recovery. Inspect recovery source/build identity and available signed recovery paths.
5. Define and rehearse a specific, authenticated recovery-to-`ota_0` operation on an isolated/simulated flash image. Ensure it does not erase `ota_0`, `ota_1`, factory recovery or NVS.
6. Define a documented host-side rescue path to restore **only** OTA selection data, with exact chip identity and flash-region safeguards. Do not use `idf.py flash` or a generic full-flash restore as the normal return method.
7. Prepare console capture and explicit timeouts; prove how to distinguish a successful recovery boot from an unintended fallback.
8. Review exact commands, risks, rollback/rescue and stop conditions; obtain a separate, explicit go/no-go decision for the destructive `otadata` change.

## Proposed supervised execution (NOT performed)

- Snapshot fresh state and stop on discrepancies.
- Enter factory recovery **only after** the above return/rescue path is proven and separately authorised.
- Confirm bootloader loaded factory at `0x20000`, capture recovery identity and diagnostics.
- Use the validated return path to select `ota_0`; verify bootloader loads `0x120000`, application reports `running=ota_0 selected=ota_0`, and health telemetry/heartbeats remain normal.
- Read back OTA metadata and confirm valid records. Record changes and evidence.

## Abort and escalation

Stop if serial access fails, image identity differs, unexpected boot partition appears, recovery cannot communicate, or return-to-A is unverified. Do not attempt speculative partition erases, eFuse operations, secure boot activation, flash encryption, firmware flashing or NVS resets. Preserve evidence and use the reviewed rescue procedure only with explicit operator approval.

**Current decision: NO-GO for recovery boot and NO-GO for Partition B.** The next safe work is offline inspection of factory recovery firmware's actual return capability and development of a read-only preflight tool.

## Offline source/binary return-path evidence — 18 October 2026

The deployed factory image matches the local 814,160-byte recovery build prefix byte-for-byte, and its source implements USB `bootA` via `esp_ota_set_boot_partition(ota_0)`. See `docs/REDONE-RECOVERY-RETURN-OFFLINE-AUDIT.md` and `hardware/boot-recovery-lab/tools/recovery_return_preflight.py`. All offline checks pass, but this does not prove that recovery boots or that `bootA` succeeds physically. **Execution still requires a fresh backup, validated rescue path and separate approval.**

## Fresh OTA snapshot and rescue preflight — 18 October 2026

A fresh 8 KiB live OTA metadata snapshot was saved locally (not in Git) and validated to select `ota_0`. The original full-flash backup's OTA metadata is stale; a new full 16 MiB backup was attempted but not completed because the read was too slow. Offline rescue planner and tests are in `hardware/boot-recovery-lab/tools/recovery_rescue_dry_run.py`; see `docs/REDONE-RECOVERY-RESCUE-PREFLIGHT-20261018.md`. **Do not execute factory boot until the full backup and independently tested rescue path are complete.**

## Offline OTA transition rehearsal — 18 October 2026

`hardware/boot-recovery-lab/tools/recovery_transition_sim.py` models the actual fresh `ota_0` selection, the factory boot's OTA metadata erase and the recovery `bootA` rewrite. Both modeled OTA-state policies return selection to `ota_0`. See `docs/REDONE-RECOVERY-TRANSITION-SIMULATION-20261018.md`. This is not physical validation; fresh complete backup and independent rescue rehearsal remain outstanding. **NO-GO**.

## Full backup completed — 18 October 2026

The previously outstanding fresh 16 MiB backup was completed via sixteen verified 1 MiB reads. Full SHA-256 `cca94c604a405a8aa137f3978de4ec4531c7d9cec6ff5542f295f7da1f80a7b3`; its OTA selection, factory recovery partition and first 1 MiB match independently read snapshots. See `docs/REDONE-FULL-BACKUP-SUCCESS-20261018.md`. **The backup gate is satisfied; independent rescue rehearsal and explicit physical boot approval remain outstanding.**

## Rescue snapshot byte-for-byte offline rehearsal — 18 October 2026

The full verified backup and fresh OTA snapshot pass an in-memory erase/restore simulation with exact whole-image SHA-256 restoration and no other changed bytes. See `docs/REDONE-RESCUE-RESTORE-REHEARSAL-20261018.md`. This satisfies an **offline** rehearsal only; the physical rescue procedure and factory recovery boot have not been validated. Separate explicit approval is still required for any physical boot-selection write.

## Independent chunk integrity audit — 18 October 2026

All 16 source chunks match the assembled full backup byte-for-byte, and independently read OTA and factory partitions match. See `docs/REDONE-BACKUP-INDEPENDENT-CHUNK-AUDIT-20261018.md`. Offline integrity PASS; physical recovery boot remains NO-GO.

## Resumable backup integrity hardened — 18 October 2026

The chunked read-only backup tool now verifies per-chunk SHA-256 and device identity from a private manifest before resuming; legacy chunks without manifests are rejected. See `docs/REDONE-BACKUP-RESUME-INTEGRITY-20261018.md`. Existing verified backup is unaffected. Physical recovery remains NO-GO.

## Independent execution evidence gate — 18 October 2026

All ten offline checks of device identity argument, backup, OTA selection and recovery partition pass. The read-only execution gate still explicitly refuses physical recovery boot, host writes and Partition B. See `docs/REDONE-PHYSICAL-RECOVERY-EXECUTION-GATE-20261018.md`. A physical rescue rehearsal on a separate board remains the outstanding dependency.

## Single-board path selected — 18 October 2026

The user has chosen to proceed without a second board. Fresh read-only OTA selection again confirms A and matches the full verified backup. See `docs/REDONE-SINGLE-BOARD-RECOVERY-PLAN-20261018.md`. Single-board recovery has greater risk: a failed factory boot/return may strand the only device. The single-board choice is **not** approval to erase OTA metadata; a separate explicit informed decision remains required.
