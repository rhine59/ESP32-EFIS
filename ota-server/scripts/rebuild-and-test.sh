#!/bin/sh
set -eu

COMPOSE_PROJECT_NAME="esp32-efis"
export COMPOSE_PROJECT_NAME
DOCKER="$(command -v docker 2>/dev/null || true)"
[ -n "$DOCKER" ] || DOCKER=/usr/local/bin/docker
[ -x "$DOCKER" ] || { echo "docker not found" >&2; exit 1; }
if "$DOCKER" info >/dev/null 2>&1; then D="$DOCKER"; else D="sudo $DOCKER"; fi
DC="$D compose"
cd "$(dirname "$0")/.."

echo "== Validate Compose =="
$DC config --quiet

echo "== Rebuild from source =="
$DC build --pull

echo "== Start/recreate stack =="
$DC up -d --force-recreate

echo "== Wait for container health =="
for service in efis-ota efis-ota-admin; do
  cid="$($DC ps -q "$service")"
  [ -n "$cid" ] || { echo "FAIL: $service container was not created"; exit 1; }
  i=0
  status=starting
  while [ "$i" -lt 45 ]; do
    status="$($D inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$cid")"
    [ "$status" = "healthy" ] && break
    if [ "$status" = "unhealthy" ]; then
      echo "FAIL: $service became unhealthy"
      $DC logs --tail=100 "$service"
      exit 1
    fi
    sleep 1
    i=$((i+1))
  done
  if [ "$status" != "healthy" ]; then
    echo "FAIL: timeout waiting for $service health (last status: $status)"
    $DC logs --tail=100 "$service"
    exit 1
  fi
  echo "PASS  $service healthy"
done

echo "== Container status =="
$DC ps

echo "== Local service health =="
curl -fsS --retry 3 --retry-delay 1 http://127.0.0.1:8180/healthz
printf '\n'
curl -fsS --retry 3 --retry-delay 1 http://127.0.0.1:8090/healthz
printf '\n'

echo "== Isolated admin functional harness =="
$DC run --rm --no-deps --entrypoint python efis-ota-admin /app/test_harness.py

echo "== Simulated SMUX OTA state machine =="
$DC run --rm --no-deps --entrypoint python efis-ota-admin /app/test_smux_ota.py

echo "== Simulated AEF-CAN SMUX OTA transport =="
$DC run --rm --no-deps --entrypoint python efis-ota-admin /app/test_smux_can_ota.py

echo "== End-to-end resumable OTA simulation =="
$DC run --rm --no-deps --entrypoint python efis-ota-admin /app/test_end_to_end_ota.py

echo "== Public origin manifest =="
curl -fsS http://127.0.0.1:8180/efis/manifest.json
printf '\n'

echo "PASS: rebuild, local health and isolated OTA admin workflow completed."
