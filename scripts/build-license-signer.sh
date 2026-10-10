#!/bin/sh
set -eu

COMPOSE_PROJECT_NAME="lollipop"
export COMPOSE_PROJECT_NAME
DOCKER="$(command -v docker 2>/dev/null || true)"
[ -n "$DOCKER" ] || DOCKER=/usr/local/bin/docker
[ -x "$DOCKER" ] || { echo "docker not found" >&2; exit 1; }
cd "$(dirname "$0")/../license-signer"
$DOCKER compose build signer
$DOCKER compose up -d signer
$DOCKER compose ps
curl -fsS http://127.0.0.1:8092/healthz
echo
