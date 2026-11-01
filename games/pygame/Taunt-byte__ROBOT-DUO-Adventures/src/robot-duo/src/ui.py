"""Fonts, text helpers, panels and the in-game HUD."""
import glob
import math
import os
import pygame
from . import settings as S
from .level_manager import format_time


class Fonts:
    """Caches fonts by size. Uses the first .ttf in assets/fonts if present, otherwise a system font."""

    def __init__(self):
        self.cache = {}
        files = sorted(glob.glob(os.path.join(S.ASSETS_DIR, "fonts", "*.ttf")))
        self.file = files[0] if files else None

    def get(self, size, bold=True):
        key = (size, bold)
        if key not in self.cache:
            f = None
            if self.file:
                try:
                    f = pygame.font.Font(self.file, size)
                except (pygame.error, OSError):
                    f = None
            if f is None:
                f = pygame.font.SysFont("trebuchetms,verdana,dejavusans,arial", size, bold=bold)
            self.cache[key] = f
        return self.cache[key]


def draw_text(surf, fonts, text, size, color, pos, anchor="center", outline=(8, 12, 28), bold=True, shadow=True):
    font = fonts.get(size, bold)
    img = font.render(text, True, color)
    rect = img.get_rect()
    setattr(rect, anchor, pos)
    if outline:
        edge = font.render(text, True, outline)
        for dx, dy in ((-2, 0), (2, 0), (0, -2), (0, 2), (-2, -2), (2, 2), (-2, 2), (2, -2)):
            surf.blit(edge, rect.move(dx, dy))
    elif shadow:
        surf.blit(font.render(text, True, (0, 0, 0)), rect.move(2, 2))
    surf.blit(img, rect)
    return rect


def draw_panel(surf, rect, color=S.C_UI_PANEL, alpha=200, border=S.C_UI_ACCENT, radius=14, width=3):
    rect = pygame.Rect(rect)
    tmp = pygame.Surface(rect.size, pygame.SRCALPHA)
    pygame.draw.rect(tmp, (color[0], color[1], color[2], alpha), tmp.get_rect(), border_radius=radius)
    surf.blit(tmp, rect.topleft)
    if border and width:
        pygame.draw.rect(surf, border, rect, width, border_radius=radius)


def glow_surface(radius, color, intensity=1.0):
    """Black-background radial gradient, meant for BLEND_RGB_ADD blits."""
    surf = pygame.Surface((radius * 2, radius * 2))
    for r in range(radius, 0, -2):
        k = (1.0 - r / float(radius)) ** 2 * intensity
        c = tuple(min(255, int(ch * k)) for ch in color)
        pygame.draw.circle(surf, c, (radius, radius), r)
    return surf


_glow_cache = {}


def add_glow(screen, x, y, radius, color, intensity=1.0):
    key = (radius, color, round(intensity, 2))
    if key not in _glow_cache:
        _glow_cache[key] = glow_surface(radius, color, intensity)
    screen.blit(_glow_cache[key], (int(x - radius), int(y - radius)), special_flags=pygame.BLEND_RGB_ADD)


def make_vignette(w, h):
    small = pygame.Surface((100, 65), pygame.SRCALPHA)
    for y in range(65):
        for x in range(100):
            dx, dy = (x - 49.5) / 50.0, (y - 32) / 32.5
            d = math.sqrt(dx * dx * 0.7 + dy * dy)
            a = max(0.0, d - 0.65) * 190
            small.set_at((x, y), (0, 0, 10, int(min(170, a))))
    return pygame.transform.smoothscale(small, (w, h))


RANK_COLORS = {"S": (255, 214, 58), "A": (90, 255, 150), "B": (80, 190, 255), "C": (180, 190, 205)}


class Hud:
    def __init__(self, fonts, anims):
        self.fonts = fonts
        self.icons = {}
        for k in ("x", "b"):          # tiny head portrait from the idle frame
            frame = anims[k].get("idle", 0.0, 1)
            self.icons[k] = pygame.transform.smoothscale(frame.subsurface((8, 4, 48, 40)).copy(), (42, 35))

    def draw(self, screen, level, players, selected, id_colors, intro_alpha=0.0):
        f = self.fonts
        draw_panel(screen, (0, 0, S.SCREEN_W, 54), (8, 14, 30), 215, None, 0, 0)
        pygame.draw.line(screen, S.C_UI_ACCENT, (0, 54), (S.SCREEN_W, 54), 2)
        draw_text(screen, f, "%d. %s" % (level.index + 1, level.name.upper()), 20, S.C_WHITE, (14, 27), "midleft")

        # crystals
        cx = 310
        pts = [(cx, 15), (cx + 9, 27), (cx, 39), (cx - 9, 27)]
        pygame.draw.polygon(screen, S.C_YELLOW, pts)
        pygame.draw.polygon(screen, (160, 110, 0), pts, 2)
        ok = level.crystals_collected >= level.required_crystals
        txt = "%d/%d" % (level.crystals_collected, level.total_crystals)
        draw_text(screen, f, txt, 22, S.C_WHITE, (cx + 18, 27), "midleft")
        if level.required_crystals:
            draw_text(screen, f, "(min %d)" % level.required_crystals, 14, S.C_GREEN if ok else (255, 170, 120),
                      (cx + 18 + 62, 29), "midleft", bold=False)

        draw_text(screen, f, format_time(level.time), 24, S.C_WHITE, (505, 27), "center")

        # robot panels
        for i, p in enumerate(players):
            x = 570 + i * 215
            sel = i == selected
            col = S.C_RED if p.kind == "x" else S.C_CYAN
            draw_panel(screen, (x, 6, 205, 42), (30, 40, 70) if not sel else (50, 66, 110), 230,
                       col if sel else (70, 84, 120), 10, 3 if sel else 2)
            screen.blit(self.icons[p.kind], (x + 6, 10))
            draw_text(screen, f, p.name, 15, col if p.alive else (140, 140, 150), (x + 52, 18), "midleft", bold=True)
            status = "MORTO" if not p.alive else "NA PORTA" if p.at_door else "TAB" if sel else "livre"
            draw_text(screen, f, status, 13, S.C_GREEN if p.at_door else (200, 210, 230), (x + 52, 36), "midleft",
                      bold=False, outline=None)

        # mechanisms: one coloured lamp per button
        if level.buttons:
            x = 14
            for bid, b in level.buttons.items():
                col = id_colors[bid]
                pygame.draw.circle(screen, (20, 24, 40), (x + 9, 72), 11)
                pygame.draw.circle(screen, col if b.active else tuple(c // 4 for c in col), (x + 9, 72), 8)
                if b.active:
                    pygame.draw.circle(screen, (255, 255, 255), (x + 9, 72), 8, 2)
                x += 28

        # intro banner
        if intro_alpha > 0:
            banner = pygame.Surface((S.SCREEN_W, 120), pygame.SRCALPHA)
            pygame.draw.rect(banner, (6, 10, 24, int(190 * intro_alpha)), banner.get_rect())
            screen.blit(banner, (0, 250))
            for txt, size, y, col in ((level.name.upper(), 48, 295, S.C_WHITE), (level.subtitle, 22, 340, S.C_CYAN_LIGHT)):
                img = self.fonts.get(size).render(txt, True, col)
                img.set_alpha(int(255 * intro_alpha))
                screen.blit(img, img.get_rect(center=(S.SCREEN_W // 2, y)))
