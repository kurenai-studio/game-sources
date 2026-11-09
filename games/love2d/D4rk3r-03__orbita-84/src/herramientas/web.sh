#!/bin/bash
# Arma la versión para navegador en web/ con love.js (modo compatibilidad,
# no necesita cabeceras especiales en el servidor). Requiere Node.js.
set -euo pipefail
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RAIZ"
bash herramientas/empaquetar.sh
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
npx --yes love.js@11.4.1 -c -t "Orbita 84" port/orbita84/orbita84.love "$tmp/web" >/dev/null
cp "$tmp/web/love.js" "$tmp/web/love.wasm" web/
# el paquete del juego se sirve como .wasm porque algunos servidores no sirven .data
cp "$tmp/web/game.data" web/paquete.wasm
sed "s/'game.data'/'paquete.wasm'/g" "$tmp/web/game.js" > web/game.js
echo "Listo: web/ (abrir web/index.html desde un servidor, por ejemplo: python3 -m http.server -d web)"
