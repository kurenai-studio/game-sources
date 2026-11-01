"""Colours, fonts and text helpers."""
from __future__ import annotations

from functools import lru_cache

import pygame

BG = (14, 18, 32)
PANEL = (24, 30, 50)
PANEL_EDGE = (48, 58, 90)
TEXT = (228, 232, 242)
MUTED = (140, 150, 175)
IDLE = (62, 110, 200)
ACTIVE = (245, 200, 70)
GOOD = (80, 205, 125)
BAD = (235, 80, 90)
SELECT = (120, 220, 255)
DISABLED = (70, 76, 96)
STAR = (255, 210, 80)

# Puzzle Stage -> its name on screen.
STAGE_LABEL = {"guided": "Guided", "challenge": "Challenge", "boss": "Boss"}

# Step kind -> highlight colour.
STEP_COLOURS = {
    "compare": ACTIVE, "visit": ACTIVE, "walk": ACTIVE, "go_left": ACTIVE, "go_right": ACTIVE,
    "found": GOOD, "swap": SELECT, "place": GOOD, "push": GOOD, "enqueue": GOOD, "new_node": GOOD,
    "remove": BAD, "pop": BAD, "dequeue": BAD, "unlink": BAD, "remove_leaf": BAD, "disrupt": BAD,
    "shift": MUTED,
}


@lru_cache(maxsize=None)
def font(size: int, mono: bool = False, bold: bool = False) -> pygame.font.Font:
    names = "consolas,couriernew,dejavusansmono,monospace" if mono else "segoeui,arial,dejavusans"
    return pygame.font.SysFont(names, size, bold=bold)


def wrap(text: str, f: pygame.font.Font, width: int) -> list[str]:
    lines: list[str] = []
    for para in text.split("\n"):
        line = ""
        for word in para.split():
            trial = f"{line} {word}".strip()
            if f.size(trial)[0] <= width or not line:
                line = trial
            else:
                lines.append(line)
                line = word
        lines.append(line)
    return lines


def draw_text(surf, text, pos, size=20, colour=TEXT, mono=False, bold=False, width=None, center=False) -> int:
    """Draw (wrapped) text; returns the y just below it."""
    f = font(size, mono, bold)
    x, y = pos
    for line in (wrap(text, f, width) if width else [text]):
        img = f.render(line, True, colour)
        surf.blit(img, img.get_rect(midtop=(x, y)) if center else (x, y))
        y += f.get_linesize()
    return y


def panel(surf, rect, colour=PANEL, edge=PANEL_EDGE, radius=10):
    pygame.draw.rect(surf, colour, rect, border_radius=radius)
    pygame.draw.rect(surf, edge, rect, 1, border_radius=radius)


def star(surf, center, size, colour):
    import math
    cx, cy = center
    pts = []
    for k in range(10):
        r = size / 2 if k % 2 == 0 else size / 4.6
        a = -math.pi / 2 + k * math.pi / 5
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    if size > 2:
        pygame.draw.polygon(surf, colour, pts)


def stars(surf, center, count, size=26, total=3):
    x0 = center[0] - (total - 1) * size * 0.6
    for i in range(total):
        cx, cy = x0 + i * size * 1.2, center[1]
        pts = []
        for k in range(10):
            import math
            r = size / 2 if k % 2 == 0 else size / 4.6
            a = -math.pi / 2 + k * math.pi / 5
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
        pygame.draw.polygon(surf, STAR if i < count else DISABLED, pts)
