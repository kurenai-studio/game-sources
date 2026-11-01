"""
Shinrin CS — Duraklatma Sahnesi (PauseScene).

Oyun duraklatıldığında gösterilen overlay sahne.
Devam et, envanter, kaydet, ana menü seçenekleri sunar.
"""

from __future__ import annotations

import pygame
from scenes.base_scene import BaseScene
from utils.constants import (
    SCREEN_WIDTH, SCREEN_HEIGHT,
    COLOR_UI_BG, COLOR_UI_BORDER, COLOR_UI_TEXT,
    COLOR_GOLD, COLOR_SAKURA_PINK, COLOR_WHITE,
    FONT_SIZE_MEDIUM, FONT_SIZE_LARGE, FONT_SIZE_SMALL
)
from utils.logger import get_logger

_logger = get_logger("PauseScene")


class PauseScene(BaseScene):
    """
    Duraklatma menüsü overlay sahnesi.

    Arka planda dünya sahnesi donmuş şekilde görünür.
    Üzerine yarı saydam panel çizilir.
    """

    MENU_OPTIONS = ["Devam Et", "Envanter", "Kaydet", "Ana Menü"]

    def __init__(self, game_engine):
        super().__init__(game_engine)
        self._selected_index: int = 0
        self._font = None
        self._title_font = None
        self._small_font = None
        self._background_snapshot: pygame.Surface | None = None

    def enter(self) -> None:
        _logger.info("Duraklatma menüsü açıldı.")
        self._selected_index = 0
        am = self._game_engine.asset_manager
        self._font = am.load_font(None, FONT_SIZE_MEDIUM)
        self._title_font = am.load_font(None, FONT_SIZE_LARGE)
        self._small_font = am.load_font(None, FONT_SIZE_SMALL)
        # Mevcut ekranı anlık olarak yakala
        self._background_snapshot = self._game_engine.screen.copy()

    def exit(self) -> None:
        _logger.info("Duraklatma menüsü kapatıldı.")

    def handle_input(self, input_handler) -> None:
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

        # Devam (Escape veya P)
        if input_handler.is_pause() or input_handler.is_cancel():
            self._game_engine.scene_manager.pop_scene()
            return

        if input_handler.is_confirm():
            self._handle_selection()

    def _handle_selection(self) -> None:
        selected = self.MENU_OPTIONS[self._selected_index]
        _logger.info("Pause menü seçimi: '%s'", selected)

        if selected == "Devam Et":
            self._game_engine.scene_manager.pop_scene()

        elif selected == "Envanter":
            self._game_engine.scene_manager.push_scene("inventory")

        elif selected == "Kaydet":
            world_scene = self._game_engine.scene_manager.get_scene("world")
            if world_scene and hasattr(world_scene, 'save_game'):
                success = world_scene.save_game(slot=1)
                if success:
                    _logger.info("Oyun başarıyla kaydedildi!")
                else:
                    _logger.warning("Kayıt başarısız!")

        elif selected == "Ana Menü":
            # Önce kaydet
            world_scene = self._game_engine.scene_manager.get_scene("world")
            if world_scene and hasattr(world_scene, 'save_game'):
                world_scene.save_game(slot=1)
            # Overlay'ı kapat ve title'a dön
            self._game_engine.scene_manager.pop_scene()
            self._game_engine.scene_manager.switch_scene("title")

    def update(self, dt: float) -> None:
        pass  # Statik menü

    def draw(self, surface: pygame.Surface) -> None:
        # Donmuş arka plan
        if self._background_snapshot:
            surface.blit(self._background_snapshot, (0, 0))

        # Karartma overlay
        overlay = pygame.Surface(surface.get_size(), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 160))
        surface.blit(overlay, (0, 0))

        if not self._font:
            return

        # Panel
        panel_w = 280
        panel_h = 300
        panel_x = (SCREEN_WIDTH - panel_w) // 2
        panel_y = (SCREEN_HEIGHT - panel_h) // 2

        panel = pygame.Surface((panel_w, panel_h), pygame.SRCALPHA)
        panel.fill((20, 20, 40, 230))
        surface.blit(panel, (panel_x, panel_y))
        pygame.draw.rect(surface, COLOR_SAKURA_PINK,
                         (panel_x, panel_y, panel_w, panel_h), 2)

        # Başlık
        title = self._title_font.render("DURAKLAT", True, COLOR_GOLD)
        title_rect = title.get_rect(center=(SCREEN_WIDTH // 2, panel_y + 35))
        surface.blit(title, title_rect)

        # Dekoratif çizgi
        line_y = panel_y + 60
        pygame.draw.line(surface, COLOR_SAKURA_PINK,
                         (panel_x + 30, line_y), (panel_x + panel_w - 30, line_y))

        # Menü seçenekleri
        menu_start_y = panel_y + 85
        spacing = 45

        for i, option in enumerate(self.MENU_OPTIONS):
            is_sel = (i == self._selected_index)
            color = COLOR_GOLD if is_sel else COLOR_UI_TEXT
            prefix = "▶ " if is_sel else "  "

            if is_sel:
                # Vurgu arka planı
                hl = pygame.Surface((panel_w - 40, 32), pygame.SRCALPHA)
                hl.fill((255, 215, 0, 25))
                surface.blit(hl, (panel_x + 20, menu_start_y + i * spacing - 5))

            text = self._font.render(prefix + option, True, color)
            rect = text.get_rect(center=(SCREEN_WIDTH // 2,
                                         menu_start_y + i * spacing + 10))
            surface.blit(text, rect)

        # Alt bilgi
        hint = self._small_font.render(
            "P: Devam  |  ↑↓: Seç  |  Z: Onayla", True, (120, 120, 150)
        )
        hint_rect = hint.get_rect(center=(SCREEN_WIDTH // 2,
                                           panel_y + panel_h - 20))
        surface.blit(hint, hint_rect)
