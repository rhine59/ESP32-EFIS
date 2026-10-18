# Lollipop live Synology inventory — 18 October 2026

Read-only inventory via SSH on `ds918` using `/usr/local/bin/docker`. No services restarted or modified.

| Existing container | Observed state | Compose project | Critical resources |
| --- | --- | --- | --- |
| lollipop-db-1 | Up, healthy | lollipop | `esp32-efis_efis-account-db` at `/var/lib/postgresql/data`; `lollipop_default` |
| lollipop-account-1 | Up | lollipop | `lollipop_default`, host 127.0.0.1:8091 |
| lollipop-efis-web-simulator-1 | Up, healthy | lollipop | `esp32-efis_efis_sim_state`; `efis-license`, `lollipop_default`, `ota-server_default`; host 8093 |
| lollipop-efis-ota-1 | Up, healthy | lollipop | OTA public bind mount; `lollipop_default`; host 8180 |
| lollipop-efis-ota-admin-1 | Up, healthy | not separately inspected | host 8090 |
| lollipop-efis-license-service-1 | Up, healthy | lollipop | `esp32-efis_license_keys`; `efis-license`, `lollipop_default`; host 8094 |
| lollipop-redone-local-license-gateway-1 | Up | not separately inspected | host network |
| lollipop-redone-simulator | Up | separate project | host 8193 |

**Important discrepancy:** the OTA container was *not* observed on `ota-server_default`, despite the web simulator joining it. Before migration, check whether the simulator can actually resolve/reach the OTA service. Source now explicitly attaches the OTA service to the **existing** `ota-server_default` network while isolating its Compose project; avoid deleting the network. The support service is not running in this observed Lollipop inventory; its proposed host binding is moved from conflicting 8093 to 8095 (verify availability before deployment).

## Deployment blockers

1. Verify the NAS working-directory checkout and its Compose configuration against Git before using `docker compose`; no assumption that Mac repository is the live deployment source.
2. Capture database backup and verified restore procedure; retain named volumes and OTA signing-key mount, without exposing secrets.
3. Inventory reverse-proxy routing, health checks, and actual container-to-container reachability. Confirm 8095 is free.
4. Review existing `lollipop` project ownership and Compose labels. Since old containers use generated names and new Compose uses fixed names, deploying isolated projects could leave old containers running and create port collisions. Stop/recreate **one service at a time** only after the operator approves downtime and rollback.
5. Verify recovery and reversion plan; never use `docker compose down -v`.

**Decision:** source migration prepared; live migration held pending preflight and explicit rollout window. No production container changes authorised by this inventory.
