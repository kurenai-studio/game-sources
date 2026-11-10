"""Paints every picture in HotDog Sports Day into assets/art/.

    python tools/gen_art.py            everything
    python tools/gen_art.py dogs face  just some parts (dogs, wardrobe, face,
                                       flags, crowd, stadium, fx, ui, icon)

Needs numpy, scipy and Pillow. Every piece comes from pix.py (the one pen),
palette.py (the only colours) and the part's own module.
"""
import json
import math
import random
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import dogs  # noqa: E402
import faces  # noqa: E402
import palette as P  # noqa: E402
import pix  # noqa: E402
import wardrobe  # noqa: E402

ROOT = HERE.parent
ART = ROOT / "assets" / "art"
COLS = 8


def save(img, rel):
    path = ART / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)
    return path


def save_json(data, rel):
    path = ART / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=1, sort_keys=True))


# -- the athletes ------------------------------------------------------------------

def gen_dogs():
    specs = dogs.frame_specs()

    def layer_sheet(parts, rel):
        frames = [dogs.paint_layer(parts, xf) for _, xf in specs]
        save(pix.sheet(frames, COLS), rel)

    for name in dogs.SAUSAGES:
        layer_sheet(dogs.sausage_layer(name), f"dogs/sausage_{name}.png")
    for name in dogs.BUNS:
        back, front = dogs.bun_layers(name)
        if back:
            layer_sheet(back, f"dogs/bun_back_{name}.png")
        if front:
            layer_sheet(front, f"dogs/bun_{name}.png")
    for name in dogs.TOPPINGS:
        layer_sheet(dogs.topping_layer(name), f"dogs/top_{name}.png")
    layer_sheet(dogs.band_layer("frank"), "dogs/band.png")
    layer_sheet(dogs.band_layer("corn"), "dogs/band_corn.png")
    layer_sheet(dogs.band_layer("lorne"), "dogs/band_lorne.png")

    frames = []
    for i, (name, xf) in enumerate(specs):
        spin = name.startswith("spin")
        r, c = divmod(i, COLS)
        frames.append({
            "name": name,
            "cell": [c * dogs.CELL[0], r * dogs.CELL[1]],
            # where the athlete's bounce point (upright) or middle (spinning) is in the cell
            "origin": [dogs.FOOT[0], dogs.FOOT[1]] if not spin else [dogs.CELL[0] / 2, dogs.CELL[1] / 2],
            "anchors": dogs.anchors_for(xf),
            "angle": round(float(np.degrees(xf.rot)), 2),
            "squash": round(float(xf.sy), 3),
        })
    save_json({
        "cell": list(dogs.CELL),
        "cols": COLS,
        "frames": frames,
        "sausages": list(dogs.SAUSAGES),
        "buns": dogs.BUNS,
        "toppings": dogs.TOPPINGS,
        "backs": [n for n in dogs.BUNS if dogs.bun_layers(n)[0]],
        "fronts": [n for n in dogs.BUNS if dogs.bun_layers(n)[1]],
        "band_keys": {"main": [list(c) for c in P.BAND_KEY_MAIN], "stripe": [list(c) for c in P.BAND_KEY_STRIPE]},
        "teams": {k: [list(c) for c in v] for k, v in P.TEAM.items()},
    }, "dogs/dogs.json")
    print("dogs: %d frames, %d sausages, %d buns, %d toppings" % (len(specs), len(dogs.SAUSAGES), len(dogs.BUNS),
                                                                 len(dogs.TOPPINGS)))


# -- the wardrobe: hats and outfits, each its own layer sheet ------------------------

def gen_wardrobe():
    specs = wardrobe.frame_specs()

    def layer_sheet(parts, rel):
        frames = [wardrobe.paint_layer(parts, xf) for _, xf in specs]
        save(pix.sheet(frames, COLS), rel)

    for name, make in wardrobe.HATS.items():
        layer_sheet(make(), f"wardrobe/hat_{name}.png")
    backs, fronts = [], []
    for name, make in wardrobe.OUTFITS.items():
        back, front = make()
        if back:
            layer_sheet(back, f"wardrobe/out_back_{name}.png")
            backs.append(name)
        if front:
            layer_sheet(front, f"wardrobe/out_{name}.png")
            fronts.append(name)
    save_json({
        "cell": list(wardrobe.CELL),
        "offset": list(wardrobe.OFFSET),
        "cols": COLS,
        "hats": list(wardrobe.HATS),
        "outfits": list(wardrobe.OUTFITS),
        "backs": backs,
        "fronts": fronts,
        "hair_shows": wardrobe.HAIR_SHOWS,
    }, "wardrobe/wardrobe.json")
    print("wardrobe: %d hats, %d outfits" % (len(wardrobe.HATS), len(wardrobe.OUTFITS)))


# -- faces: one atlas of stamps -------------------------------------------------------

def gen_face():
    groups = {"eyes": faces.EYES, "mouth": faces.MOUTHS, "brow": faces.BROWS, "specs": faces.SPECS,
              "tache": faces.TACHES, "hair": faces.HAIR, "mullet": {"mullet": faces.MULLET},
              "cheek": {"cheek": faces.CHEEK}}
    stamps = []
    for g, d in groups.items():
        for name, rows in d.items():
            if not rows:
                continue
            w = max(len(r) for r in rows)
            rows = [r.ljust(w, ".") for r in rows]
            stamps.append((g, name, rows))
    W = 128
    x = y = rowh = 0
    placed = []
    for g, name, rows in stamps:
        w, h = len(rows[0]), len(rows)
        if x + w > W:
            x, y, rowh = 0, y + rowh + 1, 0
        placed.append((g, name, rows, x, y))
        x += w + 1
        rowh = max(rowh, h)
    H = y + rowh
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    index = {}
    for g, name, rows, x, y in placed:
        w, h = len(rows[0]), len(rows)
        pix.stamp(img, rows, faces.PAL, (x + w / 2, y + h / 2))
        index.setdefault(g, {})[name] = [x, y, w, h]
    save(img, "face/face.png")
    save_json(index, "face/face.json")
    print("face: %d stamps" % len(placed))


# -- flags ------------------------------------------------------------------------

def _flag(code, w, h):
    F = P.FLAG
    a = np.zeros((h, w, 3), np.uint8)
    Y, X = np.mgrid[0:h, 0:w]

    def band_h(cols):
        n = len(cols)
        for i, c in enumerate(cols):
            a[(Y * n // h) == i] = F[c]

    def band_v(cols):
        n = len(cols)
        for i, c in enumerate(cols):
            a[(X * n // w) == i] = F[c]

    def disc(cx, cy, r, c):
        a[((X + 0.5 - cx) ** 2 + (Y + 0.5 - cy) ** 2) <= r * r] = F[c]

    if code == "usa":
        for i in range(h):
            a[i] = F["red"] if (i * 7 // h) % 2 == 0 else F["white"]
        cw, ch = int(w * 0.45), int(h * 4 / 7 + 0.5)
        a[:ch, :cw] = F["navy"]
        for yy in range(1, ch - 0, 2):
            for xx in range(1 + (yy // 2) % 2, cw - 1, 2):
                a[yy, xx] = F["white"]
    elif code == "ger":
        band_h(["black", "red", "gold"])
    elif code == "den":
        a[:] = F["red"]
        t = max(1, h // 5)
        a[h // 2 - t // 2:h // 2 - t // 2 + t, :] = F["white"]
        cx = int(w * 0.36)
        a[:, cx - t // 2:cx - t // 2 + t] = F["white"]
    elif code == "kor":
        a[:] = F["white"]
        r = h * 0.26
        cx, cy = w / 2, h / 2
        top = (Y + 0.5) < cy + np.sin((X + 0.5 - cx) / r * 1.6) * r * 0.35
        m = ((X + 0.5 - cx) ** 2 + (Y + 0.5 - cy) ** 2) <= r * r
        a[m & top] = F["red"]
        a[m & ~top] = F["blue"]
        for (tx, ty) in ((0.16, 0.2), (0.84, 0.2), (0.16, 0.8), (0.84, 0.8)):
            px_, py_ = int(tx * w), int(ty * h)
            a[max(0, py_ - 1):py_ + 1, max(0, px_ - 1):px_ + 1] = F["black"]
    elif code == "jpn":
        a[:] = F["white"]
        disc(w / 2, h / 2, h * 0.3, "red")
    elif code in ("gbr", "aus"):
        a[:] = F["navy"]
        uw, uh = (w, h) if code == "gbr" else (w // 2, h // 2)
        sub = a[:uh, :uw]
        yy, xx = np.mgrid[0:uh, 0:uw]
        d1 = np.abs((xx + 0.5) / uw - (yy + 0.5) / uh)
        d2 = np.abs((xx + 0.5) / uw - (1 - (yy + 0.5) / uh))
        sub[(d1 < 0.12) | (d2 < 0.12)] = F["white"]
        sub[(d1 < 0.05) | (d2 < 0.05)] = F["red"]
        tw, th = max(1, uw // 5), max(1, uh // 5)
        sub[uh // 2 - th // 2 - 1:uh // 2 + th // 2 + 1 + (th % 2), :] = F["white"]
        sub[:, uw // 2 - tw // 2 - 1:uw // 2 + tw // 2 + 1 + (tw % 2)] = F["white"]
        sub[uh // 2 - th // 2:uh // 2 + th // 2 + (th % 2), :] = F["red"]
        sub[:, uw // 2 - tw // 2:uw // 2 + tw // 2 + (tw % 2)] = F["red"]
        if code == "aus":
            for (tx, ty) in ((0.25, 0.75), (0.75, 0.25), (0.62, 0.5), (0.75, 0.82), (0.87, 0.42)):
                a[int(ty * h), int(tx * w)] = F["white"]
                if w > 20:
                    a[int(ty * h) - 1, int(tx * w)] = F["white"]
    elif code == "mex":
        band_v(["green", "white", "red"])
        disc(w / 2, h / 2, h * 0.16, "gold")
    elif code == "bra":
        a[:] = F["green"]
        cx, cy = w / 2, h / 2
        m = np.abs(X + 0.5 - cx) / (w * 0.42) + np.abs(Y + 0.5 - cy) / (h * 0.40) <= 1.0
        a[m] = F["yellow"]
        disc(cx, cy, h * 0.22, "navy")
    elif code == "fra":
        band_v(["blue", "white", "red"])
    elif code == "chi":
        band_h(["white", "red"])
        a[:h // 2, :int(w / 3 + 0.5)] = F["blue"]
        cx, cy = w / 6, h / 4
        a[int(cy), int(cx)] = F["white"]
        if w > 20:
            a[int(cy) - 1:int(cy) + 2, int(cx)] = F["white"]
            a[int(cy), int(cx) - 1:int(cx) + 2] = F["white"]
    elif code == "cze":
        band_h(["white", "red"])
        tri = (X + 0.5) < (w / 2) * (1 - np.abs((Y + 0.5) - h / 2) / (h / 2))
        a[tri] = F["blue"]
    elif code == "jam":
        u = (X + 0.5) / w - 0.5
        v = (Y + 0.5) / h - 0.5
        side = np.abs(u) * h > np.abs(v) * w      # left and right triangles
        a[side] = F["black"]
        a[~side] = F["green"]
        d1 = np.abs(u * h - v * w) / np.hypot(w, h)
        d2 = np.abs(u * h + v * w) / np.hypot(w, h)
        a[(d1 < 0.09) | (d2 < 0.09)] = F["gold"]
    elif code == "eng":       # St George's cross
        a[:] = F["white"]
        t = max(1, round(h / 5))
        a[(h - t) // 2:(h - t) // 2 + t, :] = F["red"]
        a[:, (w - t) // 2:(w - t) // 2 + t] = F["red"]
    elif code in ("sco", "nir"):   # St Andrew's saltire; St Patrick's for Northern Ireland
        a[:] = F["saltire"] if code == "sco" else F["white"]
        u = (X + 0.5) / w
        v = (Y + 0.5) / h
        d = np.minimum(np.abs(u - v), np.abs(u - (1 - v)))
        a[d < (0.13 if w < 20 else 0.1)] = F["white"] if code == "sco" else F["red"]
    elif code == "irl":
        band_v(["green", "white", "orange"])
    elif code == "wal":       # Y Ddraig Goch: the red dragon over white and green
        band_h(["white", "leaf"])
        a[_dragon(w, h)] = F["dragon"]
    elif code == "ngc":       # the Night Giraffe Game Cooperative's own colours
        a[:] = F["black"]
        a[h - max(2, h // 4):, :] = P.hx("#c0007a")
        disc(w * 0.72, h * 0.32, h * 0.18, "white")
    else:
        raise KeyError(code)
    img = np.zeros((h + 2, w + 2, 4), np.uint8)
    img[..., :3] = P.INK
    img[..., 3] = 255
    img[1:-1, 1:-1, :3] = a
    # a little light from the upper left on the cloth
    img[1, 1:-1, :3] = np.clip(img[1, 1:-1, :3].astype(int) + 28, 0, 255)
    img[-2, 1:-1, :3] = np.clip(img[-2, 1:-1, :3].astype(int) - 30, 0, 255)
    return img


def _dragon(w, h):
    """The Welsh dragon, passant, facing the pole: a mask, from shapes drawn on
    the unit square so it holds together at every flag size."""
    Y, X = np.mgrid[0:h, 0:w]
    u = (X + 0.5) / w
    v = (Y + 0.5) / h
    k = h / w

    def ell(cx, cy, rx, ry):
        return ((u - cx) / rx) ** 2 + ((v - cy) / ry) ** 2 <= 1.0

    def seg(ax, ay, bx, by, r):
        # distance to a segment, measured in flag heights so it isn't squashed
        px, py = (u - ax) / k, v - ay
        qx, qy = (bx - ax) / k, by - ay
        t = np.clip((px * qx + py * qy) / max(qx * qx + qy * qy, 1e-9), 0, 1)
        return (px - t * qx) ** 2 + (py - t * qy) ** 2 <= r * r

    def poly(pts):
        inside = np.zeros(u.shape, bool)
        for (x1, y1), (x2, y2) in zip(pts, pts[1:] + pts[:1]):
            cross = ((y1 > v) != (y2 > v)) & (u < (x2 - x1) * (v - y1) / ((y2 - y1) or 1e-9) + x1)
            inside ^= cross
        return inside

    m = ell(0.53, 0.58, 0.21, 0.12)                                   # body
    m |= ell(0.36, 0.55, 0.08, 0.11)                                  # chest
    m |= seg(0.34, 0.50, 0.26, 0.35, 0.065)                           # neck
    m |= ell(0.22, 0.30, 0.075, 0.075)                                # head
    m |= seg(0.21, 0.27, 0.10, 0.27, 0.035)                           # upper jaw
    m |= seg(0.20, 0.34, 0.11, 0.40, 0.03)                            # lower jaw, open
    m |= seg(0.25, 0.25, 0.30, 0.17, 0.025)                           # ear
    m |= poly([(0.40, 0.52), (0.41, 0.06), (0.50, 0.25), (0.57, 0.05), (0.62, 0.25),
               (0.71, 0.09), (0.71, 0.52)])                           # the wing, three points
    m |= seg(0.36, 0.62, 0.26, 0.66, 0.04)                            # the raised foreleg
    m |= seg(0.26, 0.66, 0.23, 0.73, 0.025)
    m |= seg(0.43, 0.66, 0.43, 0.87, 0.045)                           # the other, standing
    m |= seg(0.43, 0.87, 0.37, 0.88, 0.03)
    m |= seg(0.63, 0.66, 0.61, 0.87, 0.05)                            # hind legs
    m |= seg(0.61, 0.87, 0.55, 0.88, 0.03)
    m |= seg(0.71, 0.64, 0.73, 0.87, 0.045)
    m |= seg(0.73, 0.87, 0.68, 0.88, 0.03)
    m |= seg(0.72, 0.58, 0.84, 0.56, 0.04)                            # the tail, up over the back
    m |= seg(0.84, 0.56, 0.89, 0.43, 0.035)
    m |= seg(0.89, 0.43, 0.85, 0.31, 0.03)
    m |= poly([(0.80, 0.33), (0.90, 0.31), (0.84, 0.19)])            # its arrow tip
    return m


FLAGS = ["usa", "ger", "den", "kor", "jpn", "gbr", "aus", "mex", "bra", "fra", "chi", "cze", "ngc", "jam",
         "eng", "wal", "sco", "nir", "irl"]


def gen_flags():
    for size, (w, h) in (("s", (12, 8)), ("m", (21, 14)), ("l", (42, 28))):
        frames = [_flag(c, w, h) for c in FLAGS]
        row = np.concatenate(frames, 1)
        save(Image.fromarray(row), f"flags/flags_{size}.png")
    save_json({"order": FLAGS, "sizes": {"s": [14, 10], "m": [23, 16], "l": [44, 30]}}, "flags/flags.json")
    print("flags: %d" % len(FLAGS))


# -- the crowd: little hot dog fans ---------------------------------------------------

FAN_SAUSAGES = [P.FRANK, P.BRAT, P.RED_POLSE, P.BANGER, P.CHORIZO, P.BATTER]
FAN_BUNS = [P.BUN, P.CRUSTY, P.BUN, P.WHITE_BREAD, P.BUN]
FAN_BANDS = ["red", "blue", "yellow", "green", "white", "pink", "teal", "orange", "purple", "navy", "gold", "sky"]
FAN_W, FAN_H = 14, 22


def fan(sausage, bun, band, squash=1.0, cheer=False, seed=0):
    sx, sy = 1.0 / math.sqrt(squash), squash
    xf = pix.Xf(at=(FAN_W / 2, FAN_H - 2), sx=sx, sy=sy)
    # far away, so drawn simply: two tones a part, no glint, so a stand full
    # of them reads as a crowd rather than as noise
    sau = [sausage[0], sausage[1], sausage[2]]
    parts = [pix.Part(pix.sausage((0, -3.2), (0, -14.2), 3.2), sau, z=10, bands=[0.05, 0.5])]
    if bun is not None:
        bn = [bun[0], bun[1], bun[2]]
        for side in (-1, 1):
            parts.append(pix.Part(pix.sausage((side * 3.6, -2.2), (side * 3.6, -9), 2.1), bn, z=20 + side * 0.1,
                                  bands=[0.05, 0.5]))
        parts.append(pix.Part(pix.sausage((-3.6, -2.2), (3.6, -2.2), 2.1), bn, z=5, bands=[0.05, 0.5]))
    band_ = pix.clip(pix.sausage((0, -3.2), (0, -14.2), 3.2), pix.slab(-5, -16.2, 5, -14.4))
    parts.append(pix.Part(band_, P.TEAM[band], z=30, bands=[0.05, 0.6]))
    img = Image.fromarray(_paint(parts, xf)).copy()
    ex, ey = xf.fwd((0.6, -12.0))
    ex, ey = int(round(ex)), int(round(ey))
    px = img.load()
    for dx in (-2, 1):
        for xx, yy, c in ((0, 0, P.EYE_WHITE[2]), (1, 0, P.EYE_WHITE[2]), (0, 1, P.EYE_WHITE[2]), (1, 1, P.PUPIL[0])):
            X, Y = ex + dx + xx, ey + yy
            if 0 <= X < FAN_W and 0 <= Y < FAN_H:
                px[X, Y] = tuple(c) + (255,)
    if cheer:
        mx, my = xf.fwd((0.8, -9.4))
        for xx, yy in ((0, 0), (1, 0), (0, 1), (1, 1)):
            X, Y = int(round(mx)) + xx - 1, int(round(my)) + yy
            if 0 <= X < FAN_W and 0 <= Y < FAN_H:
                px[X, Y] = tuple(P.MOUTH[0 if yy == 0 else 1]) + (255,)
    return np.array(img)


def _paint(parts, xf):
    c = pix.Canvas(FAN_W, FAN_H)
    for p in parts:
        c.paint(p, xf)
    return c.finish()


def gen_crowd():
    rng = random.Random(12)
    frames = []
    count = 24
    for i in range(count):
        s = FAN_SAUSAGES[i % len(FAN_SAUSAGES)]
        b = FAN_BUNS[(i * 3) % len(FAN_BUNS)] if s is not P.BATTER else None
        band = FAN_BANDS[(i * 5) % len(FAN_BANDS)]
        # four frames per fan: standing, squashed (landing), stretched (jumping), cheering
        frames += [fan(s, b, band, 1.0), fan(s, b, band, 0.8), fan(s, b, band, 1.15, cheer=True), fan(s, b, band, 1.0, cheer=True)]
    save(pix.sheet(frames, 16), "crowd/fans.png")
    save_json({"cell": [FAN_W, FAN_H], "cols": 16, "fans": count, "frames_per_fan": 4,
               "foot": [FAN_W / 2, FAN_H - 2]}, "crowd/fans.json")
    print("crowd: %d fans" % count)


# -- the stadium ------------------------------------------------------------------------

def gen_stadium():
    import stadium as S
    save(Image.fromarray(S.sky()), "stadium/sky.png")
    save(Image.fromarray(S.sky(ramp=P.DUSK)), "stadium/sky_dusk.png")
    save(Image.fromarray(S.clouds()), "stadium/clouds.png")
    save(Image.fromarray(S.city()), "stadium/city.png")
    save(Image.fromarray(S.roof()), "stadium/roof.png")
    save(Image.fromarray(S.stands()), "stadium/stands.png")
    save(Image.fromarray(S.wall()), "stadium/wall.png")
    save(Image.fromarray(S.track()), "stadium/track.png")
    save(Image.fromarray(S.infield()), "stadium/infield.png")
    save(Image.fromarray(S.field()), "stadium/field.png")
    save(Image.fromarray(S.infield(kerb=False)), "stadium/infield_plain.png")
    save(Image.fromarray(S.hurdle()), "stadium/hurdle.png")
    save(Image.fromarray(S.hurdle(knocked=True)), "stadium/hurdle_down.png")
    save(Image.fromarray(S.sandpit()), "stadium/sandpit.png")
    save(Image.fromarray(S.takeoff_board()), "stadium/board.png")
    save(Image.fromarray(S.finish_post()), "stadium/finish_post.png")
    save(Image.fromarray(S.barrier()), "stadium/barrier.png")
    save(Image.fromarray(S.water_pit()), "stadium/water_pit.png")
    save(Image.fromarray(S.meatball()), "stadium/meatball.png")
    save(Image.fromarray(S.springboard()), "stadium/springboard.png")
    save(Image.fromarray(S.swim_lanes()), "stadium/swim_lanes.png")
    save(Image.fromarray(S.pool_deck()), "stadium/pool_deck.png")
    for m in range(10, 110, 10):
        save(Image.fromarray(S.distance_board(f"{m}m")), f"stadium/dist_{m}.png")
    save_json({
        "lanes": S.LANES, "track_edge": S.TRACK_EDGE, "lane_centres": S.lane_centres(),
        "stand_rows": S.STAND_ROWS, "wall_h": S.WALL_H, "infield_h": S.INFIELD_H,
        "track_h": S.TRACK_EDGE + sum(S.LANES) + 1, "stands_h": S.STAND_H,
    }, "stadium/stadium.json")
    print("stadium")


# -- the app icon ---------------------------------------------------------------------

def gen_icon():
    """A Chicago dog bouncing in front of an 80s sunset, 64 pixels drawn and
    blown up 3 times (192), so it stays chunky on a phone's home screen."""
    import compose
    S = 64
    bg = np.zeros((S, S, 4), np.uint8)
    for y in range(S):
        k = y / (S - 1)
        ramp = P.DUSK
        i = min(len(ramp) - 1, int(k * len(ramp)))
        bg[y, :, :3] = ramp[len(ramp) - 1 - i] if k > 0.5 else ramp[i]
        bg[y, :, 3] = 255
    # the sun, in stripes
    cx, cy, r = 32, 40, 21
    for y in range(S):
        for x in range(S):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r and y < cy + 2:
                if not (y > cy - 6 and (y % 3 == 0)):
                    bg[y, x, :3] = P.hx("#ffd060") if y < cy - 6 else P.hx("#ff9a5a")
    bg[50:, :, :3] = P.TRACK[2]
    bg[50, :, :3] = P.LANE_LINE[1]
    bg[57, :, :3] = P.LANE_LINE[1]
    dog = compose.athlete()
    h, w = dog.shape[:2]
    ox, oy = (S - w) // 2, 55 - dogs.FOOT[1]
    for y in range(h):
        for x in range(w):
            X, Y = ox + x, oy + y
            if 0 <= X < S and 0 <= Y < S and dog[y, x, 3]:
                bg[Y, X] = dog[y, x]
    img = Image.fromarray(bg)
    save(img.resize((192, 192), Image.NEAREST), "app/icon.png")
    print("icon")


# -- the title logo -------------------------------------------------------------------

def _word(text, scale, top, bottom, side, shine, depth, gap=0):
    """A word in the game's own letters, blown up, filled with an 80s
    two-tone (light above, warm below, a dark line between), with an ink
    outline and a solid extrusion down and to the right."""
    import font
    w = font.width_of(text, scale) + depth + 4 + gap * (len(text) - 1)
    h = 9 * scale + depth + 4
    mask = Image.new("L", (w, h), 0)
    x = 2
    for ch in text:
        font.draw(mask, ch, x, 2, (255,), scale)
        x += font.width_of(ch, scale) + scale + gap
    m = np.array(mask) > 0
    out = np.zeros((h, w, 4), np.uint8)
    # extrusion: the mask stepped down-right, darkest furthest back
    for d in range(depth, 0, -1):
        sh = np.zeros_like(m)
        sh[d:, d:] = m[:-d, :-d]
        col = side[0] if d > depth // 2 else side[1]
        out[sh, :3] = col
        out[sh, 3] = 255
    ys, xs = np.nonzero(m)
    y0, y1 = ys.min(), ys.max()
    mid = (y0 + y1) / 2.0
    for y, x in zip(ys, xs):
        k = (y - y0) / max(1, y1 - y0)
        if abs(y - mid) < 0.6 * scale / 2:
            c = side[1]
        elif y < mid:
            c = top[1] if k > 0.18 else top[0]
        else:
            c = bottom[0] if k < 0.82 else bottom[1]
        out[y, x, :3] = c
        out[y, x, 3] = 255
    # a shine along each letter's top edge
    for y, x in zip(ys, xs):
        if y - 1 >= 0 and not m[y - 1, x] and y < mid:
            out[y, x, :3] = shine
    # the outline round everything
    solid = out[..., 3] > 0
    ring = np.zeros_like(solid)
    for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (-1, -1), (1, -1), (-1, 1)):
        ring |= np.roll(np.roll(solid, dy, 0), dx, 1)
    ring &= ~solid
    out[ring, :3] = P.INK
    out[ring, 3] = 255
    return out


def gen_logo():
    hot = _word("HOTDOG", 4, (P.hx("#fff38a"), P.hx("#f7d331")), (P.hx("#f0a030"), P.hx("#d9701b")),
                (P.hx("#86283a"), P.hx("#b8423d")), P.WHITE, 4, gap=3)
    oly = _word("SPORTS DAY", 2, (P.WHITE, P.hx("#e8eef5")), (P.hx("#94c6f0"), P.hx("#6aa2e2")),
                (P.hx("#1e2a7a"), P.hx("#2a4ad2")), P.WHITE, 2, gap=2)
    W = max(hot.shape[1], oly.shape[1]) + 4
    H = hot.shape[0] + oly.shape[0] + 2
    out = np.zeros((H, W, 4), np.uint8)
    hx = (W - hot.shape[1]) // 2
    out[:hot.shape[0], hx:hx + hot.shape[1]] = hot
    ox = (W - oly.shape[1]) // 2
    oy = hot.shape[0] - 2
    region = out[oy:oy + oly.shape[0], ox:ox + oly.shape[1]]
    m = oly[..., 3] > 0
    region[m] = oly[m]
    save(Image.fromarray(out), "ui/logo.png")
    print("logo %dx%d" % (W, H))


def gen_icons():
    import icons
    img, names = icons.sheet()
    save(img, "ui/icons.png")
    save_json({"size": icons.S, "order": names}, "ui/icons.json")
    print("icons: %d" % len(names))


PARTS = {
    "icons": gen_icons,
    "logo": gen_logo,
    "icon": gen_icon,
    "dogs": gen_dogs,
    "wardrobe": gen_wardrobe,
    "crowd": gen_crowd,
    "stadium": gen_stadium,
    "face": gen_face,
    "flags": gen_flags,
}


def main(args):
    want = args or list(PARTS)
    for name in want:
        PARTS[name]()


if __name__ == "__main__":
    main(sys.argv[1:])
