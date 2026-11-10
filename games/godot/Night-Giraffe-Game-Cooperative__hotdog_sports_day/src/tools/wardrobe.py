"""The wardrobe: silly hats, outfits, sausage and bun styles, all unlocked by
playing (data/wardrobe.json says which unlocks what).

Each is painted as its own layer sheet, the same 38 frames as the body (so it
squashes, leans and spins with the hot dog): a hat on the head, an outfit on
the chest (with a back part, like a cape, painted behind everything). Body
coordinates, as in dogs.py: the head's top is at y=-44, the sausage is 7.5
wide either side of x=0, the bun's top is at -28, and the face looks right.
"""
import math
import random

import numpy as np

import palette as P
import pix

Z_HAT = 45
Z_FRONT = 35
Z_BACK = 1
HEAD = -44.0


def _P(shape, ramp, z, **k):
    return pix.Part(shape, ramp, z=z, **k)


def _stripes(shape, ramps, width, z, angle=0.0, start=-80.0):
    """A shape cut into stripes of the given ramps (bands across it)."""
    parts = []
    n = int(160 / width)
    # only the stripes that touch the shape (each part costs a pass per frame)
    Y, X = np.mgrid[-90:30:0.5, -45:45:0.5]
    ys = Y[shape(X, Y)[0]]
    lo, hi = (ys.min() - abs(angle) - width, ys.max() + abs(angle) + width) if ys.size else (0, -1)
    for i in range(n):
        y0 = start + i * width
        if y0 + width < lo or y0 > hi:
            continue
        band = pix.poly([(-40, y0), (40, y0 + angle), (40, y0 + angle + width), (-40, y0 + width)])
        parts.append(_P(pix.clip(shape, band), ramps[i % len(ramps)], z + 0.01 * i, line=False, seam=False))
    return parts


def _dome(rx=8.4, ry=6.5, base=-41.0):
    """The top half of a ball sitting on the head."""
    return pix.clip(pix.ball(0.0, base, rx, ry), pix.slab(-20, base - ry - 2, 20, base, bevel=0.1))


# -- hats ---------------------------------------------------------------------------

def hat_cap():
    dome = _dome(8.2, 5.6, -41.0)
    peak = pix.poly([(3.0, -42.6), (13.0, -41.8), (13.0, -40.4), (3.0, -40.6)])
    return [_P(dome, P.CAP_BLUE, Z_HAT, shine=0.6),
            _P(peak, P.CAP_BLUE[:3], Z_HAT + 0.5),
            _P(pix.ball(0.0, -46.4, 1.0), P.CAP_BLUE[1:], Z_HAT + 0.6, line=False)]


def hat_party():
    cone = pix.poly([(-6.0, -41.5), (6.0, -41.5), (0.5, -60.0)])
    parts = _stripes(cone, [P.PARTY_PINK, P.PARTY_YELLOW], 3.4, Z_HAT, angle=-1.5)
    parts.append(_P(pix.ball(0.5, -60.5, 2.2), P.PARTY_YELLOW, Z_HAT + 1, shine=0.4))
    return parts


def hat_bobble():
    dome = _dome(8.6, 7.0, -40.5)
    parts = _stripes(dome, [P.KNIT_RED, P.KNIT_WHITE], 2.4, Z_HAT)
    parts.append(_P(pix.slab(-8.8, -43.2, 8.8, -40.0, bevel=0.8), P.KNIT_WHITE, Z_HAT + 0.8))
    parts.append(_P(pix.bumps(pix.ball(0.0, -50.5, 3.0), 3, scale=2.0, amount=0.4), P.KNIT_WHITE, Z_HAT + 1))
    return parts


def hat_chef():
    body = pix.slab(-6.0, -54.0, 6.0, -41.0, bevel=1.0)
    puff = pix.bumps(pix.ball(0.0, -56.5, 8.0, 5.0), 5, scale=1.4, amount=0.4)
    return [_P(body, P.CHEF_WHITE, Z_HAT), _P(puff, P.CHEF_WHITE, Z_HAT + 0.5),
            _P(pix.slab(-6.2, -44.0, 6.2, -41.0, bevel=0.6), P.CHEF_WHITE[1:], Z_HAT + 0.7)]


def hat_cowboy():
    crown = pix.slab(-5.6, -53.0, 5.6, -42.0, bevel=1.4, round_=2.4)
    dent = pix.ball(0.0, -53.6, 2.6, 1.6)
    brim = pix.ball(0.5, -42.4, 14.5, 2.4)
    return [_P(brim, P.COWBOY, Z_HAT), _P(pix.cut(crown, dent), P.COWBOY, Z_HAT + 0.5),
            _P(pix.slab(-5.7, -45.0, 5.7, -43.2, bevel=0.4), P.KNIT_RED[:3], Z_HAT + 0.7, line=False)]


def hat_crown():
    band = pix.slab(-7.4, -47.0, 7.4, -41.5, bevel=0.8)
    spikes = [pix.poly([(x - 2.6, -46.5), (x + 2.6, -46.5), (x, -53.5 + abs(x) * 0.25)]) for x in (-4.8, 0.0, 4.8)]
    parts = [_P(band, P.GOLD, Z_HAT, shine=0.8)]
    for i, s in enumerate(spikes):
        parts.append(_P(s, P.GOLD, Z_HAT + 0.2 + i * 0.01))
        parts.append(_P(pix.ball([-4.8, 0.0, 4.8][i], -52.8 + abs([-4.8, 0.0, 4.8][i]) * 0.25, 1.1), P.GOLD[2:],
                        Z_HAT + 0.4, line=False))
    for x, ramp in ((-3.8, P.JEWEL_RED), (0.0, P.JEWEL_BLUE), (3.8, P.JEWEL_GREEN)):
        parts.append(_P(pix.ball(x, -44.2, 1.3), ramp, Z_HAT + 0.6, shine=1.0))
    return parts


def hat_top():
    tube = pix.slab(-5.8, -63.0, 5.8, -43.0, bevel=1.2)
    brim = pix.ball(0.3, -43.0, 10.5, 1.8)
    return [_P(brim, P.TOP_BLACK, Z_HAT), _P(tube, P.TOP_BLACK, Z_HAT + 0.5, shine=0.3),
            _P(pix.slab(-5.9, -48.5, 5.9, -45.5, bevel=0.4), P.KNIT_RED, Z_HAT + 0.7, line=False)]


def hat_viking():
    dome = _dome(8.8, 7.6, -40.5)
    horns = [pix.tube([(-7.6, -44.0), (-11.5, -48.0), (-12.0, -54.0)], 1.7),
             pix.tube([(7.6, -44.0), (11.5, -48.0), (12.0, -54.0)], 1.7)]
    parts = [_P(dome, P.STEEL, Z_HAT, shine=0.9),
             _P(pix.slab(-9.0, -43.0, 9.0, -40.5, bevel=0.6), P.COWBOY, Z_HAT + 0.3)]
    for i, h in enumerate(horns):
        parts.append(_P(h, P.HORN, Z_HAT - 0.5 + i * 0.01))
    for x in (-5.0, 0.0, 5.0):
        parts.append(_P(pix.ball(x, -41.8, 0.8), P.STEEL[2:], Z_HAT + 0.5, line=False))
    return parts


def hat_wizard():
    cone = pix.poly([(-7.0, -42.0), (7.0, -42.0), (2.0, -55.0), (-5.0, -64.0), (-1.5, -54.0)])
    brim = pix.ball(0.0, -42.4, 11.5, 2.2)
    parts = [_P(brim, P.WIZARD, Z_HAT), _P(cone, P.WIZARD, Z_HAT + 0.5)]
    for x, y in ((-1.5, -49.0), (2.5, -45.5), (-0.5, -56.0)):
        parts.append(_P(pix.poly([(x, y - 1.6), (x + 0.6, y - 0.5), (x + 1.7, y), (x + 0.6, y + 0.5),
                                  (x, y + 1.6), (x - 0.6, y + 0.5), (x - 1.7, y), (x - 0.6, y - 0.5)]),
                        P.STAR, Z_HAT + 0.8, line=False, flat=True))
    return parts


def hat_propeller():
    dome = _dome(8.4, 6.6, -40.8)
    parts = _stripes(dome, [P.KNIT_RED, P.PARTY_YELLOW, P.CAP_BLUE], 2.0, Z_HAT, angle=0.0)
    parts.append(_P(pix.tube([(0.0, -47.0), (0.0, -50.5)], 0.7), P.STEEL, Z_HAT + 0.6))
    parts.append(_P(pix.ball(-3.6, -50.8, 3.6, 1.0), P.KNIT_RED, Z_HAT + 0.7))
    parts.append(_P(pix.ball(3.6, -50.8, 3.6, 1.0), P.CAP_BLUE, Z_HAT + 0.71))
    return parts


def hat_pirate():
    hat = pix.poly([(-11.0, -43.0), (-6.0, -47.5), (-3.0, -53.5), (3.5, -53.5), (6.5, -47.5), (11.5, -43.0),
                    (5.0, -45.0), (-4.5, -45.0)])
    parts = [_P(hat, P.TOP_BLACK, Z_HAT)]
    parts.append(_P(pix.ball(0.6, -49.5, 1.9, 1.7), P.CHEF_WHITE, Z_HAT + 0.5, line=False))
    parts.append(_P(pix.tube([(-1.8, -46.4), (3.0, -46.4)], 0.5), P.CHEF_WHITE, Z_HAT + 0.6, line=False))
    parts.append(_P(pix.slab(-10.0, -44.4, 10.5, -43.4, bevel=0.2), P.GOLD[1:], Z_HAT + 0.4, line=False))
    return parts


def hat_fez():
    fez = pix.poly([(-5.8, -42.0), (5.8, -42.0), (4.4, -51.0), (-4.4, -51.0)])
    return [_P(fez, P.KNIT_RED, Z_HAT),
            _P(pix.tube([(0.0, -51.0), (4.5, -50.0), (5.5, -45.5)], 0.6), P.TOP_BLACK, Z_HAT + 0.5),
            _P(pix.ball(5.6, -45.0, 1.0, 1.4), P.PARTY_YELLOW, Z_HAT + 0.6, line=False)]


def hat_sombrero():
    brim = pix.ball(0.5, -42.6, 19.0, 3.6)
    crown = pix.poly([(-5.4, -43.5), (5.4, -43.5), (3.6, -54.5), (-3.6, -54.5)])
    parts = [_P(brim, P.STRAW, Z_HAT), _P(crown, P.STRAW, Z_HAT + 0.5),
             _P(pix.slab(-5.5, -46.0, 5.5, -44.0, bevel=0.3), P.KNIT_RED[:3], Z_HAT + 0.7, line=False)]
    for x in range(-16, 18, 4):
        parts.append(_P(pix.ball(x, -40.6, 0.8), P.JEWEL_GREEN, Z_HAT + 0.8, line=False))
    return parts


def hat_cone():
    cone = pix.poly([(-6.6, -42.0), (6.6, -42.0), (1.0, -61.0), (-1.0, -61.0)])
    parts = [_P(pix.slab(-9.0, -43.5, 9.0, -41.0, bevel=0.5), P.CONE_ORANGE, Z_HAT)]
    parts += _stripes(cone, [P.CONE_ORANGE, P.CONE_ORANGE, P.CHEF_WHITE], 2.6, Z_HAT + 0.3)
    return parts


def hat_bunny():
    ears = []
    for x, lean in ((-3.6, -1.6), (3.6, 1.2)):
        outer = pix.sausage((x, -42.0), (x + lean, -62.0), 2.8)
        inner = pix.sausage((x, -45.0), (x + lean, -60.5), 1.3)
        ears += [_P(outer, P.BUNNY, Z_HAT), _P(inner, P.BUNNY_PINK, Z_HAT + 0.2, line=False)]
    return ears


def hat_unicorn():
    horn = pix.poly([(-2.6, -42.5), (2.6, -42.5), (0.6, -60.0)])
    parts = _stripes(horn, [P.UNICORN, P.GOLD], 2.2, Z_HAT + 0.4, angle=-1.6)
    for x in (-6.2, 6.2):
        parts.append(_P(pix.poly([(x - 2.2, -42.0), (x + 2.2, -42.0), (x * 1.08, -48.0)]), P.UNICORN, Z_HAT))
    parts.append(_P(pix.bumps(pix.ball(-3.0, -43.5, 4.5, 2.2), 9, amount=0.5), P.PARTY_PINK, Z_HAT + 0.3))
    return parts


def hat_antlers():
    parts = []
    for side in (-1, 1):
        main = [(side * 3.5, -43.0), (side * 7.5, -50.0), (side * 9.0, -58.0)]
        parts.append(_P(pix.tube(main, 1.2), P.ANTLER, Z_HAT))
        for (a, b) in (((side * 6.4, -48.0), (side * 11.5, -52.0)), ((side * 8.4, -54.5), (side * 5.0, -59.5))):
            parts.append(_P(pix.tube([a, b], 0.9), P.ANTLER, Z_HAT + 0.1))
    return parts


def hat_halo():
    ring = pix.cut(pix.ball(0.0, -52.0, 8.5, 2.6), pix.ball(0.0, -52.0, 6.3, 1.3))
    return [_P(ring, P.GOLD, Z_HAT, shine=1.0)]


def hat_flowers():
    parts = [_P(pix.slab(-8.0, -43.5, 8.0, -41.5, bevel=0.5), P.LEEK_GREEN, Z_HAT)]
    ramps = [P.PETAL_PINK, P.PETAL_YELLOW, P.PETAL_BLUE, P.PETAL_WHITE]
    for i, x in enumerate((-7.0, -3.6, 0.0, 3.6, 7.0)):
        y = -43.5 - (2.0 if i % 2 else 0.6)
        parts.append(_P(pix.bumps(pix.ball(x, y, 2.4), 30 + i, scale=2.0, amount=0.5), ramps[i % 4], Z_HAT + 0.2 + i * 0.01))
        parts.append(_P(pix.ball(x, y, 0.8), P.PETAL_YELLOW[1:], Z_HAT + 0.4, line=False))
    return parts


def hat_shark():
    fin = pix.poly([(-5.0, -42.0), (5.0, -42.0), (-1.0, -56.0), (-3.4, -54.0)])
    return [_P(fin, P.SHARK, Z_HAT, shine=0.4),
            _P(pix.poly([(-4.0, -42.0), (4.0, -42.0), (0.0, -46.0)]), P.SHARK[1:], Z_HAT + 0.3, line=False)]


def hat_hotdog():
    """A tiny hot dog, worn as a hat. It has its own tiny hat... no, it doesn't."""
    bun_l = pix.sausage((-6.0, -45.5), (6.0, -45.5), 2.4)
    sausage = pix.sausage((-7.6, -47.6), (7.6, -47.6), 1.7)
    bun_f = pix.clip(pix.sausage((-6.0, -46.0), (6.0, -46.0), 2.4), pix.slab(-9, -47.0, 9, -40, bevel=0.1))
    return [_P(bun_l, P.BUN, Z_HAT), _P(sausage, P.FRANK, Z_HAT + 0.3, shine=0.8),
            _P(bun_f, P.BUN, Z_HAT + 0.5),
            _P(pix.tube([(-5.0, -48.6), (-2.5, -47.4), (0.0, -48.6), (2.5, -47.4), (5.0, -48.6)], 0.45), P.MUSTARD,
               Z_HAT + 0.7, line=False)]


def hat_headphones():
    band = pix.clip(pix.cut(pix.ball(0.0, -38.0, 9.6, 10.0), pix.ball(0.0, -38.0, 8.2, 8.6)),
                    pix.slab(-12, -50, 12, -37, bevel=0.1))
    return [_P(band, P.TOP_BLACK, Z_HAT, shine=0.4),
            _P(pix.slab(-11.2, -40.0, -7.2, -31.0, bevel=1.0, round_=1.5), P.KNIT_RED, Z_HAT + 0.5, shine=0.6),
            _P(pix.slab(7.4, -40.0, 11.4, -31.0, bevel=1.0, round_=1.5), P.KNIT_RED, Z_HAT + 0.6, shine=0.6)]


HATS = {
    "cap": hat_cap, "party": hat_party, "bobble": hat_bobble, "chef": hat_chef, "cowboy": hat_cowboy,
    "crown": hat_crown, "tophat": hat_top, "viking": hat_viking, "wizard": hat_wizard, "propeller": hat_propeller,
    "pirate": hat_pirate, "fez": hat_fez, "sombrero": hat_sombrero, "cone": hat_cone, "bunny": hat_bunny,
    "unicorn": hat_unicorn, "antlers": hat_antlers, "halo": hat_halo, "flowers": hat_flowers, "shark": hat_shark,
    "hotdog": hat_hotdog, "headphones": hat_headphones,
}

## Hats that leave the hair showing (they don't cover the top of the head).
HAIR_SHOWS = ["halo", "bunny", "antlers", "flowers", "unicorn", "headphones"]


# -- outfits: (behind, in front) ------------------------------------------------------

def out_bowtie():
    l = pix.poly([(-5.0, -26.2), (0.0, -24.2), (-5.0, -22.0)])
    r = pix.poly([(5.6, -26.2), (0.6, -24.2), (5.6, -22.0)])
    return [], [_P(l, P.KNIT_RED, Z_FRONT), _P(r, P.KNIT_RED, Z_FRONT + 0.1),
                _P(pix.ball(0.3, -24.1, 1.4), P.KNIT_RED[1:], Z_FRONT + 0.2)]


def out_scarf():
    wrap = pix.slab(-9.2, -26.0, 9.2, -22.0, bevel=1.2, round_=1.5)
    tail = pix.poly([(-3.0, -23.0), (0.5, -23.0), (-0.5, -10.5), (-4.5, -11.0)])
    parts = _stripes(wrap, [P.KNIT_RED, P.KNIT_WHITE], 1.6, Z_FRONT, angle=0.0, start=-30)
    parts += _stripes(tail, [P.KNIT_RED, P.KNIT_WHITE], 2.0, Z_FRONT + 0.5, angle=0.0, start=-30)
    return [], parts


def out_medal():
    rib = [pix.tube([(-4.5, -28.0), (-0.8, -17.0)], 1.2), pix.tube([(5.0, -28.0), (1.4, -17.0)], 1.2)]
    return [], [_P(rib[0], P.CAP_BLUE, Z_FRONT), _P(rib[1], P.KNIT_RED, Z_FRONT + 0.05),
                _P(pix.ball(0.3, -14.5, 3.3), P.GOLD, Z_FRONT + 0.2, shine=1.0)]


def out_cape(ramp):
    # it flows out behind (the hot dog faces right)
    back = pix.poly([(-7.0, -31.0), (5.0, -31.0), (0.0, -2.0), (-9.0, 0.0), (-15.0, -2.5), (-21.0, -1.0), (-19.0, -12.0)])
    collar = pix.slab(-8.4, -30.5, 8.4, -27.0, bevel=0.8)
    return [_P(back, ramp, Z_BACK)], [_P(collar, ramp, Z_FRONT), _P(pix.ball(0.4, -27.4, 1.6), P.GOLD, Z_FRONT + 0.2,
                                                                   shine=1.0)]


def out_redcape():
    return out_cape(P.CAPE_RED)


def out_cloak():
    back, front = out_cape(P.WIZARD)
    stars = []
    rng = random.Random(4)
    for i in range(6):
        x, y = rng.uniform(-12, 12), rng.uniform(-24, -4)
        stars.append(_P(pix.ball(x, y, 0.8), P.STAR, Z_BACK + 0.1, line=False, outline=False))
    return back + stars, front


def _round_waist(ring, y):
    """A ring round the waist: its far half behind the hot dog, its near half in front."""
    return (pix.clip(ring, pix.slab(-30, y - 20, 30, y, bevel=0.1)),
            pix.clip(ring, pix.slab(-30, y, 30, y + 20, bevel=0.1)))


def out_tutu():
    frill = pix.bumps(pix.cut(pix.ball(0.0, -9.0, 16.0, 5.2), pix.ball(0.0, -9.5, 9.5, 2.4)), 12, scale=2.2,
                      amount=0.6)
    back, front = _round_waist(frill, -9.5)
    return [_P(back, P.TUTU_PINK, Z_BACK)], [_P(front, P.TUTU_PINK, Z_FRONT, bands=[0.2, 0.5, 0.8])]


def out_swimring():
    ring = pix.cut(pix.ball(0.0, -14.0, 16.5, 7.5), pix.ball(0.0, -15.5, 9.5, 2.2))
    back, front = _round_waist(ring, -15.5)
    return (_stripes(back, [P.KNIT_RED, P.KNIT_WHITE], 3.0, Z_BACK, angle=6.0, start=-40),
            _stripes(front, [P.KNIT_RED, P.KNIT_WHITE], 3.0, Z_FRONT, angle=6.0, start=-40))


def out_lei():
    parts = []
    ramps = [P.PETAL_PINK, P.PETAL_YELLOW, P.PETAL_BLUE, P.PETAL_WHITE, P.PETAL_PINK]
    for i in range(9):
        a = math.pi * (0.1 + 0.8 * i / 8)
        x = math.cos(a) * 8.5
        y = -27.5 + math.sin(a) * 6.0
        parts.append(_P(pix.bumps(pix.ball(x, y, 1.9), 40 + i, scale=2.2, amount=0.5), ramps[i % 5], Z_FRONT + 0.01 * i))
    return [], parts


def out_bandana():
    tri = pix.poly([(-7.8, -27.0), (8.2, -27.0), (0.3, -17.5)])
    parts = [_P(tri, P.KNIT_RED, Z_FRONT)]
    for x, y in ((-3.5, -24.5), (3.0, -24.5), (0.0, -21.5), (-1.0, -25.6), (5.0, -25.8)):
        parts.append(_P(pix.ball(x, y, 0.7), P.CHEF_WHITE, Z_FRONT + 0.2, line=False, outline=False))
    return [], parts


def out_bib():
    bib = pix.slab(-5.5, -26.5, 5.5, -11.0, bevel=1.0, round_=3.0)
    splat = pix.bumps(pix.ball(1.2, -17.0, 2.6, 2.2), 7, scale=2.4, amount=0.8)
    return [], [_P(bib, P.CHEF_WHITE, Z_FRONT), _P(splat, P.KETCHUP, Z_FRONT + 0.2),
                _P(pix.ball(-2.0, -21.5, 0.9), P.KETCHUP, Z_FRONT + 0.3, line=False)]


def out_sash():
    sash = pix.poly([(-8.0, -27.5), (-4.0, -27.5), (8.0, -10.5), (4.0, -10.5)])
    return [], _stripes(sash, [P.GOLD, P.KNIT_RED, P.GOLD], 1.4, Z_FRONT, angle=14.0, start=-40)


def out_wings():
    parts = []
    for side, z in ((-1, Z_BACK), (1, Z_BACK + 0.1)):
        wing = pix.poly([(side * 5.0, -30.0), (side * 17.0, -38.0), (side * 19.0, -28.0), (side * 15.0, -20.0),
                         (side * 6.0, -18.0)])
        parts.append(_P(wing, P.PETAL_WHITE, z, bands=[0.3, 0.6, 0.9]))
    return parts, []


OUTFITS = {
    "bowtie": out_bowtie, "scarf": out_scarf, "medal": out_medal, "cape": out_redcape, "cloak": out_cloak,
    "tutu": out_tutu, "swimring": out_swimring, "lei": out_lei, "bandana": out_bandana, "bib": out_bib,
    "sash": out_sash, "wings": out_wings,
}


# -- frames: the body's 38, on a bigger cell (a tall hat, a sombrero's brim) ----------
# The body cell (dogs.CELL) sits at OFFSET inside the wardrobe's cell, so the
# game draws a wardrobe frame OFFSET up and left of the body's.
CELL = (88, 104)
OFFSET = (18, 32)


def frame_specs():
    import dogs
    out = []
    for name, xf in dogs.frame_specs():
        at = (xf.at[0] + OFFSET[0], xf.at[1] + OFFSET[1])
        out.append((name, pix.Xf(at=at, sx=xf.sx, sy=xf.sy, rot=math.degrees(xf.rot), pivot=tuple(xf.pivot))))
    return out


def paint_layer(parts, xf):
    c = pix.Canvas(*CELL)
    for p in parts:
        c.paint(p, xf)
    return c.finish()
