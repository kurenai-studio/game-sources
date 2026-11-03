"""Generate every sprite sheet, tile set, background and the app icon into Assets/Art/.

Usage (from the repository root, standard library only):
    python tools/art/build.py

All art is drawn here from ASCII templates and simple shapes, so it can be changed and
regenerated. Sheets are horizontal strips of equal frames; GameArt.cs slices them.
"""

import math
import pathlib
import random
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))

from image import Image, hex_color as C, mix  # noqa: E402

OUT = pathlib.Path(__file__).resolve().parents[2] / "Assets" / "Art"

INK = C("#24161a")


def outline(img, color=INK):
    """Darkens every filled pixel that touches transparency (a one-pixel inner outline)."""
    edge = []
    for y in range(img.height):
        for x in range(img.width):
            if img.get(x, y)[3] == 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if img.get(x + dx, y + dy)[3] == 0:
                    edge.append((x, y))
                    break
    for x, y in edge:
        img.set(x, y, color)


def strip(frames):
    w, h = frames[0].width, frames[0].height
    sheet = Image(w * len(frames), h)
    for i, f in enumerate(frames):
        sheet.paste(f, i * w, 0)
    return sheet


# ---------------------------------------------------------------- player

PLAYER = {
    "k": INK, "h": C("#1d1714"), "r": C("#c0392b"), "R": C("#80241d"),
    "s": C("#d8a070"), "S": C("#a8714a"), "y": C("#f2c440"), "Y": C("#a87a1c"),
    "w": C("#f3e7c9"), "b": C("#8c5a2b"), "d": C("#6b4426"), "f": C("#3a9a8a"),
}

HEAD = [
    "......ff........",
    ".......kkkk.....",
    "......khhhhk....",
    ".....khhhhhhk...",
    ".....krrrrrrk...",
    ".....khhsssskk..",
    ".....khyssksk...",
    ".....khhsssssk..",
    "......khsssSk...",
    ".......kSSk.....",
]

TORSO = [
    ".....kkrrrrkk...",
    "....krrrrrrrrk..",
    "....krRrrrrrssk.",
    "....krRrrrrrssk.",
    "....kykykykykk..",
    "....kkykykykyk..",
    "....krrrrrrrrk..",
    ".....krrrrrrk...",
]

LEGS = {
    "stand": [".....ks..sk.....", ".....ks..sk.....", ".....ks..sk.....", ".....ks..sk.....", ".....ks..sk.....", ".....dd..dd....."],
    "run0": [".....ks..sk.....", "....ks....sk....", "...ks......sk...", "..dd.......sk...", "...........dd...", "................"],
    "run1": [".....ks..sk.....", ".....ks.sk......", ".....kssk.......", "......ks.k......", "......ks.dd.....", "......dd........"],
    "run2": [".....ks..sk.....", "......ksks......", "......kssk......", ".....ks..sk.....", ".....ks..dd.....", ".....dd........."],
    "run3": [".....ks..sk.....", "....ks....sk....", "...ks......sk...", "...ks.......dd..", "...dd...........", "................"],
    "run4": [".....ks..sk.....", "......ks.sk.....", ".......kssk.....", "......k.sk......", ".....dd.sk......", "........dd......"],
    "run5": [".....ks..sk.....", "......ksks......", "......kssk......", ".....ks..sk.....", ".....dd..sk.....", ".........dd....."],
    "jump": [".....ks..sk.....", "....ks....sk....", "....dd...sk.....", ".........dd.....", "................", "................"],
    "fall": [".....ks..sk.....", ".....ks..sk.....", "....ks....sk....", "....dd....dd....", "................", "................"],
    "climb0": [".....ks..sk.....", ".....ks..sk.....", ".....dd..sk.....", "..........sk....", "..........dd....", "................"],
    "climb1": [".....ks..sk.....", ".....ks..sk.....", ".....ks..dd.....", "....ks..........", "....dd..........", "................"],
}

BOW = [(12, 9, "b"), (13, 10, "b"), (13, 11, "b"), (14, 12, "b"), (14, 13, "b"), (13, 14, "b"), (13, 15, "b"), (12, 16, "b"),
       (12, 10, "w"), (12, 11, "w"), (12, 12, "w"), (12, 13, "w"), (12, 14, "w"), (12, 15, "w")]


def player_frame(legs, bob=0, bow=True, draw=False, arms_up=False):
    img = Image(16, 24)
    top = bob
    img.stamp(0, top, HEAD, PLAYER)
    img.stamp(0, top + 10, TORSO, PLAYER)
    img.stamp(0, 18, LEGS[legs], PLAYER)
    if arms_up:
        for y in range(top + 6, top + 11):
            img.set(4, y, PLAYER["s"])
            img.set(11, y, PLAYER["s"])
        img.set(4, top + 5, PLAYER["k"])
        img.set(11, top + 5, PLAYER["k"])
    if bow:
        for x, y, ch in BOW:
            if draw and ch == "w":
                continue
            img.set(x - (2 if draw else 0) + (2 if draw else 0), y + top, PLAYER[ch])
        if draw:
            # String pulled back and an arrow nocked.
            img.set(10, top + 12, PLAYER["w"])
            img.set(11, top + 11, PLAYER["w"])
            img.set(11, top + 13, PLAYER["w"])
            for x in range(9, 16):
                img.set(x, top + 12, PLAYER["b"])
            img.set(15, top + 12, PLAYER["y"])
    return img


def player_sheet():
    frames = [
        player_frame("stand"), player_frame("stand", bob=1),
        player_frame("run0"), player_frame("run1", bob=1), player_frame("run2"),
        player_frame("run3"), player_frame("run4", bob=1), player_frame("run5"),
        player_frame("jump"), player_frame("fall"),
        player_frame("climb0", bow=False, arms_up=True), player_frame("climb1", bow=False, arms_up=True),
        player_frame("stand", draw=True), player_frame("fall", bow=False, arms_up=True),
    ]
    return strip(frames)


# ---------------------------------------------------------------- enemies

STONE = {"k": INK, "g": C("#8f8a80"), "G": C("#6a655d"), "l": C("#b4ada0"), "y": C("#ffd34d"),
         "r": C("#b0302a"), "c": C("#6b4426"), "C": C("#4a2e1a")}

WALKER_TOP = [
    "................",
    ".....kkkkkk.....",
    "....klllllgk....",
    "....kgykkgyk....",
    "....kggggggk....",
    "....kgkkkkgk....",
    ".....kggggk.....",
    "....kkrrrrkk....",
    "...klggggggGk.C.",
    "...kgGgllgGgkCc.",
    "...kggggggggkc..",
    "....kggGGggkc...",
    "....kgggggGk....",
]

WALKER_LEGS = [
    ["....kgk..kgk....", "....kgk..kgk....", "....kkk..kkk...."],
    ["...kgk...kgk....", "..kgk.....kgk...", "..kkk.....kkk..."],
    ["....kgk.kgk.....", ".....kgkgk......", ".....kkkkk......"],
    ["....kgk...kgk...", "...kgk.....kgk..", "...kkk.....kkk.."],
]


def walker_sheet():
    frames = []
    for i, legs in enumerate(WALKER_LEGS):
        img = Image(16, 16)
        bob = 1 if i % 2 else 0
        img.stamp(0, bob, WALKER_TOP, STONE)
        img.stamp(0, 13, legs, STONE)
        frames.append(img)
    return strip(frames)


BAT = {"k": INK, "p": C("#5b3a5e"), "P": C("#3b2440"), "e": C("#ff5a4a"), "w": C("#f0e0d0")}

BAT_FRAMES = [
    [
        "................",
        ".kk..........kk.",
        "kppk........kppk",
        "kpPpk..kk..kpPpk",
        ".kpPpkkppkkpPpk.",
        "..kpppkpekpppk..",
        "...kkkpppkkkk...",
        "......kwk.......",
        ".......k........",
    ],
    [
        "................",
        "................",
        "................",
        ".......kk.......",
        "kkkkkkkppkkkkkkk",
        "kpPPpppekppPPppk",
        ".kkkkkpppkkkkkk.",
        "......kwk.......",
        ".......k........",
    ],
    [
        "................",
        "................",
        "................",
        ".......kk.......",
        "......kppk......",
        "...kkkpekpkkk...",
        "..kpPpkpppkpPpk.",
        ".kpPpk.kwk.kpPpk",
        "kppk....k....kppk",
        ".kk..........kk.",
    ],
]


def bat_sheet():
    frames = []
    for rows in BAT_FRAMES:
        img = Image(16, 16)
        img.stamp(0, 3, rows, BAT)
        frames.append(img)
    return strip(frames)


def ellipse(img, cx, cy, rx, ry, color):
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1:
                img.set(x, y, color)


def puma_frame(pose):
    """The Stone Puma, 48x32, facing right. pose: idle0, idle1, run0-3, crouch, leap, hurt."""
    img = Image(48, 32)
    body = C("#a39c8c")
    dark = C("#77705f")
    gold = C("#e8b33a")
    eye = C("#ff4433")
    crouch = 3 if pose == "crouch" else 0
    lift = -3 if pose == "leap" else 0
    by = 17 + crouch + lift
    # Legs.
    phase = {"run0": 0, "run1": 1, "run2": 2, "run3": 3}.get(pose, -1)
    legs = [(14, 0), (19, 2), (31, 1), (36, 3)]
    for i, (lx, lp) in enumerate(legs):
        if pose == "leap":
            dx = -3 if i < 2 else 3
            img.rect(lx + dx, by + 4, 4, 6, dark if i % 2 else body)
            continue
        swing = 0 if phase < 0 else int(round(2 * math.sin((phase + lp) * math.pi / 2)))
        h = 31 - (by + 4) - crouch // 2
        img.rect(lx + swing, by + 4, 4, max(3, h), dark if i % 2 else body)
        img.rect(lx + swing - 1, by + 4 + max(3, h) - 2, 6, 2, dark if i % 2 else body)
    # Tail, curling up.
    for t in range(14):
        a = t / 13
        tx = int(12 - 9 * a)
        ty = int(by - 1 - 10 * math.sin(a * math.pi * 0.8) + (2 if pose == "idle1" and t > 9 else 0))
        img.rect(tx, ty, 3, 3, body)
    # Body and head.
    ellipse(img, 25, by + 2, 15, 7 - (1 if pose == "crouch" else 0), body)
    ellipse(img, 39, by - 3 + (1 if pose == "idle1" else 0), 7, 6, body)
    # Ears.
    img.rect(35, by - 10, 3, 3, body)
    img.rect(41, by - 10, 3, 3, body)
    outline(img)
    # Carved stone bands and a gold collar.
    for x in range(14, 36):
        if (x // 3) % 2 == 0:
            img.set(x, by + 2, gold)
    for x in range(14, 36, 5):
        img.rect(x, by - 2, 2, 1, dark)
        img.rect(x + 2, by + 5, 2, 1, dark)
    img.rect(32, by - 3, 2, 9, gold)
    # Face: glowing eye, nose, fangs.
    ey = by - 5 + (1 if pose == "idle1" else 0)
    img.rect(41, ey, 3, 2, eye)
    img.set(42, ey, C("#ffd0a0"))
    img.rect(45, ey + 3, 2, 2, INK)
    img.set(43, ey + 6, C("#f3e7c9"))
    img.set(45, ey + 6, C("#f3e7c9"))
    if pose == "hurt":
        for y in range(32):
            for x in range(48):
                c = img.get(x, y)
                if c[3]:
                    img.set(x, y, mix(c, C("#ffffff"), 0.55))
    return img


def puma_sheet():
    return strip([puma_frame(p) for p in ("idle0", "idle1", "run0", "run1", "run2", "run3", "crouch", "leap", "hurt")])


# ---------------------------------------------------------------- items

GOLD = C("#f2c440")
GOLD_DARK = C("#b07f1c")
GOLD_LIGHT = C("#fff2a8")


def coin_frame(width):
    img = Image(16, 16)
    rx = max(0.6, width / 2)
    ellipse(img, 8, 8, rx, 5.5, GOLD)
    if width >= 6:
        ellipse(img, 8, 8, rx - 1.6, 4, GOLD_DARK)
        ellipse(img, 8, 8, max(0.6, rx - 2.4), 3, GOLD)
        img.set(7, 6, GOLD_LIGHT)
    outline(img, C("#6e4a10"))
    if width >= 4:
        img.set(int(8 - rx / 2), 5, GOLD_LIGHT)
    return img


IDOL = [
    "......kkkk......",
    ".....kyyyyk.....",
    "....kyYyyYyk....",
    "....kykyykyk....",
    "....kyyyyyyk....",
    ".....kyYYyk.....",
    "...kkyyyyyykk...",
    "..kyykyyyykyyk..",
    "..kyk.kyyk.kyk..",
    "......kyyk......",
    ".....kyYYyk.....",
    ".....kykkyk.....",
    "....kyk..kyk....",
    "....kkk..kkk....",
]

SHELL = [
    "................",
    "...k..k..k..k...",
    "...okkokkokko...",
    "..kooOoooOook...",
    ".kOooooOooooOk..",
    "kooOooooooOoook.",
    "koooOooooOooook.",
    ".kooooOooOooook.",
    "..kooooooooook..",
    "...kkooooookk...",
    ".....kkwwkk.....",
    ".......kk.......",
]

HEART = [
    "..kkk...kkk.....",
    ".krrrk.krrrk....",
    "krwrrrkrrrrrk...",
    "krwrrrrrrrrrk...",
    "krrrrrrrrrrRk...",
    ".krrrrrrrrRk....",
    "..krrrrrrRk.....",
    "...krrrrRk......",
    "....krrRk.......",
    ".....kRk........",
    "......k.........",
]


def items_sheet():
    frames = [coin_frame(w) for w in (11, 9, 6, 2, 6, 9)]
    pal = {"k": C("#5a3a0c"), "y": GOLD, "Y": GOLD_DARK}
    for glint in (False, True):
        img = Image(16, 16)
        img.stamp(0, 1, IDOL, pal)
        if glint:
            for x, y in ((6, 3), (10, 9), (5, 8)):
                img.set(x, y, GOLD_LIGHT)
            img.set(12, 1, C("#ffffff"))
            img.set(13, 2, C("#ffffff"))
            img.set(11, 2, C("#ffffff"))
            img.set(12, 3, C("#ffffff"))
        frames.append(img)
    img = Image(16, 16)
    img.stamp(0, 2, SHELL, {"k": INK, "o": C("#e8643a"), "O": C("#b8382a"), "w": C("#f6dcc0")})
    frames.append(img)
    img = Image(16, 16)
    img.stamp(2, 2, HEART, {"k": INK, "r": C("#e8423a"), "R": C("#9a2228"), "w": C("#ffd0c8")})
    frames.append(img)
    # Rock.
    img = Image(16, 16)
    ellipse(img, 8, 8, 5, 4.5, C("#8f8a80"))
    ellipse(img, 7, 7, 2.5, 2, C("#b4ada0"))
    img.set(10, 10, C("#6a655d"))
    img.set(9, 11, C("#6a655d"))
    outline(img)
    frames.append(img)
    # Arrow, pointing right.
    img = Image(16, 16)
    for x in range(2, 13):
        img.set(x, 8, C("#9a6a38"))
    for x, y in ((13, 8), (14, 8), (12, 7), (12, 9), (13, 7), (13, 9)):
        img.set(x, y, C("#d0d0c8"))
    img.set(15, 8, C("#d0d0c8"))
    for x, y in ((1, 7), (2, 7), (1, 9), (2, 9), (0, 6), (0, 10), (3, 7), (3, 9)):
        img.set(x, y, C("#f3e7c9"))
    frames.append(img)
    # Small sparkle (for particles and the HUD).
    img = Image(16, 16)
    for d in range(-3, 4):
        img.set(8 + d, 8, C("#ffffff", 255 - abs(d) * 60))
        img.set(8, 8 + d, C("#ffffff", 255 - abs(d) * 60))
    frames.append(img)
    return strip(frames)


def checkpoint_sheet():
    """A carved huaca stone, unlit and lit (two flame frames)."""
    frames = []
    for state in ("off", "on0", "on1"):
        img = Image(16, 32)
        stone = C("#8f8a80")
        img.rect(4, 12, 8, 20, stone)
        img.rect(3, 28, 10, 4, stone)
        img.rect(5, 10, 6, 2, stone)
        outline(img)
        sun = GOLD if state != "off" else C("#5f5a52")
        ellipse(img, 8, 18, 2.6, 2.6, sun)
        for a in range(8):
            ang = a * math.pi / 4
            img.set(int(round(8 + math.cos(ang) * 4 - 0.5)), int(round(18 + math.sin(ang) * 4 - 0.5)), sun)
        img.rect(5, 24, 6, 1, C("#6a655d"))
        img.rect(5, 26, 6, 1, C("#6a655d"))
        if state != "off":
            flicker = 1 if state == "on1" else 0
            ellipse(img, 8, 6 + flicker, 3, 5 - flicker, C("#ff8a2a"))
            ellipse(img, 8, 7 + flicker, 1.8, 3 - flicker, C("#ffe070"))
        frames.append(img)
    return strip(frames)


def gate_sheet():
    """The Sun Gate: a trapezoidal Inca doorway in fitted stone. Closed, then open (two glow frames)."""
    frames = []
    for state in ("closed", "open0", "open1"):
        img = Image(32, 48)
        # Fitted ashlar frame.
        rng = random.Random(7)
        for y in range(48):
            for x in range(32):
                img.set(x, y, C("#b39a6a"))
        for row in range(0, 48, 6):
            img.rect(0, row, 32, 1, C("#6b5a3a"))
            offset = rng.randint(2, 8)
            for x in range(offset, 32, rng.randint(8, 11)):
                img.rect(x, row, 1, 6, C("#6b5a3a"))
        # Gold lintel band and a sun disc above the door.
        img.rect(0, 0, 32, 3, GOLD_DARK)
        ellipse(img, 16, 7, 4, 4, GOLD)
        ellipse(img, 16, 7, 2, 2, GOLD_LIGHT)
        # Trapezoid opening: narrower at the top.
        for y in range(14, 48):
            t = (y - 14) / 34
            half = int(round(6 + 4 * t))
            for x in range(16 - half, 16 + half):
                if state == "closed":
                    c = C("#2a2220") if (x + y) % 7 else C("#3a302a")
                else:
                    glow = 0.65 + 0.35 * (1 - abs(x - 16) / half) - (0.1 if state == "open1" else 0)
                    c = mix(C("#ffb02a"), C("#fff6c0"), max(0, min(1, glow - 0.2 * t)))
                img.set(x, y, c)
            img.set(16 - half - 1, y, C("#5a4a30"))
            img.set(16 + half, y, C("#5a4a30"))
        if state == "closed":
            # The seal: three golden idol slots that light as idols are found are drawn in game.
            img.rect(10, 28, 12, 1, C("#5a4a30"))
        outline(img)
        frames.append(img)
    return strip(frames)


# ---------------------------------------------------------------- tiles

THEMES = {
    # name: (stone, stone_dark, mortar, top, top_light, ledge, ledge_dark)
    "valley": ("#a48a68", "#86704f", "#5d4a33", "#5fae3e", "#93d45a", "#9a6a38", "#6b4426"),
    "mountain": ("#8a93a3", "#6c7585", "#474e5c", "#e6eef5", "#ffffff", "#8a6a48", "#5a4430"),
    "cave": ("#5e4a5a", "#4a3a48", "#2c2230", "#3fa58f", "#7ee0c0", "#7a5a40", "#4e3828"),
    "temple": ("#c9a25a", "#a8843e", "#6e5326", "#f2c440", "#fff0a0", "#8c3a2a", "#5e2418"),
}


def masonry(img, ox, theme, variant, top):
    stone, dark, mortar, grass, grass_light, _, _ = [C(c) for c in THEMES[theme]]
    rng = random.Random(variant * 101 + len(theme))
    img.rect(ox, 0, 16, 16, stone)
    # Polygonal fitted stones: two courses with offset joints.
    for course, (y0, y1) in enumerate(((0, 7), (8, 15))):
        joint = rng.randint(4, 11)
        img.rect(ox, y1, 16, 1, mortar)
        img.rect(ox + joint, y0, 1, y1 - y0, mortar)
        # Bevel: a light top edge and a dark bottom edge on each stone.
        for x in range(16):
            if x != joint:
                img.set(ox + x, y0 + (1 if course == 0 and top else 0), mix(stone, C("#ffffff"), 0.18))
                img.set(ox + x, y1 - 1, dark)
        for _ in range(3):
            img.set(ox + rng.randint(1, 14), rng.randint(y0 + 2, y1 - 2), dark)
    if top:
        img.rect(ox, 0, 16, 3, grass)
        for x in range(16):
            if rng.random() < 0.45:
                img.set(ox + x, 3, grass)
            if rng.random() < 0.3:
                img.set(ox + x, 0, grass_light)


def tiles_sheet():
    """One row per theme: top A, top B, inner A, inner B, inner C, ledge, ladder, spikes."""
    sheet = Image(16 * 8, 16 * len(THEMES))
    for row, theme in enumerate(THEMES):
        tile_row = Image(16 * 8, 16)
        masonry(tile_row, 0, theme, 1, True)
        masonry(tile_row, 16, theme, 2, True)
        masonry(tile_row, 32, theme, 3, False)
        masonry(tile_row, 48, theme, 4, False)
        masonry(tile_row, 64, theme, 5, False)
        _, _, _, _, _, ledge, ledge_dark = [C(c) for c in THEMES[theme]]
        # Ledge: a plank with rope lashings, 5 px thick at the top of the tile.
        tile_row.rect(80, 0, 16, 5, ledge)
        tile_row.rect(80, 4, 16, 1, ledge_dark)
        tile_row.rect(80, 0, 16, 1, mix(ledge, C("#ffffff"), 0.25))
        for x in (82, 91):
            tile_row.rect(x, 0, 2, 7, C("#d8c08a"))
        # Ladder: two rope rails and wooden rungs.
        tile_row.rect(98, 0, 2, 16, C("#c9ad78"))
        tile_row.rect(108, 0, 2, 16, C("#c9ad78"))
        for y in (2, 7, 12):
            tile_row.rect(99, y, 10, 2, ledge)
            tile_row.rect(99, y + 1, 10, 1, ledge_dark)
        # Spikes: three stone points in the lower half.
        for i in range(3):
            cx = 112 + 2 + i * 5
            for y in range(8, 16):
                half = (y - 8) // 3 + 1
                for x in range(cx + 2 - half, cx + 2 + half):
                    tile_row.set(x, y, C("#d0ccc0") if x < cx + 2 else C("#8a867c"))
            tile_row.set(cx + 1, 8, C("#ffffff"))
        sheet.paste(tile_row, 0, row * 16)
    return sheet


# ---------------------------------------------------------------- backgrounds

BG_W, BG_H = 320, 180


def gradient(img, top, bottom, y0=0, y1=None):
    y1 = img.height if y1 is None else y1
    for y in range(y0, y1):
        c = mix(top, bottom, (y - y0) / max(1, y1 - y0 - 1))
        for x in range(img.width):
            img.set(x, y, c)


def ridge(img, base, amp, color, seed, waves=(1, 2, 5), snow=None, period=BG_W):
    """A horizontally tileable mountain silhouette (period divides the width)."""
    rng = random.Random(seed)
    phases = [rng.random() * math.tau for _ in waves]
    for x in range(img.width):
        h = 0
        for k, (w, p) in enumerate(zip(waves, phases)):
            h += math.sin(x / period * math.tau * w + p) / (k + 1)
        top = int(base - amp * h)
        for y in range(max(0, top), img.height):
            img.set(x, y, color)
        if snow is not None:
            for y in range(max(0, top), min(img.height, top + 3 + int(2 * math.sin(x * 0.7)))):
                if top < base - amp * 0.4:
                    img.set(x, y, snow)


def sun(img, cx, cy, r, color, glow):
    for y in range(img.height):
        for x in range(img.width):
            d = math.hypot(x - cx, y - cy)
            if d < r * 2.6:
                a = max(0.0, 1 - d / (r * 2.6)) ** 2 * 0.5
                img.set(x, y, (*glow[:3], int(a * 255)))
    ellipse(img, cx, cy, r, r, color)


def terraces(img, seed):
    """Stepped green terraces (andenes) that tile horizontally."""
    rng = random.Random(seed)
    green, dark = C("#3e7a34"), C("#2c5a28")
    x = 0
    while x < img.width:
        w = rng.randint(80, 110)
        steps = rng.randint(3, 5)
        base = rng.randint(132, 146)
        for s in range(steps):
            y = base - s * 6
            x0 = x + s * 11
            x1 = x + w - s * 11
            for xx in range(x0, min(x1, img.width)):
                for yy in range(y, img.height):
                    img.set(xx, yy, green if s % 2 == 0 else mix(green, C("#5fae3e"), 0.3))
                img.set(xx, y, C("#93d45a"))
                img.set(xx, y + 1, dark)
        x += w - 20
    for xx in range(img.width):
        for yy in range(150, img.height):
            img.set(xx, yy, C("#2c5a28"))


def background(theme):
    far = Image(BG_W, BG_H)
    near = Image(BG_W, BG_H)
    if theme == "valley":
        gradient(far, C("#f6a65a"), C("#ffe2a8"), 0, 110)
        gradient(far, C("#ffe2a8"), C("#ffeccc"), 110, BG_H)
        sun(far, 230, 70, 18, C("#fff2b0"), C("#ffd070"))
        ridge(far, 105, 28, C("#7d6a8e"), 3, snow=C("#f4ecf6"))
        ridge(far, 125, 18, C("#5e5878"), 4)
        terraces(near, 5)
    elif theme == "mountain":
        gradient(far, C("#5c8fd0"), C("#cfe6f5"), 0, BG_H)
        for cx, cy in ((60, 40), (200, 30), (280, 55)):
            for i in range(5):
                ellipse(far, cx + i * 7 - 14, cy + (i % 2) * 3, 9, 5, C("#ffffff", 210))
        ridge(far, 95, 45, C("#7a88a8"), 8, waves=(1, 3, 4), snow=C("#ffffff"))
        ridge(far, 120, 25, C("#5a6684"), 9, snow=C("#e8eef8"))
        ridge(near, 140, 22, C("#3a4258"), 10, waves=(2, 3, 7))
    elif theme == "cave":
        gradient(far, C("#140e18"), C("#2a1e2c"), 0, BG_H)
        rng = random.Random(4)
        for _ in range(60):
            far.set(rng.randrange(BG_W), rng.randrange(BG_H), C("#3fa58f", rng.randint(60, 180)))
        for x in range(0, BG_W, 23):
            length = 20 + (x * 7) % 35
            for y in range(length):
                half = max(0, int((1 - y / length) * 5))
                for dx in range(-half, half + 1):
                    far.set(x + dx, y, C("#241a26"))
        for x in range(0, BG_W, 64):
            for y in range(BG_H):
                half = 8 + int(3 * math.sin(y * 0.08 + x))
                for dx in range(-half, half):
                    near.set(x + 30 + dx, y, C("#1e1620", 230))
    else:  # temple
        gradient(far, C("#7a1e2e"), C("#f2a040"), 0, 120)
        gradient(far, C("#f2a040"), C("#ffd27a"), 120, BG_H)
        for i in range(16):
            ang = i * math.tau / 16
            for r in range(30, 160):
                x = int(160 + math.cos(ang) * r)
                y = int(95 + math.sin(ang) * r)
                far.set(x, y, C("#ffd27a", 70))
                far.set(x + 1, y, C("#ffd27a", 40))
        sun(far, 160, 95, 26, C("#ffe680"), C("#ffb040"))
        ridge(far, 140, 15, C("#5a2a2a"), 12)
        # Stepped temple walls with trapezoid doors, tileable.
        for bx in range(0, BG_W, 80):
            for s in range(3):
                near.rect(bx + 10 + s * 8, 128 - s * 12, 60 - s * 16, BG_H, C("#4a2418") if s % 2 == 0 else C("#5a2c1e"))
            for d in range(3):
                dx = bx + 22 + d * 14
                for y in range(140, 156):
                    t = (y - 140) / 16
                    half = int(2 + 2 * t)
                    for x in range(dx - half, dx + half):
                        near.set(x, y, C("#2a120c"))
    return far, near


# ---------------------------------------------------------------- icon

def icon():
    """Inti: a golden sun face, 32x32 pixels scaled to 512."""
    img = Image(32, 32)
    for i in range(16):
        ang = i * math.tau / 16
        long = i % 2 == 0
        for r in range(9, 15 if long else 13):
            x = 16 + math.cos(ang) * r - 0.5
            y = 16 + math.sin(ang) * r - 0.5
            img.set(int(round(x)), int(round(y)), GOLD if long else GOLD_DARK)
            if long:
                img.set(int(round(x + math.sin(ang))), int(round(y - math.cos(ang))), GOLD)
    ellipse(img, 16, 16, 9.5, 9.5, GOLD)
    ellipse(img, 16, 16, 7.5, 7.5, C("#f6d060"))
    outline(img, C("#6e4a10"))
    face = C("#8a5a12")
    for x, y in ((12, 13), (13, 13), (19, 13), (20, 13)):
        img.set(x, y, face)
    img.set(12, 14, INK)
    img.set(20, 14, INK)
    img.rect(16, 14, 1, 4, face)
    img.rect(13, 20, 7, 1, face)
    img.set(12, 19, face)
    img.set(20, 19, face)
    for x, y in ((10, 17), (22, 17)):
        img.set(x, y, C("#e8642a"))
    return img.scaled(16)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    jobs = {
        "Player.png": player_sheet(),
        "Walker.png": walker_sheet(),
        "Bat.png": bat_sheet(),
        "StonePuma.png": puma_sheet(),
        "Items.png": items_sheet(),
        "Checkpoint.png": checkpoint_sheet(),
        "SunGate.png": gate_sheet(),
        "Tiles.png": tiles_sheet(),
        "AppIcon.png": icon(),
    }
    for theme in THEMES:
        far, near = background(theme)
        jobs[f"Background_{theme}_far.png"] = far
        jobs[f"Background_{theme}_near.png"] = near
    for name, img in jobs.items():
        img.save(str(OUT / name))
        print("built", name, f"{img.width}x{img.height}")


if __name__ == "__main__":
    main()
