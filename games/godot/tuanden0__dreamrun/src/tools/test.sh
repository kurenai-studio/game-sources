#!/usr/bin/env bash
# Run the headless Godot tests. A GDScript runtime error does not change Godot's exit
# code, so also fail when the output contains one. A script that fails to parse can leave a
# test awaiting forever, so the whole run is cut off after TEST_TIMEOUT seconds (default 480).
set -u
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
"$GODOT" --headless --path game --import >/dev/null 2>&1
# --fixed-fps 60 advances the game one 1/60 s step per frame without waiting for the clock: the whole run takes seconds, not minutes
out=$(timeout "${TEST_TIMEOUT:-480}" "$GODOT" --headless --path game --fixed-fps 60 --script res://tests/run_all.gd 2>&1)
code=$?
echo "$out"
if [ "$code" -eq 124 ]; then echo "TIMEOUT: tests did not finish (a script that failed to parse can hang a test)"; fi
if echo "$out" | grep -qE "SCRIPT ERROR|Parse Error"; then code=1; fi
exit $code
