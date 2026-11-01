"""Main menu: Play, Create, Settings, Exit."""

from __future__ import annotations

import pygame

from ..core.scene import Scene
from ..ui import theme
from ..ui.widgets import Button


class MainMenuScene(Scene):
    def __init__(self, game):
        super().__init__(game)
        cx, w, h, skew = theme.BASE_W // 2, 300, 58, 16
        specs = [
            ("PLAY", "primary", lambda: self._go("play")),
            ("CREATE", "normal", lambda: self._go("create")),
            ("SETTINGS", "normal", lambda: self._go("settings")),
            ("EXIT", "normal", lambda: self.game.quit()),
        ]
        self.buttons = []
        y = 236
        for label, kind, cb in specs:
            self.buttons.append(
                Button((cx - w // 2, y, w, h), label, cb, size=26,
                       kind=kind, skew=skew))
            y += h + 22
        self.selected = 0

    def _go(self, target: str) -> None:
        if target == "play":
            from .play_list import PlayListScene
            self.game.scenes.change(PlayListScene(self.game))
        elif target == "create":
            from .editor import EditorScene
            self.game.scenes.change(EditorScene(self.game))
        elif target == "settings":
            from .settings import SettingsScene
            self.game.scenes.change(SettingsScene(self.game))

    def handle_event(self, event) -> None:
        for b in self.buttons:
            if b.handle_event(event):
                return
        if event.type == pygame.KEYDOWN:
            cfg = self.game.config
            if event.key == cfg.key("menu_up"):
                self.selected = (self.selected - 1) % len(self.buttons)
            elif event.key == cfg.key("menu_down"):
                self.selected = (self.selected + 1) % len(self.buttons)
            elif event.key == cfg.key("confirm") or event.key == pygame.K_KP_ENTER:
                self.buttons[self.selected].on_click()
            elif event.key == cfg.key("cancel"):
                self.game.quit()

    def update(self, dt: float) -> None:
        pass

    def draw(self, surface) -> None:
        import math
        t = pygame.time.get_ticks() / 1000.0

        # ---------------------------------------------------------- logo
        band = pygame.Rect(theme.BASE_W // 2 - 264, 66, 528, 100)
        pulse = 0.5 + 0.5 * math.sin(t * 2.0)
        theme.alpha_rect(surface, band.inflate(34, 24), theme.MAGENTA,
                         int(45 + 40 * pulse), radius=26)
        poly = [(band.x + 18, band.y), (band.right, band.y),
                (band.right - 18, band.bottom), (band.x, band.bottom)]
        pygame.draw.polygon(surface, (17, 11, 42), poly)
        pygame.draw.polygon(surface, theme.CYAN, poly, 2)
        pygame.draw.polygon(surface, theme.MAGENTA,
                            [poly[0], poly[1],
                             (poly[1][0] - 4, poly[1][1] + 5),
                             (poly[0][0] + 4, poly[0][1] + 5)], 2)

        title = theme.font(44)
        img = title.render("RHYTHM FEST", True, theme.WHITE)
        rect = img.get_rect(center=(band.centerx, band.centery))
        # restrained chromatic glitch on a random beat
        if int(t * 3) % 11 == 0:
            for dx, col in ((4, theme.CYAN), (-4, theme.MAGENTA)):
                g = title.render("RHYTHM FEST", True, col)
                g.set_alpha(140)
                surface.blit(g, rect.move(dx, 0))
        for dx, dy in ((-3, 0), (3, 0), (0, -3), (0, 3), (-2, -2), (2, 2)):
            surface.blit(title.render("RHYTHM FEST", True, theme.VIOLET),
                         rect.move(dx, dy))
        surface.blit(img, rect)

        theme.draw_text(surface, "4-LANE NEON RHYTHM ARENA",
                        theme.BASE_W // 2, 184, size=15,
                        color=theme.LAVENDER, align="center",
                        glow=theme.VIOLET)

        # -------------------------------------------------------- buttons
        for i, b in enumerate(self.buttons):
            b.draw(surface, selected=(i == self.selected))
            if i == self.selected:
                # selection indicator: chevron + edge bar (no backdrop)
                chev = b.rect.x - 34
                cy = b.rect.centery
                theme.draw_text(surface, ">", chev + 3, cy - 16, size=26,
                                color=theme.WHITE, align="center",
                                glow=theme.CYAN)
                theme.alpha_rect(surface,
                                 pygame.Rect(b.rect.right + 8, b.rect.y + 6, 5,
                                             b.rect.h - 12),
                                 theme.CYAN, 210, radius=3)

        cfg = self.game.config
        theme.draw_text(surface,
                        f"{cfg.label('menu_up')}/{cfg.label('menu_down')} or "
                        f"click  ·  {cfg.label('cancel')} quits",
                        theme.BASE_W // 2, theme.BASE_H - 44, size=15,
                        color=theme.DIM, align="center")
