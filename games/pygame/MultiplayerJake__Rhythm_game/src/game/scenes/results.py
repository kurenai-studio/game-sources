"""End-of-round results: rank, score, accuracy, combo, hit statistics."""

from __future__ import annotations

import pygame

from ..core.scene import Scene
from ..ui import theme
from ..ui.widgets import Button

RANKS = ((99.0, "S+", theme.CYAN), (95.0, "S", theme.CYAN),
         (90.0, "A", theme.GREEN), (80.0, "B", theme.YELLOW),
         (70.0, "C", theme.LAVENDER), (0.0, "D", theme.PINK))


class ResultsScene(Scene):
    def __init__(self, game, level, summary: dict):
        super().__init__(game)
        self.level = level
        self.summary = summary
        self.is_new_high = game.save.record_score(level.name, summary["score"])
        self.accuracy = self._accuracy(summary)
        self.rank, self.rank_color = self._rank(self.accuracy)

        cy = theme.BASE_H // 2 + 130
        w, h = 240, 58
        self.again = Button((theme.BASE_W // 2 - w - 14, cy, w, h), "AGAIN",
                            self._again, size=24, kind="primary", skew=14)
        self.menu = Button((theme.BASE_W // 2 + 14, cy, w, h), "MAIN MENU",
                           self._menu, size=24, skew=14)
        self.buttons = [self.again, self.menu]
        self.selected = 0

    @staticmethod
    def _accuracy(s: dict) -> float:
        total = s["perfect"] + s["great"] + s["good"] + s["miss"]
        if not total:
            return 100.0
        got = s["perfect"] + s["great"] * 0.75 + s["good"] * 0.5
        return 100.0 * got / total

    @staticmethod
    def _rank(acc: float):
        for limit, name, color in RANKS:
            if acc >= limit:
                return name, color
        return "D", theme.PINK

    def _again(self) -> None:
        from .play import PlayScene
        self.game.scenes.change(PlayScene(self.game, self.level))

    def _menu(self) -> None:
        from .main_menu import MainMenuScene
        self.game.scenes.change(MainMenuScene(self.game))

    def handle_event(self, event) -> None:
        for b in self.buttons:
            if b.handle_event(event):
                return
        if event.type == pygame.KEYDOWN:
            cfg = self.game.config
            if event.key == cfg.key("menu_left"):
                self.selected = 0
            elif event.key == cfg.key("menu_right"):
                self.selected = 1
            elif (event.key == cfg.key("confirm")
                  or event.key == pygame.K_KP_ENTER):
                self.buttons[self.selected].on_click()
            elif event.key == cfg.key("cancel"):
                self._menu()

    def update(self, dt: float) -> None:
        pass

    # ---------------------------------------------------------------- draw
    def draw(self, surface) -> None:
        import math
        s = self.summary
        pulse = 0.5 + 0.5 * math.sin(pygame.time.get_ticks() / 380.0)

        theme.title_text(surface, "TRACK COMPLETE", theme.BASE_W // 2, 56,
                         size=44, glow=theme.MAGENTA)
        theme.draw_text(surface, self.level.name, theme.BASE_W // 2, 118,
                        size=18, color=theme.LAVENDER, align="center")

        # ---- rank badge (left) + accuracy (right) -----------------------
        cx = theme.BASE_W // 2
        rank_box = pygame.Rect(cx - 400, 170, 150, 150)
        theme.panel(surface, rank_box, fill=theme.PANEL,
                    border=self.rank_color, radius=14,
                    glow=self.rank_color)
        theme.draw_text(surface, self.rank, rank_box.centerx,
                        rank_box.y + 24, size=76, color=self.rank_color,
                        align="center", glow=self.rank_color)
        theme.draw_text(surface, "RANK", rank_box.centerx, rank_box.bottom - 34,
                        size=14, color=theme.DIM, align="center")

        acc_box = pygame.Rect(cx + 250, 170, 150, 150)
        theme.panel(surface, acc_box, fill=theme.PANEL, border=theme.CYAN,
                    radius=14, glow=theme.VIOLET)
        theme.draw_text(surface, f"{self.accuracy:.1f}%", acc_box.centerx,
                        acc_box.y + 44, size=34, color=theme.WHITE,
                        align="center", glow=theme.CYAN)
        theme.draw_text(surface, "ACCURACY", acc_box.centerx,
                        acc_box.bottom - 34, size=14, color=theme.DIM,
                        align="center")

        # ---- score -------------------------------------------------------
        theme.draw_text(surface, f"{s['score']:,}", cx, 176, size=76,
                        color=theme.WHITE, align="center", glow=theme.VIOLET)
        if self.is_new_high:
            theme.draw_text(surface, "★ NEW HIGH SCORE ★", cx, 278, size=22,
                            color=theme.YELLOW, align="center",
                            glow=theme.ORANGE if pulse > 0.4 else theme.YELLOW)
        else:
            theme.draw_text(surface,
                            f"HIGH SCORE "
                            f"{self.game.save.high_score(self.level.name):,}",
                            cx, 280, size=21, color=theme.LAVENDER,
                            align="center")

        theme.draw_text(surface, f"MAX COMBO  {s['max_combo']}", cx, 330,
                        size=26, color=theme.CYAN, align="center",
                        glow=theme.MAGENTA)

        # ---- hit statistics ---------------------------------------------
        items = [("PERFECT", s["perfect"], theme.CYAN),
                 ("GREAT", s["great"], theme.YELLOW),
                 ("GOOD", s["good"], theme.GREEN),
                 ("MISS", s["miss"], theme.PINK)]
        total_w = 4 * 170
        x0 = cx - total_w // 2
        for i, (label, count, color) in enumerate(items):
            x = x0 + i * 170 + 85
            box = pygame.Rect(x - 74, 388, 148, 74)
            theme.panel(surface, box, fill=theme.PANEL, border=theme.BORDER,
                        radius=10, glow=color if count else None)
            theme.draw_text(surface, count, x, 398, size=30, color=color,
                            align="center")
            theme.draw_text(surface, label, x, 438, size=14, color=theme.DIM,
                            align="center")

        for i, b in enumerate(self.buttons):
            b.draw(surface, selected=(i == self.selected))

        cfg = self.game.config
        theme.draw_text(surface,
                        f"{cfg.label('confirm')} = confirm  ·  "
                        f"{cfg.label('cancel')} = main menu",
                        theme.BASE_W // 2, theme.BASE_H - 46, size=15,
                        color=theme.DIM, align="center")
