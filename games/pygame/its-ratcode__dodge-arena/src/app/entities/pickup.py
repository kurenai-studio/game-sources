"""Power-up pickups: the single power-up lying on the map, waiting to be walked over."""

from __future__ import annotations

import math
from typing import TYPE_CHECKING

import pygame
from pygame.math import Vector2

from app import config
from app.render.icons import draw_icon
from app.render.shapes import draw_glow, draw_progress_ring
from app.render.text import draw_text
from app.theme.accessibility import A11Y, blink_hidden, wobble
from app.theme.palette import PALETTE

if TYPE_CHECKING:
    from app.skills.powerups import PowerUp


class PowerUpPickup:
    """Holds the power-up *class*; an instance is created when the player walks over it."""

    def __init__(self, pos, kind: type[PowerUp]) -> None:
        self.pos = Vector2(pos)
        self.kind = kind
        self.remaining = config.POWERUP_MAP_LIFETIME
        self.age = 0.0

    @property
    def alive(self) -> bool:
        return self.remaining > 0

    def update(self, dt: float) -> None:
        self.remaining -= dt
        self.age += dt

    def touches(self, pos: Vector2, radius: float) -> bool:
        return self.pos.distance_squared_to(pos) <= (config.POWERUP_RADIUS + radius) ** 2

    def draw(self, surface: pygame.Surface) -> None:
        if self.remaining < config.POWERUP_BLINK_TIME and blink_hidden(self.remaining, 10):
            return                                          # blinking: about to vanish
        color = self.kind.color_of()
        c = self.pos + Vector2(0, wobble(math.sin(self.age * 3) * 3))
        r = config.POWERUP_RADIUS
        draw_glow(surface, color, c, r * 3, 150)
        # A slowly spinning diamond with the icon inside (standing still with reduced motion).
        spin = 45 if A11Y.reduced_motion else self.age * 70
        diamond = [c + Vector2(r + 3, 0).rotate(spin + k * 90) for k in range(4)]
        pygame.draw.polygon(surface, PALETTE.panel_bottom, diamond)
        pygame.draw.polygon(surface, color, diamond, 3)
        draw_icon(surface, self.kind.icon, c, 16, color)
        # The ring shows how long it stays on the map.
        draw_progress_ring(surface, c, r + 13, self.remaining / config.POWERUP_MAP_LIFETIME, color, 2)
        draw_text(surface, self.kind.name, "tiny", color, shadow=True, midtop=(c.x, c.y + r + 18))
