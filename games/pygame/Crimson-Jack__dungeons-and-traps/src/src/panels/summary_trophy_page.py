import pygame

from settings import Settings
from src.panels.panel_page import PanelPage
from src.sprite_helper import SpriteHelper


class SummaryTrophyPage(PanelPage):
    FONT_PATH = 'font/silkscreen/silkscreen-regular.ttf'
    TROPHY_PLACEHOLDER_SIZE = (120, 120)

    def __init__(self, total_score: int, player_won: bool):
        self.total_score = total_score
        self.player_won = player_won
        self.font_score = pygame.font.Font(self.FONT_PATH, 56)
        self.font_label = pygame.font.Font(self.FONT_PATH, 20)
        if player_won:
            self.trophy_image = SpriteHelper.get_game_over_win_image(self.TROPHY_PLACEHOLDER_SIZE)
        else:
            self.trophy_image = SpriteHelper.get_game_over_lose_image(self.TROPHY_PLACEHOLDER_SIZE)

    @property
    def title(self) -> str:
        return 'SUMMARY'

    def get_content_height(self) -> int:
        return (
            self.TROPHY_PLACEHOLDER_SIZE[1]
            + 20
            + self.font_label.get_height() + 8
            + self.font_score.get_height()
        )

    def draw_content(self, screen: pygame.Surface, content_rect: pygame.Rect) -> None:
        # Trophy image
        trophy_rect = pygame.Rect(
            content_rect.centerx - self.TROPHY_PLACEHOLDER_SIZE[0] // 2,
            content_rect.y,
            self.TROPHY_PLACEHOLDER_SIZE[0],
            self.TROPHY_PLACEHOLDER_SIZE[1]
        )
        screen.blit(self.trophy_image, trophy_rect)

        # Score label
        label_y = trophy_rect.bottom + 20
        label_surface = self.font_label.render('TOTAL SCORE', True, Settings.TEXT_COLOR)
        screen.blit(label_surface, (content_rect.centerx - label_surface.get_width() // 2, label_y))

        # Score value
        score_surface = self.font_score.render(str(self.total_score), True, Settings.HIGHLIGHTED_TEXT_COLOR)
        score_y = label_y + self.font_label.get_height() + 8
        screen.blit(score_surface, (content_rect.centerx - score_surface.get_width() // 2, score_y))
