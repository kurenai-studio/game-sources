"""The duck sprite."""

import math
import random

import pygame

from duck_attack import settings


def load_duck_image() -> pygame.Surface:
    """Load the duck image scaled to ``settings.DUCK_WIDTH``. Needs an open display."""
    image = pygame.image.load(settings.DUCK_IMAGE).convert_alpha()
    w, h = image.get_size()
    size = (settings.DUCK_WIDTH, round(h * settings.DUCK_WIDTH / w))
    return pygame.transform.smoothscale(image, size)


class Duck(pygame.sprite.Sprite):
    """A duck that flies from just off the left edge across the screen to the right.

    Each duck has a random distance (``scale``): far-away ducks are smaller, fly slower
    and are worth more points. Once shot, it turns upside down and falls out of the sky.
    """

    def __init__(
        self, image: pygame.Surface, y: float | None = None, scale: float | None = None
    ) -> None:
        super().__init__()
        if scale is None:
            scale = random.uniform(settings.DUCK_MIN_SCALE, settings.DUCK_MAX_SCALE)
        self.scale = scale
        if scale != 1.0:
            w, h = image.get_size()
            image = pygame.transform.smoothscale(image, (round(w * scale), round(h * scale)))
        self.image = image
        self.rect = image.get_rect()
        # Distant things appear to move slower; keep some speed so far ducks stay a challenge.
        self.speed = settings.DUCK_SPEED * (0.6 + 0.4 * scale)
        # Pixel mask so clicks on the transparent area around the duck don't count as hits.
        self.mask = pygame.mask.from_surface(image)
        self.base_y = random.uniform(settings.DUCK_MIN_Y, settings.DUCK_MAX_Y) if y is None else y
        # Track position as floats; rect coordinates are ints and would lose sub-pixel motion.
        self.x = float(-self.rect.width)
        self.y = self.base_y
        self.time = 0.0
        self.shot = False
        self.fall_speed = 0.0
        self.rect.topleft = (round(self.x), round(self.y))

    @property
    def points(self) -> int:
        """Points for hitting this duck: the farther away (smaller), the more."""
        step = settings.POINTS_ROUNDING
        return max(
            settings.POINTS_PER_HIT, round(settings.POINTS_PER_HIT / self.scale / step) * step
        )

    def is_hit_by(self, pos: tuple[int, int]) -> bool:
        """Whether a shot at screen position ``pos`` hits this (still flying) duck."""
        if self.shot or not self.rect.collidepoint(pos):
            return False
        return bool(self.mask.get_at((pos[0] - self.rect.x, pos[1] - self.rect.y)))

    def shoot(self) -> None:
        self.shot = True
        self.image = pygame.transform.flip(self.image, False, True)

    def update(self, dt: float) -> None:
        if self.shot:
            self.fall_speed += settings.DUCK_FALL_GRAVITY * dt
            self.y += self.fall_speed * dt
            self.x += self.speed * 0.3 * dt  # a little momentum while falling
        else:
            self.time += dt
            self.x += self.speed * dt
            # Gentle up-and-down while flying.
            self.y = self.base_y + math.sin(self.time * 3) * 12 * self.scale
        self.rect.topleft = (round(self.x), round(self.y))
        if self.rect.left > settings.SCREEN_WIDTH or self.rect.top > settings.SCREEN_HEIGHT:
            self.kill()
