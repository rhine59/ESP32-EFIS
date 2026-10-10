# RedOne EFIS boot, A/B OTA and independent recovery

Status: **approved architectural direction, not yet implemented or bench-validated**. Target: ESP32-S3-WROOM-1-N16R2 (16 MB flash). RedOne/EFIS is a secondary, non-certified instrument. Git is the authoritative source.

## Decision

Use the ESP-IDF second-stage bootloader, OTA selection metadata, two complete application slots (`ota_0` and `ota_1`), persistent configuration storage, and a minimal factory/recovery application **if it fits the measured flash budget**. Keep the ESP32-S3 silicon ROM download mode and accessible native USB-C/BOOT/RESET hardware as the final fallback. Recovery firmware is not a third full EFIS operating system.

Normal firmware updates run from the active EFIS slot and stream a signed image to the inactive slot. Validate the image and hardware/EFIS-SMUX compatibility before selecting it for the next boot. Enable ESP-IDF OTA rollback: the newly booted image performs critical startup checks and explicitly marks itself valid only when successful; otherwise the bootloader can revert to the previous known-good slot. The next update uses whichever application slot is inactive. Never erase the currently executing application during normal OTA.

## Recovery independence and limits

The recovery application must not depend on either EFIS application, the EFIS flight-display code, CAN/sensor services, licence activation, the NAS, internet access, or a working phone application. It provides only Wi-Fi SoftAP, authenticated local transfer, image signature/integrity verification, partition programming, progress/failure reporting, and reboot. It *does* still depend on flash integrity, the partition table and second-stage bootloader; therefore it is not an absolute recovery guarantee.

ESP32-S3 ROM download mode is the separate last-resort path. Provide an externally accessible USB-C connection and a reliable means to assert the boot strap and reset lines. A service computer can reflash bootloader/partition table/applications when ordinary flash boot paths are damaged, **provided the selected secure-boot, flash-encryption, eFuse and ROM-download security policies permit it**. These irreversible security decisions must be settled and tested before production; never assume ROM download remains available after security lockdown.

## Entry mechanism — design work required

A recessed RECOVERY button held during power-on should request the factory recovery image. **Stock ESP-IDF does not automatically route a GPIO button to the factory partition.** Design and bench-test a reliable selection mechanism (such as a carefully constrained custom bootloader or other supported boot selection scheme), and verify behaviour when OTA metadata and both application slots are invalid. Avoid routine field bootloader updates. Provide a clearly documented alternate route to ROM USB download mode. Do not claim physical-button recovery until this has passed fault-injection tests.

## Offline recovery workflow

1. Power off, hold recessed RECOVERY, and power on.
2. Recovery firmware boots independently and starts a per-device authenticated Wi-Fi SoftAP (illustrative SSID `Lollipop-EFIS-Recovery-XXXX`; no shared default password).
3. Lollipop for iOS/Android joins the local recovery network and selects a trusted signed firmware package already on the phone. No internet or Synology service is required at the aircraft.
4. Recovery firmware checks package signature, product/hardware revision, image size, security version and EFIS/SMUX compatibility metadata. It rejects incompatible or downgraded packages according to the approved policy.
5. Stream to a suitable application slot with bounded buffers, checksum/progress reporting and power-loss-safe OTA metadata transitions. Never write recovery, bootloader or partition-table regions as part of an ordinary EFIS update.
6. Set the selected application as next boot, reboot, perform EFIS self-tests, and confirm the image only after critical checks pass. If it fails, retain a reachable recovery path and report the failure clearly.

Recovery should be possible from a phone, but **not depend exclusively on a phone**: USB ROM flashing remains a service procedure. An inaccessible/failed display must not block recovery; provide LED/status codes or another minimal observable indication.

## Storage and compatibility

Measure actual signed EFIS firmware sizes and recovery firmware size before defining partition offsets. Include bootloader, partition table, `otadata`, NVS, calibration, licence/commissioning state, optional filesystem assets, alignment and future growth allowance in the 16 MB budget. Keep persistent settings and licence material outside A/B application partitions. Use versioned configuration schemas, backups/migration rules and rollback-safe state handling. A firmware rollback must not silently corrupt or invalidate commissioned sensor settings. A/B rollback is not equivalent to reverting SMUX firmware; enforce an explicit compatibility matrix and staged update/rollback strategy across EFIS and SMUX.

## Security and operational requirements

- Signed images with a pinned trust root; secure boot and flash encryption policy designed together with ROM-recovery requirements.
- Authenticated local recovery Wi-Fi and upload, per-device credentials, anti-replay and bounded update attempts; no open unauthenticated flashing endpoint.
- Hard limits on upload size, transfer time and memory; verify entire image before activation; do not trust metadata alone.
- No update activation during flight; require a deliberate maintenance state and adequate supply voltage.
- Distinct status for download, verification, write, activation, rollback and recovery; preserve safe diagnostic evidence without exposing secrets.
- Recovery image and bootloader updates are exceptional factory/service procedures with separately tested fallback and power-failure controls.

## Bench acceptance tests (mandatory before freezing layout)

1. Valid A→B and B→A updates, with no loss of licence/commissioning data.
2. Interrupted transfer and power removal during write/metadata update: last known-good app remains bootable.
3. Invalid signature, wrong product/revision, oversized image, unsupported security version and incompatible SMUX image are rejected.
4. New application crash, watchdog reset and failed health check before confirmation cause rollback.
5. Both EFIS slots unusable: recovery button still boots the recovery application and installs a signed image offline.
6. Corrupt `otadata` and invalid partition selection: recovery entry remains deterministic.
7. Broken recovery app, corrupt bootloader and corrupt partition table: ROM USB service recovery works under the chosen production security settings.
8. Wi-Fi interrupted, phone killed, low-voltage event, repeated attempts, and no working display do not brick the device.
9. iOS and Android Lollipop complete the same recovery workflow; EFIS/SMUX dependency and rollback scenarios are tested.

## Open engineering gates

- Exact 16 MB partition table and firmware growth allowance after compiling real images.
- Recovery-button electrical interface and boot-selection implementation.
- Secure boot / flash encryption / anti-rollback / eFuse / ROM-download policy, including field-service provisioning.
- Recovery image signing/update policy and separate recovery credential provisioning.
- Offline phone package storage, verification UX and Android/iOS parity.
- Definition of critical boot-health checks and maximum rollback attempts.

This is a design decision and test plan, **not** a claim that a third partition alone guarantees independent recovery.
