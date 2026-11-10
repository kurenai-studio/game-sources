"""The pixel pen: every sprite in HotDog Sports Day is painted by this file.

A piece is described as a few shaded primitives (balls, sausages, slabs) in its
own coordinates, then painted straight onto the pixel grid through a transform
(squash, stretch, lean, spin). Because the shapes are painted afresh at every
angle and squash, a spinning hot dog is as crisp as a standing one: nothing is
ever scaled or rotated as a bitmap.

The look, everywhere:
  * one light, from the upper left and a little toward us (as in Heartwood);
  * colour comes only from the ramps in palette.py, 3 to 5 steps each, and
    shadows lean cool and purple while lights lean warm;
  * a one-pixel outline in each material's darkest step (a touch lighter on
    the lit side), and a dark seam where a front part overlaps a back part;
  * a single glint on shiny things (the sausage skin, the eyes).

Nothing here knows what a hot dog is; gen_*.py do.
"""
import math

import numpy as np
from PIL import Image

LIGHT = np.array([-0.55, -0.62, 0.56])
LIGHT = LIGHT / np.linalg.norm(LIGHT)
HALF = LIGHT + np.array([0.0, 0.0, 1.0])
HALF = HALF / np.linalg.norm(HALF)


# -- transforms ----------------------------------------------------------------

class Xf:
    """A 2D affine transform, local -> pixel. Built from squash/stretch about
    the local origin, a rotation (degrees, clockwise on screen) about a pivot,
    then a move to where the local origin lands on the canvas."""

    def __init__(self, at=(0.0, 0.0), sx=1.0, sy=1.0, rot=0.0, pivot=(0.0, 0.0)):
        self.at = np.array(at, float)
        self.sx, self.sy = sx, sy
        self.rot = math.radians(rot)
        self.pivot = np.array(pivot, float)
        c, s = math.cos(self.rot), math.sin(self.rot)
        self.R = np.array([[c, -s], [s, c]])
        self.Ri = self.R.T

    def fwd(self, p):
        p = np.array(p, float) * np.array([self.sx, self.sy])
        piv = self.pivot * np.array([self.sx, self.sy])
        return self.R @ (p - piv) + piv + self.at

    def inv(self, X, Y):
        """Pixel centres (arrays) -> local coordinates."""
        piv = self.pivot * np.array([self.sx, self.sy])
        dx = X - self.at[0] - piv[0]
        dy = Y - self.at[1] - piv[1]
        lx = self.Ri[0, 0] * dx + self.Ri[0, 1] * dy + piv[0]
        ly = self.Ri[1, 0] * dx + self.Ri[1, 1] * dy + piv[1]
        return lx / self.sx, ly / self.sy

    def turn_normal(self, nx, ny):
        """Local normal xy -> screen normal xy (rotation only)."""
        return (self.R[0, 0] * nx + self.R[0, 1] * ny,
                self.R[1, 0] * nx + self.R[1, 1] * ny)


# -- primitives ------------------------------------------------------------------
# Each returns (inside mask, nx, ny, nz) for local coordinates (lx, ly).

def _seg_dist(lx, ly, a, b):
    ax, ay = a
    bx, by = b
    vx, vy = bx - ax, by - ay
    L2 = vx * vx + vy * vy
    t = np.clip(((lx - ax) * vx + (ly - ay) * vy) / max(L2, 1e-9), 0.0, 1.0)
    px, py = ax + t * vx, ay + t * vy
    return lx - px, ly - py


def ball(cx, cy, rx, ry=None):
    ry = rx if ry is None else ry

    def f(lx, ly):
        dx, dy = (lx - cx) / rx, (ly - cy) / ry
        r2 = dx * dx + dy * dy
        inside = r2 <= 1.0
        nz = np.sqrt(np.clip(1.0 - r2, 0.0, 1.0))
        return inside, dx, dy, nz
    return f


def sausage(a, b, r, flat=0.0):
    """A capsule from a to b, radius r. `flat` (0..1) flattens its roundness
    (a bun's crust is rounder than a slab of bread)."""
    def f(lx, ly):
        dx, dy = _seg_dist(lx, ly, a, b)
        d = np.sqrt(dx * dx + dy * dy)
        inside = d <= r
        k = d / r
        nz = np.sqrt(np.clip(1.0 - k * k, 0.0, 1.0))
        nx, ny = dx / r, dy / r
        if flat:
            nx, ny = nx * (1 - flat), ny * (1 - flat)
            nz = nz * (1 - flat) + flat
        return inside, nx, ny, nz
    return f


def tube(points, r):
    """A sausage along a polyline (a zigzag of mustard, a pickle spear)."""
    segs = list(zip(points[:-1], points[1:]))

    def f(lx, ly):
        best = None
        bdx = bdy = None
        for a, b in segs:
            dx, dy = _seg_dist(lx, ly, a, b)
            d2 = dx * dx + dy * dy
            if best is None:
                best, bdx, bdy = d2, dx, dy
            else:
                m = d2 < best
                best = np.where(m, d2, best)
                bdx = np.where(m, dx, bdx)
                bdy = np.where(m, dy, bdy)
        d = np.sqrt(best)
        inside = d <= r
        k = d / r
        nz = np.sqrt(np.clip(1.0 - k * k, 0.0, 1.0))
        return inside, bdx / r, bdy / r, nz
    return f


def slab(x0, y0, x1, y1, bevel=1.5, round_=0.0):
    """A box with softly bevelled edges (flat face, lit rim)."""
    def f(lx, ly):
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        hx, hy = (x1 - x0) / 2, (y1 - y0) / 2
        qx, qy = np.abs(lx - cx) - hx + round_, np.abs(ly - cy) - hy + round_
        out = np.sqrt(np.maximum(qx, 0) ** 2 + np.maximum(qy, 0) ** 2) + np.minimum(np.maximum(qx, qy), 0) - round_
        inside = out <= 0
        ex = np.clip((np.abs(lx - cx) - (hx - bevel)) / bevel, 0, 1) * np.sign(lx - cx)
        ey = np.clip((np.abs(ly - cy) - (hy - bevel)) / bevel, 0, 1) * np.sign(ly - cy)
        nx, ny = ex * 0.7, ey * 0.7
        nz = np.sqrt(np.clip(1 - nx * nx - ny * ny, 0, 1))
        return inside, nx, ny, nz
    return f


def poly(pts, bevel=0.0):
    """A filled polygon, flat-faced (bevel>0 rounds the light off its rim)."""
    P = np.array(pts, float)

    def f(lx, ly):
        inside = np.zeros(lx.shape, bool)
        n = len(P)
        j = n - 1
        for i in range(n):
            xi, yi = P[i]
            xj, yj = P[j]
            cond = ((yi > ly) != (yj > ly)) & (lx < (xj - xi) * (ly - yi) / (yj - yi + 1e-12) + xi)
            inside ^= cond
            j = i
        nx = np.zeros(lx.shape)
        ny = np.zeros(lx.shape)
        nz = np.ones(lx.shape)
        return inside, nx, ny, nz
    return f


def cut(shape, knife):
    """`shape` with `knife` taken out of it."""
    def f(lx, ly):
        i, nx, ny, nz = shape(lx, ly)
        k = knife(lx, ly)[0]
        return i & ~k, nx, ny, nz
    return f


def clip(shape, keep):
    """`shape` only where `keep` is."""
    def f(lx, ly):
        i, nx, ny, nz = shape(lx, ly)
        k = keep(lx, ly)[0]
        return i & k, nx, ny, nz
    return f


def bumps(shape, seed, scale=1.6, amount=0.35):
    """Ruffle a shape's normals (batter, crust, crumbs) without moving its edge."""
    rs = np.random.RandomState(seed)
    ph = rs.uniform(0, 6.283, 6)

    def f(lx, ly):
        i, nx, ny, nz = shape(lx, ly)
        a = np.sin(lx * scale + ph[0]) * np.cos(ly * scale * 1.3 + ph[1])
        b = np.sin(ly * scale * 0.9 + ph[2]) * np.cos(lx * scale * 1.1 + ph[3])
        return i, nx + a * amount, ny + b * amount, nz
    return f


# -- the canvas ------------------------------------------------------------------

class Part:
    def __init__(self, shape, ramp, z=0, line=True, shine=0.0, seam=True, outline=True,
                 bands=None, flat=False, key=None):
        self.shape = shape
        self.ramp = ramp          # list of RGB, dark -> light
        self.z = z
        self.line = line          # draws a seam onto parts behind it
        self.seam = seam          # takes a seam from parts in front of it
        self.outline = outline    # contributes to the outer silhouette line
        self.shine = shine        # 0 = matte; >0 = how big the glint is
        self.bands = bands        # thresholds into the ramp (len(ramp)-1 values)
        self.flat = flat          # one colour (ramp[-2] or the only one)
        self.key = key            # name of a swappable colour (team colours)


class Canvas:
    M = 3     # a clear margin all round while painting, so nothing wraps at the edges

    def __init__(self, w, h):
        self.cw, self.ch = w, h
        w, h = w + 2 * self.M, h + 2 * self.M
        self.w, self.h = w, h
        self.rgb = np.zeros((h, w, 3), np.float32)
        self.alpha = np.zeros((h, w), bool)
        self.pid = np.full((h, w), -1, np.int32)
        self.zbuf = np.full((h, w), -1e9)
        self.level = np.zeros((h, w), np.int32)     # ramp step of each pixel
        self.parts = []
        Y, X = np.mgrid[0:h, 0:w]
        self.X = X - self.M + 0.5
        self.Y = Y - self.M + 0.5

    def paint(self, part, xf):
        lx, ly = xf.inv(self.X, self.Y)
        inside, nx, ny, nz = part.shape(lx, ly)
        nx, ny = xf.turn_normal(nx, ny)
        n = np.stack([nx, ny, nz], -1)
        n = n / (np.linalg.norm(n, axis=-1, keepdims=True) + 1e-9)
        lam = np.clip((n * LIGHT).sum(-1), 0.0, 1.0)
        ramp = part.ramp
        k = len(ramp)
        if part.flat or k == 1:
            lvl = np.full(lam.shape, max(0, k - 2) if k > 1 else 0)
        else:
            bands = part.bands or default_bands(k)
            lvl = np.zeros(lam.shape, np.int32)
            for t in bands:
                lvl += (lam > t)
        if part.shine:
            spec = (n * HALF).sum(-1)
            lvl = np.where(spec > 1.0 - part.shine * 0.02, k, lvl)   # k = the glint
        win = inside & (part.z >= self.zbuf)
        pid = len(self.parts)
        self.parts.append(part)
        self.zbuf[win] = part.z
        self.pid[win] = pid
        self.level[win] = lvl[win]
        self.alpha |= win

    def finish(self, outline=True, glint=(255, 252, 240), despeckle=True):
        """Resolve colours, seams and the outline into an RGBA image."""
        h, w = self.h, self.w
        pid, level = self.pid, self.level
        if despeckle:
            level = _despeckle(pid, level)
        out = np.zeros((h, w, 4), np.uint8)
        keys = np.zeros((h, w), np.int32)        # which swappable colour, if any
        for i, part in enumerate(self.parts):
            m = pid == i
            if not m.any():
                continue
            ramp = list(part.ramp) + [glint]
            cols = np.array(ramp, np.uint8)
            lv = np.clip(level[m], 0, len(ramp) - 1)
            out[m, :3] = cols[lv]
            out[m, 3] = 255
        # seams: a back part's pixel next to a front part that draws lines
        seam = np.zeros((h, w), bool)
        seam_col = np.zeros((h, w, 3), np.uint8)
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            nb = np.roll(np.roll(pid, dy, 0), dx, 1)
            nbz = np.roll(np.roll(self.zbuf, dy, 0), dx, 1)
            for i, part in enumerate(self.parts):
                if not part.seam:
                    continue
                m = (pid == i) & (nb >= 0) & (nb != i) & (nbz > part.z + 0.01)
                if not m.any():
                    continue
                front_lines = np.zeros_like(m)
                for j, pj in enumerate(self.parts):
                    if pj.line:
                        front_lines |= (nb == j)
                m &= front_lines
                seam |= m
                seam_col[m] = np.array(part.ramp[0], np.uint8)
        out[seam, :3] = seam_col[seam]
        if outline:
            ring = np.zeros((h, w), bool)
            ring_col = np.zeros((h, w, 3), np.uint8)
            lit = np.zeros((h, w), bool)
            for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                nb = np.roll(np.roll(pid, -dy, 0), -dx, 1)
                okm = (~self.alpha) & (nb >= 0)
                for i, part in enumerate(self.parts):
                    if not part.outline:
                        continue
                    m = okm & (nb == i) & ~ring
                    ring_col[m] = np.array(part.ramp[0], np.uint8)
                    ring |= m
                    if dy == 1 or dx == 1:   # the neighbour is below/right: we are on its upper-left, lit side
                        lit |= m
            out[ring, :3] = ring_col[ring]
            out[ring, 3] = 255
        M = self.M
        return np.ascontiguousarray(out[M:M + self.ch, M:M + self.cw])


def default_bands(k):
    # light value thresholds: more of each ramp's middle, small deep shade
    presets = {
        2: [0.35],
        3: [0.22, 0.62],
        4: [0.14, 0.40, 0.74],
        5: [0.10, 0.30, 0.55, 0.82],
        6: [0.08, 0.24, 0.44, 0.64, 0.86],
    }
    return presets[k]


def _despeckle(pid, level):
    """A lone pixel of one shade surrounded by another (same part) takes its
    neighbours' shade: bands read as clean shapes, not noise."""
    lv = level.copy()
    up = np.roll(level, 1, 0)
    dn = np.roll(level, -1, 0)
    lf = np.roll(level, 1, 1)
    rt = np.roll(level, -1, 1)
    pu = np.roll(pid, 1, 0)
    pd = np.roll(pid, -1, 0)
    pl = np.roll(pid, 1, 1)
    pr = np.roll(pid, -1, 1)
    same = (pu == pid) & (pd == pid) & (pl == pid) & (pr == pid)
    agree = (up == dn) & (lf == rt) & (up == lf)
    m = same & agree & (level != up)
    lv[m] = up[m]
    return lv


def to_image(rgba):
    return Image.fromarray(rgba).copy()


def stamp(img, rows, palette, at, flip=False, rot=0):
    """Draw a hand-made pixel stamp: `rows` are strings, each character a key
    into `palette` ('.' or ' ' is clear). `at` is where the stamp's centre goes."""
    grid = [list(r) for r in rows]
    a = np.array(grid)
    if flip:
        a = a[:, ::-1]
    if rot:
        a = np.rot90(a, -rot)
    h, w = a.shape
    x0 = int(round(at[0] - w / 2))
    y0 = int(round(at[1] - h / 2))
    px = img.load()
    for y in range(h):
        for x in range(w):
            ch = a[y, x]
            if ch in ". ":
                continue
            X, Y = x0 + x, y0 + y
            if 0 <= X < img.width and 0 <= Y < img.height:
                c = palette[ch]
                px[X, Y] = tuple(c) + ((255,) if len(c) == 3 else ())
    return img


def sheet(frames, cols):
    """Frames (same size RGBA arrays) into one image, row by row."""
    h, w = frames[0].shape[:2]
    rows = (len(frames) + cols - 1) // cols
    out = np.zeros((rows * h, cols * w, 4), np.uint8)
    for i, f in enumerate(frames):
        r, c = divmod(i, cols)
        out[r * h:(r + 1) * h, c * w:(c + 1) * w] = f
    return Image.fromarray(out).copy()


def scale_up(img, k):
    return img.resize((img.width * k, img.height * k), Image.NEAREST)
