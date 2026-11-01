import pygame


class Tombstone(pygame.sprite.Sprite):
    def __init__(self, sprites: list[pygame.Surface], position, groups, last_slide_counter=10):
        super().__init__(*groups)

        # Sprite animation variables
        self.sprites = sprites
        self.number_of_sprites = len(self.sprites) - 1
        self.number_of_frames = 4
        self.costume_step_counter = 0
        self.costume_step_counter_increment = 1
        self.costume_index = 0

        # Image
        self.image = self.sprites[0]
        self.rect = self.image.get_rect(topleft=position)
        self.hit_box = self.rect

        self.last_slide_counter = last_slide_counter

    def update(self):
        # Increase costume step counter
        self.costume_step_counter += self.costume_step_counter_increment
        self.change_costume()

    def change_costume(self):
        # Change costume only if threshold exceeded
        if self.costume_step_counter > self.number_of_frames:
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
