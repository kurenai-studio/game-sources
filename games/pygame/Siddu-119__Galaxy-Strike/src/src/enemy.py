"""Enemy ship archetypes, movement patterns, and ranged attacks."""

import math
import random

import pygame

from src.bullet import aimed_bullet


ENEMY_TYPES = {
    "basic": {
        "health": 2, "speed": 135, "score": 100, "color": (255, 92, 130),
        "radius": 17,
    },
    "fast": {
        "health": 1, "speed": 235, "score": 150, "color": (255, 181, 74),
        "radius": 14,
    },
    "heavy": {
        "health": 8, "speed": 70, "score": 320, "color": (174, 106, 255),
        "radius": 25,
    },
    "shooting": {
        "health": 3, "speed": 105, "score": 225, "color": (255, 78, 89),
        "radius": 19,
    },
    "kamikaze": {
        "health": 2, "speed": 170, "score": 185, "color": (255, 224, 73),
        "radius": 16,
    },
    "elite": {
        "health": 5, "speed": 125, "score": 500, "color": (83, 255, 185),
        "radius": 21,
    },
}

ENEMY_ALIASES = {
    "scout": "basic",
    "swift": "fast",
    "gunner": "shooting",
}


class Enemy:
    """A self-contained enemy with a type-specific ship and flight pattern."""

    def __init__(self, x, y, kind="basic", level=1):
        self.kind = ENEMY_ALIASES.get(kind, kind)
        if self.kind not in ENEMY_TYPES:
            self.kind = "basic"
        spec = ENEMY_TYPES[self.kind]
        difficulty = max(1, level)
        self.pos = pygame.Vector2(x, y)
        self.health = spec["health"] + max(0, (difficulty - 1) // 3)
        self.max_health = self.health
        self.speed = spec["speed"] * (1 + (difficulty - 1) * 0.045)
        self.score_value = spec["score"] * difficulty
        self.color = spec["color"]
        self.radius = spec["radius"]
        self.age = 0.0
        self.fire_timer = random.uniform(0.9, 1.8)
        self.alive = True
        self.phase = random.random() * math.tau
        self.direction = random.choice((-1, 1))
        self.dive_direction = None

    def update(self, dt, player_pos, width, level=1, height=720):
        self.age += dt
        if self.kind == "fast":
            self._move_zigzag(dt, width, frequency=4.2, distance=165)
        elif self.kind == "heavy":
            self.pos.y += self.speed * dt
            self.pos.x += math.sin(self.age * 1.15 + self.phase) * 48 * dt
        elif self.kind in ("shooting", "elite"):
            self.pos.y += self.speed * dt
            self.pos.x += math.sin(self.age * 2.0 + self.phase) * 92 * dt
        elif self.kind == "kamikaze":
            self._move_kamikaze(dt, player_pos)
        else:
            self.pos.y += self.speed * dt
            self.pos.x += math.sin(self.age * 2.3 + self.phase) * 68 * dt

        self.pos.x = max(self.radius, min(width - self.radius, self.pos.x))
        shots = self._shoot(dt, player_pos, level)
        if self.pos.y - self.radius > height:
            self.alive = False
        return shots

    def _move_zigzag(self, dt, width, frequency, distance):
        self.pos.y += self.speed * dt
        self.pos.x += self.direction * self.speed * 0.82 * dt
        self.pos.x += math.sin(self.age * frequency + self.phase) * distance * dt
        if self.pos.x <= self.radius or self.pos.x >= width - self.radius:
            self.direction *= -1

    def _move_kamikaze(self, dt, player_pos):
        if self.age < 0.65:
            self.pos.y += self.speed * dt
            self.pos.x += math.sin(self.age * 3 + self.phase) * 54 * dt
            return
        if self.dive_direction is None or int(self.age * 4) != int((self.age - dt) * 4):
            target = pygame.Vector2(player_pos) - self.pos
            self.dive_direction = target.normalize() if target.length_squared() else pygame.Vector2(0, 1)
        self.pos += self.dive_direction * self.speed * 1.45 * dt

    def _shoot(self, dt, player_pos, level):
        if self.kind not in ("shooting", "elite") or self.pos.y < self.radius:
            return []
        self.fire_timer -= dt
        if self.fire_timer > 0:
            return []
        difficulty = max(1, level)
        shots = [aimed_bullet(
            self.pos.x, self.pos.y + self.radius, player_pos,
            225 + min(100, difficulty * 7), self.color, 1,
        )]
        if self.kind == "elite":
            shots.append(aimed_bullet(
                self.pos.x - self.radius * 0.65, self.pos.y + self.radius * 0.5,
                player_pos, 245 + min(100, difficulty * 7), self.color, 1,
            ))
            shots.append(aimed_bullet(
                self.pos.x + self.radius * 0.65, self.pos.y + self.radius * 0.5,
                player_pos, 245 + min(100, difficulty * 7), self.color, 1,
            ))
        self.fire_timer = random.uniform(1.45, 2.25) / min(1.65, 1 + difficulty * 0.035)
        return shots

    def hit(self, damage=1):
        if not self.alive:
            return False
        self.health -= damage
        if self.health <= 0:
            self.alive = False
            return True
        return False

    def draw(self, surface):
        x, y = int(self.pos.x), int(self.pos.y)
        r = self.radius
        if self.kind == "basic":
            points = [(x, y + r), (x - r, y), (x - r // 2, y - 4),
                      (x, y - r), (x + r // 2, y - 4), (x + r, y)]
            pygame.draw.polygon(surface, (68, 34, 66), points)
            pygame.draw.polygon(surface, self.color, [
                (x, y + r - 2), (x - r + 4, y - 2), (x, y - r + 2),
                (x + r - 4, y - 2),
            ])
        elif self.kind == "fast":
            pygame.draw.polygon(surface, (72, 47, 49), [
                (x, y + r), (x - r, y - 7), (x - r // 2, y - 1),
                (x, y - r), (x + r // 2, y - 1), (x + r, y - 7),
            ])
            pygame.draw.polygon(surface, self.color, [
                (x, y + r), (x - r + 4, y - 5), (x, y - r + 3),
                (x + r - 4, y - 5),
            ])
        elif self.kind == "heavy":
            pygame.draw.polygon(surface, (54, 41, 79), [
                (x - r, y - r // 2), (x - r + 5, y - r), (x + r - 5, y - r),
                (x + r, y - r // 2), (x + r, y + r // 2), (x + r - 6, y + r),
                (x - r + 6, y + r), (x - r, y + r // 2),
            ])
            pygame.draw.polygon(surface, self.color, [
                (x - r + 4, y - r // 2), (x - r + 8, y - r + 4),
                (x + r - 8, y - r + 4), (x + r - 4, y - r // 2),
                (x + r - 4, y + r // 2), (x + r - 9, y + r - 4),
                (x - r + 9, y + r - 4), (x - r + 4, y + r // 2),
            ])
            pygame.draw.circle(surface, (255, 225, 160), (x, y), 5)
        elif self.kind == "shooting":
            pygame.draw.polygon(surface, (67, 38, 63), [
                (x, y - r), (x + 8, y - 4), (x + r + 5, y + 8),
                (x + 5, y + 6), (x, y + r), (x - 5, y + 6),
                (x - r - 5, y + 8), (x - 8, y - 4),
            ])
            pygame.draw.polygon(surface, self.color, [
                (x, y - r + 3), (x + 6, y - 2), (x + r - 3, y + 4),
                (x + 3, y + 8), (x, y + r - 3), (x - 3, y + 8),
                (x - r + 3, y + 4), (x - 6, y - 2),
            ])
            pygame.draw.circle(surface, (255, 239, 185), (x, y + r // 2), 4)
        elif self.kind == "kamikaze":
            pygame.draw.polygon(surface, (88, 65, 37), [
                (x, y + r), (x - r, y - 3), (x - 4, y - 5),
                (x, y - r), (x + 4, y - 5), (x + r, y - 3),
            ])
            pygame.draw.polygon(surface, self.color, [
                (x, y + r), (x - r + 5, y - 1), (x, y - r + 2),
                (x + r - 5, y - 1),
            ])
            pygame.draw.line(surface, (255, 247, 185), (x - 4, y), (x + 4, y), 2)
        else:
            pygame.draw.polygon(surface, (40, 58, 76), [
                (x - r, y - 4), (x - r - 6, y + 8), (x - 7, y + 6),
                (x, y + r), (x + 7, y + 6), (x + r + 6, y + 8),
                (x + r, y - 4), (x, y - r),
            ])
            pygame.draw.polygon(surface, self.color, [
                (x, y + r - 2), (x - r + 4, y - 2), (x, y - r + 2),
                (x + r - 4, y - 2),
            ])
            pygame.draw.circle(surface, (231, 255, 240), (x, y), 4)

        engine = 3 + int(1.5 * (1 + math.sin(self.age * 18 + self.phase)))
        pygame.draw.polygon(surface, (255, 116, 73), [
            (x - 4, y + r // 2), (x, y + r // 2 + engine),
            (x + 4, y + r // 2),
        ])
        pygame.draw.line(surface, (255, 232, 241),
                         (x - max(3, r // 3), y - 2),
                         (x + max(3, r // 3), y - 2), 2)
        pygame.draw.circle(surface, (255, 248, 224), (x, y - 2), 2)
        if self.kind in ("shooting", "elite"):
            for side in (-1, 1):
                pygame.draw.circle(surface, (255, 201, 111),
                                   (x + side * max(5, r // 2), y + r // 3), 2)
        if self.max_health > 3:
            bar_width = r * 2
            bar_y = y - r - 7
            pygame.draw.rect(surface, (40, 35, 58), (x - r, bar_y, bar_width, 3))
            remaining = max(0, self.health) / self.max_health
            pygame.draw.rect(surface, self.color,
                             (x - r, bar_y, int(bar_width * remaining), 3))
