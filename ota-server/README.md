# ESP32 EFIS OTA image server

The OTA server has two deliberately separate services: a **public read-only firmware origin** and a **private firmware administration service**. GitHub remains the source/build history. The Docker server distributes only administrator-published EFIS application images.

## Services and trust boundary

```text
EFIS -> Internet HTTPS :443 -> Synology reverse proxy -> 127.0.0.1:8080 -> nginx read-only origin
Admin -> LAN/VPN/SSH/private proxy -> 127.0.0.1:8090 -> OTA Admin -> public/ read-write
```

Never expose ports 8080 or 8090 directly to the Internet. Public TLS terminates at Synology (or another trusted HTTPS proxy). The admin endpoint requires a private/authenticated access boundary.

## Persistent repository

```text
public/efis/
├── manifest.json                 # exactly one PUBLISHED release
├── releases/<version>/*.bin      # staged/published/archived binaries
└── release-metadata/<version>.json
```

The nginx container mounts this read-only. The admin container mounts it read/write.

## Build and start on Synology

The repository now includes `docker-compose.yml` for the complete two-container stack. Run these commands from an SSH session on the Synology after cloning/pulling the repository:

```bash
cd ESP32-EFIS/ota-server
cp .env.example .env              # first deployment only
openssl rand -hex 32               # copy result into ADMIN_SESSION_SECRET in .env
# edit OTA_PUBLIC_BASE_URL in .env to the final HTTPS update hostname

docker compose config
docker compose build --pull
docker compose up -d
docker compose ps
curl -fsS http://127.0.0.1:8080/healthz
curl -fsS http://127.0.0.1:8090/healthz
```

Expected local health responses are `ok` from the read-only origin and JSON containing `status: ok` from the admin service. Both published ports are deliberately bound to `127.0.0.1`; do not change them to public interfaces. Synology reverse proxy should expose only the read-only origin through HTTPS.

Set `OTA_PUBLIC_BASE_URL` to the stable public HTTPS hostname and generate `ADMIN_SESSION_SECRET` with `openssl rand -hex 32`. Do not commit the real `.env`.

## Stage a newly built EFIS binary

**Staging and publishing are separate.** The historical helper filename `publish-release.sh` is retained for compatibility, but it now stages only and prints `STAGED ONLY — NOT PUBLISHED`.

When the binary is already on the Synology/repository filesystem:

```bash
cd ESP32-EFIS/ota-server
./scripts/publish-release.sh 0.4.2 52 ../firmware/build/esp32_efis.bin 0.4.0 "Release notes"
```

This copies the binary to a versioned directory, calculates SHA-256 and creates per-release metadata. It refuses to overwrite an existing version and **does not alter `manifest.json`**.

If the binary was built on the Mac but the Docker server runs on Synology, transfer it first (example):

```bash
scp ~/Documents/Xcode/ESP32-EFIS/firmware/build/esp32_efis.bin <nas-user>@<nas-host>:/tmp/esp32_efis.bin
ssh <nas-user>@<nas-host>
cd <path-to>/ESP32-EFIS/ota-server
./scripts/publish-release.sh 0.4.2 52 /tmp/esp32_efis.bin 0.4.0 "Release notes"
```

The exact command supplied for each future EFIS binary should substitute the real version, build, binary path and minimum version rather than copying these example numbers.

## Publish for EFIS consumption

Open the **private OTA Admin dashboard** on port 8090 through LAN/VPN/SSH/private authenticated reverse proxy. Review the staged version/build/hash/release notes, then select **Publish**. Publish atomically changes the public manifest. Upload/stage alone never makes a release consumable by EFIS units.

A retained older release may be republished if the advertised release must be withdrawn. The currently published release cannot be deleted.

## Public deployment

Create public DNS such as `efis-updates.example.net`, attach a valid certificate in DSM, and reverse proxy HTTPS :443 to `http://127.0.0.1:8080`. Forward only TCP 443 where inbound hosting is available. If behind CGNAT use a deliberately configured trusted HTTPS tunnel/reverse proxy. Do not expose DSM/Docker administration.

Field path:

```text
ESP32 EFIS -> iPhone Personal Hotspot -> Internet -> HTTPS :443 -> Synology -> nginx OTA origin
```

The phone is a network gateway only. Hotspot credentials stay in EFIS NVS and are never sent to the OTA server.

## Verify public consumption

```bash
curl -fsS https://efis-updates.example.net/healthz
curl -fsS https://efis-updates.example.net/efis/manifest.json
```

Test from outside the LAN as well. A published release may be automatically **downloaded** by an EFIS configured for auto-download, but activation/reboot always requires explicit `ACTIVATE & REBOOT` on the instrument.

## Diagnostics

```bash
docker compose ps
docker compose logs --tail=100 efis-ota
docker compose logs --tail=100 efis-ota-admin
docker inspect --format='{{json .State.Health}}' esp32-efis-ota
curl -v http://127.0.0.1:8080/healthz
curl -v http://127.0.0.1:8090/healthz
```

## Security

Do not put GitHub tokens, signing private keys or Wi-Fi credentials in either image. SHA-256 is an integrity check, not publisher authentication. Production firmware still requires signed-image verification. The signing private key remains outside repository, containers and EFIS filesystem. Public manifest/binaries may be readable; secrecy is not a security control.

The current admin application relies on LAN/VPN/private-proxy access as its authentication boundary. Before any public multi-user administration, add proper authentication, CSRF protection, audit records, upload limits and preferably signed-image verification before Publish.

## Validation status

**IMPLEMENTED / DEPLOYMENT UNVALIDATED.** Static origin, private admin container, deployable Compose stack, staged release metadata, explicit Publish and stage-only CLI helper are in source control. They have not yet been built/exercised on the Synology. Real ESP32 HTTPS download, A/B flash, activation and rollback remain hardware-unvalidated. See `../docs/OTA_IMAGE_ADMIN.md`, `../docs/OTA_USER_SCENARIO.md`, `../docs/PHONE_NETWORK_AND_PUBLIC_OTA.md` and `../docs/REMOTE_UPDATES.md`.
