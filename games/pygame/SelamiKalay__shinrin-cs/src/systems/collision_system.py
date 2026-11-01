"""
Shinrin CS — Çarpışma Algılama Sistemi.

Entity'ler arası ve entity-tilemap arası çarpışma
kontrolü ve çözümleme sağlar.
"""

from __future__ import annotations

import pygame
from utils.constants import TILE_SIZE
from utils.logger import get_logger

_logger = get_logger("CollisionSystem")


class CollisionSystem:
    """
    Merkezi çarpışma algılama ve çözümleme sistemi.
    """

    def __init__(self):
        pass

    @staticmethod
    def check_entity_collision(entity_a, entity_b) -> bool:
        """İki entity arasında çarpışma var mı kontrol eder."""
        return entity_a.get_collision_rect().colliderect(
            entity_b.get_collision_rect()
        )

    @staticmethod
    def resolve_tilemap_collision(entity, tilemap, dx: float, dy: float,
                                  dt: float) -> tuple:
        """
        Entity'nin tilemap ile çarpışmasını çözer.
        Hareket öncesi kontrol yapar, geçilemezse hareketi engeller.

        Args:
            entity: Hareket eden entity.
            tilemap: Çarpışma kontrolü yapılacak TileMap.
            dx, dy: Hareket yönü (-1, 0, 1).
            dt: Delta time.

        Returns:
            (new_x, new_y) — çarpışma çözümlendikten sonraki pozisyon.
        """
        speed = entity._move_speed * dt
        old_x, old_y = entity.get_position()
        new_x = old_x + dx * speed
        new_y = old_y + dy * speed

        # Çarpışma kutusu (alt yarı)
        coll_w = entity.width - 8
        coll_h = entity.height // 2
        coll_offset_x = 4
        coll_offset_y = entity.height // 2

        # X ekseninde kontrol
        test_rect_x = pygame.Rect(
            int(new_x + coll_offset_x),
            int(old_y + coll_offset_y),
            coll_w, coll_h
        )
        if not tilemap.is_rect_walkable(test_rect_x):
            new_x = old_x

        # Y ekseninde kontrol
        test_rect_y = pygame.Rect(
            int(new_x + coll_offset_x),
            int(new_y + coll_offset_y),
            coll_w, coll_h
        )
        if not tilemap.is_rect_walkable(test_rect_y):
            new_y = old_y

        return new_x, new_y

    @staticmethod
    def find_nearby_entities(entity, entities: list,
                             radius: float) -> list:
        """
        Belirtilen yarıçap içindeki entity'leri bulur.

        Args:
            entity: Merkez entity.
            entities: Aranacak entity listesi.
            radius: Arama yarıçapı (piksel).

        Returns:
            Yakındaki entity listesi.
        """
        ex, ey = entity.get_position()
        nearby = []

        for other in entities:
            if other is entity:
                continue
            ox, oy = other.get_position()
            dist = ((ox - ex) ** 2 + (oy - ey) ** 2) ** 0.5
            if dist <= radius:
                nearby.append(other)

        return nearby

    @staticmethod
    def find_interactable_in_front(player, entities: list,
                                    interact_range: float = 40.0):
        """
        Oyuncunun baktığı yöndeki etkileşilebilir entity'yi bulur.

        Args:
            player: Oyuncu entity'si.
            entities: Aranacak entity listesi.
            interact_range: Etkileşim menzili.

        Returns:
            En yakın etkileşilebilir entity veya None.
        """
        from utils.constants import DIR_UP, DIR_DOWN, DIR_LEFT, DIR_RIGHT

        px, py = player.get_position()

        # Baktığı yöne göre kontrol noktası
        if player.direction == DIR_UP:
            check_x, check_y = px, py - interact_range
        elif player.direction == DIR_DOWN:
            check_x, check_y = px, py + interact_range
        elif player.direction == DIR_LEFT:
            check_x, check_y = px - interact_range, py
        elif player.direction == DIR_RIGHT:
            check_x, check_y = px + interact_range, py
        else:
            check_x, check_y = px, py + interact_range

        check_rect = pygame.Rect(
            int(check_x), int(check_y), TILE_SIZE, TILE_SIZE
        )

        best = None
        best_dist = float('inf')

        for entity in entities:
            if entity is player:
                continue
            if entity.get_rect().colliderect(check_rect):
                ex, ey = entity.get_position()
                dist = ((ex - px) ** 2 + (ey - py) ** 2) ** 0.5
                if dist < best_dist:
                    best = entity
                    best_dist = dist

        return best
