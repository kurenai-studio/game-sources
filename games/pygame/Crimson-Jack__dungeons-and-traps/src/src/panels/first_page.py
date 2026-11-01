import pygame

from src.spritesheet import SpriteSheet


class FirstPage:
    def __init__(self, screen):
        self.screen = screen

        # Original size: 1 point == 1px
        width = 320
        height = 192
        # The final image size is 960px x 576px
        scale_factor = 3
        final_image_size = scale_factor * width, scale_factor * height

        # Get image in the right size
        self.background_image = SpriteSheet(
            pygame.image.load('img/start-page.png').convert_alpha(),
            width,
            height,
            final_image_size,
            None
        ).get_image(0, 0)

        # Calculate image position
        self.image_position = [0, 0]
        if final_image_size[0] < self.screen.get_width():
            self.image_position[0] = (self.screen.get_width() - final_image_size[0]) // 2
        else:
            self.image_position[0] = - (final_image_size[0] - self.screen.get_width()) // 2

        if final_image_size[1] < self.screen.get_height():
            self.image_position[1] = (self.screen.get_height() - final_image_size[1]) // 2
        else:
            self.image_position[1] = - (final_image_size[1] - self.screen.get_height()) // 2

    def draw(self):
        self.screen.blit(self.background_image, self.image_position)
