#!/bin/sh
set -eu
ROOT="${1:-/volume1/docker/ESP32-EFIS}"
cd "$ROOT"
echo "== Validate compose =="
docker compose -f license-service/compose.yml config --quiet
docker compose -f efis-web-simulator/compose.yml config --quiet
echo "== Licence service =="
docker compose -f license-service/compose.yml up -d --build
echo "== Web simulator =="
docker compose -f efis-web-simulator/compose.yml up -d --build
echo "== Status =="
docker compose -f license-service/compose.yml ps
docker compose -f efis-web-simulator/compose.yml ps
echo "Rebuild complete. Both services should report healthy."
