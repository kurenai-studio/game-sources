#!/bin/sh
# Headless checks. Fails on any failed check or any script error.
#   ./test.sh          the full suite
#   ./test.sh --quick  one seed of AI-vs-AI battles
set -u
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
cd "$(dirname "$0")"
# Private paths are never tracked: the owner's prompt log lives in his
# notebook (CLAUDE.md, "Private paths").
if [ -n "$(git ls-files notes/prompts.md 2>/dev/null)" ]; then
  echo "FAILED: notes/prompts.md is tracked; it must stay a gitignored symlink"
  exit 1
fi
"$GODOT" --headless --path . --import >/dev/null 2>&1
out=$("$GODOT" --headless --path . -s tests/run_tests.gd -- "$@" 2>&1)
status=$?
printf '%s\n' "$out" | grep -v '^Godot Engine'
if printf '%s' "$out" | grep -q 'SCRIPT ERROR\|Parse Error'; then
  echo "FAILED: script errors"
  exit 1
fi
exit $status
