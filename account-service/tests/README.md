# Disposable recovery tests

From the repository root, build the production and test images:

```sh
docker build -t lollipop-account-recovery-test account-service
docker build -t lollipop-account-recovery-suite -f account-service/tests/Dockerfile .
docker run --rm -v "$PWD/account-service/tests:/tests:ro" lollipop-account-recovery-suite python -m unittest discover -s /tests -v
```

The integration project has no production mounts, ports, secrets or container names. It intentionally does not depend on database startup order. Use a fresh test volume for the sentinel-count assertions. Start the account first, observe retry logs, then start PostgreSQL within the retry budget:

```sh
docker compose -f account-service/tests/compose.recovery.yml up -d account
docker compose -f account-service/tests/compose.recovery.yml logs account
docker compose -f account-service/tests/compose.recovery.yml up -d db
docker compose -f account-service/tests/compose.recovery.yml exec -T account python /tests/check_recovery.py seed
docker compose -f account-service/tests/compose.recovery.yml stop db
docker compose -f account-service/tests/compose.recovery.yml exec -T account python /tests/check_recovery.py outage
docker compose -f account-service/tests/compose.recovery.yml start db
docker compose -f account-service/tests/compose.recovery.yml exec -T account python /tests/check_recovery.py verify
docker compose -f account-service/tests/compose.recovery.yml kill -s SIGKILL db
docker compose -f account-service/tests/compose.recovery.yml start db
docker compose -f account-service/tests/compose.recovery.yml exec -T account python /tests/check_recovery.py verify
```

Check account restart count and start timestamp before and after the outages; they must remain unchanged. Stop the disposable stack after testing. Its test volume may be retained for inspection. Never substitute the production Compose file for these outage commands.
