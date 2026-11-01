#!/usr/bin/env bash
# Builds the debug APK: build/sumup-debug.apk
#
# Run from any folder, in Git Bash:
#   scripts/build.sh
#   scripts/build.sh --icons
#
# --icons redraws the launcher icon PNGs in launcher/ first, with
# tools/launcher_icon.tscn. The build also does this when one of the four PNGs
# is missing. The icon tool opens a window for a moment and closes by itself.
#
# Godot 4.7.2 must be on PATH as "godot", or set the GODOT environment variable
# to the full path of the Godot exe. The Android SDK, the JDK and the debug
# keystore come from Godot's Editor Settings (see README.md).

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot="${GODOT:-godot}"
apk="$root/build/sumup-debug.apk"
want_version="4.7.2.stable"

icons=0
for arg in "$@"; do
	case "$arg" in
		--icons) icons=1 ;;
		*) echo "Unknown option: $arg (the only option is --icons)"; exit 1 ;;
	esac
done

if ! command -v "$godot" > /dev/null 2>&1; then
	echo "Godot was not found as '$godot'. Install Godot $want_version or set GODOT to the full path of its exe."
	exit 1
fi

version="$("$godot" --version | tr -d '\r' | tail -n 1)"
case "$version" in
	"$want_version"*) echo "Godot $version" ;;
	*) echo "This project needs Godot $want_version, but '$godot' is version '$version'."; exit 1 ;;
esac

for f in main_192.png adaptive_foreground_432.png adaptive_background_432.png adaptive_monochrome_432.png; do
	if [ ! -f "$root/launcher/$f" ]; then
		icons=1
	fi
done
if [ "$icons" = 1 ]; then
	echo "Drawing the launcher icons (tools/launcher_icon.tscn)..."
	if ! "$godot" --path "$root" res://tools/launcher_icon.tscn; then
		echo "The launcher icon tool failed."
		exit 1
	fi
fi

echo "Importing the project..."
if ! "$godot" --headless --path "$root" --import; then
	echo "The import failed."
	exit 1
fi

mkdir -p "$root/build"
rm -f "$apk"

echo "Exporting the debug APK..."
if ! "$godot" --headless --path "$root" --export-debug "Android" "$apk" || [ ! -f "$apk" ]; then
	echo "The export failed. Read the Godot output above."
	exit 1
fi

size_mb="$(( $(wc -c < "$apk") / 1048576 ))"
echo "Built $apk (about $size_mb MB)"
echo "Install it with: scripts/install.sh"
