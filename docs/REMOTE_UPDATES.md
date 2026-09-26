# ESP32 EFIS — Remote firmware update and fallback design

**Design status:** server/admin and Swift user-flow implemented; physical ESP32 OTA not implemented or hardware validated  
**Baseline:** 16 September 2026  
**Target:** ESP32-S3-WROOM-1-N16R2, 16 MB flash

## Purpose and policy

Provide controlled remote application firmware updates while preserving a known-working application. The definitive policy separates four actions: **Stage → Publish → Download → Activate**.

The Docker administrator stages and explicitly publishes a release. The EFIS may optionally auto-download the next published compatible release while in its deliberate maintenance/network-update context, but **activation and reboot always require local `ACTIVATE & REBOOT`**. There is no unattended activation policy.

## A/B architecture

Use ESP-IDF native dual-slot OTA:

```text
HTTPS published manifest + signed application
                 |
                 v
ESP32-S3 bootloader
  ├── ota_0      current known-good or candidate
  ├── ota_1      candidate or previous known-good
  └── otadata    boot selection/OTA state
NVS/config/calibration remains separate
```

Download always targets the inactive slot. The running image is never overwritten in place. A completed candidate must pass transport/image/signature/compatibility verification before it can become **UPDATE READY**.

## Download versus activation

Auto-download ON means: discover the administrator-published release, download it to the inactive slot and verify it. It must stop there. The candidate remains dormant until the user chooses `ACTIVATE & REBOOT`.

Auto-download OFF means the user first chooses Download. The same verification and ready state follows. Network/download failure leaves the current application selected and usable.

If an administrator withdraws a release by republishing another manifest before activation, the production client must re-check publication/compatibility policy before activating a previously downloaded candidate and invalidate a withdrawn candidate where policy requires.

## Activation / fallback

After explicit activation, select the candidate boot slot and reboot. Enable ESP-IDF application rollback with application-controlled confirmation. The candidate starts `ESP_OTA_IMG_PENDING_VERIFY` and is not accepted merely because `app_main()` starts.

Minimum first-boot checks:

1. image/partition state sane;
2. NVS and required schema readable or safely migrated;
3. core render/data tasks alive for validation interval;
4. no watchdog/reset loop/fatal allocation condition;
5. physical display framebuffer allocation succeeds on hardware;
6. required software invariants pass.

Missing development sensors normally produce invalid data rather than rejecting an otherwise bootable firmware image; stricter production hardware-profile checks may be introduced only deliberately.

Pass:

```c
esp_ota_mark_app_valid_cancel_rollback();
```

Mandatory failure:

```c
esp_ota_mark_app_invalid_rollback_and_reboot();
```

Crash/reset/power loss before confirmation must cause return to the previous known-good image.

## State model

```text
KNOWN GOOD
   |
   v
CHECK PUBLISHED MANIFEST -- none/invalid/incompatible --> KNOWN GOOD
   |
   +-- auto-download OFF --> UPDATE AVAILABLE -- user Download --+
   |                                                           |
   +-- auto-download ON ---------------------------------------+
                                                               v
                                                  DOWNLOAD INACTIVE SLOT
                                                    | failure -> KNOWN GOOD
                                                               v
                                                        VERIFY CANDIDATE
                                                    | failure -> KNOWN GOOD
                                                               v
                                                           UPDATE READY
                                                    | user Later -> dormant
                                                               v
                                                    ACTIVATE & REBOOT
                                                               v
                                                        PENDING VERIFY
                                                        /            \
                                                      pass           fail
                                                       |              |
                                                   MARK VALID      ROLLBACK
```

## Release/distribution service

GitHub remains source/build history. The Docker OTA server is distribution. Its private admin service stages binaries and metadata; explicit Publish atomically changes the public manifest. Public EFIS clients never receive GitHub credentials and never access the admin endpoint.

Manifest identifies product, version, build, hardware profile, IDF baseline, immutable image URL, SHA-256, minimum allowed version and release notes. Production releases additionally require signed application images.

## Security

Minimum: valid HTTPS server certificate, product/hardware/version compatibility, complete-image integrity, logging of current/candidate/result. Production: signed application verification. Signing private keys never enter Git, Docker image, EFIS filesystem or downloadable artefacts; only verification material belongs on the device.

Do not initially enable irreversible eFuse anti-rollback during prototype work. Operational A/B rollback must remain available. Secure Boot v2, flash encryption and eventual security-version anti-rollback are later hardening decisions after update/recovery is proven.

## Persistent configuration compatibility

Application rollback is incomplete if new firmware irreversibly mutates shared NVS. Version every persistent config/calibration schema, prefer additive/backward-compatible changes, retain old calibration until the candidate is confirmed, and stage incompatible migrations so the previous known-good image can still boot safely.

## Network model

Wi-Fi is maintenance-oriented. The EFIS may use an iPhone Personal Hotspot as its Internet gateway to the public HTTPS OTA origin. Credentials are stored locally in NVS. Auto-download is constrained to the maintenance/network-update context; normal flight presentation must not silently initiate update traffic.

## Recovery

Preserve automatic A/B rollback, USB serial/JTAG service recovery, and a manual diagnostic procedure identifying running/boot/last-invalid partitions and versions. Initial OTA updates application image only; bootloader/partition-table OTA is excluded.

## Validation plan

Software: manifest/parser, state machine, auto/manual download decisions, withdrawn-candidate policy, self-test decisions, schema migration/rollback and maintenance UI. Physical bench: A→B/B→A, corrupt/truncated/wrong-product/wrong-hardware/wrong-signature rejection, Wi-Fi loss, power loss at multiple phases, deliberate first-boot crash/watchdog/self-test failure, exact rollback, NVS compatibility, repeated cycles and USB recovery.

QEMU/Swift success is not evidence of physical flash/power-loss recovery.

## Current status

Implemented in source control: Docker read-only origin, private image admin, staged metadata, explicit Publish, stage-only CLI helper, network/OTA Swift user scenarios. Not implemented/validated on ESP32: A/B partition table, maintenance Wi-Fi client, HTTPS OTA writer, signed-image pipeline/verification, boot confirmation and physical rollback/interruption tests.

## Boot/update entry and Wi-Fi — 26 September 2026

OTA is entered deliberately from the physical rotary boot menu: **FIRMWARE UPDATE** -> **Wi-Fi Connection** -> Check -> Download/Verify -> explicit **ACTIVATE & REBOOT**. The rotary/push control must operate the complete instrument-side flow. START EFIS remains available if networking fails.

Saved Wi-Fi credentials persist in ESP-IDF NVS and require encrypted NVS in production. Wi-Fi/network failure must not alter the current known-good application or prevent it starting. Auto-download, where enabled, still applies only inside maintenance/update context and never implies automatic activation.


## Licence compatibility

Firmware/OTA and product licensing are separate trust domains. OTA image signing and licence signing must use separate keys. Firmware updates must preserve a valid installed licence unless an explicit migration is required and tested. Licence verification is local/offline using a public verification key embedded/provisioned in the EFIS; the private licence-generation key must never be present on the instrument or OTA public server.

Licence schema/version compatibility must be checked during update testing so an otherwise valid update cannot silently strand a licensed instrument.


### Licence account service architecture — 26 September 2026

**ADOPTED / DESIGN STAGED.** Add a separate Docker service (working name `efis-account`) alongside OTA/admin services. It owns customer accounts, registered EFIS devices, licence entitlements and payment-provider linkage; it does not hold the licence-signing private key in the public web tier.

Device identity uses a provisioned immutable **EFIS Device ID / serial number** as the primary key. The ESP32 factory/eFuse base MAC may be recorded as a secondary hardware fingerprint and registration aid, but MAC address alone is not the licence identity because interface MACs can be derived/changed and MAC exposure is unnecessary for manual licensing.

Online boot-maintenance flow: LICENSE -> Connect Wi-Fi -> identify device -> authenticated account/licence endpoint -> fetch signed licence entitlement -> verify locally -> store in protected NVS -> continue offline. The EFIS must not send a user password; device authentication uses a provisioned device credential/challenge mechanism to be specified. Normal flight startup must not depend on account/payment/network availability.

Offline flow: show Device ID and short registration code/QR-capable text; user obtains a signed licence from the account portal on another device and enters/imports it manually or via USB service. The licence is verified locally with the embedded public verification key.

Payment integration is provider-adapter based. The account service creates checkout/customer-management requests and consumes verified payment webhooks; payment card data is handled by the payment provider, not stored by EFIS services. Payment status changes entitlements; a separate private signing worker/service generates signed licence payloads. Define explicit grace/revocation policy before subscriptions are enabled.

Suggested containers: `efis-account` API/web portal; PostgreSQL account/device/entitlement store; private `efis-license-signer` with tightly restricted signing-key access; existing `efis-ota` and `efis-ota-admin`. Payment provider secrets live only in server-side secret storage.
