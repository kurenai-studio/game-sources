"""Procedural parallax backgrounds, one look per theme.

Each layer is a 1600px-wide strip drawn once at load time and tiled while scrolling
at its own speed factor, which gives depth without any image assets.
"""
import math
import random
import pygame
from . import settings as S

LAYER_W = 1600

THEMES = {
    "factory":   dict(sky=((16, 30, 66), (60, 104, 168)), far=(36, 62, 110), mid=(26, 46, 86), near=(16, 28, 54), glow=(255, 176, 64)),
    "abandoned": dict(sky=((36, 30, 50), (132, 98, 98)), far=(78, 62, 80), mid=(56, 46, 66), near=(34, 28, 44), glow=(255, 196, 130)),
    "lab":       dict(sky=((8, 28, 52), (40, 120, 140)), far=(26, 74, 102), mid=(16, 54, 80), near=(10, 36, 58), glow=(110, 242, 255)),
    "cave":      dict(sky=((18, 10, 42), (58, 32, 100)), far=(50, 34, 88), mid=(36, 24, 68), near=(22, 14, 44), glow=(196, 124, 255)),
    "core":      dict(sky=((30, 8, 14), (112, 38, 30)), far=(86, 38, 42), mid=(60, 26, 34), near=(38, 16, 24), glow=(255, 112, 52)),
    "space":     dict(sky=((4, 6, 20), (28, 30, 80)), far=(40, 44, 100), mid=(28, 30, 76), near=(18, 20, 52), glow=(150, 190, 255)),
}


def _gradient(w, h, top, bottom):
    surf = pygame.Surface((w, h))
    for y in range(h):
        f = y / float(h - 1)
        c = tuple(int(top[i] + (bottom[i] - top[i]) * f) for i in range(3))
        pygame.draw.line(surf, c, (0, y), (w, y))
    return surf


def _lit(color, f):
    return tuple(min(255, int(c * f)) for c in color)


def _windows(surf, rng, rect, color, glow, density=0.35):
    x, y, w, h = rect
    for wy in range(int(y) + 10, int(y + h) - 10, 16):
        for wx in range(int(x) + 8, int(x + w) - 10, 14):
            if rng.random() < density:
                pygame.draw.rect(surf, glow if rng.random() < 0.5 else _lit(color, 1.5), (wx, wy, 6, 8))


def _gear(surf, cx, cy, r, teeth, color, hole):
    pts = []
    for i in range(teeth * 2):
        a = i * math.pi / teeth
        rad = r if i % 2 == 0 else r * 0.82
        pts += [(cx + math.cos(a - 0.12) * rad, cy + math.sin(a - 0.12) * rad),
                (cx + math.cos(a + 0.12) * rad, cy + math.sin(a + 0.12) * rad)]
    pygame.draw.polygon(surf, color, pts)
    pygame.draw.circle(surf, hole, (int(cx), int(cy)), int(r * 0.35))


def _layer(theme, depth, rng):
    th = THEMES[theme]
    H = S.SCREEN_H
    surf = pygame.Surface((LAYER_W, H), pygame.SRCALPHA)
    col = (th["far"], th["mid"], th["near"])[depth]
    glow = th["glow"]
    base = H
    if theme in ("factory", "core", "lab", "abandoned", "space"):
        x = 0
        while x < LAYER_W - 60:
            w = rng.randint(70, 150) * (1 + depth * 0.2)
            w = int(min(w, LAYER_W - x - 4))
            h = rng.randint(140, 330) + depth * 70
            if theme == "abandoned":
                h = rng.randint(100, 300) + depth * 60
            rect = (x, base - h, w, h)
            if theme == "lab":
                pygame.draw.rect(surf, col, rect, border_radius=w // 2 if depth == 0 else 10)
                pygame.draw.rect(surf, _lit(glow, 0.45), (x + w // 4, base - h + h // 3, w // 2, h // 2), border_radius=8)
            else:
                pygame.draw.rect(surf, col, rect)
                if theme == "abandoned":      # broken, jagged roof
                    for i in range(0, w, 14):
                        pygame.draw.polygon(surf, (0, 0, 0, 0), [(x + i, base - h), (x + i + 14, base - h), (x + i + 7, base - h + rng.randint(4, 22))])
                if theme == "factory" and rng.random() < 0.5:
                    pygame.draw.rect(surf, _lit(col, 0.8), (x + w // 2 - 8, base - h - 60, 16, 60))
            _windows(surf, rng, rect, col, glow, 0.25 if depth else 0.4)
            x += w + rng.randint(6, 40)
        if theme in ("factory", "core") and depth >= 1:
            for _ in range(3):
                _gear(surf, rng.randint(80, LAYER_W - 80), rng.randint(180, 420), rng.randint(40, 90) * (depth),
                      rng.randint(8, 14), _lit(col, 1.25), col)
        if theme == "core":
            for gx in range(60, LAYER_W, 260):
                pygame.draw.rect(surf, _lit(glow, 0.55 - depth * 0.12), (gx, base - 250, 10, 110))
    elif theme == "cave":
        x = 0
        while x < LAYER_W:                                     # stalactites from the ceiling
            w, h = rng.randint(40, 110), rng.randint(60, 220) + depth * 50
            pygame.draw.polygon(surf, col, [(x, 0), (x + w, 0), (x + w // 2, h)])
            x += w - rng.randint(0, 20)
        x = 0
        while x < LAYER_W - 40:                                # stalagmites / crystals from the floor
            w, h = rng.randint(40, 100), rng.randint(60, 200)
            pygame.draw.polygon(surf, col, [(x, base), (x + w, base), (x + w // 2, base - h)])
            if rng.random() < 0.5 and depth < 2:
                cxx, cyy = x + w // 2, base - h // 2
                pts = [(cxx, cyy - 38), (cxx + 12, cyy), (cxx, cyy + 38), (cxx - 12, cyy)]
                pygame.draw.polygon(surf, _lit(glow, 0.6 - depth * 0.15), pts)
                pygame.draw.polygon(surf, _lit(glow, 0.9), pts, 2)
            x += w + rng.randint(0, 50)
    # horizontal pipes / cables on every theme except the cave
    if theme != "cave":
        for _ in range(2 + depth):
            y = rng.randint(40, 300)
            pygame.draw.rect(surf, _lit(col, 1.2), (0, y, LAYER_W, 8 + depth * 4))
            for px in range(40, LAYER_W, 200):
                pygame.draw.rect(surf, _lit(col, 0.8), (px, y - 3, 10, 14 + depth * 4))
    if depth == 2:                                             # hanging cables in the foreground
        for _ in range(8):
            x = rng.randint(10, LAYER_W - 10)
            pygame.draw.line(surf, _lit(col, 1.5), (x, 0), (x + rng.randint(-20, 20), rng.randint(60, 200)), 3)
    return surf


class Background:
    FACTORS = (0.12, 0.28, 0.55)

    def __init__(self, theme, seed=1, view_w=S.SCREEN_W, view_h=S.SCREEN_H):
        theme = theme if theme in THEMES else "factory"
        self.theme = theme
        self.view_w, self.view_h = view_w, view_h
        th = THEMES[theme]
        self.sky = _gradient(view_w, view_h, *th["sky"])
        rng = random.Random(seed * 101 + len(theme))
        self.layers = [_layer(theme, d, rng) for d in range(3)]
        self.stars = [(rng.randint(0, view_w), rng.randint(0, view_h // 2), rng.random()) for _ in range(40)]

    def draw(self, screen, cam_x, t=0.0):
        screen.blit(self.sky, (0, 0))
        for sx, sy, ph in self.stars:
            b = int(120 + 100 * math.sin(t * 1.5 + ph * 6))
            screen.set_at((int(sx), int(sy)), (b, b, min(255, b + 30)))
        for layer, f in zip(self.layers, self.FACTORS):
            x0 = -(int(cam_x * f) % LAYER_W)
            screen.blit(layer, (x0, self.view_h - layer.get_height()))
            screen.blit(layer, (x0 + LAYER_W, self.view_h - layer.get_height()))
