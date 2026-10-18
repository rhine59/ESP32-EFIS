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
