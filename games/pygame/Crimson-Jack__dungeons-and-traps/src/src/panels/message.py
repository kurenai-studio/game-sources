import pygame


class Message:
    def __init__(self, text: str, color: pygame.Color, size: int):
        self._text = text
        self._color = color
        self._size = size

    @property
    def text(self):
        return self._text

    @property
    def color(self):
        return self._color

    @property
    def size(self):
        return self._size
