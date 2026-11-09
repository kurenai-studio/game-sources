#!/bin/bash
# Arma port/orbita84/orbita84.love con el código del juego y prueba la lógica antes.
set -euo pipefail
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RAIZ"
luajit herramientas/probar_logica.lua
rm -f port/orbita84/orbita84.love
(cd juego && zip -q -9 -X ../port/orbita84/orbita84.love conf.lua main.lua logica.lua datos.lua fondos.lua portada.lua tactil.lua puente.lua idioma.lua)
echo "Listo: port/orbita84/orbita84.love ($(stat -c %s port/orbita84/orbita84.love) bytes)"
