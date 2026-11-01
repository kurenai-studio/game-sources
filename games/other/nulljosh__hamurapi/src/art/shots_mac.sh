#!/bin/sh
# Mac screenshots of staged moments. Usage: art/shots_mac.sh <built Hamurapi.app> <out dir> [shot ...]
# The window is 1280x800, an App Store size on a 1x display.
APP="$1"; OUT="$2"; shift 2
[ $# -eq 0 ] && set -- title card orders report plague over
mkdir -p "$OUT"
for shot in "$@"; do
  pkill -x Hamurapi 2>/dev/null; sleep 0.5
  # -reigns and -best override the saved records for this launch only, so a shot never shows (or changes) a real player's grade
  HAMURABI_SHOT=$shot "$APP/Contents/MacOS/Hamurapi" -reigns 0 -best "" >/dev/null 2>&1 &
  sleep 3
  osascript -e 'tell application "System Events" to tell process "Hamurapi"
    set frontmost to true
    set position of window 1 to {300, 120}
    set size of window 1 to {1280, 800}
  end tell' >/dev/null
  sleep 1.5
  screencapture -x -R300,120,1280,800 "$OUT/mac-$shot.png"
done
pkill -x Hamurapi 2>/dev/null
ls "$OUT"
