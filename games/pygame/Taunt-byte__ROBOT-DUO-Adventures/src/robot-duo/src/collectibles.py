"""Energy crystals."""
import math
from . import settings as S
from .collision import Box


class Crystal:
    def __init__(self, col, row):
        self.x = col * S.TILE + S.TILE / 2
        self.y = row * S.TILE + S.TILE / 2
        self.collected = False
        self.phase = (col * 0.7 + row * 1.3) % (2 * math.pi)
        self.box = Box(self.x - 13, self.y - 13, 26, 26)
        self.age = 0.0

    def update(self, dt):
        self.age += dt

    @property
    def bob(self):
        """Vertical floating offset in pixels (render only)."""
        return math.sin(self.age * 3.0 + self.phase) * 4.0
