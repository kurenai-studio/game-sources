#!/bin/bash
# Arma la versión para YouTube Playables en youtube/ (y youtube/orbita84-youtube.zip)
# a partir de la versión web. Para probarla con la CSP de YouTube: python3 herramientas/youtube-servir.py
set -euo pipefail
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RAIZ"
bash herramientas/web.sh
rm -rf youtube
mkdir -p youtube
cp herramientas/youtube.html youtube/index.html
cp web/game.js web/love.js web/love.wasm web/paquete.wasm youtube/
(cd youtube && zip -q -9 -X orbita84-youtube.zip index.html game.js love.js love.wasm paquete.wasm)
echo "Listo: youtube/ ($(du -sh youtube/orbita84-youtube.zip | cut -f1) comprimido)"
