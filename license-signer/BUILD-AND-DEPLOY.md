# Licence Signer — Complete Build and Deployment Guide

This is the authoritative build/run procedure for the private `efis-license-signer` Docker service on the Synology NAS.

**Current status:** source complete; Synology runtime validation pending.

## 1. Security boundary

The signer is an internal service. **Do not create a Synology reverse-proxy rule or router port-forward for port 8092.** It binds only to `127.0.0.1:8092`.

The Ed25519 private key and service token are secrets. They must never be committed, pasted into documentation, printed into logs, baked into the image or exposed by the public OTA service.

Development keys created by this guide are for integration/testing only. Production signing requires separate controlled key custody.

## 2. Repository assets

- `license-signer/Dockerfile` — Python 3.13 non-root image.
- `license-signer/compose.yml` — hardened Compose service and private-key mount.
- `license-signer/requirements.txt` — pinned Python dependencies.
- `license-signer/app/main.py` — FastAPI Ed25519/deterministic-CBOR signer.
- `license-signer/.env.example` — non-secret configuration template.
- `license-signer/.gitignore` — excludes environment/key material.
- `license-signer/scripts/generate-dev-key.sh` — one-time disposable development key generator.
- `scripts/build-license-signer.sh` — repository-level build/start/health helper.

## 3. Pull on Synology

From the existing repository checkout:

```sh
cd /volume1/docker/ESP32-EFIS
git status
git pull --ff-only
```

Do not discard local changes if `git status` is not clean; reconcile them before pulling.

## 4. Create signer configuration

```sh
cd /volume1/docker/ESP32-EFIS/license-signer
cp .env.example .env
```

Edit `.env`. Replace `CHANGE-ME` with a long random service-to-service token. Do not display that token in chat, screenshots or logs.

Keep:
```text
SIGNER_KEY_ID=lic-2026-01
SIGNER_PRIVATE_KEY_FILE=/run/secrets/efis_license_ed25519.pem
```

The `.env` file is Git-ignored.

## 5. Generate DEVELOPMENT signing key

Run once:

```sh
cd /volume1/docker/ESP32-EFIS/license-signer
chmod +x scripts/generate-dev-key.sh
./scripts/generate-dev-key.sh
```

Expected private/public files are under `license-signer/secrets/`, which is Git-ignored.

The script refuses to overwrite an existing private key. Never solve that refusal by deleting a key unless replacement is deliberate and its consequences are understood.

## 6. Validate configuration without exposing secrets

```sh
sudo docker compose config --quiet
```

Do not paste ordinary `docker compose config` output because resolved environment values may reveal secrets.

## 7. Build

```sh
sudo docker compose build signer
```

A successful image build does not yet prove signing works.

## 8. Start/recreate

```sh
sudo docker compose up -d signer
sudo docker compose ps
```

Expected container: `esp32-efis-license-signer`, running, with host binding `127.0.0.1:8092`.

## 9. Health test

```sh
curl -fsS http://127.0.0.1:8092/healthz
echo
```

Expected fields include `status: ok`, service name, configured key ID and `key_file_present: true`.

The health endpoint deliberately does not expose private key material or the service token.

## 10. Check isolation

Confirm only loopback is published:

```sh
sudo docker port esp32-efis-license-signer
```

Expected host address is `127.0.0.1`, not `0.0.0.0`.

There must be no public reverse proxy or router rule to 8092.

## 11. Logs

```sh
sudo docker compose logs --tail=100 signer
```

Logs must not contain the API token, private key or complete sensitive request credentials.

## 12. Stop/restart

```sh
sudo docker compose restart signer
sudo docker compose stop signer
sudo docker compose up -d signer
```

Normal restart must retain the mounted key and key ID.

## 13. Rebuild after source changes

```sh
cd /volume1/docker/ESP32-EFIS
git pull --ff-only
cd license-signer
sudo docker compose config --quiet
sudo docker compose build signer
sudo docker compose up -d --force-recreate signer
curl -fsS http://127.0.0.1:8092/healthz
echo
```

## 14. Repository helper

The repository helper performs build/start/status/health from the repo:

```sh
cd /volume1/docker/ESP32-EFIS
chmod +x scripts/build-license-signer.sh
sudo ./scripts/build-license-signer.sh
```

If Docker permissions/environment handling on the Synology make the helper unsuitable, use the explicit commands above; they are authoritative.

## 15. Backup/recovery

For development, loss of the disposable signing key invalidates licences created with that key unless the corresponding public/private test setup is restored. Do not treat the development key as production material.

Before production, define and validate:
- protected signing-key generation;
- encrypted backup/recovery;
- access control;
- key rotation and `kid` lifecycle;
- compromise response;
- trusted-public-key rollout to EFIS firmware;
- dual-key overlap during rotation.

Never put a production private key in Git or a normal Docker image.

## 16. Validation gate before account integration

Do not mark the signer runtime VALIDATED until all of these pass:
1. Compose config validation.
2. Clean image build.
3. Container starts non-root.
4. Health endpoint passes and sees the key.
5. Host port is loopback only.
6. Authorized sign request returns an envelope.
7. Unauthorized request is rejected.
8. Returned CBOR decodes correctly.
9. Independent Ed25519 verification succeeds using the public key.
10. One-byte payload/signature corruption is rejected.
11. Wrong public key is rejected.
12. Container restart preserves ability to verify licences issued before restart.
13. Logs contain no signing key/token.
14. No public reverse proxy/router exposure exists.

The automated sign/decode/verify/corruption harness is the next implementation step; until then items 6–12 remain manual/pending.

## 17. Production gate

Before issuing customer licences:
- replace development key custody with the production-approved mechanism;
- replace/scaffold bearer-only trust with restricted service authentication/network policy;
- integrate only the authorized `efis-account` service;
- run cross-platform server/ESP32 test vectors;
- validate encrypted/protected NVS on the EFIS;
- test key rotation and recovery;
- complete security review.

See `docs/LICENSING.md` for the authoritative licensing lifecycle.
