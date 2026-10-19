# Stage 25 — Secure-element selection and trust-chain integration

**Design checkpoint, 18 October 2026. Candidate selection is provisional. No device changes. Partition B NO-GO.**

## Decision and alternatives

**Preferred evaluation path: Microchip ATECC608 family**, because it is a relatively focused ESP32-compatible I2C authentication component with development ecosystem and candidate counter functionality. **Fallback evaluation: NXP SE050 family**, if the exact ATECC608 variant cannot meet authenticated, power-loss-safe monotonic build-floor requirements. **Infineon OPTIGA Trust M** remains a research alternative. This is a prioritisation for investigation, **not** an assertion that any exact part implements the required secure monotonic state. Do not order a production PCB or lock device configuration based on this shortlist.

Before selecting an exact SKU, verify vendor datasheet revision, counter width and endurance, increment semantics, maximum increments, power-failure atomicity, host authentication protocol, challenge freshness, identity binding, irreversible configuration/lock steps, lifecycle support and lead time. Require a working vendor evaluation board and reference implementation. If counters cannot support a practical release cadence, do not repurpose a limited counter; revise the architecture.

## Host-to-element contract

1. Host obtains fresh unpredictable nonce and requests identity, current floor, epoch and authenticated response; verify the response using an independently provisioned trust anchor. I2C address and plain chip serial number are **not** authentication.
2. Reject mismatched identity, unknown key, stale nonce, invalid MAC/signature, malformed floor, untrusted epoch and transport errors. Never fall back to `build:0`.
3. On a signed candidate, validate on-device signature, payload hash, board compatibility, signed build/minimum and trusted floor; staging remains disabled until the full trust chain and rollback gates pass.
4. Do **not** advance the monotonic floor when staging or selecting an unconfirmed candidate. Advance only after a fully verified boot and rollback-safe confirmation protocol; the old known-good image must remain compatible with the new floor or recovery must provide an independently authenticated downgrade/service route.
5. On element failure, lock update operations and show a diagnostic/service state; do not unlock firmware staging. Define an authorised replacement/reprovisioning flow bound to the physical board and recovery identity.

## Security prerequisites

Secure Boot V2 and flash-encryption provisioning on an expendable ESP32-S3 are a **separate future workstream**. An element attached to the current insecure host cannot force untrusted host firmware to honour its counter. The factory recovery image must be signed, bootable and compatible with the proposed hardware security epoch before any irreversible provisioning. Preserve the sole RedOne as an unprovisioned bench device.

## Stage 25 exit criteria

- Vendor-confirmed exact part and counter/identity capabilities; explicit lifecycle and power-failure test plan.
- Protocol specification with independent host key provisioning and authenticated, fresh responses.
- Separate-board recovery/security-epoch plan and independently verified signed boot chain.
- Offline adapter test harness with unavailable, replay, forged, rollback, overflow and power-cut cases.
- Independent review of advance-after-confirmation and RMA/replacement semantics.

**Current outcome:** preferred/fallback evaluation paths chosen, but no exact SKU approved, no physical trust anchor, no hardware-backed floor provider and no physical test. NO-GO for Partition B.

## Stage 25 continuation — floor advancement transaction (19 October 2026)

The offline simulator now exercises a **post-confirmation-only** floor-advance
transaction. All four independent conditions are required: authenticated
release signature, complete boot-health confirmation, explicit on-ground
operator confirmation, and proof that the known-good recovery path remains
compatible with the proposed new floor. A failure in any condition leaves the
simulated floor unchanged. Replay of a used nonce is rejected. A power cut
*after* an abstract commit leaves the new floor in place, so the host must
reconcile with a fresh authenticated read instead of blindly retrying.

This models the required decision boundary, **not** physical atomicity,
cryptographic host identity, a real secure-element counter or a working
recovery-compatibility verifier. The booleans are controlled test fixtures and
must never be exposed as caller-provided production authorisation. No hardware
provider, secure boot, flash encryption, or physical OTA write is enabled.

**Next external prerequisite:** acquire vendor evidence for an exact secure
counter part, plus a disposable production-representative ESP32-S3 and an
appropriate secure-element evaluation board. Verify increment limits,
power-cut semantics, host challenge authentication, device binding and recovery
compatibility before implementing a device backend. Current decision: NO-GO.
