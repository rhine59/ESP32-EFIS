#!/bin/sh
set -eu
ROOT="${1:-/volume1/docker/ESP32-EFIS}"
cd "$ROOT"
echo "== Validate compose =="
sudo docker compose -f license-service/compose.yml config --quiet
sudo docker compose -f efis-web-simulator/compose.yml config --quiet
echo "== Licence service =="
sudo docker compose -f license-service/compose.yml up -d --build
echo "== Web simulator =="
sudo docker compose -f efis-web-simulator/compose.yml up -d --build
echo "== Status =="
sudo docker compose -f license-service/compose.yml ps
sudo docker compose -f efis-web-simulator/compose.yml ps
echo "Rebuild complete. Both services should report healthy."
