import pygame

from settings import Settings
from src.enums.sound_effect import SoundEffect
from src.game_helper import GameHelper
from src.sound_manager import SoundManager
from src.sprites.item_to_collect import ItemToCollect


class CheckPoint(ItemToCollect):
    def __init__(self, image, position, groups, game_manager):
        super().__init__(groups, game_manager)

        # Sound
        self.sound_manager = SoundManager()

        # Sprite
        self.image = pygame.transform.scale(image, (Settings.TILE_SIZE, Settings.TILE_SIZE))
        self.rect = self.image.get_rect(topleft=position)
        self.hit_box = self.rect.inflate(GameHelper.multiply_by_tile_size_ratio(-20),
                                         GameHelper.multiply_by_tile_size_ratio(-20))

    def collect(self):
        self.sound_manager.play_sfx(SoundEffect.COLLECT_CHECKPOINT)
        self.game_manager.collect_check_point(self.rect.topleft)
        super().kill()
