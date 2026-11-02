#!/bin/bash
# Builds Kindred Lights: game.love, Windows (64-bit) and macOS zips.
set -e
cd "$(dirname "$0")"
NAME="KindredLights"
OUT=dist
rm -rf "$OUT" build_tmp && mkdir -p "$OUT" build_tmp
# 1. .love
(cd game && zip -9 -q -r "../$OUT/$NAME.love" . -x "*.DS_Store")
# 2. Windows
unzip -q dist_src/love-11.5-win64.zip -d build_tmp
W=build_tmp/$NAME-win64
mkdir -p "$W"
cat build_tmp/love-11.5-win64/love.exe "$OUT/$NAME.love" > "$W/$NAME.exe"
cp build_tmp/love-11.5-win64/*.dll "$W/"
cp build_tmp/love-11.5-win64/license.txt "$W/LOVE-license.txt"
cp README-player.txt "$W/README.txt"
(cd build_tmp && zip -9 -q -r "../$OUT/$NAME-win64.zip" "$NAME-win64")
# 3. macOS
unzip -q dist_src/love-11.5-macos.zip -d build_tmp/mac
APP="build_tmp/mac/Kindred Lights.app"
mv build_tmp/mac/love.app "$APP"
cp "$OUT/$NAME.love" "$APP/Contents/Resources/$NAME.love"
PL="$APP/Contents/Info.plist"
python3 - "$PL" <<'PY'
import plistlib, sys
p = sys.argv[1]
with open(p, 'rb') as f: d = plistlib.load(f)
d['CFBundleIdentifier'] = 'io.github.ridakalam52-design.kindredlights'
d['CFBundleName'] = 'Kindred Lights'
d['CFBundleDisplayName'] = 'Kindred Lights'
d.pop('UTExportedTypeDeclarations', None)
d.pop('CFBundleDocumentTypes', None)
with open(p, 'wb') as f: plistlib.dump(d, f)
PY
cp README-player.txt "build_tmp/mac/README.txt"
(cd build_tmp/mac && zip -9 -q -y -r "../../$OUT/$NAME-macos.zip" "Kindred Lights.app" README.txt)
rm -rf build_tmp
ls -la "$OUT"
