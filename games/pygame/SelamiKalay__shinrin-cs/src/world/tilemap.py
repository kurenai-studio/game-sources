"""
Shinrin CS — Karo Haritası (TileMap) Sınıfı.

2D grid tabanlı harita yönetimi. Prosedürel veya
veri dosyasından harita oluşturma, çizim ve çarpışma
sorgusu sağlar.
"""

from __future__ import annotations

import random
import pygame
from world.tile import Tile
from utils.constants import TILE_SIZE, SCREEN_WIDTH, SCREEN_HEIGHT
from utils.logger import get_logger

_logger = get_logger("TileMap")


class TileMap:
    """
    Karo haritası yönetim sınıfı.

    Attributes:
        _width (int): Harita genişliği (karo cinsinden).
        _height (int): Harita yüksekliği (karo cinsinden).
        _tiles (list): 2D Tile dizisi [y][x].
        _cached_surface (Surface): Önbelleğe alınmış harita görseli.
    """

    def __init__(self, width: int, height: int):
        self._width: int = width
        self._height: int = height
        self._tiles: list = []
        self._cached_surface: pygame.Surface | None = None
        self._dirty: bool = True  # Önbellek geçersiz mi?

    # ══════════════════════════════════════════
    #  Harita Oluşturma
    # ══════════════════════════════════════════

    def generate_village_map(self, seed: int = 42) -> None:
        """
        Prosedürel Japon köyü haritası oluşturur.

        Args:
            seed: Rastgelelik tohumu (tekrarlanabilirlik için).
        """
        rng = random.Random(seed)
        self._tiles = []

        for y in range(self._height):
            row = []
            for x in range(self._width):
                tile_id = self._determine_tile(x, y, rng)
                row.append(Tile(tile_id, x, y))
            self._tiles.append(row)

        # Yollar ekle
        self._carve_paths(rng)
        # Su kenarları
        self._add_water_border()

        self._dirty = True
        _logger.info("Köy haritası oluşturuldu: %dx%d", self._width, self._height)

    def _determine_tile(self, x: int, y: int, rng: random.Random) -> int:
        """Koordinata göre karo tipini belirler."""
        # Kenarlar su
        if x <= 1 or x >= self._width - 2 or y <= 1 or y >= self._height - 2:
            return Tile.WATER

        # Rastgele dağılım
        r = rng.random()
        if r < 0.60:
            return Tile.GRASS
        elif r < 0.72:
            return Tile.DARK_GRASS
        elif r < 0.80:
            return Tile.FLOWER
        elif r < 0.85:
            return Tile.DIRT
        elif r < 0.90:
            return Tile.STONE
        else:
            return Tile.GRASS

    def _carve_paths(self, rng: random.Random) -> None:
        """Haritaya yollar oyar."""
        # Yatay ana yol
        mid_y = self._height // 2
        for x in range(3, self._width - 3):
            for dy in range(-1, 2):
                ty = mid_y + dy
                if 0 <= ty < self._height:
                    self._tiles[ty][x] = Tile(Tile.PATH, x, ty)

        # Dikey yollar
        cross_points = [self._width // 3, self._width * 2 // 3]
        for cx in cross_points:
            for y in range(3, self._height - 3):
                self._tiles[y][cx] = Tile(Tile.PATH, cx, y)

        # Köy alanları (ahşap zemin)
        village_centers = [
            (self._width // 3, mid_y - 4),
            (self._width * 2 // 3, mid_y + 4),
            (self._width // 2, mid_y - 6),
        ]
        for vx, vy in village_centers:
            for dy in range(-2, 3):
                for dx in range(-3, 4):
                    tx, ty = vx + dx, vy + dy
                    if 2 < tx < self._width - 3 and 2 < ty < self._height - 3:
                        self._tiles[ty][tx] = Tile(Tile.WOOD_FLOOR, tx, ty)

    def _add_water_border(self) -> None:
        """Harita kenarlarını su karosu yapar."""
        for y in range(self._height):
            for x in range(self._width):
                if (x == 0 or x == self._width - 1 or
                        y == 0 or y == self._height - 1):
                    self._tiles[y][x] = Tile(Tile.WATER, x, y)

    def load_from_data(self, data: list) -> None:
        """
        2D int dizisinden harita yükler.

        Args:
            data: [[tile_id, ...], ...] formatında 2D liste.
        """
        self._tiles = []
        for y, row in enumerate(data):
            tile_row = []
            for x, tid in enumerate(row):
                tile_row.append(Tile(tid, x, y))
            self._tiles.append(tile_row)
        self._width = len(data[0]) if data else 0
        self._height = len(data)
        self._dirty = True

    # ══════════════════════════════════════════
    #  Çizim
    # ══════════════════════════════════════════

    def draw(self, surface: pygame.Surface, camera) -> None:
        """
        Haritayı kamera görüş alanına göre çizer.
        Sadece görünür karoları çizer (performans).

        Args:
            surface: Çizim yüzeyi.
            camera: Kamera nesnesi.
        """
        if not self._tiles:
            return

        visible = camera.get_visible_area()

        # Görünür karo aralığını hesapla
        start_x = max(0, visible.x // TILE_SIZE - 1)
        start_y = max(0, visible.y // TILE_SIZE - 1)
        end_x = min(self._width, (visible.x + visible.width) // TILE_SIZE + 2)
        end_y = min(self._height, (visible.y + visible.height) // TILE_SIZE + 2)

        for y in range(start_y, end_y):
            for x in range(start_x, end_x):
                tile = self._tiles[y][x]
                screen_x, screen_y = camera.apply(tile.pixel_x, tile.pixel_y)
                surface.blit(tile.surface, (int(screen_x), int(screen_y)))

    # ══════════════════════════════════════════
    #  Çarpışma Sorgusu
    # ══════════════════════════════════════════

    def is_walkable(self, pixel_x: float, pixel_y: float) -> bool:
        """
        Belirtilen piksel koordinatının geçilebilir olup olmadığını sorgular.

        Args:
            pixel_x, pixel_y: Dünya piksel koordinatı.

        Returns:
            True ise karo geçilebilir.
        """
        grid_x = int(pixel_x // TILE_SIZE)
        grid_y = int(pixel_y // TILE_SIZE)

        if not (0 <= grid_x < self._width and 0 <= grid_y < self._height):
            return False

        return self._tiles[grid_y][grid_x].walkable

    def is_rect_walkable(self, rect: pygame.Rect) -> bool:
        """
        Bir dikdörtgenin kapladığı tüm karoların geçilebilir
        olup olmadığını kontrol eder.
        """
        corners = [
            (rect.left + 2, rect.top + 2),
            (rect.right - 3, rect.top + 2),
            (rect.left + 2, rect.bottom - 3),
            (rect.right - 3, rect.bottom - 3),
        ]
        return all(self.is_walkable(cx, cy) for cx, cy in corners)

    def get_tile_at(self, grid_x: int, grid_y: int) -> Tile | None:
        """Grid koordinatındaki karoyu döndürür."""
        if 0 <= grid_x < self._width and 0 <= grid_y < self._height:
            return self._tiles[grid_y][grid_x]
        return None

    # ══════════════════════════════════════════
    #  Properties
    # ══════════════════════════════════════════

    @property
    def width(self) -> int:
        return self._width

    @property
    def height(self) -> int:
        return self._height

    @property
    def pixel_width(self) -> int:
        return self._width * TILE_SIZE

    @property
    def pixel_height(self) -> int:
        return self._height * TILE_SIZE

    def get_spawn_point(self) -> tuple:
        """Oyuncunun doğma noktasını döndürür (ilk geçilebilir karo)."""
        for y in range(self._height):
            for x in range(self._width):
                if self._tiles[y][x].walkable:
                    return (x * TILE_SIZE + TILE_SIZE // 2,
                            y * TILE_SIZE + TILE_SIZE // 2)
        return (TILE_SIZE * 3, TILE_SIZE * 3)
