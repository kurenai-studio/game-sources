"""Núcleo de Plasma (🔷) en el suelo: escaso y valioso. Lo sueltan Arietes y Tanques y los alijos de plasma."""
import math

from pygame.math import Vector2

import config as C
from src.entities import pickup_art as art

MAGNET_SPEED = 600
LIFETIME = 90.0                       # (derivado) dura bastante más que la chatarra: es escaso


class CoreItem(art.PickupSprite):
    is_core = True                  # botín de plasma (el Carroñero lo distingue de la chatarra)
    trail_color = (90, 230, 255)
    bob_amp = 2                     # flotación ±2 px

    def __init__(self, pos, value=1):
        super().__init__()
        self.pos = Vector2(pos)
        self.value = value
        self.lifetime = LIFETIME
        self.t = art._rng.uniform(0, 6.28)                              # fase propia: no pulsan todos a la vez
        self._level = 0
        self._dim = False
        self._fx_init()
        self.image = art.core_frame(0, self._extra())
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))
        self._draw()

    def _extra(self):
        return min(self.value, 5) - 1 if self.value > 1 else 0       # varios núcleos juntos: puntos extra

    def _draw(self):
        self._dim = self.lifetime < 8 and int(self.lifetime * 6) % 2 == 0
        self._level = round((0.5 + 0.5 * math.sin(self.t * 4)) * (art.PULSE_LEVELS - 1))
        self.image = art.core_frame(self._level, self._extra(), self._dim)

    def glow_surface(self):
        return None if self._dim else art.core_glow(self._level)

    def update(self, dt, target=None):
        self.lifetime -= dt
        self.t += dt
        if self.lifetime <= 0:
            self.kill()
            return
        moved = False
        if target is not None and target.alive():                      # magnetismo suave, como la chatarra
            to = target.pos - self.pos
            dist = to.length()
            if 0 < dist <= C.SCRAP_COLLECTION_RANGE:
                self.pos += to.normalize() * min(dist, MAGNET_SPEED * dt)
                moved = True
        self._fx_step(dt, moved)
        self.rect.center = (round(self.pos.x), round(self.pos.y))
        self._draw()
