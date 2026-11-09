#!/bin/bash
# Arma la versión para itch.io en itch/ (y itch/orbita84-itch.zip): es la página de YouTube
# sin el SDK, así fuera de YouTube ocupa toda la ventana y guarda los récords en el navegador.
set -euo pipefail
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RAIZ"
bash herramientas/web.sh
rm -rf itch
mkdir -p itch
grep -v 'game_api/v1\|El SDK de YouTube Playables' herramientas/youtube.html > itch/index.html
cp web/game.js web/love.js web/love.wasm web/paquete.wasm itch/
(cd itch && zip -q -9 -X orbita84-itch.zip index.html game.js love.js love.wasm paquete.wasm)
# copia lista para subir: publicar/itch/ (junto a las imágenes de la página)
mkdir -p publicar/itch
cp itch/orbita84-itch.zip publicar/itch/
echo "Listo: itch/ ($(du -sh itch/orbita84-itch.zip | cut -f1) comprimido; para subir: publicar/itch/orbita84-itch.zip)"
