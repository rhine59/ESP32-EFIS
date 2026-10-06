#!/bin/sh
set -eu

COMPOSE_PROJECT_NAME="esp32-efis"
export COMPOSE_PROJECT_NAME
DOCKER="$(command -v docker 2>/dev/null || true)"
[ -n "$DOCKER" ] || DOCKER=/usr/local/bin/docker
[ -x "$DOCKER" ] || { echo "docker not found" >&2; exit 1; }
cd "$(dirname "$0")/.."
$DOCKER compose -f account-service/compose.yml --env-file account-service/.env build --pull account
$DOCKER compose -f account-service/compose.yml --env-file account-service/.env up -d
$DOCKER compose -f account-service/compose.yml --env-file account-service/.env ps
