"""The stadium: sky, far skyline, the far stand's roof and seats, the ad boards,
the track, the infield, and the things that stand on the track.

Every backdrop strip tiles left to right so the camera can follow a bounce
for as long as it needs. Strips are painted at the game's own resolution with
only the palette's colours, lit from the upper left like everything else.
"""
import math
import random

import numpy as np

import font
import palette as P
import pix

TILE = 512


def blank(w, h, col=None):
    a = np.zeros((h, w, 4), np.uint8)
    if col is not None:
        a[..., :3] = col
        a[..., 3] = 255
    return a


def rect(a, x0, y0, x1, y1, col, alpha=255):
    h, w = a.shape[:2]
    x0, x1 = max(0, int(x0)), min(w, int(x1))
    y0, y1 = max(0, int(y0)), min(h, int(y1))
    if x0 < x1 and y0 < y1:
        a[y0:y1, x0:x1, :3] = col
        a[y0:y1, x0:x1, 3] = alpha


def rect_wrap(a, x0, y0, x1, y1, col):
    """A rectangle that wraps round the strip's right edge to its left."""
    w = a.shape[1]
    rect(a, x0, y0, x1, y1, col)
    if x1 > w:
        rect(a, x0 - w, y0, x1 - w, y1, col)
    if x0 < 0:
        rect(a, x0 + w, y0, x1 + w, y1, col)


def dither(a, x0, y0, x1, y1, c0, c1, k=0.5):
    """Mix two colours in a checker (k=0.5) or a sparser 1-in-4 pattern."""
    for y in range(int(y0), int(y1)):
        for x in range(int(x0), int(x1)):
            if 0 <= y < a.shape[0] and 0 <= x < a.shape[1]:
                if k >= 0.5:
                    on = (x + y) % 2 == 0
                else:
                    on = (x % 2 == 0) and (y % 2 == 0)
                a[y, x, :3] = c1 if on else c0
                a[y, x, 3] = 255


def over(dst, src, x, y):
    h, w = src.shape[:2]
    H, W = dst.shape[:2]
    for oy in range(h):
        Y = y + oy
        if not (0 <= Y < H):
            continue
        for ox in range(w):
            X = (x + ox) % W
            if src[oy, ox, 3]:
                dst[Y, X] = src[oy, ox]


def paint(parts, w, h, xf=None, outline=True):
    c = pix.Canvas(w, h)
    xf = xf or pix.Xf()
    for p in parts:
        c.paint(p, xf)
    return c.finish(outline=outline)


# -- sky ------------------------------------------------------------------------

def sky(h=200, ramp=P.SKY):
    """A 4-pixel-wide column of sky, stretched sideways by the game. Bands of
    the ramp, top dark to horizon light, with a checker where they meet."""
    a = blank(4, h)
    n = len(ramp)
    edges = [int(h * (i + 1) / n) for i in range(n)]
    y0 = 0
    for i, y1 in enumerate(edges):
        rect(a, 0, y0, 4, y1, ramp[i])
        if i + 1 < n:
            dither(a, 0, y1 - 2, 4, y1, ramp[i], ramp[i + 1])
        y0 = y1
    return a


CLOUD = P.ramp("#7a8ec8", "#b4c6ea", "#e6eefa", "#fffaf0")


def clouds(w=960, h=64, seed=1):
    rng = random.Random(seed)
    a = blank(w, h)
    for i in range(7):
        cx = (i + 0.5) * w / 7 + rng.uniform(-30, 30)
        cy = rng.uniform(22, 44)
        parts = []
        k = rng.uniform(0.7, 1.25)
        for j in range(rng.randint(4, 7)):
            bx = rng.uniform(-28, 28) * k
            by = rng.uniform(-6, 4) * k
            r = rng.uniform(7, 14) * k * (1.0 - abs(bx) / 60)
            parts.append(pix.Part(pix.ball(bx, by, r * 1.2, r), CLOUD, z=j * 0.01, line=False, seam=False,
                                  bands=[0.12, 0.4, 0.75]))
        # a flat bottom
        parts = [pix.Part(pix.cut(p.shape, pix.slab(-80, 8 * k, 80, 40)), CLOUD, z=p.z, line=False, seam=False,
                          bands=[0.12, 0.4, 0.75]) for p in parts]
        img = paint(parts, 120, 50, pix.Xf(at=(60, 30)), outline=False)
        over(a, img, int(cx - 60), int(cy - 30))
    return a


# -- the city beyond the stadium ---------------------------------------------------
HAZE = P.ramp("#6a7ab8", "#7e92c8", "#94a8d6", "#aec0e2")


def city(w=960, h=56, seed=2):
    rng = random.Random(seed)
    a = blank(w, h)
    x = 0
    while x < w:
        bw = rng.randint(14, 34)
        bh = rng.randint(14, 48)
        col = HAZE[rng.randint(0, 1)]
        rect_wrap(a, x, h - bh, x + bw, h, col)
        rect_wrap(a, x, h - bh, x + 1, h, HAZE[2])               # lit left edge
        for wy in range(h - bh + 3, h - 2, 4):                   # windows
            for wx in range(x + 3, x + bw - 2, 4):
                if rng.random() < 0.55:
                    rect_wrap(a, wx, wy, wx + 2, wy + 2, HAZE[2] if rng.random() < 0.8 else HAZE[3])
        if rng.random() < 0.25:                                  # an aerial or a crane
            rect_wrap(a, x + bw // 2, h - bh - 8, x + bw // 2 + 1, h - bh, col)
        x += bw + rng.randint(-4, 6)
    # hills to sit it on
    for X in range(w):
        y = int(h - 6 - 3 * math.sin(X / w * 6.283 * 3) - 2 * math.sin(X / w * 6.283 * 7 + 1))
        a[y:, X, :3] = HAZE[1]
        a[y:, X, 3] = 255
        a[y, X, :3] = HAZE[2]
    return a


# -- the far stand: roof, floodlights, seats ---------------------------------------
ROOF = P.ramp("#3a3a58", "#5e6286", "#9aa0c0", "#d0d6ec", "#fffaf0")


def roof(w=TILE, h=64):
    """The far stand's roof: a white canopy on a dark truss, floodlights on top."""
    a = blank(w, h)
    # the canopy, thick at the front edge
    rect(a, 0, 30, w, 42, ROOF[3])
    rect(a, 0, 30, w, 31, ROOF[4])
    rect(a, 0, 40, w, 42, ROOF[2])
    rect(a, 0, 42, w, 46, ROOF[0])                       # its shadowed edge
    # the underside: dark, with trusses
    rect(a, 0, 46, w, h, P.CONCRETE[0])
    for x in range(0, w, 16):
        for y in range(46, h):
            t = (y - 46) % 16
            if (x + t) % 16 == 0 or (x - t) % 16 == 0:
                a[y, x % w, :3] = P.CONCRETE[1]
        rect(a, x, 46, x + 1, h, P.CONCRETE[1])
    rect(a, 0, 46, w, 47, P.CONCRETE[2])
    # floodlight banks: a mast on the roof and a grid of lamps
    for fx in (96, 352):
        rect(a, fx + 13, 6, fx + 15, 30, P.STEEL[1])
        rect(a, fx + 13, 6, fx + 14, 30, P.STEEL[3])
        rect(a, fx, 0, fx + 28, 12, P.STEEL[0])
        for ly in range(1, 11, 3):
            for lx in range(1, 27, 3):
                rect(a, fx + lx, ly, fx + lx + 2, ly + 2, P.STEEL[4])
                a[ly, fx + lx, :3] = P.WHITE
        rect(a, fx, 12, fx + 28, 13, P.STEEL[1])
    return a


SEATS = [P.SEAT_BLUE, P.SEAT_RED, P.ramp("#4a2a10", "#a0661e", "#e0a02a", "#ffd25a"), P.SEAT_BLUE]
STAND_H = 64
STAND_ROWS = list(range(7, STAND_H - 2, 7))   # each row of seats: where its fans stand (y of their feet)


def stands(w=TILE, h=STAND_H):
    """Tiers of seats in blocks of colour, stairs between the blocks, and the
    dark mouths of the tunnels. Fans are drawn on top by the game."""
    a = blank(w, h, P.CONCRETE[1])
    block = 64
    for b in range(w // block):
        ramp = SEATS[b % len(SEATS)]
        x0 = b * block + 4
        x1 = (b + 1) * block - 4
        for ry, y in enumerate(STAND_ROWS):
            # the riser, then the row of seat backs
            rect(a, x0, y - 6, x1, y, P.CONCRETE[2] if ry % 2 else P.CONCRETE[1])
            rect(a, x0, y - 4, x1, y - 1, ramp[1])
            for sx in range(x0, x1, 4):
                rect(a, sx, y - 4, sx + 3, y - 3, ramp[2])
                rect(a, sx + 3, y - 4, sx + 4, y - 1, ramp[0])
            rect(a, x0, y, x1, y + 1, P.CONCRETE[0])
        # stairs in the aisle between blocks
        for y in range(0, h, 3):
            rect(a, b * block - 4, y, b * block + 4, y + 1, P.CONCRETE[3])
            rect(a, b * block - 4, y + 1, b * block + 4, y + 3, P.CONCRETE[2])
        # a tunnel mouth half way down every other block
        if b % 2 == 1:
            tx = b * block + block // 2 - 9
            rect(a, tx, 34, tx + 18, 50, P.CONCRETE[0])
            rect(a, tx - 1, 33, tx + 19, 34, P.CONCRETE[3])
            rect(a, tx + 2, 36, tx + 16, 50, P.INK)
    # the shadow of the roof over the top rows
    for y in range(0, 10):
        for x in range(w):
            if (x + y) % 2 == 0 or y < 5:
                px = a[y, x, :3].astype(int)
                a[y, x, :3] = np.clip(px * 0.62 + np.array(P.CONCRETE[0]) * 0.38, 0, 255)
    return a


# -- the wall of ad boards between the stand and the track -------------------------
# The hot dogs' sponsors, and in between them the studio's other games
# (since 23 October 2026), each in its own colours.
ADS = [
    ("NIGHT GIRAFFE", P.hx("#24152e"), P.hx("#fffaf0"), P.hx("#c0007a")),
    ("MUSTARD & CO", P.hx("#f7d331"), P.hx("#5a2e12"), None),
    ("UNICORN BOUNCE", P.hx("#3a1c4e"), P.hx("#ffe878"), P.hx("#ff8ac4")),
    ("RELISH EVERY MOMENT", P.hx("#38a03a"), P.hx("#fffaf0"), None),
    ("REGGIE'S NEON", P.hx("#141e38"), P.hx("#ff62d0"), P.hx("#4ee2ff")),
    ("BOING!", P.hx("#2a4ad2"), P.hx("#fff07a"), None),
    ("HEARTWOOD", P.hx("#1c2e1e"), P.hx("#ffd26a"), P.hx("#8ae068")),
    ("SIZZLE SPORTS", P.hx("#d42c3a"), P.hx("#fffaf0"), None),
    ("WALLED GARDEN", P.hx("#243428"), P.hx("#f4b886"), P.hx("#a8e6a0")),
    ("BUN VOYAGE TRAVEL", P.hx("#f8d896"), P.hx("#6a3a2a"), None),
    ("POCKET GALAXY", P.hx("#141a46"), P.hx("#fff07a"), P.hx("#64b8ff")),
    ("KETCHUP IF YOU CAN", P.hx("#e0383a"), P.hx("#fff07a"), None),
    ("HOT DIGGITY", P.hx("#2a1426"), P.hx("#ff88c8"), P.hx("#ff4d64")),
    ("STAY SAUCY", P.hx("#7a3ad2"), P.hx("#fffaf0"), None),
    ("FRANKLY FANTASTIC", P.hx("#161834"), P.hx("#c688ff"), P.hx("#56e2ff")),
    ("MR FEATHERINGTON", P.hx("#282234"), P.hx("#f7d331"), P.hx("#e6dcf0")),
    ("KITCHEN TABLE", P.hx("#3a1a1e"), P.hx("#fffaf0"), P.hx("#ffd060")),
]
WALL_H = 18


def wall(seed=4):
    boards = []
    for text, bg, fg, accent in ADS:
        tw = font.width_of(text)
        bw = tw + 18
        boards.append((text, bg, fg, accent, bw))
    w = sum(b[4] + 2 for b in boards)
    w = int(math.ceil(w / 64.0) * 64)
    a = blank(w, WALL_H, P.CONCRETE[0])
    from PIL import Image
    x = 1
    for text, bg, fg, accent, bw in boards:
        rect(a, x, 2, x + bw, WALL_H - 3, bg)
        rect(a, x, 2, x + bw, 3, tuple(min(255, c + 40) for c in bg))
        rect(a, x, WALL_H - 4, x + bw, WALL_H - 3, tuple(max(0, c - 40) for c in bg))
        if accent:
            rect(a, x, WALL_H - 6, x + bw, WALL_H - 4, accent)
        img = Image.fromarray(a).copy()
        font.draw(img, text, x + 9, 4, fg)
        a = np.array(img)
        x += bw + 2
    rect(a, x, 2, w, WALL_H - 3, P.CONCRETE[1])
    rect(a, 0, 0, w, 1, P.CONCRETE[3])
    rect(a, 0, WALL_H - 3, w, WALL_H, P.CONCRETE[2])
    return a


# -- the track ------------------------------------------------------------------
LANES = [18, 20, 22, 24]          # lane heights, far to near (the near lanes are bigger)
TRACK_EDGE = 3                     # the white kerb behind lane 1


def track(w=64):
    """One tile of the track: four lanes of red tartan with white lines."""
    h = TRACK_EDGE + sum(LANES) + 1
    a = blank(w, h, P.TRACK[2])
    rng = np.random.RandomState(3)
    # tartan grain: a sparse speckle of the next steps up and down
    g = rng.rand(h, w)
    a[g < 0.06, :3] = P.TRACK[1]
    a[g > 0.95, :3] = P.TRACK[3]
    rect(a, 0, 0, w, TRACK_EDGE, P.LANE_LINE[1])
    rect(a, 0, TRACK_EDGE - 1, w, TRACK_EDGE, P.LANE_LINE[0])
    y = TRACK_EDGE
    for i, lh in enumerate(LANES):
        y += lh
        rect(a, 0, y, w, y + 1, P.LANE_LINE[1])
    # the near lanes are in a little more light
    for yy in range(TRACK_EDGE, TRACK_EDGE + LANES[0]):
        for x in range(w):
            if a[yy, x, 0] == P.TRACK[2][0] and (x + yy) % 2 == 0:
                a[yy, x, :3] = P.TRACK[1]
    return a


def lane_centres():
    out = []
    y = TRACK_EDGE
    for lh in LANES:
        out.append(y + lh * 0.62)
        y += lh
    return out


FAR_LANES = [5, 6]                # the far straight, seen across the infield


def field(w=128):
    """The infield, where the jumps and throws happen: across it, the far
    straight of the track (two thin lanes and its kerb), then grass mown in
    stripes right up to us. Tiles in step with infield()'s stripes."""
    h = TRACK_EDGE + sum(LANES) + 1
    a = blank(w, h, P.GRASS[3])
    y = 0
    rect(a, 0, 0, w, 2, P.LANE_LINE[1])                    # the outer kerb, by the wall
    y = 2
    rng = np.random.RandomState(13)
    for lh in FAR_LANES:
        rect(a, 0, y, w, y + lh, P.TRACK[2])
        g = rng.rand(lh, w)
        sub = a[y:y + lh]
        sub[g < 0.08, :3] = P.TRACK[1]
        sub[g > 0.95, :3] = P.TRACK[3]
        y += lh
        rect(a, 0, y, w, y + 1, P.LANE_LINE[1])
        y += 1
    rect(a, 0, y, w, y + 2, P.CONCRETE[4])                 # the inner kerb
    rect(a, 0, y + 2, w, y + 3, P.CONCRETE[2])
    top = y + 3
    for x in range(w):
        stripe = (x // 32) % 2
        for yy in range(top, h):
            a[yy, x, :3] = P.GRASS[3] if stripe else P.GRASS[2]
    g = np.random.RandomState(15).rand(h, w)
    for yy in range(top, h):
        for x in range(w):
            if g[yy, x] < 0.025:
                a[yy, x, :3] = P.GRASS[4]
            elif g[yy, x] > 0.985:
                a[yy, x, :3] = P.GRASS[1]
    rect(a, 0, top, w, top + 1, P.GRASS[0])                # the kerb's shadow on the grass
    return a


INFIELD_H = 40


def infield(w=128, kerb=True):
    """The grass on our side of the track, mown in stripes, with the kerb
    (or, in the infield itself, without)."""
    a = blank(w, INFIELD_H, P.GRASS[3])
    for x in range(w):
        stripe = ((x + 0) // 32) % 2
        for y in range(4, INFIELD_H):
            c = P.GRASS[3] if stripe else P.GRASS[2]
            a[y, x, :3] = c
    rng = np.random.RandomState(5)
    g = rng.rand(INFIELD_H, w)
    for y in range(4, INFIELD_H):
        for x in range(w):
            if g[y, x] < 0.025:
                a[y, x, :3] = P.GRASS[4]
            elif g[y, x] > 0.985:
                a[y, x, :3] = P.GRASS[1]
    if not kerb:
        for y in range(0, 4):
            for x in range(w):
                a[y, x, :3] = P.GRASS[3] if (x // 32) % 2 else P.GRASS[2]
        return a
    # the kerb: white concrete with a shadow under it
    rect(a, 0, 0, w, 3, P.CONCRETE[4])
    rect(a, 0, 2, w, 3, P.CONCRETE[3])
    rect(a, 0, 3, w, 5, P.GRASS[0])
    return a


# -- things on the track -------------------------------------------------------------

def _fence(w, h, top, board_h, post_ramp, board_ramp, depth=(5, -8), knocked=False, post_w=1.2, stripes=(0.25, 0.75)):
    """A hurdle or a barrier, seen from the side of the track and a little
    above: the near post, the far one a step up and behind, and the top board
    between them as a thick band. Its near foot is at x=7 on the bottom row."""
    a = blank(w, h)
    near = (7, h - 2)
    far = (near[0] + depth[0], near[1] + depth[1])
    parts = []
    for i, (fx, fy) in enumerate((far, near)):
        if not knocked:
            parts.append(pix.Part(pix.slab(fx - post_w, fy - top, fx + post_w, fy, bevel=0.6), post_ramp, z=i))
        parts.append(pix.Part(pix.slab(fx - 2.5, fy - 1.8, fx + 7, fy, bevel=0.5), post_ramp, z=i + 0.1))
    if not knocked:
        y0, y1 = near[1] - top - board_h, near[1] - top
        board = pix.poly([(near[0] - 3, y0), (far[0] - 3, y0 + depth[1]), (far[0] + 3, y0 + depth[1]),
                          (far[0] + 3, y1 + depth[1]), (near[0] + 3, y1), (near[0] - 3, y1)])
        parts.append(pix.Part(board, board_ramp, z=5, bands=[0.05, 0.5]))
    else:
        parts.append(pix.Part(pix.slab(near[0] + 1, near[1] - board_h - 1, near[0] + 15, near[1] - 1, bevel=0.6),
                              board_ramp, z=5))
    img = paint(parts, w, h)
    if not knocked:
        # black stripes across the board's face
        for t in stripes:
            x = int(near[0] - 3 + 6 * t)
            for yy in range(h):
                for xx in (x, x + 1):
                    if 0 <= xx < w and img[yy, xx, 3] and yy <= near[1] - top and yy >= near[1] - top - board_h:
                        if tuple(img[yy, xx, :3]) != tuple(P.INK):
                            img[yy, xx, :3] = P.INK
    return img


WHITE_BOARD = P.ramp("#5a5a70", "#c8c8d8", "#fffaf0")


def hurdle(knocked=False):
    return _fence(30, 44, 20, 4, P.STEEL, WHITE_BOARD, knocked=knocked)


def sandpit(w=TILE):
    """A long-jump pit along the near lanes: its wooden edge and raked sand."""
    h = sum(LANES[1:]) + 6
    a = blank(w, h, P.SAND[2])
    rng = np.random.RandomState(9)
    g = rng.rand(h, w)
    a[g < 0.10, :3] = P.SAND[1]
    a[g > 0.93, :3] = P.SAND[3]
    for y in range(4, h - 3, 5):              # rake lines
        for x in range(w):
            if (x // 3) % 2 == 0:
                a[y, x, :3] = P.SAND[1]
    rect(a, 0, 0, w, 2, P.WOOD[3])
    rect(a, 0, 2, w, 3, P.WOOD[1])
    rect(a, 0, h - 3, w, h - 1, P.WOOD[2])
    rect(a, 0, h - 1, w, h, P.WOOD[0])
    return a


def takeoff_board():
    a = blank(8, sum(LANES[1:]) + 2)
    rect(a, 0, 0, 8, a.shape[0], P.WHITE)
    rect(a, 0, 0, 1, a.shape[0], P.CONCRETE[3])
    rect(a, 6, 0, 8, a.shape[0], P.hx("#e8dcc0"))        # the plasticine strip
    return a


def finish_post():
    """The photo-finish post on the far side of the finish line."""
    w, h = 16, 60
    parts = [pix.Part(pix.slab(6, 8, 10, 60, bevel=1), P.STEEL, z=0),
             pix.Part(pix.slab(1, 0, 15, 10, bevel=1.5, round_=1), P.ramp("#24152e", "#3a2a4a", "#5a4a6a", "#8a7aa0"), z=1),
             pix.Part(pix.ball(4, 5, 2.2), P.ramp("#0e1238", "#3e5ac0", "#9ad8f0"), z=2, shine=1.2)]
    return paint(parts, w, h)


def distance_board(text):
    """A little board on a stick in the infield: 10m, 20m..."""
    from PIL import Image
    tw = font.width_of(text)
    w, h = tw + 6, 22
    a = blank(w, h)
    rect(a, w // 2 - 1, 10, w // 2 + 1, h, P.STEEL[2])
    rect(a, 0, 0, w, 11, P.INK)
    rect(a, 1, 1, w - 1, 10, P.WHITE)
    img = Image.fromarray(a).copy()
    font.draw(img, text, 3, 2, P.INK)
    return np.array(img)


# -- the steeplechase ------------------------------------------------------------------

def barrier():
    """A steeplechase barrier: a heavy striped beam on stout wooden posts; it
    doesn't fall over."""
    return _fence(32, 46, 21, 6, P.WOOD, WHITE_BOARD, post_w=1.8, stripes=(0.2, 0.7))


def water_pit(w=128):
    """The water jump, as a strip that tiles along the pit (drawn across the lanes)."""
    h = sum(LANES[1:]) + 6
    a = blank(w, h, P.WATER[2])
    for y in range(h):
        for x in range(w):
            if (x + y * 3) % 23 < 3 and y % 4 == 1:
                a[y, x, :3] = P.WATER[4]
            elif (x * 2 + y) % 31 < 2:
                a[y, x, :3] = P.WATER[3]
    rect(a, 0, 0, w, 2, P.CONCRETE[3])
    rect(a, 0, 2, w, 3, P.WATER[0])
    rect(a, 0, h - 3, w, h - 1, P.CONCRETE[2])
    rect(a, 0, h - 1, w, h, P.CONCRETE[0])
    return a


# -- the meatball put and the vault ------------------------------------------------------

MEAT = P.ramp("#3a1a14", "#6a3222", "#94502e", "#b8703e", "#d89a5e")


def meatball():
    parts = [pix.Part(pix.bumps(pix.ball(0, 0, 4.2), 3, scale=2.2, amount=0.35), MEAT, z=0, shine=0.8)]
    # a dribble of tomato sauce on top
    parts.append(pix.Part(pix.clip(pix.ball(0, 0, 4.2), pix.ball(-0.8, -2.6, 3.0, 1.6)), P.TOMATO, z=1, shine=1.0))
    return paint(parts, 12, 12, pix.Xf(at=(6, 6)))


def springboard():
    """The vault's springboard: a sprung board on a wedge, seen side on."""
    w, h = 30, 14
    parts = [pix.Part(pix.poly([(2, 12), (27, 12), (27, 6), (2, 10)]), P.STEEL, z=0),
             pix.Part(pix.slab(1, 5, 29, 8, bevel=1.0), P.ramp("#7a1428", "#d42c3a", "#ff6a6a"), z=1),
             pix.Part(pix.tube([(8, 9), (10, 11), (12, 9), (14, 11), (16, 9), (18, 11), (20, 9)], 0.7), P.STEEL, z=0.5)]
    return paint(parts, w, h)


# -- the swimming pool (the stadium with water for a track) ---------------------------------

def swim_lanes(w=64):
    """One tile of the pool: four lanes of water with lane ropes between them,
    the same heights as the track's lanes so swimmers sit where runners do."""
    h = TRACK_EDGE + sum(LANES) + 1
    a = blank(w, h, P.WATER[2])
    rng = np.random.RandomState(11)
    for y in range(h):
        for x in range(w):
            k = (x + int(6 * math.sin(y * 0.7))) % 32
            if k < 5 and y % 3 == 0:
                a[y, x, :3] = P.WATER[3]
            elif rng.rand() < 0.02:
                a[y, x, :3] = P.WATER[4]
    rect(a, 0, 0, w, TRACK_EDGE, P.TILE[2])
    rect(a, 0, TRACK_EDGE - 1, w, TRACK_EDGE, P.TILE[0])
    y = TRACK_EDGE
    for i, lh in enumerate(LANES):
        y += lh
        if i < len(LANES) - 1:
            # a lane rope: floats, red and white in turn
            for x in range(0, w, 4):
                col = P.hx("#e0383a") if (x // 4) % 2 == 0 else P.WHITE
                rect(a, x, y - 1, x + 3, y + 1, col)
                rect(a, x, y + 1, x + 3, y + 2, P.WATER[0])
    return a


def pool_deck(w=128):
    """The poolside on our side: pale tiles and the gutter."""
    a = blank(w, INFIELD_H, P.TILE[3])
    for y in range(4, INFIELD_H, 8):
        rect(a, 0, y, w, y + 1, P.TILE[2])
    for x in range(0, w, 8):
        for y in range(4, INFIELD_H):
            if ((y - 4) // 8) % 2 == 0 and x % 16 == 0 or ((y - 4) // 8) % 2 == 1 and x % 16 == 8:
                a[y, x, :3] = P.TILE[2]
    rect(a, 0, 0, w, 2, P.TILE[1])
    rect(a, 0, 2, w, 4, P.TILE[0])
    return a
