#!/usr/bin/env bash
# Run from anywhere. GODOT_BIN may name an absolute executable or a PATH entry.
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
godot_bin="${GODOT_BIN:-godot}"
if ! command -v "$godot_bin" >/dev/null 2>&1; then
  echo "Godot executable not found: $godot_bin. Set GODOT_BIN to Godot 4.5.1." >&2
  exit 1
fi
log_dir="$(mktemp -d)"
trap 'rm -rf "$log_dir"' EXIT
run_check() {
  local check_name="$1"
  shift
  echo "Running $check_name"
  if ! timeout 90 "$godot_bin" --headless --path "$project_root" "$@" >"$log_dir/$check_name.log" 2>&1; then
    cat "$log_dir/$check_name.log"
    return 1
  fi
  cat "$log_dir/$check_name.log"
  # Godot can exit successfully despite parse/runtime errors; reject the log too.
  if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Assertion failed' "$log_dir/$check_name.log"; then
    echo "$check_name reported a Godot error." >&2
    return 1
  fi
}
run_check import --editor --quit
run_check rules --script res://tests/test_rules.gd
run_check integration --script res://tests/test_integration.gd
run_check playthrough --script res://tests/test_playthrough.gd
run_check scene --quit-after 180
echo "Running rendered UI input and layout checks"
if ! timeout 90 xvfb-run -a "$godot_bin" --path "$project_root" --audio-driver Dummy --script res://tests/test_ui.gd >"$log_dir/ui.log" 2>&1; then
  cat "$log_dir/ui.log"
  exit 1
fi
cat "$log_dir/ui.log"
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Assertion failed' "$log_dir/ui.log"; then
  echo "UI validation reported a Godot error." >&2
  exit 1
fi
echo "All Godot checks passed."
