#!/bin/sh
set -eu

COMPOSE_PROJECT_NAME="esp32-efis"
export COMPOSE_PROJECT_NAME
cd "$(dirname "$0")/.."
docker compose -f account-service/compose.yml --env-file account-service/.env build --pull account
docker compose -f account-service/compose.yml --env-file account-service/.env up -d
docker compose -f account-service/compose.yml --env-file account-service/.env ps
