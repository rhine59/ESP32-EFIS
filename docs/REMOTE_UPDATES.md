# ESP32 EFIS — Remote firmware update and fallback design

**Design status:** architecture/design only — not implemented or hardware validated  
**Baseline:** software/emulator baseline of 16 September 2026  
**Target:** ESP32-S3-WROOM-1-N16R2, 16 MB flash

## Purpose

Provide a controlled way to update ESP32 EFIS application firmware remotely while preserving a known-working application if the download, first boot or application self-test fails.

This capability must never make flight information less trustworthy. An update is a maintenance operation, not a flight function. The EFIS must never download/install firmware merely because a network becomes available, and synthetic data must never be substituted if an update or rollback affects a real sensor source.

## Recommended architecture

Use ESP-IDF's native dual-slot application OTA mechanism:

```text
                         HTTPS
                          │
                          ▼
                 signed release metadata
                 + signed application image
                          │
                          ▼
┌───────────────────────────────────────────────────────────┐
│ ESP32-S3                                                  │
│                                                           │
│  bootloader                                               │
│      │                                                    │
│      ├── ota_0  ← current known-good application          │
│      ├── ota_1  ← candidate/new application               │
│      └── otadata ← boot selection + OTA state             │
│                                                           │
│  NVS/config/calibration data remains separate             │
└───────────────────────────────────────────────────────────┘
```

The running application downloads into the **inactive** OTA slot. It never overwrites itself in place. Only after the complete candidate image has passed transport/image verification is the inactive slot selected for the next boot.

ESP-IDF's OTA data partition uses redundant sectors and is specifically designed so interruption while changing the boot selection does not destroy the currently running application.

## Fallback / rollback behaviour

Enable ESP-IDF application rollback and use **application-controlled confirmation**.

A newly installed image therefore starts as `ESP_OTA_IMG_PENDING_VERIFY`. It is not marked good merely because `app_main()` was reached. The new ESP32 EFIS firmware must first run a short boot self-test.

Minimum confirmation checks should include:

1. application image/partition state is sane;
2. NVS can be opened and required settings schema can be read or safely migrated;
3. core render/data tasks start and remain alive for the validation interval;
4. no watchdog/reset loop or fatal allocation condition occurs;
5. display framebuffer allocation succeeds on physical hardware;
6. required internal software invariants pass.

Sensor absence must be handled carefully. During development or maintenance a sensor can legitimately be disconnected, so a missing BMI088/BMP585/RM3100 should normally leave its flight data **invalid** rather than automatically reject otherwise bootable firmware. Once the production hardware baseline is frozen, a stricter hardware-profile self-test may be introduced deliberately.

If mandatory self-tests pass, call:

```c
esp_ota_mark_app_valid_cancel_rollback();
```

If a mandatory self-test fails, call:

```c
esp_ota_mark_app_invalid_rollback_and_reboot();
```

If the new application crashes, resets or loses power before confirmation, the bootloader must select the previous known-good OTA application on the following boot.

## Update states

```text
IDLE / KNOWN GOOD
      │
      │ explicit maintenance request
      ▼
CHECK MANIFEST ──invalid/incompatible──► IDLE + report failure
      │
      ▼
DOWNLOAD TO INACTIVE SLOT
      │
      ├── network/power/error ─────────► retain current app
      ▼
VERIFY IMAGE
      │
      ├── fail ────────────────────────► retain current app
      ▼
SET CANDIDATE BOOT SLOT
      │
      ▼
REBOOT
      │
      ▼
PENDING VERIFY
      │
      ├── self-test passes ────────────► MARK VALID ─► KNOWN GOOD
      │
      └── fail/crash/reset ────────────► ROLLBACK ──► PREVIOUS KNOWN GOOD
```

## Partition layout

The current project only fixes the module flash size at 16 MB and has not yet frozen a custom OTA partition table. Before implementation, create and validate a project-specific CSV partition table containing at minimum:

- `nvs` — settings/calibration/state;
- `otadata` — OTA boot selection/state;
- `ota_0` — application slot A;
- `ota_1` — application slot B;
- optional dedicated diagnostic/crash-log/data partition if later justified.

Both application slots must be large enough for the expected mature EFIS image plus deliberate growth margin. Freeze actual offsets/sizes only after measuring the built application and expected assets. Do not invent a factory partition merely as a second fallback: the two OTA slots provide the operational A/B fallback and keep the previous known-good image available.

## Network model

Wi-Fi should be a **maintenance-only service**. It should normally be disabled during normal flight operation and enabled only through an explicit local maintenance action, for example a long encoder action or a future dedicated maintenance menu.

Recommended sequence:

1. aircraft stationary / maintenance mode explicitly entered;
2. flight display remains conspicuously in maintenance/update state;
3. Wi-Fi starts and joins a configured trusted network;
4. user explicitly requests **Check for update**;
5. version/manifest is shown;
6. user explicitly confirms installation;
7. download/verification proceeds;
8. reboot only after the image is complete and verified.

Do not perform unattended automatic installation. A later optional *notification* that an update exists is distinct from automatic installation.

## Release service

The device should retrieve a small HTTPS release manifest from a controlled endpoint rather than scrape GitHub pages. Example logical fields:

```json
{
  "product": "ESP32-EFIS",
  "version": "0.4.0",
  "build": 42,
  "hardware_profile": "s3-n16r2-v1",
  "idf": "5.4.4",
  "image_url": "https://updates.example/esp32-efis/0.4.0/app.bin",
  "sha256": "...",
  "minimum_allowed_version": "0.3.0",
  "release_notes": "..."
}
```

The final service can be backed by a GitHub Release or another HTTPS host, but the device-facing URL and trust policy should remain stable. Do not embed a GitHub personal access token in firmware. Public release binaries or a small authenticated update service are preferable to placing long-lived repository credentials on the instrument.

## Authenticity and transport security

Minimum design requirement:

- HTTPS with server certificate validation;
- reject incompatible product/hardware metadata;
- verify the complete ESP application image before selecting it for boot;
- log installed/current/candidate version and update result.

Production recommendation: require **signed application images** so possession/control of the download server alone is insufficient to install arbitrary firmware. ESP-IDF supports signed OTA verification even without enabling hardware Secure Boot. Secure Boot v2 and flash encryption should be evaluated before the production hardware/security baseline is frozen.

Signing **private keys never go into the repository, firmware image, device filesystem or CI artifact**. Only public verification material belongs on the device.

## Anti-rollback versus operational rollback

Do not initially enable irreversible eFuse anti-rollback during prototype development. ESP-IDF anti-rollback prevents booting images below an eFuse security version; that is useful after a security baseline is mature, but it can also deliberately make older images unbootable.

The first implementation should use **operational A/B rollback**: a bad candidate returns to the previous known-good image.

Later, once releases and recovery are proven, anti-rollback can be introduced only for firmware generations with a security vulnerability that must never be reinstalled. The security-version policy must ensure the immediately previous fallback image remains eligible when a candidate is first deployed.

## Configuration and calibration compatibility

Application rollback is incomplete if a new application irreversibly changes shared NVS data so the previous firmware can no longer use it.

Therefore:

- version every persistent configuration/calibration schema;
- prefer backward-compatible additive changes;
- do not delete/overwrite old calibration until the new application has been confirmed valid;
- for incompatible migrations, stage new data separately and commit migration only after application confirmation;
- the previous known-good image must be able to start safely after rollback, even if it chooses to invalidate a newer unsupported setting.

This is especially important for future IMU alignment, pressure calibration and magnetometer calibration data.

## Update user interface

A future maintenance page should show at least:

```text
SOFTWARE UPDATE
Current:   0.4.0 (42)
Available: 0.4.1 (47)
State:     Ready to install

[ Install ]   [ Cancel ]
```

During transfer:

```text
SOFTWARE UPDATE — DO NOT POWER OFF
Downloading  63%
Current firmware remains recoverable
```

First boot after update:

```text
VERIFYING NEW SOFTWARE
0.4.1 (47)
```

If rollback occurs, display/log a maintenance message such as `UPDATE FAILED — PREVIOUS SOFTWARE RESTORED`. Do not obscure invalid flight-data annunciations with a normal-looking instrument page while update verification is incomplete.

## Recovery paths

Remote OTA is not the only recovery mechanism. Preserve:

1. **automatic A/B rollback** — primary failed-update recovery;
2. **USB serial/JTAG service recovery** — for corrupted configuration/bootloader/partition-table cases that application OTA cannot repair;
3. documented manual service procedure for identifying current/running/last-invalid partitions and firmware version.

Application OTA should normally update only the application image. Bootloader/partition-table changes are higher-risk service operations and should not be part of the first remote-update implementation.

## Proposed firmware modules

Keep update logic isolated from flight-data code:

```text
firmware/main/
    update_manager.c/.h       state machine and policy
    update_manifest.c/.h      manifest parsing/compatibility
    update_selftest.c/.h      first-boot confirmation gate
    maintenance_wifi.c/.h     explicit maintenance networking
```

`update_manager` should expose state/progress/errors to the UI rather than draw directly. No update module may fabricate or alter attitude/altitude/heading validity.

## Validation plan

### Software/QEMU/unit stage

Can be developed without physical hardware:

- manifest parser and version/hardware compatibility tests;
- update state-machine tests with simulated download results;
- self-test decision tests;
- persistent-schema migration/rollback tests;
- maintenance UI states;
- malformed manifest/image rejection paths.

QEMU success is not evidence of flash/power-loss recovery on the real N16R2.

### Physical bench stage

Required before enabling field use:

- successful A→B and B→A updates;
- corrupt/truncated/wrong-product/wrong-hardware/wrong-signature image rejection;
- Wi-Fi loss at multiple download percentages;
- power removal during download;
- power removal after image selection but before/during first-boot verification;
- deliberate first-boot crash/watchdog and self-test failure;
- confirmation of automatic rollback to the exact previous known-good version;
- NVS/config/calibration compatibility after rollback;
- repeated update cycles and flash-space checks;
- USB service recovery.

Only after these pass should remote updating be considered validated.

## Implementation phases

**Phase 1 — software-only:** custom A/B partition design, manifest/parser, update state machine, maintenance UI and simulated rollback states. No network installation capability enabled in aircraft firmware.

**Phase 2 — hardware bench:** HTTPS OTA to inactive slot, application-controlled rollback confirmation and exhaustive interruption/failure testing.

**Phase 3 — release security:** signed images, release signing procedure, key custody, release manifest generation and production trust policy.

**Phase 4 — optional hardening:** evaluate Secure Boot v2, flash encryption and eFuse anti-rollback after recovery/update procedures are proven and the hardware baseline is stable.

## Current validation status

**DESIGNED / DOCUMENTED — NOT IMPLEMENTED.** No partition table, Wi-Fi maintenance service, OTA downloader, signed-release pipeline or boot confirmation code has yet been added. This capability therefore does not change the current ESP32 EFIS software/emulator baseline and makes no new hardware-validation claim.
