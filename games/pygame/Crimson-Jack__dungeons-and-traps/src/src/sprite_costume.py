import pygame


class SpriteCostume:
    """An animation image and the number of game frames it is shown for."""

    def __init__(self, image: pygame.Surface, number_of_frames: int):
        """
        Create a costume.

        :param image: image shown by the sprite
        :param number_of_frames: number of game frames the image is shown before the next costume
        """
        self._image = image
        self._number_of_frames = number_of_frames

    @classmethod
    def create_list(cls, images: list[pygame.Surface], number_of_frames: int) -> list['SpriteCostume']:
        """
        Create a costume for each image, all shown for the same number of frames.

        :param images: images of the animation in order
        :param number_of_frames: number of game frames each image is shown
        :return: costumes in the order of the images
        """
        sprite_costumes = []
        for image in images:
            sprite_costumes.append(cls(image, number_of_frames))
        return sprite_costumes

    @property
    def image(self) -> pygame.Surface:
        """Image shown by the sprite."""
        return self._image

    @property
    def number_of_frames(self) -> int:
        """Number of game frames the image is shown before the next costume."""
        return self._number_of_frames
