import pygame

from src.panels.message import Message


class InputMessage(Message):
    def __init__(self, text: str, color: pygame.Color, size: int, input_width: int, input_height: int,
                 input_top_padding: int, input_left_padding: int, input_top_and_bottom_margin: int):
        super().__init__(text, color, size)

        self._input_width = input_width
        self._input_height = input_height
        self._input_top_padding = input_top_padding
        self._input_left_padding = input_left_padding
        self._input_top_and_bottom_margin = input_top_and_bottom_margin

    @property
    def input_width(self):
        return self._input_width

    @property
    def input_height(self):
        return self._input_height

    @property
    def input_top_padding(self):
        return self._input_top_padding

    @property
    def input_left_padding(self):
        return self._input_left_padding

    @property
    def input_top_and_bottom_margin(self):
        return self._input_top_and_bottom_margin
