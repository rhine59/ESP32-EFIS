# RedOne security, OTA rollback and recovery architecture — Stage 18

**Status:** proposed design; not implemented or approved for irreversible hardware provisioning. **Physical Partition B: NO-GO.**

## 1. Separate three version concepts

- **Release build** (`build`, nonnegative int32): signed publisher claim, strictly increasing for ordinary application releases. Signed `minimum_allowed_version` is `build:<n>` and must not exceed the candidate build.
- **Installed build floor**: trusted monotonic policy for which release builds the device may accept. The existing `ota_floor` abstraction deliberately has **no** hardware provider. Never treat plain NVS or the application version string as a trusted floor.
- **ESP-IDF `secure_version`**: distinct hardware eFuse anti-rollback counter for *security epochs*, not for each application build. Increasing this can irreversibly make older signed application images, including factory recovery, unbootable. Never derive it automatically from the release build.

**Decision:** keep release builds and hardware security epochs separate. Security epoch increments require a dedicated security/recovery review, not a routine OTA release. The signed publisher manifest does not yet carry a validated `secure_version` claim; this requires a future signed schema revision and migration tests.

## 2. Trust and threat boundaries

1. OTA server and phone transport are untrusted for code execution: firmware must be authenticated and hashed **on device** using pinned trusted keys and hardware image verification when enabled. HTTPS alone is insufficient.
2. Secure Boot V2 on production-representative ESP32-S3 hardware should anchor bootloader/application authenticity. Current lab configuration has secure boot **disabled**.
3. Flash encryption should be evaluated to protect secrets at rest; it is not a substitute for signature verification, and key/eFuse provisioning can be irreversible. Current lab configuration has encryption **disabled**.
4. Hardware eFuse anti-rollback is one-way and finite. Use a deliberately conservative security-epoch policy with explicit recovery-image compatibility.
5. A recovery app in a `factory` partition is **not inherently immutable** and is not automatically guaranteed to boot under anti-rollback. Its write protection and actual bootloader fallback behavior must be proven on the target hardware and ESP-IDF version.
6. NVS `recovery` credentials are sensitive; avoid logging, exposing, or embedding them in test evidence.

## 3. A/B activation and recovery contract

- Normal application images occupy `ota_0` and `ota_1`; `recovery` is a separate factory slot. Never write an OTA image to the recovery partition.
- Stage only a signed, compatible image into the verified inactive slot; read back and verify before allowing an explicit ground-authorized boot selection.
- Keep the previously known-good application bootable until the candidate passes real firmware self-tests, sensors, display, supply, recovery-path checks and operator ground confirmation.
- An unconfirmed candidate must fail closed. Validate ESP-IDF rollback behavior across resets, watchdogs and interrupted first boot **on a dedicated test board** before exposing activation.
- If both OTA images fail, factory recovery access must be **demonstrated**, not assumed; include a physical factory-service pathway and a recoverable backup procedure.
- A power interruption at any stage must not silently promote a candidate, overwrite recovery, erase NVS or advance a security epoch.

## 4. Recovery versus security epoch compatibility

**Critical constraint:** an eFuse `secure_version` increase may reject older images, including recovery. Therefore no epoch advancement is permitted until the bootloader's actual recovery behavior and recovery image `secure_version` have been tested at the proposed epoch. If this cannot be guaranteed, **do not enable hardware anti-rollback on this partition architecture**; redesign recovery before provisioning.

Preferred sequence for a future security epoch migration:

1. Prove a recovery image compatible with the proposed epoch, signed by the approved production key, and a supported way to install/protect it without erasing credentials.
2. Verify at least one independently recoverable, signed application path and offline factory-service access.
3. Run rollback and interruption matrices at the *old* epoch on sacrificial hardware.
4. Obtain explicit approval for eFuse changes; record board identity, backups, keys, commands and irreversibility warnings without disclosing secrets.
5. Provision the test board only, confirm all recovery paths and failure behavior, and stop on any discrepancy.
6. Revisit production provisioning only after independent safety/security signoff.

**No eFuse writes, flash encryption, secure boot activation or recovery overwrite are authorized by this document.**

## 5. Device identity and monotonic floor design options

**Option A — ESP-IDF security epoch (preferred for coarse security boundaries):** use hardware `secure_version` for rare epoch changes, provided recovery compatibility is proven. It does **not** directly store every signed release build number.

**Option B — dedicated secure element / trusted monotonic storage:** use an externally authenticated monotonic counter or sealed state with a well-defined trust root and power-loss behavior for a per-build floor. The `ota_floor` interface may connect to it only after security and fault testing. Avoid claiming monotonicity from an ordinary writable NVS value.

**Interim bench behavior:** trusted floor unavailable, signed staging rejected; read-only status and signed preflight remain permitted where explicitly routed. No fake or permissive fallback values.

## 6. Ground-only and aviation safety rules

Firmware download to the phone may occur anywhere; transfer, boot selection, activation and rollback commands require the aircraft on the ground, a deliberate operator action and sufficient power. Firmware changes must not interrupt flight instrumentation. This supplementary EFIS is not a certified primary flight instrument.

## 7. Stage 19 test matrix on a separate board

| Test | Expected result | Evidence |
| --- | --- | --- |
| Unsigned or tampered manifest/image | Rejected before write/boot | Serial log, hashes, device result |
| Older release build | Rejected by signed build policy | Signed claims and decision trace |
| Missing/unreadable trusted floor | Staging refused | Error code and unchanged flash |
| Unconfirmed candidate / failed self-test | Candidate not confirmed; known-good fallback demonstrated | Boot-state logs, partition map |
| Power cut during staging / readback / activation | No recovery overwrite; deterministic boot outcome | Repeated interruption logs |
| Invalid OTA A and B | Factory-service recovery demonstrated | Physical console logs |
| Security epoch increased | Recovery and approved app remain bootable | eFuse readout and boot logs |
| Old security-epoch image | Hardware rejects it | Bootloader logs |
| Wi-Fi/phone disconnection | No unintended activation | Transport and boot logs |
| Ground-authorisation absent | No activation or confirmation | Endpoint test evidence |

Record each test's board identity, ESP-IDF version, firmware hashes, partition offsets, before/after boot states and explicit pass/fail. **Never execute the eFuse or flash mutation tests on the existing RedOne board without a separate approved plan.**

## 8. Stage 18 decision and outstanding work

**Decision:** use a separate disposable production-representative ESP32-S3 for security provisioning; retain existing RedOne as an unprovisioned recovery-capable development unit. Preserve the factory recovery architecture provisionally, but do not claim its security-epoch compatibility until verified. No production floor backend, image security-epoch migration, boot-health instrumentation, or physical fault-injection has yet been completed.

**Go/no-go:** NO-GO for physical Partition B until the readiness checklist in `docs/REDONE-PARTITION-B-DEPLOYMENT-READINESS.md` is independently satisfied.
