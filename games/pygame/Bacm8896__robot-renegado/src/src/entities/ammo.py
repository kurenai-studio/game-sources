"""Caja de munición: la sueltan los enemigos (30%) y da +50 balas al recogerla (Acto 2 en adelante)."""
import math

from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.entities import pickup_art as art

MAGNET_SPEED = 600


class AmmoBox(art.PickupSprite):
    trail_color = (150, 200, 90)

    def __init__(self, pos, amount=None):
        super().__init__()
        self.pos = Vector2(pos)
        self.amount = U.AMMO_SYSTEM["ammo_drop_amount"] if amount is None else amount
        self.lifetime = U.AMMO_SYSTEM["box_lifetime"]
        self.t = 0.0
        self._fx_init()
        self.image = art.ammo_frame(0)
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))
        self._draw()

    def _draw(self):
        dim = self.lifetime < 5 and int(self.lifetime * 6) % 2 == 0
        led = round((0.5 + 0.5 * math.sin(self.t * 5)) * (art.LED_LEVELS - 1))      # LED verde que late
        self.image = art.ammo_frame(led, dim)

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
