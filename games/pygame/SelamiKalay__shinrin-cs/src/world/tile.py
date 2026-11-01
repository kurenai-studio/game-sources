"""
Shinrin CS — Tek Karo (Tile) Sınıfı.

Haritadaki her bir karoyu temsil eder. Geçilebilirlik,
karo tipi ve katman bilgisi içerir.
"""

from __future__ import annotations

import pygame
from utils.constants import TILE_SIZE


class Tile:
    """
    Haritadaki tek bir karo.

    Attributes:
        _tile_id (int): Karo tipi kimliği.
        _x, _y (int): Grid koordinatları (tile cinsinden).
        _walkable (bool): Üzerinden geçilebilir mi?
        _surface (Surface): Karonun görseli.
    """

    # ── Karo Tipleri ──
    GRASS = 0
    DIRT = 1
    WATER = 2
    STONE = 3
    WOOD_FLOOR = 4
    SAND = 5
    BRIDGE = 6
    FLOWER = 7
    DARK_GRASS = 8
    PATH = 9

    # Tip → (renk, geçilebilir) eşlemesi
    TILE_DATA = {
        GRASS:      ((54, 120, 58),   True),
        DIRT:       ((139, 110, 75),  True),
        WATER:      ((40, 80, 150),   False),
        STONE:      ((120, 120, 120), False),
        WOOD_FLOOR: ((160, 120, 75),  True),
        SAND:       ((210, 190, 130), True),
        BRIDGE:     ((140, 100, 60),  True),
        FLOWER:     ((54, 130, 58),   True),
        DARK_GRASS: ((35, 85, 40),    True),
        PATH:       ((170, 140, 95),  True),
    }

    def __init__(self, tile_id: int, grid_x: int, grid_y: int):
        self._tile_id: int = tile_id
        self._grid_x: int = grid_x
        self._grid_y: int = grid_y

        data = self.TILE_DATA.get(tile_id, ((200, 0, 200), True))
        self._walkable: bool = data[1]
        self._base_color: tuple = data[0]
        self._surface: pygame.Surface = self._create_surface()

    def _create_surface(self) -> pygame.Surface:
        """Karo görseli oluşturur (prosedürel piksel art)."""
        surf = pygame.Surface((TILE_SIZE, TILE_SIZE))
        surf.fill(self._base_color)

        import random
        rng = random.Random(self._grid_x * 1000 + self._grid_y)

        r, g, b = self._base_color

        if self._tile_id == self.GRASS or self._tile_id == self.DARK_GRASS:
            # Çimen detayları
            for _ in range(6):
                gx = rng.randint(2, TILE_SIZE - 3)
                gy = rng.randint(2, TILE_SIZE - 3)
                variation = rng.randint(-15, 15)
                c = (max(0, min(255, r + variation)),
                     max(0, min(255, g + variation + 10)),
                     max(0, min(255, b + variation)))
                pygame.draw.line(surf, c, (gx, gy), (gx, gy - rng.randint(2, 5)))

        elif self._tile_id == self.FLOWER:
            # Çimen + çiçekler
            for _ in range(4):
                gx = rng.randint(2, TILE_SIZE - 3)
                gy = rng.randint(2, TILE_SIZE - 3)
                pygame.draw.line(surf, (40, 110, 45),
                                 (gx, gy), (gx, gy - 3))
            # Çiçekler
            flower_colors = [(255, 180, 200), (255, 255, 150),
                             (200, 150, 255), (255, 200, 100)]
            for _ in range(2):
                fx = rng.randint(4, TILE_SIZE - 5)
                fy = rng.randint(4, TILE_SIZE - 8)
                fc = rng.choice(flower_colors)
                pygame.draw.circle(surf, fc, (fx, fy), 2)

        elif self._tile_id == self.WATER:
            # Su dalgaları
            for i in range(3):
                wy = 8 + i * 10
                wave_color = (min(255, r + 30), min(255, g + 20),
                              min(255, b + 30))
                pygame.draw.line(surf, wave_color,
                                 (2, wy), (TILE_SIZE - 3, wy + 2))

        elif self._tile_id == self.STONE:
            # Taş dokusu
            for _ in range(3):
                sx = rng.randint(3, TILE_SIZE - 6)
                sy = rng.randint(3, TILE_SIZE - 6)
                sc = rng.randint(-20, 20)
                pygame.draw.rect(
                    surf,
                    (max(0, r + sc), max(0, g + sc), max(0, b + sc)),
                    (sx, sy, rng.randint(4, 8), rng.randint(4, 8))
                )

        elif self._tile_id == self.DIRT or self._tile_id == self.PATH:
            # Toprak detay
            for _ in range(5):
                dx = rng.randint(1, TILE_SIZE - 2)
                dy = rng.randint(1, TILE_SIZE - 2)
                dc = rng.randint(-10, 10)
                surf.set_at((dx, dy),
                            (max(0, min(255, r + dc)),
                             max(0, min(255, g + dc)),
                             max(0, min(255, b + dc))))

        return surf

    # ── Properties ──

    @property
    def tile_id(self) -> int:
        return self._tile_id

    @property
    def walkable(self) -> bool:
        return self._walkable

    @walkable.setter
    def walkable(self, value: bool):
        self._walkable = value

    @property
    def surface(self) -> pygame.Surface:
        return self._surface

    @property
    def grid_x(self) -> int:
        return self._grid_x

    @property
    def grid_y(self) -> int:
        return self._grid_y

    @property
    def pixel_x(self) -> int:
        return self._grid_x * TILE_SIZE

    @property
    def pixel_y(self) -> int:
        return self._grid_y * TILE_SIZE

    def get_rect(self) -> pygame.Rect:
        return pygame.Rect(self.pixel_x, self.pixel_y, TILE_SIZE, TILE_SIZE)
