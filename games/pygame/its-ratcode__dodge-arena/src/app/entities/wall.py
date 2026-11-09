"""Walls: temporary barriers that destroy bolts (lasers pass through)."""

import pygame

from app import config
from app.theme.accessibility import blink_hidden
from app.theme.palette import PALETTE
from app.util.geometry import RotatedRect
from app.util.mathx import clamp, lerp_color


class Wall:
    """A thin rotated rectangle that lives for ``duration`` seconds."""

    def __init__(self, center, along, length: float = config.WALL_LENGTH,
                 duration: float = config.WALL_DURATION) -> None:
        self.shape = RotatedRect(center, along, length, config.WALL_THICKNESS)
        self.duration = duration
        self.remaining = duration

    @property
    def alive(self) -> bool:
        return self.remaining > 0

    def update(self, dt: float) -> None:
        self.remaining -= dt

    def draw(self, surface: pygame.Surface) -> None:
        s = self.shape
        color, outline = PALETTE.wall, PALETTE.wall_outline
        # Blink just before vanishing so it never disappears by surprise.
        if self.remaining < config.WALL_BLINK_TIME and blink_hidden(self.remaining, 14):
            color = lerp_color(color, PALETTE.arena_center, 0.6)
            outline = lerp_color(outline, PALETTE.arena_center, 0.6)
        aura = RotatedRect(s.center, s.direction, s.length + 12, s.width + 14).corners()
        pygame.draw.polygon(surface, lerp_color(PALETTE.wall, PALETTE.arena_center, 0.72), aura)
        corners = s.corners()
        pygame.draw.polygon(surface, color, corners)
        pygame.draw.polygon(surface, outline, corners, 2)
        # The spine shrinks as the wall's lifetime runs out.
        half = s.direction * ((s.length / 2 - 6) * clamp(self.remaining / self.duration, 0.0, 1.0))
        pygame.draw.line(surface, outline, s.center - half, s.center + half, 2)
