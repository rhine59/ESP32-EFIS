#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
: "${IDF_PATH:?Source the ESP-IDF export.sh first}"
cd "$ROOT"
for label in A B; do
  if [ "$label" = A ]; then version=1.0.0; else version=1.1.0; fi
  echo "== Building EFIS image $label v$version =="
  idf.py -B "build-$label" -D "EFIS_LAB_IMAGE=$label" build
  mkdir -p images
  cp "build-$label/efis_boot_lab.bin" "images/efis-$label-v$version.bin"
done
ls -lh images/*.bin
