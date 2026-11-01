"""
Shinrin CS — Soyut Temel Sınıf: GameObject.

Oyundaki tüm nesnelerin (entity, item, UI vb.) ortak atası.
Pozisyon, boyut, görünürlük ve temel çizim/güncelleme
arayüzünü tanımlar.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
import pygame


class GameObject(ABC):
    """
    Oyundaki tüm nesnelerin soyut temel sınıfı.

    Alt sınıflar update() ve draw() metotlarını
    EZMELİDİR (override).

    Attributes:
        _x (float): X pozisyonu (dünya koordinatı).
        _y (float): Y pozisyonu (dünya koordinatı).
        _width (int): Nesne genişliği (piksel).
        _height (int): Nesne yüksekliği (piksel).
        _visible (bool): Görünür mü?
        _active (bool): Aktif mi? (güncelleniyor mu?)
    """

    def __init__(self, x: float = 0.0, y: float = 0.0,
                 width: int = 32, height: int = 32):
        # ── Protected: Alt sınıflar erişebilir ──
        self._x: float = x
        self._y: float = y
        self._width: int = width
        self._height: int = height
        self._visible: bool = True
        self._active: bool = True

    # ══════════════════════════════════════════
    #  Soyut Metotlar (Alt sınıflar EZMEK ZORUNDA)
    # ══════════════════════════════════════════

    @abstractmethod
    def update(self, dt: float) -> None:
        """
        Her frame çağrılır. Nesnenin mantığını günceller.

        Args:
            dt: Delta time (saniye cinsinden).
        """
        pass

    @abstractmethod
    def draw(self, surface: pygame.Surface, camera=None) -> None:
        """
        Nesneyi ekrana çizer.

        Args:
            surface: Çizim yapılacak pygame.Surface.
            camera: Opsiyonel kamera (dünya→ekran dönüşümü için).
        """
        pass

    # ══════════════════════════════════════════
    #  Pozisyon Yönetimi (Kapsüllenmiş)
    # ══════════════════════════════════════════

    def get_position(self) -> tuple[float, float]:
        """Nesnenin dünya konumunu döndürür."""
        return self._x, self._y

    def set_position(self, x: float, y: float) -> None:
        """Nesnenin dünya konumunu ayarlar."""
        self._x = x
        self._y = y

    @property
    def x(self) -> float:
        return self._x

    @x.setter
    def x(self, value: float):
        self._x = value

    @property
    def y(self) -> float:
        return self._y

    @y.setter
    def y(self, value: float):
        self._y = value

    # ══════════════════════════════════════════
    #  Boyut ve Dikdörtgen
    # ══════════════════════════════════════════

    def get_rect(self) -> pygame.Rect:
        """
        Nesnenin çarpışma dikdörtgenini döndürür.

        Returns:
            Nesneyi kapsayan pygame.Rect.
        """
        return pygame.Rect(
            int(self._x), int(self._y),
            self._width, self._height
        )

    @property
    def width(self) -> int:
        return self._width

    @property
    def height(self) -> int:
        return self._height

    # ══════════════════════════════════════════
    #  Görünürlük ve Aktivite
    # ══════════════════════════════════════════

    @property
    def visible(self) -> bool:
        return self._visible

    @visible.setter
    def visible(self, value: bool):
        self._visible = value

    @property
    def active(self) -> bool:
        return self._active

    @active.setter
    def active(self, value: bool):
        self._active = value

    # ══════════════════════════════════════════
    #  Temsil
    # ══════════════════════════════════════════

    def __repr__(self) -> str:
        return (
            f"<{self.__class__.__name__} "
            f"pos=({self._x:.1f}, {self._y:.1f}) "
            f"size=({self._width}x{self._height}) "
            f"active={self._active}>"
        )
