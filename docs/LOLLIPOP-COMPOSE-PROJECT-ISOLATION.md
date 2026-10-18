# Lollipop Compose project isolation — migration checkpoint

**Source changes only. Synology services have not been redeployed.**

The following Compose projects are now isolated: `lollipop-account`, `lollipop-support`, `lollipop-ota`, `lollipop-web-simulator`, `lollipop-license`, `lollipop-signer`, `lollipop-local-gateway`; the separate `lollipop-redone-simulator` is unchanged. All service containers retain explicit `lollipop-` names. This removes the shared project-level `db` service collision. The OTA server's default network is explicitly named `lollipop-ota-network`, and the web simulator joins that external network. The licence service and simulator continue to use the pre-existing external `efis-license` network.

**Do not apply a blanket `docker compose up -d` on Synology yet.** Before rollout, capture read-only inventory of containers and Compose labels, network membership, project names and persistent volume mounts. Specifically identify the support database's **actual** data volume: its old Compose-managed `support-db` volume was associated with the shared `lollipop` project. A new `lollipop-support` project would otherwise create a new empty volume. Pin the old volume by its verified name as an external volume or plan a verified backup-and-restore before recreating that service. Existing account DB, simulator state and licence keys have explicit external volume names and should remain untouched.

Plan per-service downtime, confirm required `.env` secrets are present without printing them, verify unique host ports (both support and web simulator currently bind 127.0.0.1:8093 and **cannot run together on the same host**), verify network DNS resolution and reverse-proxy endpoints, and take backups before any container recreation. Explicit container names also prevent side-by-side old/new instances with the same name. Migrate one service at a time; do not use `down -v` or delete named volumes. Roll back using the previous Compose revision and retained volumes if health checks fail.

**Go/no-go:** source isolation prepared, live deployment **NO-GO until inventory, volume pinning and port conflict are resolved**.
