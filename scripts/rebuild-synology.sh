#!/bin/sh
set -eu

COMPOSE_PROJECT_NAME="esp32-efis"
export COMPOSE_PROJECT_NAME
ROOT="${1:-/volume1/docker/ESP32-EFIS}"
cd "$ROOT"
echo "== Validate compose =="
docker compose -f license-service/compose.yml config --quiet
docker compose -f efis-web-simulator/compose.yml config --quiet
echo "== Licence service =="
docker compose -f license-service/compose.yml up -d --build
echo "== Web simulator =="
docker compose -f efis-web-simulator/compose.yml up -d --build
echo "== Local licence gateway =="
"$ROOT/scripts/rebuild-local-license-gateway.sh" "$ROOT"
echo "== Status =="
docker compose -f license-service/compose.yml ps
docker compose -f efis-web-simulator/compose.yml ps
echo "Rebuild complete. Licence service, simulator and authenticated local gateway should be running."
