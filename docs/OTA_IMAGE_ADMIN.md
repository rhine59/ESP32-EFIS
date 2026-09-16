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
