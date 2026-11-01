"""Componentes recuperados del chasis de combate de AURA (se instalan en la Base Central)."""
import math

from pygame.math import Vector2

from src.entities import pickup_art as art

PART_MAGNET_RANGE = 70
PART_MAGNET_SPEED = 650
PART_KINDS = len(art.PART_NAMES)             # cabeza, torso, 2 brazos y 2 piernas = los 6 componentes del chasis


class ChassisPart(art.PickupSprite):
    """Pieza del cuerpo de AURA (cabeza, torso, brazo o pierna): no caduca; el jugador la atrae por magnetismo
    (como la chatarra, con más alcance). `index` elige la pieza (0-5); sin él se reparte al azar."""
    trail_color = (200, 90, 255)
    bob_amp = 2

    def __init__(self, pos, index=None):
        super().__init__()
        self.pos = Vector2(pos)
        self.index = art._rng.randrange(PART_KINDS) if index is None else index % PART_KINDS
        self.t = art._rng.uniform(0, 6.28)
        self._level = 0
        self._fx_init()
        self.image = art.part_frame(self.index)
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))
        self._draw()

    @property
    def part_name(self):
        return art.PART_NAMES[self.index]

    def _draw(self):
        self._level = round((0.5 + 0.5 * math.sin(self.t * 4)) * (art.PULSE_LEVELS - 1))
        self.image = art.part_frame(self.index, art.shine_index(self.t, self.index * 0.3, 2.4))

    def glow_surface(self):
        return art.part_glow(self._level)

    def update(self, dt, target=None):
        self.t += dt
        moved = False
        if target is not None and target.alive():
            to = target.pos - self.pos
            dist = to.length()
            if 0 < dist <= PART_MAGNET_RANGE:
                self.pos += to.normalize() * min(dist, PART_MAGNET_SPEED * dt)
                moved = True
        self._fx_step(dt, moved)
        self.rect.center = (round(self.pos.x), round(self.pos.y))
        self._draw()
