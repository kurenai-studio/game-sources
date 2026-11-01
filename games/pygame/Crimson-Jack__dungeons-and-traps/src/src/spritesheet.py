import pygame


class SpriteSheet:
    def __init__(self, image: pygame.Surface, width: int, height: int, size: tuple[float, float], key_color):
        self._sheet = image
        self._width = width
        self._height = height
        self._size = size
        self._key_color = key_color

        # Calculate cells and rows count
        self._number_of_cells = self._sheet.get_width() // self._width
        self._number_of_rows = self._sheet.get_height() // self._height

    def get_image(self, row: int, cell: int) -> pygame.Surface:
        image = pygame.Surface((self._width, self._height)).convert_alpha()
        image.blit(self._sheet, (0, 0), ((cell * self._width), (row * self._height), self._width, self._height))
        image = pygame.transform.scale(image, self._size)
        image.set_colorkey(self._key_color)

        return image

    @property
    def number_of_cells(self) -> int:
        return self._number_of_cells

    @property
    def number_of_rows(self) -> int:
        return self._number_of_rows
