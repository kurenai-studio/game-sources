import pygame

from src.panels.message import Message


class MenuBox:
    _FONT_PATH = 'font/silkscreen/silkscreen-regular.ttf'
    _TITLE_BOTTOM_GAP = 10

    def __init__(self, screen: pygame.Surface, width: int, height: int, top_margin: int,
                 background_color: pygame.Color, border_color: pygame.Color,
                 highlighted_color: pygame.Color,
                 title: Message | None, items: list[Message],
                 show_border: bool = True):
        self.screen = screen
        self.width = width
        self.height = height
        self.background_color = background_color
        self.border_color = border_color
        self.highlighted_color = highlighted_color
        self.title = title
        self.items = items
        self.show_border = show_border
        self.selected_index = 0

        self.rect_position = (screen.get_rect().width // 2 - width // 2,
                              screen.get_rect().height // 2 - height // 2)
        self.text_center_x = self.rect_position[0] + width // 2
        self.text_start_y = self.rect_position[1] + top_margin

    def select_next(self):
        self.selected_index = (self.selected_index + 1) % len(self.items)

    def select_previous(self):
        self.selected_index = (self.selected_index - 1) % len(self.items)

    def get_selected_index(self) -> int:
        return self.selected_index

    def draw(self):
        rectangle = pygame.rect.Rect(self.rect_position[0], self.rect_position[1], self.width, self.height)
        pygame.draw.rect(self.screen, self.background_color, rectangle)
        if self.show_border:
            pygame.draw.rect(self.screen, self.border_color, rectangle.inflate(-8, -8), 4)

        y_offset = 0
        if self.title is not None:
            title_font = pygame.font.Font(self._FONT_PATH, self.title.size)
            title_surface = title_font.render(self.title.text, True, self.title.color, self.background_color)
            self.screen.blit(title_surface, (self.text_center_x - title_surface.get_width() // 2, self.text_start_y))
            y_offset = title_surface.get_height() + self._TITLE_BOTTOM_GAP

        for index, message in enumerate(self.items):
            if index == self.selected_index:
                label = '> ' + message.text
                color = self.highlighted_color
            else:
                label = '  ' + message.text
                color = message.color
            item_font = pygame.font.Font(self._FONT_PATH, message.size)
            item_surface = item_font.render(label, True, color, self.background_color)
            self.screen.blit(item_surface, (self.text_center_x - item_surface.get_width() // 2,
                                            self.text_start_y + y_offset))
            y_offset += item_surface.get_height()
