"""Coins: pickups that lie in the arena for a few seconds."""

import math

import pygame
from pygame.math import Vector2

from app import config
from app.render.icons import draw_icon
from app.render.shapes import draw_glow
from app.theme.accessibility import blink_hidden, wobble
from app.theme.palette import PALETTE


class Coin:
    """Worth ``value`` coins. Disappears after ``COIN_LIFETIME`` seconds, blinking first."""

    def __init__(self, pos, value: int = config.COIN_VALUE) -> None:
        self.pos = Vector2(pos)
        self.value = value
        self.big = value > config.COIN_VALUE
        self.radius = config.COIN_RADIUS * (config.BIG_COIN_RADIUS_SCALE if self.big else 1)
        self.remaining = config.COIN_LIFETIME
        self.age = 0.0

    @property
    def alive(self) -> bool:
        return self.remaining > 0

    def update(self, dt: float, player_pos: Vector2, magnet_radius: float) -> None:
        self.remaining -= dt
        self.age += dt
        # Inside the magnet radius the coin flies toward the player.
        to_player = player_pos - self.pos
        distance = to_player.length()
        if 0 < distance <= magnet_radius:
            self.pos += to_player / distance * min(distance, config.COIN_MAGNET_SPEED * dt)

    def touches(self, pos: Vector2, radius: float) -> bool:
        return self.pos.distance_squared_to(pos) <= (self.radius + radius) ** 2

    def draw(self, surface: pygame.Surface) -> None:
        if self.remaining < config.COIN_BLINK_TIME and blink_hidden(self.remaining, 10):
            return                                          # blinking: skip every other tenth
        bob = Vector2(0, wobble(math.sin(self.age * 4) * 2))      # a gentle float up and down
        draw_glow(surface, PALETTE.coin, self.pos, self.radius * 3, 120)
        draw_icon(surface, "coin", self.pos + bob, self.radius * 2.4, PALETTE.coin)
        if self.big:
            pygame.draw.circle(surface, PALETTE.coin_shine, self.pos + bob, round(self.radius) + 3, 1)
