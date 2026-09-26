#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
docker compose -f account-service/compose.yml --env-file account-service/.env build --pull account
docker compose -f account-service/compose.yml --env-file account-service/.env up -d
docker compose -f account-service/compose.yml --env-file account-service/.env ps
