"""
Shinrin CS — Diyalog Sistemi.

NPC konuşmalarını, seçenekli diyalogları ve
metin animasyonunu (typewriter efekti) yönetir.
"""

from __future__ import annotations

import pygame
from utils.constants import (
    SCREEN_WIDTH, SCREEN_HEIGHT, TILE_SIZE,
    COLOR_UI_BG, COLOR_UI_BORDER, COLOR_UI_TEXT,
    COLOR_GOLD, FONT_SIZE_MEDIUM, FONT_SIZE_SMALL
)
from utils.logger import get_logger

_logger = get_logger("DialogueSystem")


class DialogueSystem:
    """
    Diyalog yönetim sistemi.

    Metin kutusunu, karakter yazma animasyonunu ve
    seçenekli dallanmayı yönetir.
    """

    def __init__(self, asset_manager):
        self._asset_manager = asset_manager
        self._active: bool = False
        self._dialogue_data: list = []    # Diyalog satırları listesi
        self._current_index: int = 0
        self._current_text: str = ""
        self._displayed_text: str = ""
        self._speaker_name: str = ""
        self._char_index: int = 0
        self._char_timer: float = 0.0
        self._char_speed: float = 0.03    # Saniye/karakter
        self._is_complete: bool = False
        self._font = None
        self._name_font = None
        self._choices: list = []
        self._choice_index: int = 0

    def start(self, dialogue_lines: list) -> None:
        """
        Yeni bir diyalog başlatır.

        Args:
            dialogue_lines: Diyalog satırları listesi. Her öğe:
                {'speaker': str, 'text': str, 'choices': list (opsiyonel)}
        """
        if not dialogue_lines:
            return

        # Kopya: close() listeyi temizler, cagiranin (NPC) verisi silinmesin
        self._dialogue_data = list(dialogue_lines)
        self._current_index = 0
        self._active = True
        self._load_line(0)

        if not self._font:
            self._font = self._asset_manager.load_font(None, FONT_SIZE_MEDIUM)
            self._name_font = self._asset_manager.load_font(None, FONT_SIZE_SMALL)

        _logger.info("Diyalog başlatıldı (%d satır)", len(dialogue_lines))

    def _load_line(self, index: int) -> None:
        """Belirtilen satırı yükler."""
        if index >= len(self._dialogue_data):
            self.close()
            return

        line = self._dialogue_data[index]
        self._speaker_name = line.get('speaker', '')
        self._current_text = line.get('text', '')
        self._displayed_text = ""
        self._char_index = 0
        self._char_timer = 0.0
        self._is_complete = False
        self._choices = line.get('choices', [])
        self._choice_index = 0

    def advance(self) -> None:
        """
        Diyalogu ilerletir.
        Metin yazılıyorsa tamamlar, tamamsa sonraki satıra geçer.
        """
        if not self._active:
            return

        if not self._is_complete:
            # Metni anında tamamla
            self._displayed_text = self._current_text
            self._is_complete = True
        elif self._choices:
            # Seçim yapılmış
            self._handle_choice()
        else:
            # Sonraki satır
            self._current_index += 1
            self._load_line(self._current_index)

    def navigate_choice(self, direction: int) -> None:
        """Seçenekler arasında gezinir (yukarı/aşağı)."""
        if self._choices:
            self._choice_index = (
                (self._choice_index + direction) % len(self._choices)
            )

    def _handle_choice(self) -> None:
        """Seçili seçeneği işler."""
        if not self._choices:
            return

        chosen = self._choices[self._choice_index]
        _logger.info("Diyalog seçimi: '%s'", chosen.get('text', '?'))

        # Seçime göre dallanma (ileride genişletilecek)
        next_index = chosen.get('next', self._current_index + 1)
        self._current_index = next_index
        self._load_line(self._current_index)

    def close(self) -> None:
        """Diyalogu kapatır."""
        self._active = False
        self._dialogue_data.clear()
        _logger.info("Diyalog kapatıldı.")

    def update(self, dt: float) -> None:
        """Typewriter animasyonunu günceller."""
        if not self._active or self._is_complete:
            return

        self._char_timer += dt
        while self._char_timer >= self._char_speed:
            self._char_timer -= self._char_speed
            if self._char_index < len(self._current_text):
                self._char_index += 1
                self._displayed_text = self._current_text[:self._char_index]
            else:
                self._is_complete = True
                break

    def draw(self, surface: pygame.Surface) -> None:
        """Diyalog kutusunu çizer."""
        if not self._active or not self._font:
            return

        # Panel boyutları
        margin = 20
        panel_h = 130
        panel_y = SCREEN_HEIGHT - panel_h - margin
        panel_w = SCREEN_WIDTH - margin * 2

        # Arka plan paneli
        panel = pygame.Surface((panel_w, panel_h), pygame.SRCALPHA)
        panel.fill(COLOR_UI_BG)
        surface.blit(panel, (margin, panel_y))
        pygame.draw.rect(surface, COLOR_UI_BORDER,
                         (margin, panel_y, panel_w, panel_h), 2)

        # Konuşmacı adı
        if self._speaker_name:
            name_bg = pygame.Surface((len(self._speaker_name) * 10 + 20, 24),
                                     pygame.SRCALPHA)
            name_bg.fill((30, 30, 50, 230))
            surface.blit(name_bg, (margin + 10, panel_y - 16))
            name_surf = self._name_font.render(
                self._speaker_name, True, COLOR_GOLD
            )
            surface.blit(name_surf, (margin + 20, panel_y - 14))

        # Metin (satır kırma)
        text_x = margin + 20
        text_y = panel_y + 18
        max_width = panel_w - 40

        words = self._displayed_text.split(' ')
        line = ""
        line_y = text_y

        for word in words:
            test_line = line + (' ' if line else '') + word
            test_surf = self._font.render(test_line, True, COLOR_UI_TEXT)
            if test_surf.get_width() > max_width:
                # Bu satırı çiz, yeni satıra geç
                if line:
                    surf = self._font.render(line, True, COLOR_UI_TEXT)
                    surface.blit(surf, (text_x, line_y))
                    line_y += 26
                line = word
            else:
                line = test_line

        if line:
            surf = self._font.render(line, True, COLOR_UI_TEXT)
            surface.blit(surf, (text_x, line_y))

        # Seçenekler
        if self._is_complete and self._choices:
            choice_y = panel_y + panel_h + 5
            for i, choice in enumerate(self._choices):
                is_selected = (i == self._choice_index)
                prefix = "▶ " if is_selected else "  "
                color = COLOR_GOLD if is_selected else COLOR_UI_TEXT
                choice_surf = self._font.render(
                    prefix + choice.get('text', '?'), True, color
                )
                surface.blit(choice_surf, (text_x, choice_y + i * 28))

        # Devam göstergesi (▼ yanıp söner)
        if self._is_complete and not self._choices:
            import time
            if int(time.time() * 2) % 2:
                indicator = self._font.render("▼", True, COLOR_UI_TEXT)
                surface.blit(indicator,
                             (margin + panel_w - 30, panel_y + panel_h - 25))

    @property
    def is_active(self) -> bool:
        return self._active

    @property
    def is_complete(self) -> bool:
        return self._is_complete
