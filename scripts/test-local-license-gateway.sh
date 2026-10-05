#!/bin/sh
set -eu
HOST="${REDONE_GATEWAY_HOST:-192.168.1.99}"
PORT="${REDONE_GATEWAY_PORT:-9443}"
TLS_CERT="${REDONE_GATEWAY_CERT:-/volume1/docker/redone-local-license-gateway/tls/tls.crt}"
DEVICE_ID="${REDONE_TEST_DEVICE_ID:-EFIS-SIM-0001}"
BASE="https://redone-license.local:$PORT"

curl -fsS --cacert "$TLS_CERT" --resolve "redone-license.local:$PORT:$HOST" "$BASE/healthz" | grep -q 'redone-local-gateway'
code="$(curl -sS -o /dev/null -w '%{http_code}' --cacert "$TLS_CERT" --resolve "redone-license.local:$PORT:$HOST" "$BASE/")"
[ "$code" = 404 ]
curl -fsS --cacert "$TLS_CERT" --resolve "redone-license.local:$PORT:$HOST" "$BASE/api/phone/account?device_id=$DEVICE_ID" | grep -q '"device_id"'
echo "PASS: local RedOne gateway TLS, allow-list and phone account API"
