from pygame.math import Vector2

import config as C
from src.entities import pickup_art as art

MAGNET_SPEED = 650


class ScrapItem(art.PickupSprite):
    """Chatarra recuperada en disputa (3 variantes, destello cada ~2 s). Parpadea antes de desaparecer y es atraída por el jugador."""
    trail_color = (214, 140, 90)

    def __init__(self, pos, value=C.SCRAP_VALUE):
        super().__init__()
        self.pos = Vector2(pos)
        self.value = value
        self.lifetime = C.SCRAP_LIFETIME
        self.glow_timer = 0
        self.variant = art._rng.randrange(3)
        self._shine_offset = art._rng.uniform(0, 2.0)          # que no destellen todas a la vez
        self._fx_init()
        self.image = art.scrap_frame(self.variant)
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))
        self._draw()

    def _draw(self):
        dim = self.lifetime < 5 and int(self.lifetime * 6) % 2 == 0
        self.image = art.scrap_frame(self.variant, art.shine_index(self.glow_timer, self._shine_offset), dim)

    def update(self, dt, target=None):
        self.lifetime -= dt
        self.glow_timer += dt
        if self.lifetime <= 0:
            self.kill()
            return
        moved = False
        # Magnetismo: a menos de 35 px del jugador la chatarra vuela hacia él
        if target is not None and target.alive():
            to = target.pos - self.pos
            dist = to.length()
            if 0 < dist <= C.SCRAP_COLLECTION_RANGE:
                self.pos += to.normalize() * min(dist, MAGNET_SPEED * dt)
                moved = True
        self._fx_step(dt, moved)
        self.rect.center = (round(self.pos.x), round(self.pos.y))
        self._draw()


Scrap = ScrapItem      # alias por compatibilidad
