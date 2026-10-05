#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
command -v xcodegen >/dev/null 2>&1 || { echo "ERROR: XcodeGen is required (brew install xcodegen)." >&2; exit 1; }
for dir in "$ROOT/ios/EFISService" "$ROOT/simulator"; do
  echo "Generating Xcode project from $dir/project.yml"
  (cd "$dir" && xcodegen generate)
done
echo "Xcode projects generated successfully. project.yml files are authoritative."
