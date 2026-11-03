import pygame
from enum import Enum


class DotColor(Enum):
    EMPTY = 0
    BLACK = 1
    WHITE = 2


class Tile(pygame.sprite.Sprite):
    def __init__(self, map_pos, pos, size):
        super().__init__()
        self.map_pos = map_pos
        self.image = pygame.Surface((size, size))

        # Make sprite transparent
        self.image.set_colorkey('black')
        self.rect = self.image.get_rect(topleft=pos)

    def fill(self, dot_color):
        if dot_color != DotColor.EMPTY:
            blue = (10, 10, 70)
            size = self.image.get_width() // 2
            if dot_color == DotColor.BLACK:
                pygame.draw.circle(self.image, blue, (size, size), size)
            elif dot_color == DotColor.WHITE:
                pygame.draw.circle(self.image, blue, (size, size), size, size // 3)
