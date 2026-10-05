#!/bin/sh
set -eu
ROOT="${ROOT:-/volume1/docker/ESP32-EFIS}"
SIM="${SIM_URL:-http://127.0.0.1:8093}"
LIC="${LIC_URL:-http://127.0.0.1:8094}"
TMP="/tmp/efis-license-test.$$"
trap 'rm -f "$TMP"' EXIT

json_post(){ curl -fsS -H 'Content-Type: application/json' -X POST -d "$2" "$SIM$1"; }
lic_post(){ curl -fsS -H 'Content-Type: application/json' -X POST -d "$2" "$LIC$1"; }
status(){ curl -fsS "$SIM/api/state"; }
storage(){ curl -fsS "$SIM/api/license/test/storage"; }
field(){ printf '%s' "$1" | sed -n "s/.*\\\"$2\\\": \\\"\\([^\\\"]*\\)\\\".*/\\1/p"; }
require(){ printf '%s' "$1" | grep -F "$2" >/dev/null || { echo "FAIL: expected $2"; echo "$1"; exit 1; }; }
expect_refresh_failure(){
  code=$(curl -sS -o "$TMP" -w '%{http_code}' -H 'Content-Type: application/json' -X POST -d '{}' "$SIM/api/license/refresh")
  [ "$code" -ge 400 ] || { echo "FAIL: refresh unexpectedly succeeded"; cat "$TMP"; exit 1; }
  cat "$TMP"; echo
}
restart_sim(){
  docker compose -f "$ROOT/efis-web-simulator/compose.yml" restart >/dev/null
  i=0
  until curl -fsS "$SIM/api/state" >/dev/null 2>&1; do
    i=$((i+1)); [ "$i" -lt 30 ] || { echo "FAIL: simulator did not restart"; exit 1; }
    sleep 1
  done
}

echo "== EFIS licence regression harness =="
json_post /api/sim/network '{"state":"online"}' >/dev/null
echo "Acquire/verify signed licence"
r=$(json_post /api/license/refresh '{}'); require "$r" '"status": "VALID"'; echo "$r"
baseline=$(field "$r" license_id)

for t in tamper bad-signature wrong-device; do
  echo "Negative test: $t"
  r=$(json_post /api/license/test "{\"test\":\"$t\"}")
  require "$r" '"result": "REJECTED"'; require "$r" '"installed": "VALID"'; echo "$r"
done

echo "No-entitlement must preserve installed licence"
lic_post /v1/test/entitlement '{"active":false}' >/dev/null
expect_refresh_failure
r=$(status); require "$r" '"status": "VALID"'; require "$r" "$baseline"
lic_post /v1/test/entitlement '{"active":true}' >/dev/null

echo "Interrupted replacement must preserve previous licence across restart"
r=$(json_post /api/license/test '{"test":"interrupted-replacement"}')
require "$r" '"result": "INTERRUPTED"'; require "$r" '"temp_exists": true'; echo "$r"
restart_sim
r=$(status); require "$r" '"status": "VALID"'; require "$r" "$baseline"
s=$(storage); require "$s" '"licence_exists": true'; require "$s" '"temp_exists": false'; echo "$s"

echo "Licence Reset must preserve Device ID, firmware and trust anchor"
before=$(status); device=$(field "$before" device_id); firmware=$(field "$before" firmware)
json_post /api/license/mock-reset '{}' >/dev/null
after=$(status); require "$after" '"status": "NOT INSTALLED"'; require "$after" "$device"; require "$after" "$firmware"
s=$(storage); require "$s" '"licence_exists": false'; require "$s" '"trust_key_count": 1'; echo "$s"

echo "Offline acquisition with no licence must fail cleanly"
json_post /api/sim/network '{"state":"offline"}' >/dev/null
expect_refresh_failure
r=$(status); require "$r" '"status": "NOT INSTALLED"'; require "$r" "$device"
echo "START EFIS remains an independent boot-menu action in the simulator UI."

echo "Reacquire valid licence for corruption test"
json_post /api/sim/network '{"state":"online"}' >/dev/null
r=$(json_post /api/license/refresh '{}'); require "$r" '"status": "VALID"'
json_post /api/license/test/corrupt-store '{}' >/dev/null
restart_sim
r=$(status); require "$r" '"status": "INVALID"'; echo "$r"

echo "Recover from corrupt stored licence with a newly verified signed licence"
json_post /api/sim/network '{"state":"online"}' >/dev/null
r=$(json_post /api/license/refresh '{}'); require "$r" '"status": "VALID"'; echo "$r"
json_post /api/sim/network '{"state":"offline"}' >/dev/null

echo "Offline phone transfer must verify/install without licence-service access"
json_post /api/license/mock-reset '{}' >/dev/null
r=$(status); require "$r" '"status": "NOT INSTALLED"'
json_post /api/sim/network '{"state":"online"}' >/dev/null
phone=$(json_post /api/phone/entitlement '{"device_id":"EFIS-SIM-0001"}')
envelope=$(printf '%s' "$phone" | python3 -c 'import json,sys; print(json.load(sys.stdin)["license"])')
json_post /api/sim/network '{"state":"offline"}' >/dev/null
payload=$(python3 -c 'import json,sys; print(json.dumps({"device_id":"EFIS-SIM-0001","license":sys.argv[1]}))' "$envelope")
r=$(json_post /api/phone/install-license "$payload"); require "$r" '"result": "INSTALLED"'; require "$r" '"status": "VALID"'; echo "$r"
restart_sim
r=$(status); require "$r" '"status": "VALID"'; require "$r" '"network": "offline"'; echo "$r"

echo "Final state"
r=$(status); require "$r" '"status": "VALID"'; require "$r" '"network": "offline"'; echo "$r"
echo "PASS: integrity, Device-ID binding, no-entitlement, interrupted replacement, reset, offline acquisition, corrupt-store recovery, offline phone transfer and offline restart persistence."
