#!/bin/bash
# Regenera las capturas de capturas/ usando el modo automático del juego.
# Requiere LÖVE 11 (flatpak org.love2d.love2d o el comando love) e ImageMagick.
set -euo pipefail
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RAIZ"
if command -v love >/dev/null; then
	LOVE=(love)
	DATOS="${XDG_DATA_HOME:-$HOME/.local/share}/love/orbita84"
else
	LOVE=(flatpak run --user --filesystem="$RAIZ/juego" org.love2d.love2d)
	DATOS="$HOME/.var/app/org.love2d.love2d/data/love/orbita84"
fi
mkdir -p capturas

# recorta la pantalla del juego (84x48 a escala 7, centrada en la ventana de 640x480)
recortar() { magick "$1" -crop 588x336+26+72 +repage "capturas/$2.png"; }

pantalla() { # $1 = salida, resto = variables de entorno
	local salida="$1"; shift
	rm -f "$DATOS/captura_pantalla.png"
	env ORBITA_CAPTURA=1 "$@" timeout 20 "${LOVE[@]}" "$RAIZ/juego" >/dev/null 2>&1 || true
	recortar "$DATOS/captura_pantalla.png" "$salida"
}

jugando() { # $1 = nivel, $2 = número de captura, $3 = salida
	rm -f "$DATOS"/captura_0*.png
	env ORBITA_CAPTURA=1 ORBITA_NIVEL="$1" timeout 40 "${LOVE[@]}" "$RAIZ/juego" >/dev/null 2>&1 || true
	recortar "$DATOS/captura_0$2.png" "$3"
}

pantalla portada_abduccion ORBITA_PANTALLA=tabla ORBITA_PORTADA=1
pantalla portada_recreativa ORBITA_PANTALLA=tabla ORBITA_PORTADA=2
pantalla portada_radar ORBITA_PANTALLA=tabla ORBITA_PORTADA=3
pantalla portada_expediente ORBITA_PANTALLA=tabla ORBITA_PORTADA=4
pantalla enemigos ORBITA_PANTALLA=enemigos
pantalla elegir_nave ORBITA_PANTALLA=nave
jugando 1 5 nivel1_roswell
jugando 3 5 nivel3_phoenix
jugando 4 5 nivel4_hangar18
pantalla prologo ORBITA_PANTALLA=prologo ORBITA_PAGINA=1
pantalla mapa_hill ORBITA_PANTALLA=mapa ORBITA_PIEZA=5
pantalla final ORBITA_PANTALLA=final ORBITA_PAGINA=2
echo "Listo: capturas/"
