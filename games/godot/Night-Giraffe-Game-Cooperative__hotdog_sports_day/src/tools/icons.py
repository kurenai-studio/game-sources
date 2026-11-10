"""Sports pictograms for every event: a white hot dog (no arms, no legs) and
its kit on a coloured tile, in the manner of the Games' own pictograms.

Drawn at 6 times size with plain shapes, shrunk to 32x32 with a hard edge, then
given an ink outline and a rim, so they sit with the rest of the pixel art.
"""
import math

import numpy as np
from PIL import Image, ImageDraw

import palette as P

S = 32
K = 6                      # supersampling
KK = K * S / 26.0          # the pictograms are laid out on a 26-pixel grid
W = (255, 250, 240, 255)


def _caps(d, a, b, r, fill=W):
    """A capsule from a to b (big-pixel coordinates), radius r."""
    ax, ay = a
    bx, by = b
    ang = math.atan2(by - ay, bx - ax)
    nx, ny = -math.sin(ang) * r, math.cos(ang) * r
    d.polygon([(ax + nx, ay + ny), (bx + nx, by + ny), (bx - nx, by - ny), (ax - nx, ay - ny)], fill=fill)
    d.ellipse([ax - r, ay - r, ax + r, ay + r], fill=fill)
    d.ellipse([bx - r, by - r, bx + r, by + r], fill=fill)


def _rot(p, c, ang):
    s, co = math.sin(ang), math.cos(ang)
    x, y = p[0] - c[0], p[1] - c[1]
    return (c[0] + x * co - y * s, c[1] + x * s + y * co)


def hotdog(d, cx, cy, ang=0.0, size=1.0, gap=None):
    """A hot dog standing on (cx, cy) (its bottom), turned by ang degrees: the
    sausage with two eyes and a sweatband, sitting in a U of bun."""
    a = math.radians(ang)
    u = KK * size * 0.82
    c = (cx * KK, cy * KK)

    def R(x, y):
        return _rot((c[0] + x * u, c[1] + y * u), c, a)
    clear = (0, 0, 0, 0)
    for side in (-1, 1):
        _caps(d, R(side * 3.4, -2.0), R(side * 3.4, -6.6), 1.5 * u)
    _caps(d, R(-3.4, -1.8), R(3.4, -1.8), 1.5 * u)
    _caps(d, R(0, -2.8), R(0, -11.0), 3.2 * u, fill=clear)
    _caps(d, R(0, -2.8), R(0, -11.0), 2.35 * u)
    d.line([R(-2.6, -9.8), R(2.6, -9.8)], fill=clear, width=max(1, int(1.0 * u)))
    for ex in (-0.95, 1.15):
        e = R(ex, -7.6)
        d.ellipse([e[0] - 0.6 * u, e[1] - 0.8 * u, e[0] + 0.6 * u, e[1] + 0.8 * u], fill=clear)


def _dots(d, pts, r=0.6):
    for (x, y) in pts:
        d.ellipse([(x - r) * KK, (y - r) * KK, (x + r) * KK, (y + r) * KK], fill=W)


def _line(d, a, b, w=1.0):
    d.line([(a[0] * KK, a[1] * KK), (b[0] * KK, b[1] * KK)], fill=W, width=int(w * KK))


def _waves(d, y, x0=3, x1=23):
    for x in range(x0, x1, 5):
        d.arc([x * KK, (y - 1.5) * KK, (x + 5) * KK, (y + 1.5) * KK], 0, 180, fill=W, width=int(0.9 * KK))


DRAW = {}


def icon(name, tile):
    def wrap(fn):
        DRAW[name] = (fn, tile)
        return fn
    return wrap


@icon("sprint", "#e0383a")
def _(d):
    hotdog(d, 15, 21, 18)
    for y in (9, 13, 17):
        _line(d, (3, y), (8, y), 1.0)


@icon("long_jump", "#d0902e")
def _(d):
    hotdog(d, 12, 15, 62)
    _line(d, (3, 22), (23, 22), 1.2)
    _dots(d, [(17, 20), (19, 19), (21, 20)], 0.7)


@icon("meatball_put", "#94502e")
def _(d):
    hotdog(d, 9, 22, -8)
    d.ellipse([12.5 * KK, 4.5 * KK, 17.5 * KK, 9.5 * KK], fill=W)
    _dots(d, [(19.5, 9), (21.5, 12), (22.5, 15.5)], 0.6)


@icon("hurdles", "#38a03a")
def _(d):
    _line(d, (13, 23), (13, 16), 1.0)
    _line(d, (20, 23), (20, 16), 1.0)
    _line(d, (11.5, 15.5), (21.5, 15.5), 1.6)
    hotdog(d, 10, 13, 25, 0.85)


@icon("high_jump", "#2a4ad2")
def _(d):
    _line(d, (3, 14), (23, 14), 1.0)
    _line(d, (4, 14), (4, 23), 0.8)
    _line(d, (22, 14), (22, 23), 0.8)
    hotdog(d, 7, 11, 90, 0.9)


@icon("triple_jump", "#c0602e")
def _(d):
    for x0 in (3, 9, 15):
        d.arc([x0 * KK, 14 * KK, (x0 + 6) * KK, 20 * KK], 180, 360, fill=W, width=int(0.8 * KK))
    hotdog(d, 18, 15, 40, 0.8)


@icon("vault", "#7a3ad2")
def _(d):
    _line(d, (14, 6), (23, 6), 1.0)
    _line(d, (2, 23), (8, 21), 1.2)
    hotdog(d, 12, 11, 110, 0.85)


@icon("steeplechase", "#2a7a8a")
def _(d):
    _line(d, (8, 20), (8, 14), 1.0)
    _line(d, (6, 13.5), (11, 13.5), 1.6)
    _waves(d, 22, 12, 24)
    hotdog(d, 16, 14, 30, 0.8)


@icon("relay", "#f04aa8")
def _(d):
    hotdog(d, 8, 21, 15, 0.8)
    hotdog(d, 18, 21, 15, 0.8)
    _line(d, (10, 6), (16, 6), 1.0)
    d.polygon([(16 * KK, 4 * KK), (19 * KK, 6 * KK), (16 * KK, 8 * KK)], fill=W)


@icon("dive", "#1e9a9a")
def _(d):
    hotdog(d, 13, 4, 180, 0.95)
    _waves(d, 22)


@icon("swim", "#2a86b4")
def _(d):
    hotdog(d, 4, 15, 90, 0.9)
    _waves(d, 20)


@icon("trampoline", "#e0701e")
def _(d):
    _line(d, (4, 22), (22, 22), 1.0)
    _line(d, (5, 22), (5, 24), 0.8)
    _line(d, (21, 22), (21, 24), 0.8)
    hotdog(d, 13, 6, 180, 0.85)
    d.arc([6 * KK, 2 * KK, 20 * KK, 18 * KK], 200, 340, fill=W, width=int(0.7 * KK))


@icon("breaking", "#3a1468")
def _(d):
    hotdog(d, 13, 5, 180, 0.95)
    d.arc([5 * KK, 15 * KK, 21 * KK, 24 * KK], 190, 350, fill=W, width=int(0.7 * KK))
    _dots(d, [(4, 10), (22, 10)], 0.7)


@icon("skateboard", "#f0701e")
def _(d):
    hotdog(d, 13, 18, -10, 0.9)
    _line(d, (6, 19.5), (20, 18), 1.2)
    _dots(d, [(8, 21), (18, 20)], 0.9)


@icon("ski_jump", "#4aa2e8")
def _(d):
    _line(d, (3, 12), (23, 24), 1.0)
    hotdog(d, 12, 13, 55, 0.85)
    _line(d, (8, 15), (19, 9), 0.8)


@icon("bobsleigh", "#1e2a7a")
def _(d):
    d.pieslice([3 * KK, 9 * KK, 23 * KK, 23 * KK], 0, 180, fill=W)
    hotdog(d, 13, 16, 0, 0.7, gap=None)
    for y in (12, 15):
        _line(d, (1, y), (4, y), 0.8)


def render(name):
    fn, tile = DRAW[name]
    big = Image.new("RGBA", (int(26 * KK), int(26 * KK)), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    fn(d)
    small = big.resize((S, S), Image.BOX)
    a = np.array(small)
    fig = a[..., 3] > 110
    out = np.zeros((S, S, 4), np.uint8)
    col = P.hx(tile)
    # the tile: rounded corners, a light top edge and a dark bottom one
    yy, xx = np.mgrid[0:S, 0:S]
    r = 4
    inside = np.ones((S, S), bool)
    for cx, cy in ((r, r), (S - 1 - r, r), (r, S - 1 - r), (S - 1 - r, S - 1 - r)):
        corner = ((xx < r) if cx == r else (xx > S - 1 - r)) & ((yy < r) if cy == r else (yy > S - 1 - r))
        inside &= ~(corner & ((xx - cx) ** 2 + (yy - cy) ** 2 > r * r))
    out[inside, :3] = col
    out[inside, 3] = 255
    rim = inside & ~np.roll(inside, -1, 0)
    out[rim, :3] = np.clip(np.array(col) * 0.6, 0, 255).astype(np.uint8)
    top = inside & ~np.roll(inside, 1, 0)
    out[top, :3] = np.clip(np.array(col) * 0.6 + 110, 0, 255).astype(np.uint8)
    edge = inside & ~(np.roll(inside, 1, 1) & np.roll(inside, -1, 1) & np.roll(inside, 1, 0) & np.roll(inside, -1, 0))
    out[edge, :3] = P.INK
    # the figure, with a dark outline where it meets the tile
    ring = np.zeros((S, S), bool)
    for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        ring |= np.roll(np.roll(fig, dy, 0), dx, 1)
    ring &= ~fig & inside & ~edge
    out[ring, :3] = np.clip(np.array(col) * 0.45, 0, 255).astype(np.uint8)
    out[fig & inside, :3] = P.WHITE
    return out


def sheet():
    names = list(DRAW)
    img = np.zeros((S, S * len(names), 4), np.uint8)
    for i, n in enumerate(names):
        img[:, i * S:(i + 1) * S] = render(n)
    return Image.fromarray(img), names
