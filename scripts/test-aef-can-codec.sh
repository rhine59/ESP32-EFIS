#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OUT="${TMPDIR:-/tmp}/aef-can-codec-test"
cc -std=c11 -Wall -Wextra -Werror -pedantic -I"$ROOT/firmware/main" "$ROOT/firmware/main/aef_can_codec.c" "$ROOT/tests/aef_can_codec_test.c" -o "$OUT"
"$OUT"
