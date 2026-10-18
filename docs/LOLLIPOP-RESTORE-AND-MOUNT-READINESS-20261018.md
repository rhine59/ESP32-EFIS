# Synology restore verification and staging mount readiness — 18 October 2026

## Actual restore verification (PASS)

On NAS `ds918`, a private custom-format account backup at `/volume1/homes/chatgpt/lollipop-account-pre-migration-20261018.dump` was restored with `pg_restore --no-owner --no-acl` into a temporary `postgres:17-alpine` container named `lollipop-restore-check`. The container used `--network none`, an ephemeral tmpfs PostgreSQL data directory and no published ports. PostgreSQL reported eight public tables and one user record in the restored `efis_accounts` database. The temporary container was stopped and removed after the check; the live `lollipop-db-1` and its `esp32-efis_efis-account-db` volume were not modified. This validates basic recoverability of the logical backup, but is not a full application-level disaster recovery exercise.

## Required staging wiring (NOT YET APPLIED)

- Account service: retain the **existing external** `esp32-efis_efis-account-db` volume, and supply account `.env` from the private live deployment without printing or committing it. Avoid running two Postgres servers against the same data directory.
- OTA server/admin: bind the existing `/volume1/docker/ESP32-EFIS/ota-server/public` into the new service or perform a verified content migration. Staging's newly cloned `ota-server/public` is empty and **must not** become the production release directory by accident. Preserve the private signing-key mount from the existing admin container and do not expose the key.
- Web simulator: retain external `esp32-efis_efis_sim_state`, shared `efis-license` network and legacy `ota-server_default` network. Check OTA service reachability; currently only the simulator was observed on `ota-server_default`.
- Licence service: retain `esp32-efis_license_keys` and `efis-license` network.
- Support service: no live support database was observed. Keep proposed 8095 host port, but verify socket and reverse-proxy availability before starting.
- Other services: verify current bind mounts, Docker labels, secret paths, ports and health endpoints before migration.

## Rollout order

1. Snapshot or archive existing Compose files, private environment settings and live bind mount paths; verify archive and restore without disclosing secrets.
2. Prepare deployment overrides to reference existing volumes and OTA public directory from the staging checkout; validate rendered Compose configuration **without displaying secrets**.
3. Migrate non-database services one at a time, checking network DNS, service health and reverse-proxy response; stop on unexpected results.
4. Schedule a short separate database cutover, preserve the verified backup, stop the old account and database containers, start the isolated-project replacements against the **same** existing volume, verify account login and rollback.
5. Do not delete old project networks or volumes while any container still depends on them. Do not use `docker compose down -v`.

**Current decision:** restored backup verified, production rollout **not yet performed**. All original Lollipop containers remain running.
