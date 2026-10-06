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
$DOCKER compose -f license-service/compose.yml config --quiet
$DOCKER compose -f efis-web-simulator/compose.yml config --quiet
echo "== Licence service =="
$DOCKER compose -f license-service/compose.yml up -d --build
echo "== Web simulator =="
$DOCKER compose -f efis-web-simulator/compose.yml up -d --build
echo "== Local licence gateway =="
"$ROOT/scripts/rebuild-local-license-gateway.sh" "$ROOT"
echo "== Status =="
$DOCKER compose -f license-service/compose.yml ps
$DOCKER compose -f efis-web-simulator/compose.yml ps
echo "Rebuild complete. Licence service, simulator and authenticated local gateway should be running."
