#!/usr/bin/env bash
# Build the qa (test-channel) APK, install it and run the on-device checks through
# the debug scripting hook. Exits non-zero if any expected result is missing.
set -euo pipefail
cd "$(dirname "$0")/.."
SERIAL="${SERIAL:-}"
ADB=(adb); [ -n "$SERIAL" ] && ADB=(adb -s "$SERIAL")
APP_ID="app.mobilecad.i18n.test"
PKG="app/app/build/outputs/apk/arm64/qa/app-arm64-qa.apk"

if [ "${SKIP_BUILD:-0}" != "1" ]; then
  (cd app && ./gradlew --console=plain :app:assembleArm64Qa --no-daemon)
fi
[ -f "$PKG" ] || { echo "missing $PKG" >&2; exit 1; }

if [ "${SKIP_INSTALL:-0}" != "1" ]; then
  "${ADB[@]}" install -r "$PKG" >/dev/null
fi
"${ADB[@]}" shell am force-stop "$APP_ID"
"${ADB[@]}" shell am start -n "$APP_ID/app.mobilecad.MainActivity" >/dev/null
echo "waiting for the engine…"
sleep "${ENGINE_WAIT:-25}"
"${ADB[@]}" logcat -c

for script in device_check.py device_extra.py; do
  echo "== $script"
  "${ADB[@]}" shell am start -n "$APP_ID/app.mobilecad.MainActivity" --es runchecks "$script" >/dev/null
  sleep 8
done

LOG=$("${ADB[@]}" logcat -d -s fcscript:V)
fail=0
check() { if grep -q "$1" <<< "$2"; then echo "ok   $1"; else echo "MISS $1" >&2; fail=1; fi; }
check '"bridge": 2' "$LOG"
check '"placement_changes_mesh": true' "$LOG"
check '"link_updates": true' "$LOG"
check '"clear_on_new_document": true' "$LOG"
check '"sketch_updates": true' "$LOG"
check '"redo_same_mesh": true' "$LOG"
check 'badarg=' "$LOG"
check 'unknown argument' "$LOG"
[ "$fail" -eq 0 ] && echo "ALL CHECKS PASSED" || { echo "CHECKS FAILED" >&2; exit 1; }
