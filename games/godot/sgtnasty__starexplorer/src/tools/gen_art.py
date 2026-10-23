#!/usr/bin/env python3
# StarExplorer - pixel art generator
# Copyright (C) 2026 StarExplorer contributors
# SPDX-License-Identifier: GPL-3.0-only
#
# Regenerates every sprite in assets/sprites from code, so the art is
# reproducible and editable as text. Requires Pillow:
#
#     python3 tools/gen_art.py
#
# Ships are drawn as ASCII pixel maps (top half only; the bottom half is
# mirrored). Planets, the starbase and the monster are drawn procedurally
# from a fixed seed so the output is identical on every run.

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets" / "sprites"


def hexc(s, a=255):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


CLEAR = (0, 0, 0, 0)


# --------------------------------------------------------------------------
# Ships: ASCII maps, 24 px wide. Only rows above the centre line are given;
# the centre row is listed last and the top rows are mirrored beneath it.
# --------------------------------------------------------------------------

SHIPS = {
    "ship_player": {
        "palette": {
            "a": "#1d2b53", "b": "#c2c3c7", "c": "#83769c", "d": "#29adff",
            "e": "#ffa300", "f": "#ffec27", "g": "#5f574f",
        },
        "rows": [
            "........................",
            "......aaa...............",
            "......abfa..............",
            ".....abbbfaaa...........",
            "..aaabcbbbbbbaaaa.......",
            "eeagccbbbbbbbbbbbaaa....",
            "eeagccbbbbbbbbbbddddaa..",
            "eeagccbbffffffbbddddbbba",
        ],
    },
    "ship_pirate": {
        "palette": {
            "a": "#1a0a10", "b": "#5f574f", "c": "#3b2a33", "d": "#ff004d",
            "e": "#ff77a8", "f": "#ab5236", "g": "#000000",
        },
        "rows": [
            "..aa....................",
            "..afa...................",
            "..abfa.......aa.........",
            "...abfaaaaaaafda........",
            "....abbbbbbbbbbbaa......",
            "eeaacbbbbbbbbbbbbbaaa...",
            "eeacccbbbbbbbbbbbddddaa.",
            "eeacccbbbbddddbbbbbbbbba",
        ],
    },
    "ship_trader": {
        "palette": {
            "a": "#1d2b53", "b": "#ab5236", "c": "#ffccaa", "d": "#29adff",
            "e": "#ffa300", "f": "#008751", "g": "#ffec27",
        },
        "rows": [
            "........................",
            "........................",
            "...aaaaaaaaaaaaa........",
            "...afffafffafffa........",
            "...afgfafgfafgfa........",
            "eeaaaaaaaaaaaaaaaaaaa...",
            "eeabbbbbbbbbbbbbbbbddaa.",
            "eeabcbcbcbcbcbcbbbbddbba",
        ],
    },
    "ship_patrol": {
        "palette": {
            "a": "#1d2b53", "b": "#fff1e8", "c": "#c2c3c7", "d": "#29adff",
            "e": "#29adff", "f": "#ff004d", "g": "#1d2b53",
        },
        "rows": [
            "........................",
            "....aaaa................",
            "....abbba...............",
            "....abfbbaa.............",
            "...aabbbbbbaaaaaa.......",
            "eeaccbbbbbbbbbbbbaaaa...",
            "eeaccbbbbbbbbbbbbbddda..",
            "eeaccddddddddddddbdddbba",
        ],
    },
}


def draw_ship(spec):
    pal = {k: hexc(v) for k, v in spec["palette"].items()}
    rows = spec["rows"]
    full = rows + rows[-2::-1]
    w, h = len(full[0]), len(full)
    img = Image.new("RGBA", (w, h), CLEAR)
    for y, row in enumerate(full):
        for x, ch in enumerate(row):
            if ch != ".":
                img.putpixel((x, y), pal[ch])
    # pad to a 32x24 canvas, centred, so all ships share one size
    canvas = Image.new("RGBA", (32, 24), CLEAR)
    canvas.paste(img, ((32 - w) // 2, (24 - h) // 2))
    return canvas


# --------------------------------------------------------------------------
# Planets: 32x32 spheres shaded from the top-left with value noise.
# --------------------------------------------------------------------------

PLANETS = {
    "barren": ["#3b3333", "#5f574f", "#8a7f74", "#b0a596"],
    "rocky": ["#422136", "#7e2553", "#ab5236", "#e0855a"],
    "ice": ["#1d2b53", "#5a8ac0", "#a8e4ff", "#fff1e8"],
    "gas_giant": ["#5c2d0a", "#ab5236", "#ffa300", "#ffccaa"],
    "ocean": ["#0b1a40", "#1d2b53", "#29adff", "#9ee6ff"],
    "jungle": ["#0f2d1c", "#008751", "#00b543", "#a8e72e"],
    "volcanic": ["#1a0a10", "#3b2a33", "#ff004d", "#ffa300"],
    "crystal": ["#2a1240", "#83769c", "#c070ff", "#ffccff"],
}


def value_noise(rng, size=8):
    grid = [[rng.random() for _ in range(size + 1)] for _ in range(size + 1)]

    def sample(u, v):
        x, y = u * size, v * size
        x0, y0 = int(x), int(y)
        fx, fy = x - x0, y - y0
        x1, y1 = min(x0 + 1, size), min(y0 + 1, size)
        a = grid[y0][x0] * (1 - fx) + grid[y0][x1] * fx
        b = grid[y1][x0] * (1 - fx) + grid[y1][x1] * fx
        return a * (1 - fy) + b * fy

    return sample


def draw_planet(kind, shades, seed):
    rng = random.Random(seed)
    noise = value_noise(rng, 6)
    noise2 = value_noise(rng, 12)
    pal = [hexc(s) for s in shades]
    size, cx, cy, r = 32, 15.5, 15.5, 14.0
    img = Image.new("RGBA", (size, size), CLEAR)
    for y in range(size):
        for x in range(size):
            dx, dy = x - cx, y - cy
            d = math.hypot(dx, dy)
            if d > r:
                continue
            u, v = x / size, y / size
            if kind == "gas_giant":
                n = 0.5 + 0.5 * math.sin(v * 22 + noise(u, v) * 3)
            else:
                n = 0.65 * noise(u, v) + 0.35 * noise2(u, v)
            # light from the upper left
            light = 1.0 - ((dx + dy) / (2 * r) + 0.5) * 0.9
            val = n * 0.55 + light * 0.6
            if kind == "crystal" and rng.random() < 0.06:
                val = 1.0
            if kind == "ocean" and noise2(u, v) > 0.72:
                val = max(val, 0.8)  # cloud wisps
            idx = max(0, min(3, int(val * 4)))
            if d > r - 1.2:  # dark rim
                idx = max(0, idx - 1)
            img.putpixel((x, y), pal[idx])
    return img


# --------------------------------------------------------------------------
# Starbase, monster, resource icons, app icon.
# --------------------------------------------------------------------------


def draw_starbase():
    img = Image.new("RGBA", (48, 48), CLEAR)
    d = ImageDraw.Draw(img)
    dark, mid, light, lamp = hexc("#1d2b53"), hexc("#83769c"), hexc("#c2c3c7"), hexc("#ffec27")
    d.ellipse((4, 4, 43, 43), outline=mid, width=3)
    d.ellipse((5, 5, 42, 42), outline=light, width=1)
    for ang in range(0, 360, 45):
        rad = math.radians(ang)
        x, y = 24 + math.cos(rad) * 19, 24 + math.sin(rad) * 19
        d.line((24, 24, x, y), fill=mid, width=1)
        d.rectangle((x - 1, y - 1, x + 1, y + 1), fill=lamp if ang % 90 == 0 else light)
    d.rectangle((18, 18, 29, 29), fill=dark, outline=light)
    d.rectangle((21, 21, 26, 26), fill=hexc("#29adff"))
    d.line((24, 0, 24, 6), fill=light)
    d.point((24, 0), fill=hexc("#ff004d"))
    return img


def draw_monster():
    rng = random.Random(77)
    img = Image.new("RGBA", (48, 40), CLEAR)
    d = ImageDraw.Draw(img)
    body, dark, glow, eye = hexc("#7e2553"), hexc("#422136"), hexc("#ff77a8"), hexc("#ffec27")
    # tentacles trailing to the right
    for i in range(5):
        y0 = 12 + i * 4
        pts = []
        for t in range(14):
            x = 22 + t * 1.8
            y = y0 + math.sin(t * 0.7 + i) * 2.5 + (i - 2) * t * 0.25
            pts.append((x, y))
        d.line(pts, fill=dark, width=2)
        d.line(pts, fill=body, width=1)
    d.ellipse((2, 8, 30, 32), fill=dark)
    d.ellipse((3, 9, 28, 30), fill=body)
    for _ in range(14):
        x, y = rng.randint(6, 26), rng.randint(11, 28)
        d.point((x, y), fill=glow)
    d.ellipse((7, 14, 15, 22), fill=eye)
    d.ellipse((9, 16, 12, 20), fill=hexc("#000000"))
    d.line((4, 26, 12, 24), fill=hexc("#000000"))  # maw
    return img


def draw_resource_icons():
    icons = {}
    shapes = {
        "iron": ("#c2c3c7", "#5f574f", "rock"),
        "ice": ("#a8e4ff", "#29adff", "diamond"),
        "hydrogen": ("#ffb0e0", "#ff77a8", "ball"),
        "organics": ("#6ad35a", "#008751", "leaf"),
        "uranium": ("#d4ff3a", "#008751", "rod"),
        "crystals": ("#c070ff", "#83769c", "diamond"),
        "exotic": ("#ff5adc", "#7e2553", "star"),
    }
    for rid, (light, dark, shape) in shapes.items():
        img = Image.new("RGBA", (8, 8), CLEAR)
        d = ImageDraw.Draw(img)
        lc, dc = hexc(light), hexc(dark)
        if shape == "rock":
            d.polygon([(1, 5), (2, 2), (5, 1), (7, 3), (6, 6), (3, 7)], fill=dc)
            d.polygon([(2, 4), (3, 2), (5, 2), (5, 4)], fill=lc)
        elif shape == "diamond":
            d.polygon([(4, 0), (7, 4), (4, 7), (1, 4)], fill=dc)
            d.polygon([(4, 1), (5, 4), (4, 5), (2, 4)], fill=lc)
        elif shape == "ball":
            d.ellipse((1, 1, 6, 6), fill=dc)
            d.ellipse((2, 2, 4, 4), fill=lc)
        elif shape == "leaf":
            d.ellipse((1, 2, 6, 6), fill=dc)
            d.line((2, 6, 6, 2), fill=lc)
        elif shape == "rod":
            d.rectangle((2, 0, 5, 7), fill=dc)
            d.rectangle((3, 1, 4, 6), fill=lc)
        elif shape == "star":
            d.polygon([(4, 0), (5, 3), (7, 4), (5, 5), (4, 7), (3, 5), (0, 4), (3, 3)], fill=lc)
            d.point((4, 4), fill=dc)
        icons[rid] = img
    return icons


def draw_icon(ship):
    img = Image.new("RGBA", (64, 64), hexc("#0b0e1a"))
    rng = random.Random(5)
    for _ in range(40):
        img.putpixel((rng.randrange(64), rng.randrange(64)), hexc("#5f6b99"))
    big = ship.resize((64, 48), Image.NEAREST)
    img.alpha_composite(big, (0, 8))
    return img


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    ships = {}
    for name, spec in SHIPS.items():
        ships[name] = draw_ship(spec)
        ships[name].save(OUT / f"{name}.png")
    for i, (kind, shades) in enumerate(PLANETS.items()):
        draw_planet(kind, shades, 1000 + i).save(OUT / f"planet_{kind}.png")
    draw_starbase().save(OUT / "starbase.png")
    draw_monster().save(OUT / "monster.png")
    for rid, img in draw_resource_icons().items():
        img.save(OUT / f"res_{rid}.png")
    draw_icon(ships["ship_player"]).save(OUT.parent.parent / "icon.png")
    print(f"wrote sprites to {OUT}")


if __name__ == "__main__":
    main()
