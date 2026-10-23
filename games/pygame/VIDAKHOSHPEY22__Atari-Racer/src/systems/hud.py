import pygame as pg
import math
from core.settings import *
from utils.drawing import draw_heart
from utils.helpers import clamp, clamp_color

class HUD:
    def __init__(self, fonts):
        self.small = fonts[1]
        self.tiny = fonts[2]
        self.surf = pg.Surface((340, 155), pg.SRCALPHA)
        self._text_cache = {}

    def _render(self, font, text, color):
        key = (id(font), text, color)
        if key not in self._text_cache:
            self._text_cache[key] = font.render(text, True, color)
        return self._text_cache[key]

    def draw(self, surface, score, level, speed_pct, difficulty, multiplier,
             lives, max_lives, boost_timer):
        self.surf.fill((0, 0, 0, 180))
        pg.draw.rect(self.surf, (255, 255, 255, 40), (0, 0, 340, 155), 3, border_radius=10)

        pulse = int(8 * abs(math.sin(pg.time.get_ticks() / 300)))
        score_col = (255, 220, 50 + pulse)
        self._blit(f"SCORE: {score}", score_col, 12, 10)

        self._blit(f"LEVEL: {level}", CYAN, 12, 40)

        self._blit(f"SPEED: {speed_pct}%", GREEN, 12, 65)

        bar_width, bar_height = 100, 8
        fill = int(bar_width * min(1.0, speed_pct / 250))
        pg.draw.rect(self.surf, (50, 50, 50), (12, 88, bar_width, bar_height), border_radius=4)
        pg.draw.rect(self.surf, GREEN, (12, 88, fill, bar_height), border_radius=4)

        self._blit(f"MODE: {difficulty}", YELLOW, 12, 100, tiny=True)

        if boost_timer > 0:
            boost_width = int(100 * (boost_timer / 1.5))
            pg.draw.rect(self.surf, ORANGE, (12, 115, boost_width, 6), border_radius=3)
            self._blit("BOOST!", (255, 105, 0), 12, 120, tiny=True)

        y_icons = 138
        for i in range(max_lives):
            draw_heart(self.surf, 22 + i * 20, y_icons, 14, RED if i < lives else GRAY)

        if multiplier > 1.0:
            col = YELLOW if multiplier >= 2.0 else (150, 220, 150)
            glow = int(50 * abs(math.sin(pg.time.get_ticks() / 100)))
            self._blit(f"x{multiplier:.1f} COMBO!",
                      clamp_color(col[0] + glow, col[1] + glow, col[2]),
                      130, 126, tiny=True)

        surface.blit(self.surf, (10, 10))

    def draw_achievement_toast(self, surface, ach, timer, max_timer):
        alpha = 255
        if timer < 0.5:
            alpha = int(255 * (timer / 0.5))
        elif timer > max_timer - 0.4:
            alpha = int(255 * ((max_timer - timer) / 0.4))
        alpha = clamp(alpha, 0, 255)

        box_w, box_h = 340, 64
        bx = WIDTH // 2 - box_w // 2
        by = 20

        box = pg.Surface((box_w, box_h), pg.SRCALPHA)
        box.fill((25, 20, 5, 220))
        pg.draw.rect(box, (255, 215, 0, 200), (0, 0, box_w, box_h), 3, border_radius=10)

        title = self.small.render("ACHIEVEMENT UNLOCKED", True, YELLOW)
        box.blit(title, (box_w // 2 - title.get_width() // 2, 8))

        name = self.small.render(ach["name"], True, WHITE)
        box.blit(name, (box_w // 2 - name.get_width() // 2, 34))

        box.set_alpha(alpha)
        surface.blit(box, (bx, by))

    def _blit(self, text, color, x, y, tiny=False):
        if isinstance(color, tuple):
            color = tuple(int(clamp(c, 0, 255)) for c in color)
        font = self.tiny if tiny else self.small
        self.surf.blit(self._render(font, text, color), (x, y))
