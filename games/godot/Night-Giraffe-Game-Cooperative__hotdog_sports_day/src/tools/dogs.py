"""What a hot dog athlete is made of: a sausage, a bun (or batter, or bread),
toppings worn like a vest or heaped like hair, an 80s sweatband, and (drawn on
top by the game) a cartoon face.

Every athlete stands upright in its bun with the sausage's head poking out of
the top. They have no arms and no legs: they bounce. Local coordinates: the
origin is the bottom of the bun, where it bounces; y runs up the screen as
negative numbers. A neutral athlete is 44 pixels tall.

Each piece is a list of layers; a layer is a list of pix.Part. The layers are
painted as separate sprite sheets so the game can put any sausage in any bun
with any toppings (the dressing room), in this order:
    back (bun behind) < sausage < front (bun before) < toppings < band
The face is drawn last, by the game, at the anchors saved for each frame.
"""
import math
import random

import palette as P
import pix

TOP = -44.0        # top of the sausage, neutral
FOOT_Y = -3.0      # bottom of the sausage (the bun's fold is below it)
R = 7.5            # sausage radius
BUN_X = 8.4        # bun halves' centre lines
BUN_R = 4.8
BUN_TOP = -28.0

# Anchors (local) the game draws the face and the hat-like things at.
ANCHORS = {
    "eyes": (1.0, -33.2),      # between the eyes
    "mouth": (1.4, -27.9),
    "brow": (1.0, -37.6),
    "top": (0.0, -44.0),       # top of the head
    "chest": (0.0, -19.0),
    "centre": (0.0, -22.0),
}


def _sausage_shape(kind):
    a = (0, FOOT_Y - R)
    b = (0, TOP + R)
    if kind == "corn":            # a corn dog is all batter: its "sausage" is the batter
        return pix.sausage((0, -9 - R), (0, TOP + R + 0.5), R + 1.0)
    if kind == "brat":
        return pix.sausage(a, (0, TOP + R - 1.0), R - 0.4)
    if kind == "banger":
        return pix.sausage(a, (0, TOP + R + 0.8), R + 0.6)
    if kind == "square":          # a Lorne: a slice, square-cornered
        return pix.slab(-R - 0.4, TOP + 0.6, R + 0.4, FOOT_Y + 0.5, bevel=2.2, round_=2.2)
    return pix.sausage(a, b, R)


SAUSAGES = {
    # name: (ramp, shape kind, shine)
    "frank": (P.FRANK, "frank", 1.4),
    "brat": (P.BRAT, "brat", 1.0),
    "red": (P.RED_POLSE, "frank", 1.6),
    "banger": (P.BANGER, "banger", 0.9),
    "chorizo": (P.CHORIZO, "frank", 1.2),
    "bacon": (P.BACON, "frank", 0.8),
    "corn": (P.BATTER, "corn", 0.0),
    "tako": (P.FRANK, "tako", 1.4),
    "cumberland": (P.CUMBERLAND, "banger", 0.7),
    "glamorgan": (P.GLAMORGAN, "frank", 0.0),
    "lorne": (P.LORNE, "square", 0.6),
    # the silly ones, unlocked by playing (data/wardrobe.json)
    "golden": (P.GOLDEN, "frank", 2.4),
    "blue": (P.BLUE_RASPBERRY, "frank", 1.8),
    "pink": (P.PINK_SAUSAGE, "frank", 1.6),
    "glow": (P.GLOW, "frank", 2.0),
    "zombie": (P.ZOMBIE, "banger", 0.4),
    "rainbow": (P.KNIT_RED, "frank", 1.4),
}

RAINBOW = [P.KNIT_RED, P.CONE_ORANGE, P.PARTY_YELLOW, P.RELISH, P.CAP_BLUE, P.WIZARD]


def sausage_layer(name):
    ramp, kind, shine = SAUSAGES[name]
    if kind == "corn":
        body = pix.bumps(_sausage_shape("corn"), 7, scale=1.5, amount=0.32)
        return [pix.Part(body, ramp, z=10),
                # the stick it bounces on
                pix.Part(pix.sausage((0, -1.4), (0, -12), 1.5), P.STICK, z=9)]
    shape = _sausage_shape(kind)
    if kind == "tako":
        # an octopus-cut wiener: the bottom is cut into little curly legs
        legs = []
        for i, x in enumerate((-4.6, -1.6, 1.6, 4.6)):
            legs.append(pix.Part(pix.tube([(x * 0.6, -10), (x, -3.5), (x * 1.3, -1.2)], 1.6), ramp, z=31 + i * 0.01))
        top = pix.clip(shape, pix.slab(-9, -48, 9, -8))
        return [pix.Part(top, ramp, z=10, shine=shine)] + legs
    parts = [pix.Part(shape, ramp, z=10, shine=shine)]
    if name == "cumberland":
        # coarse ground, flecked with pepper and herbs
        return [pix.Part(pix.bumps(shape, 41, scale=2.1, amount=0.22), ramp, z=10, shine=shine)] + \
            _flecks(shape, 17, 14, P.HERB, 10.3)
    if name == "glamorgan":
        # no meat at all: cheese and leek in breadcrumbs, flecked green
        return [pix.Part(pix.bumps(shape, 43, scale=2.4, amount=0.4), ramp, z=10)] + \
            _flecks(shape, 19, 10, P.LEEK_GREEN[1:], 10.3)
    if name == "lorne":
        return [pix.Part(shape, ramp, z=10, shine=shine)] + _flecks(shape, 23, 12, P.FAT_FLECK, 10.3)
    if name == "rainbow":
        for i, ramp_ in enumerate(RAINBOW):
            y = -52 + i * 8.5
            band = pix.clip(shape, pix.slab(-12, y, 12, y + (8.5 if i < 5 else 14), bevel=0.1))
            parts.append(pix.Part(band, ramp_, z=10.1 + i * 0.01, line=False, seam=False, shine=shine))
        return parts
    if name == "zombie":
        for y in (-34.0, -20.0):
            parts.append(pix.Part(pix.tube([(-6.5, y), (6.5, y - 1.0)], 0.5), [P.INK], z=10.4, line=False, seam=False,
                                  outline=False, flat=True))
            for x in (-4.5, -1.5, 1.5, 4.5):
                parts.append(pix.Part(pix.tube([(x, y - 1.6), (x, y + 1.0)], 0.45), [P.INK], z=10.5, line=False,
                                      seam=False, outline=False, flat=True))
        return parts + _flecks(shape, 29, 8, P.GLOW[1:3], 10.3)
    if name == "glow":
        return parts + _flecks(shape, 31, 10, P.GLOW[3:], 10.3)
    if name == "golden":
        return parts + _flecks(shape, 37, 6, [P.WHITE], 10.3)
    if name == "bacon":
        # bacon wound round in a spiral: diagonal bands clipped to the sausage
        for i in range(7):
            y = -5 - i * 5.8
            band = pix.clip(shape, pix.poly([(-9, y), (9, y - 4.4), (9, y - 7.0), (-9, y - 2.6)]))
            parts.append(pix.Part(band, P.BACON_FAT, z=10.2, line=False, seam=False))
    return parts


def _flecks(shape, seed, n, ramp, z):
    """Little specks on a sausage: herbs, leek, fat."""
    rng = random.Random(seed)
    out = []
    for i in range(n):
        x, y = rng.uniform(-5.5, 5.5), rng.uniform(-40, -6)
        out.append(pix.Part(pix.clip(pix.ball(x, y, 0.7), shape), ramp, z=z + i * 0.001, line=False, seam=False,
                            outline=False, flat=True))
    return out


# -- buns -----------------------------------------------------------------------
# A bun half is a crust capsule with its pale crumb showing on the inner side;
# behind the sausage the two halves join in a fold, so it reads as one bun.

def _bun_half(side, ramp, crumb, top=BUN_TOP, bottom=0.0, r=BUN_R, x=BUN_X, z=20, seed=0, bumpy=0.0):
    a = (side * x, bottom - r)
    b = (side * x, top + r)
    crust = pix.sausage(a, b, r)
    if bumpy:
        crust = pix.bumps(crust, seed, scale=1.4, amount=bumpy)
    inner = pix.clip(pix.sausage((side * (x - 1.6), bottom - r - 0.4), (side * (x - 1.6), top + r + 0.6), r - 1.7),
                     pix.slab(-20 if side > 0 else 0, -60, 0 if side > 0 else 20, 10))
    return [pix.Part(crust, ramp, z=z),
            pix.Part(inner, crumb, z=z + 0.5, line=False, seam=False, outline=False, bands=[0.25, 0.55, 0.85])]


def _fold(ramp, x=BUN_X, r=BUN_R, bottom=0.0, top=BUN_TOP):
    """The bun behind the sausage: the crumb inside, and the crust fold at the
    bottom joining the two halves."""
    inside = pix.slab(-x, top + 2, x, bottom - 3, bevel=2.0)
    fold = pix.sausage((-x, bottom - r), (x, bottom - r), r)
    return [pix.Part(inside, P.CRUMB, z=4, line=False), pix.Part(fold, ramp, z=5)]


def _bun(name):
    """Returns (back parts, front parts)."""
    if name == "soft":
        return _fold(P.BUN), _bun_half(-1, P.BUN, P.CRUMB) + _bun_half(1, P.BUN, P.CRUMB, z=21)
    if name == "poppy":
        front = _bun_half(-1, P.BUN, P.CRUMB) + _bun_half(1, P.BUN, P.CRUMB, z=21)
        return _fold(P.BUN), front + _seeds(5, P.POPPY)
    if name == "sesame":
        front = _bun_half(-1, P.BUN, P.CRUMB) + _bun_half(1, P.BUN, P.CRUMB, z=21)
        return _fold(P.BUN), front + _seeds(6, P.SESAME)
    if name == "crusty":     # brötchen: rounder, crustier, shorter
        k = dict(top=-25.5, r=5.4, x=8.6, bumpy=0.25)
        front = _bun_half(-1, P.CRUSTY, P.CRUMB, seed=3, **k) + _bun_half(1, P.CRUSTY, P.CRUMB, z=21, seed=4, **k)
        return _fold(P.CRUSTY, x=8.6, r=5.4, top=-25.5), front
    if name == "baguette":   # long, thin, with slashes
        k = dict(top=-36.0, r=4.1, x=8.0)
        front = _bun_half(-1, P.CRUSTY, P.CRUMB, **k) + _bun_half(1, P.CRUSTY, P.CRUMB, z=21, **k)
        for side in (-1, 1):
            for y in (-10, -19, -28):
                front.append(pix.Part(pix.tube([(side * 10.5, y + 1.6), (side * 9.0, y - 1.7)], 0.55), P.CRUMB[1:],
                                      z=22, line=False, seam=False, outline=False, flat=True))
        return _fold(P.CRUSTY, x=8.0, r=4.1, top=-36), front
    if name == "white":      # Australian sausage sizzle: a slice of white bread folded round
        slice_ = pix.slab(-12.5, -27.5, 12.5, 0, bevel=2.0, round_=2.5)
        window = pix.slab(-4.4, -40, 4.4, -2.5)   # the sausage shows down the middle
        crust = pix.cut(pix.slab(-13.5, -28.5, 13.5, 1, round_=3.0), pix.slab(-12.5, -27.5, 12.5, 0, round_=2.5))
        return ([pix.Part(pix.slab(-12, -27, 12, 0), P.WHITE_BREAD, z=4, line=False)],
                [pix.Part(pix.cut(slice_, window), P.WHITE_BREAD, z=20),
                 pix.Part(pix.cut(crust, window), P.CRUSTY[1:], z=20.1, line=False)])
    if name == "tube":       # Czech rohlík: a closed roll, the sausage pops out of the top
        roll = pix.sausage((0, -9.6), (0, -21), 9.6)
        front = [pix.Part(pix.bumps(roll, 11, scale=1.1, amount=0.18), P.CRUSTY, z=20)]
        for y in (-9, -15.5, -22):
            front.append(pix.Part(pix.tube([(-8.5, y + 2), (8.5, y - 2)], 0.6), P.CRUSTY[2:], z=20.5, line=False,
                                  seam=False, outline=False, flat=True))
        return [pix.Part(pix.ball(0, -30.4, 8.0, 2.4), P.CRUMB, z=19.5, line=False)], front
    if name == "flat":       # Swedish tunnbröd: wrapped like a cone
        wrap = pix.poly([(-12.5, -27), (12.5, -31), (8.5, 0), (-7.5, 0)])
        return [], [pix.Part(pix.bumps(wrap, 5, scale=1.2, amount=0.3), P.FLATBREAD, z=20)]
    if name == "bolillo":    # Mexican bolillo: fat and soft
        k = dict(top=-29.0, r=5.6, x=8.8)
        front = _bun_half(-1, P.BUN, P.CRUMB, **k) + _bun_half(1, P.BUN, P.CRUMB, z=21, **k)
        return _fold(P.BUN, x=8.8, r=5.6, top=-29), front
    if name == "floury":     # a floury bap: soft, pale, dusted
        k = dict(top=-27.0, r=5.4, x=8.8)
        front = _bun_half(-1, P.FLOURY, P.CRUMB, **k) + _bun_half(1, P.FLOURY, P.CRUMB, z=21, **k)
        return _fold(P.FLOURY, x=8.8, r=5.4, top=-27), front + _flour(7)
    if name == "farl":       # a soda farl: flat, square-shouldered, floury
        k = dict(top=-23.5, r=5.8, x=9.0, bumpy=0.2)
        front = _bun_half(-1, P.SODA, P.CRUMB, seed=7, **k) + _bun_half(1, P.SODA, P.CRUMB, z=21, seed=8, **k)
        return _fold(P.SODA, x=9.0, r=5.8, top=-23.5), front + _flour(9)
    if name == "pretzel":    # dark, glossy and salted
        k = dict(top=-27.0, r=5.0, x=8.6, bumpy=0.15)
        front = _bun_half(-1, P.PRETZEL, P.CRUMB, seed=12, **k) + _bun_half(1, P.PRETZEL, P.CRUMB, z=21, seed=13, **k)
        return _fold(P.PRETZEL, x=8.6, r=5.0, top=-27), front + _seeds(14, P.SALT)
    if name == "chocolate":  # an eclair, really
        k = dict(top=-28.0, r=5.0, x=8.6)
        front = _bun_half(-1, P.FLOURY, P.CRUMB, **k) + _bun_half(1, P.FLOURY, P.CRUMB, z=21, **k)
        for side in (-1, 1):
            top = pix.clip(pix.sausage((side * 8.6, -5.0), (side * 8.6, -23.0), 5.0),
                           pix.slab(side * 8.6 - 6, -40, side * 8.6 + 6, -14, bevel=0.1))
            front.append(pix.Part(top, P.CHOCOLATE, z=21.6 + side * 0.01, shine=1.4))
        return _fold(P.FLOURY, x=8.6, r=5.0, top=-28), front
    if name == "iced":       # pink icing and sprinkles: a party bun
        front = _bun_half(-1, P.BUN, P.CRUMB) + _bun_half(1, P.BUN, P.CRUMB, z=21)
        for side in (-1, 1):
            top = pix.clip(pix.sausage((side * BUN_X, -4.8), (side * BUN_X, -23.2), BUN_R + 0.2),
                           pix.slab(side * BUN_X - 6, -40, side * BUN_X + 6, -16, bevel=0.1))
            front.append(pix.Part(pix.bumps(top, 21 + side, scale=1.2, amount=0.2), P.ICING_PINK, z=21.6 + side * 0.01,
                                  shine=1.0))
        rng = random.Random(15)
        for i in range(14):
            side = -1 if i % 2 else 1
            x, y = side * rng.uniform(6.5, 12.0), rng.uniform(-26.5, -17.5)
            a = rng.uniform(0, math.pi)
            d = (math.cos(a) * 0.8, math.sin(a) * 0.8)
            front.append(pix.Part(pix.tube([(x - d[0], y - d[1]), (x + d[0], y + d[1])], 0.45), P.SPRINKLES[i % 5],
                                  z=22, line=False, seam=False, outline=False, flat=True))
        return _fold(P.BUN), front
    if name == "glitter":    # purple, and it sparkles
        front = _bun_half(-1, P.GLITTER, P.CRUMB) + _bun_half(1, P.GLITTER, P.CRUMB, z=21)
        return _fold(P.GLITTER), front + _seeds(16, P.STAR) + _seeds(17, [P.WHITE])
    if name == "cloud":      # a fluffy white cloud
        k = dict(top=-27.0, r=5.6, x=8.8, bumpy=0.5)
        front = _bun_half(-1, P.BUNNY, P.CRUMB, seed=18, **k) + _bun_half(1, P.BUNNY, P.CRUMB, z=21, seed=19, **k)
        return _fold(P.BUNNY, x=8.8, r=5.6, top=-27), front
    if name == "none":
        return [], []
    raise KeyError(name)


def _flour(seed):
    rng = random.Random(seed)
    parts = []
    for side in (-1, 1):
        for _ in range(7):
            x = side * rng.uniform(8.5, 12.5)
            y = rng.uniform(-24, -3)
            parts.append(pix.Part(pix.ball(x, y, 0.6), P.FLOUR, z=22, line=False, seam=False, outline=False, flat=True))
    return parts


BUNS = ["soft", "poppy", "sesame", "crusty", "baguette", "white", "tube", "flat", "bolillo", "floury", "farl",
        "pretzel", "chocolate", "iced", "glitter", "cloud", "none"]


def _seeds(seed, ramp):
    rng = random.Random(seed)
    parts = []
    for side in (-1, 1):
        for _ in range(9):
            x = side * rng.uniform(9.0, 12.0)
            y = rng.uniform(-26, -4)
            parts.append(pix.Part(pix.ball(x, y, 0.55), ramp, z=22, line=False, seam=False, outline=False, flat=True))
    return parts


def bun_layers(name):
    return _bun(name)


# -- toppings -------------------------------------------------------------------
# Worn on the chest like a vest, or heaped on top of the head like hair.

def _zigzag(y0, y1, w, n, r, ramp, z, x0=0.0):
    pts = []
    for i in range(n + 1):
        t = i / n
        pts.append((x0 + (w if i % 2 else -w), y0 + (y1 - y0) * t))
    return pix.Part(pix.tube(pts, r), ramp, z=z, line=True, shine=0.8)


def _dots(seed, n, region, r, ramp, z, flat=False):
    rng = random.Random(seed)
    x0, y0, x1, y1 = region
    out = []
    for i in range(n):
        x, y = rng.uniform(x0, x1), rng.uniform(y0, y1)
        out.append(pix.Part(pix.ball(x, y, r * rng.uniform(0.85, 1.15)), ramp, z=z + i * 0.001, line=True, flat=flat))
    return out


CHEST = (-3.0, -24.5, 3.0, -9.0)


def topping_layer(name):
    z = 30
    if name == "mustard":
        return [_zigzag(-25, -9, 2.7, 5, 1.1, P.MUSTARD, z)]
    if name == "ketchup":
        return [_zigzag(-24, -8, 2.7, 5, 1.1, P.KETCHUP, z)]
    if name == "brown_sauce":
        return [_zigzag(-24.5, -9, 2.6, 4, 1.05, P.BROWN_SAUCE, z)]
    if name == "brown_mustard":
        return [_zigzag(-24.5, -9, 2.6, 4, 1.05, P.BROWN_MUSTARD, z)]
    if name == "relish":
        return _dots(2, 9, CHEST, 1.15, P.RELISH, z + 1)
    if name == "pickle":
        return [pix.Part(pix.sausage((-10.6, -4.5), (-9.8, -31), 2.0), P.PICKLE, z=z + 2, shine=0.6)]
    if name == "tomato":
        return [pix.Part(pix.ball(10.8, -22, 2.7, 2.1), P.TOMATO, z=z + 2, shine=0.8),
                pix.Part(pix.ball(10.6, -14.5, 2.7, 2.1), P.TOMATO, z=z + 2.1, shine=0.8)]
    if name == "crispy_onion":
        return _dots(9, 15, CHEST, 0.95, P.CRISPY_ONION, z + 1)
    if name == "onion":
        return _dots(4, 8, CHEST, 1.05, P.ONION, z + 1)
    if name == "remoulade":
        return [_zigzag(-23.5, -10, 2.4, 4, 1.05, P.REMOULADE, z)]
    if name == "avocado":       # a heap on the head, like a hairdo
        heap = pix.bumps(pix.ball(0, -44.5, 8.6, 4.0), 21, scale=1.3, amount=0.35)
        return [pix.Part(heap, P.AVOCADO, z=z + 3)]
    if name == "mayo":
        return [_zigzag(-24.5, -10, 2.5, 6, 0.9, P.MAYO, z + 0.5)]
    if name == "cheese":        # melted over the shoulders
        drip = pix.poly([(-7.4, -29), (7.4, -29), (7.4, -23), (5, -20), (3.4, -23.5), (0.6, -18), (-1.6, -22.5),
                         (-4.4, -19.5), (-7.4, -23.5)])
        return [pix.Part(drip, P.CHEESE, z=z)]
    if name == "potato_sticks":  # a crunchy crown
        rng = random.Random(8)
        parts = []
        for i in range(12):
            x = rng.uniform(-6.0, 6.0)
            a = rng.uniform(-0.9, 0.9)
            ln = rng.uniform(2.6, 4.8)
            y = -43.4 + abs(x) * 0.3
            parts.append(pix.Part(pix.tube([(x, y), (x + math.sin(a) * ln, y - math.cos(a) * ln)], 0.65),
                                  P.POTATO_STICKS, z=z + 3 + i * 0.01))
        return parts
    if name == "corn_peas":
        return _dots(3, 6, CHEST, 1.15, P.CORN, z + 1) + _dots(13, 5, CHEST, 1.15, P.PEAS, z + 1.1)
    if name == "jalapeno":
        return [pix.Part(pix.ball(-1.6, -20, 1.8, 1.5), P.JALAPENO, z=z + 1, shine=0.5),
                pix.Part(pix.ball(1.8, -14.5, 1.8, 1.5), P.JALAPENO, z=z + 1.1, shine=0.5)]
    if name == "beans":
        return _dots(6, 7, (-3, -12, 3, -6), 1.05, P.BEANS, z + 1)
    if name == "potato_cubes":  # corn dog: cubes of potato fried into the batter
        rng = random.Random(14)
        parts = []
        for i in range(11):
            x, y = rng.uniform(-6.5, 6.5), rng.uniform(-28, -12)
            parts.append(pix.Part(pix.slab(x - 1.4, y - 1.4, x + 1.4, y + 1.4, bevel=0.8), P.POTATO_STICKS,
                                  z=z + i * 0.01))
        return parts
    if name == "nori":
        return [pix.Part(pix.slab(-7.4, -23, 7.4, -19.5, bevel=0.5), P.NORI, z=z)]
    if name == "sauerkraut":
        rng = random.Random(23)
        parts = []
        for i in range(9):
            x, y = rng.uniform(-3, 3), rng.uniform(-24, -10)
            parts.append(pix.Part(pix.tube([(x - 1.6, y), (x, y - 0.8), (x + 1.6, y)], 0.5), P.REMOULADE, z=z + i * 0.01))
        return parts
    if name == "leek":          # worn on the head, as on St David's Day
        stalk = pix.tube([(0.6, -41.5), (1.6, -50.5)], 2.3)
        leaves = [pix.Part(pix.tube([(1.6, -49.5), (-1.4, -55.5), (-4.6, -59.5)], 1.5), P.LEEK_GREEN, z=z + 3.1),
                  pix.Part(pix.tube([(1.8, -49.5), (4.4, -56), (7.6, -58.5)], 1.5), P.LEEK_GREEN, z=z + 3.2),
                  pix.Part(pix.tube([(1.7, -50), (1.9, -57), (0.8, -62.5)], 1.4), P.LEEK_GREEN, z=z + 3.3)]
        return [pix.Part(stalk, P.LEEK_WHITE, z=z + 3, shine=0.5)] + leaves
    if name == "egg":           # a fried egg, worn like a badge
        white = pix.bumps(pix.ball(0.2, -16.5, 6.6, 5.0), 27, scale=1.0, amount=0.25)
        return [pix.Part(white, P.EGG_WHITE, z=z + 2, bands=[0.3, 0.7]),
                pix.Part(pix.ball(0.8, -17.4, 2.5, 2.3), P.YOLK, z=z + 2.5, shine=1.0)]
    if name == "none":
        return []
    raise KeyError(name)


TOPPINGS = ["mustard", "ketchup", "brown_sauce", "brown_mustard", "relish", "pickle", "tomato", "crispy_onion",
            "onion", "remoulade", "avocado", "mayo", "cheese", "potato_sticks", "corn_peas", "jalapeno", "beans",
            "potato_cubes", "nori", "sauerkraut", "leek", "egg"]


# -- the 80s sweatband ----------------------------------------------------------
# Painted in key colours: the game swaps them for the team's (ui/swap.gdshader).

def band_layer(sausage="frank"):
    shape = _sausage_shape({"corn": "corn", "lorne": "square"}.get(sausage, "frank"))
    y0, y1 = -42.0, -38.0
    if sausage == "corn":
        y0, y1 = -41.6, -37.6
    band = pix.bumps(pix.clip(shape, pix.slab(-12, y0, 12, y1)), 31, scale=3.2, amount=0.18)
    stripe = pix.clip(shape, pix.slab(-12, y0 + 1.5, 12, y0 + 2.5))
    return [pix.Part(band, P.BAND_KEY_MAIN, z=40, bands=[0.2, 0.6]),
            pix.Part(stripe, P.BAND_KEY_STRIPE, z=40.5, bands=[0.2, 0.6], line=False, seam=False, outline=False)]


# -- frames -----------------------------------------------------------------------
CELL = (52, 72)                                    # every frame's cell
FOOT = (26, 66)                                    # where the local origin sits, upright frames
SPIN_PIVOT = (0.0, -22.0)                          # spinning frames turn about the middle

SQUASH = [0.68, 0.78, 0.88, 1.0, 1.1, 1.2, 1.3]    # height factors; width follows to keep volume
LEAN = 14.0                                         # degrees forward at full tilt
SPIN = 24                                           # spin frames round a full turn


def frame_specs():
    """Every frame the game uses, in sheet order: (name, Xf)."""
    specs = []
    for i, s in enumerate(SQUASH):
        specs.append((f"sq{i}", pix.Xf(at=FOOT, sx=1.0 / math.sqrt(s), sy=s)))
    for i, s in enumerate(SQUASH):
        specs.append((f"lean{i}", pix.Xf(at=FOOT, sx=1.0 / math.sqrt(s), sy=s, rot=LEAN)))
    at = (CELL[0] / 2 - SPIN_PIVOT[0], CELL[1] / 2 - SPIN_PIVOT[1])
    for i in range(SPIN):
        specs.append((f"spin{i}", pix.Xf(at=at, rot=i * 360.0 / SPIN, pivot=SPIN_PIVOT)))
    return specs


def paint_layer(parts, xf, outline=True):
    c = pix.Canvas(*CELL)
    for p in parts:
        c.paint(p, xf)
    return c.finish(outline=outline)


def anchors_for(xf):
    out = {}
    for k, p in ANCHORS.items():
        q = xf.fwd(p)
        out[k] = [round(float(q[0]), 2), round(float(q[1]), 2)]
    return out
