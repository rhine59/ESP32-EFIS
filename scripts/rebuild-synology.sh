#!/bin/sh
set -eu

COMPOSE_PROJECT_NAME="esp32-efis"
export COMPOSE_PROJECT_NAME
DOCKER="$(command -v docker 2>/dev/null || true)"
[ -n "$DOCKER" ] || DOCKER=/usr/local/bin/docker
[ -x "$DOCKER" ] || { echo "docker not found" >&2; exit 1; }
ROOT="${1:-/volume1/docker/ESP32-EFIS}"
cd "$ROOT"
echo "== Validate compose =="
$DOCKER compose -f account-service/compose.yml --env-file account-service/.env config --quiet
$DOCKER compose -f license-service/compose.yml config --quiet
$DOCKER compose -f efis-web-simulator/compose.yml config --quiet
echo "== Account service =="
$DOCKER compose -f account-service/compose.yml --env-file account-service/.env up -d --build
echo "== Licence service =="
$DOCKER compose -f license-service/compose.yml up -d --build
echo "== Web simulator =="
$DOCKER compose -f efis-web-simulator/compose.yml up -d --build
echo "== Local licence gateway =="
"$ROOT/scripts/rebuild-local-license-gateway.sh" "$ROOT"
echo "== Status =="
$DOCKER compose -f account-service/compose.yml --env-file account-service/.env ps
$DOCKER compose -f license-service/compose.yml ps
$DOCKER compose -f efis-web-simulator/compose.yml ps
echo "Rebuild complete. Account service, licence service, simulator and authenticated local gateway should be running."
