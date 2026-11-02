#!/bin/bash
# Packages a clean, deploy-ready zip of GOAL RUSH for GitHub → Render.
# Excludes build artifacts, the sandbox database and platform-only files.
set -euo pipefail

SRC="/home/z/my-project"
OUT="/home/z/my-project/download/goal-rush-deploy.zip"
STAGE="$(mktemp -d)/goal-rush"
mkdir -p "$STAGE" "$(dirname "$OUT")"

# --- root files (deploy-relevant only) -------------------------------------
for f in package.json bun.lock tsconfig.json next.config.ts tailwind.config.ts \
         postcss.config.mjs components.json eslint.config.mjs README.md \
         render.yaml .env.example .gitignore; do
  cp "$SRC/$f" "$STAGE/"
done

# --- directories ------------------------------------------------------------
cp -r "$SRC/prisma" "$STAGE/prisma"
cp -r "$SRC/public" "$STAGE/public"
cp -r "$SRC/src"    "$STAGE/src"
cp -r "$SRC/docs"   "$STAGE/docs"
cp -r "$SRC/scripts" "$STAGE/scripts"
cp -r "$SRC/examples" "$STAGE/examples"
cp -r "$SRC/tests"  "$STAGE/tests"

# --- zip it -----------------------------------------------------------------
rm -f "$OUT"
cd "$(dirname "$STAGE")"
zip -qr "$OUT" "goal-rush"
rm -rf "$(dirname "$STAGE")"

echo "Created $OUT"
unzip -l "$OUT" | tail -3
