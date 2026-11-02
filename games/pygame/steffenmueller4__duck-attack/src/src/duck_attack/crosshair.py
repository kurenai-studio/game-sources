"""The crosshair mouse cursor."""

import pygame

from duck_attack import settings


def make_crosshair_cursor() -> pygame.cursors.Cursor:
    """Build a color cursor from the crosshair image, with its hotspot on the red dot."""
    image = pygame.image.load(settings.CROSSHAIR_IMAGE).convert_alpha()
    size = settings.CROSSHAIR_SIZE
    image = pygame.transform.smoothscale(image, (size, size))
    fx, fy = settings.CROSSHAIR_HOTSPOT
    hotspot = (round(fx * (size - 1)), round(fy * (size - 1)))
    return pygame.cursors.Cursor(hotspot, image)
