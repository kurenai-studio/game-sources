"""Lasers: beams across the whole arena, aimed through the player's position."""

import pygame
from pygame.math import Vector2

from app import config
from app.theme.accessibility import A11Y, blink_hidden
from app.theme.palette import PALETTE
from app.util.geometry import RotatedRect
from app.util.mathx import clamp


class Laser:
    """Three phases: warning (harmless telegraph) -> firing (deadly) -> fade (harmless).

    The beam passes through ``target`` (the player's position when it was cast)
    from a random angle, and is long enough to cross the whole arena.
    """

    def __init__(self, origin, target, warning_time: float) -> None:
        direction = Vector2(target) - Vector2(origin)
        self.shape = RotatedRect(target, direction, config.LASER_LENGTH, config.LASER_WIDTH)
        self.warning_time = warning_time
        self.age = 0.0
        self.disarmed = False           # set once a shield blocks it, so it can't hit again
        self.grazed = False             # fired while the player was just outside it ...
        self.near_miss_counted = False  # ... and has already paid out as a close call

    @property
    def firing(self) -> bool:
        return self.warning_time <= self.age < self.warning_time + config.LASER_ACTIVE_TIME

    @property
    def deadly(self) -> bool:
        return self.firing and not self.disarmed

    @property
    def alive(self) -> bool:
        return self.age < self.warning_time + config.LASER_ACTIVE_TIME + config.LASER_FADE_TIME

    def update(self, dt: float) -> None:
        self.age += dt

    def band(self, width: float) -> list[Vector2]:
        """Corners of a strip along the beam with the given width (for layered drawing)."""
        return RotatedRect(self.shape.center, self.shape.direction, self.shape.length, width).corners()

    def draw(self, layer: pygame.Surface) -> None:
        """Draw onto a transparent full-screen layer (alpha is needed for the glow)."""
        if self.age < self.warning_time:
            # Warning: an outlined lane plus a strip that widens until the beam fires.
            p = self.age / self.warning_time
            flicker = 0 if blink_hidden(self.age, 20) else 20
            pygame.draw.polygon(layer, (*PALETTE.laser, 25 + int(35 * p)), self.band(config.LASER_WIDTH))
            pygame.draw.polygon(layer, (*PALETTE.laser, 150 + flicker), self.band(config.LASER_WIDTH), 2)
            pygame.draw.polygon(layer, (*PALETTE.laser, 60 + int(120 * p)),
                                self.band(max(2.0, config.LASER_WIDTH * p)))
            if A11Y.outlines:
                pygame.draw.polygon(layer, (*PALETTE.text, 230), self.band(config.LASER_WIDTH + 4), 2)
        elif self.firing:
            # Firing: wide glow, colored body, white-hot core.
            pygame.draw.polygon(layer, (*PALETTE.laser, 90), self.band(config.LASER_WIDTH * 1.5))
            pygame.draw.polygon(layer, (*PALETTE.laser, 220), self.band(config.LASER_WIDTH))
            pygame.draw.polygon(layer, (*PALETTE.laser_core, 255), self.band(config.LASER_WIDTH * 0.35))
            if A11Y.outlines:
                pygame.draw.polygon(layer, (*PALETTE.text, 255), self.band(config.LASER_WIDTH + 4), 3)
        else:
            # Fade-out. Clamped: a laser may age past its end before it is removed.
            f = clamp(1 - (self.age - self.warning_time - config.LASER_ACTIVE_TIME) / config.LASER_FADE_TIME,
                      0.0, 1.0)
            if f > 0:
                pygame.draw.polygon(layer, (*PALETTE.laser, int(180 * f)),
                                    self.band(max(2.0, config.LASER_WIDTH * f)))
