"""
Shinrin CS — Girdi (Input) Yönetim Sistemi.

Klavye olaylarını merkezi olarak işler. Tek seferlik
(just_pressed) ve sürekli basılı (is_held) tespiti sağlar.
İleride gamepad desteği de eklenebilir.
"""

from __future__ import annotations

import pygame
from utils.logger import get_logger

_logger = get_logger("InputHandler")


class InputHandler:
    """
    Merkezi girdi yönetimi sınıfı.

    Her frame'de update() çağrılarak tuş durumları güncellenir.
    """

    def __init__(self):
        self._keys_pressed: set[int] = set()     # Bu frame basıldı
        self._keys_released: set[int] = set()     # Bu frame bırakıldı
        self._keys_held: set[int] = set()         # Basılı tutulan
        self._quit_requested: bool = False
        _logger.info("InputHandler başlatıldı.")

    # ══════════════════════════════════════════
    #  Frame Güncellemesi
    # ══════════════════════════════════════════

    def process_events(self, events: list[pygame.event.Event]) -> None:
        """
        Pygame olay kuyruğunu işler. Her frame'in başında çağrılır.

        Args:
            events: pygame.event.get() tarafından döndürülen olay listesi.
        """
        self._keys_pressed.clear()
        self._keys_released.clear()

        for event in events:
            if event.type == pygame.QUIT:
                self._quit_requested = True

            elif event.type == pygame.KEYDOWN:
                self._keys_pressed.add(event.key)
                self._keys_held.add(event.key)

            elif event.type == pygame.KEYUP:
                self._keys_released.add(event.key)
                self._keys_held.discard(event.key)

    # ══════════════════════════════════════════
    #  Sorgu Metotları
    # ══════════════════════════════════════════

    def is_just_pressed(self, key: int) -> bool:
        """
        Tuş bu frame'de ilk kez mi basıldı?

        Args:
            key: pygame.K_* tuş kodu.

        Returns:
            True ise tuş bu frame'de basılmış.
        """
        return key in self._keys_pressed

    def is_held(self, key: int) -> bool:
        """
        Tuş basılı mı tutuluyor?

        Args:
            key: pygame.K_* tuş kodu.

        Returns:
            True ise tuş şu an basılı.
        """
        return key in self._keys_held

    def is_released(self, key: int) -> bool:
        """
        Tuş bu frame'de bırakıldı mı?

        Args:
            key: pygame.K_* tuş kodu.

        Returns:
            True ise tuş bu frame'de bırakılmış.
        """
        return key in self._keys_released

    @property
    def quit_requested(self) -> bool:
        """Pencere kapatma isteği geldi mi?"""
        return self._quit_requested

    def is_confirm(self) -> bool:
        """Onay tuşu (Enter veya Z) basıldı mı?"""
        return (self.is_just_pressed(pygame.K_RETURN) or
                self.is_just_pressed(pygame.K_z))

    def is_cancel(self) -> bool:
        """İptal tuşu (Escape veya X) basıldı mı?"""
        return (self.is_just_pressed(pygame.K_ESCAPE) or
                self.is_just_pressed(pygame.K_x))

    def is_pause(self) -> bool:
        """Duraklat tuşu (P veya Escape) basıldı mı?"""
        return self.is_just_pressed(pygame.K_p)

    def get_movement_vector(self) -> tuple[int, int]:
        """
        Yön tuşlarına göre (dx, dy) hareket vektörü döndürür.

        Returns:
            (-1, 0), (1, 0), (0, -1), (0, 1) veya (0, 0).
        """
        dx, dy = 0, 0

        if self.is_held(pygame.K_LEFT) or self.is_held(pygame.K_a):
            dx = -1
        elif self.is_held(pygame.K_RIGHT) or self.is_held(pygame.K_d):
            dx = 1

        if self.is_held(pygame.K_UP) or self.is_held(pygame.K_w):
            dy = -1
        elif self.is_held(pygame.K_DOWN) or self.is_held(pygame.K_s):
            dy = 1

        return dx, dy

    def reset(self) -> None:
        """Tüm girdi durumunu sıfırlar (sahne geçişinde kullanılır)."""
        self._keys_pressed.clear()
        self._keys_released.clear()
        self._keys_held.clear()
        self._quit_requested = False
