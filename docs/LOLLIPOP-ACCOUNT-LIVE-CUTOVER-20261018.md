# Lollipop account and PostgreSQL live cutover — 18 October 2026

**Production cutover completed:** Built account image in the clean Synology staging checkout, stopped and retained the legacy `lollipop-account-1` and `lollipop-db-1` containers as `lollipop-account-legacy` and `lollipop-db-legacy`, and started the isolated Compose project `lollipop-account` with explicit containers `lollipop-account` and `lollipop-account-db`.

**Verification:** PostgreSQL became healthy, uses the **same original external volume** `esp32-efis_efis-account-db` at `/var/lib/postgresql/data`, and contains the existing user record (count 1). Account application started successfully; NAS loopback `GET http://127.0.0.1:8091/healthz` returned HTTP 200. The private staging account `.env` was retained locally with mode 0600 and excluded from Git. The prior isolated restore test verified eight tables and one user record from the private logical backup. No production data volume was deleted or replaced.

**Rollback:** Stop the new `lollipop-account` and `lollipop-account-db` before starting either legacy container, because two PostgreSQL instances **must never simultaneously access the same data volume**. Check application/schema compatibility before rollback, rename or start retained `lollipop-db-legacy` and `lollipop-account-legacy` with their original port bindings. Retain the private backup and legacy images until acceptance. A full browser/email/password-reset login test has **not** been performed; health and database continuity do not prove all authentication flows.

**Other services:** OTA download/admin remained healthy on their isolated Compose project. Licence service, web simulator and local gateway have not yet been migrated.
