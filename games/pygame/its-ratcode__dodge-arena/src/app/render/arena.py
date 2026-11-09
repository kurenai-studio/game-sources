"""Full-screen layers built once: the arena background, and the red vignette of the death beat."""

import math

import pygame

from app import config
from app.theme.palette import PALETTE
from app.util.mathx import lerp_color

GRADIENT_STEPS = 48        # rings used to approximate the radial gradient
GRID_ALPHA_MINOR = 8
GRID_ALPHA_MAJOR = 16
BORDER_RADIUS = 14


def build_arena_background(width: int, height: int) -> pygame.Surface:
    """Pre-render the static arena once; the game blits it every frame."""
    surface = pygame.Surface((width, height)).convert()
    surface.fill(PALETTE.arena_edge)

    # Radial gradient: concentric filled circles from the edge color to the center color.
    center = (width // 2, height // 2)
    max_radius = int(math.hypot(width, height) / 2)
    for i in range(GRADIENT_STEPS):
        t = i / (GRADIENT_STEPS - 1)
        color = lerp_color(PALETTE.arena_edge, PALETTE.arena_center, t ** 0.7)
        pygame.draw.circle(surface, color, center, int(max_radius * (1 - t)) + 1)

    # Grid on a transparent layer so it can use alpha.
    grid = pygame.Surface((width, height), pygame.SRCALPHA)
    spacing = config.GRID_SPACING
    for x in range(0, width, spacing):
        alpha = GRID_ALPHA_MAJOR if (x // spacing) % config.GRID_MAJOR_EVERY == 0 else GRID_ALPHA_MINOR
        pygame.draw.line(grid, (*PALETTE.grid_line, alpha), (x, 0), (x, height))
    for y in range(0, height, spacing):
        alpha = GRID_ALPHA_MAJOR if (y // spacing) % config.GRID_MAJOR_EVERY == 0 else GRID_ALPHA_MINOR
        pygame.draw.line(grid, (*PALETTE.grid_line, alpha), (0, y), (width, y))
    surface.blit(grid, (0, 0))

    inset = config.ARENA_BORDER_INSET
    pygame.draw.rect(surface, PALETTE.border, surface.get_rect().inflate(-inset * 2, -inset * 2), 1,
                     border_radius=BORDER_RADIUS)
    return surface


def build_vignette(width: int, height: int, color, strength: int) -> pygame.Surface:
    """A full-screen tint that is strongest at the edges and clear in the middle
    (the red edges of the death beat). Blit it with ``set_alpha`` to pulse it."""
    surface = pygame.Surface((width, height), pygame.SRCALPHA)
    center = (width // 2, height // 2)
    max_radius = int(math.hypot(width, height) / 2) + 40
    steps = 40
    for i in range(steps):
        t = i / (steps - 1)
        pygame.draw.circle(surface, (*color, int(strength * (1 - t) ** 2)), center, int(max_radius * (1 - 0.6 * t)))
    pygame.draw.circle(surface, (*color, 0), center, int(max_radius * 0.4))
    return surface
