import pygame

from src.camera_group import CameraGroup


class CameraGroupWithYSort(CameraGroup):
    """Camera group that draws sprites in the order of their y position, so lower sprites cover higher ones."""

    def _get_visible_sprites(self, offset: pygame.math.Vector2) -> list[pygame.sprite.Sprite]:
        # Visible sprites sorted by the y position of their centers for the depth effect
        return sorted(super()._get_visible_sprites(offset), key=self._get_sprite_center_y)

    @staticmethod
    def _get_sprite_center_y(sprite: pygame.sprite.Sprite) -> float:
        # Y position of the sprite center; every sorted sprite must have a rect
        sprite_rect = sprite.rect
        if sprite_rect is None:
            raise ValueError('Sprite without a rect cannot be sorted')
        return sprite_rect.centery
