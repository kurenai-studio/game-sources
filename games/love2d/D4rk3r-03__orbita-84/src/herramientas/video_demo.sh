#!/bin/bash
# Graba el demo del juego (modo arcade que se juega solo, START lo abre) para el salvapantallas
# de EmulationStation: portada + cuatro niveles con su jefe, 640x480 a 30 cuadros.
# Salida: port/orbita84/demo.mp4. Requiere LÖVE 11 (love o flatpak) y ffmpeg.
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
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

tramo() { # $1 = nombre, $2 = desde, $3 = hasta, resto = variables de entorno
	local nombre="$1" desde="$2" hasta="$3"; shift 3
	rm -rf "$DATOS/video"
	env ORBITA_CAPTURA=1 ORBITA_VIDEO=1 ORBITA_VIDEO_DESDE="$desde" ORBITA_VIDEO_HASTA="$hasta" "$@" \
		timeout 120 "${LOVE[@]}" "$RAIZ/juego" >/dev/null 2>&1 || true
	local n; n=$(ls "$DATOS/video" | wc -l)
	[ "$n" -gt 0 ] || { echo "el tramo $nombre no grabó cuadros"; exit 1; }
	# fundido a negro de medio segundo al entrar y al salir de cada tramo
	local dur; dur=$(echo "$n / 30" | bc -l)
	ffmpeg -loglevel error -y -framerate 30 -i "$DATOS/video/%05d.png" \
		-vf "fade=in:st=0:d=0.4,fade=out:st=$(echo "$dur - 0.4" | bc -l):d=0.4" \
		-c:v libx264 -pix_fmt yuv420p -preset slow -crf 20 "$TMP/$nombre.mp4"
	echo "$nombre: $n cuadros"
	echo "file '$TMP/$nombre.mp4'" >> "$TMP/lista.txt"
}

tramo portada 0 2.9
tramo nivel1 3.5 17 ORBITA_NIVEL=1
tramo nivel3 3.5 17 ORBITA_NIVEL=3
tramo nivel6 3.5 17 ORBITA_NIVEL=6
tramo nivel9 3.5 17 ORBITA_NIVEL=9
ffmpeg -loglevel error -y -f concat -safe 0 -i "$TMP/lista.txt" -c copy -movflags +faststart port/orbita84/demo.mp4
rm -rf "$DATOS/video"
ls -la port/orbita84/demo.mp4
