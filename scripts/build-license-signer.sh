#!/bin/sh
set -eu
cd "$(dirname "$0")/../license-signer"
docker compose build signer
docker compose up -d signer
docker compose ps
curl -fsS http://127.0.0.1:8092/healthz
echo
