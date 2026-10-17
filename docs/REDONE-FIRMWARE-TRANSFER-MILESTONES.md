# RedOne firmware distribution, installation and recovery — implementation checkpoints

## Checkpoint 1: authenticated device inventory (implemented)

The recovery firmware now provides `GET /api/recovery/firmware` on the per-device WPA2 access point. It uses the same `X-RedOne-Recovery-Token` authentication as diagnostics. The response contains schema, device identity, running partition label, A/B image versions or `not installed`, A/B partition capacities, and explicit `transferEnabled`, `activationEnabled`, `rollbackEnabled` booleans, all **false**. It reports why changes are locked. This is a read-only endpoint: it does not erase, stage, select or reboot any firmware image. The Lollipop Diagnostics page offers **Inspect RedOne firmware slots** and displays the live response. Authentication uses the previously paired recovery QR credentials stored in the iOS Keychain.

The endpoint is an inventory aid, not a secure attestation: a compromised device can lie about its state. Image versions are read from ESP-IDF application descriptors, which do not by themselves establish a valid image signature or bootability. The firmware must independently verify all signed release claims before accepting an upload.

## Existing phone-side release preparation

The iOS firmware library stores signed release envelopes, verifies Ed25519 signatures against pinned public keys and verifies downloaded firmware SHA-256 against the signed envelope. Release preparation works offline once downloaded. The current publisher and signing policy must still be audited for production key management, anti-rollback, hardware profile and SMUX compatibility. An untrusted local file must never become installable merely because its hash is displayed.

## Checkpoint 2: stage only (not yet implemented)

Implement a versioned, authenticated transfer API with bounded chunks and explicit transfer ID, length, offset, hash, expiry and replay controls. Device must independently authenticate the signed release envelope using its own pinned public key and enforce hardware profile, image size, secure version and compatibility. Stream into an inactive OTA partition using ESP-IDF OTA APIs; never write factory recovery, bootloader, NVS, partition table or the active app. Preserve the old application throughout. Interrupted transfers must leave a known-good boot path. Finish with device-side full-image hash and signature checks and report `staged`, but do not select the new boot partition automatically.

## Checkpoint 3: activate, health check and rollback (not yet implemented)

Require deliberate maintenance mode, voltage gate, explicit confirmation and verified staged image. Select the staged OTA partition, reboot and use ESP-IDF pending-verify/mark-valid APIs only after startup self-tests. Exercise watchdog reset, bad image and power interruptions to confirm fallback. Persist update audit metadata separately from mutable app slots. Protect against incompatible persistent configuration migrations and SMUX version mismatches.

## Checkpoint 4: independent recovery and final fallback (not yet proven)

Validate deliberate physical recovery entry without depending on either normal app, including corrupt OTA selection data and both normal slots unusable. A GPIO recovery button does not automatically select factory in stock ESP-IDF. Maintain tested USB ROM recovery, subject to chosen eFuse/secure-boot/flash-encryption policy. Do not ship a custom bootloader or permanently lock download access until a sacrificial board has passed these tests.

## Validation of checkpoint 1

ESP-IDF recovery build and iOS device build succeeded. Recovery application-only flash at `0x20000` completed and esptool verified the written hash; bootloader, partition table and NVS were not rewritten. An end-to-end response from Lollipop remains to be observed on the phone. Firmware-changing controls remain disabled.
