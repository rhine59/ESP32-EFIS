# ESP32 EFIS — Hosted firmware administration and definitive OTA workflow

**Status:** admin workflow and simulator implemented; Synology/physical ESP32 validation pending.

## Policy

ESP32 EFIS separates **Upload**, **Publish**, **Download**, and **Activate**. These are independent decisions.

```text
Git/build -> approved .bin -> ADMIN UPLOAD -> STAGED
                                      |
                               explicit PUBLISH
                                      v
                               public manifest
                                      |
                         EFIS discovers release
                           /              \
                    auto-download ON   manual
                           \              /
                            verified inactive slot
                                      |
                           ACTIVATE & REBOOT
                                      |
                           first-boot self-test
                              /          \
                           PASS          FAIL
                            |              |
                         accept         rollback
```

Publishing never causes an EFIS to reboot. Automatic download never means automatic activation.

## Docker administrator

The private browser dashboard manages the actual firmware images hosted by the OTA Docker server. Uploading an approved `.bin` creates a **STAGED** release and records version, build, minimum allowed version, release notes and server-calculated SHA-256 in per-release metadata. Upload does not change the public manifest.

An explicit **Publish** action atomically changes `manifest.json`. The previously published image remains hosted and becomes archived/staged. Any retained older version can be deliberately republished, providing an administrative release rollback. The currently published version cannot be deleted.

The public nginx service remains read-only. The admin service alone has read/write access to `ota-server/public`. Admin port `127.0.0.1:8090` remains private; public EFIS downloads use the HTTPS reverse proxy to the read-only origin on `127.0.0.1:8080`.

## EFIS user behaviour

The normal user has one persistent preference:

```text
Automatically download next update   ON/OFF
```

Default is **ON**. Automatic activity is permitted only in the maintenance/network-update context, never as an unannounced flight operation.

With automatic download ON, a compatible administrator-published release is downloaded to the inactive OTA slot and verified. It is then left dormant. The user sees a deliberately simple decision:

```text
SOFTWARE UPDATE READY
Version 0.4.2
Downloaded and verified

[ ACTIVATE & REBOOT ]
        Later
```

There is no automatic activation or automatic reboot. With automatic download OFF, the user first sees the available release and selects **Download**; after verification the same **ACTIVATE & REBOOT** decision is presented.

Activation selects the candidate OTA slot and reboots. The candidate remains pending until the mandatory first-boot self-test succeeds. Success marks it known-good. Failure/crash/reset before confirmation invokes the A/B rollback design and restores the previous known-good application.

## Administrator release workflow

1. Build/test an intended firmware image separately.
2. Open the private OTA Admin dashboard.
3. Upload the approved `.bin`; it becomes STAGED only.
4. Review version/build/release notes/SHA-256.
5. Select **Publish** deliberately.
6. Confirm the public HTTPS manifest identifies the intended release.
7. EFIS units may now discover/download it according to their preference.
8. Each user still explicitly selects **ACTIVATE & REBOOT**.

A bad publication can be withdrawn by republishing a retained previous image. Devices that already downloaded a newer candidate must still apply compatibility/policy checks before activation; production implementation should support invalidating a withdrawn candidate when the manifest changes.

## Persistent server data

Back up:

```text
ota-server/public/efis/manifest.json
ota-server/public/efis/releases/
ota-server/public/efis/release-metadata/
```

Containers remain disposable/rebuildable from Git.

## Security

Staging/publishing is not firmware signing. Production images still require the signed-image trust model in `REMOTE_UPDATES.md`. Signing private keys never belong in the Docker admin container. The admin UI stays behind LAN/VPN/private authenticated reverse proxy; its Flask session secret is not user authentication.

Before any Internet-facing multi-user admin deployment add authentication, CSRF protection, audit history, upload limits and preferably signed-image verification before Publish.

## Validation

The Docker admin code now implements separate staging and publishing, per-release metadata, SHA-256 calculation, republishing and protected deletion. The Swift simulator implements automatic-download preference, manual download, verified-ready state, explicit **ACTIVATE & REBOOT**, first-boot success and rollback simulation.

**Not yet validated:** Docker build/runtime on Synology, public reverse-proxy deployment, physical ESP32 download/flash, real A/B boot selection, interruption recovery or signed-image verification. Simulator behaviour must not be represented as physical OTA validation.


## Remote EIU firmware delivery — 1 October 2026

Horizon is the update gateway for the Stage-7 EIU. Production flow is:

`signed release service -> Horizon OTA client -> local verified staging -> AEF-CAN maintenance transfer -> EIU inactive A/B slot -> EIU verification -> explicit activation -> health confirmation/rollback`.

The EIU is not provisioned with Internet/Wi-Fi credentials. Release metadata must distinguish Horizon images from EIU images and declare target product, supported hardware/board revision, minimum bootloader/protocol compatibility, version, size, digest and signature information.

Horizon verification before CAN transfer is required but is not the final trust boundary: the EIU independently authenticates the image before boot. EIU persistent sensor mappings/calibration/identity remain outside the application slots.

Extend the existing simulator/admin harness with an emulated EIU target and at least two visibly/version-distinct test images. Exercise successful update, wrong-hardware rejection, corrupt image/hash failure, interrupted transfer, activation, first-boot failure and rollback, EIU disappearance/reappearance, and preservation of commissioned configuration. Keep these results explicitly labelled simulation until real transceivers, real flash A/B behaviour and interruption tests pass on hardware.


## Simulated EIU OTA implementation — 1 October 2026

The first executable transport-neutral EIU update state machine is in `ota-server/admin/eiu_ota_sim.py`, with regression coverage in `ota-server/admin/test_eiu_ota.py`. The normal `scripts/rebuild-and-test.sh` runner now executes this suite inside the admin image after the existing isolated OTA-admin tests.

Current simulation covers discovery/version reporting, target-hardware rejection, segmented transfer, end-to-end SHA-256 corruption detection, inactive-slot staging, RPM=0 activation gate, successful first-boot confirmation, failed-first-boot rollback and preservation of commissioned sensor configuration. Test payloads deliberately identify two distinct simulated releases (`EIU-V2-GREEN-LED` and `EIU-V3-BLUE-LED`).

This remains a software model. It does not yet implement AEF-CAN frame segmentation, cryptographic signature verification, resume after interruption, ESP32 partition-table flashing or physical bootloader rollback. Those are subsequent gates and must not be described as hardware-validated.


## Two-stage download checkpoints — 1 October 2026

Both firmware-delivery legs are checkpointed.

**Release service -> Horizon:** Horizon stages firmware persistently and records absolute downloaded offset/image identity so an interrupted network download can resume rather than restart. The complete staged image must pass digest/signature verification before it is offered to the EIU.

**Horizon -> EIU:** AEF-CAN DATA remains sequence checked and the EIU durably commits the inactive-slot candidate in 4 KiB blocks. Each checkpoint binds the transfer/image identity to the committed byte offset and block integrity. On restart Horizon queries the EIU and resumes only when identities match.

The UI may display percentage, but the stored/protocol state is always an absolute byte offset. Final whole-image verification remains mandatory even when every intermediate checkpoint passed.
