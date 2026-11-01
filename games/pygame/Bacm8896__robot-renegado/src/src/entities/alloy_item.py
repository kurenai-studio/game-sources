"""Aleación Militar (▣) en el suelo: lingotes prensados con franja de advertencia. Solo arte/animación:
hoy la aleación se abona directamente al inventario y no se suelta; esta entidad no está conectada a ningún drop."""
from pygame.math import Vector2

import config as C
from src.entities import pickup_art as art

MAGNET_SPEED = 600
LIFETIME = 120.0                      # (derivado) es el recurso más raro


class AlloyItem(art.PickupSprite):
    is_alloy = True
    trail_color = (200, 210, 224)

    def __init__(self, pos, value=1):
        super().__init__()
        self.pos = Vector2(pos)
        self.value = value
        self.lifetime = LIFETIME
        self.t = 0.0
        self._fx_init()
        self.image = art.alloy_frame()
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))
        self._draw()

    def _draw(self):
        dim = self.lifetime < 8 and int(self.lifetime * 6) % 2 == 0
        self.image = art.alloy_frame(art.shine_index(self.t, 0.0, 2.6), dim)      # reflejo cromado que barre

    def update(self, dt, target=None):
        self.lifetime -= dt
        self.t += dt
        if self.lifetime <= 0:
            self.kill()
            return
        moved = False
        if target is not None and target.alive():
            to = target.pos - self.pos
            dist = to.length()
            if 0 < dist <= C.SCRAP_COLLECTION_RANGE:
                self.pos += to.normalize() * min(dist, MAGNET_SPEED * dt)
                moved = True
        self._fx_step(dt, moved)
        self.rect.center = (round(self.pos.x), round(self.pos.y))
        self._draw()
