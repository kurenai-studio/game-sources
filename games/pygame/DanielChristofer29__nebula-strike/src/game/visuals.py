"""Original vector-like visuals drawn entirely with Pygame."""

from __future__ import annotations

from dataclasses import dataclass
import random

import pygame

from game.config import (
    BLUE,
    CYAN,
    DARK,
    GREEN,
    HEIGHT,
    MAGENTA,
    ORANGE,
    VIOLET,
    WIDTH,
)


def build_background() -> pygame.Surface:
    surface = pygame.Surface((WIDTH, HEIGHT))
    top = DARK
    bottom = (14, 12, 48)
    for y in range(HEIGHT):
        ratio = y / max(1, HEIGHT - 1)
        color = tuple(
            int(top[channel] + (bottom[channel] - top[channel]) * ratio)
            for channel in range(3)
        )
        pygame.draw.line(surface, color, (0, y), (WIDTH, y))

    haze = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
    pygame.draw.circle(haze, (*VIOLET, 28), (770, 110), 210)
    pygame.draw.circle(haze, (*BLUE, 22), (190, 470), 240)
    surface.blit(haze, (0, 0))
    return surface


def ship_surface() -> pygame.Surface:
    surface = pygame.Surface((58, 40), pygame.SRCALPHA)
    pygame.draw.polygon(surface, (33, 55, 91), [(5, 4), (54, 20), (5, 36), (16, 20)])
    pygame.draw.polygon(surface, CYAN, [(11, 8), (47, 20), (11, 32), (21, 20)], 3)
    pygame.draw.circle(surface, (230, 251, 255), (31, 20), 5)
    pygame.draw.polygon(surface, ORANGE, [(7, 14), (0, 20), (7, 26)])
    return surface


def enemy_surface(kind: str) -> pygame.Surface:
    color = MAGENTA if kind == "striker" else ORANGE
    surface = pygame.Surface((48, 38), pygame.SRCALPHA)
    pygame.draw.polygon(surface, (39, 31, 64), [(45, 4), (7, 9), (1, 19), (7, 29), (45, 34), (34, 19)])
    pygame.draw.polygon(surface, color, [(40, 8), (12, 12), (7, 19), (12, 26), (40, 30), (31, 19)], 3)
    pygame.draw.circle(surface, (245, 248, 255), (19, 19), 4)
    return surface


def boss_surface() -> pygame.Surface:
    surface = pygame.Surface((128, 94), pygame.SRCALPHA)
    pygame.draw.polygon(
        surface,
        (45, 26, 73),
        [(123, 8), (47, 3), (8, 24), (2, 47), (8, 70), (47, 91), (123, 86), (99, 47)],
    )
    pygame.draw.polygon(
        surface,
        VIOLET,
        [(117, 15), (52, 10), (16, 28), (10, 47), (16, 66), (52, 84), (117, 79), (91, 47)],
        4,
    )
    pygame.draw.circle(surface, MAGENTA, (65, 47), 17)
    pygame.draw.circle(surface, (245, 250, 255), (65, 47), 7)
    return surface


def powerup_surface(kind: str) -> pygame.Surface:
    color = GREEN if kind == "repair" else CYAN
    surface = pygame.Surface((32, 32), pygame.SRCALPHA)
    pygame.draw.circle(surface, (11, 25, 50), (16, 16), 14)
    pygame.draw.circle(surface, color, (16, 16), 13, 3)
    if kind == "repair":
        pygame.draw.rect(surface, color, (13, 7, 6, 18), border_radius=2)
        pygame.draw.rect(surface, color, (7, 13, 18, 6), border_radius=2)
    else:
        pygame.draw.polygon(surface, color, [(17, 5), (9, 17), (15, 17), (13, 27), (24, 13), (18, 13)])
    return surface


def projectile_surface(friendly: bool) -> pygame.Surface:
    surface = pygame.Surface((18, 8), pygame.SRCALPHA)
    color = CYAN if friendly else MAGENTA
    pygame.draw.ellipse(surface, color, (0, 1, 18, 6))
    pygame.draw.ellipse(surface, (245, 252, 255), (10 if friendly else 2, 2, 6, 4))
    return surface


@dataclass(slots=True)
class Star:
    x: float
    y: float
    speed: float
    radius: int


class StarField:
    def __init__(self, count: int = 92, seed: int = 29):
        generator = random.Random(seed)
        self.stars = [
            Star(
                x=generator.uniform(0, WIDTH),
                y=generator.uniform(0, HEIGHT),
                speed=generator.uniform(18, 85),
                radius=generator.choice((1, 1, 1, 2)),
            )
            for _ in range(count)
        ]

    def update(self, dt: float) -> None:
        for star in self.stars:
            star.x -= star.speed * dt
            if star.x < -2:
                star.x = WIDTH + 2

    def draw(self, surface: pygame.Surface) -> None:
        for star in self.stars:
            brightness = min(255, int(125 + star.speed * 1.4))
            pygame.draw.circle(
                surface,
                (brightness, brightness, 255),
                (int(star.x), int(star.y)),
                star.radius,
            )
