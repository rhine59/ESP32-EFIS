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
