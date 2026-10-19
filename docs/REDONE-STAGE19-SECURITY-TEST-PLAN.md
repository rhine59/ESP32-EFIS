# Stage 19 — dedicated ESP32-S3 security test-board plan

**Status:** preparation only. **No board identified or provisioned.** Physical RedOne Partition B remains **NO-GO**.

## Purpose

Establish whether Secure Boot V2, flash encryption, ESP-IDF security-version anti-rollback, OTA A/B fallback and factory recovery can coexist on the chosen ESP32-S3 configuration. This is a safety/security validation activity on a separate, expendable board; not a production deployment.

## Equipment and separation

- A **separate, expendable** ESP32-S3 development board matching the RedOne's relevant flash/PSRAM and bootloader capabilities (ideally ESP32-S3-WROOM-1-N16R2), with independent USB power and serial console.
- Stable power supply with a controlled interrupt method, serial log capture, physical board identification and a copy of the partition map.
- Non-production signing keys and secrets, never copied from the real RedOne or checked into Git.
- Offline recovery tooling and a verified full-flash backup taken **before** security provisioning. A backup is not necessarily restorable after irreversible eFuse changes.

## Sequence and gates

**Gate 19A — read-only inventory:** identify test-board chip, revision, flash size, MAC, eFuse state and current partitions without writes; review the independent recovery method. Compare to RedOne configuration. Do not read or print secrets.

**Gate 19B — unprovisioned functional rehearsal:** with test-only keys, verify signed-image acceptance and tamper rejection in software; exercise A/B boot-health failure and rollback on the disposable board **before** irreversible provisioning. Keep recovery accessible.

**Gate 19C — security-epoch compatibility design review:** confirm how the ESP-IDF bootloader handles `factory` recovery with `secure_version` enforcement. Establish which signed images remain bootable at each epoch. Do not assume factory partition bypasses anti-rollback. If this cannot be demonstrated, redesign the recovery path.

**Gate 19D — separately approved irreversible experiment:** only after operator review of exact board identity, flash layout, provisioning commands, test-only keys, irreversibility, recovery limitations and abort criteria, provision security features on the disposable board. This plan does not authorise those commands.

**Gate 19E — physical fault matrix:** test corrupted image, wrong signature, old security epoch, interrupted writes, interrupted first boot, failed diagnostics, Wi-Fi loss, loss of power and both OTA slots invalid. Record logs and known-good/recovery boot outcomes.

**Gate 19F — independent review:** verify evidence and update deployment readiness. No test success automatically enables physical RedOne Partition B.

## Preflight command

```sh
python3 hardware/boot-recovery-lab/tools/stage19_preflight.py
```

The tool reads source/config only. Optional `--evidence reviewed.json` accepts booleans for the named physical review gates, but even with all true it **never** grants eFuse or flash authorisation. Evidence must be backed by independent logs and approval. No secrets in evidence JSON.

## Stop conditions

Stop on unexpected board identity, missing serial recovery, unknown eFuse state, recovery-image incompatibility, loss of known-good boot, incomplete power-loss results, signing-key mismatch, or any ambiguity about irreversible changes. Do not touch the existing RedOne board during Stage 19.

## Expected deliverables

Signed-image validation logs, hardware inventory, recovery boot demonstration, physical interruption matrix, security-epoch compatibility report and explicit independent go/no-go review. Until completed, **NO-GO**.

## Evidence register (offline, read-only)

Run `python3 hardware/boot-recovery-lab/tools/physical_fault_evidence.py` to list missing evidence. Once a **separate** disposable board is available, maintain a private JSON record with `board.mac`, `board.disposable`, `board.test_only_keys`, and a `scenarios` object. Each scenario requires `result: "PASS"`, a SHA-256 digest of its retained test log in `log_sha256`, and a nonempty `reviewer`. The scenarios are defined in the script and cover signatures, downgrade, staging/activation/boot interruptions, failed boot health, both OTA slots invalid, recovery after each fault, and security-epoch compatibility. Do not include private keys, tokens, or confidential serial logs in Git.

The tool checks only the *shape of operator claims*. It cannot authenticate a log, identify a physically connected board, prove fault injection, or approve provisioning. Even a complete record remains **NO-GO** for RedOne flashing. The existing RedOne MAC is explicitly rejected as a separate test-board identity. Physical execution requires a separate, narrowly scoped operator-approved test plan and equipment.
