import pygame

from settings import Settings
from src.bonus_record import BonusRecord
from src.collectable_record import CollectableRecord
from src.panels.panel_page import PanelPage


class SummaryCollectablesPage(PanelPage):
    ROW_HEIGHT = 52
    FONT_PATH = 'font/silkscreen/silkscreen-regular.ttf'

    def __init__(self, diamond_record: CollectableRecord, key_record: CollectableRecord,
                 bonus_record: BonusRecord):
        self.diamond_record = diamond_record
        self.key_record = key_record
        self.bonus_record = bonus_record

        self.font_header = pygame.font.Font(self.FONT_PATH, 20)
        self.font_row    = pygame.font.Font(self.FONT_PATH, 16)

    @property
    def title(self) -> str:
        return 'COLLECTABLES'

    def get_content_height(self) -> int:
        row_count = 3
        return self.font_header.get_height() + 6 + 10 + row_count * self.ROW_HEIGHT

    def draw_content(self, screen: pygame.Surface, content_rect: pygame.Rect) -> None:
        x_name      = content_rect.x + 24
        x_collected = content_rect.right - 240
        x_score     = content_rect.right - 90

        y = content_rect.y
        self._blit_centered(screen, self.font_header, 'COLLECTED', Settings.TEXT_COLOR, x_collected, y)
        self._blit_centered(screen, self.font_header, 'SCORE',     Settings.TEXT_COLOR, x_score,     y)
        y += self.font_header.get_height() + 6 + 10

        rows = [
            ('Diamonds', self.diamond_record.collected, self.diamond_record.count, self.diamond_record.score),
            ('Keys',     self.key_record.collected,     self.key_record.count,     self.key_record.score),
            ('Bonus',    self.bonus_record.awarded,     None,                      self.bonus_record.score),
        ]

        for label, collected, total, score in rows:
            row_center_y = y + self.ROW_HEIGHT // 2

            name_surface = self.font_row.render(label, True, Settings.TEXT_COLOR)
            screen.blit(name_surface, (x_name, row_center_y - name_surface.get_height() // 2))

            collected_text = f'{collected} / {total}' if total is not None else str(collected)
            self._blit_centered(screen, self.font_row, collected_text,
                                Settings.HIGHLIGHTED_TEXT_COLOR, x_collected,
                                row_center_y - self.font_row.get_height() // 2)
            self._blit_centered(screen, self.font_row, f'{score} pts',
                                Settings.HIGHLIGHTED_TEXT_COLOR, x_score,
                                row_center_y - self.font_row.get_height() // 2)
            y += self.ROW_HEIGHT

    def _blit_centered(self, screen: pygame.Surface, font: pygame.font.Font,
                       text: str, color, center_x: int, y: int) -> None:
        text_surface = font.render(text, True, color)
        screen.blit(text_surface, (center_x - text_surface.get_width() // 2, y))
