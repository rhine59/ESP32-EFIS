# RedOne hardware-protected build floor — Stage 23 design decision

**Design only — 18 October 2026. No flash writes, no eFuse provisioning, Partition B NO-GO.**

## Recommendation

**Keep the sole RedOne ESP32-S3 unprovisioned.** Do not repurpose its eFuse `secure_version` counter as a per-release build number. That counter represents a small number of irreversible *security epochs*, not ordinary software revisions; raising it could make the current factory recovery unbootable. The present unprotected boot chain also cannot establish a tamper-resistant local build floor simply by storing a counter in NVS or an ordinary flash partition.

For a production per-build monotonic floor, evaluate an authenticated external secure element with monotonic/rollback-resistant storage **on a separate prototype**, or redesign the secure-boot trust chain and signed policy to tolerate recovery across epochs. A generic I2C EEPROM, ordinary NVS or unauthenticated counter is not acceptable. Selection of a specific secure element must follow interface, cryptographic-authentication, power-loss atomicity, lifecycle and provisioning reviews; this document does not assume an unverified device feature.

## Trust contract

1. Device firmware authenticates the secure element (or another reviewed hardware root) with a non-exportable device-specific key and freshness-protected challenge-response. An untrusted bus reply must not count as hardware attestation.
2. Trusted state binds device identity, monotonic floor and current policy epoch. A missing, swapped, reset, corrupted or unavailable element must block staging, not default to zero.
3. Each advance is atomic under interrupted power and monotonic. Readback alone is insufficient against an active attacker without authenticated state and anti-replay protection.
4. The running firmware's build identity must be authenticated independently of a human-readable version string; the signed candidate build and image digest must be verified on-device before any update decision.
5. An accepted candidate may stage to the inactive slot without changing the floor. Advance only at a separately defined successful confirmation point, after real boot-health, rollback and recovery checks; avoid advancing past the known-good fallback before that fallback's compatibility is proven.
6. Preserve a separately signed and independently bootable factory recovery route across every permitted security epoch. A secure element failure must have a documented ground-only service path, not a permissive bypass.
7. Provisioning secrets, counter initialization, secure-element replacement and RMA procedures need independent design review. Never include secret keys in Git or logs.

## Prototype acceptance matrix (not yet executed)

- Valid authenticated counter/read succeeds; wrong identity, swapped element, replayed response, forged counter and absent element all reject.
- Counter rollback, increment overflow, write failure, torn update and power loss at each stage all reject or recover without reducing the floor.
- Signed candidate below installed floor, below running build, or requiring a higher minimum than running build rejects; matching permitted candidate accepts **policy evaluation only**.
- A/B recovery remains available after rejected releases and fault injection; factory image remains bootable across security epoch changes.
- Explicit, separate physical approval is required before any test-board flash or irreversible provisioning. Existing RedOne remains read-only for this stage.

## Read-only audit

Run `python3 hardware/boot-recovery-lab/tools/trusted_floor_design_audit.py`. It reports existing source guardrails and **hardcoded NO-GO** for unimplemented hardware trust, independent physical recovery testing and all physical writes. The script is not a security certification. See `docs/REDONE-SECURITY-AND-RECOVERY-ARCHITECTURE.md` and `docs/REDONE-PARTITION-B-DEPLOYMENT-READINESS.md`.
