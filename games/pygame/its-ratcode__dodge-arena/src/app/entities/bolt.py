"""Bolts: rectangles that fly straight through the spot the player stood on."""

import pygame
import pygame.gfxdraw
from pygame.math import Vector2

from app import config
from app.render.shapes import draw_glow
from app.theme.accessibility import A11Y
from app.theme.palette import PALETTE
from app.util.geometry import RotatedRect

SCREEN_CENTER = Vector2(config.SCREEN_WIDTH / 2, config.SCREEN_HEIGHT / 2)


class Bolt:
    """Aims once, at spawn, at ``target`` (the player's position at that moment),
    then flies in a straight line - it never follows the player - until it has
    left the screen on the other side."""

    def __init__(self, spawn_pos, target, speed: float = config.BOLT_SPEED_START) -> None:
        direction = Vector2(target) - Vector2(spawn_pos)
        if direction.length_squared() == 0:
            direction = SCREEN_CENTER - Vector2(spawn_pos)
        self.shape = RotatedRect(spawn_pos, direction, config.BOLT_LENGTH, config.BOLT_WIDTH)
        self.velocity = self.shape.direction * speed
        self.grazing = False                # came within close-call distance of the player ...
        self.near_miss_counted = False      # ... and has already paid out as a close call

    def update(self, dt: float) -> None:
        self.shape.center += self.velocity * dt

    def is_off_screen(self) -> bool:
        """True once the bolt is fully outside the screen and moving away from it."""
        margin = self.shape.length
        c = self.shape.center
        outside = (c.x < -margin or c.x > config.SCREEN_WIDTH + margin or
                   c.y < -margin or c.y > config.SCREEN_HEIGHT + margin)
        return outside and self.velocity.dot(c - SCREEN_CENTER) > 0

    def draw_trail(self, surface: pygame.Surface) -> None:
        """A faint streak behind the bolt, so its direction reads at a glance.
        gfxdraw blends the alpha straight onto the surface (no extra full-screen layer needed)."""
        corners = self.shape.corners()
        tail = self.shape.center - self.shape.direction * (self.shape.length * 1.9)
        points = [(round(p.x), round(p.y)) for p in (corners[2], corners[3], tail)]
        pygame.gfxdraw.filled_polygon(surface, points, (*PALETTE.bolt, 55))

    def draw(self, surface: pygame.Surface, highlight: bool = False) -> None:
        s = self.shape
        draw_glow(surface, PALETTE.bolt, s.center, s.length * 0.75, 90)
        corners = s.corners()
        pygame.draw.polygon(surface, PALETTE.bolt, corners)
        core = RotatedRect(s.center, s.direction, s.length * 0.78, s.width * 0.36).corners()
        pygame.draw.polygon(surface, PALETTE.bolt_core, core)
        pygame.draw.polygon(surface, PALETTE.text if highlight else PALETTE.bolt_core, corners, 2)
        pygame.draw.line(surface, PALETTE.bolt_front, corners[0], corners[1], 4)
        if A11Y.outlines:
            # A bright outline a little outside the body, so bolts stand out from any background.
            outline = RotatedRect(s.center, s.direction, s.length + 6, s.width + 6).corners()
            pygame.draw.polygon(surface, PALETTE.text, outline, 2)
