"""Gestor de assets gráficos (PNG) con caché en memoria y respaldo procedural.

El juego usa imágenes reales en cuanto existen en `assets/images/...`, y dibuja el arte procedural
actual cuando faltan: un asset ausente o corrupto NUNCA provoca un error, solo un aviso discreto
(una sola línea por archivo). Cada textura se carga una única vez.

Carpetas esperadas (rutas relativas a `assets/images/`):
    portraits/   operator.png, aura.png, vulcano.png        (retratos del códec)
    entities/    sprites top-down de jugador, scouts, ariete, tanques
    structures/  pilones, muros, torretas
    tiles/       suelos de refugio, asfalto, búnker
"""
import logging
from pathlib import Path

import pygame

log = logging.getLogger("robot_renegado.assets")

PROJECT_ROOT = Path(__file__).resolve().parents[2]
IMAGES_ROOT = PROJECT_ROOT / "assets" / "images"
ASSET_FOLDERS = ("portraits", "entities", "structures", "tiles")

# Emisor del diálogo -> archivo del retrato (SISTEMA y OPERADOR comparten el avatar del Operador)
PORTRAIT_FILES = {
    "AURA": "portraits/aura.png",
    "VULCANO": "portraits/vulcano.png",
    "OPERADOR": "portraits/operator.png",
    "SISTEMA": "portraits/operator.png",
}


def fit_size(size, box):
    """Tamaño que cabe en `box` conservando la proporción de `size` (sin ampliar más allá del recuadro)."""
    w, h = size
    bw, bh = box
    if w <= 0 or h <= 0:
        return max(1, bw), max(1, bh)
    scale = min(bw / w, bh / h)
    return max(1, round(w * scale)), max(1, round(h * scale))


def scale_keep_aspect(surface, box):
    """Escala `surface` para que quepa en `box` (ancho, alto) manteniendo sus proporciones."""
    size = fit_size(surface.get_size(), box)
    if size == surface.get_size():
        return surface
    return pygame.transform.smoothscale(surface, size)


class AssetManager:
    def __init__(self, root=None):
        self.root = Path(root) if root is not None else IMAGES_ROOT
        self._images = {}          # ruta relativa -> Surface | None (None = ausente o corrupto)
        self._scaled = {}          # (ruta, tamaño o caja, modo) -> Surface
        self.missing = set()       # rutas ya avisadas

    # --- rutas ---
    def path(self, rel):
        return self.root / rel

    def has(self, rel):
        """True si el archivo existe y se pudo cargar."""
        return self.load(rel) is not None

    def ensure_folders(self):
        """Crea las carpetas de recursos si no existen."""
        for folder in ASSET_FOLDERS:
            (self.root / folder).mkdir(parents=True, exist_ok=True)

    # --- carga con caché y respaldo ---
    def _warn_once(self, rel, reason):
        if rel not in self.missing:
            self.missing.add(rel)
            log.warning("asset '%s' no disponible (%s): se usa el dibujo procedural", rel, reason)

    def load(self, rel):
        """Carga la imagen una sola vez (`convert_alpha`). Devuelve None si falta o no se puede leer."""
        rel = str(rel).replace("\\", "/")
        if rel in self._images:
            return self._images[rel]
        image = None
        file = self.path(rel)
        if not file.is_file():
            self._warn_once(rel, "no existe")
        else:
            try:
                image = pygame.image.load(str(file))
                if pygame.display.get_surface() is not None:     # convert_alpha exige un modo de video activo
                    image = image.convert_alpha()
            except (pygame.error, OSError, ValueError) as exc:
                image = None
                self._warn_once(rel, f"ilegible: {exc}")
        self._images[rel] = image
        return image

    def get(self, rel, fallback=None):
        """Imagen cargada o, si falta, el respaldo (`Surface` o función sin argumentos que devuelve una)."""
        image = self.load(rel)
        if image is not None:
            return image
        return fallback() if callable(fallback) else fallback

    # --- escalado con caché ---
    def scaled(self, rel, size, fallback=None):
        """Imagen escalada exactamente a `size`."""
        key = (str(rel), tuple(size), "exact")
        if key not in self._scaled:
            image = self.load(rel)
            if image is None:
                return fallback() if callable(fallback) else fallback
            self._scaled[key] = pygame.transform.smoothscale(image, tuple(size))
        return self._scaled[key]

    def fitted(self, rel, box, fallback=None):
        """Imagen escalada para caber en `box` conservando la proporción."""
        key = (str(rel), tuple(box), "fit")
        if key not in self._scaled:
            image = self.load(rel)
            if image is None:
                return fallback() if callable(fallback) else fallback
            self._scaled[key] = scale_keep_aspect(image, box)
        return self._scaled[key]

    def portrait(self, sender, size):
        """Retrato del emisor ajustado a `size`, o None si no hay archivo (el llamador dibuja el procedural)."""
        rel = PORTRAIT_FILES.get(sender)
        return self.fitted(rel, size) if rel else None

    def clear(self):
        """Olvida la caché (p. ej. para recargar assets recién añadidos) y los avisos ya emitidos."""
        self._images.clear()
        self._scaled.clear()
        self.missing.clear()


assets = AssetManager()        # instancia compartida por el juego
