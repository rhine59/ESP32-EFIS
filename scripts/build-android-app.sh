#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
cd "$ROOT/customer-app/android"
GRADLE="$(command -v gradle 2>/dev/null || true)"
[ -n "$GRADLE" ] || { echo "gradle not found" >&2; exit 1; }
: "${ANDROID_HOME:=$HOME/Library/Android/sdk}"
if [ -x /usr/libexec/java_home ]; then JAVA_HOME="$(/usr/libexec/java_home -v 17)"; export JAVA_HOME; fi
export ANDROID_HOME
"$GRADLE" :app:assembleDebug
printf 'APK: %s\n' "$ROOT/customer-app/android/app/build/outputs/apk/debug/app-debug.apk"
