"""Procedural neon-cyberpunk backdrop and ambient animation.

Drawn once per frame *behind* every scene (see ``Game.run``), so all
screens share the same cinematic look: gradient sky, deep-purple horizon
glow, a cyber-city skyline with flickering windows, a scrolling
perspective grid and slow-drifting light motes.

Everything is generated procedurally - no external artwork.
"""

from __future__ import annotations

import math
import random

import pygame

from . import theme

_WINDOW_TONES = [(0, 78, 96), (74, 22, 74), (44, 30, 104), (0, 60, 90)]
_LIT_TONES = [theme.CYAN, theme.MAGENTA, theme.VIOLET, theme.PINK]


class Backdrop:
    """Animated background shared by every screen."""

    def __init__(self, seed: int = 1337):
        self.w, self.h = theme.BASE_W, theme.BASE_H
        self.t = 0.0
        rng = random.Random(seed)

        self._sky = pygame.Surface((self.w, self.h))
        theme.vgrad(self._sky, self._sky.get_rect(),
                    theme.BG_TOP, theme.BG, step=6)

        self.horizon = int(self.h * 0.70)

        # --- cyber-city skyline -------------------------------------------
        self.buildings = []
        x = -30
        while x < self.w + 40:
            bw = rng.randint(46, 108)
            bh = rng.randint(70, 250)
            windows = []
            for wx in range(6, bw - 8, 13):
                for wy in range(8, bh - 10, 16):
                    if rng.random() < 0.55:
                        windows.append((wx, wy,
                                        rng.choice(_WINDOW_TONES),
                                        rng.random() * math.tau,
                                        rng.choice(_LIT_TONES)))
            self.buildings.append((x, bw, bh, windows))
            x += bw + rng.randint(4, 20)

        # --- drifting light motes -----------------------------------------
        self.motes = [{
            "x": rng.uniform(0, self.w),
            "y": rng.uniform(0, self.h),
            "vx": rng.uniform(-6, 6),
            "vy": rng.uniform(-14, -4),
            "r": rng.uniform(1.2, 3.0),
            "phase": rng.uniform(0, math.tau),
            "color": rng.choice([theme.CYAN, theme.MAGENTA, theme.VIOLET]),
        } for _ in range(44)]

    # ------------------------------------------------------------------ draw
    def draw(self, surface, dt: float = 0.016, particles: bool = True) -> None:
        self.t += max(dt, 0.0)
        t = self.t

        surface.blit(self._sky, (0, 0))

        # horizon bloom
        band = pygame.Rect(0, self.horizon - 90, self.w, 150)
        theme.alpha_rect(surface, band, theme.BG_HORIZON, 110, radius=0)
        theme.alpha_rect(surface, pygame.Rect(0, self.horizon - 26, self.w, 60),
                         theme.VIOLET, 70)

        # skyline
        base = self.horizon + 24
        for bx, bw, bh, windows in self.buildings:
            rect = pygame.Rect(bx, base - bh, bw, bh)
            pygame.draw.rect(surface, (11, 8, 26), rect)
            pygame.draw.rect(surface, (30, 20, 62), rect, 1)
            for i, (wx, wy, tone, phase, lit) in enumerate(windows):
                flicker = math.sin(t * 0.9 + phase + i * 0.37)
                color = lit if flicker > 0.86 else tone
                pygame.draw.rect(surface, color,
                                 (rect.x + wx, rect.y + wy, 7, 9))

        # perspective grid along the floor
        floor = pygame.Rect(0, base, self.w, self.h - base)
        theme.alpha_rect(surface, floor, (10, 7, 26), 200)
        vanish_x = self.w / 2
        for i in range(-14, 15):
            x_end = vanish_x + i * (self.w / 9)
            pygame.draw.line(surface, (44, 26, 92),
                             (vanish_x + i * 10, self.horizon),
                             (int(x_end), self.h), 1)
        scroll = (t * 46) % 54
        y = base + 6
        step = 8.0
        while y < self.h:
            col = theme.lerp((40, 24, 88), theme.CYAN, 0.25)
            pygame.draw.line(surface, col, (0, int(y)), (self.w, int(y)), 1)
            step *= 1.28
            y += step + scroll * 0.02

        if particles:
            for m in self.motes:
                m["x"] = (m["x"] + m["vx"] * dt) % self.w
                m["y"] = (m["y"] + m["vy"] * dt) % self.h
                pulse = 0.55 + 0.45 * math.sin(t * 2.0 + m["phase"])
                r = m["r"]
                pygame.draw.circle(surface, m["color"],
                                   (int(m["x"]), int(m["y"])), r + 2)
                pygame.draw.circle(surface, theme.lerp(m["color"], theme.WHITE,
                                                       0.5 * pulse),
                                   (int(m["x"]), int(m["y"])), r)

        # vignette - keeps text readable over the city
        theme.alpha_rect(surface, pygame.Rect(0, 0, self.w, 90), theme.BG, 150)
        theme.alpha_rect(surface, pygame.Rect(0, self.h - 70, self.w, 70),
                         theme.BG, 130)
        theme.alpha_rect(surface, pygame.Rect(0, 0, 120, self.h), theme.BG, 110)
        theme.alpha_rect(surface, pygame.Rect(self.w - 120, 0, 120, self.h),
                         theme.BG, 110)
