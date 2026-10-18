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
