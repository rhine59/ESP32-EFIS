# ESP32 EFIS — Hosted firmware image administration

**Status:** implemented in Docker configuration; deployment validation pending.

## Purpose

This is the administrator interface for the **firmware images hosted by the OTA Docker server**. It is not an instrument configuration page and it is not intended for EFIS devices to access.

The public and administrative paths are deliberately separated:

```text
ESP32 EFIS -> HTTPS public update hostname -> nginx download container -> manifest/.bin (read only)
Administrator -> private DSM/VPN route -> admin container -> same public/ volume (read/write)
```

The public nginx service remains read-only. The admin service is the only network application allowed to modify `ota-server/public`.

## Functions

The browser dashboard lists hosted versions, file size, SHA-256 and the currently advertised version. It can upload a new approved `.bin`, enter version/build/minimum-version/release notes, calculate SHA-256 server-side, create the versioned release directory, atomically replace `manifest.json`, make an older hosted image current, and delete an image that is not current. The current advertised image cannot be deleted.

Uploading a new image immediately makes it the advertised release. This does **not** install it on an EFIS: the instrument still requires an explicit maintenance-mode check/review/install action.

## Deployment

Create `ota-server/.env` on the Synology from `.env.example`:

```bash
cd ESP32-EFIS/ota-server
cp .env.example .env
openssl rand -hex 32
```

Put the random value in `ADMIN_SESSION_SECRET` and set `OTA_PUBLIC_BASE_URL` to the real public HTTPS update origin. Do not commit `.env`.

Then rebuild/start both services:

```bash
docker compose build
docker compose up -d
docker compose ps
curl http://127.0.0.1:8080/healthz
curl http://127.0.0.1:8090/healthz
```

The ports have different roles:

- `127.0.0.1:8080` — read-only firmware origin, reached publicly only through the HTTPS update reverse proxy.
- `127.0.0.1:8090` — firmware administration UI, private only.

## Accessing the administration UI

Do **not** add `/admin` to the public EFIS update hostname. Preferred remote administration is through a VPN into the home/NAS network. A private Synology reverse-proxy hostname can alternatively forward HTTPS to `127.0.0.1:8090`, but it must have an authentication/access-control layer at the proxy before traffic reaches Flask.

For local NAS diagnostics an SSH tunnel is also suitable:

```bash
ssh -L 8090:127.0.0.1:8090 <nas-user>@<nas-address>
```

Then browse to `http://127.0.0.1:8090` on the administrator computer. This keeps the admin application off the public Internet.

## Release workflow

1. Build and validate the intended ESP32 application image separately.
2. Open the private OTA Admin dashboard.
3. Upload the approved `.bin` and enter its release metadata.
4. The server calculates SHA-256 and stores the binary under `/efis/releases/<version>/`.
5. Review the dashboard and public manifest.
6. Test the public manifest and binary over HTTPS from outside the LAN.
7. Only then use an EFIS maintenance session to check for/install the release.

Older releases remain hosted to support deliberate re-selection and diagnostics. Making an older release current changes the manifest only; it does not erase newer files. Deletion is deliberately blocked for the current release.

## Security boundaries

The admin container must not contain GitHub credentials or firmware signing private keys. It accepts an already-approved binary; signing belongs in the controlled release/build process. SHA-256 detects file corruption but is not publisher authentication. Production EFIS firmware must still verify signed application images as specified in `REMOTE_UPDATES.md`.

The current implementation uses the private network/proxy/VPN as the admin authentication boundary. `ADMIN_SESSION_SECRET` protects Flask session integrity; it is **not** a substitute for login authentication. Do not expose port 8090 directly or reverse-proxy it publicly without a proper authentication layer.

Uploads are restricted to `.bin` filenames, versions use a restricted character set, existing version directories cannot be overwritten, and manifest replacement is atomic. Further hardening before Internet-facing multi-user administration would include authenticated users, CSRF protection, audit records, upload-size limits and signed-image verification before publication.

## Backup

The persistent data to back up is:

```text
ota-server/public/efis/manifest.json
ota-server/public/efis/releases/
```

The containers themselves are disposable and can be rebuilt from Git.

## Validation status

**IMPLEMENTED — DEPLOYMENT UNVALIDATED.** The Flask/Gunicorn admin application, Docker image, Compose service, environment template and documentation are committed. They have not yet been built or exercised on the Synology. No claim is made that a hosted binary is safe firmware merely because the admin server accepts it.
