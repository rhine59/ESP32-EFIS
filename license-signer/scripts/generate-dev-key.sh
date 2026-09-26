#!/bin/sh
set -eu
mkdir -p secrets
if [ -e secrets/efis_license_ed25519.pem ]; then
  echo "Refusing to overwrite existing key" >&2
  exit 1
fi
openssl genpkey -algorithm Ed25519 -out secrets/efis_license_ed25519.pem
chmod 600 secrets/efis_license_ed25519.pem
openssl pkey -in secrets/efis_license_ed25519.pem -pubout -out secrets/efis_license_ed25519.pub.pem
echo "Development key generated. NEVER commit secrets/."
