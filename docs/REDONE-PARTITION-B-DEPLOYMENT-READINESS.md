# RedOne Partition B — deployment readiness and go/no-go

**Assessment:** 18 October 2026 · **Decision: NO-GO for real deployment**.

The iOS **EFIS status** readout now renders its authenticated status rows in green instead of secondary grey. Green indicates that the readout succeeded; it **does not certify firmware integrity, rollback readiness or flight suitability**. Unavailable/unknown rollback remains explicitly labelled as such.

Run the read-only, fail-closed audit:

```bash
python3 hardware/boot-recovery-lab/tools/partition_b_readiness.py
```

Exit `0` means every declared evidence gate is true; exit `2` means no-go. The default run uses no invented evidence and deliberately fails. Evidence may be supplied as a local JSON file with `--evidence`, but a human reviewer must confirm each claim against physical logs and signed test records. The script does **not** inspect the actual board or flash anything; source checks are guardrails, not proof of physical readiness.

## Required before real Partition B staging

1. Demonstrate genuine publisher-signed release acceptance and tampered-release rejection on the physical ESP32.
2. Implement and verify a trusted persistent anti-downgrade floor, including a defined relationship between signed version string and monotonic build number.
3. Implement real boot-health checks and demonstrate rollback when checks fail; do not mark a pending image valid at startup.
4. Pass physical power-cut/interrupted-transfer tests at erase, write, finalize, readback, boot selection and first boot.
5. Verify factory recovery and a known-good boot route after each injected failure.
6. Confirm physical device is running Partition A, Partition B is the intended inactive target, full-flash backup is verified, and exact offset/length are reviewed.
7. Obtain explicit operator approval for a narrowly scoped physical write. No generic `idf.py flash`, NVS erase or recovery overwrite.

The current experimental signed staging function is **not routable**. Live update/verify/activate routes remain locked. A successful Xcode build, ESP-IDF build, or host simulation does not satisfy the physical gates.

## Practical release stages

- **Now:** test green iOS status readout, exercise non-destructive readiness audit and read-only signed-release checks.
- **Next:** complete on-device crypto tests, trusted version policy, health/rollback implementation and read-only physical partition inventory.
- **Then:** conduct supervised fault-injection tests using an approved, recovery-preserving Partition B test image.
- **Only after all gates pass:** permit a controlled Partition B staging and separate explicit activation trial. Keep the aircraft grounded and use a verified recovery plan.

Cross-references: `docs/REDONE-ARCHITECTURE-GUIDE.md`, `docs/REDONE-USER-GUIDE.md`, `hardware/boot-recovery-lab/SECURE-OTA-GATE.md`.

## Boot-health policy checkpoint

The `redone_ota_guard/ota_boot_health` component now requires seven independently asserted health conditions before a pending OTA image can be confirmed: identity, firmware self-test, required sensors, display, power, rollback path and operator ground confirmation. Host tests verify each missing condition blocks confirmation. Bench startup explicitly reports the unavailable hardware evidence and **does not mark the image valid**. This policy is deliberately not an automatic confirmation mechanism: real sensors, watchdog, rollback readiness and trusted operator confirmation have not yet been connected or physically tested. It does not change the NO-GO decision.

## Read-only live evidence endpoint (Stage 12)

The bench firmware now compiles an authenticated `GET /boot-health` endpoint returning `pendingVerify`, `imageIdentityOk`, `inactiveSlotPresent`, `firmwareSelfTestOk`, `requiredSensorsOk`, `displayOk`, `powerOk`, `rollbackPathOk`, `operatorGroundConfirmation`, `mayConfirmBoot` and `updateReady`. Only actual ESP-IDF boot/partition and app descriptor readings can become true; untested physical evidence remains false. No flash writes or boot metadata changes occur. This endpoint is not yet installed on the physical RedOne, so a successful build is not a live diagnostic result. Deployment decision remains **NO-GO**.

## Stage 13: version-claim parsing

Strict signed build-floor parsing is now implemented and tested, but not yet integrated with the publisher manifest or persistent trusted version state. Partition B remains NO-GO.

## Stage 14: anti-downgrade gate integrated, deployment still blocked

The unregistered staging path now checks the signed build-floor claim and anti-downgrade policy before flash selection/writes. Because the installed trusted monotonic floor and running build are not yet available, it **always rejects staging**. Current publisher metadata uses a semantic-version minimum, not `build:<int32>`, so signer/device schema migration is necessary. Do not substitute plain NVS as tamper-proof monotonic storage or infer build identity from a human-readable firmware version. Readiness remains **NO-GO**.

## Stage 15: publisher-side build policy validation

The OTA Admin now validates release metadata against the device's `build:<int32>` signed-minimum format before staging and before publishing. It rejects legacy `0.0.0`, malformed values, overflow and a minimum greater than the candidate build. The upload form defaults to `build:0`. **Existing published manifests and hosted metadata have not been migrated**, and the shell-based staging helper remains a separate legacy interface requiring a future update. The device's trusted monotonic floor and physical rollback testing remain missing. No production publication or device deployment was performed; **Partition B remains NO-GO**.

## Stage 16: legacy shell staging policy aligned

`ota-server/scripts/publish-release.sh` now calls the same Python build-policy validator as the OTA Admin UI before touching release files. It defaults to `build:0`, rejects semantic-version minimums and malformed or out-of-range build claims, and continues to **stage only**, never publish. This eliminates a publisher-side validation bypass; it does not establish trusted on-device monotonic storage. Existing published manifests remain unchanged and physical deployment remains **NO-GO**.

## Stage 17: trusted monotonic floor interface (not yet provisioned)

Added `ota_floor.c/.h`: a fail-closed storage policy that requires a backend to attest hardware protection, read a nonnegative floor, refuse any decrement, and read back increases. Host tests cover missing protection, failed reads/writes, attempted downgrade and incorrect readback. **No hardware-backed provider exists yet.** Current bench configuration has `CONFIG_SECURE_BOOT`, `CONFIG_FLASH_ENCRYPTION_ENABLED`, `CONFIG_APP_ANTI_ROLLBACK` and `CONFIG_BOOTLOADER_APP_ANTI_ROLLBACK` disabled. Turning these on may involve irreversible eFuse provisioning and must not be done without a separate physical security and recovery design. Do not use ordinary NVS as trusted monotonic storage. Partition B remains NO-GO.

## Stage 18: approved security architecture, no physical provisioning

See `docs/REDONE-SECURITY-AND-RECOVERY-ARCHITECTURE.md` for the design decision to separate signed release build numbers, trusted installed build floor and irreversible ESP-IDF hardware `secure_version` security epochs. Recovery bootability under a raised security epoch **must be demonstrated**, not assumed. Preserve the existing RedOne board and conduct secure boot, encryption and eFuse tests only on a separately approved sacrificial board. Run `python3 hardware/boot-recovery-lab/tools/security_architecture_audit.py` for a **read-only source/config inventory**; it is not a physical safety test. Partition B remains **NO-GO**.

## Stage 19: separate security test-board preparation

The test plan in `docs/REDONE-STAGE19-SECURITY-TEST-PLAN.md` defines gates for inventory, unprovisioned rehearsal, factory recovery/security-epoch compatibility, separately approved eFuse experiment, fault injection and independent review. `hardware/boot-recovery-lab/tools/stage19_preflight.py` is read-only and fails closed until physical test-board evidence is supplied; it never authorises writes. No separate board has been identified or provisioned. Partition B remains **NO-GO**.

## Physical RedOne read-only checkpoint — 18 October 2026

Live ESP32-S3 rev0.2/16 MB/8 MB identity, backup SHA-256, partition-table 4 KiB and recovery-header 4 KiB matching the existing backup, and disabled secure boot/encryption were verified without flash writes. See `docs/REDONE-LIVE-BOARD-READONLY-20261018.md` for exact evidence and limitations. Recovery **bootability** and whole-image integrity have not been demonstrated. Partition B remains **NO-GO**.

## Live OTA metadata and complete recovery image — 18 October 2026

See `docs/REDONE-LIVE-OTA-RECOVERY-20261018.md`. The full 1 MiB factory recovery region matches the backup, with a valid ESP32 image checksum and validation hash. Live OTA selection metadata differs from backup; raw sequence numbers alone do not prove the executing partition. Recovery bootability remains untested. Physical Partition B **NO-GO**.

## Physical OTA selection decoded — 18 October 2026

Both live OTA selection entries have valid ESP-IDF CRCs and are marked VALID; latest sequence 5 selects `ota_0` (Partition A). See `docs/REDONE-LIVE-OTA-DECODE-20261018.md`. This remains a boot-selection inference, not independent running-firmware telemetry. No firmware write or boot selection was performed. **NO-GO**.

## Live running-partition confirmation — 18 October 2026

Read-only USB console observation confirmed the bootloader loaded `0x120000` and the running application independently reported `running=ota_0 selected=ota_0`. See `docs/REDONE-LIVE-RUNNING-PARTITION-20261018.md`. The compiled `IMAGE B` label does not represent the physical slot. Recovery boot, trusted version floor and interruption tests remain unproven. **Partition B NO-GO**.

## Factory recovery boot preparation — 18 October 2026

Installed ESP-IDF 5.4.4 `esp_ota_set_boot_partition(factory)` erases the entire `otadata` partition. On the only RedOne board, this is a persistent, potentially disruptive operation. See `docs/REDONE-PHYSICAL-FACTORY-RECOVERY-BOOT-PLAN.md` for required rescue-path verification and separate approval. No recovery boot has been performed. **NO-GO**.

## Stage 20: prevent manually asserted evidence from bypassing physical safety gates

The read-only `partition_b_readiness.py` checker now measures security-related ESP-IDF build settings directly and introduces non-overridable gates for independent physical security provisioning and rollback fault-test attestation. Even an input JSON file with every declared key set to `true` **cannot** produce a physical deployment GO decision. A source-level configuration flag also cannot prove that the corresponding security eFuses are provisioned or that the installed board is secure. This deliberately requires a future independent, authenticated physical evidence verification workflow before the gate can ever be lifted. The checker always reports `physical_write_authorized=false` and `partition_b_activation_authorized=false` because a diagnostic CLI is not an operator authorisation mechanism. The installed board remains on OTA A; no physical changes were made during Stage 20. **Partition B remains NO-GO.**
