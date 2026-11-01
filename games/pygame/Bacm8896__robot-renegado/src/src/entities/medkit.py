"""Botiquín: lo sueltan los enemigos (y sale de los alijos de incursión). Al recogerlo va al bolsillo del Operador (máx. 5)
y [H] lo consume para devolver un bloque de vida perdido."""
import math

from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.entities import pickup_art as art

MAGNET_SPEED = 600


class Medkit(art.PickupSprite):
    trail_color = (230, 90, 90)

    def __init__(self, pos):
        super().__init__()
        self.pos = Vector2(pos)
        self.lifetime = U.MEDKITS["lifetime"]
        self.t = 0.0
        self._fx_init()
        self.image = art.medkit_frame(0)
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))
        self._draw()

    def _draw(self):
        dim = self.lifetime < 5 and int(self.lifetime * 6) % 2 == 0
        led = round((0.5 + 0.5 * math.sin(self.t * 4)) * (art.LED_LEVELS - 1))
        self.image = art.medkit_frame(led, dim)

    def update(self, dt, target=None, room=True):
        self.lifetime -= dt
        self.t += dt
        if self.lifetime <= 0:
            self.kill()
            return
        moved = False
        if room and target is not None and target.alive():              # magnetismo suave (solo con hueco en el bolsillo)
            to = target.pos - self.pos
            dist = to.length()
            if 0 < dist <= C.SCRAP_COLLECTION_RANGE:
                self.pos += to.normalize() * min(dist, MAGNET_SPEED * dt)
                moved = True
        self._fx_step(dt, moved)
        self.rect.center = (round(self.pos.x), round(self.pos.y))
        self._draw()


def medkit_drop_chance(enemy_type):
    return U.MEDKITS["enemy_chance"].get(enemy_type, 0.0)
