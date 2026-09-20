#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

echo "== Validate Compose =="
sudo docker compose config --quiet

echo "== Rebuild from source =="
sudo docker compose build --pull

echo "== Start/recreate stack =="
sudo docker compose up -d --force-recreate

echo "== Container status =="
sudo docker compose ps

echo "== Local service health =="
curl -fsS http://127.0.0.1:8180/healthz
printf '\n'
curl -fsS http://127.0.0.1:8090/healthz
printf '\n'

echo "== Isolated admin functional harness =="
sudo docker compose run --rm --no-deps --entrypoint python efis-ota-admin /app/test_harness.py

echo "== Public origin manifest =="
curl -fsS http://127.0.0.1:8180/efis/manifest.json
printf '\n'

echo "PASS: rebuild, local health and isolated OTA admin workflow completed."
