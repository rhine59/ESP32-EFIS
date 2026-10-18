# Lollipop maintenance preflight — 18 October 2026

**Live migration halted safely. No containers restarted, removed, renamed or recreated.**

Read-only SSH inspection identified the running Compose deployment at `/volume1/docker/ESP32-EFIS` on `ds918`. The NAS Git metadata reports `fatal: bad object HEAD` even when using `/usr/local/git/bin/git`; **do not run a destructive Git reset, checkout, clean, or pull in this working tree** until it has been recovered or replaced via a separately validated staging checkout. Existing service files may differ from current Git and must be compared before any deployment.

The account DB is `lollipop-db-1` with external Docker volume `esp32-efis_efis-account-db`, PostgreSQL database `efis_accounts`. A logical PostgreSQL custom-format backup was written on the NAS to `/volume1/homes/chatgpt/lollipop-account-pre-migration-20261018.dump` (25,006 bytes). `pg_restore -l` successfully parsed the archive (72 TOC entries, PostgreSQL 17.11); **a complete restore has not been tested**. This is sensitive application data: retain privately, limit access, and do not commit to Git. Note the initial non-interactive `docker exec` validation without `-i` failed because stdin was not forwarded; validation succeeded with `docker exec -i`.

The existing OTA network is `ota-server_default`; the web simulator uses it, while the OTA server was not observed attached to it. The current service containers remain healthy. Source Compose changes in Git use isolated projects and fixed `lollipop-` container names; they are **not deployed**. Support host port is proposed as 8095; availability and reverse-proxy requirements must be checked.

**Next safe steps:** recover Git metadata or prepare a clean NAS staging checkout without modifying live directories; inspect actual Compose environment without disclosing secrets; take verified backup of the NAS deployment configuration and database volume; validate rollback and network migration; then perform a single-service maintenance rollout with health checks. Do not remove the shared legacy `lollipop_default` network while old services use it.
