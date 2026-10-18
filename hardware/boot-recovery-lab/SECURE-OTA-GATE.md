# Secure OTA implementation checkpoint

The bench HTTP endpoints `/update`, `/verify`, and `/activate` are **locked** in the newly built source. After token authentication, they return HTTP 403 and do not write flash, change boot selection, or reboot. `/status` remains authenticated and read-only. This is an intentional safety gate: a project-name/image check is **not** a cryptographic signature check.

## Requirements before unlocking

1. Define a canonical signed firmware manifest with trusted signing public key provisioned in the EFIS image, product/hardware compatibility, firmware digest and length, monotonic release/security version, and explicit expiry/revocation policy. Verify signature **on the ESP32**, not solely on the phone.
2. Bind each upload to an authenticated session and validated manifest; stream only to the inactive OTA partition, with length bounds, SHA-256 validation, aborted-upload cleanup and anti-replay/anti-downgrade checks.
3. Re-read the staged image and independently verify hash, application identity, and secure manifest before allowing activation. Ensure activation is a separate confirmed action with explicit on-ground safety warning.
4. Demonstrate automatic rollback after failed health confirmation, power interruption during transfer, and recovery access across OTA A/B. Validate with distinct versions and known-good rollback images.
5. Run bench hardware tests and app integration tests. Keep existing NVS pairing, OTA A/B images, and the recovery partition untouched until a reviewed flash plan is approved.

## Verification scope

The ESP-IDF build and source-level regression test exercise the **new source only**. They do not establish that the currently installed OTA A firmware is locked: no ESP32 flash operation was performed. The iOS transfer and activation buttons remain disabled.

Never use `idf.py flash` for this bench board; it can overwrite bootloader, partition table, OTA metadata and factory recovery. Use only reviewed slot-specific flashing when the hardware test plan permits it.

## Read-only signature verification implemented

The bench OTA application now reuses the recovery firmware's trusted-key Ed25519 verifier and canonical signed JSON envelope parser through the `redone_crypto` component. `POST /firmware/verify-manifest` requires `X-Lab-Token`, accepts at most 8192 bytes, rejects incomplete payloads, and reports `signatureVerified` while always reporting `transferEnabled:false`. It never writes flash or changes boot selection. The existing `/update`, `/verify`, and `/activate` safety locks remain in place.

This checks the **manifest signature and declared hardware/product metadata only**; it does not verify the firmware binary against the signed SHA-256 digest, enforce downgrade prevention, or establish safe staging. Do not enable transfer yet. Built successfully with ESP-IDF; not flashed or hardware-tested.

## Read-only streamed firmware digest

`POST /firmware/hash` authenticates using `X-Lab-Token`, bounds the incoming image to the inactive OTA partition size (minimum 1024 bytes), and computes SHA-256 incrementally in 1024-byte chunks. It returns the digest, received byte count, and `transferEnabled:false`. Incomplete transfers are rejected; no flash writes or boot changes occur. This does **not** bind the image to a signed manifest yet and is not permission to stage it. The signed digest must be compared inside the ESP32 in the same authenticated update transaction before any OTA writes are unlocked. Built and source-tested; not flashed to the physical board.

## Combined signed-image preflight (read-only)

`POST /firmware/preflight` accepts a single authenticated request body: four bytes of **big-endian** unsigned manifest length, followed by the signed JSON envelope, followed by raw firmware bytes. The device validates the signature and hardware metadata before trusting the envelope's SHA-256 claim, then streams the firmware into SHA-256 in 1024-byte blocks and compares the digest to the authenticated claim. The manifest is capped at 8192 bytes and the firmware at the inactive slot capacity; incomplete streams fail. The response distinguishes a verified signature and matching/mismatching firmware digest and **always** says `transferEnabled:false`. No flash writes, boot selection, or persistent authorisation are performed.

This preflight still does **not** guarantee safe OTA deployment: release anti-downgrade policy, interrupted-write recovery, staged-image re-read, activation confirmation, and automatic rollback remain to be implemented and bench-tested. The live device has not been flashed.

## Stage 5: offline staging policy state machine

Added `components/redone_ota_guard` as a pure C, host-testable staging policy. It requires authenticated, signed and inactive-slot inputs, enforces partition capacity and exact byte counts, aborts on interrupted/oversized streams, compares streamed and flash-readback SHA-256 against the signed digest, and requires separate on-ground confirmation and rollback readiness before activation can be authorised. The state machine **does not call ESP-IDF OTA or partition write APIs**, and is not connected to the live HTTP update route. This is a policy foundation, not an implementation or validation of physical flash staging or automatic rollback. An unexpected reset clears in-memory staging state; no activation is possible without revalidation.

Remaining: integrate with OTA writes only after a reviewed persistent transaction protocol, signed release monotonicity, on-device flash readback, boot-health confirmation, automatic rollback and power-cut hardware testing. Current HTTP mutation routes remain locked.

## Stage 6: injectable staging transport and fault tests

Added `ota_staging.c/.h`, a transport-neutral coordinator around the Stage 5 policy guard. A storage adapter must implement begin, write, readback digest and abort. It refuses unverified, unauthenticated, wrong-slot or oversized transfers; checks exact byte counts; rejects simulated write and readback failures; and requires the streamed SHA-256 and stored-image readback SHA-256 to match the signed digest. Host fault-injection tests cover interrupted transfer, write failure, premature finish, readback failure and success. This component is compiled into the ESP-IDF project but is **not wired to the HTTP upload endpoint**. No actual flash writes or physical power interruption have been tested. Existing mutation endpoints remain locked; boot/recovery partitions are untouched.

## Stage 7: isolated ESP-IDF inactive-slot backend

`main/ota_esp_storage.c` implements the Stage 6 storage callbacks using ESP-IDF OTA begin/write/end/abort. Before begin and each write it checks that the selected target is the next-update OTA application partition, is not the running partition, and is never the factory recovery slot. On completion it calls `esp_ota_end` for ESP image validation, then reads back exactly the received image length using `esp_partition_read` and computes SHA-256. It does not set boot selection, reboot, erase factory/recovery, or change NVS.

**This adapter is compiled but intentionally not called by HTTP routes.** There is no physical flash staging or power-cut validation yet. Source guards verify mutation endpoints stay locked. Before enabling the adapter, review ESP-IDF error semantics (including `esp_ota_end` failures), interrupted-write recovery, firmware version policy, and a controlled bench test with recovery verified. Never use generic `idf.py flash` on the provisioned board.

## Stage 8: staging integration experiment (not routable)

Added `signed_staging_dry_run()` as an **unregistered static function** in the bench firmware. It is based on the authenticated signed-manifest preflight protocol, decodes the authenticated digest, selects the inactive OTA slot, streams firmware through the Stage 6 staging coordinator and Stage 7 ESP-IDF adapter, and compares streamed and flash-readback hashes. It is deliberately **not registered with the HTTP server and is not callable by users**. Despite its name, it would write flash if deliberately invoked in a future code change; do not call it for dry-run testing. The existing `/update`, `/verify`, and `/activate` routes still reject mutation. The currently running physical board is unchanged.

Before registering any staging route: review release downgrade protection, guarantee signed claims are extracted from the exact verified payload, implement safe persistent transaction handling and rollback health checks, validate ESP-IDF `esp_ota_end` behaviour, and conduct physical bench power-interruption testing. No hardware staging tests have been performed.

## Stage 9: boot confirmation hardening and downgrade policy

Removed the automatic `esp_ota_mark_app_valid_cancel_rollback()` call from bench startup: `PENDING_VERIFY` images remain pending until meaningful health checks are implemented. Manual `boot0`/`boot1` console boot switching is compiled out by default and requires an explicit unsafe build-time macro to restore. This prevents accidental bypass of the signed staging policy. A pure host-tested `ota_version` policy rejects unsigned claims, invalid build numbers, same/older versions, and candidates below the signed minimum or persistent installed floor.

**Not yet wired to production:** signed manifest `minimum_allowed_version` is currently a version string rather than a verified integer build floor; the installed monotonic floor is not yet persisted, and no signed-release metadata is bound to the policy. Do not enable OTA staging or activation until these are resolved. No physical device update or rollback test was performed.

## Stage 10: trusted signed-release metadata extraction

The shared recovery cryptography component now provides `redone_verify_release_metadata()`. It returns the signed build number, 32-byte binary SHA-256 and minimum allowed version string only after Ed25519 verification; failed verification clears the output. The existing signature-only API delegates to the same verifier. The unregistered experimental staging handler consumes this trusted digest rather than independently reparsing the signed envelope. The minimum version remains a string and cannot safely be treated as a monotonic build number; trusted installed-floor persistence and boot-health rollback validation are still required. No HTTP mutation endpoints were unlocked, and no physical firmware was flashed.

## Stage 11: fail-closed boot-health evidence policy

Added `ota_boot_health.c/.h` with seven independent health predicates and a pending-image-only confirmation gate. Host unit tests test the successful case and each missing predicate; bench startup currently supplies false for unavailable physical sensor/display/power/rollback/ground evidence and leaves the image pending. No call to `esp_ota_mark_app_valid_cancel_rollback()` has been added. This is a **policy** implementation, not physical rollback or boot-health acceptance testing. The signed staging endpoint and boot activation remain locked.

## Stage 12: authenticated, read-only live boot-health snapshot

Added `GET /boot-health` to the bench HTTP server. It requires the provisioned NVS token and reads the actual running partition, next OTA partition, ESP-IDF boot state and compiled application descriptor. It exposes distinct evidence flags and `mayConfirmBoot`, but does not call any OTA mutation, boot confirmation or reboot API. Physical sensor, display, supply, rollback, self-test and on-ground evidence remain explicitly `false` until validated measurement sources are implemented. The endpoint is **compiled but not deployed to the physical board**. The existing `/update`, `/verify`, `/activate` routes remain locked. This is observability, not proof of rollback.

## Stage 13: signed build-floor format

A strict host-tested parser accepts only build:<nonnegative int32> notation. It rejects ambiguous versions and overflow. It is not yet connected to the publisher or the OTA staging flow, because persistent trusted build-floor storage and signed manifest migration are pending. No physical flash occurred.

## Stage 14: fail-closed version gate before staging

The experimental, unregistered staging handler now verifies signed release metadata, strictly parses `minimum_allowed_version` as `build:<int32>`, and evaluates the anti-downgrade policy **before** selecting the inactive OTA slot or beginning any write. Trusted persistent floor and running-build provenance are not yet implemented; explicit unavailable sentinels force rejection. This is intentional: existing published manifests use legacy semver minimums (e.g. `0.0.0`) and are not compatible with the new parser. Publisher schema migration and secure floor provisioning require separate design and verification. No write route was enabled.

## Stage 15: publisher metadata policy

The OTA Admin now checks `build:<int32>` minimums and candidate build bounds on upload and again before publication. This is input validation, not device-side monotonic storage. Legacy published manifests are unchanged, and the shell publisher helper is not yet migrated. OTA device staging/activation remains disabled.

## Stage 16: consistent publisher validation

The legacy shell staging helper now uses the OTA Admin's strict signed-build policy before file operations. Both publisher interfaces reject incompatible version claims. Device-side trusted monotonic floor, activation and physical rollback remain blocked.
