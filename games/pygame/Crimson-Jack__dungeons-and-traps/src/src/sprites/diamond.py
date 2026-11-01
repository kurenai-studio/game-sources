import pygame

from settings import Settings
from src.enums.sound_effect import SoundEffect
from src.game_helper import GameHelper
from src.sound_manager import SoundManager
from src.sprites.item_to_collect import ItemToCollect
from src.tile_details.diamond_tile_details import DiamondTileDetails


class Diamond(ItemToCollect):
    def __init__(self, image, position, groups, game_manager, details: DiamondTileDetails):
        super().__init__(groups, game_manager)

        # Sound
        self.sound_manager = SoundManager()

        # Sprite
        self.image = pygame.transform.scale(image, (Settings.TILE_SIZE, Settings.TILE_SIZE))
        self.base_size_image = pygame.transform.scale(image, (GameHelper.BASE_TILE_SIZE, GameHelper.BASE_TILE_SIZE))
        self.rect = self.image.get_rect(topleft=position)
        self.hit_box = self.rect.inflate(GameHelper.multiply_by_tile_size_ratio(-35),
                                         GameHelper.multiply_by_tile_size_ratio(-35))

        self.score = details.score

    def collect(self):
        self.sound_manager.play_sfx(SoundEffect.COLLECT_DIAMOND)
        self.game_manager.collect_diamond(self)
        super().kill()
