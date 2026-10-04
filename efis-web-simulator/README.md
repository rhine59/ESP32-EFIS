# Horizon EFIS Web Simulator

Containerised browser emulator for the Horizon boot/maintenance menus. Its purpose is to exercise OTA firmware and licensing services without physical ESP32 hardware.

## Scope

The simulator mirrors the rotary/push boot UX and uses a synthetic device identity. It deliberately does **not** emulate flight sensors or claim to validate flight firmware.

Current menu:

- START EFIS
- FULL TEST
- FAULT LOG
- LICENSE
- FIRMWARE UPDATE

LICENSE exercises status/install/reset flows. FIRMWARE UPDATE exercises Wi-Fi state, manifest checking, download, staged firmware and explicit ACTIVATE & REBOOT. A test panel can inject network/device states and inspect the event log.

## Run

```sh
docker compose up --build
```

Open `http://localhost:8093`.

## Service integration

Browser calls the simulator backend only. Configure upstream service URLs in Compose/environment; do not put admin/signing credentials in browser JavaScript.

- `OTA_BASE_URL`: public OTA origin. Manifest endpoint defaults to `/efis/manifest.json`.
- `LICENSE_BASE_URL`: customer/device licence service base URL. API paths are intentionally adapters/placeholders until the account/licence service contract is frozen.
- `SIM_ALLOW_MUTATIONS`: keep false against production services.

Default mode is safe mock mode and works without either upstream.

## Controls

Use the on-screen rotary buttons or keyboard: Up/Down = rotate, Enter = short press, Escape = back. State persists in the container only as test state and may be reset.

The circular display is a hard layout constraint, not a rectangular browser viewport. Maintenance menus must keep every selectable item fully visible inside the safe central area of the round display. The firmware-update view therefore uses compact typography, line spacing and margins so `ACTIVATE & REBOOT` and `BACK` remain visible without scrolling or clipping.

## Safety

Never configure the simulator with the private licence signing key, signer token, OTA admin session secret, payment secrets or real aircraft credentials. It is a client/service test harness, not an admin control plane.


## Multi-node offline OTA simulation

The simulator now exposes Horizon and EIU installed versions, release-set caching, local maintenance-network state, transfer/staging and dependency-ordered activation. The default mock release demonstrates EIU 1.7 -> 1.9 before Horizon 2.4 -> 2.5, with Horizon checking the required EIU capability before completing its own activation.

This models control flow only. It is not evidence of physical Wi-Fi, flash, A/B boot or CAN behaviour.


## Health check

The Compose service has a Docker health check against the simulator's internal `/api/state` endpoint. After startup, `docker compose ps` should report `(healthy)`. The check runs inside the container and does not depend on the Synology host-port assignment.


## Real OTA integration

When `OTA_BASE_URL` is set, firmware testing uses the real public OTA service rather than a synthetic manifest. The simulator requires maintenance Wi-Fi to be set online, retrieves `/efis/manifest.json`, validates the product and required fields, rejects the repository's unpublished CHANGE-ME/REPLACE placeholder, downloads the referenced firmware image, calculates SHA-256 over the received bytes, and refuses staging if the digest differs from the manifest. Only a verified cached image can be staged; activation remains a separate explicit action.

This path is intentionally read-only against the OTA server: it consumes the same public manifest/image interface as Horizon and does not need the OTA admin secret. A real release must be published before the live path can complete successfully.

For Synology deployment, set `OTA_BASE_URL` to an address reachable **from inside the simulator container**. Do not assume the NAS public hostname will hairpin back through the router; verify reachability from the container before relying on it.


### Synology OTA network

The Synology deployment joins the existing external Docker network `ota-server_default` and defaults `OTA_BASE_URL` to `http://esp32-efis-ota:8080`. This keeps simulator-to-OTA traffic inside Docker and avoids NAS public-hostname/NAT-loopback dependencies. The OTA admin container/network endpoint is not used.


## Live development licence integration

Start `../license-service/compose.yml` first. The simulator joins the external `efis-license` Docker network and defaults to `http://esp32-efis-license-service:8080`.

`LICENSE -> GET / REFRESH` now exercises the real development vertical slice: one-time challenge, HMAC proof of the synthetic provisioned device credential, entitlement lookup, deterministic-CBOR Ed25519 issuance, local signature/schema/product/Device-ID verification, then installation. The signer private key never enters the simulator. The trust-key HTTP bootstrap is explicitly simulation-only; production EFIS provisioning must embed/provision the trusted public key independently.

The browser's **Install mock licence (bypass)** control remains only for isolated UI testing and must not be counted as licence validation.

## Licence persistence and offline boot verification

A successfully retrieved signed licence is now stored in the simulator's `efis_sim_state` Docker volume as the original base64url-transported CBOR envelope. The simulation-only public verification key used for that licence is cached separately in the same persistent volume. On process/container startup the simulator reloads the stored artefact and re-verifies the Ed25519 signature, schema, product and immutable Device ID locally before restoring `VALID`; no licence-service or Wi-Fi access is required for this boot check.

Installation uses candidate-first semantics: the downloaded licence is fully verified before the persistent file is atomically replaced. Licence Reset removes the persisted installed licence. This models the intended ESP32 protected-NVS lifecycle, but Docker-volume persistence is not evidence of ESP32 NVS security, atomicity or flash behaviour.

### Persistence runtime result

**PASS — 4 October 2026.** After acquiring a signed DEVELOPMENT licence into the persistent store, the simulator was set offline and its container restarted. It returned `VALID` with network offline, confirming that startup can reload and locally verify the persisted signed licence without contacting the licence service. Physical ESP32 NVS/power-loss behaviour remains unvalidated.
