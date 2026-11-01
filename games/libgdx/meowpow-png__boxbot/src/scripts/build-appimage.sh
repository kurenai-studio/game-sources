#!/usr/bin/env bash

set -euo pipefail

version="${1:?Usage: build-appimage.sh <version>}"

image_dir="lwjgl3/build/jpackage/image/Boxbot"
appdir="lwjgl3/build/jpackage/Boxbot.AppDir"
dist_dir="lwjgl3/build/jpackage/dist"
appimagetool="lwjgl3/build/jpackage/appimagetool"
icon="packaging/linux/boxbot.png"

if [ ! -f "$icon" ]; then
  echo "::error::Missing $icon — appimagetool requires an icon at the AppDir root."
  exit 1
fi

curl -L -o "$appimagetool" \
  https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x "$appimagetool"

rm -rf "$appdir"
mkdir -p "$appdir"
cp -r "$image_dir"/. "$appdir"/
cp "$icon" "$appdir/boxbot.png"

cat > "$appdir/Boxbot.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Boxbot
Exec=bin/Boxbot
Icon=boxbot
Categories=Game;
EOF

cat > "$appdir/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/bin/Boxbot" "$@"
EOF
chmod +x "$appdir/AppRun"

mkdir -p "$dist_dir"
ARCH=x86_64 "$appimagetool" "$appdir" "$dist_dir/Boxbot-$version-x86_64.AppImage"
