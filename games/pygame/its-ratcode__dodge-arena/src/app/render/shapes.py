"""Drawing primitives that pygame.draw doesn't provide directly.

Translucent shapes need their own SRCALPHA surface. Building one is slow, so
the sprites are cached by size and color and only their alpha changes per blit.
"""

import math
from functools import lru_cache

import pygame

from app.theme.palette import PALETTE
from app.theme.styles import PANEL_STYLES
from app.util.mathx import Color, clamp, lerp_color


# --- Cached sprites ----------------------------------------------------------------------
@lru_cache(maxsize=512)
def _circle_sprite(radius: int, color: Color, width: int) -> pygame.Surface:
    size = radius * 2 + 2
    sprite = pygame.Surface((size, size), pygame.SRCALPHA)
    pygame.draw.circle(sprite, color, (radius + 1, radius + 1), radius, width)
    return sprite


@lru_cache(maxsize=256)
def _glow_sprite(radius: int, color: Color) -> pygame.Surface:
    """Soft radial glow: many circles, more opaque toward the center."""
    sprite = pygame.Surface((radius * 2, radius * 2), pygame.SRCALPHA)
    steps = min(24, radius)
    for i in range(steps):
        t = i / steps
        pygame.draw.circle(sprite, (*color, int(150 * t ** 1.8)), (radius, radius), max(1, int(radius * (1 - t))))
    return sprite


@lru_cache(maxsize=128)
def _panel_sprite(size: tuple[int, int], radius: int, top: Color, bottom: Color) -> pygame.Surface:
    """Rounded rectangle with a vertical gradient."""
    w, h = size
    sprite = pygame.Surface(size, pygame.SRCALPHA)
    for y in range(h):
        pygame.draw.line(sprite, lerp_color(top, bottom, y / max(1, h - 1)), (0, y), (w, y))
    mask = pygame.Surface(size, pygame.SRCALPHA)
    pygame.draw.rect(mask, (255, 255, 255, 255), mask.get_rect(), border_radius=radius)
    sprite.blit(mask, (0, 0), special_flags=pygame.BLEND_RGBA_MIN)     # cut the rounded corners
    return sprite


@lru_cache(maxsize=32)
def _edge_light_sprite(width: int, color: Color) -> pygame.Surface:
    """A 2 px line that fades in from both ends: the lit top edge of a big panel."""
    sprite = pygame.Surface((max(1, width), 2), pygame.SRCALPHA)
    for x in range(width):
        strength = math.sin(math.pi * x / max(1, width - 1)) ** 2
        pygame.draw.line(sprite, (*color, int(220 * strength)), (x, 0), (x, 0))
        pygame.draw.line(sprite, (*color, int(70 * strength)), (x, 1), (x, 1))
    return sprite


@lru_cache(maxsize=64)
def _shadow_sprite(size: tuple[int, int], radius: int, spread: int) -> pygame.Surface:
    w, h = size
    sprite = pygame.Surface((w + spread * 2, h + spread * 2), pygame.SRCALPHA)
    for i in range(spread, 0, -2):
        alpha = int(90 * (1 - i / spread) ** 2) + 4
        rect = pygame.Rect(spread - i, spread - i, w + i * 2, h + i * 2)
        pygame.draw.rect(sprite, (0, 0, 0, alpha), rect, border_radius=radius + i)
    return sprite


# --- Circles and glows ---------------------------------------------------------------------
def draw_alpha_circle(surface: pygame.Surface, color: Color, center, radius: float,
                      alpha: float = 255, width: int = 0) -> None:
    """Draw a translucent circle (pygame.draw ignores alpha on the window surface)."""
    radius = int(radius)
    if radius <= 0 or alpha <= 0 or (width and width >= radius):
        return
    sprite = _circle_sprite(radius, tuple(color), width)
    sprite.set_alpha(int(clamp(alpha, 0, 255)))
    surface.blit(sprite, (int(center[0]) - radius - 1, int(center[1]) - radius - 1))


def draw_glow(surface: pygame.Surface, color: Color, center, radius: float, alpha: float = 255) -> None:
    sprite = _glow_sprite(max(2, int(radius)), tuple(color))
    sprite.set_alpha(int(clamp(alpha, 0, 255)))
    half = sprite.get_width() // 2
    surface.blit(sprite, (int(center[0]) - half, int(center[1]) - half))


# --- Interface shapes ---------------------------------------------------------------------
def draw_panel(surface: pygame.Surface, rect, style: str = "chip") -> None:
    """A themed panel: drop shadow, gradient body, top highlight line and border."""
    st = PANEL_STYLES[style]
    rect = pygame.Rect(rect)
    top, bottom = getattr(PALETTE, st.top), getattr(PALETTE, st.bottom)
    if st.shadow:
        spread = st.shadow
        surface.blit(_shadow_sprite(rect.size, st.radius, spread), (rect.x - spread, rect.y - spread + spread // 3))
    surface.blit(_panel_sprite(rect.size, st.radius, top, bottom), rect.topleft)
    pygame.draw.line(surface, lerp_color(top, PALETTE.text, 0.10),
                     (rect.x + st.radius, rect.y + 1), (rect.right - st.radius - 1, rect.y + 1))
    pygame.draw.rect(surface, getattr(PALETTE, st.border), rect, 1, border_radius=st.radius)
    if st.finish:
        # A fine line just inside the border, then the top edge lit in the accent color, brightest in the middle.
        pygame.draw.rect(surface, lerp_color(top, getattr(PALETTE, st.border), 0.55), rect.inflate(-8, -8), 1,
                         border_radius=max(2, st.radius - 4))
        edge = _edge_light_sprite(rect.width - st.radius * 2, PALETTE.accent)
        surface.blit(edge, (rect.x + st.radius, rect.y))


def draw_row(surface: pygame.Surface, rect, hover: float) -> None:
    """A flat list row (settings, guide sidebar). ``hover`` 0..1 tints it and grows an accent bar on the left."""
    rect = pygame.Rect(rect)
    radius = PANEL_STYLES["button"].radius
    pygame.draw.rect(surface, lerp_color(PALETTE.row, PALETTE.row_hover, hover), rect, border_radius=radius)
    border = lerp_color(PALETTE.border, lerp_color(PALETTE.accent, PALETTE.panel_bottom, 0.45), hover)
    pygame.draw.rect(surface, border, rect, 1, border_radius=radius)
    draw_accent_bar(surface, rect, hover, PALETTE.accent)


def draw_accent_bar(surface: pygame.Surface, rect: pygame.Rect, amount: float, color: Color) -> None:
    """A short vertical bar inside the left edge of ``rect`` that grows with ``amount`` (the focus marker)."""
    height = int((rect.height - 16) * clamp(amount, 0.0, 1.0))
    if height > 1:
        pygame.draw.rect(surface, color, (rect.x + 6, rect.centery - height // 2, 3, height), border_radius=2)


def draw_bar(surface: pygame.Surface, rect, fraction: float, color: Color) -> None:
    """A rounded progress bar filled from the left."""
    rect = pygame.Rect(rect)
    radius = rect.height // 2
    pygame.draw.rect(surface, PALETTE.track, rect, border_radius=radius)
    width = int(rect.width * clamp(fraction, 0.0, 1.0))
    if width > 0:
        pygame.draw.rect(surface, color, (rect.x, rect.y, max(width, rect.height), rect.height),
                         border_radius=radius)


def draw_progress_ring(surface: pygame.Surface, center, radius: int, fraction: float,
                       color: Color, width: int = 3) -> None:
    """A ring that drains clockwise, starting at 12 o'clock."""
    fraction = clamp(fraction, 0.0, 1.0)
    if fraction <= 0:
        return
    rect = pygame.Rect(0, 0, radius * 2, radius * 2)
    rect.center = (int(center[0]), int(center[1]))
    if fraction >= 0.999:
        pygame.draw.circle(surface, color, rect.center, radius, width)
    else:
        pygame.draw.arc(surface, color, rect, math.pi / 2, math.pi / 2 + math.tau * fraction, width)


def draw_cooldown_sweep(surface: pygame.Surface, rect, fraction: float, radius: int) -> None:
    """Clock-style cooldown: a dark wedge that shrinks clockwise from 12 o'clock.

    ``fraction`` is the part of the cooldown still left (1 = just cast).
    """
    rect = pygame.Rect(rect)
    overlay = pygame.Surface(rect.size, pygame.SRCALPHA)
    cx, cy = rect.width / 2, rect.height / 2
    reach = rect.width + rect.height                 # far enough to cover the corners
    start, end = -90 + 360 * (1 - fraction), 270     # degrees, 0 = 3 o'clock, clockwise on screen
    steps = max(2, int(48 * fraction) + 1)
    points = [(cx, cy)]
    for i in range(steps + 1):
        a = math.radians(start + (end - start) * i / steps)
        points.append((cx + math.cos(a) * reach, cy + math.sin(a) * reach))
    pygame.draw.polygon(overlay, (*PALETTE.key_shadow, 175), points)
    a = math.radians(start)                          # bright edge of the sweep
    pygame.draw.line(overlay, (*PALETTE.text, 110), (cx, cy), (cx + math.cos(a) * reach, cy + math.sin(a) * reach))
    mask = pygame.Surface(rect.size, pygame.SRCALPHA)
    pygame.draw.rect(mask, (255, 255, 255, 255), mask.get_rect(), border_radius=radius)
    overlay.blit(mask, (0, 0), special_flags=pygame.BLEND_RGBA_MIN)
    surface.blit(overlay, rect.topleft)
