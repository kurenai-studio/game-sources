import pygame

from src.panels.input_message import InputMessage
from src.panels.message import Message


class MessageBox:
    _FONT_PATH = 'font/silkscreen/silkscreen-regular.ttf'

    def __init__(self, screen: pygame.Surface, width: int, height: int, top_margin: int, background_color: pygame.Color,
                 border_color: pygame.Color, messages: list[Message]):
        self.screen = screen
        self.width = width
        self.height = height
        self.top_margin = top_margin
        self.background_color = background_color
        self.border_color = border_color
        self.messages = messages

        # Rectangle position - centered
        self.rect_position = (self.screen.get_rect().width // 2 - width // 2,
                              self.screen.get_rect().height // 2 - height // 2)

        # Text position - centered
        self.text_position = (self.screen.get_rect().width // 2,
                              self.screen.get_rect().height // 2 - height // 2 + top_margin)

        self.text_layers = list()
        self.convert_messages_to_text_layers()

    def convert_messages_to_text_layers(self):
        y_offset = 0
        for message in self.messages:
            if isinstance(message, InputMessage):
                basic_font = pygame.font.Font(self._FONT_PATH, message.size)
                text_layer = basic_font.render(message.text + '_', True, message.color, self.background_color)
                input_rectangle = pygame.rect.Rect(self.text_position[0] - message.input_width // 2,
                                                   self.text_position[1] + y_offset + message.input_top_and_bottom_margin,
                                                   message.input_width, message.input_height)
                self.text_layers.append((text_layer,
                                         message.input_width // 2 - message.input_left_padding,
                                         y_offset + message.input_top_and_bottom_margin + message.input_top_padding,
                                         input_rectangle))
                y_offset += message.input_top_and_bottom_margin * 2 + message.input_height
            elif isinstance(message, Message):
                basic_font = pygame.font.Font(self._FONT_PATH, message.size)
                text_layer = basic_font.render(message.text, True, message.color, self.background_color)
                self.text_layers.append((text_layer,
                                         text_layer.get_size()[0] // 2,
                                         y_offset,
                                         None))
                y_offset += text_layer.get_size()[1]

    def draw(self):
        rectangle = pygame.rect.Rect(self.rect_position[0], self.rect_position[1], self.width, self.height)
        border = rectangle.inflate(-8, -8)

        pygame.draw.rect(self.screen, self.background_color, rectangle)
        pygame.draw.rect(self.screen, self.border_color, border, 4)

        for text_layer, x_offset, y_offset, input_rectangle in self.text_layers:
            self.screen.blit(text_layer, (self.text_position[0] - x_offset, self.text_position[1] + y_offset))
            if input_rectangle is not None:
                pygame.draw.rect(self.screen, self.border_color, input_rectangle, 4)
