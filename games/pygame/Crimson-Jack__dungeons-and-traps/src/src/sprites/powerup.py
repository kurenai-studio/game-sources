import pygame

from settings import Settings
from src.game_helper import GameHelper
from src.sprites.item_to_collect import ItemToCollect


class Powerup(ItemToCollect):
    def __init__(self, image, position, groups, game_manager):
        super().__init__(groups, game_manager)

        # Sprite
        self.image = pygame.transform.scale(image, (Settings.TILE_SIZE, Settings.TILE_SIZE))
        self.rect = self.image.get_rect(topleft=position)
        self.hit_box = self.rect.inflate(GameHelper.multiply_by_tile_size_ratio(-25),
                                         GameHelper.multiply_by_tile_size_ratio(-25))

    def activate(self):
        pass

