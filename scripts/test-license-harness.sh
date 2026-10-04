#!/bin/sh
set -eu
SIM="${SIM_URL:-http://127.0.0.1:8093}"
json_post(){ curl -fsS -H 'Content-Type: application/json' -X POST -d "$2" "$SIM$1"; }
status(){ curl -fsS "$SIM/api/state"; }
echo "== EFIS licence harness smoke test =="
status
echo
echo "Set network online"
json_post /api/sim/network '{"state":"online"}' >/dev/null
echo "Acquire/verify signed licence"
json_post /api/license/refresh '{}' 
echo
for t in tamper bad-signature wrong-device; do
  echo "Negative test: $t"
  json_post /api/license/test "{\"test\":\"$t\"}"
  echo
done
echo "Set network offline"
json_post /api/sim/network '{"state":"offline"}' >/dev/null
echo "Final state"
status
echo
echo "PASS requires VALID licence and REJECTED for all three negative candidates."
