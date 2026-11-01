"""
Shinrin CS — Çizim / Render Katmanı.

Ekrana çizim yapmak için yardımcı fonksiyonlar sunar.
Z-sıralama, katmanlı çizim ve debug görselleştirme desteği.
"""

from __future__ import annotations

import pygame
from utils.constants import (
    COLOR_BLACK, COLOR_WHITE, COLOR_HP_BAR,
    COLOR_HP_BAR_LOW, COLOR_MP_BAR, COLOR_UI_BG,
    COLOR_UI_BORDER, FONT_SIZE_SMALL
)
from utils.logger import get_logger

_logger = get_logger("Renderer")


class Renderer:
    """
    Merkezi çizim katmanı.

    Ekranı temizleme, katmanlı çizim, UI bar'ları ve
    debug overlay işlemleri burada bulunur.
    """

    def __init__(self, screen: pygame.Surface):
        self._screen: pygame.Surface = screen
        self._debug_mode: bool = False
        self._debug_font: pygame.font.Font | None = None
        _logger.info("Renderer başlatıldı.")

    @property
    def screen(self) -> pygame.Surface:
        return self._screen

    @property
    def debug_mode(self) -> bool:
        return self._debug_mode

    @debug_mode.setter
    def debug_mode(self, value: bool):
        self._debug_mode = value

    # ══════════════════════════════════════════
    #  Temel Çizim
    # ══════════════════════════════════════════

    def clear(self, color: tuple = COLOR_BLACK) -> None:
        """Ekranı belirtilen renk ile temizler."""
        self._screen.fill(color)

    def present(self) -> None:
        """Frame buffer'ı ekrana yansıtır."""
        pygame.display.flip()

    # ══════════════════════════════════════════
    #  UI Çizim Yardımcıları
    # ══════════════════════════════════════════

    def draw_bar(
        self,
        x: int, y: int,
        width: int, height: int,
        current: float, maximum: float,
        fill_color: tuple,
        bg_color: tuple = (40, 40, 40),
        border_color: tuple | None = None
    ) -> None:
        """
        İlerleme/can/mana barı çizer.

        Args:
            x, y: Sol üst köşe konumu.
            width, height: Bar boyutları.
            current: Mevcut değer.
            maximum: Maksimum değer.
            fill_color: Dolgu rengi.
            bg_color: Arka plan rengi.
            border_color: Kenarlık rengi (None = kenarlık yok).
        """
        ratio = max(0.0, min(1.0, current / maximum)) if maximum > 0 else 0

        # Arka plan
        pygame.draw.rect(self._screen, bg_color,
                         (x, y, width, height))
        # Dolgu
        fill_width = int(width * ratio)
        if fill_width > 0:
            pygame.draw.rect(self._screen, fill_color,
                             (x, y, fill_width, height))
        # Kenarlık
        if border_color:
            pygame.draw.rect(self._screen, border_color,
                             (x, y, width, height), 1)

    def draw_hp_bar(
        self,
        x: int, y: int,
        width: int, height: int,
        current_hp: int, max_hp: int
    ) -> None:
        """HP barı çizer — düşükse renk kırmızıya döner."""
        ratio = current_hp / max_hp if max_hp > 0 else 0
        color = COLOR_HP_BAR if ratio > 0.3 else COLOR_HP_BAR_LOW
        self.draw_bar(x, y, width, height, current_hp, max_hp,
                      color, border_color=COLOR_UI_BORDER)

    def draw_mp_bar(
        self,
        x: int, y: int,
        width: int, height: int,
        current_mp: int, max_mp: int
    ) -> None:
        """MP barı çizer."""
        self.draw_bar(x, y, width, height, current_mp, max_mp,
                      COLOR_MP_BAR, border_color=COLOR_UI_BORDER)

    def draw_panel(
        self,
        x: int, y: int,
        width: int, height: int,
        bg_color: tuple = COLOR_UI_BG,
        border_color: tuple = COLOR_UI_BORDER,
        border_width: int = 2
    ) -> None:
        """
        Yarı saydam UI paneli çizer.

        Args:
            x, y: Sol üst köşe.
            width, height: Panel boyutları.
            bg_color: Arka plan rengi (RGBA destekler).
            border_color: Kenarlık rengi.
            border_width: Kenarlık kalınlığı.
        """
        # Yarı saydam yüzey
        panel = pygame.Surface((width, height), pygame.SRCALPHA)
        panel.fill(bg_color)
        self._screen.blit(panel, (x, y))

        # Kenarlık
        if border_width > 0:
            pygame.draw.rect(self._screen, border_color,
                             (x, y, width, height), border_width)

    # ══════════════════════════════════════════
    #  Debug Overlay
    # ══════════════════════════════════════════

    def draw_debug_info(self, fps: float, entity_count: int) -> None:
        """FPS ve entity sayısını gösterir (debug modu)."""
        if not self._debug_mode:
            return

        if self._debug_font is None:
            self._debug_font = pygame.font.Font(None, FONT_SIZE_SMALL)

        texts = [
            f"FPS: {fps:.0f}",
            f"Entities: {entity_count}"
        ]

        for i, text in enumerate(texts):
            surf = self._debug_font.render(text, True, COLOR_WHITE)
            self._screen.blit(surf, (5, 5 + i * 18))

    def draw_collision_rect(
        self,
        rect: pygame.Rect,
        color: tuple = (255, 0, 0),
        width: int = 1
    ) -> None:
        """Debug: Çarpışma kutusunu çizer."""
        if self._debug_mode:
            pygame.draw.rect(self._screen, color, rect, width)

    # ══════════════════════════════════════════
    #  Ekran Geçiş Efektleri
    # ══════════════════════════════════════════

    def fade_to_black(self, alpha: int) -> None:
        """
        Ekranı siyaha karartır (geçiş efekti).

        Args:
            alpha: Karartma derecesi (0–255).
        """
        overlay = pygame.Surface(self._screen.get_size(), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, min(255, max(0, alpha))))
        self._screen.blit(overlay, (0, 0))
