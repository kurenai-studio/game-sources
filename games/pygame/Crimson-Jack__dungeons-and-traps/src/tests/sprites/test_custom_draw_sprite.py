import pygame

from src.sprites.custom_draw_sprite import CustomDrawSprite


class TestGetCullingRect:
    def test_returns_sprite_rect(self):
        sprite = CustomDrawSprite([])
        sprite.rect = pygame.Rect(10, 20, 30, 40)
        assert sprite.get_culling_rect() == pygame.Rect(10, 20, 30, 40)
