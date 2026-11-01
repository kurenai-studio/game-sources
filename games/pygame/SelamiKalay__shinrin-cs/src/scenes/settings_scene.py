"""
Shinrin CS — Ayarlar Sahnesi (SettingsScene).

Ses, ekran ve kontrol ayarlarının yapıldığı overlay sahne.
Değişiklikler anında uygulanır ve settings.json'a kaydedilir.
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

_logger = get_logger("SettingsScene")


class SettingsScene(BaseScene):
    """
    Ayarlar menüsü sahnesi.

    Ayarlanabilir öğeler:
    - Müzik Sesi (0-100)
    - Efekt Sesi (0-100)
    - Tam Ekran (Açık/Kapalı)
    - FPS Göster (Açık/Kapalı)
    - Zorluk (Kolay/Normal/Zor)
    """

    def __init__(self, game_engine):
        super().__init__(game_engine)
        self._selected_index: int = 0
        self._font = None
        self._title_font = None
        self._small_font = None
        self._background_snapshot: pygame.Surface | None = None
        self._settings_items: list = []
        self._message: str = ""
        self._message_timer: float = 0.0

    def enter(self) -> None:
        _logger.info("Ayarlar menüsü açıldı.")
        self._selected_index = 0
        am = self._game_engine.asset_manager
        self._font = am.load_font(None, FONT_SIZE_MEDIUM)
        self._title_font = am.load_font(None, FONT_SIZE_LARGE)
        self._small_font = am.load_font(None, FONT_SIZE_SMALL)
        self._background_snapshot = self._game_engine.screen.copy()
        self._build_settings_items()

    def _build_settings_items(self) -> None:
        """Ayar öğelerini oluşturur."""
        s = self._game_engine.settings
        self._settings_items = [
            {
                'label': 'Müzik Sesi',
                'type': 'slider',
                'key': 'music_volume',
                'value': s.music_volume,
                'min': 0, 'max': 100, 'step': 10,
            },
            {
                'label': 'Efekt Sesi',
                'type': 'slider',
                'key': 'sfx_volume',
                'value': s.sfx_volume,
                'min': 0, 'max': 100, 'step': 10,
            },
            {
                'label': 'Tam Ekran',
                'type': 'toggle',
                'key': 'fullscreen',
                'value': s.fullscreen,
            },
            {
                'label': 'FPS Göster',
                'type': 'toggle',
                'key': 'show_fps',
                'value': s.show_fps,
            },
            {
                'label': 'Zorluk',
                'type': 'choice',
                'key': 'difficulty',
                'value': s.difficulty,
                'choices': ['Kolay', 'Normal', 'Zor'],
            },
            {
                'label': 'Kaydet ve Kapat',
                'type': 'action',
                'key': 'save_close',
            },
        ]

    def exit(self) -> None:
        _logger.info("Ayarlar menüsü kapatıldı.")

    def handle_input(self, input_handler) -> None:
        # Kapat
        if input_handler.is_cancel():
            self._game_engine.scene_manager.pop_scene()
            return

        # Navigasyon
        if input_handler.is_just_pressed(pygame.K_UP) or \
           input_handler.is_just_pressed(pygame.K_w):
            self._selected_index = (
                (self._selected_index - 1) % len(self._settings_items)
            )

        if input_handler.is_just_pressed(pygame.K_DOWN) or \
           input_handler.is_just_pressed(pygame.K_s):
            self._selected_index = (
                (self._selected_index + 1) % len(self._settings_items)
            )

        item = self._settings_items[self._selected_index]

        # Sol/Sağ değer değiştirme
        if input_handler.is_just_pressed(pygame.K_LEFT) or \
           input_handler.is_just_pressed(pygame.K_a):
            self._adjust_value(item, -1)

        if input_handler.is_just_pressed(pygame.K_RIGHT) or \
           input_handler.is_just_pressed(pygame.K_d):
            self._adjust_value(item, 1)

        # Onay
        if input_handler.is_confirm():
            if item['type'] == 'toggle':
                item['value'] = not item['value']
                self._apply_setting(item)
            elif item['type'] == 'action' and item['key'] == 'save_close':
                self._save_and_close()

    def _adjust_value(self, item: dict, direction: int) -> None:
        """Değeri artırır/azaltır."""
        if item['type'] == 'slider':
            item['value'] = max(
                item['min'],
                min(item['max'], item['value'] + item['step'] * direction)
            )
            self._apply_setting(item)

        elif item['type'] == 'toggle':
            item['value'] = not item['value']
            self._apply_setting(item)

        elif item['type'] == 'choice':
            choices = item['choices']
            idx = choices.index(item['value']) if item['value'] in choices else 0
            idx = (idx + direction) % len(choices)
            item['value'] = choices[idx]
            self._apply_setting(item)

    def _apply_setting(self, item: dict) -> None:
        """Ayarı anında uygular."""
        s = self._game_engine.settings
        key = item['key']

        if key == 'music_volume':
            s.music_volume = item['value']
            pygame.mixer.music.set_volume(item['value'] / 100.0)
        elif key == 'sfx_volume':
            s.sfx_volume = item['value']
        elif key == 'fullscreen':
            s.fullscreen = item['value']
        elif key == 'show_fps':
            s.show_fps = item['value']
        elif key == 'difficulty':
            s.difficulty = item['value']

    def _save_and_close(self) -> None:
        """Ayarları kaydedip menüyü kapatır."""
        self._game_engine.settings.save()
        _logger.info("Ayarlar kaydedildi.")
        self._message = "Ayarlar kaydedildi!"
        self._message_timer = 1.5
        self._game_engine.scene_manager.pop_scene()

    def update(self, dt: float) -> None:
        if self._message_timer > 0:
            self._message_timer -= dt

    def draw(self, surface: pygame.Surface) -> None:
        # Arka plan
        if self._background_snapshot:
            surface.blit(self._background_snapshot, (0, 0))

        overlay = pygame.Surface(surface.get_size(), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 170))
        surface.blit(overlay, (0, 0))

        if not self._font:
            return

        # Panel
        panel_w = 450
        panel_h = 380
        panel_x = (SCREEN_WIDTH - panel_w) // 2
        panel_y = (SCREEN_HEIGHT - panel_h) // 2

        panel = pygame.Surface((panel_w, panel_h), pygame.SRCALPHA)
        panel.fill((15, 15, 35, 240))
        surface.blit(panel, (panel_x, panel_y))
        pygame.draw.rect(surface, COLOR_SAKURA_PINK,
                         (panel_x, panel_y, panel_w, panel_h), 2)

        # Başlık
        title = self._title_font.render("AYARLAR", True, COLOR_GOLD)
        title_rect = title.get_rect(center=(SCREEN_WIDTH // 2, panel_y + 30))
        surface.blit(title, title_rect)

        # Dekoratif çizgi
        pygame.draw.line(surface, COLOR_SAKURA_PINK,
                         (panel_x + 30, panel_y + 55),
                         (panel_x + panel_w - 30, panel_y + 55))

        # Ayar öğeleri
        item_y = panel_y + 75
        item_spacing = 45

        for i, item in enumerate(self._settings_items):
            is_sel = (i == self._selected_index)
            label_color = COLOR_GOLD if is_sel else COLOR_UI_TEXT

            # Seçim vurgusu
            if is_sel:
                hl = pygame.Surface((panel_w - 40, 34), pygame.SRCALPHA)
                hl.fill((255, 215, 0, 20))
                surface.blit(hl, (panel_x + 20, item_y - 5))
                # Ok işareti
                arrow = self._font.render("▶", True, COLOR_GOLD)
                surface.blit(arrow, (panel_x + 25, item_y))

            # Etiket
            label = self._font.render(item['label'], True, label_color)
            surface.blit(label, (panel_x + 50, item_y))

            # Değer
            if item['type'] == 'slider':
                # Slider bar
                bar_x = panel_x + panel_w - 180
                bar_w = 120
                bar_y = item_y + 8

                pygame.draw.rect(surface, (50, 50, 70),
                                 (bar_x, bar_y, bar_w, 8))
                ratio = (item['value'] - item['min']) / (item['max'] - item['min'])
                fill_color = COLOR_GOLD if is_sel else COLOR_SAKURA_PINK
                pygame.draw.rect(surface, fill_color,
                                 (bar_x, bar_y, int(bar_w * ratio), 8))

                val = self._small_font.render(
                    f"{item['value']}%", True, COLOR_WHITE
                )
                surface.blit(val, (bar_x + bar_w + 8, bar_y - 3))

            elif item['type'] == 'toggle':
                state_text = "Açık" if item['value'] else "Kapalı"
                state_color = (80, 255, 80) if item['value'] else (255, 80, 80)
                val = self._font.render(
                    f"◀ {state_text} ▶", True, state_color
                )
                surface.blit(val, (panel_x + panel_w - 150, item_y))

            elif item['type'] == 'choice':
                val = self._font.render(
                    f"◀ {item['value']} ▶", True,
                    COLOR_GOLD if is_sel else COLOR_WHITE
                )
                surface.blit(val, (panel_x + panel_w - 150, item_y))

            elif item['type'] == 'action':
                if is_sel:
                    val = self._font.render(
                        "[ Onayla ]", True, COLOR_GOLD
                    )
                    surface.blit(val, (panel_x + panel_w - 150, item_y))

            item_y += item_spacing

        # Alt bilgi
        hint = self._small_font.render(
            "↑↓: Seç  |  ←→: Değiştir  |  Z: Onayla  |  X: Geri",
            True, (120, 120, 150)
        )
        hint_rect = hint.get_rect(
            center=(SCREEN_WIDTH // 2, panel_y + panel_h - 20)
        )
        surface.blit(hint, hint_rect)
