#!/bin/sh
# Simulator screenshots of staged moments. Usage: art/shots_ios.sh <device udid> <out dir> [prefix] [shot ...]
# Builds the app for the simulator, installs it, and launches once per shot with HAMURABI_SHOT set.
set -e
UDID="$1"; OUT="$2"; PRE="${3:-iphone}"; shift 3 2>/dev/null || shift $#
[ $# -eq 0 ] && set -- title card orders report plague over
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; DD="${TMPDIR:-/tmp}/hamurapi-ios"
mkdir -p "$OUT"
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
( cd "$ROOT/app" && xcodegen generate >/dev/null && xcodebuild build -project Hamurapi.xcodeproj -scheme Hamurapi \
    -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$DD" -quiet 2>&1 | grep -E "error:|BUILD" || true )
APP="$DD/Build/Products/Debug-iphonesimulator/Hamurapi.app"
xcrun simctl install "$UDID" "$APP"
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 2>/dev/null || true
# Relaunch in place for each shot. Terminating first hands the screen to whatever ran before,
# and the next launch then carries a "back to that app" link in the status bar.
xcrun simctl launch --terminate-running-process "$UDID" com.nulljosh.hamurabi >/dev/null; sleep 2
for shot in "$@"; do
  SIMCTL_CHILD_HAMURABI_SHOT=$shot xcrun simctl launch --terminate-running-process "$UDID" com.nulljosh.hamurabi >/dev/null
  sleep 4
  xcrun simctl io "$UDID" screenshot "$OUT/$PRE-$shot.png" 2>/dev/null
done
xcrun simctl terminate "$UDID" com.nulljosh.hamurabi 2>/dev/null || true
ls "$OUT" | tr '\n' ' '
