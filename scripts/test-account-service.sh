#!/bin/sh
set -eu
BASE="${EFIS_ACCOUNT_URL:-http://127.0.0.1:8091}"
curl -fsS "$BASE/healthz"
printf '\nPASS: EFIS account service health\n'
