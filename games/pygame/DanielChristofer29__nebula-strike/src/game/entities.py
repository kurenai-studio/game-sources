"""Object-oriented game entities."""

from __future__ import annotations

from abc import ABC, abstractmethod
import math
import random
from typing import Mapping

import pygame

from game.config import HEIGHT, PLAYER_INVULNERABLE_MS, WIDTH
from game.visuals import (
    boss_surface,
    enemy_surface,
    powerup_surface,
    projectile_surface,
    ship_surface,
)


class Entity(ABC):
    """Base class shared by every visible game object."""

    def __init__(self, image: pygame.Surface, position: tuple[float, float]):
        self.image = image
        self.position = pygame.Vector2(position)
        self.rect = self.image.get_rect(topleft=(round(self.position.x), round(self.position.y)))

    def sync_rect(self) -> None:
        self.rect.topleft = (round(self.position.x), round(self.position.y))

    @abstractmethod
    def update(self, *args: object, **kwargs: object) -> None:
        """Advance the entity state."""

    def draw(self, surface: pygame.Surface) -> None:
        surface.blit(self.image, self.rect)


class Player(Entity):
    def __init__(self, lives: int = 3):
        super().__init__(ship_surface(), (120, HEIGHT / 2 - 20))
        self.speed = 310.0
        self.lives = max(0, lives)
        self.invulnerable_until = 0
        self.powerup_type: str | None = None
        self.powerup_until = 0
        self.last_shot_at = -1_000

    def update(
        self,
        keys: Mapping[int, bool] | pygame.key.ScancodeWrapper,
        dt: float,
        now_ms: int,
    ) -> None:
        direction = pygame.Vector2(
            float(bool(keys[pygame.K_RIGHT]) or bool(keys[pygame.K_d]))
            - float(bool(keys[pygame.K_LEFT]) or bool(keys[pygame.K_a])),
            float(bool(keys[pygame.K_DOWN]) or bool(keys[pygame.K_s]))
            - float(bool(keys[pygame.K_UP]) or bool(keys[pygame.K_w])),
        )
        if direction.length_squared() > 0:
            direction = direction.normalize()

        multiplier = 1.6 if self.powerup_type == "speed" and now_ms < self.powerup_until else 1.0
        self.position += direction * self.speed * multiplier * dt
        self.position.x = max(0, min(self.position.x, WIDTH - self.image.get_width()))
        self.position.y = max(0, min(self.position.y, HEIGHT - self.image.get_height()))

        if self.powerup_type == "speed" and now_ms >= self.powerup_until:
            self.powerup_type = None
        if self.powerup_type == "shield" and now_ms >= self.powerup_until:
            self.powerup_type = None
        self.sync_rect()

    def can_shoot(self, now_ms: int) -> bool:
        cooldown = 115 if self.powerup_type == "speed" else 220
        if now_ms - self.last_shot_at < cooldown:
            return False
        self.last_shot_at = now_ms
        return True

    def take_damage(self, now_ms: int) -> str:
        if now_ms < self.invulnerable_until:
            return "ignored"
        if self.powerup_type == "shield":
            self.powerup_type = None
            self.powerup_until = 0
            self.invulnerable_until = now_ms + 350
            return "shielded"

        self.lives = max(0, self.lives - 1)
        self.invulnerable_until = now_ms + PLAYER_INVULNERABLE_MS
        return "damaged"

    def activate_powerup(self, kind: str, now_ms: int, duration_ms: int = 7_000) -> None:
        self.powerup_type = kind
        self.powerup_until = now_ms + duration_ms

    def draw(self, surface: pygame.Surface) -> None:
        now_ms = pygame.time.get_ticks()
        if now_ms < self.invulnerable_until and (now_ms // 90) % 2:
            return
        if self.powerup_type:
            color = (82, 224, 151, 92) if self.powerup_type == "shield" else (62, 225, 255, 78)
            glow = pygame.Surface((76, 58), pygame.SRCALPHA)
            pygame.draw.ellipse(glow, color, glow.get_rect(), 3)
            surface.blit(glow, (self.rect.x - 9, self.rect.y - 9))
        super().draw(surface)


class Enemy(Entity):
    def __init__(self, kind: str = "scout", rng: random.Random | None = None):
        self.kind = kind if kind in {"scout", "striker"} else "scout"
        generator = rng or random
        super().__init__(
            enemy_surface(self.kind),
            (generator.uniform(WIDTH + 30, WIDTH + 260), generator.uniform(50, HEIGHT - 90)),
        )
        self.speed = generator.uniform(125, 170) * (1.22 if self.kind == "striker" else 1.0)
        self.hp = 2 if self.kind == "striker" else 1
        self.points = 25 if self.kind == "striker" else 10
        self.phase = generator.uniform(0, math.tau)
        self.shot_interval_ms = generator.randint(1_500, 2_900)
        self.last_shot_at = generator.randint(-1_000, 0)

    def update(self, dt: float, elapsed_seconds: float = 0.0) -> None:
        difficulty_multiplier = min(1.75, 1.0 + elapsed_seconds / 110)
        self.position.x -= self.speed * difficulty_multiplier * dt
        self.phase += dt * (2.6 if self.kind == "striker" else 1.8)
        self.position.y += math.sin(self.phase) * (55 if self.kind == "striker" else 28) * dt
        self.position.y = max(30, min(self.position.y, HEIGHT - self.image.get_height() - 20))
        self.sync_rect()

    def ready_to_shoot(self, now_ms: int) -> bool:
        if now_ms - self.last_shot_at < self.shot_interval_ms:
            return False
        self.last_shot_at = now_ms
        return True

    def take_damage(self, amount: int = 1) -> bool:
        self.hp -= max(0, amount)
        return self.hp <= 0

    @property
    def off_screen(self) -> bool:
        return self.rect.right < 0


class Boss(Entity):
    MAX_HP = 36

    def __init__(self):
        image = boss_surface()
        super().__init__(image, (WIDTH - image.get_width() - 34, HEIGHT / 2 - image.get_height() / 2))
        self.hp = self.MAX_HP
        self.vertical_speed = 126.0
        self.last_shot_at = 0

    def update(self, dt: float) -> None:
        self.position.y += self.vertical_speed * dt
        if self.position.y <= 30:
            self.position.y = 30
            self.vertical_speed = abs(self.vertical_speed)
        maximum_y = HEIGHT - self.image.get_height() - 24
        if self.position.y >= maximum_y:
            self.position.y = maximum_y
            self.vertical_speed = -abs(self.vertical_speed)
        self.sync_rect()

    def ready_to_shoot(self, now_ms: int) -> bool:
        if now_ms - self.last_shot_at < 820:
            return False
        self.last_shot_at = now_ms
        return True

    def take_damage(self, amount: int = 1) -> bool:
        self.hp = max(0, self.hp - max(0, amount))
        return self.hp == 0


class Projectile(Entity):
    def __init__(
        self,
        position: tuple[float, float],
        friendly: bool,
        velocity: tuple[float, float] | None = None,
        damage: int = 1,
        boss_shot: bool = False,
    ):
        super().__init__(projectile_surface(friendly), position)
        if velocity is None:
            velocity = (640.0, 0.0) if friendly else (-330.0, 0.0)
        self.velocity = pygame.Vector2(velocity)
        self.friendly = friendly
        self.damage = max(1, damage)
        self.boss_shot = boss_shot

    def update(self, dt: float) -> None:
        self.position += self.velocity * dt
        self.sync_rect()

    @property
    def off_screen(self) -> bool:
        return (
            self.rect.right < -10
            or self.rect.left > WIDTH + 10
            or self.rect.bottom < -10
            or self.rect.top > HEIGHT + 10
        )


class PowerUp(Entity):
    def __init__(self, kind: str, y: float):
        self.kind = kind if kind in {"speed", "shield"} else "speed"
        super().__init__(powerup_surface("repair" if self.kind == "shield" else "speed"), (WIDTH + 20, y))
        self.speed = 115.0

    def update(self, dt: float) -> None:
        self.position.x -= self.speed * dt
        self.sync_rect()

    @property
    def off_screen(self) -> bool:
        return self.rect.right < 0
