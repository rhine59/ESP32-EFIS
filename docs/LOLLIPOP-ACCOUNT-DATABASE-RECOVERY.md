# Account database recovery architecture and runbook

Prepared 24 October 2026. This runbook describes the recovery change; deployment evidence is recorded separately below.

## Incident evidence and limits

Live logs show PostgreSQL received a fast-shutdown request at **2026-10-22 15:29:26 UTC (16:29 BST)** and completed a clean shutdown at 15:29:27 UTC. It was started again at 21:22:11 UTC and became ready at 21:22:13 UTC. Account startup repeatedly failed on database hostname resolution (`Name or service not known`), reaching 307 restarts. The account recovered at 21:22:25 UTC after PostgreSQL returned. The original one-shot schema initialization converted database absence into repeated application exits.

This is evidence of a requested clean stop, not an observed database crash or corruption. The initiating actor/process remains unidentified: retained Docker events did not include the incident, and host logs require additional privileges; passwordless sudo is unavailable. Current DB OOMKilled is false, but that field alone cannot exclude historical memory events. On 24 October the volume had 13 TB available (43% used), and the DB was healthy. No administrator authentication changes were made to obtain access. NAS access used the repository-documented LAN address and an existing trusted SSH host key.

The clean NAS deployment checkout is `/volume1/docker/ESP32-EFIS-staging`. The original `/volume1/docker/ESP32-EFIS` checkout is documented as damaged; do not pull or reset it. Preserve external volume `esp32-efis_efis-account-db`, existing `.env`, signing keys, TLS configuration, and all administrator 2FA settings.

## Revised architecture

```text
Browser / phone -> DSM HTTPS proxy -> account :8091 -> private PostgreSQL :5432
                                      |                 |
                                /livez process      pg_isready
                                /healthz SELECT 1   persistent external volume
                                      |
                                Docker health status
```

Compose gates initial account creation on database health. This ordering is not a runtime recovery supervisor and is not guaranteed during a Docker daemon restart. The application now retries its existing idempotent schema transaction up to 12 times, with exponential delay capped at 15 seconds plus up to one second jitter. Connections have a five-second timeout. Schema initialization runs in a worker thread, with a 15-second statement timeout and five-second lock timeout; the transaction commits only after all schema statements succeed. Programming/schema errors fail immediately; connection errors exhaust the retry budget and exit so `unless-stopped` can retry later. No destructive migration is added.

After startup each request opens a fresh connection. Connection failures return HTTP 503 and a five-second Retry-After hint. The application never automatically replays a customer transaction: a failure during commit can leave its outcome uncertain, and callers must reconcile before repeating a write. Connections and transactions close through context managers. Once PostgreSQL recovers, subsequent requests reconnect without restarting the account container.

`/livez` reports process responsiveness after startup. `/healthz` checks a real database query with a three-second statement timeout and returns 503 on connection failure. The account Docker health check probes `/healthz` every 30 seconds, with three failures required and a 240-second startup grace. PostgreSQL retains its readiness check, with a 120-second startup grace and 60-second graceful-stop window. PostgreSQL is never automatically killed merely for an unhealthy status. Docker health status alone does **not** restart unhealthy containers or send alerts. Existing restart policies recover exited processes; database corruption, full storage, hung processes, and host outages require operator action. Configure the existing NAS monitoring system to alert on unhealthy/restarting containers, disk/inode pressure, volume health and host memory; do not grant a generic watchdog Docker socket access.

## Read-only incident collection

Connect only to a verified NAS host identity. Use `/usr/local/bin/docker` on the NAS. Collect timestamps in UTC, `docker ps -a`, and bounded logs from both account containers. Inspect only selected fields to avoid exposing environment secrets:

```sh
docker inspect --format '{{json .State}} {{.RestartCount}} {{.Image}}' lollipop-account-db lollipop-account
docker inspect --format '{{json .Mounts}}' lollipop-account-db
docker logs --timestamps --tail 200 lollipop-account-db
docker logs --timestamps --tail 100 lollipop-account
df -h
df -i
free -m
```

Use the full Docker path if it is absent from PATH. Check DSM Log Center, Storage Manager, UPS/power events and kernel OOM messages for the incident time. A shutdown message is not itself evidence of corruption. Record image IDs, restart counters, exit codes, OOMKilled, volume identity and available space before recovery. Never print full `docker inspect` or rendered Compose output containing secrets.

## Backup and deployment gate

1. Confirm the deployment checkout status and current commit; record current account image ID and tag it for rollback. Do not overwrite local changes. Build the tested revision before service recreation.
2. Confirm only one PostgreSQL instance owns the external volume. If PostgreSQL is available, take a fresh private custom-format `pg_dump` using the container's configured DB/user. Use `umask 077` and a timestamped private destination outside Git. Require successful dump exit and `pg_restore --list`; restore into an isolated disposable database and verify table counts before deployment. Archive listing alone is not a restore test.
3. If PostgreSQL cannot start, stop repeated intervention and investigate storage/permissions/logs. Preserve a storage snapshot or cold copy with PostgreSQL stopped before repair. Never initialize a replacement volume, remove WAL, run `pg_resetwal`, prune volumes, or attach a second server to the original volume.
4. Validate Compose with `config --quiet` using the private `.env`. Deploy the exact tested Git commit through the clean NAS checkout. Recreate only `account` with `up -d --no-deps --build account` first, leaving the existing database running. The database grace-period change can be applied during a controlled database restart after backup; do not unnecessarily recreate it during an incident.
5. Verify local `/livez` and `/healthz`, Docker health and stable restart counters. Verify public HTTPS `/healthz` through the existing DSM proxy with normal certificate validation. Check login page availability. Real-user login/email/mobile-session acceptance requires existing test credentials and must retain 2FA. Do not reset users or enable development reset to obtain access.
6. Observe at least several health intervals. Record commit, image, backup/restore verification, deployment time, endpoint results and restart counters. Only then mark this revision deployed.

## Outage and rollback

For a temporary database interruption, expect account `/healthz` and database-backed requests to fail with 503, `/livez` to remain 200, and health to recover when the database returns. Test deliberate outages only against disposable test data, never by killing the live database. A process stuck despite healthy PostgreSQL should have logs captured before a targeted account restart. Repeated database exits require root-cause investigation rather than a restart watchdog.

For application rollback, restore the recorded prior account image using a private Compose image override and recreate only the account container with `--no-deps --no-build`. Verify health again. This change retains the same schema and external volume, so no database downgrade or restore is needed. Restore data only through a separately reviewed recovery procedure; never overwrite the only surviving copy. Do not run `compose down -v`.

## Verification

Run the unit/HTTP suite inside the built Python 3.13 image with the tests directory mounted read-only and `PYTHONDONTWRITEBYTECODE=1`:

```sh
python -m unittest discover -s /tests -v
```

Five unit/HTTP tests passed on 24 October in Python 3.13. A separate disposable PostgreSQL 17.11 integration stack passed delayed database startup (five connection attempts), runtime outage (health 503, liveness 200), clean restart, and SIGKILL crash recovery. A committed audit sentinel survived both database restarts; the account process retained restart count zero and the same start timestamp. No production database was stopped for these tests.

Reproduce with `tests/Dockerfile` and `tests/compose.recovery.yml` as described in `account-service/tests/README.md`. NAS backup/restore and live acceptance are recorded in the deployment evidence.

## Follow-up — 9 November 2026

The prepared changes had not been committed or deployed before the prior session was interrupted. Live logs still showed the original one-shot startup failing with PostgreSQL `the database system is starting up`. Both active account containers were healthy/running when inspected on 9 November.

A separate obsolete container, `lollipop-efis-ota-admin-1`, had exit code 128 with `Bind for 127.0.0.1:8090 failed: port is already allocated`. The active `lollipop-efis-ota-admin` already owns that endpoint. Retain the obsolete container for rollback, but set its restart policy to `no`; do not start both. Other historical legacy containers remain stopped. Home Assistant was stopped with exit code zero and no recorded startup error, so its state is outside this fix.
