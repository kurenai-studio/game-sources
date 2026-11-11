#!/usr/bin/env bash
# Matching Godot export templates required. Android also needs configured SDK/JDK17.
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
godot_bin="${GODOT_BIN:-godot}"
mkdir -p build/linux build/web build/android build/release
touch build/.gdignore
export_one() {
  local mode="$1" preset="$2" destination="$3"
  local log="build/export-${preset}.log"
  if ! "$godot_bin" --headless --path "$project_root" "$mode" "$preset" "$destination" >"$log" 2>&1; then
    cat "$log"
    return 1
  fi
  if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:' "$log"; then
    cat "$log"
    return 1
  fi
  echo "Exported $preset: $destination"
}
export_one --export-release Linux build/linux/buraco-politico.x86_64
export_one --export-release Web build/web/index.html
export_one --export-debug Android build/android/buraco-politico.apk
cp LICENSE assets/fonts/OFL-*.txt build/linux/
cp LICENSE assets/fonts/OFL-*.txt build/web/
(cd build/linux && zip -q -r ../release/buraco-politico-linux-x86_64.zip . -x '*.import')
(cd build/web && zip -q -r ../release/buraco-politico-web.zip . -x '*.import')
cp build/android/buraco-politico.apk build/release/buraco-politico-android-arm64-debug.apk
(cd build/release && sha256sum *.zip *.apk > SHA256SUMS.txt)
echo "Release artifacts: build/release"
