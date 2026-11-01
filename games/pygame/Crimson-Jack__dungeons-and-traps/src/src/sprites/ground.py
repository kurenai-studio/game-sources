import pygame

from settings import Settings


class Ground(pygame.sprite.Sprite):
    def __init__(self, image, position, groups):
        super().__init__(*groups)
        self.image = pygame.transform.scale(image, (Settings.TILE_SIZE, Settings.TILE_SIZE))
        self.rect = self.image.get_rect(topleft=position)
