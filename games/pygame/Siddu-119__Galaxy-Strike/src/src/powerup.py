"""Weighted collectible upgrades with falling, bobbing, and sparkle effects."""

import math
import random

import pygame

from src.particle import Particle

POWERUPS = {
    "health": ("+", (86, 255, 143)),
    "shield": ("S", (88, 184, 255)),
    "life": ("1UP", (255, 225, 96)),
    "rapid": ("R", (255, 139, 77)),
    "double": ("II", (118, 182, 255)),
    "triple": ("III", (158, 133, 255)),
    "laser": ("L", (98, 248, 239)),
    "beam": ("L", (98, 248, 239)),
    "damage": ("D", (255, 99, 138)),
    "weapon": ("W", (158, 133, 255)),
    "missile": ("M", (255, 156, 79)),
    "multiplier": ("x2", (255, 219, 86)),
    "invincible": ("I", (255, 255, 255)),
}

POWERUP_DURATIONS = {
    "shield": 10.0,
    "rapid": 8.0,
    "laser": 9.0,
    "multiplier": 10.0,
    "damage": 8.0,
    "missile": 10.0,
    "invincible": 5.0,
}

# Weights total 100. Triple shot becomes available after double shot.
POWERUP_DROP_WEIGHTS = (
    ("health", 18),
    ("life", 3),
    ("shield", 14),
    ("rapid", 12),
    ("double", 16),
    ("laser", 8),
    ("multiplier", 10),
    ("missile", 4),
    ("damage", 5),
    ("invincible", 2),
)


class PowerUp:
    def __init__(self, x, y, kind=None):
        self.pos = pygame.Vector2(x, y)
        self.kind = kind or self.random_kind()
        if self.kind not in POWERUPS:
            raise ValueError(f"Unknown power-up kind: {self.kind}")
        self.label, self.color = POWERUPS[self.kind]
        self.phase = random.random() * math.tau
        self.alive = True
        self.age = 0.0
        self.sparkle_timer = 0.0
        self.font = pygame.font.Font(None, 18)
        self.large_font = pygame.font.Font(None, 20)

    @staticmethod
    def random_kind(weapon_level=1):
        eligible = [
            (kind, weight)
            for kind, weight in POWERUP_DROP_WEIGHTS
            if kind != "double" or weapon_level < 2
        ]
        if weapon_level >= 2:
            eligible.append(("triple", 8))
        choices, weights = zip(*eligible)
        return random.choices(choices, weights=weights, k=1)[0]

    def update(self, dt, width=1280, height=720, particles=None):
        self.age += dt
        self.pos.y += 125 * dt
        self.phase += dt * 3.2
        self.pos.x += math.sin(self.phase * 0.55) * 13 * dt
        self.sparkle_timer += dt
        if particles is not None:
            while self.sparkle_timer >= 0.13:
                self.sparkle_timer -= 0.13
                angle = random.random() * math.tau
                radius = random.uniform(11, 19)
                x = self.pos.x + math.cos(angle) * radius
                y = self.pos.y + math.sin(angle) * radius
                particles.append(Particle(x, y, self.color, life=0.32, radius=2))
        if self.pos.y - 20 > height or self.pos.x < -24 or self.pos.x > width + 24:
            self.alive = False

    def draw(self, surface):
        bob = math.sin(self.phase) * 3
        pulse = 0.5 + 0.5 * math.sin(self.phase * 2.2)
        x, y = int(self.pos.x), int(self.pos.y + bob)
        pygame.draw.circle(surface, self.color, (x, y), 22 + int(pulse * 3), 1)
        pygame.draw.circle(surface, self.color, (x, y), 17, 2)
        pygame.draw.circle(surface, (20, 31, 57), (x, y), 13)
        pygame.draw.line(surface, self.color, (x - 10, y), (x - 6, y), 1)
        pygame.draw.line(surface, self.color, (x + 6, y), (x + 10, y), 1)
        font = self.large_font if len(self.label) > 2 else self.font
        label = font.render(self.label, True, self.color)
        surface.blit(label, label.get_rect(center=(x, y)))
