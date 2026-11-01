import pygame

from src.sprite_helper import SpriteHelper


class LoadingPage:
    # Source image is 320px x 192px, the final image size is 960px x 576px
    IMAGE_SIZE = 960, 576

    def __init__(self, screen: pygame.Surface) -> None:
        """
        Load the loading page image and center it on the screen.

        :param screen: main display surface
        """
        self.screen = screen
        self.background_image = SpriteHelper.get_loading_page_image(self.IMAGE_SIZE)
        self.image_position = (
            (self.screen.get_width() - self.IMAGE_SIZE[0]) // 2,
            (self.screen.get_height() - self.IMAGE_SIZE[1]) // 2,
        )

    def draw(self) -> None:
        """
        Draw the loading page image.
        """
        self.screen.blit(self.background_image, self.image_position)
