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
