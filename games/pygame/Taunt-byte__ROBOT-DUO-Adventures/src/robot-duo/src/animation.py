"""Robot art + animation.

Both robots are drawn procedurally (vector-style) on a 128x128 supersampled canvas,
then smooth-scaled down, which gives clean cartoon outlines without any image files.

The design of ROBO-X follows the reference mascot: round red body, big fin-shaped
shoulder pads, black visor with two vertical green eyes, black gloves, grey waist
joint and a blue chevron on the chest. ROBO-B shares the silhouette but is cyan,
has a droplet emblem and an antenna so the two are recognisable at a glance.

The architecture is ready for hand-made art: drop PNG frames named
    assets/sprites/robo_x/<state>_<index>.png     (e.g. idle_0.png, walk_3.png)
into the matching folder and they replace the procedural frames for that state.
States: idle walk jump fall land death victory.
"""
import glob
import math
import os
import pygame

from . import settings as S

CANVAS = 128            # hi-res canvas size
BASE = 64               # in-game sprite size at scale 1
FOOT_Y = 122            # y of the soles inside the canvas
OUTLINE_W = 5


class Palette:
    def __init__(self, main, dark, light, outline, eye, eye_glow, accent):
        self.main, self.dark, self.light, self.outline = main, dark, light, outline
        self.eye, self.eye_glow, self.accent = eye, eye_glow, accent


PALETTES = {
    "x": Palette(main=(214, 40, 44), dark=(148, 22, 34), light=(255, 118, 100), outline=(56, 8, 20),
                 eye=(64, 255, 160), eye_glow=(40, 220, 130), accent=(44, 150, 240)),
    "b": Palette(main=(34, 166, 232), dark=(18, 104, 178), light=(150, 228, 255), outline=(8, 28, 72),
                 eye=(120, 255, 235), eye_glow=(60, 230, 220), accent=(255, 255, 255)),
}
JOINT = (70, 78, 94)
JOINT_DARK = (44, 50, 64)
GLOVE = (28, 30, 38)
VISOR = (16, 18, 26)

# state -> (frame count, fps, loops?)
STATE_DEFS = {
    "idle": (12, 9, True),
    "walk": (8, 14, True),
    "jump": (2, 8, False),
    "fall": (2, 8, True),
    "land": (4, 26, False),
    "death": (10, 15, False),
    "victory": (12, 12, True),
}


# ----------------------------------------------------------------------------- drawing helpers
def _rrect(surf, color, rect, radius):
    pygame.draw.rect(surf, color, rect, border_radius=radius)


def _alpha_ellipse(surf, color, alpha, rect):
    x, y, w, h = [int(v) for v in rect]
    tmp = pygame.Surface((max(1, w), max(1, h)), pygame.SRCALPHA)
    pygame.draw.ellipse(tmp, (color[0], color[1], color[2], alpha), tmp.get_rect())
    surf.blit(tmp, (x, y))


def _poly(surf, pts, fill, outline, shrink=0.8):
    """Polygon with a uniform-ish outline: draw it in the outline colour, then a shrunken copy on top."""
    pygame.draw.polygon(surf, outline, pts)
    cx = sum(p[0] for p in pts) / len(pts)
    cy = sum(p[1] for p in pts) / len(pts)
    inner = [(cx + (x - cx) * shrink, cy + (y - cy) * shrink) for x, y in pts]
    pygame.draw.polygon(surf, fill, inner)


def paint_robot(kind, pose):
    """Draw one robot facing right on a CANVAS x CANVAS surface. `pose` controls limbs and face."""
    pal = PALETTES[kind]
    surf = pygame.Surface((CANVAS, CANVAS), pygame.SRCALPHA)
    ol = pal.outline
    cx = CANVAS // 2
    bob = pose.get("bob", 0.0)
    leg = pose.get("leg", 0.0)
    arm = pose.get("arm", 0.0)
    arm_up = pose.get("arm_up", 0.0)
    blink = pose.get("blink", 0.0)
    eyes = pose.get("eyes", "normal")

    # --- antenna (ROBO-B only), behind the head -------------------------------
    if kind == "b":
        top = 26 + bob
        pygame.draw.line(surf, ol, (cx, top + 4), (cx, top - 14), 7)
        pygame.draw.line(surf, JOINT, (cx, top + 4), (cx, top - 13), 3)
        pygame.draw.circle(surf, ol, (cx, int(top - 17)), 9)
        pygame.draw.circle(surf, pal.eye, (cx, int(top - 17)), 6)
        pygame.draw.circle(surf, (255, 255, 255), (cx - 2, int(top - 19)), 2)

    # --- legs and feet ----------------------------------------------------------
    for side in (-1, 1):
        ph = leg * side
        lift = max(0.0, ph) * 9
        sway = ph * 7
        lx = cx + side * 16 + sway
        foot_top = FOOT_Y - 12 - lift
        top = 92 + bob
        _rrect(surf, ol, (lx - 10, top, 20, foot_top + 8 - top), 7)
        _rrect(surf, JOINT, (lx - 7, top + 2, 14, foot_top + 5 - top), 5)
        pygame.draw.line(surf, JOINT_DARK, (lx - 7, foot_top - 4), (lx + 7, foot_top - 4), 2)
        _rrect(surf, ol, (lx - 14, foot_top, 32, 12), 6)
        _rrect(surf, JOINT_DARK, (lx - 12, foot_top + 2, 28, 8), 4)
        _rrect(surf, (120, 130, 150), (lx - 10, foot_top + 2, 12, 3), 2)

    # --- waist joint ------------------------------------------------------------
    _rrect(surf, ol, (42, 90 + bob, 44, 18), 7)
    _rrect(surf, JOINT, (45, 92 + bob, 38, 13), 5)
    for i in range(3):
        pygame.draw.line(surf, JOINT_DARK, (52 + i * 12, 93 + bob), (52 + i * 12, 103 + bob), 2)

    # --- body ---------------------------------------------------------------------
    body = (24, 22 + bob, 80, 80)
    pygame.draw.ellipse(surf, ol, body)
    pygame.draw.ellipse(surf, pal.dark, (body[0] + 4, body[1] + 4, body[2] - 8, body[3] - 8))
    pygame.draw.ellipse(surf, pal.main, (body[0] + 4, body[1] + 3, body[2] - 12, body[3] - 14))
    _alpha_ellipse(surf, pal.light, 150, (38, 30 + bob, 34, 14))
    _alpha_ellipse(surf, (255, 255, 255), 120, (42, 33 + bob, 14, 6))

    # chest panel line + emblem
    pygame.draw.arc(surf, pal.dark, (36, 74 + bob, 56, 26), math.pi * 1.1, math.pi * 1.9, 3)
    if kind == "x":
        for dy in (0, 8):                                   # double chevron, like the mascot
            pts = [(cx - 12, 80 + bob + dy), (cx, 90 + bob + dy), (cx + 12, 80 + bob + dy),
                   (cx + 12, 85 + bob + dy), (cx, 95 + bob + dy), (cx - 12, 85 + bob + dy)]
            _poly(surf, pts, pal.accent, ol, 0.8)
    else:
        pygame.draw.circle(surf, ol, (cx, 90 + int(bob)), 10)
        pygame.draw.circle(surf, pal.accent, (cx, 90 + int(bob)), 8)
        pygame.draw.polygon(surf, ol, [(cx - 8, 88 + bob), (cx, 72 + bob), (cx + 8, 88 + bob)])
        pygame.draw.polygon(surf, pal.accent, [(cx - 6, 87 + bob), (cx, 76 + bob), (cx + 6, 87 + bob)])
        pygame.draw.circle(surf, pal.main, (cx + 2, 92 + int(bob)), 3)

    # --- arms (behind pauldrons, in front of body) ---------------------------------
    hands = []
    for side in (-1, 1):
        sh = (cx + side * 38, 64 + bob)
        hx = cx + side * (50 + 3 * arm_up)
        hy_idle = 94 + bob + side * arm * 8
        hy = hy_idle + (36 + bob - hy_idle) * arm_up
        pygame.draw.line(surf, ol, sh, (hx, hy), 15)
        pygame.draw.line(surf, pal.dark, sh, (hx, hy), 10)
        hands.append((hx, hy))

    # --- shoulder pads (fins) ------------------------------------------------------
    for side in (-1, 1):
        pts = [(36, 66), (21, 58), (11, 36), (9, 17), (26, 25), (41, 42)]
        if side == 1:
            pts = [(CANVAS - x, y) for x, y in pts]
        pts = [(x, y + bob) for x, y in pts]
        _poly(surf, pts, pal.main, ol, 0.84)
        a, b = pts[3], pts[1]
        pygame.draw.line(surf, pal.light, (a[0] + side * -4 * -1 + (4 if side == -1 else -4), a[1] + 8),
                         (b[0] + (3 if side == -1 else -3), b[1] - 6), 3)
        pygame.draw.circle(surf, pal.dark, (int(pts[5][0]), int(pts[5][1] + 6)), 3)

    # --- gloves --------------------------------------------------------------------
    for side, (hx, hy) in zip((-1, 1), hands):
        pygame.draw.circle(surf, ol, (int(hx), int(hy)), 12)
        pygame.draw.circle(surf, GLOVE, (int(hx), int(hy)), 9)
        pygame.draw.circle(surf, (78, 84, 100), (int(hx - 3), int(hy - 3)), 3)
        pygame.draw.circle(surf, GLOVE, (int(hx - side * 9), int(hy + 3)), 5)     # thumb

    # --- visor -------------------------------------------------------------------------
    _rrect(surf, ol, (35, 38 + bob, 58, 40), 17)
    _rrect(surf, VISOR, (38, 41 + bob, 52, 34), 14)
    _alpha_ellipse(surf, (150, 190, 255), 70, (42, 43 + bob, 22, 7))
    ex = cx + 3                                      # eyes look slightly toward the facing direction
    ey = 58 + bob
    if eyes == "happy":
        for dx in (-12, 12):
            pygame.draw.lines(surf, pal.eye, False,
                              [(ex + dx - 7, ey + 6), (ex + dx, ey - 5), (ex + dx + 7, ey + 6)], 5)
    elif eyes == "dead":
        for dx in (-12, 12):
            pygame.draw.line(surf, pal.eye, (ex + dx - 6, ey - 7), (ex + dx + 6, ey + 7), 4)
            pygame.draw.line(surf, pal.eye, (ex + dx - 6, ey + 7), (ex + dx + 6, ey - 7), 4)
    else:
        h = 20 if eyes == "normal" else 25
        h = max(3, int(h * (1.0 - 0.85 * blink)))
        w = 8 if eyes == "normal" else 11
        for dx in (-12, 12):
            _alpha_ellipse(surf, pal.eye_glow, 90, (ex + dx - w, ey - h // 2 - 4, w * 2, h + 8))
            _rrect(surf, pal.eye, (ex + dx - w // 2, ey - h // 2, w, h), 4)
    return surf


# ----------------------------------------------------------------------------- pose tables
def pose_for(state, i, n):
    """Returns (pose dict, tilt degrees, sx, sy, zoom, alpha) for frame i of n."""
    t = i / float(n)
    s = math.sin(t * 2 * math.pi)
    d = dict(pose={}, tilt=0.0, sx=1.0, sy=1.0, zoom=1.0, alpha=255)
    p = d["pose"]
    if state == "idle":
        blink = 1.0 if i in (9, 10) else 0.5 if i in (8, 11) else 0.0
        p.update(bob=1.6 * s, arm=0.25 * s, blink=blink)
        d.update(sx=1.0 - 0.012 * s, sy=1.0 + 0.016 * s)
    elif state == "walk":
        p.update(leg=s, arm=-s * 0.9, bob=-abs(s) * 3.5)
        d.update(tilt=-3.5, sy=1.0 + 0.02 * abs(s))
    elif state == "jump":
        p.update(arm_up=1.0 if i == 0 else 0.8, leg=0.6 if i == 0 else 0.3, bob=-2)
        d.update(tilt=-7.0, sx=0.94, sy=1.08)
    elif state == "fall":
        p.update(arm_up=0.55 + 0.15 * i, leg=-0.4, eyes="surprised", arm=0.5)
        d.update(tilt=4.0, sx=0.97, sy=1.05)
    elif state == "land":
        d.update(sx=[1.22, 1.12, 1.05, 1.0][i], sy=[0.78, 0.88, 0.95, 1.0][i])
        p.update(arm=0.8, bob=2)
    elif state == "death":
        p.update(eyes="dead", arm_up=0.7, bob=-i * 1.2)
        d.update(tilt=i * 32.0, zoom=max(0.15, 1.0 - i * 0.085), alpha=max(0, 255 - i * 24),
                 sx=1.0 + 0.03 * i, sy=1.0 - 0.02 * i)
    elif state == "victory":
        p.update(arm_up=1.0, arm=s, bob=-abs(s) * 9, eyes="happy", leg=0.0)
        d.update(tilt=s * 5.0, sy=1.0 + 0.03 * abs(s))
    return d


def _compose(canvas, tilt, sx, sy, zoom, alpha, out_size):
    w = canvas.get_width()
    surf = canvas
    if sx != 1.0 or sy != 1.0 or zoom != 1.0:
        nw, nh = max(1, int(w * sx * zoom)), max(1, int(w * sy * zoom))
        scaled = pygame.transform.smoothscale(surf, (nw, nh))
        surf = pygame.Surface((w, w), pygame.SRCALPHA)
        surf.blit(scaled, ((w - nw) // 2, w - nh - int((1 - zoom) * 0)))   # anchored at the feet
    if tilt:
        rot = pygame.transform.rotozoom(surf, tilt, 1.0)
        surf = pygame.Surface((w, w), pygame.SRCALPHA)
        surf.blit(rot, rot.get_rect(center=(w // 2, w // 2)))
    if alpha < 255:
        surf.fill((255, 255, 255, alpha), special_flags=pygame.BLEND_RGBA_MULT)
    return pygame.transform.smoothscale(surf, (out_size, out_size))


class AnimationSet:
    """All frames of one robot at one scale, for both facing directions."""

    def __init__(self, kind, scale=1, states=None):
        self.kind = kind
        self.size = BASE * scale
        self.foot_offset = FOOT_Y * self.size / CANVAS      # y of the soles inside the sprite
        self.frames = {}                                    # state -> [right-facing surfaces]
        self.frames_left = {}
        for state, (count, fps, loop) in STATE_DEFS.items():
            if states and state not in states:
                continue
            frames = self._load_files(state) or self._render(state, count)
            self.frames[state] = frames
            self.frames_left[state] = [pygame.transform.flip(f, True, False) for f in frames]

    def _render(self, state, count):
        out = []
        for i in range(count):
            d = pose_for(state, i, count)
            out.append(_compose(paint_robot(self.kind, d["pose"]), d["tilt"], d["sx"], d["sy"],
                                d["zoom"], d["alpha"], self.size))
        return out

    def _load_files(self, state):
        """Optional hand-made frames: assets/sprites/robo_<kind>/<state>_<n>.png"""
        folder = os.path.join(S.ASSETS_DIR, "sprites", "robo_" + self.kind)
        paths = sorted(glob.glob(os.path.join(folder, state + "_*.png")))
        frames = []
        for p in paths:
            try:
                img = pygame.image.load(p).convert_alpha()
                frames.append(pygame.transform.smoothscale(img, (self.size, self.size)))
            except (pygame.error, FileNotFoundError):
                return None
        return frames or None

    def get(self, state, t, facing):
        count, fps, loop = STATE_DEFS[state]
        frames = (self.frames if facing >= 0 else self.frames_left).get(state)
        if not frames:
            frames = (self.frames if facing >= 0 else self.frames_left)["idle"]
            count = len(frames)
        idx = int(t * fps)
        idx = idx % len(frames) if loop else min(idx, len(frames) - 1)
        return frames[idx]


class PlayerAnimator:
    """Tracks animation time for one Player and draws it."""

    def __init__(self, animset, player):
        self.set = animset
        self.player = player
        self.state = "idle"
        self.time = 0.0
        self.offset_phase = 0.0

    def update(self, dt):
        st = self.player.anim_state
        if st != self.state:
            self.state = st
            self.time = 0.0
        self.time += dt

    def sprite(self):
        return self.set.get(self.state, self.time, self.player.facing)

    def draw(self, screen, ox, oy):
        img = self.sprite()
        b = self.player.box
        x = int(b.centerx - img.get_width() / 2) - ox
        y = int(b.bottom - self.set.foot_offset) - oy
        screen.blit(img, (x, y))
