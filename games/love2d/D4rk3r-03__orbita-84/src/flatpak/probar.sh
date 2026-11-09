#!/bin/bash
# Arma e instala el Flatpak de Órbita 84 en este equipo (usuario) con el código de esta carpeta,
# y pasa el revisor de Flathub. Requiere org.flatpak.Builder y org.freedesktop.Sdk//26.08.
# Después: flatpak run io.github.d4rk3r_03.orbita-84
set -euo pipefail
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ID=io.github.d4rk3r_03.orbita-84
OBRA="$AQUI/.obra"
mkdir -p "$OBRA"

# la receta de Flathub, pero con el juego tomado de esta carpeta en vez de GitHub
python3 - "$AQUI/$ID.yaml" "$OBRA/$ID.yaml" <<'EOF'
import sys
t = open(sys.argv[1]).read()
i = t.index("      - type: git\n        url: https://github.com/D4rk3r-03/orbita-84.git")
local = """      - type: archive
        path: fuente.tar
"""
open(sys.argv[2], "w").write(t[:i] + local)
EOF

# solo los archivos que están en git (con su contenido actual), como los verá Flathub
(cd "$AQUI/.." && git ls-files -z | tar --null -T - --transform 's|^|orbita-84/|' -cf "$OBRA/fuente.tar")

cd "$OBRA"
flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest "$AQUI/$ID.yaml" || true
flatpak run org.flatpak.Builder --user --install --force-clean --jobs="${TRABAJOS:-2}" --install-deps-from=flathub \
	--state-dir="$OBRA/estado" --repo="$OBRA/repo" "$OBRA/construir" "$OBRA/$ID.yaml"
flatpak run --command=flatpak-builder-lint org.flatpak.Builder repo "$OBRA/repo" || true
echo "Listo: flatpak run $ID"
