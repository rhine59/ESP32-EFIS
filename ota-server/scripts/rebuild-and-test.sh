#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

echo "== Validate Compose =="
sudo docker compose config --quiet

echo "== Rebuild from source =="
sudo docker compose build --pull

echo "== Start/recreate stack =="
sudo docker compose up -d --force-recreate

echo "== Wait for container health =="
for service in efis-ota efis-ota-admin; do
  cid="$(sudo docker compose ps -q "$service")"
  [ -n "$cid" ] || { echo "FAIL: $service container was not created"; exit 1; }
  i=0
  status=starting
  while [ "$i" -lt 45 ]; do
    status="$(sudo docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$cid")"
    [ "$status" = "healthy" ] && break
    if [ "$status" = "unhealthy" ]; then
      echo "FAIL: $service became unhealthy"
      sudo docker compose logs --tail=100 "$service"
      exit 1
    fi
    sleep 1
    i=$((i+1))
  done
  if [ "$status" != "healthy" ]; then
    echo "FAIL: timeout waiting for $service health (last status: $status)"
    sudo docker compose logs --tail=100 "$service"
    exit 1
  fi
  echo "PASS  $service healthy"
done

echo "== Container status =="
sudo docker compose ps

echo "== Local service health =="
curl -fsS --retry 3 --retry-delay 1 http://127.0.0.1:8180/healthz
printf '\n'
curl -fsS --retry 3 --retry-delay 1 http://127.0.0.1:8090/healthz
printf '\n'

echo "== Isolated admin functional harness =="
sudo docker compose run --rm --no-deps --entrypoint python efis-ota-admin /app/test_harness.py

echo "== Public origin manifest =="
curl -fsS http://127.0.0.1:8180/efis/manifest.json
printf '\n'

echo "PASS: rebuild, local health and isolated OTA admin workflow completed."
