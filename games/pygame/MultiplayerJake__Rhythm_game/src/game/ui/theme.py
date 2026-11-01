"""Neon Cyberpunk theme: palette, typography and drawing helpers.

All drawing happens on the 1280x720 design surface (BASE_W/BASE_H);
``Game`` scales that surface onto the desktop, so every coordinate in
the game is a *design-space* pixel.

Palette notes
------------
* Backgrounds are near-black navy / deep purple.
* Electric cyan is the primary accent, neon magenta + violet the
  secondary accents (they mark boost/special notes and selection).
* Text is white / pale lavender with layered neon glows.
"""

from __future__ import annotations

import pygame

BASE_W, BASE_H = 1280, 720

# ------------------------------------------------------------------ colors
BG = (8, 6, 20)              # near-black navy
BG_TOP = (14, 8, 34)
BG_HORIZON = (52, 16, 86)    # deep purple glow near the horizon
PANEL = (15, 11, 34)         # dark "transparent-looking" panel
PANEL_LIGHT = (27, 19, 60)
BORDER = (54, 42, 100)
BORDER_BRIGHT = (0, 190, 230)

CYAN = (0, 235, 255)         # primary accent
CYAN_SOFT = (150, 246, 255)
MAGENTA = (255, 46, 173)     # secondary accents
VIOLET = (140, 70, 255)
PURPLE = VIOLET              # legacy alias (used by scenes as glow colour)
PINK = (255, 104, 190)
YELLOW = (255, 220, 60)
ORANGE = (255, 140, 60)
WHITE = (244, 250, 255)
LAVENDER = (214, 205, 255)
TEXT = (216, 210, 255)
DIM = (126, 116, 186)
GREEN = (110, 255, 190)
RED = (255, 74, 120)

RATING_COLORS = {
    "perfect": CYAN,
    "great": YELLOW,
    "good": GREEN,
    "miss": PINK,
}

_FONT_CACHE: dict = {}


def lerp(a, b, t: float):
    t = max(0.0, min(1.0, t))
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


# ------------------------------------------------------------------- fonts
def font(size: int, bold: bool = True) -> pygame.font.Font:
    key = (size, bold)
    if key not in _FONT_CACHE:
        f = pygame.font.SysFont("segoeui semibold,segoeui,arial", size, bold=bold)
        if f is None:
            f = pygame.font.Font(None, size)
        _FONT_CACHE[key] = f
    return _FONT_CACHE[key]


# ----------------------------------------------------------------- shapes
def alpha_rect(surface, rect, color, alpha: int, radius: int = 0) -> None:
    """Filled rounded rect with real alpha (used for flashes/glows)."""
    if rect.w <= 0 or rect.h <= 0 or alpha <= 0:
        return
    surf = pygame.Surface((rect.w, rect.h), pygame.SRCALPHA)
    pygame.draw.rect(surf, (*color, min(alpha, 255)), surf.get_rect(),
                     border_radius=radius)
    surface.blit(surf, rect.topleft)


def vgrad(surface, rect, top, bottom, step: int = 4) -> None:
    """Vertical gradient fill (cached full-screen version in effects.py)."""
    h = max(rect.h, 1)
    for i in range(0, rect.h, step):
        t = i / h
        pygame.draw.rect(surface, lerp(top, bottom, t),
                         pygame.Rect(rect.x, rect.y + i, rect.w,
                                     min(step, rect.bottom - rect.y - i)))


def glow_rect(surface, rect, color, radius=8, blur=True, intensity=70) -> None:
    """Rounded rectangle with a layered neon halo."""
    if rect.w <= 2 or rect.h <= 2:
        return
    if blur:
        for grow, alpha in ((16, intensity // 3), (9, (intensity * 2) // 3),
                            (3, intensity)):
            r = rect.inflate(grow * 2, grow * 2)
            if r.w > 0 and r.h > 0:
                alpha_rect(surface, r, color, alpha, radius=radius + grow)
    pygame.draw.rect(surface, color, rect, border_radius=radius)


def panel(surface, rect, fill=PANEL, border=BORDER, radius=10, width=2,
          glow=None) -> None:
    """Dark translucent-looking panel with an optional edge glow."""
    alpha_rect(surface, rect, fill, 242, radius=radius)
    if glow is not None:
        alpha_rect(surface, rect.inflate(6, 6), glow, 55, radius=radius + 3)
    if border and width:
        pygame.draw.rect(surface, border, rect, width, border_radius=radius)
        # holographic edge light along the top
        edge = pygame.Rect(rect.x + radius, rect.y + 1, rect.w - radius * 2, 1)
        pygame.draw.rect(surface, lerp(border, WHITE, 0.35), edge)


# ------------------------------------------------------------------- text
def draw_text(surface, text, x, y, size=24, color=WHITE, align="left",
              glow=None, bold=True):
    """Render ``text`` with an optional layered glow. Returns the text rect."""
    f = font(size, bold)
    s = str(text)
    img = f.render(s, True, color)
    rect = img.get_rect()
    if align == "center":
        rect.centerx = x
    elif align == "right":
        rect.right = x
    else:
        rect.x = x
    rect.y = y
    if glow:
        g = f.render(s, True, glow)
        for dx, dy in ((-2, 0), (2, 0), (0, -2), (0, 2),
                       (-2, -2), (2, 2), (-2, 2), (2, -2)):
            surface.blit(g, (rect.x + dx, rect.y + dy))
        g2 = f.render(s, True, lerp(glow, WHITE, 0.3))
        for dx, dy in ((-4, 0), (4, 0), (0, -4), (0, 4)):
            surface.blit(g2, (rect.x + dx, rect.y + dy))
    surface.blit(img, rect)
    return rect


def title_text(surface, text, x, y, size=40, color=WHITE, glow=CYAN):
    return draw_text(surface, text, x, y, size=size, color=color,
                     align="center", glow=glow)


# ------------------------------------------------------------- scanlines
_SCANLINES: pygame.Surface | None = None


def scanlines(surface, alpha: int = 16) -> None:
    """Subtle CRT scanline overlay (cached, blitted once per frame)."""
    global _SCANLINES
    if _SCANLINES is None or _SCANLINES.get_size() != surface.get_size():
        w, h = surface.get_size()
        _SCANLINES = pygame.Surface((w, h), pygame.SRCALPHA)
        for y in range(0, h, 3):
            pygame.draw.line(_SCANLINES, (0, 0, 0, 70), (0, y), (w, y))
    if alpha != 100:
        _SCANLINES.set_alpha(alpha * 2)
    surface.blit(_SCANLINES, (0, 0))
