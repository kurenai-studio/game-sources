import pygame

from settings import Settings
from src.game_helper import GameHelper


class Wall(pygame.sprite.Sprite):
    def __init__(self, image, position, groups):
        super().__init__(*groups)
        self.image = pygame.transform.scale(image, (Settings.TILE_SIZE, Settings.TILE_SIZE))
        self.rect = self.image.get_rect(topleft=position)
        self.hit_box = self.rect.inflate(int(GameHelper.multiply_by_tile_size_ratio(0)),
                                         int(GameHelper.multiply_by_tile_size_ratio(-40)))
