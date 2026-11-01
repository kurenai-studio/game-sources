"""
Shinrin CS — Bölge (Zone) ve Portal Sınıfları.

Zone: Bir harita alanını, entity'lerini ve özelliklerini tanımlar.
Portal: Bölgeler arası geçiş noktasını temsil eder.
"""

from __future__ import annotations

import pygame
from world.tilemap import TileMap
from utils.constants import TILE_SIZE, COLOR_SAKURA_PINK
from utils.logger import get_logger

_logger = get_logger("Zone")


class Portal:
    """
    Bölgeler arası geçiş noktası.

    Attributes:
        _x, _y: Portal piksel konumu.
        _target_zone: Hedef bölge adı.
        _target_x, _target_y: Hedef bölgede spawn noktası.
    """

    def __init__(self, x: float, y: float, target_zone: str,
                 target_x: float, target_y: float):
        self._x = x
        self._y = y
        self._target_zone = target_zone
        self._target_x = target_x
        self._target_y = target_y
        self._rect = pygame.Rect(int(x), int(y), TILE_SIZE, TILE_SIZE)
        self._active = True

    def check_collision(self, entity_rect: pygame.Rect) -> bool:
        """Entity'nin portal'a girip girmediğini kontrol eder."""
        return self._active and self._rect.colliderect(entity_rect)

    def draw(self, surface: pygame.Surface, camera) -> None:
        """Portal'ı çizer (parlayan efekt)."""
        import math
        import time

        sx, sy = camera.apply(self._x, self._y)
        alpha = int(120 + 60 * math.sin(time.time() * 3))

        portal_surf = pygame.Surface((TILE_SIZE, TILE_SIZE), pygame.SRCALPHA)
        pygame.draw.ellipse(portal_surf,
                            (*COLOR_SAKURA_PINK, alpha),
                            (2, 4, TILE_SIZE - 4, TILE_SIZE - 8))
        pygame.draw.ellipse(portal_surf,
                            (255, 255, 255, alpha // 2),
                            (6, 8, TILE_SIZE - 12, TILE_SIZE - 16))
        surface.blit(portal_surf, (int(sx), int(sy)))

    @property
    def target_zone(self) -> str:
        return self._target_zone

    @property
    def target_position(self) -> tuple:
        return self._target_x, self._target_y

    @property
    def rect(self) -> pygame.Rect:
        return self._rect


class Zone:
    """
    Oyun dünyasındaki bir bölge.

    Bir TileMap, entity listesi, portal listesi ve
    ortam ayarlarını içerir.
    """

    def __init__(self, name: str, width: int = 40, height: int = 30):
        self._name: str = name
        self._tilemap: TileMap = TileMap(width, height)
        self._entities: list = []
        self._portals: list = []
        self._ambient_color: tuple = (0, 0, 0, 0)
        self._music_path: str = ""
        _logger.debug("Bölge oluşturuldu: '%s' (%dx%d)", name, width, height)

    def generate(self, seed: int = 42) -> None:
        """Bölge haritasını prosedürel olarak oluşturur."""
        self._tilemap.generate_village_map(seed)

    @property
    def name(self) -> str:
        return self._name

    @property
    def tilemap(self) -> TileMap:
        return self._tilemap

    @property
    def entities(self) -> list:
        return self._entities

    @property
    def portals(self) -> list:
        return self._portals

    def add_entity(self, entity) -> None:
        self._entities.append(entity)

    def remove_entity(self, entity) -> None:
        if entity in self._entities:
            self._entities.remove(entity)

    def add_portal(self, portal: Portal) -> None:
        self._portals.append(portal)

    def get_spawn_point(self) -> tuple:
        return self._tilemap.get_spawn_point()

    def update(self, dt: float) -> None:
        """Bölgedeki tüm entity'leri günceller."""
        for entity in self._entities:
            if entity.active:
                entity.update(dt)

    def draw(self, surface: pygame.Surface, camera) -> None:
        """Bölgeyi çizer: tilemap + entity'ler + portal'lar."""
        self._tilemap.draw(surface, camera)
        for portal in self._portals:
            portal.draw(surface, camera)
        # Entity'leri Y sırasına göre çiz (derinlik hissi)
        sorted_entities = sorted(self._entities, key=lambda e: e.y)
        for entity in sorted_entities:
            if entity.visible:
                entity.draw(surface, camera)
