import pygame

from src.sprites.custom_draw_sprite import CustomDrawSprite


class CameraGroup(pygame.sprite.Group):
    """Sprite group drawn on the game surface with the offset of the camera; only sprites in view are drawn."""

    def __init__(self, game_surface: pygame.Surface) -> None:
        """
        Prepare the group drawn on the game surface.

        :param game_surface: surface the sprites are drawn on
        """
        super().__init__()
        self._game_surface = game_surface
        self._game_surface_width, self._game_surface_height = self._game_surface.get_size()

    def custom_draw(self, offset: pygame.math.Vector2) -> None:
        """
        Draw the visible sprites on the game surface.

        :param offset: offset that moves map coordinates to game surface coordinates in the current frame
        """
        # Draw each visible tile with an offset on game_surface
        for sprite in self._get_visible_sprites(offset):
            if isinstance(sprite, CustomDrawSprite):
                sprite.custom_draw(self._game_surface, offset)
            else:
                sprite_image = sprite.image
                sprite_rect = sprite.rect
                if sprite_image is not None and sprite_rect is not None:
                    offset_position = sprite_rect.topleft + offset
                    self._game_surface.blit(sprite_image, offset_position)

    def _get_visible_sprites(self, offset: pygame.math.Vector2) -> list[pygame.sprite.Sprite]:
        # The map area currently shown on game_surface
        visible_rect = pygame.rect.Rect(-offset.x, -offset.y, self._game_surface_width, self._game_surface_height)

        # Keep only sprites whose drawn area overlaps the visible map area
        visible_sprites = []
        for sprite in self.sprites():
            culling_rect = self._get_sprite_culling_rect(sprite)
            if culling_rect is not None and visible_rect.colliderect(culling_rect):
                visible_sprites.append(sprite)

        return visible_sprites

    @staticmethod
    def _get_sprite_culling_rect(sprite: pygame.sprite.Sprite) -> pygame.Rect | pygame.FRect | None:
        # Area of the map the sprite draws on; larger than the sprite for custom drawn sprites
        if isinstance(sprite, CustomDrawSprite):
            return sprite.get_culling_rect()
        return sprite.rect
