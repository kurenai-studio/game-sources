#!/usr/bin/env bash
# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
# Imports the project, runs the test suite and boots the game headless.
# Usage: GODOT=/path/to/godot tools/validate.sh
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
fail=0

echo "== import"
"$GODOT" --headless --path . --import 2>&1 | grep -E "ERROR|Parse Error|SCRIPT ERROR" && fail=1

echo "== tests"
out=$("$GODOT" --headless --path . res://tests/test_runner.tscn 2>&1)
status=$?
echo "$out" | grep -E "FAIL|ERROR|checks"
[ "$status" -eq 0 ] || fail=1
echo "$out" | grep -qE "SCRIPT ERROR|^ERROR" && fail=1

echo "== boot"
"$GODOT" --headless --path . --quit-after 120 2>&1 | grep -E "ERROR|Parse Error|SCRIPT ERROR" && fail=1

[ "$fail" -eq 0 ] && echo "OK" || echo "FAILED"
exit "$fail"
