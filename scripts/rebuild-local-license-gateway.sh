#!/bin/sh
set -eu

ROOT="${1:-/volume1/docker/ESP32-EFIS}"
RUNTIME="${REDONE_GATEWAY_RUNTIME:-/volume1/docker/redone-local-license-gateway}"
TLS_DIR="$RUNTIME/tls"
DAYS="${REDONE_GATEWAY_CERT_DAYS:-825}"
REDONE_UID="${REDONE_UID:-$(id -u)}"
REDONE_GID="${REDONE_GID:-$(id -g)}"
export REDONE_UID REDONE_GID

mkdir -p "$RUNTIME" "$TLS_DIR"
cp "$ROOT/local-license-gateway/Dockerfile" "$RUNTIME/Dockerfile"
cp "$ROOT/local-license-gateway/gateway.py" "$RUNTIME/gateway.py"
cp "$ROOT/local-license-gateway/compose.yml" "$RUNTIME/compose.yml"

if [ ! -s "$TLS_DIR/tls.key" ] || [ ! -s "$TLS_DIR/tls.crt" ]; then
  echo "Generating dedicated RedOne local-gateway TLS identity"
  openssl req -x509 -newkey rsa:3072 -sha256 -days "$DAYS" -nodes \
    -subj "/CN=redone-license.local" \
    -addext "subjectAltName=DNS:redone-license.local" \
    -keyout "$TLS_DIR/tls.key" -out "$TLS_DIR/tls.crt"
  chmod 600 "$TLS_DIR/tls.key"
  chmod 644 "$TLS_DIR/tls.crt"
  echo "NEW CERTIFICATE GENERATED."
  echo "Before distributing the iOS build, update RedOneLocalGateway.certificatePins with:"
  openssl x509 -in "$TLS_DIR/tls.crt" -outform DER | openssl dgst -sha256
fi

cd "$RUNTIME"
docker compose config --quiet
docker compose up -d --build

echo "Gateway certificate:"
openssl x509 -in "$TLS_DIR/tls.crt" -noout -subject -dates -fingerprint -sha256
echo "Gateway container:"
docker compose ps
