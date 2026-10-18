# RedOne secure-element candidates and offline monotonic-floor simulator — Stage 24

**18 October 2026. Design evaluation only; no hardware purchase, wiring, provisioning, flash or eFuse writes. Partition B NO-GO.**

## Hardware candidate shortlist — features require datasheet confirmation

| Candidate family | Why investigate | Key question before selection |
| --- | --- | --- |
| Microchip ATECC608 family | I2C hardware key storage, authentication and limited-use counter capabilities are relevant to device identity | Does the exact variant's counter/lifecycle model support the required per-release monotonic floor, atomic power-loss behavior and recoverable replacement? |
| NXP SE050 family | General-purpose secure-element applets and protected persistent state are relevant to authenticated device policy | Can the selected SKU enforce the desired monotonic semantics and anti-replay with an independently anchored host trust key? |
| Infineon OPTIGA Trust M family | Hardware-protected identities and cryptographic operations may support authenticated state | Does its exact firmware/object policy offer genuinely rollback-resistant counters rather than only mutable secure storage? |

**No candidate is approved or claimed to meet the requirements.** Obtain current vendor datasheets, development boards, lifecycle/locking documentation and power-loss test evidence before choosing one. A protected key alone is not equivalent to a protected monotonic counter. On the ESP32-S3, the host verification trust anchor also needs a secure-boot-backed design: with secure boot disabled, modified host firmware can bypass application policy.

## Simulator

`python3 hardware/boot-recovery-lab/tools/secure_floor_simulator.py` models device-bound, nonce-based authenticated floor reads and an abstract atomic counter update using in-memory HMAC test fixtures. The secret in the simulator is a public test constant, **not a real device key**. Tests cover forged counters, wrong identity/key, replay, epoch/nonce mismatch, missing element, downgrades, invalid numeric values and simulated power cuts before and after an abstract commit. They do not model a torn physical write or prove that any chip has atomic counters, authenticated channels or correct lifecycle configuration.

The simulator explicitly reports `hardware_attested=false`, `physical_flash_authorized=false` and `partition_b_decision=NO-GO`. It is not linked to device firmware or OTA routes. Next: choose a candidate by verified capabilities, define a host authentication protocol and key lifecycle, then run physical fault injection **only on a separately authorised prototype**. The existing single RedOne board is unchanged.
