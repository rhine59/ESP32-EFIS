#!/bin/sh
set -eu

COMPOSE_PROJECT_NAME="ESP32-EFIS"
export COMPOSE_PROJECT_NAME
cd "$(dirname "$0")/../license-signer"
docker compose build signer
docker compose up -d signer
docker compose ps
curl -fsS http://127.0.0.1:8092/healthz
echo
