"""Draws a Level. Reads game state, never changes it.

Static geometry (tiles, spikes) is pre-rendered once into one big surface; animated things
(lava, water, mechanisms, crystals) are drawn every frame, only when on screen.
"""
import math
import random
import pygame
from . import settings as S
from .ui import add_glow, draw_text, draw_panel

T = S.TILE
ID_COLORS = [(255, 96, 96), (90, 204, 255), (255, 222, 72), (120, 255, 148), (255, 144, 232), (255, 164, 64)]

TILE_THEMES = {
    "factory":   dict(base=(60, 68, 88), light=(104, 116, 144), dark=(34, 40, 56), accent=(255, 172, 44)),
    "abandoned": dict(base=(78, 72, 68), light=(120, 110, 100), dark=(46, 42, 42), accent=(176, 112, 62)),
    "lab":       dict(base=(66, 86, 108), light=(118, 154, 184), dark=(36, 52, 70), accent=(90, 230, 255)),
    "cave":      dict(base=(66, 52, 96), light=(110, 90, 156), dark=(36, 28, 58), accent=(176, 124, 255)),
    "core":      dict(base=(70, 54, 58), light=(120, 92, 96), dark=(38, 28, 32), accent=(255, 96, 52)),
    "space":     dict(base=(58, 64, 96), light=(100, 110, 160), dark=(30, 34, 58), accent=(140, 190, 255)),
}


def _shade(c, d):
    return tuple(max(0, min(255, v + d)) for v in c)


class LevelRenderer:
    def __init__(self, level, fonts):
        self.lv = level
        self.fonts = fonts
        self.pal = TILE_THEMES.get(level.theme, TILE_THEMES["factory"])
        self.id_colors = {bid: ID_COLORS[i % len(ID_COLORS)] for i, bid in enumerate(sorted(level.buttons))}
        self.pool_surfs = {}
        self.static = self._build_static()
        self.sign_cache = {}

    # ------------------------------------------------------------------ static geometry
    def _build_static(self):
        lv = self.lv
        surf = pygame.Surface((lv.pixel_w, lv.pixel_h), pygame.SRCALPHA)
        rng = random.Random(lv.index + 11)
        for r in range(lv.rows):
            for c in range(lv.cols):
                if lv.grid[r][c] == "#":
                    self._tile(surf, c, r, rng)
        for c, r in lv.spike_tiles:
            self._spikes(surf, c * T, r * T)
        return surf

    def _tile(self, s, c, r, rng):
        lv, p = self.lv, self.pal
        x, y = c * T, r * T
        v = (c * 7 + r * 13) % 3
        up, dn = lv.is_solid_tile(c, r - 1), lv.is_solid_tile(c, r + 1)
        lf, rt = lv.is_solid_tile(c - 1, r), lv.is_solid_tile(c + 1, r)
        interior = up and dn and lf and rt
        base = _shade(p["base"], (v - 1) * 5 - (14 if interior else 0))
        pygame.draw.rect(s, base, (x, y, T, T))
        if interior:                                          # recessed panel look
            pygame.draw.rect(s, _shade(p["dark"], 6), (x + 3, y + 3, T - 6, T - 6), 2)
            if (c + r) % 3 == 0:
                pygame.draw.line(s, _shade(p["dark"], 10), (x + 6, y + 6), (x + T - 7, y + T - 7), 2)
        else:
            pygame.draw.rect(s, _shade(base, -10), (x + 2, y + 2, T - 4, T - 4), 1)
        if not up:
            pygame.draw.rect(s, p["accent"], (x, y, T, 5))
            pygame.draw.rect(s, _shade(p["accent"], 60), (x, y, T, 2))
            pygame.draw.rect(s, p["light"], (x, y + 5, T, 3))
        if not dn:
            pygame.draw.rect(s, p["dark"], (x, y + T - 5, T, 5))
        if not lf:
            pygame.draw.rect(s, p["light"], (x, y, 3, T))
        if not rt:
            pygame.draw.rect(s, p["dark"], (x + T - 3, y, 3, T))
        if not interior:
            if lv.theme == "cave":
                for _ in range(3):
                    pygame.draw.circle(s, _shade(p["light"], rng.randint(-20, 30)),
                                       (x + rng.randint(6, T - 6), y + rng.randint(10, T - 6)), rng.randint(1, 3))
            else:
                for (rx, ry) in ((6, 12), (T - 7, 12), (6, T - 8), (T - 7, T - 8)):
                    pygame.draw.circle(s, p["dark"], (x + rx, y + ry), 2)
                    pygame.draw.circle(s, p["light"], (x + rx - 1, y + ry - 1), 1)

    def _spikes(self, s, x, y):
        pygame.draw.rect(s, (40, 44, 58), (x, y + T - 9, T, 9))
        for i in range(4):
            bx = x + i * 10
            pts = [(bx + 1, y + T - 9), (bx + 9, y + T - 9), (bx + 5, y + 10)]
            pygame.draw.polygon(s, (30, 34, 46), pts)
            pygame.draw.polygon(s, (190, 200, 220), [(bx + 3, y + T - 10), (bx + 7, y + T - 10), (bx + 5, y + 15)])

    # ------------------------------------------------------------------ main draw
    def draw(self, screen, ox, oy, t, players):
        lv = self.lv
        screen.blit(self.static, (-ox, -oy))
        vis = pygame.Rect(ox - 80, oy - 80, S.SCREEN_W + 160, S.SCREEN_H + 160)
        for pool in lv.pools:
            if vis.colliderect(pool.rect):
                self._pool(screen, pool, ox, oy, t)
        for b in lv.bridges:
            self._bridge(screen, b, ox, oy, t)
        for f in lv.fadings:
            self._fading(screen, f, ox, oy, t)
        for m in lv.movers:
            self._mover(screen, m, ox, oy, t)
        for d in lv.doors:
            self._door(screen, d, ox, oy)
        for b in lv.buttons.values():
            self._button(screen, b, ox, oy)
        for bar in lv.barriers:
            self._barrier(screen, bar, ox, oy, t)
        for kind in ("x", "b"):
            self._exit(screen, kind, ox, oy, t, players)
        for cr in lv.crystals:
            if not cr.collected and vis.collidepoint(cr.x, cr.y):
                self._crystal(screen, cr, ox, oy, t)
        for sg in lv.signs:
            self._sign(screen, sg, ox, oy)

    # ------------------------------------------------------------------ pools
    def _pool(self, screen, pool, ox, oy, t):
        x, y, w, h = pool.rect
        key = id(pool)
        surf = self.pool_surfs.get(key)
        if surf is None:
            surf = pygame.Surface((w, h), pygame.SRCALPHA)
            self.pool_surfs[key] = surf
        surf.fill((0, 0, 0, 0))
        lava = pool.kind == "lava"
        pts, low = [], []
        for px in range(0, w + 1, 8):
            wy = 9 + math.sin(t * 2.6 + (x + px) * 0.06) * 2.5 + math.sin(t * 1.7 + (x + px) * 0.13) * 1.5
            pts.append((px, wy))
            low.append((px, wy + 7))
        body = (226, 66, 18, 255) if lava else (46, 146, 240, 205)
        band = (255, 186, 56, 255) if lava else (176, 228, 255, 235)
        pygame.draw.polygon(surf, body, pts + [(w, h), (0, h)])
        pygame.draw.polygon(surf, band, pts + list(reversed(low)))
        for i in range(w // 26):                               # drifting highlights / blobs
            px = (i * 26 + int(t * (18 if lava else 28))) % w
            py = 18 + (i * 7) % 14
            if lava:
                pygame.draw.ellipse(surf, (255, 150, 40, 255), (px, py, 10, 5))
            else:
                pygame.draw.line(surf, (200, 240, 255, 200), (px, py), (px + 12, py), 2)
        screen.blit(surf, (x - ox, y - oy))

    # ------------------------------------------------------------------ mechanisms
    def _lamp(self, screen, x, y, color, on):
        pygame.draw.circle(screen, (16, 18, 28), (int(x), int(y)), 6)
        pygame.draw.circle(screen, color if on else tuple(c // 4 for c in color), (int(x), int(y)), 4)

    def _door(self, screen, d, ox, oy):
        f = d.full
        x, y, w, h = int(f.x - ox), int(f.y - oy), int(f.w), int(f.h)
        pygame.draw.rect(screen, (22, 26, 38), (x, y, w, h))                     # slot behind the panel
        ph = int(d.solid_box.h)
        if ph > 0:
            pygame.draw.rect(screen, (96, 106, 130), (x + 2, y, w - 4, ph))
            for ry in range(10, ph, 14):
                pygame.draw.line(screen, (66, 74, 96), (x + 3, y + ry), (x + w - 4, y + ry), 2)
            pygame.draw.rect(screen, (150, 160, 184), (x + 2, y, 3, ph))
            for sx in range(x + 2, x + w - 4, 10):                               # hazard stripe along the bottom
                pygame.draw.rect(screen, S.C_YELLOW, (sx, y + ph - 8, 5, 8))
                pygame.draw.rect(screen, (30, 30, 36), (sx + 5, y + ph - 8, 5, 8))
        pygame.draw.rect(screen, (52, 58, 78), (x - 6, y - 12, 6, h + 12))
        pygame.draw.rect(screen, (52, 58, 78), (x + w, y - 12, 6, h + 12))
        pygame.draw.rect(screen, (40, 46, 64), (x - 6, y - 14, w + 12, 12))
        n = len(d.triggers)
        for i, tid in enumerate(d.triggers):
            lx = x + w / 2 + (i - (n - 1) / 2.0) * 13
            self._lamp(screen, lx, y - 8, self.id_colors.get(tid, S.C_WHITE), self.lv.signals.get(tid, False))

    def _bridge(self, screen, b, ox, oy, t):
        x0, y = int(b.origin_x - ox), int(b.box.y - oy)
        if b.box.w < b.full_w:                                                   # faint guide dots
            for gx in range(int(b.box.w), int(b.full_w), 18):
                pygame.draw.circle(screen, (60, 110, 140), (x0 + gx, y + 6), 2)
        pygame.draw.rect(screen, (40, 46, 64), (x0 - 12, y - 6, 14, 32), border_radius=4)
        n = len(b.triggers)
        for i, tid in enumerate(b.triggers):
            self._lamp(screen, x0 - 5, y + 2 + i * 12, self.id_colors.get(tid, S.C_WHITE), self.lv.signals.get(tid, False))
        w = int(b.box.w)
        if w > 2:
            pygame.draw.rect(screen, (30, 110, 160), (x0, y, w, 16))
            pygame.draw.rect(screen, (120, 236, 255), (x0, y, w, 5))
            for gx in range(10, w, 20):
                pygame.draw.line(screen, (20, 70, 110), (x0 + gx, y + 5), (x0 + gx, y + 15), 2)
            pulse = int(160 + 80 * math.sin(t * 6))
            pygame.draw.rect(screen, (pulse, 255, 255), (x0 + w - 4, y, 4, 16))

    def _mover(self, screen, m, ox, oy, t):
        if m.triggers or True:
            a = (m.start[0] + m.box.w / 2 - ox, m.start[1] + 9 - oy)
            e = (m.end[0] + m.box.w / 2 - ox, m.end[1] + 9 - oy)
            dist = max(1.0, math.hypot(e[0] - a[0], e[1] - a[1]))
            for i in range(0, int(dist), 14):
                f = i / dist
                pygame.draw.circle(screen, (70, 82, 110), (int(a[0] + (e[0] - a[0]) * f), int(a[1] + (e[1] - a[1]) * f)), 2)
        x, y, w, h = [int(v) for v in (m.box.x - ox, m.box.y - oy, m.box.w, m.box.h)]
        pygame.draw.rect(screen, (30, 34, 48), (x - 1, y - 1, w + 2, h + 2), border_radius=6)
        pygame.draw.rect(screen, (128, 138, 164), (x + 1, y + 1, w - 2, h - 2), border_radius=5)
        pygame.draw.rect(screen, (190, 200, 224), (x + 3, y + 2, w - 6, 4), border_radius=2)
        for sx in range(x + 6, x + w - 12, 16):
            pygame.draw.polygon(screen, S.C_YELLOW, [(sx, y + h - 3), (sx + 8, y + h - 3), (sx + 12, y + 8), (sx + 4, y + 8)])
        for tx in (x + 10, x + w - 10):                                          # thruster glow
            pygame.draw.circle(screen, (90, 200, 255), (tx, y + h + 3), 3)

    def _fading(self, screen, f, ox, oy, t):
        x, y, w, h = [int(v) for v in (f.box.x - ox, f.box.y - oy, f.box.w, f.box.h)]
        if f.state == f.GONE:
            for dx in range(0, w, 10):
                pygame.draw.line(screen, (90, 100, 130), (x + dx, y), (x + dx + 4, y), 2)
            return
        shake = int(math.sin(t * 70) * 3 * f.progress) if f.state == f.CRUMBLING else 0
        k = int(120 * f.progress)
        col = (110 + k, 122 - k // 2, 150 - k)
        pygame.draw.rect(screen, (30, 34, 48), (x + shake - 1, y - 1, w + 2, h + 2), border_radius=5)
        pygame.draw.rect(screen, col, (x + shake, y, w, h), border_radius=5)
        pygame.draw.rect(screen, _shade(col, 50), (x + shake + 2, y + 2, w - 4, 4))
        for cx in range(x + 14, x + w - 6, T):
            pygame.draw.lines(screen, (40, 44, 60), False, [(cx + shake, y + 2), (cx - 4 + shake, y + 9), (cx + 3 + shake, y + h - 2)], 2)

    def _button(self, screen, b, ox, oy):
        x, y = b.col * T - ox, (b.row + 1) * T - oy
        col = self.id_colors.get(b.id, S.C_WHITE)
        pygame.draw.rect(screen, (30, 34, 48), (x + 2, y - 5, T - 4, 5), border_radius=2)
        drop = 3 if b.active else 0
        cap = col if b.active else tuple(int(c * 0.55) for c in col)
        pygame.draw.rect(screen, (20, 22, 32), (x + 6, y - 11 + drop, T - 12, 7 - drop + 3), border_radius=4)
        pygame.draw.rect(screen, cap, (x + 8, y - 10 + drop, T - 16, 6 - drop + 2), border_radius=3)
        if b.latch:                                                             # small notch marks latching buttons
            pygame.draw.rect(screen, (255, 255, 255), (x + T // 2 - 2, y - 9 + drop, 4, 2))

    def _barrier(self, screen, bar, ox, oy, t):
        b = bar.rect_box
        x, y, w, h = [int(v) for v in (b.x - ox, b.y - oy, b.w, b.h)]
        if bar.vertical:
            cx = x + w // 2
            pygame.draw.rect(screen, (46, 52, 72), (cx - 13, y, 26, 11), border_radius=4)
            pygame.draw.rect(screen, (46, 52, 72), (cx - 13, y + h - 11, 26, 11), border_radius=4)
            ends = ((cx, y + 11), (cx, y + h - 11))
        else:
            cy = y + h // 2
            pygame.draw.rect(screen, (46, 52, 72), (x, cy - 13, 11, 26), border_radius=4)
            pygame.draw.rect(screen, (46, 52, 72), (x + w - 11, cy - 13, 11, 26), border_radius=4)
            ends = ((x + 11, cy), (x + w - 11, cy))
        for i, tid in enumerate(bar.triggers[:2]):
            lx, ly = (ends[0][0] + (i - 0.5) * 12, ends[0][1] - 6) if bar.vertical else (ends[0][0] - 6, ends[0][1] + (i - 0.5) * 12)
            self._lamp(screen, lx, ly, self.id_colors.get(tid, S.C_WHITE), self.lv.signals.get(tid, False))
        if not bar.active:
            return
        rng = random.Random(int(t * 24) * 31 + int(b.x))
        (x0, y0), (x1, y1) = ends
        pts = [(x0, y0)]
        steps = max(2, int(math.hypot(x1 - x0, y1 - y0) // 12))
        for i in range(1, steps):
            f = i / float(steps)
            jx, jy = rng.uniform(-11, 11), rng.uniform(-11, 11)
            pts.append((x0 + (x1 - x0) * f + (jx if bar.vertical else 0), y0 + (y1 - y0) * f + (0 if bar.vertical else jy)))
        pts.append((x1, y1))
        pygame.draw.lines(screen, (70, 110, 255), False, pts, 8)
        pygame.draw.lines(screen, (160, 210, 255), False, pts, 4)
        pygame.draw.lines(screen, (255, 255, 255), False, pts, 1)

    def _exit(self, screen, kind, ox, oy, t, players):
        ex = self.lv.exits[kind]
        x, y = int(ex.x - ox), int(ex.y - oy)
        col = S.C_RED if kind == "x" else S.C_CYAN
        occupied = any(p.kind == kind and p.at_door for p in players)
        unlocked = self.lv.exit_label_ok()
        pygame.draw.rect(screen, (14, 16, 26), (x - 4, y - 4, T + 8, 2 * T + 4), border_top_left_radius=22, border_top_right_radius=22)
        inner = _shade(col, -60) if not occupied else _shade(col, 40)
        pygame.draw.rect(screen, inner, (x, y, T, 2 * T), border_top_left_radius=18, border_top_right_radius=18)
        pygame.draw.rect(screen, (8, 10, 20), (x + 6, y + 10, T - 12, 2 * T - 10), border_top_left_radius=12, border_top_right_radius=12)
        if occupied:
            pygame.draw.rect(screen, _shade(col, 90), (x + 8, y + 12, T - 16, 2 * T - 12), border_top_left_radius=10, border_top_right_radius=10)
        pulse = 2 + int(2 * math.sin(t * 4))
        pygame.draw.rect(screen, col, (x - 4 - pulse // 2, y - 4 - pulse // 2, T + 8 + pulse, 2 * T + 4 + pulse // 2), 3,
                         border_top_left_radius=22, border_top_right_radius=22)
        draw_text(screen, self.fonts, "X" if kind == "x" else "B", 22, S.C_WHITE, (x + T // 2, y + 44), "center")
        if not unlocked:                                                         # padlock + requirement
            pygame.draw.rect(screen, S.C_YELLOW, (x + T // 2 - 8, y + 12, 16, 12), border_radius=3)
            pygame.draw.arc(screen, S.C_YELLOW, (x + T // 2 - 6, y + 4, 12, 14), 0, math.pi, 3)
            draw_text(screen, self.fonts, "%d/%d" % (self.lv.crystals_collected, self.lv.required_crystals), 13,
                      S.C_YELLOW, (x + T // 2, y - 14), "center")

    def _crystal(self, screen, c, ox, oy, t):
        x, y = c.x - ox, c.y - oy + c.bob
        pts = [(x, y - 13), (x + 9, y), (x, y + 13), (x - 9, y)]
        pygame.draw.polygon(screen, (150, 100, 0), [(px, py + 1) for px, py in pts])
        pygame.draw.polygon(screen, S.C_YELLOW, pts)
        pygame.draw.polygon(screen, (255, 245, 170), [(x, y - 11), (x + 4, y - 1), (x, y + 2), (x - 5, y - 1)])
        pygame.draw.polygon(screen, (200, 140, 0), pts, 2)
        a = t * 2 + c.phase
        if math.sin(a) > 0.85:
            pygame.draw.line(screen, (255, 255, 255), (x + 5, y - 8), (x + 11, y - 14), 2)
            pygame.draw.line(screen, (255, 255, 255), (x + 11, y - 8), (x + 5, y - 14), 2)

    def _sign(self, screen, sg, ox, oy):
        txt = sg["text"]
        img = self.sign_cache.get(txt)
        if img is None:
            img = self.fonts.get(15, False).render(txt, True, (225, 240, 255))
            self.sign_cache[txt] = img
        x, y = sg["col"] * T - ox, sg["row"] * T - oy
        if x > S.SCREEN_W or x + img.get_width() < -20:
            return
        draw_panel(screen, (x - 8, y - 4, img.get_width() + 16, img.get_height() + 8), (10, 16, 36), 170, (90, 130, 200), 8, 2)
        screen.blit(img, (x, y))

    # ------------------------------------------------------------------ lighting
    def draw_lights(self, screen, ox, oy, t, players):
        lv = self.lv
        for pool in lv.pools:
            x, y, w, h = pool.rect
            if x + w < ox - 60 or x > ox + S.SCREEN_W + 60:
                continue
            col = (150, 62, 8) if pool.kind == "lava" else (20, 70, 120)
            for px in range(0, w, 50):
                add_glow(screen, x + px + 25 - ox, y + 8 - oy, 56, col, 0.8 + 0.2 * math.sin(t * 3 + px))
        for c in lv.crystals:
            if not c.collected:
                add_glow(screen, c.x - ox, c.y - oy + c.bob, 30, (120, 96, 16))
        for bar in lv.barriers:
            if bar.active:
                b = bar.rect_box
                add_glow(screen, b.centerx - ox, b.centery - oy, 70, (30, 50, 140), 0.9)
        for b in lv.buttons.values():
            if b.active:
                add_glow(screen, b.col * T + 20 - ox, (b.row + 1) * T - 8 - oy, 34, tuple(c // 3 for c in self.id_colors[b.id]))
        for br in lv.bridges:
            if br.box.w > 2:
                add_glow(screen, br.origin_x + br.box.w / 2 - ox, br.box.y + 8 - oy, 60, (20, 80, 110), 0.7)
        for p in players:
            col = (90, 26, 26) if p.kind == "x" else (20, 60, 100)
            if p.alive:
                add_glow(screen, p.box.centerx - ox, p.box.centery - oy, 60, col, 0.8)
            if p.at_door:
                add_glow(screen, lv.exits[p.kind].centerx - ox, lv.exits[p.kind].centery - oy, 80, tuple(c * 2 for c in col))


def draw_selector(screen, player, ox, oy, t):
    """Bobbing arrow above the robot that currently has camera focus."""
    if not player.alive:
        return
    col = (255, 90, 80) if player.kind == "x" else (80, 200, 255)
    cx = player.box.centerx - ox
    tip = player.box.top - oy - 14 + math.sin(t * 6) * 3
    pts = [(cx, tip), (cx - 9, tip - 13), (cx + 9, tip - 13)]
    pygame.draw.polygon(screen, (10, 12, 24), [(px, py + 1) for px, py in pts], 0)
    pygame.draw.polygon(screen, col, pts)
    pygame.draw.polygon(screen, (255, 255, 255), pts, 2)
