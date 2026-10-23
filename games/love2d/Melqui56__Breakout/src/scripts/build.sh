#!/usr/bin/env bash
# build.sh — Package the portable versions of Breakout.
#
# Produces (in ./dist):
#   Breakout.love               portable game package (any OS with LÖVE)
#   Breakout-linux-x86_64.tar.gz portable Linux bundle (AppImage + game + run.sh)
#
# Usage: ./scripts/build.sh [version]   (default version: 0.1.0)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
NAME="Breakout"
VER="${1:-0.1.0}"
DIST="$ROOT/dist"
LOVE_VERSION="11.5"
mkdir -p "$DIST"

echo "==> Packing $NAME.love (v$VER)..."

# 1) Portable .love package (a zip of the project sources).
LOVE_FILE="$DIST/$NAME.love"
rm -f "$LOVE_FILE"
python3 - "$LOVE_FILE" "$ROOT" <<'PY'
import sys, zipfile, os
out, root = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for rel in ("main.lua", "conf.lua"):
        z.write(os.path.join(root, rel), rel)
    for dirpath, _dirs, files in os.walk(os.path.join(root, "src")):
        for f in sorted(files):
            if f.endswith(".lua"):
                full = os.path.join(dirpath, f)
                z.write(full, os.path.relpath(full, root))
print("packed", out)
PY

# 2) Portable Linux bundle: LÖVE AppImage + game + launcher.
LINUX_DIR="$DIST/${NAME}-linux-x86_64"
rm -rf "$LINUX_DIR"
mkdir -p "$LINUX_DIR"
if [[ ! -f "$DIST/love.AppImage" ]]; then
    echo "==> Downloading LÖVE AppImage $LOVE_VERSION..."
    curl -fL -o "$DIST/love.AppImage" \
        "https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-x86_64.AppImage"
fi
chmod +x "$DIST/love.AppImage"
cp "$DIST/love.AppImage" "$LINUX_DIR/love"
cp "$LOVE_FILE" "$LINUX_DIR/$NAME.love"
cat > "$LINUX_DIR/run.sh" <<'LAUNCH'
#!/usr/bin/env bash
# Run Breakout from this portable folder (no installation required).
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
if "$DIR/love" "$DIR/Breakout.love"; then
    exit 0
fi
# Fallback for systems without FUSE (AppImage cannot mount itself).
exec "$DIR/love" --appimage-extract-and-run "$DIR/Breakout.love"
LAUNCH
chmod +x "$LINUX_DIR/run.sh"
tar -czf "$DIST/${NAME}-linux-x86_64.tar.gz" -C "$DIST" "${NAME}-linux-x86_64"

echo ""
echo "==> Built artifacts:"
ls -lh "$LOVE_FILE" "$DIST/${NAME}-linux-x86_64.tar.gz"
echo ""
echo "    Linux portable : extract ${NAME}-linux-x86_64.tar.gz and run ./run.sh"
echo "    Any OS with love: love $LOVE_FILE"
