# Lollipop Design RedOne — System Architecture and Engineering Guide

**Edition:** 18 October 2026 · **Audience:** firmware, iOS/Android, backend, hardware, QA and support engineers · **Authority:** GitHub `main` plus referenced source; design intentions are not evidence of implementation.

> **Scope:** RedOne EFIS and its companion Lollipop workflows, signed licensing, OTA/recovery, diagnostics and supporting services. BlueOne/SMUX is a separate proposed sensor-multiplexer product. This is a non-certified, supplementary aviation system. No development build is approved as a primary flight instrument.

## Contents
1. [System boundary and component map](#1-system-boundary-and-component-map)
2. [Repositories and code ownership](#2-repositories-and-code-ownership)
3. [Hardware and physical interfaces](#3-hardware-and-physical-interfaces)
4. [Instrument firmware and data integrity](#4-instrument-firmware-and-data-integrity)
5. [Boot partitions and recovery](#5-boot-partitions-and-recovery)
6. [OTA trust and transport](#6-ota-trust-and-transport)
7. [Boot-health, rollback and downgrade controls](#7-boot-health-rollback-and-downgrade-controls)
8. [Lollipop client architecture](#8-lollipop-client-architecture)
9. [Accounts, ownership and licensing](#9-accounts-ownership-and-licensing)
10. [Backend services and deployment](#10-backend-services-and-deployment)
11. [CAN and future SMUX integration](#11-can-and-future-smux-integration)
12. [Diagnostics, logging and observability](#12-diagnostics-logging-and-observability)
13. [Security model and threat analysis](#13-security-model-and-threat-analysis)
14. [Build, testing and release](#14-build-testing-and-release)
15. [Failure modes and recovery runbooks](#15-failure-modes-and-recovery-runbooks)
16. [Open decisions and acceptance gates](#16-open-decisions-and-acceptance-gates)
17. [Source-document index](#17-source-document-index)

## 1. System boundary and component map

```text
Manufacturer / publisher (internet)       Customer identity and licences
  signed releases, release metadata          account, device, entitlement
                 |                                      |
                 v                                      v
         Lollipop phone app <------ internet ------ backend services
         iOS (implemented), Android parity target
                 |
        local RedOne Wi-Fi (authenticated)
                 |
                 v
       RedOne ESP32-S3 firmware
       +----------------------------+
       | factory recovery / bench  |
       | OTA Partition A / B       |
       | instrument UI + sensors   |
       | local diagnostics + NVS   |
       +----------------------------+
          |       |       |      |
       display  IMU    pressure  magnetometer / GNSS
          |
       AEF-CAN (planned) <---- BlueOne / SMUX (separate scope)
```

**Trust boundaries:** Internet publication is untrusted until a pinned publisher signature verifies; the phone is an untrusted transport from the EFIS perspective; the local Wi-Fi link requires authentication but does not substitute for signature verification; the account service is authoritative for ownership, while the device independently verifies licences and firmware. Simulators are never evidence of physical hardware performance.

## 2. Repositories and code ownership

The canonical repository is `rhine59/ESP32-EFIS`; GitHub `main` is the source of truth. Key paths:

| Area | Location | Role |
|---|---|---|
| Main EFIS firmware | `firmware/` | ESP-IDF application, sensors, display and state |
| Recovery crypto | `firmware/recovery/components/redone_crypto/` | Pinned-key Ed25519 and verified release envelopes |
| OTA bench firmware | `hardware/boot-recovery-lab/` | Partition tests, authenticated read-only APIs, staging guards |
| iOS Lollipop | `ios/EFISService/` | SwiftUI companion and guided processes |
| OTA server | `ota-server/` | Publisher/admin assets and service deployment |
| Customer services | `account-service/`, `license-service/`, `license-signer/` | Identity, entitlement and signing separation |
| Support | `support-service/` | Reviewed product help and diagnostic support |
| Simulator | `simulator/`, `redone-ota-simulator/`, `efis-web-simulator/` | Development and fault scenarios |
| CAN schema | `protocol/aef-can.yaml` | Machine-readable bus contract |
| Architecture docs | `docs/` | Adopted designs, test notes, requirements and limitations |

Names such as `EFISService` and `esp32_efis` are stable implementation identifiers; customer-facing product names are **Lollipop Design**, **RedOne**, and **BlueOne**. The README contains historical checkpoints; always use dated source evidence for current safety assertions.

## 3. Hardware and physical interfaces

The proposed processor is **ESP32-S3-WROOM-1-N16R2** (16 MB flash, 2 MB PSRAM). The display is a single Newhaven 2.1-inch, 480 × 480 circular IPS panel; display controller initialization and RGB565 framebuffer rendering are developed against QEMU. Proposed sensing: BMI088 IMU, BMP585 on aircraft **static** pressure, remote RM3100 magnetometer, GNSS receiver with explicit fix validity and horizontal accuracy. The project does **not** include a pitot/differential-pressure IAS channel. Rotary/push PEC09 control, MCP23008 GPIO expansion, backlight drive, USB-C bench power and a 3 1/8-inch enclosure are documented separately.

Physical harnesses, voltage domains, grounding, RF placement, mounting orientation, connector pinouts, power budgets and thermal/mechanical tolerances require carrier-board verification. No GPIO or bus operation should be inferred safe merely from a schematic or simulator. See `docs/HARDWARE.md`, `docs/WIRING.md`, `docs/POWER_BUDGET.md`, `docs/SENSORS.md`, `docs/MECHANICAL_MATERIALS_AND_THERMAL.md` and `BOM.md`.

## 4. Instrument firmware and data integrity

ESP-IDF **v5.4.4** is the documented baseline. Instrument data is separated from presentation; each measurement needs source identity, timestamp/freshness, validity, units and fault reason. Do not silently substitute zero or stale readings. Attitude estimation requires a verified aircraft-axis mapping; barometric altitude requires static pressure and QNH; magnetic heading requires calibration and tilt compensation; GNSS track is not magnetic heading. Receiver-reported horizontal accuracy is a quality estimate, not certified integrity. Deterministic QEMU and SwiftUI simulation are acceptance aids for rendering and state logic, not substitutes for flight-hardware calibration.

## 5. Boot partitions and recovery

The provisioned **bench board** uses the following layout (addresses hexadecimal; do not assume all future production revisions share it):

| Partition | Offset | Size | Purpose |
|---|---:|---:|---|
| NVS | `0x9000` | `0x6000` | Persistent configuration/bench pairing |
| OTA metadata | `0xF000` | `0x2000` | Boot selection and OTA state |
| PHY init | `0x11000` | `0x1000` | RF calibration |
| Factory recovery | `0x20000` | `0x100000` | Recovery image; never use as update target |
| OTA Partition A (`ota_0`) | `0x120000` | `0x300000` | Application slot |
| OTA Partition B (`ota_1`) | `0x420000` | `0x300000` | Application slot |
| Coredump | `0x720000` | `0x10000` | Crash diagnostics |

The running app and factory recovery must never be erased during normal OTA staging. The bootloader's OTA state and `esp_ota_get_running_partition()` determine the active image; `esp_ota_get_next_update_partition()` identifies the candidate inactive slot. The storage adapter rechecks these conditions. The bench device has a preserved full-flash backup, excluded from Git because it may contain secrets. **Never run a generic `idf.py flash` or erase NVS on the provisioned board.** Firmware/recovery and bootloader/partition-table changes need a separately approved, narrowly targeted procedure.

## 6. OTA trust and transport

### Signed-release envelope

`redone-ed25519-json-v1` uses a pinned manufacturer public key and a canonical JSON payload with the fields `build`, `hardware_profile`, `idf`, `image_url`, `minimum_allowed_version`, `product`, `release_notes`, `sha256`, `version`. The ESP32 verifier in `redone_envelope.c` rejects malformed, duplicated or unexpected fields; enforces `ESP32-EFIS` and `s3-n16r2-v1`; and rejects non-ASCII metadata pending canonicalization parity tests. `redone_verify_release_metadata()` returns signed build, binary digest and minimum-version string **only on successful Ed25519 verification**. A checksum without a trusted signature is not a firmware authenticity guarantee. Private signing keys must never be placed on the EFIS or phone.

### Current bench HTTP surface

| Method/path | Behaviour |
|---|---|
| `GET /status` | Authenticated version, running/next partition, boot state; rollback/update readiness false |
| `POST /firmware/verify-manifest` | Authenticated, read-only signed-envelope verification |
| `POST /firmware/hash` | Authenticated, read-only streamed image SHA-256 |
| `POST /firmware/preflight` | Authenticated, read-only combined signed-envelope + image hash check |
| `POST /update` | Locked: 403, no flash write |
| `POST /verify` | Locked: 403 |
| `POST /activate` | Locked: 403 |

`/firmware/preflight` accepts a 4-byte big-endian signed-manifest length, signed JSON envelope, then firmware bytes. The verified digest is compared against the received image; its response includes `transferEnabled:false`. These are **bench** endpoints, not a production API contract. The separate factory recovery service uses `/api/recovery/...` paths: do not conflate the two HTTP interfaces.

### Internal staging components

`redone_ota_guard` (pure C) checks authentication, signed manifest, inactive-slot eligibility, size, transfer byte count, incoming and flash-readback digest, plus explicit ground/rollback conditions before activation. `ota_staging` coordinates begin/write/readback/abort via an injectable backend; host tests simulate interruptions and I/O failures. `main/ota_esp_storage.c` uses `esp_ota_begin`, `esp_ota_write`, `esp_ota_end`, `esp_partition_read` and `esp_ota_abort` on the selected inactive slot. `signed_staging_dry_run()` is an **unregistered experimental function** in `ota_http.c`. Despite its name, it would write flash if invoked: it is **not** a harmless dry run. No HTTP route calls it. Never register it without completing the remaining gates.

### Target future sequence (not enabled)

Download signed release on internet → cache verified envelope and image on phone → connect to RedOne Wi-Fi → authenticate device and requester → verify signed metadata and downgrade policy → stage bounded chunks to inactive slot → read back/verify → explicit on-ground activation → reboot → health checks → confirm image valid or roll back. Interrupted uploads must not modify boot selection. A production protocol must define transaction/session IDs, replay protection, idempotency, timeouts, durable offsets and restart handling; the current single-request experimental staging function does not implement all of these.

## 7. Boot-health, rollback and downgrade controls

ESP-IDF OTA boot state includes `NEW`, `PENDING_VERIFY`, `VALID`, `INVALID` and `ABORTED`. **Stage 9 removed automatic confirmation of a pending image** from the bench startup code: a new image must not be marked valid merely because it reached `app_main()`. The manual USB `boot0`/`boot1` selection commands are compiled out by default. The pure C `ota_version` policy rejects unsigned claims, invalid build numbers, same/older builds and candidates below signed/device minimums.

**Remaining blockers:** the signed `minimum_allowed_version` is a string, not a numeric monotonic build floor; trusted installed-floor persistence is not implemented; no complete device health protocol has been validated; power-loss and boot-failure rollback remain unproven on physical hardware. The candidate cannot be activated until all are resolved. Persistent NVS alone is not automatically tamper-resistant or monotonic; define the threat model before claiming downgrade resistance. Health confirmation must include relevant sensor/display/power/communication checks and must not silently validate failed critical functions.

## 8. Lollipop client architecture

The iOS SwiftUI project is under `ios/EFISService/`; the app uses process-led views rather than a flat diagnostics-button catalogue. A top **What to do next** instruction and selectable current step share the same action. Green/blue/grey/amber/red statuses correspond to completed/current/future/waiting/failed. The phone downloads signed releases using internet connectivity, then joins RedOne Wi-Fi for local authenticated status and (eventually) transfer. iOS Keychain stores sensitive credentials; Android Keystore or equivalent is the planned counterpart. Saved device connections and future product-box QR onboarding are design requirements, not blanket assertions of production readiness. Firmware Push/Verify/Activate/Rollback remain disabled pending device-side safety acceptance. The companion's licence/account flows must use authoritative server and EFIS acknowledgements rather than treating a cached state as success.

## 9. Accounts, ownership and licensing

Account service responsibilities: registration/verification, authentication, recovery, owner/device association, transfers, entitlement and audit history. The server must authenticate the buyer and atomically accept ownership; email matching in a simulator is not production authentication. Signed licence generation belongs in a private signer service separate from the public account/payment API. RedOne independently verifies device-bound licences offline using a pinned public key; installation is complete only after the EFIS reports valid status. First-year entitlement attaches once to the device and does not reset on ownership transfer. Licence expiry or service outage must not create plausible false instrument data. See `docs/LICENSING_ARCHITECTURE_AND_FLOWS.md`, `docs/CUSTOMER_ACCOUNT_AND_APPS.md` and `docs/PROCESS_WORKFLOW_ARCHITECTURE.md`.

## 10. Backend services and deployment

`ota-server/` publishes approved releases and manifests; signing and promotion must be restricted and auditable. `account-service/`, `license-service/`, `license-signer/`, `support-service/` are separate service boundaries. Docker Compose/Synology and a proposed Proxmox virtualization host are infrastructure options, not EFIS runtime dependencies. Use per-repository container naming, private secrets, explicit port mapping, least-privilege accounts, backups and monitored TLS termination. Avoid placing signing private keys in web images, Git or client bundles. Deployment details and historical endpoint ports are in `docs/SYNOLOGY_CONFIGURATION.md`, `docs/SERVER_PLATFORM.md`, `docs/OTA_IMAGE_ADMIN.md` and the service READMEs; verify the live configuration before operating it.

## 11. CAN and future SMUX integration

AEF-CAN (Aircraft Experimental Flight CAN) is a planned 500 kbit/s Classical CAN protocol with 11-bit identifiers. `protocol/aef-can.yaml` is the machine-readable source. BlueOne is the proposed SMUX sensor node; RedOne owns display units, alert thresholds and presentation, while producers report canonical measurements and explicit validity. ESP32-S3 TWAI needs an external transceiver. Node discovery, firmware compatibility, stale-data handling, fault isolation and bus-load testing are required before integration acceptance. Current RedOne OTA work does not imply BlueOne firmware deployment support is ready.

## 12. Diagnostics, logging and observability

Separate **instrument operational faults**, **bench recovery diagnostics**, **app workflow state** and **server audit logs**. Diagnostic PASS must identify the measured condition and threshold; SKIP means not measured. Persist fault identifiers with bounded flash wear and no credentials. The recovery diagnostics service currently tests selected internal resources and explicitly skips unverified external hardware. `/status` is not a complete diagnostic report. Expose build/partition/boot state and non-secret errors; never log Wi-Fi passwords, tokens or private signing keys. Crash/coredump retention needs privacy controls and safe extraction procedures.

## 13. Security model and threat analysis

| Threat / fault | Control | Outstanding gap |
|---|---|---|
| Malicious publisher response | Pinned Ed25519, canonical payload, signed hash | Publisher positive/negative on-device acceptance evidence |
| Compromised phone or Wi-Fi peer | Device-side independent verification, token authentication | Production pairing/session protocol, replay resistance |
| Wrong hardware image | Signed product/hardware claims, image descriptor validation | Full hardware/revision compatibility matrix |
| Downgrade | Build-number policy | Trusted monotonic floor and signed minimum semantics |
| Power loss during transfer | Inactive slot, no boot selection until completion | Physical interruption matrix, durable transaction handling |
| Failed new firmware boot | Pending verification/rollback | Validated health criteria and physical rollback tests |
| Recovery corruption | Factory recovery never OTA target | Factory/recovery backup, recovery entry validation |
| Secret disclosure | Keychain, protected NVS, private signer separation | Production NVS encryption, provisioning/rotation |
| Faulty/stale sensor | Explicit freshness and invalid indication | Physical sensor and aircraft installation validation |

Do not infer secure boot, flash encryption, anti-rollback eFuse configuration or production-grade key storage merely because ESP32 hardware supports them. Those must be independently specified and measured for the actual board.

## 14. Build, testing and release

### Local build (macOS)

```bash
cd ~/Documents/Xcode/ESP32-EFIS
source scripts/efis-env.sh
cd hardware/boot-recovery-lab
idf.py -B build-secure-ota -D EFIS_LAB_IMAGE=B build
```

**Build only**: this command does not flash hardware. Avoid generic `idf.py flash` on the provisioned board.

### Host safety tests

```bash
cd ~/Documents/Xcode/ESP32-EFIS
python3 -m unittest discover -s hardware/boot-recovery-lab/tests -p 'test_*.py' -v
cc -std=c11 -Wall -Wextra -Werror \
  -I hardware/boot-recovery-lab/components/redone_ota_guard \
  hardware/boot-recovery-lab/components/redone_ota_guard/ota_guard.c \
  hardware/boot-recovery-lab/components/redone_ota_guard/ota_staging.c \
  hardware/boot-recovery-lab/tests/test_ota_staging.c \
  -o /tmp/redone-stage-test && /tmp/redone-stage-test
```

Additional unit tests cover `ota_version` and Ed25519. For iOS build/test use `ios/EFISService/EFISService.xcodeproj`, scheme `EFISService`, and a valid simulator or provisioned device destination. Keep signing credentials out of Git. Release acceptance must record source commit, toolchain, signing key ID, image SHA-256, firmware/hardware compatibility, unit/integration results, physical interruption/rollback matrix, and operator sign-off. A successful compile or phone install is **not** a release approval.

## 15. Failure modes and recovery runbooks

**Upload disconnect:** cancel staging, do not select boot slot; retry with a new authenticated transaction. **Hash mismatch:** reject candidate and retain known-good running image. **Invalid signature/wrong hardware:** reject before any flash write. **Boot pending verification:** do not mark valid until explicit health checks pass; retain rollback path. **Boot loop:** collect serial logs and inspect OTA state; use documented recovery entry without erasing NVS or factory image. **Wi-Fi failure:** preserve normal instrument startup; diagnose pairing/SoftAP without exposing secrets. **Licence failure:** distinguish cloud entitlement from signed device licence; avoid affecting fail-obvious instrument readings. **Sensor fault:** mark affected data invalid and follow bench commissioning procedure. **Partition corruption:** stop automated changes and restore only from a verified, authorised device-specific backup with a controlled recovery procedure.

A bench power-interruption campaign should test resets before begin, during erase, at each chunk boundary, after `esp_ota_end`, during readback, after boot selection and during first boot; capture serial logs and boot selection each time. No such campaign has been completed for Stage 10.

## 16. Open decisions and acceptance gates

1. Define signed minimum-version semantics and a trustworthy device monotonic build floor, with factory and recovery handling.
2. Define boot-health predicates, timeout, watchdog and rollback behaviour; do not auto-confirm at startup.
3. Design authenticated, replay-resistant staging sessions and durable progress/recovery.
4. Verify canonical Ed25519 signatures and firmware metadata on the physical ESP32 against genuine published release samples.
5. Validate physical interrupted-write, corrupted-image, failed-boot and recovery tests without jeopardising the factory partition.
6. Review secure boot, flash/NVS encryption, key rotation, signing-service controls and manufacturing provisioning.
7. Complete sensor, power, display, rotary, CAN and environmental bench tests before any aircraft evaluation.
8. Validate iOS/Android functional parity and accessible guided workflows against actual service responses.

**Go/no-go:** OTA Push/Activate/Rollback must remain locked until signed metadata, version policy, hardware compatibility, safe inactive-slot staging, physical recovery and post-boot health validation have passed independently. See `hardware/boot-recovery-lab/SECURE-OTA-GATE.md` for the current code-specific gate.

## 17. Source-document index

- **Product and safety:** `README.md`, `docs/PROJECT_STATUS.md`, `docs/SAFETY.md`, `docs/BRANDING.md`.
- **Instrument and hardware:** `docs/HARDWARE.md`, `docs/WIRING.md`, `docs/SENSORS.md`, `docs/AHRS.md`, `docs/GNSS_DISPLAY.md`, `docs/DISPLAY.md`, `docs/CALIBRATION.md`, `docs/TESTING.md`, `BOM.md`.
- **Boot and OTA:** `docs/EFIS_BOOT_AND_RECOVERY_ARCHITECTURE.md`, `docs/REDONE_FACTORY_BOOT_POLICY.md`, `docs/REDONE-OTA-STAGE-PROTOCOL.md`, `docs/REDONE_OTA_RELEASE_READINESS.md`, `docs/REDONE-FIRMWARE-TRANSFER-MILESTONES.md`, `hardware/boot-recovery-lab/SECURE-OTA-GATE.md`.
- **Phone and workflows:** `docs/PROCESS_WORKFLOW_ARCHITECTURE.md`, `docs/PHONE_LOCAL_FIRMWARE_MANAGEMENT.md`, `docs/PHONE_NETWORK_AND_PUBLIC_OTA.md`, `docs/OTA_USER_SCENARIO.md`, `docs/REDONE-RECOVERY-DIAGNOSTICS.md`.
- **Services/licensing:** `docs/CUSTOMER_ACCOUNT_AND_APPS.md`, `docs/LICENSING_ARCHITECTURE_AND_FLOWS.md`, `docs/SYNOLOGY_CONFIGURATION.md`, `docs/SERVER_PLATFORM.md`, `docs/SUPPORT_SERVICE.md`.
- **Bus/SMUX:** `docs/CAN-PROTOCOL.md`, `protocol/aef-can.yaml`, `docs/STAGE-7-SMUX.md`.
- **History and verification:** `CHANGELOG.md`, `docs/PROJECT_STATUS.md`, `docs/OTA_PHYSICAL_TEST_NODE.md`.

---

**Change-control rule:** update this guide, the User Guide, `CHANGELOG.md` and the relevant source-specific safety document when behaviour or release gates change. Prefer explicit *implemented*, *tested in simulation*, *tested on hardware*, *planned*, and *blocked* labels over undifferentiated feature claims.
