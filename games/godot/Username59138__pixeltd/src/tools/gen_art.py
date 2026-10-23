#!/usr/bin/env python3
"""Generates every PNG asset of Pixel TD plus scripts/data/maps_data.gd."""
import os, random, math
from PIL import Image
from sprites import *
import units as U

ROOT = os.path.join(os.path.dirname(__file__), '..')
A = os.path.join(ROOT, 'assets')
T = 16


def out(path):
    p = os.path.join(A, path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    return p


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def shade(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c)


# ------------------------------------------------------------------ sprites
def flash(img):
    """White silhouette used for the hit flash."""
    w = img.copy()
    px = w.load()
    for y in range(w.height):
        for x in range(w.width):
            if px[x, y][3]:
                px[x, y] = (255, 255, 255, 255)
    return w


def gen_sprites():
    for name, rows, cm in [('gunner', GUNNER, GUNNER_C), ('gunner_elite', GUNNER, GUNNER_ELITE),
                           ('knight', KNIGHT, KNIGHT_C), ('knight_elite', KNIGHT, KNIGHT_ELITE),
                           ('flamer', FLAMER, FLAMER_C), ('flamer_elite', FLAMER, FLAMER_ELITE),
                           ('soldier', SOLDIER, SOLDIER_C), ('soldier_elite', SOLDIER, SOLDIER_ELITE),
                           ('garage', GARAGE, GARAGE_C), ('garage_elite', GARAGE, GARAGE_ELITE),
                           ('sniper', SNIPER, SNIPER_C), ('sniper_elite', SNIPER, SNIPER_ELITE),
                           ('necro', NECRO, NECRO_C), ('necro_elite', NECRO, NECRO_ELITE),
                           ('freezer', FREEZER, FREEZER_C), ('freezer_elite', FREEZER, FREEZER_ELITE),
                           ('toxic', TOXIC, TOXIC_C), ('toxic_elite', TOXIC, TOXIC_ELITE),
                           ('assassin', ASSASSIN, ASSASSIN_C), ('assassin_elite', ASSASSIN, ASSASSIN_ELITE),
                           ('farm', FARM, FARM_C), ('farm_elite', FARM, FARM_ELITE),
                           ('minigun', MINIGUN, MINIGUN_C), ('minigun_elite', MINIGUN, MINIGUN_ELITE)]:
        make(rows, cm).save(out(f'sprites/towers/{name}.png'))
    # enemies and friendly vehicles: side view (name.png), front (name_down.png), back (name_up.png)
    for name, u in U.UNITS.items():
        folder = 'vehicles' if name in ('car', 'pickup', 'truck', 'armored') else 'enemies'
        for view, suffix in (('side', ''), ('down', '_down'), ('up', '_up')):
            img = U.render(u[view], u['colors'])
            img.save(out(f'sprites/{folder}/{name}{suffix}.png'))
            flash(img).save(out(f'sprites/{folder}/{name}{suffix}_flash.png'))
            if folder == 'enemies':   # Lead enemies are cast in lead (Bloated ones look like any other)
                img = U.render(u[view], U.lead_colors(u['colors']))
                img.save(out(f'sprites/enemies/{name}_lead{suffix}.png'))
                flash(img).save(out(f'sprites/enemies/{name}_lead{suffix}_flash.png'))
            if folder == 'vehicles' and view == 'side':
                img.save(out(f'ui/upgrades/{name}.png'))
    for name, (rows, cm) in ICONS.items():
        make(rows, cm).save(out(f'ui/icons/{name}.png'))
    for name, (rows, cm) in UP_ICONS.items():
        make(rows, cm).save(out(f'ui/upgrades/{name}.png'))
    for name, rows in [('arrow', CURSOR_ARROW), ('hand', CURSOR_HAND), ('cross', CURSOR_CROSS)]:
        make(rows, CURSOR_C).save(out(f'ui/cursor_{name}.png'))


# ------------------------------------------------------------------ UI
def bevel_box(w, h, base, border=C['black'], light=None, dark=None, pressed=False):
    light = light or shade(base, 1.25)
    dark = dark or shade(base, 0.7)
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    px = img.load()
    for y in range(h):
        for x in range(w):
            corner = (x in (0, w - 1)) and (y in (0, h - 1))
            if corner:
                continue
            if x == 0 or y == 0 or x == w - 1 or y == h - 1:
                px[x, y] = border + (255,)
                continue
            c = base
            if pressed:
                if y == 1:
                    c = dark
                elif y == h - 2:
                    c = base
            else:
                if y == 1 or (x == 1 and y < h - 3):
                    c = light
                elif y >= h - 3:
                    c = dark
            px[x, y] = c + (255,)
    return img


def gen_ui():
    variants = {
        'green': C['green'], 'blue': C['dblue'], 'red': C['dred'], 'gold': C['lorange'],
        'gray': C['xdgray'], 'purple': C['purple'],
    }
    for name, base in variants.items():
        bevel_box(16, 16, base).save(out(f'ui/btn_{name}.png'))
        bevel_box(16, 16, shade(base, 1.2), light=shade(base, 1.5)).save(out(f'ui/btn_{name}_hover.png'))
        bevel_box(16, 16, shade(base, 0.9), pressed=True).save(out(f'ui/btn_{name}_pressed.png'))
    bevel_box(16, 16, (60, 60, 72), light=(75, 75, 88), dark=(48, 48, 58)).save(out('ui/btn_disabled.png'))
    # panels
    p = bevel_box(16, 16, C['navy'], light=C['xdgray'], dark=(30, 33, 54))
    p.save(out('ui/panel.png'))
    p = bevel_box(16, 16, (30, 26, 46), border=C['black'], light=C['navy'], dark=(22, 19, 34))
    p.save(out('ui/panel_dark.png'))
    # parchment card
    bevel_box(16, 16, (58, 68, 102), light=C['dgray'], dark=C['navy']).save(out('ui/card.png'))
    bevel_box(16, 16, (78, 90, 130), light=C['gray'], dark=C['xdgray']).save(out('ui/card_hover.png'))
    bevel_box(16, 16, C['dgreen'], light=C['green'], dark=C['xdgreen']).save(out('ui/card_selected.png'))
    gen_scrollbar()
    gen_logo()


def gen_scrollbar():
    """7 px wide scrollbar for the battle shop: inset groove, ridged blue grabber, tiny arrow buttons."""
    W = 7
    # groove: an inverted bevel so it looks pressed into the panel
    bevel_box(W, 8, (30, 26, 46), light=(22, 19, 34), dark=C['navy']).save(out('ui/scroll_track.png'))
    # grabber: 3 px caps top and bottom, the 4 middle rows are tiled (one ridge every 4 px)
    for suffix, base, light, dark in (('', C['blu'], C['blu_l'], C['blu_d']),
                                      ('_hover', C['blu_l'], (120, 200, 245), C['blu']),
                                      ('_pressed', C['blu_d'], C['blu'], (12, 46, 90))):
        H = 10
        img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        px = img.load()
        for y in range(H):
            for x in range(W):
                if (x in (0, W - 1)) and (y in (0, H - 1)):
                    continue
                inner = 1 < x < W - 2
                if x in (0, W - 1) or y in (0, H - 1):
                    c = C['black']
                elif y == 1:
                    c = light
                elif y == H - 2:
                    c = dark
                elif y == 4 and inner:
                    c = light
                elif y == 5 and inner:
                    c = dark
                else:
                    c = base
                px[x, y] = c + (255,)
        img.save(out(f'ui/scroll_grab{suffix}.png'))
    # arrow buttons (Godot draws them at the ends of the bar)
    for name, up in (('scroll_up', True), ('scroll_down', False)):
        for suffix, base, light, arrow in (('', C['dblue'], C['blu'], C['lgray']),
                                           ('_hover', C['blu'], C['blu_l'], C['white']),
                                           ('_pressed', C['blu_d'], C['dblue'], C['gray'])):
            img = bevel_box(W, 7, base, light=light, dark=shade(base, 0.7))
            px = img.load()
            for i, (x0, x1) in enumerate(((3, 4), (2, 5)) if up else ((2, 5), (3, 4))):   # 1 then 3 px wide
                for x in range(x0, x1):
                    px[x, 2 + i] = arrow + (255,)
            img.save(out(f'ui/{name}{suffix}.png'))


FONT5 = {
    'P': ["1111", "1001", "1001", "1110", "1000", "1000", "1000"],
    'I': ["111", "010", "010", "010", "010", "010", "111"],
    'X': ["10001", "10001", "01010", "00100", "01010", "10001", "10001"],
    'E': ["1111", "1000", "1000", "1110", "1000", "1000", "1111"],
    'L': ["1000", "1000", "1000", "1000", "1000", "1000", "1111"],
    'T': ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
    'D': ["1110", "1001", "1001", "1001", "1001", "1001", "1110"],
    ' ': ["00", "00", "00", "00", "00", "00", "00"],
}
FONT3 = {  # tiny 3x5 sign font
    'G': ["111", "100", "101", "101", "111"], 'A': ["010", "101", "111", "101", "101"],
    'S': ["111", "100", "111", "001", "111"], 'O': ["111", "101", "101", "101", "111"],
    '&': ["010", "101", "010", "101", "011"], ' ': ["0", "0", "0", "0", "0"],
    'M': ["10001", "11011", "10101", "10001", "10001"], 'R': ["110", "101", "110", "101", "101"],
    'T': ["111", "010", "010", "010", "010"],
    'P': ["110", "101", "110", "100", "100"], 'E': ["111", "100", "110", "100", "111"],
    'N': ["1001", "1101", "1011", "1001", "1001"], 'C': ["111", "100", "100", "100", "111"],
    'W': ["10001", "10001", "10101", "11011", "10001"], 'H': ["101", "101", "111", "101", "101"],
    'Y': ["101", "101", "010", "010", "010"], 'I': ["1", "1", "1", "1", "1"],
    'L': ["100", "100", "100", "100", "111"], 'K': ["101", "101", "110", "101", "101"],
    '.': ["0", "0", "0", "0", "1"], '-': ["000", "000", "111", "000", "000"], '$': ["011", "110", "010", "011", "110"],
    '0': ["111", "101", "101", "101", "111"], '1': ["01", "11", "01", "01", "01"],
    '2': ["111", "001", "111", "100", "111"], '3': ["111", "001", "011", "001", "111"],
    '4': ["101", "101", "111", "001", "001"], '5': ["111", "100", "111", "001", "111"],
    '6': ["111", "100", "111", "101", "111"], '7': ["111", "001", "001", "010", "010"],
    '8': ["111", "101", "111", "101", "111"], '9': ["111", "101", "111", "001", "111"],
}


def text3_width(text, s=1):
    return sum((len(FONT3[ch][0]) + 1) * s for ch in text) - s


def draw_text3(img, x, y, text, col, s=1):
    px = img.load()
    for ch in text:
        g = FONT3[ch]
        for gy, row in enumerate(g):
            for gx, v in enumerate(row):
                if v == '1':
                    for sy in range(s):
                        for sx in range(s):
                            px[x + gx * s + sx, y + gy * s + sy] = col + (255,)
        x += (len(g[0]) + 1) * s


def gen_logo():
    text = "PIXEL TD"
    s = 4
    w = sum(len(FONT5[c][0]) + 1 for c in text) * s + 12
    h = 7 * s + 14
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    mask = Image.new('L', (w, h), 0)
    mp = mask.load()
    x = 6
    for ch in text:
        g = FONT5[ch]
        for gy, row in enumerate(g):
            for gx, v in enumerate(row):
                if v == '1':
                    for yy in range(s):
                        for xx in range(s):
                            mp[x + gx * s + xx, 5 + gy * s + yy] = 255
        x += (len(g[0]) + 1) * s
    px = img.load()
    # shadow (offset 3 down), outline, fill gradient
    for y in range(h):
        for x in range(w):
            def m(a, b):
                return 0 <= a < w and 0 <= b < h and mp[a, b]
            if m(x, y):
                t = (y - 5) / (7 * s)
                if t < 0.5:
                    col = lerp(C['yellow'], C['gold'], t * 2)
                else:
                    col = lerp(C['gold'], C['orange'], (t - 0.5) * 2)
                if (y - 5) % s == 0 and (y - 5) < s * 2:
                    col = lerp(col, C['white'], 0.4)
                px[x, y] = col + (255,)
    src = img.copy().load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3]:
                continue
            near = False
            for dx in range(-2, 3):
                for dy in range(-2, 3):
                    if abs(dx) + abs(dy) <= 2 and 0 <= x + dx < w and 0 <= y + dy < h and src[x + dx, y + dy][3]:
                        near = True
            if near:
                px[x, y] = C['black'] + (255,)
    src = img.copy().load()
    for y in range(h - 1, -1, -1):
        for x in range(w):
            if src[x, y][3] == 0:
                for d in (1, 2, 3):
                    if y - d >= 0 and src[x, y - d][3]:
                        px[x, y] = C['dred'] + (255,) if d < 3 else C['black'] + (255,)
                        break
    img.save(out('ui/logo.png'))


# ------------------------------------------------------------------ maps
def value_noise(w, h, cell, rnd):
    gw, gh = w // cell + 2, h // cell + 2
    g = [[rnd.random() for _ in range(gw)] for _ in range(gh)]
    res = [[0.0] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            fx, fy = x / cell, y / cell
            ix, iy = int(fx), int(fy)
            tx, ty = fx - ix, fy - iy
            tx = tx * tx * (3 - 2 * tx)
            ty = ty * ty * (3 - 2 * ty)
            a = g[iy][ix] + (g[iy][ix + 1] - g[iy][ix]) * tx
            b = g[iy + 1][ix] + (g[iy + 1][ix + 1] - g[iy + 1][ix]) * tx
            res[y][x] = a + (b - a) * ty
    return res


BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

THEMES = {
    'meadow': dict(ground=[(52, 120, 64), C['green'], (82, 160, 80)], path=[(196, 140, 92), C['tan'], (172, 116, 78)],
                   path_edge=C['dbrown'], ground_edge=C['dgreen'], speck=[C['lgreen'], C['dgreen']],
                   pebble=[C['brown'], C['sand']], details='flowers'),
    'desert': dict(ground=[(214, 176, 120), C['sand'], (226, 196, 140)], path=[C['lorange'], (200, 108, 66), C['brown']],
                   path_edge=C['dbrown'], ground_edge=C['tan'], speck=[C['tan'], C['white']],
                   pebble=[C['dbrown'], C['tan']], details='desert'),
    # gas station: grass by default, concrete / asphalt zones around the station (see ZONES)
    'gas': dict(ground=[(52, 116, 64), C['green'], (78, 156, 80)], path=[(44, 46, 68), (50, 52, 76), (56, 58, 82)],
                path_edge=C['black'], ground_edge=C['dgreen'], speck=[C['lgreen'], C['dgreen']],
                pebble=[(36, 38, 58), (66, 70, 94)], details='gas', path_style='asphalt',
                zones={'concrete': [(160, 168, 188), (172, 180, 198), (184, 192, 208)],
                       'asphalt': [(70, 76, 100), (78, 84, 108), (86, 92, 116)]},
                zone_edge={'grass': C['dgreen'], 'concrete': C['lgray'], 'asphalt': C['xdgray']},
                zone_speck={'concrete': [(150, 158, 178), (196, 204, 218)], 'asphalt': [(60, 66, 88), (98, 104, 128)]}),
    'swamp': dict(ground=[(40, 74, 52), (50, 88, 58), (62, 102, 62)], path=[(150, 104, 70), (132, 90, 62), (166, 118, 78)],
                  path_edge=C['xdbrown'], ground_edge=(28, 52, 40), speck=[(80, 128, 72), (30, 56, 42)],
                  pebble=[C['wd_d']], details='swamp', path_style='planks'),
    'grave': dict(ground=[(46, 62, 62), (56, 74, 70), (66, 86, 76)], path=[(90, 92, 110), (104, 106, 124), (120, 122, 140)],
                  path_edge=C['black'], ground_edge=(34, 44, 48), speck=[(84, 100, 92), (36, 48, 52)],
                  pebble=[(70, 72, 90)], details='grave', path_style='cobble'),
    # Halloween look of the meadow: same layout, autumn colours, pumpkins instead of bushes
    'meadow_halloween': dict(ground=[(150, 76, 44), (170, 94, 50), (190, 116, 60)],
                             path=[(112, 82, 70), (98, 70, 62), (86, 60, 54)],
                             path_edge=C['xdbrown'], ground_edge=(132, 60, 36), speck=[(240, 170, 90), (126, 54, 32)],
                             pebble=[(70, 50, 46), (150, 120, 100)], details='flowers',
                             tuft=((230, 160, 80), (116, 52, 34)),
                             flowers=[C['red_m'], C['yellow'], C['dbrown'], C['org_d']], flower_mid=C['org_d'],
                             decor_swap={'tree': 'autumn_tree', 'bush': 'pumpkin'}),
    'snow': dict(ground=[(232, 240, 250), C['white'], C['lgray']], path=[C['gray'], (160, 176, 200), C['lgray']],
                 path_edge=C['dgray'], ground_edge=(180, 196, 220), speck=[C['lgray'], C['white']],
                 pebble=[C['dgray'], C['white']], details='snow'),
    # acid refinery: grimy factory yard, riveted steel plates for the road
    'toxic': dict(ground=[(56, 62, 58), (66, 72, 64), (78, 84, 72)], path=[(96, 102, 112), (108, 114, 124), (88, 94, 104)],
                  path_edge=C['black'], ground_edge=(40, 46, 44), speck=[(96, 104, 84), (44, 50, 48)],
                  pebble=[(70, 76, 86)], details='toxic', path_style='plates'),
    # farmlands: warm grass, dirt road, fenced crop fields
    'farm': dict(ground=[(78, 142, 66), (92, 160, 72), (108, 174, 82)], path=[(176, 126, 80), (160, 110, 70), (190, 142, 94)],
                 path_edge=C['dbrown'], ground_edge=(54, 106, 54), speck=[C['lgreen'], C['dgreen']],
                 pebble=[C['brown'], C['sand']], details='flowers'),
    'volcano': dict(ground=[C['navy'], (48, 46, 72), C['xdgray']], path=[(92, 60, 58), C['dbrown'], (100, 70, 62)],
                    path_edge=C['xdbrown'], ground_edge=C['black'], speck=[C['xdgray'], C['dred']],
                    pebble=[C['dred'], C['orange']], details='embers'),
}


def path_tiles(waypoints):
    tiles = []
    for (x0, y0), (x1, y1) in zip(waypoints, waypoints[1:]):
        dx = (x1 > x0) - (x1 < x0)
        dy = (y1 > y0) - (y1 < y0)
        x, y = x0, y0
        tiles.append((x, y))
        while (x, y) != (x1, y1):
            x += dx
            y += dy
            tiles.append((x, y))
    return tiles


def path_orientation(paths):
    """tile -> set of 'h' / 'v': which way the road runs through it (both on corners and crossings)."""
    res = {}
    for p in paths:
        for (x0, y0), (x1, y1) in zip(p, p[1:]):
            o = 'h' if y0 == y1 else 'v'
            for t in path_tiles([(x0, y0), (x1, y1)]):
                res.setdefault(t, set()).add(o)
    return res


def ellipse_tiles(cx, cy, rx, ry):
    res = set()
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1:
                res.add((x, y))
    return res


def gas_zone(tx, ty):
    if 8 <= tx <= 24 and ty <= 5:
        return 'concrete'     # shop and sidewalk
    if 5 <= tx <= 27 and 6 <= ty <= 7:
        return 'asphalt'      # forecourt
    if 13 <= tx <= 19 and 9 <= ty <= 17:
        return 'concrete'     # pump pad
    if 6 <= tx <= 11 and 10 <= ty <= 16:
        return 'asphalt'      # parking lot
    if 22 <= tx <= 26 and 11 <= ty <= 16:
        return 'concrete'     # car wash pad
    return 'grass'


ZONES = {'gas_station': gas_zone}

# farmlands: fenced crop fields (x0, y0, x1, y1 in tiles, inclusive) and the barn
FARM_FIELDS = [((7, 13, 11, 17), 'wheat'), ((15, 1, 19, 4), 'cabbage'), ((23, 16, 30, 20), 'wheat'),
               ((0, 15, 3, 20), 'corn'), ((23, 0, 30, 4), 'cabbage')]
FARM_BARN = (15, 9, 18, 11)

# graveyard plots: (x0, y0, x1, y1) in tiles, grave columns / rows, chance of a grave
GRAVE_PLOTS = [
    ((1, 5, 7, 9), (2, 4, 6), (6, 8), 0.8),
    ((2, 14, 12, 19), (3, 5, 7, 9, 11), (15, 17), 0.65),
    ((11, 0, 14, 5), (12, 14), (1, 3), 0.75),
    ((24, 4, 30, 8), (25, 27, 29), (5, 7), 0.7),
    ((19, 10, 24, 15), (20, 22, 24), (11, 13), 0.5),
]

MAPS = [
    dict(id='meadow', name='Green Meadow', theme='meadow', tier='Beginner', seed=11, seed_idx=0,
         paths=[[(-1, 4), (8, 4), (8, 15), (16, 15), (16, 6), (24, 6), (24, 17), (33, 17)]],
         decor=['tree', 'tree', 'bush', 'bush', 'rock'], density=0.07, variants=['halloween'],
         desc='A calm field. Perfect for learning the ropes.'),
    dict(id='canyon', name='Dusty Canyon', theme='desert', tier='Beginner', seed=23, seed_idx=1,
         paths=[[(-1, 17), (5, 17), (5, 4), (12, 4), (12, 13), (19, 13), (19, 3), (27, 3), (27, 18), (14, 18),
                 (14, 23)]],
         decor=['cactus', 'cactus', 'rock', 'skull', 'dead_tree'], density=0.06,
         desc='Long dusty road through the badlands.'),
    dict(id='gas_station', name='Gas Station', theme='gas', tier='Intermediate', seed=5, seed_idx=2,
         paths=[[(-1, 2), (4, 2), (4, 18), (12, 18), (12, 8), (20, 8), (20, 18), (28, 18), (28, 4), (33, 4)]],
         decor={'grass': ['tree', 'bush', 'bush', 'rock'], 'concrete': ['cone', 'barrel', 'tires'], 'asphalt': []},
         density=0.03,
         desc='Something is leaking. Fuel for a new recruit?'),
    dict(id='swamp', name='Murky Swamp', theme='swamp', tier='Intermediate', seed=17, seed_idx=5,
         paths=[[(14, -1), (14, 15), (25, 15), (25, 9), (8, 9), (8, 23)]],
         decor=['swamp_tree', 'swamp_tree', 'dead_tree', 'reeds', 'mushroom', 'log'], density=0.05,
         desc='The boardwalk crosses itself. Guard the crossing!'),
    dict(id='farmlands', name='Farmlands', theme='farm', tier='Intermediate', seed=41, seed_idx=8,
         paths=[[(-1, 11), (5, 11), (5, 3), (13, 3), (13, 18), (21, 18), (21, 7), (28, 7), (28, 14), (33, 14)]],
         decor=['tree', 'bush', 'haystack', 'hay_bale', 'hay_bale', 'scarecrow', 'rock'], density=0.05,
         desc='Quiet country roads between the fields. Crops and the barn take some of the space.'),
    dict(id='frozen_lake', name='Frozen Lake', theme='snow', tier='Advanced', seed=7, seed_idx=3,
         paths=[[(3, -1), (3, 7), (14, 7), (14, 11), (20, 11), (20, 3), (27, 3), (27, 18), (33, 18)],
                [(3, 23), (3, 15), (14, 15), (14, 11), (20, 11), (20, 3), (27, 3), (27, 18), (33, 18)]],
         decor=['snow_pine', 'snow_pine', 'snow_pine', 'snowman', 'ice_block', 'rock'], density=0.06,
         desc='Two trails meet on the ice. Watch both flanks.'),
    dict(id='graveyard', name='Old Graveyard', theme='grave', tier='Advanced', seed=13, seed_idx=6,
         paths=[[(-1, 3), (9, 3), (9, 12), (16, 12), (16, 18), (27, 18), (27, 10), (33, 10)],
                [(22, 3), (22, 7), (16, 7), (16, 12), (16, 18), (27, 18), (27, 10), (33, 10)]],
         decor=['dead_tree', 'tomb', 'tomb_cross', 'skull', 'pumpkin', 'rock'], density=0.035,
         desc='The dead crawl out of the crypt. Short roads, no rest.'),
    dict(id='refinery', name='Acid Refinery', theme='toxic', tier='Advanced', seed=31, seed_idx=7,
         paths=[[(-1, 3), (6, 3), (6, 9), (13, 9), (13, 13), (20, 13), (20, 4), (27, 4), (27, 17), (33, 17)],
                [(-1, 19), (10, 19), (10, 13), (13, 13), (20, 13), (20, 4), (27, 4), (27, 17), (33, 17)]],
         decor=['toxic_barrel', 'toxic_barrel', 'acid_barrel', 'pipe', 'tires', 'rock'], density=0.05,
         desc='Two roads through a leaking chemical plant. They join in the middle.'),
    dict(id='volcano', name='Volcano', theme='volcano', tier='Expert', seed=3, seed_idx=4,
         paths=[[(5, -1), (5, 6), (27, 6), (27, 23)],
                [(-1, 17), (14, 17), (14, 12), (27, 12), (27, 23)]],
         decor=['lava_rock', 'lava_rock', 'crystal', 'dead_tree', 'skull'], density=0.04,
         desc='Two short roads, lava eats the best spots. It erupts!'),
]
MENU_MAP = dict(id='menu', name='Menu', theme='meadow', tier='', seed=99, seed_idx=-1,
                paths=[[(-1, 9), (7, 9), (7, 18), (15, 18), (15, 13), (25, 13), (25, 18), (33, 18), (33, 8),
                        (41, 8)]],
                decor=['tree', 'tree', 'bush', 'rock', 'bush'], density=0.08, variants=['halloween'], desc='')


def path_style_px(style, x, y, d, horiz, pal, idx):
    """Texture of a road pixel. d = distance to the road edge (1 = outermost pixel)."""
    if style == 'asphalt':
        if d == 3:
            return (150, 156, 178)   # white side line
        return pal[idx]
    if style == 'planks':
        a = x if horiz else y   # along the road
        b = y if horiz else x   # across
        if d == 2:
            return (96, 62, 44)     # side rail
        if a % 4 == 0:
            return (70, 46, 36)     # gap between boards
        board = a // 4
        col = pal[(board * 5 + (b // 16) * 3) % 3]
        if a % 4 == 1 and d == 3:
            return C['xdgray']      # nail
        if (board * 7 + b * 3) % 11 == 0:
            return shade(col, 0.85)  # grain
        return col
    if style == 'plates':
        if x % 16 == 0 or y % 16 == 0:
            return (64, 68, 80)     # seam between plates
        if x % 16 in (2, 13) and y % 16 in (2, 13):
            return (150, 156, 168)  # rivet
        if (x // 16 + y // 16) % 3 == 0 and (x * 3 + y * 7) % 29 == 0:
            return (140, 84, 54)    # rust spot
        return pal[idx]
    if style == 'cobble':
        r = y // 4
        off = (r % 2) * 3
        if y % 4 == 0 or (x + off) % 6 == 0:
            return (60, 60, 78)     # mortar
        col = pal[(r * 7 + ((x + off) // 6) * 13) % 3]
        if y % 4 == 1 and (x + off) % 6 == 1:
            return shade(col, 1.15)
        return col
    return pal[idx]


def bake_map(m, cols=32, rows=23, variant=None):
    """variant: seasonal look ('halloween'). It consumes the same random numbers, so the layout stays identical."""
    rnd = random.Random(m['seed'])
    th = THEMES[m['theme'] + ('_' + variant if variant else '')]
    W, H = cols * T, rows * T
    img = Image.new('RGBA', (W, H))
    px = img.load()
    # tile classification
    ptiles = set()
    for p in m['paths']:
        ptiles |= set(path_tiles(p))
    porient = path_orientation(m['paths'])
    zone_fn = ZONES.get(m['id'])
    style = th.get('path_style')
    special = {}  # tile -> kind (lake/lava/building)
    ellipses = []  # (kind, cx, cy, rx, ry) in tile units, rendered per pixel
    if m['id'] == 'frozen_lake':
        ellipses += [('lake', 9, 11.5, 4.6, 2.6), ('lake', 23.5, 15.5, 2.6, 2.4)]
    if m['id'] == 'volcano':
        ellipses += [('lava', cx, cy, rx, ry) for (cx, cy, rx, ry) in
                     [(2.5, 3.0, 2.0, 2.2), (9.0, 10.5, 3.5, 2.2), (20.5, 9.0, 4.0, 1.4), (31.0, 9.0, 1.6, 2.6),
                      (20.0, 17.0, 4.0, 2.6), (8.5, 20.5, 3.5, 1.5)]]
    if m['id'] == 'refinery':
        ellipses += [('acid', cx, cy, rx, ry) for (cx, cy, rx, ry) in
                     [(2.5, 12.0, 2.0, 2.5), (16.5, 18.0, 3.0, 1.8), (24.0, 9.5, 2.0, 3.0), (11.0, 1.5, 3.5, 1.2),
                      (30.5, 10.5, 1.3, 2.5)]]
    if m['id'] == 'swamp':
        ellipses += [('bog', cx, cy, rx, ry) for (cx, cy, rx, ry) in
                     [(3.5, 14.5, 2.6, 3.0), (19.5, 12.0, 4.0, 1.7), (28.5, 4.5, 2.8, 2.6), (13.5, 21.3, 3.2, 1.3),
                      (4.5, 1.2, 3.2, 1.3), (19.5, 6.0, 3.6, 2.0), (10.8, 5.8, 2.2, 1.8)]]
    for (k, cx, cy, rx, ry) in ellipses:
        for ty in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for tx in range(int(cx - rx) - 1, int(cx + rx) + 2):
                hit = 0
                for sx in (0.15, 0.5, 0.85):
                    for sy in (0.15, 0.5, 0.85):
                        if ((tx + sx - cx) / rx) ** 2 + ((ty + sy - cy) / ry) ** 2 <= 1:
                            hit += 1
                if hit >= 2:
                    special[(tx, ty)] = k
    buildings = []  # (tx0, ty0, tx1, ty1) inclusive
    if m['id'] == 'gas_station':
        buildings += [(9, 0, 22, 4), (14, 10, 18, 13), (23, 12, 25, 14), (25, 1, 26, 2)]
    if m['id'] == 'graveyard':
        buildings += [(20, 0, 24, 2)]
    if m['id'] == 'farmlands':
        buildings += [r for r, _ in FARM_FIELDS] + [FARM_BARN]
    for (x0, y0, x1, y1) in buildings:
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                special[(x, y)] = 'building'
    for t in list(special):
        if t in ptiles:
            del special[t]

    def is_path_px(x, y):
        return (x // T, y // T) in ptiles

    def special_px(x, y):
        if (x // T, y // T) in ptiles:
            return None
        for (k, cx, cy, rx, ry) in ellipses:
            if ((x / T - cx) / rx) ** 2 + ((y / T - cy) / ry) ** 2 <= 1:
                return k
        k = special.get((x // T, y // T))
        return k if k in ('building', 'island') else None

    def zone_px(x, y):
        return zone_fn(x // T, y // T) if zone_fn else None

    def edge_dist(x, y, maxd=4):
        for d in range(1, maxd + 1):
            for dy in range(-d, d + 1):
                for dx in ((-d, d) if abs(dy) != d else range(-d, d + 1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and not is_path_px(nx, ny):
                        return d
        return maxd + 1

    nz = value_noise(W, H, 12, rnd)
    nz2 = value_noise(W, H, 5, rnd)
    for y in range(H):
        for x in range(W):
            n = nz[y][x] * 0.7 + nz2[y][x] * 0.3
            b = BAYER[y % 4][x % 4] / 16.0 - 0.5
            v = n + b * 0.18
            on_path = is_path_px(x, y)
            if on_path:
                pal = th['path']
            else:
                pal = th['ground']
                if zone_fn:
                    pal = th['zones'].get(zone_px(x, y), pal)
            idx = 0 if v < 0.42 else (1 if v < 0.6 else 2)
            col = pal[idx]
            if style and on_path:
                col = path_style_px(style, x, y, edge_dist(x, y), 'h' in porient.get((x // T, y // T), 'h'), pal, idx)
            px[x, y] = col + (255,)
    # specials
    for y in range(H):
        for x in range(W):
            k = special_px(x, y)
            if not k:
                continue
            if k == 'lake':
                v = nz2[y][x]
                col = C['cyan'] if v > 0.72 else ((126, 200, 240) if v > 0.4 else (96, 176, 230))
                if (x + y * 3) % 23 == 0:
                    col = C['white']
                px[x, y] = col + (255,)
            elif k == 'lava':
                v = nz[y][x] * 0.6 + nz2[y][x] * 0.4
                col = C['yellow'] if v > 0.68 else (C['orange'] if v > 0.45 else C['red'])
                px[x, y] = col + (255,)
            elif k == 'bog':
                v = nz[y][x] * 0.5 + nz2[y][x] * 0.5
                col = (70, 124, 100) if v > 0.66 else ((52, 106, 92) if v > 0.42 else (40, 88, 82))
                if (x * 5 + y * 3) % 37 == 0:
                    col = (126, 176, 134)
                px[x, y] = col + (255,)
            elif k == 'acid':
                v = nz[y][x] * 0.5 + nz2[y][x] * 0.5
                col = (170, 240, 100) if v > 0.68 else (C['lgreen'] if v > 0.45 else (60, 160, 64))
                if (x * 7 + y * 5) % 41 == 0:
                    col = (220, 255, 170)   # bubble
                px[x, y] = col + (255,)
            elif k == 'island':
                px[x, y] = (C['lgray'] if (x // 4 + y // 4) % 2 else (176, 188, 206)) + (255,)
    # edges for path / specials
    src = img.copy().load()
    for y in range(H):
        for x in range(W):
            here_p = is_path_px(x, y)
            here_s = special_px(x, y)
            here_z = zone_px(x, y)
            near_ground = False
            near_path = False
            near_special = None
            near_zone = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < W and 0 <= ny < H):
                    continue
                p2 = is_path_px(nx, ny)
                s2 = special_px(nx, ny)
                if here_p and not p2:
                    near_ground = True
                if not here_p and p2:
                    near_path = True
                if here_s and s2 != here_s:
                    near_special = here_s
                if zone_fn and not p2 and zone_px(nx, ny) != here_z:
                    near_zone = True
            if here_p and near_ground:
                px[x, y] = th['path_edge'] + (255,)
            elif not here_p and near_path and not here_s:
                ge = th['zone_edge'][here_z] if zone_fn else th['ground_edge']
                px[x, y] = ge + (255,)
            elif near_special:
                k = near_special
                ec = {'lake': C['white'], 'lava': C['black'], 'island': C['dgray'], 'building': None,
                      'bog': (28, 52, 40), 'acid': C['xdgreen']}[k]
                if ec:
                    px[x, y] = ec + (255,)
            elif near_zone and not here_p and not here_s:
                px[x, y] = th['zone_edge'][here_z] + (255,)
    # ground details & pebbles
    for _ in range(int(W * H / 90)):
        x, y = rnd.randrange(W), rnd.randrange(H)
        if special_px(x, y):
            continue
        if is_path_px(x, y):
            if style in ('planks', 'cobble'):
                continue
            px[x, y] = rnd.choice(th['pebble']) + (255,)
        elif zone_fn:
            px[x, y] = rnd.choice(th['zone_speck'].get(zone_px(x, y), th['speck'])) + (255,)
        else:
            px[x, y] = rnd.choice(th['speck']) + (255,)
    det = th['details']
    for _ in range(int(cols * rows * 0.5)):
        tx, ty = rnd.randrange(cols), rnd.randrange(rows)
        if (tx, ty) in ptiles or (tx, ty) in special:
            continue
        x, y = tx * T + rnd.randrange(2, 13), ty * T + rnd.randrange(3, 13)
        if det == 'flowers' or (det == 'gas' and gas_zone(tx, ty) == 'grass'):
            if rnd.random() < 0.6:  # grass tuft
                for (dx, dy) in ((0, 0), (-1, -1), (1, -1), (0, -2)):
                    tl, td = th.get('tuft', (C['lgreen'], C['dgreen']))
                    px[x + dx, y + dy] = (tl if dy < -1 else td) + (255,)
            else:
                c = rnd.choice(th.get('flowers', [C['yellow'], C['white'], C['pink'], C['red']]))
                px[x, y] = c + (255,)
                px[x + 1, y] = c + (255,)
                px[x, y - 1] = c + (255,)
                px[x + 1, y - 1] = th.get('flower_mid', C['gold']) + (255,)
        elif det == 'desert':
            for (dx, dy) in ((0, 0), (1, 0), (2, 0)):
                px[x + dx, y + dy] = C['tan'] + (255,)
            px[x + 1, y - 1] = C['white'] + (255,)
        elif det == 'snow':
            px[x, y] = C['lgray'] + (255,)
            px[x + 1, y] = C['lgray'] + (255,)
            px[x, y - 1] = C['white'] + (255,)
        elif det == 'embers':
            px[x, y] = rnd.choice([C['orange'], C['red'], C['dred']]) + (255,)
        elif det == 'swamp':
            r = rnd.random()
            if r < 0.55:  # dark tuft
                for (dx, dy) in ((0, 0), (-1, -1), (1, -1), (0, -2), (2, -2)):
                    px[x + dx, y + dy] = ((88, 132, 72) if dy < -1 else (30, 56, 42)) + (255,)
            elif r < 0.8:  # firefly
                px[x, y] = (214, 240, 120) + (255,)
            else:  # mud
                for (dx, dy) in ((0, 0), (1, 0), (2, 0), (1, 1)):
                    px[x + dx, y + dy] = (52, 56, 40) + (255,)
        elif det == 'toxic':
            r = rnd.random()
            if r < 0.4:  # green stain
                for (dx, dy) in ((0, 0), (1, 0), (0, 1)):
                    px[x + dx, y + dy] = (74, 112, 64) + (255,)
            elif r < 0.7:  # rust flake
                px[x, y] = (140, 84, 54) + (255,)
            else:  # bolt
                px[x, y] = (130, 136, 148) + (255,)
                px[x + 1, y] = (60, 64, 76) + (255,)
        elif det == 'grave':
            r = rnd.random()
            if r < 0.6:  # dry tuft
                for (dx, dy) in ((0, 0), (-1, -1), (1, -1), (0, -2)):
                    px[x + dx, y + dy] = ((96, 110, 90) if dy < -1 else (38, 50, 52)) + (255,)
            elif r < 0.8:  # tiny flower
                px[x, y] = rnd.choice([C['magenta'], C['lgray']]) + (255,)
                px[x, y + 1] = (38, 50, 52) + (255,)
            else:  # bone
                px[x, y] = C['sand'] + (255,)
                px[x + 1, y] = C['sand'] + (255,)
    if det == 'gas':
        paint_gas_ground(img, rnd, ptiles, special, m['paths'], W, H)
    # concrete slab lines for gas station ground
    if det == 'concrete':
        for y in range(H):
            for x in range(W):
                if is_path_px(x, y) or special_px(x, y):
                    continue
                if (x % 32 == 0 or y % 32 == 0):
                    px[x, y] = C['dgray'] + (255,)
        # yellow dashes along road centre
        for p in m['paths']:
            for (x0, y0), (x1, y1) in zip(p, p[1:]):
                ax, ay, bx, by = x0 * T + 8, y0 * T + 8, x1 * T + 8, y1 * T + 8
                n = max(abs(bx - ax), abs(by - ay))
                for i in range(n):
                    if (i // 4) % 2:
                        continue
                    xx = ax + (bx - ax) * i // max(n, 1)
                    yy = ay + (by - ay) * i // max(n, 1)
                    if 0 <= xx < W and 0 <= yy < H:
                        px[xx, yy] = C['gold'] + (255,)
    if m['id'] == 'swamp':
        paint_lily_pads(img, rnd, special_px, W, H)
    # lava glow speck
    if det == 'embers':
        for (tx, ty), k in special.items():
            pass

    blocked = set(ptiles) | set(special)
    decor_list = []

    def place(name, tx, ty, fw=1, fh=1):
        for xx in range(tx, tx + fw):
            for yy in range(ty, ty + fh):
                blocked.add((xx, yy))
        decor_list.append((name, tx, ty, fw, fh))

    # fixed gas station props
    if m['id'] == 'gas_station':
        draw_store(img, 9 * T, 0, 14 * T, 5 * T)
        draw_canopy(img, 14 * T, 10 * T, 5 * T, 4 * T)
        draw_carwash(img, 23 * T, 12 * T, 3 * T, 3 * T)
        draw_pylon(img, 25 * T, 1 * T, 2 * T, 2 * T)
        draw_parking(img, 6, 10, 11, 16)
        for x in (14, 16, 18):
            place('pump', x, 12)
        place('car_red', 6, 11, 2, 1)
        place('car_blue', 10, 12, 2, 1)
        place('car_blue', 6, 14, 2, 1)
        place('car_red', 10, 16, 2, 1)
        place('lamp', 5, 7)
        place('lamp', 27, 7)
        place('dumpster', 23, 3, 2, 1)
        place('trash', 10, 5)
        place('trash', 21, 5)
        place('hydrant', 2, 9)
    if m['id'] == 'refinery':
        place('tank', 16, 6, 2, 2)
        place('tank', 23, 18, 2, 2)
        for (x, y) in ((2, 5), (8, 14), (29, 0), (14, 14), (23, 13)):
            place('big_barrel', x, y, 2, 3)
    if m['id'] == 'farmlands':
        for rect, kind in FARM_FIELDS:
            draw_field(img, rect, kind, rnd)
        x0, y0, x1, y1 = FARM_BARN
        draw_barn(img, x0 * T, y0 * T, (x1 - x0 + 1) * T, (y1 - y0 + 1) * T)
    if m['id'] == 'graveyard':
        draw_crypt(img, 20 * T, 0, 5 * T, 3 * T)
        for (rect, xs, ys, chance) in GRAVE_PLOTS:
            draw_fence(img, rect)
            for gy in ys:
                for gx in xs:
                    if (gx, gy) not in blocked and rnd.random() < chance:
                        place(rnd.choice(['tomb', 'tomb', 'tomb_cross']), gx, gy)
    if m['id'] == 'swamp':
        for (x, y) in sorted(t for t, k in special.items() if k == 'bog'):
            for d in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (x + d[0], y + d[1])
                if 0 <= n[0] < cols and 0 <= n[1] < rows - 1 and n not in blocked and rnd.random() < 0.3:
                    place('reeds', *n)
    # random decor
    cand = [(x, y) for x in range(cols) for y in range(rows - 1) if (x, y) not in blocked]
    rnd.shuffle(cand)
    n = int(len(cand) * m['density'])
    for (x, y) in cand[:n]:
        if (x, y) in blocked:
            continue
        decor = m['decor']
        if isinstance(decor, dict):
            decor = decor[zone_fn(x, y)]
            if not decor:
                continue
        place(rnd.choice(decor), x, y)
    # draw decor sorted by y
    for name, tx, ty, fw, fh in sorted(decor_list, key=lambda d: d[2]):
        if name in th.get('decor_swap', {}):
            # every third tree is a dead one, picked by position so no random numbers are used
            name = 'dead_tree' if name == 'tree' and (tx * 7 + ty * 3) % 3 == 0 else th['decor_swap'][name]
        rows_, cm = DECOR_SPRITES[name]
        spr = make(rows_, cm)
        x = tx * T + (fw * T - spr.width) // 2
        y = (ty + fh) * T - spr.height - 1
        # shadow
        sh = Image.new('RGBA', spr.size, (0, 0, 0, 0))
        shp = sh.load()
        sp = spr.load()
        for yy in range(spr.height):
            for xx in range(spr.width):
                if sp[xx, yy][3] and yy > spr.height - 4:
                    shp[xx, yy] = (0, 0, 0, 70)
        img.alpha_composite(sh, (x + 2, y + 1))
        if y >= 0:
            img.alpha_composite(spr, (x, y))
        else:
            img.alpha_composite(spr.crop((0, -y, spr.width, spr.height)), (x, 0))
    return img, blocked, ptiles, special


# ------------------------------------------------------------------ map painters
def fill(px, x0, y0, x1, y1, col):
    """Fills [x0, x1) x [y0, y1)."""
    for y in range(y0, y1):
        for x in range(x0, x1):
            px[x, y] = col + (255,)


def frame(px, x0, y0, x1, y1, col):
    """1 px outline of [x0, x1) x [y0, y1)."""
    for x in range(x0, x1):
        px[x, y0] = col + (255,)
        px[x, y1 - 1] = col + (255,)
    for y in range(y0, y1):
        px[x0, y] = col + (255,)
        px[x1 - 1, y] = col + (255,)


def darken(px, x0, y0, x1, y1, f, W=None, H=None):
    for y in range(y0, y1):
        for x in range(x0, x1):
            if (W is None or 0 <= x < W) and (H is None or 0 <= y < H):
                c = px[x, y]
                px[x, y] = shade(c[:3], f) + (255,)


def paint_gas_ground(img, rnd, ptiles, special, paths, W, H):
    px = img.load()
    # concrete slab seams and asphalt oil stains
    for y in range(H):
        for x in range(W):
            t = (x // T, y // T)
            if t in ptiles or t in special:
                continue
            z = gas_zone(*t)
            if z == 'concrete' and (x % T == 0 or y % T == 0):
                c = px[x, y][:3]
                if c != C['lgray']:
                    px[x, y] = (146, 154, 176, 255)
    for _ in range(26):
        x, y = rnd.randrange(W), rnd.randrange(H)
        t = (x // T, y // T)
        if t in ptiles or t in special or gas_zone(*t) != 'asphalt':
            continue
        rx, ry = rnd.randint(2, 5), rnd.randint(1, 3)
        for yy in range(y - ry, y + ry + 1):
            for xx in range(x - rx, x + rx + 1):
                if not (0 <= xx < W and 0 <= yy < H):
                    continue
                if ((xx - x) / rx) ** 2 + ((yy - y) / ry) ** 2 <= 1 and gas_zone(xx // T, yy // T) == 'asphalt' \
                        and (xx // T, yy // T) not in ptiles:
                    c = px[xx, yy][:3]
                    px[xx, yy] = shade(c, 0.72) + (255,)
    # yellow dashes along the road centre
    for p in paths:
        for (x0, y0), (x1, y1) in zip(p, p[1:]):
            ax, ay, bx, by = x0 * T + 8, y0 * T + 8, x1 * T + 8, y1 * T + 8
            n = max(abs(bx - ax), abs(by - ay))
            for i in range(n):
                if (i // 4) % 2:
                    continue
                xx = ax + (bx - ax) * i // max(n, 1)
                yy = ay + (by - ay) * i // max(n, 1)
                if 0 <= xx < W and 0 <= yy < H:
                    px[xx, yy] = C['gold'] + (255,)


def draw_parking(img, tx0, ty0, tx1, ty1):
    """White stall lines: a column of stalls on each side of a 2 tile aisle."""
    px = img.load()
    line = (214, 220, 232)
    for (sx0, sx1) in ((tx0 * T, (tx0 + 2) * T), ((tx1 - 1) * T, (tx1 + 1) * T)):
        for y in [ty * T for ty in range(ty0, ty1 + 1)] + [(ty1 + 1) * T - 1]:
            for x in range(sx0 + 2, sx1 - 2):
                px[x, y] = line + (255,)
    # arrows in the aisle
    ax = (tx0 + 3) * T
    for ty in (ty0 + 1, ty0 + 4):
        cy = ty * T + 4
        for i in range(8):
            px[ax, cy + i] = line + (255,)
        for i in range(1, 4):
            px[ax - i, cy + 7 - i] = line + (255,)
            px[ax + i, cy + 7 - i] = line + (255,)


def draw_store(img, x0, y0, w, h):
    px = img.load()
    rnd = random.Random(42)
    # flat roof with gravel
    for y in range(y0, y0 + 22):
        for x in range(x0, x0 + w):
            px[x, y] = ((150, 160, 182) if (x * 7 + y * 13) % 5 else (138, 148, 170)) + (255,)
    fill(px, x0, y0 + 19, x0 + w, y0 + 20, C['lgray'])
    fill(px, x0, y0 + 20, x0 + w, y0 + 22, C['dgray'])
    # AC units
    for (ax, aw) in ((16, 28), (176, 32)):
        darken(px, x0 + ax + 2, y0 + 15, x0 + ax + aw + 2, y0 + 17, 0.75)
        fill(px, x0 + ax, y0 + 3, x0 + ax + aw, y0 + 15, C['lgray'])
        fill(px, x0 + ax, y0 + 12, x0 + ax + aw, y0 + 15, C['gray'])
        frame(px, x0 + ax, y0 + 3, x0 + ax + aw, y0 + 15, C['black'])
        for gx in range(x0 + ax + 3, x0 + ax + aw // 2, 2):
            for gy in range(y0 + 5, y0 + 11):
                px[gx, gy] = C['dgray'] + (255,)
        cx, cy = x0 + ax + aw * 3 // 4, y0 + 8
        for yy in range(cy - 4, cy + 5):
            for xx in range(cx - 4, cx + 5):
                d = (xx - cx) ** 2 + (yy - cy) ** 2
                if d <= 16:
                    px[xx, yy] = (C['xdgray'] if d > 9 else C['dgray']) + (255,)
        for i in range(-3, 4):
            px[cx + i, cy] = C['gray'] + (255,)
            px[cx, cy + i] = C['gray'] + (255,)
    # vent pipes
    for vx in (x0 + 96, x0 + 128):
        fill(px, vx, y0 + 6, vx + 5, y0 + 11, C['gray'])
        frame(px, vx, y0 + 6, vx + 5, y0 + 11, C['black'])
        px[vx + 2, y0 + 8] = C['black'] + (255,)
    # sign fascia
    fill(px, x0, y0 + 22, x0 + w, y0 + 36, C['red_m'])
    fill(px, x0, y0 + 22, x0 + w, y0 + 23, C['red_l'])
    fill(px, x0, y0 + 35, x0 + w, y0 + 36, C['red_d'])
    text = "GAS-N-GO"
    tw = text3_width(text, 2)
    tx = x0 + (w - tw) // 2
    draw_text3(img, tx + 1, y0 + 25, text, C['red_d'], 2)
    draw_text3(img, tx, y0 + 24, text, C['white'], 2)
    for sx in (tx - 14, tx + tw + 8):   # little fuel drops
        for (dx, dy) in ((2, 0), (1, 1), (2, 1), (3, 1), (0, 2), (1, 2), (2, 2), (3, 2), (4, 2), (0, 3), (1, 3), (2, 3),
                         (3, 3), (4, 3), (1, 4), (2, 4), (3, 4)):
            px[sx + dx, y0 + 26 + dy] = C['yellow'] + (255,)
    # awning
    for y in range(y0 + 36, y0 + 43):
        for x in range(x0 + 1, x0 + w - 1):
            stripe = ((x - x0) // 6) % 2 == 0
            if y == y0 + 42 and (x - x0) % 6 in (0, 5):
                continue   # scalloped edge
            c = C['red_l'] if stripe else C['white']
            if y >= y0 + 40:
                c = C['red_m'] if stripe else C['lgray']
            px[x, y] = c + (255,)
    # brick wall
    for y in range(y0 + 43, y0 + 78):
        for x in range(x0, x0 + w):
            ly, lx = y - y0, x - x0
            mortar = ly % 5 == 0 or (lx + (4 if (ly // 5) % 2 else 0)) % 9 == 0
            px[x, y] = (C['tan_l'] if mortar else C['sand']) + (255,)
    darken(px, x0, y0 + 43, x0 + w, y0 + 45, 0.8)
    # shop windows with shelves
    for (wx0, wx1) in ((10, 90), (134, 214)):
        fill(px, x0 + wx0, y0 + 47, x0 + wx1, y0 + 72, C['glass_d'])
        for y in range(y0 + 48, y0 + 71):
            for x in range(x0 + wx0 + 1, x0 + wx1 - 1):
                t = (y - y0 - 48) / 22
                c = lerp(C['glass_d'], C['glass'], t * 0.8)
                px[x, y] = c + (255,)
        for sy in (57, 65):
            fill(px, x0 + wx0 + 2, y0 + sy, x0 + wx1 - 2, y0 + sy + 1, C['xdgray'])
            x = x0 + wx0 + 3
            while x < x0 + wx1 - 4:
                col = rnd.choice([C['red'], C['yellow'], C['lgreen'], C['blue'], C['orange'], C['white']])
                hh = rnd.randint(2, 4)
                fill(px, x, y0 + sy - hh, x + 2, y0 + sy, col)
                x += 3 + rnd.randint(0, 1)
        for y in range(y0 + 48, y0 + 71):
            for x in range(x0 + wx0 + 1, x0 + wx1 - 1):
                if (x - y) % 23 in (0, 1):
                    px[x, y] = lerp(px[x, y][:3], C['white'], 0.6) + (255,)
        frame(px, x0 + wx0, y0 + 47, x0 + wx1, y0 + 72, C['black'])
        fill(px, x0 + wx0, y0 + 72, x0 + wx1, y0 + 74, C['lgray'])
        fill(px, x0 + wx0, y0 + 74, x0 + wx1, y0 + 75, C['dgray'])
    # OPEN sign
    fill(px, x0 + 14, y0 + 49, x0 + 35, y0 + 56, C['black'])
    draw_text3(img, x0 + 16, y0 + 50, "OPEN", C['red_l'])
    # double glass door
    dx0, dx1 = x0 + w // 2 - 14, x0 + w // 2 + 14
    fill(px, dx0, y0 + 45, dx1, y0 + 78, C['xdgray'])
    for (gx0, gx1) in ((dx0 + 2, dx0 + 13), (dx0 + 15, dx1 - 2)):
        for y in range(y0 + 47, y0 + 78):
            for x in range(gx0, gx1):
                c = C['glass'] if (x - y) % 13 > 1 else C['white']
                px[x, y] = shade(c, 0.85) + (255,)
    for hy in range(y0 + 59, y0 + 65):
        px[dx0 + 11, hy] = C['lgray'] + (255,)
        px[dx0 + 16, hy] = C['lgray'] + (255,)
    frame(px, dx0, y0 + 45, dx1, y0 + 79, C['black'])
    # base and outline
    fill(px, x0, y0 + 78, x0 + w, y0 + 79, C['dgray'])
    fill(px, x0, y0 + 79, x0 + w, y0 + 80, C['black'])
    for y in range(y0, y0 + h):
        px[x0, y] = C['black'] + (255,)
        px[x0 + w - 1, y] = C['black'] + (255,)
    darken(px, x0 + 2, y0 + 80, x0 + w + 2, y0 + 83, 0.72)


def draw_canopy(img, x0, y0, w, h):
    px = img.load()
    # shade under the roof
    darken(px, x0, y0 + 22, x0 + w, y0 + 52, 0.82)
    # pump island
    fill(px, x0 + 2, y0 + 36, x0 + w - 2, y0 + 47, (186, 194, 210))
    fill(px, x0 + 2, y0 + 47, x0 + w - 2, y0 + 50, C['dgray'])
    for x in range(x0 + 2, x0 + w - 2):
        if ((x - x0) // 3) % 2 == 0:
            px[x, y0 + 48] = C['yellow'] + (255,)
    frame(px, x0 + 2, y0 + 36, x0 + w - 2, y0 + 51, C['black'])
    # pillars between the pumps
    for lx in (22, 54):
        fill(px, x0 + lx, y0 + 22, x0 + lx + 4, y0 + 46, C['white'])
        fill(px, x0 + lx + 3, y0 + 22, x0 + lx + 4, y0 + 46, C['lgray'])
        fill(px, x0 + lx, y0 + 40, x0 + lx + 4, y0 + 43, C['red_m'])
        for y in range(y0 + 22, y0 + 46):
            px[x0 + lx - 1, y] = C['black'] + (255,)
            px[x0 + lx + 4, y] = C['black'] + (255,)
    # roof
    for y in range(y0, y0 + 14):
        for x in range(x0, x0 + w):
            px[x, y] = ((236, 240, 248) if (x + y) % 7 else C['lgray']) + (255,)
    fill(px, x0, y0 + 14, x0 + w, y0 + 21, C['red_m'])
    fill(px, x0, y0 + 14, x0 + w, y0 + 15, C['red_l'])
    fill(px, x0, y0 + 21, x0 + w, y0 + 22, C['red_d'])
    tw = text3_width("GAS")
    draw_text3(img, x0 + (w - tw) // 2, y0 + 15, "GAS", C['white'])
    frame(px, x0, y0, x0 + w, y0 + 23, C['black'])
    for x in range(x0 + 4, x0 + w - 4, 8):   # lights under the edge
        px[x, y0 + 23] = C['yellow'] + (255,)
        px[x + 1, y0 + 23] = C['yellow'] + (255,)


def draw_carwash(img, x0, y0, w, h):
    px = img.load()
    darken(px, x0 + 2, y0 + h, x0 + w + 2, y0 + h + 3, 0.72)
    # roof
    for y in range(y0, y0 + 14):
        for x in range(x0, x0 + w):
            px[x, y] = (C['blu'] if ((x - x0) // 4 + (y - y0) // 4) % 2 else C['blu_d']) + (255,)
    fill(px, x0, y0 + 14, x0 + w, y0 + 22, C['white'])
    text = "CAR WASH"
    draw_text3(img, x0 + (w - text3_width(text)) // 2, y0 + 16, text, C['blu'])
    # walls and the open bay
    fill(px, x0, y0 + 22, x0 + w, y0 + h - 1, C['lgray'])
    fill(px, x0 + 8, y0 + 23, x0 + w - 8, y0 + h - 1, C['navy'])
    for (bx0, bx1) in ((x0 + 11, x0 + 18), (x0 + w - 18, x0 + w - 11)):
        for y in range(y0 + 24, y0 + h - 3):
            for x in range(bx0, bx1):
                c = C['blu_l'] if (x + (y // 2)) % 3 else C['cyan']
                px[x, y] = c + (255,)
    for (dx, dy) in ((21, 27), (25, 33), (23, 39), (27, 29), (20, 36)):
        px[x0 + dx, y0 + dy] = C['glass'] + (255,)
    fill(px, x0, y0 + h - 1, x0 + w, y0 + h, C['black'])
    frame(px, x0, y0, x0 + w, y0 + h, C['black'])
    frame(px, x0 + 7, y0 + 22, x0 + w - 7, y0 + h, C['black'])


def draw_pylon(img, x0, y0, w, h):
    px = img.load()
    darken(px, x0 + 10, y0 + h - 3, x0 + 24, y0 + h, 0.7)
    fill(px, x0 + 14, y0 + 16, x0 + 18, y0 + h - 1, C['xdgray'])
    fill(px, x0 + 14, y0 + 16, x0 + 15, y0 + h - 1, C['gray'])
    fill(px, x0 + 11, y0 + h - 3, x0 + 21, y0 + h - 1, C['dgray'])
    fill(px, x0 + 1, y0 + 0, x0 + w - 1, y0 + 18, C['navy'])
    fill(px, x0 + 1, y0 + 0, x0 + w - 1, y0 + 7, C['red_m'])
    draw_text3(img, x0 + (w - text3_width("GAS")) // 2, y0 + 1, "GAS", C['white'])
    draw_text3(img, x0 + (w - text3_width("$3.99")) // 2, y0 + 10, "$3.99", C['yellow'])
    frame(px, x0 + 1, y0, x0 + w - 1, y0 + 18, C['black'])


def draw_fence(img, rect):
    """Iron fence around a grave plot, with a gate in the bottom side."""
    px = img.load()
    tx0, ty0, tx1, ty1 = rect
    X0, Y0, X1, Y1 = tx0 * T + 2, ty0 * T + 4, (tx1 + 1) * T - 3, (ty1 + 1) * T - 2
    gate = ((X0 + X1) // 2 - 5, (X0 + X1) // 2 + 5)
    for x in range(X0, X1 + 1):
        for y in (Y0, Y1):
            if y == Y1 and gate[0] <= x <= gate[1]:
                continue
            px[x, y] = C['dgray'] + (255,)
            if (x - X0) % 4 == 0:
                px[x, y - 1] = C['black'] + (255,)
                px[x, y - 2] = C['gray'] + (255,)
    for y in range(Y0, Y1 + 1):
        for x in (X0, X1):
            px[x, y] = C['dgray'] + (255,)
            if (y - Y0) % 4 == 0:
                px[x - 1, y] = C['black'] + (255,)
                px[x + 1, y] = C['black'] + (255,)
                px[x, y] = C['gray'] + (255,)
    for gx in gate:   # gate posts
        for y in range(Y1 - 4, Y1 + 1):
            px[gx, y] = C['black'] + (255,)
        px[gx, Y1 - 5] = C['gray'] + (255,)


def draw_field(img, rect, kind, rnd):
    """A plowed field in rows of wheat, cabbage or corn behind a wooden fence."""
    px = img.load()
    tx0, ty0, tx1, ty1 = rect
    X0, Y0, X1, Y1 = tx0 * T + 2, ty0 * T + 3, (tx1 + 1) * T - 3, (ty1 + 1) * T - 2
    soil = [(110, 72, 50), (98, 62, 46), (122, 82, 56)]
    for y in range(Y0 + 1, Y1):
        for x in range(X0 + 1, X1):
            px[x, y] = soil[(x * 7 + y * 3) % 3] + (255,)
    for y in range(Y0 + 3, Y1 - 1, 4):   # a crop row every 4 pixels
        for x in range(X0 + 2, X1 - 1):
            if kind == 'wheat':
                px[x, y] = (C['yellow'] if (x + y) % 3 == 0 else C['gold']) + (255,)
                px[x, y - 1] = (C['gold'] if x % 2 else C['lorange']) + (255,)
                if x % 2 == 0:
                    px[x, y - 2] = C['yellow'] + (255,)
            elif kind == 'cabbage':
                if (x - X0) % 4 in (0, 1, 2):
                    px[x, y] = C['green'] + (255,)
                    px[x, y - 1] = (C['lgreen'] if (x - X0) % 4 == 1 else C['green']) + (255,)
            else:   # corn: tall stalks with a cob here and there
                if (x - X0) % 3 == 0:
                    for k in range(4):
                        px[x, y - k] = (C['lgreen'] if k % 2 else C['green']) + (255,)
                    if rnd.random() < 0.3:
                        px[x + 1, y - 2] = C['yellow'] + (255,)
    wood, dark = C['brown'], C['dbrown']
    for x in range(X0, X1 + 1):
        for y in (Y0, Y1):
            px[x, y] = wood + (255,)
            px[x, y + 1 if y < Y1 else y - 1] = px[x, y + 1 if y < Y1 else y - 1] if (x - X0) % 5 else dark + (255,)
            if (x - X0) % 5 == 0:
                px[x, y - 1] = dark + (255,)
    for y in range(Y0, Y1 + 1):
        for x in (X0, X1):
            px[x, y] = (dark if (y - Y0) % 5 == 0 else wood) + (255,)


def draw_barn(img, x0, y0, w, h):
    """Big red barn: gambrel roof, white trim, a hay loft and a big door with a white X."""
    px = img.load()
    red, dred, white, dark = C['red'], C['dred'], C['white'], C['black']
    roof_h = h * 2 // 5
    for y in range(roof_h):
        k = y / max(1, roof_h - 1)
        inset = int((1 - k) * w * 0.32) if k < 0.5 else int((1 - k) * w * 0.12)
        for x in range(x0 + inset, x0 + w - inset):
            px[x, y0 + y] = (dred if (x - x0) % 6 == 0 or y == 0 else (130, 34, 44)) + (255,)
    for y in range(y0 + roof_h, y0 + h - 2):
        for x in range(x0 + 2, x0 + w - 2):
            px[x, y] = (dred if (x - x0) % 4 == 0 else red) + (255,)
    for x in range(x0 + 1, x0 + w - 1):   # trim under the roof and along the ground
        px[x, y0 + roof_h] = white + (255,)
        px[x, y0 + h - 2] = dark + (255,)
    for y in range(y0 + roof_h, y0 + h - 2):
        px[x0 + 2, y] = white + (255,)
        px[x0 + w - 3, y] = white + (255,)
    # hay loft
    lx, ly = x0 + w // 2 - 4, y0 + roof_h - 7
    for y in range(ly, ly + 6):
        for x in range(lx, lx + 8):
            edge = y in (ly, ly + 5) or x in (lx, lx + 7)
            px[x, y] = (white if edge else (C['gold'] if (x + y) % 2 else C['yellow'])) + (255,)
    # door with the white X
    dw, dh = w // 2, (h - roof_h) - 6
    dx, dy = x0 + (w - dw) // 2, y0 + h - 2 - dh
    for y in range(dy, dy + dh):
        for x in range(dx, dx + dw):
            edge = y == dy or x in (dx, dx + dw - 1)
            px[x, y] = (white if edge else (C['dbrown'] if (x - dx) % 3 else C['xdbrown'])) + (255,)
    for i in range(min(dw, dh)):
        for ox, oy in ((dx + i * dw // min(dw, dh), dy + i * dh // min(dw, dh)),
                       (dx + dw - 1 - i * dw // min(dw, dh), dy + i * dh // min(dw, dh))):
            px[ox, oy] = white + (255,)
    px[x0 + w // 2, y0 + h - 2 - dh // 2] = white + (255,)


def draw_crypt(img, x0, y0, w, h):
    """Stone mausoleum; the road starts at its door."""
    px = img.load()
    stone, stone_l, stone_d = (112, 116, 136), (140, 146, 166), (78, 80, 100)
    # body with stone blocks
    for y in range(y0 + 14, y0 + h - 2):
        for x in range(x0, x0 + w):
            ly, lx = y - y0, x - x0
            mortar = ly % 6 == 0 or (lx + (5 if (ly // 6) % 2 else 0)) % 10 == 0
            px[x, y] = (stone_d if mortar else stone) + (255,)
    # pediment roof
    for y in range(y0, y0 + 14):
        half = (y - y0) * (w // 2) // 13
        for x in range(x0 + w // 2 - half, x0 + w // 2 + half + 1):
            edge = x in (x0 + w // 2 - half, x0 + w // 2 + half)
            px[x, y] = (C['black'] if edge else (stone_l if y < y0 + 11 else stone_d)) + (255,)
    fill(px, x0, y0 + 12, x0 + w, y0 + 15, stone_l)
    fill(px, x0, y0 + 15, x0 + w, y0 + 16, C['black'])
    # skull emblem
    cx = x0 + w // 2
    for (dx, dy) in ((-1, 6), (0, 6), (1, 6), (-2, 7), (-1, 7), (0, 7), (1, 7), (2, 7), (-2, 8), (0, 8), (2, 8),
                     (-1, 9), (1, 9)):
        px[cx + dx, y0 + dy] = C['sand'] + (255,)
    # columns
    for lx in (6, 20, w - 24, w - 10):
        fill(px, x0 + lx, y0 + 16, x0 + lx + 4, y0 + h - 2, stone_l)
        fill(px, x0 + lx + 3, y0 + 16, x0 + lx + 4, y0 + h - 2, stone_d)
        frame(px, x0 + lx - 1, y0 + 16, x0 + lx + 5, y0 + h - 2, C['black'])
    # dark door with an eerie glow
    dx0, dx1 = cx - 8, cx + 8
    for y in range(y0 + 20, y0 + h - 2):
        for x in range(dx0, dx1):
            t = (y - y0 - 20) / (h - 22)
            px[x, y] = lerp((20, 14, 30), (104, 56, 108), t * 0.7) + (255,)
    frame(px, dx0 - 1, y0 + 19, dx1 + 1, y0 + h - 1, C['black'])
    # steps
    fill(px, x0 + 2, y0 + h - 2, x0 + w - 2, y0 + h, stone_l)
    fill(px, x0 + 2, y0 + h - 1, x0 + w - 2, y0 + h, stone_d)
    for y in range(y0 + 12, y0 + h):
        px[x0, y] = C['black'] + (255,)
        px[x0 + w - 1, y] = C['black'] + (255,)


def paint_lily_pads(img, rnd, special_px, W, H):
    px = img.load()
    for _ in range(400):
        x, y = rnd.randrange(W), rnd.randrange(H)
        r = rnd.choice((2, 2, 3))
        if any(special_px(x + dx, y + dy) != 'bog' for dx in (-r - 1, r + 1) for dy in (-r - 1, r + 1)
               if 0 <= x + dx < W and 0 <= y + dy < H):
            continue
        for yy in range(y - r, y + r + 1):
            for xx in range(x - r, x + r + 1):
                d = (xx - x) ** 2 + (yy - y) ** 2
                if d <= r * r + 1 and not (xx > x and yy == y):   # notch
                    px[xx, yy] = (C['olv_l'] if d < r * r - 1 else C['olv']) + (255,)
        if rnd.random() < 0.25:
            px[x - 1, y - 1] = C['pink'] + (255,)
            px[x, y - 1] = C['white'] + (255,)


def gen_maps():
    lines = ['# AUTO-GENERATED by tools/gen_art.py - do not edit by hand', 'class_name MapsData', 'extends RefCounted', '',
             'const ORDER = [%s]' % ', '.join('"%s"' % m['id'] for m in MAPS), '', 'const MAPS = {']
    for m in MAPS + [MENU_MAP]:
        cols = 40 if m['id'] == 'menu' else 32
        img, blocked, ptiles, special = bake_map(m, cols=cols)
        img.save(out(f'maps/{m["id"]}.png'))
        if m['id'] != 'menu':
            th = img.crop((0, 0, 512, 352)).resize((128, 88), Image.BOX)
            th.save(out(f'maps/{m["id"]}_thumb.png'))
        variants_txt = []
        for v in m.get('variants', []):
            vimg, vblocked, _, _ = bake_map(m, cols=cols, variant=v)
            assert vblocked == blocked, 'a seasonal variant must keep the layout'
            vimg.save(out(f'maps/{m["id"]}_{v}.png'))
            if m['id'] != 'menu':
                vimg.crop((0, 0, 512, 352)).resize((128, 88), Image.BOX).save(out(f'maps/{m["id"]}_{v}_thumb.png'))
            variants_txt.append('"%s": {"bg": "res://assets/maps/%s_%s.png", "thumb": "res://assets/maps/%s_%s_thumb.png"}'
                                % (v, m['id'], v, m['id'], v))
        rows_txt = []
        for y in range(23):
            rows_txt.append('"' + ''.join('1' if (x, y) in blocked else '0' for x in range(cols)) + '"')
        paths_txt = []
        for p in m['paths']:
            paths_txt.append('[' + ', '.join('Vector2(%d, %d)' % (x * T + 8, y * T + 8) for x, y in p) + ']')
        lines.append('\t"%s": {' % m['id'])
        lines.append('\t\t"name": "%s", "tier": "%s", "theme": "%s", "seed_idx": %d,' % (
            m['name'], m['tier'], m['theme'], m['seed_idx']))
        lines.append('\t\t"desc": "%s",' % m['desc'])
        lines.append('\t\t"bg": "res://assets/maps/%s.png", "thumb": "res://assets/maps/%s_thumb.png",' % (
            m['id'], m['id']))
        lines.append('\t\t"variants": {%s},' % ', '.join(variants_txt))
        lines.append('\t\t"paths": [%s],' % ', '.join(paths_txt))
        lines.append('\t\t"blocked": [%s],' % ', '.join(rows_txt))
        lava = sorted(t for t, k in special.items() if k == 'lava' and 0 <= t[0] < cols and 0 <= t[1] < 22)
        lines.append('\t\t"lava": [%s],' % ', '.join('Vector2i(%d, %d)' % t for t in lava))
        lines.append('\t},')
    lines.append('}')
    with open(os.path.join(ROOT, 'scripts/data/maps_data.gd'), 'w') as f:
        f.write('\n'.join(lines) + '\n')


if __name__ == '__main__':
    gen_sprites()
    gen_ui()
    gen_maps()
    print('ok')
