"""
Shinrin CS — Kamera Sistemi.

Oyun dünyasını takip eden 2D kamera. Oyuncuyu merkeze alır,
harita sınırlarına uyar ve yumuşak geçiş (lerp) sağlar.
"""

import pygame
from utils.constants import SCREEN_WIDTH, SCREEN_HEIGHT
from utils.helpers import lerp
from utils.logger import get_logger

_logger = get_logger("Camera")


class Camera:
    """
    2D Kamera sınıfı.

    Hedef entity'yi takip eder. Harita sınırlarını aşmaz.
    Yumuşak takip (smoothing) destekler.
    """

    def __init__(self, width: int = SCREEN_WIDTH, height: int = SCREEN_HEIGHT):
        self._x: float = 0.0
        self._y: float = 0.0
        self._width: int = width
        self._height: int = height
        self._target = None
        self._smoothing: float = 0.1       # 0 = anlık, 1 = çok yavaş
        self._map_width: int = 0
        self._map_height: int = 0
        self._shake_intensity: float = 0.0
        self._shake_duration: float = 0.0
        _logger.info("Kamera başlatıldı (%dx%d).", width, height)

    # ══════════════════════════════════════════
    #  Hedef Takibi
    # ══════════════════════════════════════════

    def set_target(self, target) -> None:
        """
        Kameranın takip edeceği hedefi ayarlar.

        Args:
            target: get_position() metodu olan bir entity.
        """
        self._target = target

    def set_map_bounds(self, map_width: int, map_height: int) -> None:
        """
        Harita sınırlarını ayarlar.

        Args:
            map_width: Harita genişliği (piksel).
            map_height: Harita yüksekliği (piksel).
        """
        self._map_width = map_width
        self._map_height = map_height

    @property
    def smoothing(self) -> float:
        return self._smoothing

    @smoothing.setter
    def smoothing(self, value: float):
        self._smoothing = max(0.01, min(1.0, value))

    # ══════════════════════════════════════════
    #  Güncelleme
    # ══════════════════════════════════════════

    def update(self, dt: float) -> None:
        """
        Kamera konumunu günceller.

        Args:
            dt: Delta time (saniye).
        """
        if self._target is None:
            return

        # Hedef pozisyonunu al
        target_x, target_y = self._target.get_position()

        # Hedefi ekranın ortasına hizala
        goal_x = target_x - self._width // 2
        goal_y = target_y - self._height // 2

        # Yumuşak takip (lerp)
        smooth_factor = 1.0 - (self._smoothing ** (dt * 60))
        self._x = lerp(self._x, goal_x, smooth_factor)
        self._y = lerp(self._y, goal_y, smooth_factor)

        # Harita sınırlarına uydur
        self._clamp_to_bounds()

        # Sarsıntı efekti
        if self._shake_duration > 0:
            self._shake_duration -= dt
            import random
            self._x += random.uniform(
                -self._shake_intensity, self._shake_intensity
            )
            self._y += random.uniform(
                -self._shake_intensity, self._shake_intensity
            )

    def _clamp_to_bounds(self) -> None:
        """Kamerayı harita sınırları içinde tutar."""
        if self._map_width > 0 and self._map_height > 0:
            self._x = max(0, min(self._x,
                                  self._map_width - self._width))
            self._y = max(0, min(self._y,
                                  self._map_height - self._height))
        else:
            # Harita sınırı yoksa negatif olmasın
            self._x = max(0, self._x)
            self._y = max(0, self._y)

    # ══════════════════════════════════════════
    #  Efektler
    # ══════════════════════════════════════════

    def shake(self, intensity: float = 5.0, duration: float = 0.3) -> None:
        """
        Kamera sarsıntısı başlatır (hasar alındığında vb.)

        Args:
            intensity: Sarsıntı şiddeti (piksel).
            duration: Sarsıntı süresi (saniye).
        """
        self._shake_intensity = intensity
        self._shake_duration = duration

    # ══════════════════════════════════════════
    #  Dönüşüm Metotları
    # ══════════════════════════════════════════

    def apply(self, world_x: float, world_y: float) -> tuple[float, float]:
        """
        Dünya koordinatını ekran koordinatına çevirir.

        Args:
            world_x: Dünyadaki X pozisyonu.
            world_y: Dünyadaki Y pozisyonu.

        Returns:
            (ekran_x, ekran_y) tuple.
        """
        return world_x - self._x, world_y - self._y

    def apply_rect(self, rect: pygame.Rect) -> pygame.Rect:
        """
        Bir Rect'i dünya koordinatından ekran koordinatına çevirir.

        Args:
            rect: Dünyadaki Rect.

        Returns:
            Ekran koordinatında yeni Rect.
        """
        return pygame.Rect(
            rect.x - int(self._x),
            rect.y - int(self._y),
            rect.width,
            rect.height
        )

    def get_visible_area(self) -> pygame.Rect:
        """
        Kameranın görebildiği dünya alanını döndürür.

        Returns:
            Görünür alanı temsil eden Rect.
        """
        return pygame.Rect(
            int(self._x), int(self._y),
            self._width, self._height
        )

    @property
    def x(self) -> float:
        return self._x

    @property
    def y(self) -> float:
        return self._y
