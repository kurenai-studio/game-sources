"""Procedural vector icons, drawn with pygame.draw (no image files needed).

Each icon is designed in a box from -1 to 1 on both axes and scaled to
``size`` px, so it stays sharp at any size and takes any color.
"""

import math

import pygame

from app.theme.palette import PALETTE
from app.util.mathx import Color


def draw_icon(surface: pygame.Surface, name: str, center, size: float, color: Color) -> None:
    cx, cy = center
    s = size / 2
    w = max(2, round(size / 11))                   # line width grows with the icon

    def p(x: float, y: float) -> tuple[float, float]:
        """Icon-box coordinates -> screen coordinates."""
        return cx + x * s, cy + y * s

    if name == "shield":
        pygame.draw.polygon(surface, color, [p(-0.72, -0.78), p(0.72, -0.78), p(0.72, 0.05),
                                             p(0, 0.88), p(-0.72, 0.05)], w)
        pygame.draw.line(surface, color, p(0, -0.5), p(0, 0.5), w)
    elif name == "wall":
        # Three rows of bricks with staggered joints.
        for row, y in enumerate((-0.62, -0.02, 0.58)):
            brick = pygame.Rect(0, 0, 1.7 * s, max(3, 0.42 * s))
            brick.center = (round(cx), round(cy + y * s))
            pygame.draw.rect(surface, color, brick, border_radius=2)
            jx = -0.25 if row % 2 else 0.25
            pygame.draw.line(surface, PALETTE.panel_bottom, p(jx, y - 0.2), p(jx, y + 0.2), max(1, w - 1))
    elif name == "dash":
        # Double chevron.
        for off in (-0.38, 0.32):
            pygame.draw.lines(surface, color, False, [p(off - 0.3, -0.62), p(off + 0.3, 0), p(off - 0.3, 0.62)], w + 1)
    elif name == "sprint":
        # Speed lines behind an arrowhead.
        for y, x0 in ((-0.45, -0.9), (0, -0.7), (0.45, -0.9)):
            pygame.draw.line(surface, color, p(x0, y), p(0.05, y), w)
        pygame.draw.polygon(surface, color, [p(0.15, -0.6), p(0.92, 0), p(0.15, 0.6)])
    elif name == "blink":
        # A dotted start, then a solid jump arrow.
        for x0, x1 in ((-0.95, -0.72), (-0.58, -0.32)):
            pygame.draw.line(surface, color, p(x0, 0), p(x1, 0), w)
        pygame.draw.line(surface, color, p(-0.15, 0), p(0.85, 0), w)
        pygame.draw.lines(surface, color, False, [p(0.4, -0.42), p(0.88, 0), p(0.4, 0.42)], w)
    elif name == "coin":
        # Always gold (``color`` is ignored): a dark rim, the face and a small shine.
        r = max(3, round(s * 0.82))
        pygame.draw.circle(surface, PALETTE.coin_dark, (cx, cy), r)
        pygame.draw.circle(surface, PALETTE.coin, (cx, cy), max(1, r - 2))
        pygame.draw.circle(surface, PALETTE.coin_shine, p(-0.3, -0.3), max(1, round(r * 0.3)))
    elif name == "coin_rush":
        # Two overlapping coins.
        draw_icon(surface, "coin", p(0.28, -0.22), size * 0.62, color)
        draw_icon(surface, "coin", p(-0.26, 0.24), size * 0.62, color)
    elif name == "stasis":
        # An hourglass with sand in the bottom half.
        pygame.draw.polygon(surface, color, [p(-0.25, 0.45), p(0.25, 0.45), p(0.55, 0.8), p(-0.55, 0.8)])
        pygame.draw.polygon(surface, color, [p(-0.6, -0.85), p(0.6, -0.85), p(0, 0), p(0.6, 0.85),
                                             p(-0.6, 0.85), p(0, 0)], w)
        pygame.draw.line(surface, color, p(-0.75, -0.85), p(0.75, -0.85), w + 1)
        pygame.draw.line(surface, color, p(-0.75, 0.85), p(0.75, 0.85), w + 1)
    elif name == "time_warp":
        # A clock face with two hands.
        pygame.draw.circle(surface, color, (cx, cy), max(3, round(s * 0.82)), w)
        pygame.draw.line(surface, color, (cx, cy), p(0, -0.55), w)
        pygame.draw.line(surface, color, (cx, cy), p(0.4, 0.15), w)
        pygame.draw.circle(surface, color, (cx, cy), max(1, w))
    elif name == "warp":
        # A portal ring on the left with an arrow shooting out of it.
        portal = pygame.Rect(0, 0, 0.55 * s, 1.6 * s)
        portal.center = (round(cx - 0.55 * s), round(cy))
        pygame.draw.ellipse(surface, color, portal, w)
        pygame.draw.line(surface, color, p(-0.45, 0), p(0.85, 0), w)
        pygame.draw.lines(surface, color, False, [p(0.4, -0.45), p(0.9, 0), p(0.4, 0.45)], w)
    elif name == "nova":
        # A burst: a core with eight rays, long and short alternating.
        for k in range(8):
            d = pygame.math.Vector2(1, 0).rotate(k * 45)
            reach = 0.95 if k % 2 == 0 else 0.68
            pygame.draw.line(surface, color, p(d.x * 0.42, d.y * 0.42), p(d.x * reach, d.y * reach), w)
        pygame.draw.circle(surface, color, (cx, cy), max(2, round(s * 0.26)))
    elif name == "second_wind":
        # A heart with a small plus cut out of it.
        r = 0.36
        pygame.draw.circle(surface, color, p(-0.34, -0.3), max(2, round(s * r)))
        pygame.draw.circle(surface, color, p(0.34, -0.3), max(2, round(s * r)))
        pygame.draw.polygon(surface, color, [p(-0.69, -0.18), p(0.69, -0.18), p(0, 0.82)])
        pygame.draw.line(surface, PALETTE.panel_bottom, p(-0.24, -0.08), p(0.24, -0.08), max(1, w - 1))
        pygame.draw.line(surface, PALETTE.panel_bottom, p(0, -0.32), p(0, 0.16), max(1, w - 1))
    elif name == "boots":
        # A boot with two speed lines behind it.
        pygame.draw.polygon(surface, color, [p(-0.3, -0.85), p(0.2, -0.85), p(0.2, 0.15), p(0.85, 0.35),
                                             p(0.85, 0.75), p(-0.3, 0.75)])
        for y in (-0.35, 0.15):
            pygame.draw.line(surface, color, p(-0.95, y), p(-0.5, y), w)
    elif name == "haste":
        # A circular arrow: an open ring with an arrowhead at its end.
        ring = pygame.Rect(0, 0, 1.5 * s, 1.5 * s)
        ring.center = (round(cx), round(cy))
        pygame.draw.arc(surface, color, ring, math.radians(-30), math.radians(240), w + 1)
        pygame.draw.polygon(surface, color, [p(0.42, -0.05), p(0.95, -0.05), p(0.68, 0.42)])
    elif name == "magnet":
        # A horseshoe magnet: two legs joined by a curved bottom, with light tips.
        thick = max(3, round(s * 0.34))
        bend = pygame.Rect(0, 0, 1.5 * s, 1.5 * s)
        bend.center = (round(cx), round(cy + 0.05 * s))
        pygame.draw.arc(surface, color, bend, math.pi, math.tau, thick)        # the bottom half circle
        for x in (-0.75, 0.75 - thick / s):
            leg = pygame.Rect(round(cx + x * s), round(cy - 0.85 * s), thick, round(0.92 * s))
            pygame.draw.rect(surface, color, leg)
            pygame.draw.rect(surface, PALETTE.text, (leg.x, leg.y, thick, round(0.3 * s)))   # the tip
    elif name == "bolt":
        # A tilted bolt with a bright leading edge.
        d = pygame.math.Vector2(1, -1).normalize()
        n = pygame.math.Vector2(-d.y, d.x)
        body = [p(*(d * along + n * side)) for along, side in ((0.85, 0.3), (0.85, -0.3), (-0.85, -0.3), (-0.85, 0.3))]
        pygame.draw.polygon(surface, color, body)
        pygame.draw.line(surface, PALETTE.text, body[0], body[1], w)
    elif name == "laser":
        # A beam across the box, with dashed warning lanes above and below it.
        pygame.draw.line(surface, color, p(-0.95, 0), p(0.95, 0), w + 2)
        for y in (-0.55, 0.55):
            for x0 in (-0.9, -0.3, 0.3):
                pygame.draw.line(surface, color, p(x0, y), p(x0 + 0.35, y), max(1, w - 1))
    elif name == "play":
        pygame.draw.polygon(surface, color, [p(-0.55, -0.75), p(0.8, 0), p(-0.55, 0.75)])
    elif name == "restart":
        # A circular arrow, the other way round from "haste".
        ring = pygame.Rect(0, 0, 1.5 * s, 1.5 * s)
        ring.center = (round(cx), round(cy))
        pygame.draw.arc(surface, color, ring, math.radians(-60), math.radians(210), w + 1)
        pygame.draw.polygon(surface, color, [p(-0.95, -0.15), p(-0.42, -0.15), p(-0.68, 0.32)])
    elif name == "book":
        for side in (-1, 1):
            pygame.draw.polygon(surface, color, [p(0, -0.6), p(0.9 * side, -0.75), p(0.9 * side, 0.7), p(0, 0.85)], w)
    elif name == "gear":
        for k in range(8):
            angle = k * math.pi / 4
            pygame.draw.line(surface, color, p(math.cos(angle) * 0.55, math.sin(angle) * 0.55),
                             p(math.cos(angle) * 0.92, math.sin(angle) * 0.92), w + 2)
        pygame.draw.circle(surface, color, (cx, cy), max(3, round(s * 0.6)), w)
        pygame.draw.circle(surface, color, (cx, cy), max(1, round(s * 0.18)))
    elif name == "exit":
        # A door with an arrow walking out of it.
        door = pygame.Rect(0, 0, 0.9 * s, 1.6 * s)
        door.center = (round(cx - 0.35 * s), round(cy))
        pygame.draw.rect(surface, color, door, w, border_radius=2)
        pygame.draw.line(surface, color, p(-0.05, 0), p(0.9, 0), w)
        pygame.draw.lines(surface, color, False, [p(0.55, -0.35), p(0.9, 0), p(0.55, 0.35)], w)
    elif name == "empty":
        # A dashed diamond: an empty power-up slot.
        corners = [p(0, -0.7), p(0.7, 0), p(0, 0.7), p(-0.7, 0)]
        for a, b in zip(corners, corners[1:] + corners[:1]):
            pygame.draw.line(surface, color, a, ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), max(1, w - 1))
    elif name == "warning":
        # A warning triangle with an exclamation mark.
        pygame.draw.lines(surface, color, True, [p(0, -0.85), p(0.9, 0.75), p(-0.9, 0.75)], w)
        pygame.draw.line(surface, color, p(0, -0.3), p(0, 0.2), w)
        pygame.draw.circle(surface, color, p(0, 0.45), max(1, w - 1))
    elif name == "eye":
        # An eye: two arcs meeting at the corners, and a round pupil.
        top = [p(-0.9 + 1.8 * t / 12, -0.55 * (1 - ((t - 6) / 6) ** 2)) for t in range(13)]
        bottom = [(x, 2 * cy - y) for x, y in top]
        pygame.draw.lines(surface, color, False, top, w)
        pygame.draw.lines(surface, color, False, bottom, w)
        pygame.draw.circle(surface, color, (cx, cy), max(2, round(s * 0.28)))
    else:
        # Unknown name: a plain ring, so a missing icon is visible but harmless.
        pygame.draw.circle(surface, color, (cx, cy), max(3, int(s * 0.7)), w)


ICON_NAMES = ("shield", "wall", "dash", "sprint", "blink", "coin", "coin_rush", "stasis", "time_warp", "warp",
              "nova", "second_wind", "boots", "haste", "magnet", "bolt", "laser", "play", "restart", "book", "gear",
              "exit", "empty", "warning", "eye")
"""Every icon drawn above."""
