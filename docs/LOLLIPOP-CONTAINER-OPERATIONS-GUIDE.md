# Lollipop Design — Synology container operations and architecture

**Current as of 18 October 2026.** Applies to the deployed development infrastructure, not a certified aviation system. GitHub `main` is the source of truth for source and Compose definitions. The clean NAS deployment checkout is `/volume1/docker/ESP32-EFIS-staging`. Do **not** reset or pull in `/volume1/docker/ESP32-EFIS`: its Git HEAD is damaged. The latter still owns live firmware files and some historical mounts.

## Running stack inventory

| Compose project | Explicit container(s) | Local service | Persistence / dependencies |
| --- | --- | --- | --- |
| `lollipop-account` | `lollipop-account`, `lollipop-account-db` | Account API `127.0.0.1:8091`; PostgreSQL private | External volume `esp32-efis_efis-account-db`; private `account-service/.env` |
| `lollipop-ota` | `lollipop-efis-ota`, `lollipop-efis-ota-admin` | OTA nginx `127.0.0.1:8180`; admin `127.0.0.1:8090` | Original `ota-server/public` bind; external signing-key file; `ota-server_default` network |
| `lollipop-license` | `lollipop-efis-license-service` | `127.0.0.1:8094` | External volume `esp32-efis_license_keys`; `efis-license` network |
| `lollipop-web-simulator` | `lollipop-efis-web-simulator` | `127.0.0.1:8093` | External volume `esp32-efis_efis_sim_state`; `ota-server_default` and `efis-license` networks |
| `lollipop-local-gateway` | `lollipop-redone-local-license-gateway` | Host-network LAN TLS gateway on port 9443 | Read-only `/volume1/docker/redone-local-license-gateway/tls`; mDNS |
| `lollipop-redone-simulator` | `lollipop-redone-simulator` | `127.0.0.1:8193` | Separate existing simulator stack |

**Not running / not provisioned:** `lollipop-signer` requires a private signer key and token; `lollipop-support` requires a secure PostgreSQL password, DATABASE_URL and ADMIN_TOKEN. They were not active before the migration. Do not enable them with placeholder secrets. The `lollipop-support` proposal uses loopback port 8095.

## Architecture and boundaries

```text
Phone / browser -> DSM HTTPS reverse proxy -> account API :8091
Phone on hosting LAN -> pinned local TLS gateway :9443 -> scoped phone API
Web simulator :8093 -> [ota-server_default] -> OTA nginx :8180
                    -> [efis-license] -> licence API :8094
OTA admin :8090 -> shared firmware publication directory <- OTA nginx (read only)
Account API -> PostgreSQL on isolated lollipop-account network
```

All application host ports shown above are loopback-only except the host-network local gateway. Reverse-proxy public endpoints, TLS certificates and firewall policy are separately administered; container health is **not** a public HTTPS acceptance test. No signing private key belongs in Git, mobile bundles or public web images.

## Safe maintenance

1. Confirm clean checkout and production state: `/usr/local/git/bin/git -C /volume1/docker/ESP32-EFIS-staging status --short`; `/usr/local/bin/docker ps --format '{{.Names}} {{.Status}}'`.
2. Back up PostgreSQL and confirm a restorable archive before schema or database changes. The last tested private logical backup is `/volume1/homes/chatgpt/lollipop-account-pre-migration-20261018.dump`; ensure a **fresh** backup for any later maintenance.
3. Check each stack independently: `cd /volume1/docker/ESP32-EFIS-staging/<stack-directory>` then `/usr/local/bin/docker compose config --quiet`. For OTA, private `OTA_PUBLIC_DIR` and `OTA_SIGNING_KEY_FILE` overrides are necessary; ensure they point to existing live resources and are supplied for every Compose command.
4. Build first, then recreate **only the target service group**, with health/HTTP checks and rollback plan. Never run `docker compose down -v`. Never attach two PostgreSQL instances to `esp32-efis_efis-account-db` at the same time.
5. Preserve old stopped `*-legacy` containers until account/email, reverse-proxy, gateway and OTA functional acceptance is complete. Do not indiscriminately prune volumes, images, networks or stopped containers.
6. Check `http://127.0.0.1:8091/healthz`, `http://127.0.0.1:8094/health`, `http://127.0.0.1:8093/api/state`, `http://127.0.0.1:8090/healthz`, and `http://127.0.0.1:8180/efis/manifest.signed.json` from the NAS. The OTA root `/` is not a health endpoint and may return 404.

## Recovery and acceptance

To revert a group, stop the new container(s) and restart its retained legacy container(s) with original port/network mappings. For the account group, stop the **new PostgreSQL** before restarting the old PostgreSQL, and verify schema compatibility. Do not delete or rename persistent volumes during rollback. Do not treat restarting a legacy container as a substitute for a tested backup.

As of migration, all eight running containers had correct project labels; OTA, licence, PostgreSQL and web simulator Docker health checks passed, and the account API was responsive. Full real-user login, verification/reset email, external TLS, phone-app login, gateway LAN discovery, and physical-device signed OTA remain outstanding functional tests. No physical EFIS firmware changes were authorized or made by the container migration.

See `LOLLIPOP-FULL-LIVE-CUTOVER-20261018.md`, `LOLLIPOP-POST-CUTOVER-ACCEPTANCE-20261018.md`, `SYNOLOGY_CONFIGURATION.md`, and `REDONE-LICENCE-NETWORK-ARCHITECTURE.md`.
