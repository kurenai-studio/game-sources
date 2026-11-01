import pygame

from src.sprite_helper import SpriteHelper


class VanishingPoint(pygame.sprite.Sprite):
    def __init__(self, position, groups):
        super().__init__(*groups)

        # Sprite animation variables
        self.sprites = SpriteHelper.get_all_vanishing_point_sprites()
        self.number_of_sprites = 7
        self.costume_switching_threshold = 2
        self.costume_step_counter = 0
        self.costume_step_counter_increment = 1
        self.costume_index = 0

        # Image
        self.image = self.sprites[0]
        self.rect = self.image.get_rect(topleft=position)
        self.hit_box = self.rect

        self.last_slide_counter = 0

    def update(self):
        # Increase costume step counter
        self.costume_step_counter += self.costume_step_counter_increment
        self.change_costume()

    def change_costume(self):
        # Change costume only if threshold exceeded
        if self.costume_step_counter > self.costume_switching_threshold:
            # Reset counter
            self.costume_step_counter = 0
            if self.costume_index < self.number_of_sprites:
                # Increase costume index
                self.costume_index += 1
                # Set new image
                self.image = self.sprites[self.costume_index]
            else:
                self.last_slide_counter -= 1

    def is_expired(self):
        return self.last_slide_counter < 0
