"""Procedural pixel-art generator for Defold Fighter.

Draws both fighters from simple 2-bone IK skeleton poses, plus effects and the
stage background, then writes PNG frames into assets/images and regenerates
assets/game.atlas:

    python tools/gen_sprites.py

This is the starting point for the art. Once you hand-edit sprites in
LibreSprite (see tools/art.py), don't re-run it: it overwrites the PNGs.

Every frame is a separate PNG named <character>_<anim>_<n>.png. The game
selects frames from Lua (see modules/characters.lua), so the frame timing lives
with the frame data rather than in the atlas.
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

import art

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG_DIR = os.path.join(ROOT, "assets", "images")

FW, FH = 96, 96          # fighter frame size
OX, OY = 48, 88          # feet origin inside the frame
OUTLINE = (22, 14, 28)


# --------------------------------------------------------------------------
# math helpers (local space: x forward, y up, origin at the feet)
# --------------------------------------------------------------------------

def add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def polar(deg, length):
    r = math.radians(deg)
    return (length * math.cos(r), length * math.sin(r))


def to_img(p):
    return (OX + p[0], OY - p[1])


def shade(col, k):
    return tuple(max(0, min(255, int(c * k))) for c in col)


def ik(root, target, l1, l2, pref):
    """Two-bone IK. Returns (joint, end). pref picks which bend solution."""
    dx, dy = target[0] - root[0], target[1] - root[1]
    d = math.hypot(dx, dy)
    d = max(abs(l1 - l2) + 0.01, min(l1 + l2 - 0.01, d))
    a = math.atan2(dy, dx)
    cb = (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)
    b = math.acos(max(-1.0, min(1.0, cb)))
    c1 = (root[0] + l1 * math.cos(a + b), root[1] + l1 * math.sin(a + b))
    c2 = (root[0] + l1 * math.cos(a - b), root[1] + l1 * math.sin(a - b))

    def score(c):
        return (c[0] - root[0]) * pref[0] + (c[1] - root[1]) * pref[1]

    joint = c1 if score(c1) >= score(c2) else c2
    end = (root[0] + d * math.cos(a), root[1] + d * math.sin(a))
    return joint, end


# --------------------------------------------------------------------------
# drawing primitives
# --------------------------------------------------------------------------

def seg(d, a, b, w, col):
    pa, pb = to_img(a), to_img(b)
    d.line([pa, pb], fill=col, width=int(round(w)))
    r = w / 2.0 - 0.5
    for p in (pa, pb):
        d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=col)


def disc(d, c, r, col):
    p = to_img(c)
    d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=col)


def poly(d, pts, col):
    d.polygon([to_img(p) for p in pts], fill=col)


def outlined(canvas, size, draw_fn, outline=OUTLINE):
    """Draw a group on its own layer, give it a 1px outline, composite it."""
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(layer))
    alpha = layer.split()[3].point(lambda v: 255 if v > 0 else 0)
    dil = alpha.filter(ImageFilter.MaxFilter(3))
    base = Image.new("RGBA", size, (0, 0, 0, 0))
    base.paste(Image.new("RGBA", size, outline + (255,)), (0, 0), dil)
    base.alpha_composite(layer)
    canvas.alpha_composite(base)


# --------------------------------------------------------------------------
# characters
# --------------------------------------------------------------------------

KENJI = dict(
    name="kenji",
    thigh=13, shin=13, uarm=10, farm=10, torso=18, neck=2, head_r=6,
    w_thigh=8, w_shin=7, w_uarm=6, w_farm=5, hip_w=5.5, chest_w=7,
    skin=(232, 172, 124), top=(196, 38, 44), pants=(196, 38, 44),
    sleeve=(196, 38, 44), belt=(28, 24, 30), hair=(34, 26, 36),
    band=(244, 240, 232), glove=(126, 74, 40), foot=(232, 172, 124),
    boot=None, lapel=(140, 22, 34),
)

VERA = dict(
    name="vera",
    thigh=14, shin=14, uarm=10, farm=10, torso=16, neck=2, head_r=5.5,
    w_thigh=7, w_shin=6, w_uarm=5, w_farm=5, hip_w=5, chest_w=6,
    skin=(244, 196, 156), top=(36, 168, 170), pants=(44, 54, 108),
    sleeve=None, belt=(150, 70, 186), hair=(250, 208, 88),
    band=None, glove=(232, 232, 242), foot=(78, 44, 34),
    boot=(78, 44, 34), lapel=(20, 112, 120),
)


def render_fighter(ch, pose, t=0.0):
    img = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    dy = pose.get("dy", 0)
    hip = (pose["hip"][0], pose["hip"][1] + dy)
    lean = pose.get("lean", 6)
    ta = 90 - lean
    axis = polar(ta, 1)
    perp = (axis[1], -axis[0])  # points forward when upright
    neck = add(hip, polar(ta, ch["torso"]))
    head_c = add(neck, polar(ta + pose.get("head_tilt", 0), ch["neck"] + ch["head_r"]))
    sh = add(neck, polar(ta, -3))
    sh_n = (sh[0] + 1, sh[1])
    sh_f = (sh[0] - 1.5, sh[1] + 0.5)
    hip_n = (hip[0] + 1.5, hip[1])
    hip_f = (hip[0] - 1.5, hip[1] + 0.5)

    def hand(key):
        h = pose[key]
        return (h[0], h[1] + dy)

    elbow_pref = pose.get("elbow_pref", (-0.3, -1))
    knee_pref = pose.get("knee_pref", (1, 0.2))
    far_knee_pref = pose.get("far_knee_pref", knee_pref)

    def draw_arm(shoulder, target, k):
        elbow, hnd = ik(shoulder, target, ch["uarm"], ch["farm"], elbow_pref)

        def fn(d):
            seg(d, shoulder, elbow, ch["w_uarm"], shade(ch["sleeve"] or ch["skin"], k))
            seg(d, elbow, hnd, ch["w_farm"], shade(ch["skin"], k))
            disc(d, hnd, 2.8, shade(ch["glove"], k))
            if ch["sleeve"]:
                seg(d, shoulder, add(elbow, ((shoulder[0] - elbow[0]) * 0.25, (shoulder[1] - elbow[1]) * 0.25)),
                    ch["w_uarm"] + 1, shade(ch["sleeve"], k))
        outlined(img, (FW, FH), fn)

    def draw_leg(h, target, k, pref, foot_ang=None):
        knee, ankle = ik(h, target, ch["thigh"], ch["shin"], pref)
        shin_ang = math.degrees(math.atan2(ankle[1] - knee[1], ankle[0] - knee[0]))
        fa = foot_ang if foot_ang is not None else shin_ang + 90
        toe = add(ankle, polar(fa, 5))

        def fn(d):
            seg(d, h, knee, ch["w_thigh"], shade(ch["pants"], k))
            seg(d, knee, ankle, ch["w_shin"], shade(ch["pants"], k))
            if ch["boot"]:
                mid = (knee[0] + (ankle[0] - knee[0]) * 0.45, knee[1] + (ankle[1] - knee[1]) * 0.45)
                seg(d, mid, ankle, ch["w_shin"], shade(ch["boot"], k))
            seg(d, ankle, toe, 3.4, shade(ch["foot"], k))
        outlined(img, (FW, FH), fn)

    def draw_torso():
        def fn(d):
            n2 = add(neck, polar(ta, -1))
            pts = [add(hip, (perp[0] * ch["hip_w"], perp[1] * ch["hip_w"])),
                   add(n2, (perp[0] * ch["chest_w"], perp[1] * ch["chest_w"])),
                   add(n2, (-perp[0] * ch["chest_w"], -perp[1] * ch["chest_w"])),
                   add(hip, (-perp[0] * ch["hip_w"], -perp[1] * ch["hip_w"]))]
            poly(d, pts, ch["top"])
            # neck
            seg(d, neck, add(neck, polar(ta, 3)), 4, ch["skin"])
            # lapel / chest detail
            if ch["name"] == "kenji":
                seg(d, add(n2, (perp[0] * 3, perp[1] * 3)), add(hip, polar(ta, 7)), 1, ch["lapel"])
                seg(d, add(n2, (perp[0] * 3.5, perp[1] * 3.5)), add(n2, (perp[0] * 1, perp[1] * 1)), 2, ch["skin"])
            else:
                seg(d, add(n2, (-perp[0] * 2, -perp[1] * 2)), add(hip, polar(ta, 6)), 1, ch["lapel"])
            # belt
            b0 = add(hip, polar(ta, 1))
            b1 = add(hip, polar(ta, 4))
            bw = ch["hip_w"] + 0.5
            poly(d, [add(b0, (perp[0] * bw, perp[1] * bw)), add(b1, (perp[0] * bw, perp[1] * bw)),
                     add(b1, (-perp[0] * bw, -perp[1] * bw)), add(b0, (-perp[0] * bw, -perp[1] * bw))], ch["belt"])
            knot = add(b0, (-perp[0] * bw, -perp[1] * bw))
            sway = math.sin(t * math.tau) * 2
            seg(d, knot, add(knot, (-3 + sway * 0.3, -6)), 2, ch["belt"])
            seg(d, knot, add(knot, (-5 + sway * 0.5, -4)), 2, ch["belt"])
        outlined(img, (FW, FH), fn)

    def draw_head():
        r = ch["head_r"]
        tilt = ta + pose.get("head_tilt", 0) - 90  # rotation from upright

        def hp(x, y):  # head-local -> local
            c, s = math.cos(math.radians(tilt)), math.sin(math.radians(tilt))
            return (head_c[0] + x * c - y * s, head_c[1] + x * s + y * c)

        def fn(d):
            if ch["name"] == "vera":
                # ponytail behind the head
                sway = math.sin(t * math.tau)
                prev = hp(-3, 3)
                for i in range(1, 6):
                    p = hp(-3 - i * 1.8 - sway * i * 0.2, 3 - i * 2.2 + abs(sway) * 0.3)
                    seg(d, prev, p, 4.2 - i * 0.45, ch["hair"])
                    prev = p
            disc(d, head_c, r, ch["skin"])
            if ch["name"] == "kenji":
                hair = [hp(-r - 1, -1), hp(-r - 4, 3), hp(-r, 4), hp(-r - 2, 7.5), hp(-2, r + 1),
                        hp(0, r + 3), hp(2, r + 0.5), hp(5, r - 0.5), hp(r, 2), hp(-1, 1), hp(-3, -2)]
                poly(d, hair, ch["hair"])
                # headband + tails
                seg(d, hp(-r + 0.5, 2.5), hp(r - 0.5, 2.5), 2, ch["band"])
                sway = math.sin(t * math.tau) * 1.5
                seg(d, hp(-r, 2), hp(-r - 5, 0 + sway), 2, ch["band"])
                seg(d, hp(-r, 2), hp(-r - 4, -3 + sway), 1.6, ch["band"])
            else:
                hair = [hp(-r - 0.5, -2), hp(-r - 1, 2), hp(-3, r + 1.2), hp(1, r + 1),
                        hp(r, 3), hp(r - 1, 1.5), hp(1, 2.5), hp(-2, 0), hp(-3, -3)]
                poly(d, hair, ch["hair"])
            # eye + ear
            e = to_img(hp(2.6, 0.5))
            d.rectangle([e[0], e[1] - 1, e[0], e[1]], fill=OUTLINE)
            m = to_img(hp(3.5, -3))
            d.point(m, fill=shade(ch["skin"], 0.7))
        outlined(img, (FW, FH), fn)

    draw_arm(sh_f, hand("far_hand"), 0.72)
    draw_leg(hip_f, pose["far_foot"], 0.74, far_knee_pref, pose.get("far_foot_ang"))
    draw_torso()
    draw_leg(hip_n, pose["near_foot"], 1.0, knee_pref, pose.get("near_foot_ang"))
    draw_head()
    draw_arm(sh_n, hand("near_hand"), 1.0)
    return img


def P(base, **kw):
    p = dict(base)
    p.update(kw)
    return p


def poses_for(ch):
    """All animation frames for a character: {anim: [pose, ...]}."""
    k = ch["name"] == "kenji"
    stance = dict(hip=(0, 24), lean=8, near_foot=(9, 0), far_foot=(-9, 0),
                  near_hand=(14, 43), far_hand=(9, 39))
    if not k:
        stance = dict(hip=(0, 25), lean=6, near_foot=(8, 0), far_foot=(-10, 0),
                      near_hand=(12, 44), far_hand=(8, 41))
    crouch = P(stance, hip=(0, 13), lean=18, near_foot=(11, 0), far_foot=(-9, 0),
               near_hand=(15, 31), far_hand=(11, 28))
    A = {}
    A["idle"] = [P(stance, dy=d) for d in (0, -1, -1, 0)]
    walk = []
    for i in range(6):
        th = i / 6 * math.tau
        walk.append(P(stance,
                      near_foot=(9 * math.cos(th), max(0, 4 * math.sin(th))),
                      far_foot=(-9 * math.cos(th), max(0, -4 * math.sin(th))),
                      dy=-round(abs(math.sin(th)))))
    A["walk"] = walk
    A["crouch"] = [crouch]
    A["jump"] = [P(stance, hip=(0, 26), lean=10, near_foot=(7, 11), far_foot=(-5, 7),
                   near_hand=(12, 46), far_hand=(6, 48)),
                 P(stance, hip=(0, 25), lean=4, near_foot=(8, 3), far_foot=(-7, 2),
                   near_hand=(15, 42), far_hand=(9, 40))]
    A["block"] = [P(stance, hip=(-2, 24), lean=-2, near_hand=(10, 49), far_hand=(12, 45))]
    A["cblock"] = [P(crouch, lean=10, near_hand=(11, 34), far_hand=(13, 30))]
    A["hit"] = [P(stance, hip=(-3, 24), lean=-18, head_tilt=-12, near_hand=(2, 40), far_hand=(-2, 44)),
                P(stance, hip=(-5, 23), lean=-28, head_tilt=-18, near_foot=(10, 0), far_foot=(-11, 0),
                  near_hand=(-2, 42), far_hand=(-6, 38))]
    A["chit"] = [P(crouch, hip=(-3, 13), lean=-6, head_tilt=-15, near_hand=(4, 28), far_hand=(0, 30))]
    A["fall"] = [P(stance, hip=(0, 28), lean=-55, head_tilt=-10, near_foot=(16, 34), far_foot=(12, 26),
                   near_hand=(-10, 46), far_hand=(-4, 50), knee_pref=(0.3, 1))]
    A["down"] = [dict(hip=(-2, 5), lean=-86, head_tilt=4, near_foot=(18, 2), far_foot=(15, 4),
                      near_hand=(-12, 1), far_hand=(-20, 2), knee_pref=(0.2, 1), elbow_pref=(0, -1))]
    A["rise"] = [P(stance, hip=(0, 13), lean=12, near_foot=(10, 0), far_foot=(-13, 0),
                   near_hand=(9, 15), far_hand=(4, 13), far_knee_pref=(1, -1), far_foot_ang=180)]
    A["win"] = [P(stance, lean=2), P(stance, lean=-4, near_hand=(5, 60), far_hand=(-6, 27))]

    if k:
        A["punch"] = [P(stance, lean=6, near_hand=(5, 40), far_hand=(13, 43)),
                      P(stance, hip=(2, 24), lean=16, near_foot=(11, 0), near_hand=(27, 44), far_hand=(4, 35)),
                      P(stance, hip=(1, 24), lean=11, near_hand=(19, 44), far_hand=(6, 37))]
        A["kick"] = [P(stance, hip=(-1, 25), lean=-4, near_foot=(9, 15), far_foot=(-6, 0), knee_pref=(1, 1),
                       near_hand=(12, 45), far_hand=(6, 41)),
                     P(stance, hip=(-2, 26), lean=-14, near_foot=(30, 30), far_foot=(-8, 0),
                       near_hand=(8, 46), far_hand=(-2, 40), near_foot_ang=80),
                     P(stance, hip=(-1, 25), lean=-4, near_foot=(11, 12), far_foot=(-7, 0), knee_pref=(1, 1),
                       near_hand=(12, 45), far_hand=(6, 41))]
        A["special"] = [P(stance, hip=(-1, 23), lean=0, near_hand=(-5, 31), far_hand=(-7, 33)),
                        P(stance, hip=(-2, 21), lean=-4, near_foot=(12, 0), far_foot=(-11, 0),
                          near_hand=(-8, 31), far_hand=(-9, 34)),
                        P(stance, hip=(2, 22), lean=18, near_foot=(13, 0), far_foot=(-11, 0),
                          near_hand=(26, 38), far_hand=(24, 35), elbow_pref=(0, -1)),
                        P(stance, hip=(1, 22), lean=14, near_foot=(13, 0), far_foot=(-11, 0),
                          near_hand=(23, 38), far_hand=(21, 35), elbow_pref=(0, -1))]
    else:
        A["punch"] = [P(stance, lean=4, near_hand=(6, 42), far_hand=(13, 44)),
                      P(stance, hip=(2, 25), lean=14, near_foot=(10, 0), near_hand=(26, 47), far_hand=(4, 38)),
                      P(stance, hip=(1, 25), lean=10, near_hand=(18, 46), far_hand=(6, 40))]
        A["kick"] = [P(stance, hip=(-1, 26), lean=-8, near_foot=(6, 20), far_foot=(-6, 0), knee_pref=(1, 1),
                       near_hand=(10, 46), far_hand=(2, 42)),
                     P(stance, hip=(-3, 27), lean=-24, near_foot=(30, 46), far_foot=(-8, 0),
                       near_hand=(4, 48), far_hand=(-8, 40), near_foot_ang=20),
                     P(stance, hip=(-1, 26), lean=-8, near_foot=(10, 16), far_foot=(-7, 0), knee_pref=(1, 1),
                       near_hand=(10, 46), far_hand=(2, 42))]
        A["special"] = [P(crouch, hip=(-2, 16), lean=22, near_foot=(12, 0), far_foot=(-11, 0),
                          near_hand=(-2, 22), far_hand=(-6, 24)),
                        P(stance, hip=(0, 30), lean=12, near_foot=(4, 20), far_foot=(-16, 18),
                          knee_pref=(1, 0.4), far_knee_pref=(0, -1), far_foot_ang=200,
                          near_hand=(-6, 40), far_hand=(14, 48)),
                        P(stance, hip=(0, 33), lean=8, near_foot=(5, 27), far_foot=(-15, 20),
                          knee_pref=(1, 1), far_knee_pref=(0, -1), far_foot_ang=200,
                          near_hand=(-4, 42), far_hand=(15, 52)),
                        P(crouch, hip=(0, 17), lean=12, near_hand=(14, 33), far_hand=(10, 30))]

    A["cpunch"] = [P(crouch, near_hand=(8, 28), far_hand=(13, 31)),
                   P(crouch, hip=(2, 13), lean=24, near_hand=(28, 28), far_hand=(6, 26))]
    A["sweep"] = [P(crouch, hip=(-2, 11), lean=26, near_foot=(10, 0), far_foot=(-8, 0),
                    near_hand=(14, 3), far_hand=(10, 5)),
                  P(crouch, hip=(-4, 10), lean=32, near_foot=(31, 2), far_foot=(-8, 0),
                    near_foot_ang=60, far_knee_pref=(1, 0.2), near_hand=(10, 2), far_hand=(5, 4)),
                  P(crouch, hip=(-2, 11), lean=26, near_foot=(14, 1), far_foot=(-8, 0),
                    near_hand=(14, 3), far_hand=(10, 5))]
    A["jkick"] = [P(stance, hip=(0, 26), lean=6, near_foot=(9, 14), far_foot=(-6, 12),
                    knee_pref=(1, 1), near_hand=(12, 46), far_hand=(6, 44)),
                  P(stance, hip=(-1, 26), lean=-14, near_foot=(26, 10), far_foot=(-7, 15),
                    near_foot_ang=0, far_knee_pref=(1, -0.5), near_hand=(6, 48), far_hand=(-4, 42))]
    return A


# --------------------------------------------------------------------------
# effects
# --------------------------------------------------------------------------

def render_spark(i, palette):
    size = 40
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = size / 2
    rng = random.Random(7)
    rays = 9
    reach = [8, 15, 18, 16][i]
    width = [3, 3, 2, 1][i]
    core = [6, 5, 3, 0][i]
    for r in range(rays):
        a = r / rays * math.tau + rng.uniform(-0.2, 0.2)
        ln = reach * rng.uniform(0.65, 1.0)
        inner = [0, 3, 7, 10][i]
        d.line([(c + math.cos(a) * inner, c + math.sin(a) * inner),
                (c + math.cos(a) * ln, c + math.sin(a) * ln)], fill=palette[1], width=width)
    if core:
        d.ellipse([c - core, c - core, c + core, c + core], fill=palette[0])
        d.ellipse([c - core / 2, c - core / 2, c + core / 2, c + core / 2], fill=(255, 255, 255))
    return img


def render_fireball(i):
    w, h = 44, 26
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = 30, 13
    rng = random.Random(i * 13 + 1)
    # flame tail (behind = left)
    for k in range(14):
        x = cx - 4 - k * 1.8 + rng.uniform(-1, 1)
        y = cy + math.sin(k * 0.9 + i * 1.7) * (k * 0.35)
        r = max(1.0, 7 - k * 0.45)
        col = (40, 90, 230) if k > 7 else (70, 150, 255)
        d.ellipse([x - r, y - r, x + r, y + r], fill=col)
    pulse = [0, 1, 0, -1][i]
    d.ellipse([cx - 10 - pulse, cy - 10 - pulse, cx + 10 + pulse, cy + 10 + pulse], fill=(40, 90, 230))
    d.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(90, 180, 255))
    d.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=(190, 240, 255))
    d.ellipse([cx - 3 + pulse, cy - 3, cx + 2, cy + 2], fill=(255, 255, 255))
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    alpha = img.split()[3].point(lambda v: 255 if v > 0 else 0).filter(ImageFilter.MaxFilter(3))
    out.paste(Image.new("RGBA", (w, h), (16, 20, 70, 255)), (0, 0), alpha)
    out.alpha_composite(img)
    return out


def render_dust(i):
    w, h = 48, 20
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rng = random.Random(3)
    spread = [6, 12, 17][i]
    alpha = [230, 180, 110][i]
    for _ in range(9):
        x = w / 2 + rng.uniform(-1, 1) * spread
        r = rng.uniform(2.5, 4.5) * (1 + i * 0.25)
        y = h - 4 - rng.uniform(0, 3) - i * 2
        d.ellipse([x - r, y - r, x + r, y + r], fill=(222, 200, 176, alpha))
    return img


def render_shadow():
    img = Image.new("RGBA", (40, 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([0, 0, 39, 7], fill=(20, 8, 24, 110))
    d.ellipse([6, 1, 33, 6], fill=(20, 8, 24, 150))
    return img


# --------------------------------------------------------------------------
# stage background
# --------------------------------------------------------------------------

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def render_stage():
    W, H = 428, 240
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    px = img.load()
    stops = [(0, (34, 24, 72)), (60, (92, 40, 112)), (110, (184, 72, 118)),
             (150, (246, 138, 92)), (176, (255, 196, 120))]
    # dithered sky, quantized to 10 bands per segment
    for y in range(H):
        for s in range(len(stops) - 1):
            if stops[s][0] <= y <= stops[s + 1][0]:
                t = (y - stops[s][0]) / (stops[s + 1][0] - stops[s][0])
                a, b = stops[s][1], stops[s + 1][1]
                break
        else:
            t, a, b = 1, stops[-1][1], stops[-1][1]
        for x in range(W):
            tq = t * 6
            base = int(tq)
            frac = tq - base
            thr = (BAYER[y % 4][x % 4] + 0.5) / 16
            step = base + (1 if frac > thr else 0)
            px[x, y] = lerp(a, b, min(1, step / 6)) + (255,)
    d = ImageDraw.Draw(img)
    # stars
    rng = random.Random(42)
    for _ in range(40):
        x, y = rng.randrange(W), rng.randrange(70)
        d.point((x, y), fill=(255, 236, 220) if rng.random() < 0.5 else (200, 170, 230))
    # retro sun with cut stripes
    sx, sy, sr = 300, 132, 34
    d.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=(255, 214, 140))
    d.ellipse([sx - sr + 5, sy - sr + 5, sx + sr - 5, sy + sr - 5], fill=(255, 232, 170))
    for k, yy in enumerate(range(sy + 2, sy + sr, 6)):
        d.rectangle([sx - sr, yy, sx + sr, yy + 1 + k // 2], fill=px[sx - sr - 2, yy][:3])

    def ridge(base_y, amp, freq, seed, col):
        r2 = random.Random(seed)
        ph = [r2.uniform(0, 6) for _ in range(3)]
        pts = [(0, H)]
        for x in range(0, W + 1, 2):
            y = base_y - amp * (0.6 * math.sin(x * freq + ph[0]) + 0.3 * math.sin(x * freq * 2.3 + ph[1])
                                + 0.15 * math.sin(x * freq * 5.1 + ph[2]))
            pts.append((x, y))
        pts.append((W, H))
        d.polygon(pts, fill=col)

    ridge(150, 26, 0.018, 1, (120, 58, 120))
    ridge(162, 18, 0.03, 2, (84, 40, 98))
    # pagoda silhouette
    pc = (52, 26, 66)
    bx = 78
    d.rectangle([bx - 4, 100, bx + 4, 172], fill=pc)
    for k, (yy, wd) in enumerate([(108, 22), (124, 28), (140, 34), (156, 40)]):
        d.polygon([(bx - wd, yy + 4), (bx + wd, yy + 4), (bx + wd - 6, yy - 3), (bx - wd + 6, yy - 3)], fill=pc)
        d.rectangle([bx - wd + 8, yy + 4, bx + wd - 8, yy + 13], fill=pc)
        d.point((bx - wd, yy + 3), fill=pc)
    d.line([(bx, 84), (bx, 100)], fill=pc, width=2)
    ridge(176, 6, 0.05, 3, (60, 30, 72))
    # courtyard wall with lanterns
    wall_top = 168
    d.rectangle([0, wall_top, W, 194], fill=(92, 62, 78))
    d.rectangle([0, wall_top, W, wall_top + 3], fill=(58, 34, 52))
    for y in range(wall_top + 6, 194, 7):
        off = 0 if (y // 7) % 2 else 9
        for x in range(-off, W, 18):
            d.rectangle([x + 1, y, x + 16, y + 5], fill=(110, 76, 90))
            d.line([(x + 1, y), (x + 16, y)], fill=(130, 92, 104))
    for lx in (34, 150, 278, 394):
        d.rectangle([lx - 1, 150, lx + 1, 168], fill=(40, 22, 40))
        d.rectangle([lx - 6, 146, lx + 6, 150], fill=(40, 22, 40))
        d.rectangle([lx - 4, 151, lx + 4, 160], fill=(255, 176, 86))
        d.rectangle([lx - 2, 153, lx + 2, 158], fill=(255, 236, 170))
        d.rectangle([lx - 6, 160, lx + 6, 162], fill=(40, 22, 40))
    # wooden floor
    floor_top = 194
    for y in range(floor_top, H):
        t = (y - floor_top) / (H - floor_top)
        col = lerp((170, 104, 70), (96, 54, 40), t)
        d.line([(0, y), (W, y)], fill=col)
    y = floor_top
    gap = 3
    row = 0
    while y < H:
        d.line([(0, y), (W, y)], fill=(70, 38, 32))
        seam_off = (row * 37) % 60
        for x in range(seam_off, W, 60):
            d.line([(x, y + 1), (x, min(H, y + gap))], fill=(80, 44, 36))
        row += 1
        y += gap
        gap += 2
    # sun reflection on the floor
    for yy in range(floor_top + 2, H, 3):
        w = 26 - (yy - floor_top) * 0.3
        if w > 2:
            d.line([(sx - w, yy), (sx + w, yy)], fill=(214, 150, 96))
    # cherry tree on the right
    tc = (44, 22, 34)
    d.polygon([(404, 194), (420, 194), (417, 140), (410, 120), (404, 140)], fill=tc)
    d.line([(410, 128), (384, 96)], fill=tc, width=4)
    d.line([(412, 124), (428, 92)], fill=tc, width=4)
    d.line([(392, 106), (366, 92)], fill=tc, width=3)
    rng = random.Random(9)
    for _ in range(170):
        x = rng.gauss(400, 22)
        y = rng.gauss(88, 14)
        r = rng.uniform(2, 5)
        col = rng.choice([(236, 136, 178), (250, 176, 206), (204, 98, 150), (255, 210, 228)])
        d.ellipse([x - r, y - r, x + r, y + r], fill=col)
    for _ in range(14):
        x, y = rng.uniform(330, 428), rng.uniform(110, 190)
        d.point((x, y), fill=(250, 176, 206))
    # vignette at the floor edge
    for yy in range(H - 10, H):
        a = (yy - (H - 10)) / 10 * 0.45
        for xx in range(W):
            r, g, b, _ = px[xx, yy]
            px[xx, yy] = (int(r * (1 - a)), int(g * (1 - a)), int(b * (1 - a)), 255)
    return img


# --------------------------------------------------------------------------
# output
# --------------------------------------------------------------------------

def save(img, sub, name):
    path = os.path.join(IMG_DIR, sub)
    os.makedirs(path, exist_ok=True)
    img.save(os.path.join(path, name + ".png"))
    return "/assets/images/%s/%s.png" % (sub, name)


def main():
    entries = []
    for ch in (KENJI, VERA):
        for anim, frames in poses_for(ch).items():
            for i, pose in enumerate(frames):
                img = render_fighter(ch, pose, t=i / max(1, len(frames)))
                entries.append(save(img, ch["name"], "%s_%s_%d" % (ch["name"], anim, i)))
    for i in range(4):
        entries.append(save(render_spark(i, [(255, 240, 160), (255, 190, 60)]), "fx", "spark_%d" % i))
        entries.append(save(render_spark(i, [(200, 240, 255), (110, 190, 255)]), "fx", "bspark_%d" % i))
        entries.append(save(render_fireball(i), "fx", "fireball_%d" % i))
    for i in range(3):
        entries.append(save(render_dust(i), "fx", "dust_%d" % i))
    entries.append(save(render_shadow(), "fx", "shadow"))
    entries.append(save(render_stage(), "stage", "stage_bg"))
    print("wrote %d images" % len(entries))
    art.cmd_atlas()


if __name__ == "__main__":
    main()
