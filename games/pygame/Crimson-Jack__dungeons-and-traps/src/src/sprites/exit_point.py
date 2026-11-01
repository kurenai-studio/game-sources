import pygame

from settings import Settings
from src.enums.sound_effect import SoundEffect
from src.game_helper import GameHelper
from src.sound_manager import SoundManager
from src.sprites.custom_draw_sprite import CustomDrawSprite


class ExitPoint(CustomDrawSprite):
    def __init__(self, image, position, groups, visible):
        super().__init__(groups)

        # Sound
        self.sound_manager = SoundManager()

        # Sprite
        self.image = pygame.transform.scale(image, (Settings.TILE_SIZE, Settings.TILE_SIZE))
        self.rect = self.image.get_rect(topleft=position)
        self.hit_box = self.rect.inflate(GameHelper.multiply_by_tile_size_ratio(-30), GameHelper.multiply_by_tile_size_ratio(-30))
        self.visible = visible

    def custom_draw(self, game_surface, offset):
        # Draw sprite if visible
        if self.visible:
            offset_position = self.rect.topleft + offset
            game_surface.blit(self.image, offset_position)

    def show(self):
        self.sound_manager.play_sfx(SoundEffect.SHOW_EXIT_POINT)
        self.visible = True
