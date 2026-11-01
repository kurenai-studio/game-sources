import pygame


class ItemToCollect(pygame.sprite.Sprite):
    def __init__(self, groups, game_manager):
        super().__init__(*groups)
        self.game_manager = game_manager

    def collect(self):
        pass
