"""
Shinrin CS — Oyun Bitti Sahnesi (GameOverScene).

Oyuncu yenildiğinde gösterilen sahne.
Yeniden deneme veya ana menüye dönme seçenekleri sunar.
"""

from __future__ import annotations

import math
import pygame
from scenes.base_scene import BaseScene
from utils.constants import (
    SCREEN_WIDTH, SCREEN_HEIGHT,
    COLOR_TORII_RED, COLOR_GOLD, COLOR_UI_TEXT, COLOR_WHITE,
    FONT_SIZE_MEDIUM, FONT_SIZE_LARGE, FONT_SIZE_TITLE, FONT_SIZE_SMALL
)
from utils.logger import get_logger

_logger = get_logger("GameOverScene")


class GameOverScene(BaseScene):
    """
    Oyun bitti ekranı.

    Dramatik karartma efekti ve yeniden deneme seçenekleri.
    """

    MENU_OPTIONS = ["Yeniden Dene", "Ana Menü"]

    def __init__(self, game_engine):
        super().__init__(game_engine)
        self._selected_index: int = 0
        self._title_font = None
        self._font = None
        self._small_font = None
        self._time: float = 0.0
        self._fade_alpha: int = 0

    def enter(self) -> None:
        _logger.info("Game Over ekranı.")
        self._selected_index = 0
        self._time = 0.0
        self._fade_alpha = 0
        am = self._game_engine.asset_manager
        self._title_font = am.load_font(None, FONT_SIZE_TITLE)
        self._font = am.load_font(None, FONT_SIZE_MEDIUM)
        self._small_font = am.load_font(None, FONT_SIZE_SMALL)

    def exit(self) -> None:
        _logger.info("Game Over ekranından çıkıldı.")

    def handle_input(self, input_handler) -> None:
        if self._fade_alpha < 200:
            return  # Fade tamamlanmadan girdi alma

        if input_handler.is_just_pressed(pygame.K_UP) or \
           input_handler.is_just_pressed(pygame.K_w):
            self._selected_index = (
                (self._selected_index - 1) % len(self.MENU_OPTIONS)
            )

        if input_handler.is_just_pressed(pygame.K_DOWN) or \
           input_handler.is_just_pressed(pygame.K_s):
            self._selected_index = (
                (self._selected_index + 1) % len(self.MENU_OPTIONS)
            )

        if input_handler.is_confirm():
            self._handle_selection()

    def _handle_selection(self) -> None:
        selected = self.MENU_OPTIONS[self._selected_index]
        _logger.info("Game Over seçimi: '%s'", selected)

        if selected == "Yeniden Dene":
            self._game_engine.scene_manager.switch_scene("world")

        elif selected == "Ana Menü":
            self._game_engine.scene_manager.switch_scene("title")

    def update(self, dt: float) -> None:
        self._time += dt
        # Yavaş karartma
        if self._fade_alpha < 220:
            self._fade_alpha = min(220, self._fade_alpha + int(100 * dt))

    def draw(self, surface: pygame.Surface) -> None:
        # Koyu kırmızımsı arka plan
        surface.fill((15, 5, 5))

        # Karartma overlay
        overlay = pygame.Surface(surface.get_size(), pygame.SRCALPHA)
        overlay.fill((10, 0, 0, self._fade_alpha))
        surface.blit(overlay, (0, 0))

        if not self._font:
            return

        # Dekoratif parçacıklar (düşen kıvılcımlar)
        for i in range(15):
            px = (i * 57 + int(self._time * 20)) % SCREEN_WIDTH
            py = (i * 43 + int(self._time * 30 * (1 + i * 0.1))) % SCREEN_HEIGHT
            alpha = int(80 + 50 * math.sin(self._time * 2 + i))
            pygame.draw.circle(surface, (200, 50, 30, max(0, alpha)),
                               (px, py), 2)

        # "GAME OVER" başlık (titreme efekti)
        shake = 0
        if self._time < 2:
            shake = int(5 * math.sin(self._time * 20) * (2 - self._time))

        title_text = "GAME OVER"
        shadow = self._title_font.render(title_text, True, (80, 0, 0))
        s_rect = shadow.get_rect(
            center=(SCREEN_WIDTH // 2 + 3 + shake,
                    SCREEN_HEIGHT // 3 + 3)
        )
        surface.blit(shadow, s_rect)

        main_text = self._title_font.render(title_text, True, COLOR_TORII_RED)
        m_rect = main_text.get_rect(
            center=(SCREEN_WIDTH // 2 + shake, SCREEN_HEIGHT // 3)
        )
        surface.blit(main_text, m_rect)

        # Alt mesaj
        sub = self._font.render(
            "— Ormanın karanlığı seni yuttu... —",
            True, (150, 80, 80)
        )
        sub_rect = sub.get_rect(
            center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 3 + 55)
        )
        surface.blit(sub, sub_rect)

        # Menü (fade tamamlandıysa)
        if self._fade_alpha >= 200:
            menu_y = SCREEN_HEIGHT // 2 + 40

            for i, option in enumerate(self.MENU_OPTIONS):
                is_sel = (i == self._selected_index)
                color = COLOR_GOLD if is_sel else COLOR_UI_TEXT
                prefix = "▶ " if is_sel else "  "

                text = self._font.render(prefix + option, True, color)
                rect = text.get_rect(
                    center=(SCREEN_WIDTH // 2, menu_y + i * 40)
                )
                surface.blit(text, rect)

            # İpucu
            hint = self._small_font.render(
                "↑↓: Seç  |  Enter: Onayla", True, (100, 80, 80)
            )
            h_rect = hint.get_rect(
                center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT - 40)
            )
            surface.blit(hint, h_rect)
