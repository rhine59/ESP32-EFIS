# RedOne stage-only OTA transport contract — draft, NOT enabled

## Security gate

Firmware writes are **not enabled**. The recovery endpoint `POST /api/recovery/firmware/stage` explicitly returns HTTP 403 and `{ "schema": 1, "result": "LOCKED", "staged": false }`, without reading the request body, opening OTA handles, modifying partitions or selecting a boot target. The read-only firmware inventory continues to report `transferEnabled: false`. This response is a negative safety contract, **not** a functional transfer protocol.

## Required trust model

The current iPhone release signature uses `redone-ed25519-json-v1`: Ed25519 over a canonical JSON payload with sorted keys and unescaped slashes. The ESP32 needs a separately implemented and independently tested verifier for exactly those canonical bytes and the same pinned manufacturer public key(s). It must validate key ID, product, hardware profile, security version, image size, destination partition and signed SHA-256; never accept phone-supplied `verified=true` as authority. Key rotation and rollback prevention need explicit policy. ESP-IDF's default mbedTLS build is not proof of Ed25519 support. Until verified cryptography is available on the ESP32, **all write endpoints remain locked**.

## Planned versioned request sequence

1. `POST /api/ota/v1/sessions`: authenticated, bounded signed envelope, declared image length and digest. Device checks independent Ed25519 signature, compatibility and inactive partition; returns random short-lived session ID, chosen partition, max chunk size and expiry. Invalid input leaves flash untouched.
2. `PUT /api/ota/v1/sessions/{id}/chunks`: authenticated, bounded binary body, exact monotonic byte offset, per-chunk digest and idempotency rule. Device streams into inactive OTA partition using ESP-IDF APIs, never the factory partition. Report durable accepted offset; reject gaps, overlaps, replay and oversized chunks.
3. `GET /api/ota/v1/sessions/{id}`: authenticated progress with accepted bytes, expected total and state (`receiving`, `verifying`, `staged`, `failed`). No implicit activation.
4. `POST /api/ota/v1/sessions/{id}/finish`: finalize OTA write, validate full SHA-256, image header/descriptor, hardware and security version; return `staged` only if every check passes. **Do not call `esp_ota_set_boot_partition` here.**
5. `DELETE /api/ota/v1/sessions/{id}`: cancel and discard incomplete candidate, preserving recovery and currently selected boot partition.

## Safety tests before enabling writes

Reject absent/wrong authentication; unsigned, malformed, expired, wrong-product or wrong-hardware envelope; wrong key; altered canonical JSON; hash mismatch; non-ESP image; wrong target; too-large image; duplicate/reordered chunk; stalled transfer; reconnect; abrupt power loss; out-of-space; reset at each state transition; corrupted OTA metadata. Prove neither factory recovery, bootloader, NVS nor active app is modified. Prove device still boots recovery and exposes diagnostics after each negative test. Only then expose the Push action in Lollipop.

## Bench-only status

This checkpoint adds an explicit locked endpoint and the written protocol contract. It does **not** implement device-side Ed25519, OTA chunk transfer, staging, activation or rollback. No phone firmware Push action is enabled.

## ESP-IDF 5.4.4 Ed25519 capability check (17 October 2026)

Checked the installed ESP-IDF 5.4.4 Mbed TLS headers and library sources. The headers declare the Ed25519 OID and TLS signature identifier, and the PSA headers define the `PSA_ALG_PURE_EDDSA` algorithm identifier. **These declarations do not mean the cryptographic verifier is implemented**: no `PSA_ALG_PURE_EDDSA` implementation references were found in the bundled Mbed TLS library sources, and no project Ed25519 verification implementation or dependency was found. `CONFIG_MBEDTLS_ECP_DP_CURVE25519_ENABLED` concerns Curve25519 support and does not establish Ed25519 verification.

**Decision:** do not substitute X25519/ECDSA or accept a checksum as a signature. Select a maintained, reviewed embedded Ed25519 verifier with a reproducible pinned source/version and license, then test it against RFC 8032 vectors and the exact publisher canonical JSON bytes. Include valid signatures for each trusted key ID and negative tests for tampered fields, altered signature, wrong key, invalid encodings and signature malleability. Run these tests both on host and the ESP32 before opening the staging API. The 1 MiB factory partition size must still fit the recovery build after the dependency is linked.

## Ed25519 verifier integrated (17 October 2026)

Vendored Monocypher 4.0.2, pinned upstream commit `0d85f98c9d9b0227e42cf795cb527dff372b40a4`, including its **optional standard Ed25519/SHA-512 module** (not the incompatible default BLAKE2b EdDSA variant). Original license and upstream provenance retained under `firmware/recovery/components/redone_crypto/`. `redone_verify_release_signature()` verifies the exact caller-supplied canonical payload bytes with pinned `redone-v1` / `redone-v2` public keys, rejects unknown key IDs, null inputs and oversized payloads. **Caller still needs to parse and validate the entire signed envelope and canonicalize it deterministically**; this primitive alone does not authorize OTA writes. Recovery startup now runs an RFC 8032 known-answer self-test before bringing up the Wi-Fi service.

Host test `firmware/recovery/tests/test_ed25519.c` passed RFC 8032 section 7.1 valid signature, changed message, tampered signature, unknown key, incorrect pinned key and empty payload rejection. ESP-IDF firmware build passed; recovery image is `0xc05f0` bytes in a `0x100000` partition, leaving `0x3fa10` bytes (25%) free. **ESP32 on-device self-test, actual publisher envelope verification and negative power-loss tests are not yet validated.** No firmware was flashed and all firmware-changing APIs remain locked.

## Read-only signed-envelope verification checkpoint (17 October 2026)

Implemented `redone_verify_release_envelope()` using bounded cJSON parsing and the pinned Monocypher Ed25519 verifier. It accepts the publisher's nine-field signed payload schema, rejects duplicate/unknown/missing keys, checks the signature format, pinned key ID, RedOne product and hardware profile, HTTPS URL, 64-digit image digest, nonnegative integer build and strict base64 signature. The nine fields are reconstructed in sorted-key order to match the publisher's `json.dumps(sort_keys=True, separators=(',', ':'), ensure_ascii=False)` and Lollipop's sorted-key encoder. Metadata containing non-ASCII/control characters is **deliberately rejected** until cross-language canonicalization tests cover those cases; this is a compatibility limitation, not a silent fallback.

Added `POST /api/recovery/firmware/verify`, authenticated with the existing recovery token. It accepts a maximum 8192-byte JSON envelope and returns only `signatureVerified` and `transferEnabled:false`. This endpoint **does not validate downloaded firmware bytes, authorize transfer, write flash, select a partition or reboot**. The stage endpoint still rejects all requests. Current code must still undergo real publisher-envelope positive/negative integration tests and fuzzing before the write gate can open.

ESP-IDF build passed with a `0xc6bf0` recovery binary, leaving `0x39410` bytes (22%) of the 1 MiB factory partition. Flashed **only** the recovery app at offset `0x20000` on the ESP32-S3 bench board; esptool reported `Hash of data verified` and hard reset. Bootloader, partition table, OTA slots and NVS were not reflashed. A live authenticated verification response from the board has not yet been observed.
