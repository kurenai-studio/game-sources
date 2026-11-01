import pygame

from settings import Settings
from src.panels.panel_page import PanelPage


class MultiPagePanel:
    PANEL_WIDTH = 740
    FONT_PATH = 'font/silkscreen/silkscreen-regular.ttf'

    def __init__(self, screen: pygame.Surface, pages: list[PanelPage]):
        self.screen = screen
        self.pages = pages
        self.current_page_index = 0

        self.font_title = pygame.font.Font(self.FONT_PATH, 40)
        self.font_footer = pygame.font.Font(self.FONT_PATH, 20)

        has_multiple_pages = len(self.pages) > 1
        footer_height = (
            (self.font_footer.get_height() + 6) * 2 if has_multiple_pages
            else self.font_footer.get_height()
        )

        max_content_height = max(page.get_content_height() for page in self.pages)

        panel_height = (
            20
            + self.font_title.get_height() + 16
            + 10
            + max_content_height
            + 16
            + footer_height
            + 32
        )

        center_x = screen.get_rect().centerx
        center_y = screen.get_rect().centery
        self.rect = pygame.Rect(
            center_x - self.PANEL_WIDTH // 2,
            center_y - panel_height // 2,
            self.PANEL_WIDTH,
            panel_height
        )

        content_top = self.rect.y + 20 + self.font_title.get_height() + 16 + 10
        content_bottom = self.rect.bottom - 20 - footer_height - 16
        self.content_rect = pygame.Rect(
            self.rect.x + 20,
            content_top,
            self.PANEL_WIDTH - 40,
            content_bottom - content_top
        )

    def next_page(self) -> None:
        self.current_page_index = (self.current_page_index + 1) % len(self.pages)

    def previous_page(self) -> None:
        self.current_page_index = (self.current_page_index - 1) % len(self.pages)

    def draw(self) -> None:
        pygame.draw.rect(self.screen, Settings.MESSAGE_BACKGROUND_COLOR, self.rect)
        pygame.draw.rect(self.screen, Settings.MESSAGE_BORDER_COLOR, self.rect.inflate(-8, -8), 4)

        current_page = self.pages[self.current_page_index]

        title_surface = self.font_title.render(current_page.title, True, Settings.HIGHLIGHTED_TEXT_COLOR)
        self.screen.blit(title_surface, (self.rect.centerx - title_surface.get_width() // 2, self.rect.y + 20))

        current_page.draw_content(self.screen, self.content_rect)

        footer_y = self.rect.bottom - 32 - self.font_footer.get_height()
        esc_surface = self.font_footer.render('Press ESC to close', True, Settings.TEXT_COLOR)
        self.screen.blit(esc_surface, (self.rect.centerx - esc_surface.get_width() // 2, footer_y))

        if len(self.pages) > 1:
            space_surface = self.font_footer.render('< previous                               next page >', True, Settings.TEXT_COLOR)
            space_y = footer_y - self.font_footer.get_height() - 6
            self.screen.blit(space_surface, (self.rect.centerx - space_surface.get_width() // 2, space_y))
