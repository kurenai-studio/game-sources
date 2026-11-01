import pygame


class CustomDrawSprite(pygame.sprite.Sprite):
    def __init__(self, groups):
        super().__init__(*groups)

    def custom_draw(self, game_surface, offset):
        pass

    def get_culling_rect(self):
        # Area covered by everything the sprite draws, used to skip drawing when off-screen
        return self.rect
