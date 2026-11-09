import random

import pygame
from pygame.math import Vector2


class Fruit:
    def __init__(self, configs):
        self.x = 0
        self.y = 0
        self.pos = 0

        self.configs = configs
        self.image = configs.sprite("apple")
        self.randomize()

    def draw_fruit(self):
        fruit_rect = pygame.Rect(
            int(self.pos.x * self.configs.cell_size),
            int(self.pos.y * self.configs.cell_size),
            self.configs.cell_size,
            self.configs.cell_size,
        )
        self.configs.screen.blit(self.image, fruit_rect)

    def randomize(self, occupied=()):
        # Only pick cells not covered by the snake
        taken = {(int(block.x), int(block.y)) for block in occupied}
        free_cells = [
            (x, y)
            for x in range(self.configs.cell_number)
            for y in range(self.configs.cell_number)
            if (x, y) not in taken
        ]
        self.x, self.y = random.choice(free_cells)
        self.pos = Vector2(self.x, self.y)
