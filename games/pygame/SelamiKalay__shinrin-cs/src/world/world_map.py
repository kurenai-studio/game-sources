"""
Shinrin CS — Dünya Harita Yöneticisi.

Tüm bölgeleri (Zone) yönetir. Bölge geçişlerini,
entity'lerin yüklenmesini ve güncel bölgenin
güncellenmesini koordine eder.
"""

from __future__ import annotations

import pygame
from world.zone import Zone, Portal
from utils.constants import TILE_SIZE
from utils.logger import get_logger

_logger = get_logger("WorldMap")


class WorldMap:
    """
    Dünya yönetim sınıfı.

    Tüm bölgeleri saklar, aktif bölgeyi yönetir,
    bölge geçişlerini koordine eder.
    """

    def __init__(self):
        self._zones: dict = {}
        self._current_zone: Zone | None = None
        self._current_zone_name: str = ""
        _logger.info("WorldMap başlatıldı.")

    def add_zone(self, name: str, zone: Zone) -> None:
        """Bir bölgeyi dünyaya ekler."""
        self._zones[name] = zone
        _logger.debug("Bölge eklendi: '%s'", name)

    def load_zone(self, zone_name: str) -> None:
        """
        Belirtilen bölgeyi aktif yapar.

        Args:
            zone_name: Yüklenecek bölgenin adı.
        """
        if zone_name not in self._zones:
            _logger.error("Bölge bulunamadı: '%s'", zone_name)
            return

        self._current_zone = self._zones[zone_name]
        self._current_zone_name = zone_name
        _logger.info("Bölge yüklendi: '%s'", zone_name)

    @property
    def current_zone(self) -> Zone | None:
        return self._current_zone

    @property
    def current_zone_name(self) -> str:
        return self._current_zone_name

    def get_zone(self, name: str) -> Zone | None:
        return self._zones.get(name)

    def update(self, dt: float) -> None:
        """Aktif bölgeyi günceller."""
        if self._current_zone:
            self._current_zone.update(dt)

    def draw(self, surface: pygame.Surface, camera) -> None:
        """Aktif bölgeyi çizer."""
        if self._current_zone:
            self._current_zone.draw(surface, camera)

    def check_portals(self, entity_rect: pygame.Rect) -> Portal | None:
        """
        Entity'nin herhangi bir portala girip girmediğini kontrol eder.

        Returns:
            Girilen Portal veya None.
        """
        if not self._current_zone:
            return None

        for portal in self._current_zone.portals:
            if portal.check_collision(entity_rect):
                return portal
        return None
