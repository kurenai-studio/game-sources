import pygame

from settings import Settings
from src.enums.enemy_type import EnemyType
from src.panels.panel_page import PanelPage
from src.sprite_helper import SpriteHelper


class SummaryEnemiesPage(PanelPage):
    ENEMY_DISPLAY_NAMES = {
        EnemyType.SPIDER_SMALL:       'Creeplin',
        EnemyType.SPIDER_MEDIUM:      'Lurker',
        EnemyType.SPIDER_BIG:         'Webmaster',
        EnemyType.MONSTER_BLUE:       'Bluemantle',
        EnemyType.MONSTER_GREEN:      'Thornback',
        EnemyType.MONSTER_RED:        'Bloodclaw',
        EnemyType.MONSTER_BLUE_DEAF:  'Wandering bluemantle',
        EnemyType.MONSTER_GREEN_DEAF: 'Wandering thornback',
        EnemyType.MONSTER_RED_DEAF:   'Wandering bloodclaw',
        EnemyType.BAT:                'Duskwing',
    }

    ICON_SIZE = (32, 32)
    ROW_HEIGHT = 52
    MAX_ROWS_PER_PAGE = 6
    FONT_PATH = 'font/silkscreen/silkscreen-regular.ttf'

    def __init__(self, rows: list):
        self.rows = rows
        self.icons = {
            enemy_type: SpriteHelper.get_enemy_icon(enemy_type, self.ICON_SIZE)
            for enemy_type, _ in self.rows
        }
        self.font_header = pygame.font.Font(self.FONT_PATH, 20)
        self.font_row    = pygame.font.Font(self.FONT_PATH, 16)

    @classmethod
    def create_pages(cls, aggregate_kill_stats: dict) -> list:
        all_rows = [
            (enemy_type, record)
            for enemy_type, record in aggregate_kill_stats.items()
            if record.count > 0
        ]
        pages = []
        for offset in range(0, max(len(all_rows), 1), cls.MAX_ROWS_PER_PAGE):
            pages.append(cls(all_rows[offset:offset + cls.MAX_ROWS_PER_PAGE]))
        return pages

    @property
    def title(self) -> str:
        return 'ENEMIES'

    def get_content_height(self) -> int:
        return self.font_header.get_height() + 6 + 10 + len(self.rows) * self.ROW_HEIGHT

    def draw_content(self, screen: pygame.Surface, content_rect: pygame.Rect) -> None:
        x_icon   = content_rect.x + 24
        x_name   = content_rect.x + 68
        x_killed = content_rect.right - 240
        x_score  = content_rect.right - 90

        y = content_rect.y
        self._blit_centered(screen, self.font_header, 'KILLED', Settings.TEXT_COLOR, x_killed, y)
        self._blit_centered(screen, self.font_header, 'SCORE',  Settings.TEXT_COLOR, x_score,  y)
        y += self.font_header.get_height() + 6 + 10

        for enemy_type, record in self.rows:
            row_center_y = y + self.ROW_HEIGHT // 2

            icon = self.icons.get(enemy_type)
            if icon:
                screen.blit(icon, (x_icon, row_center_y - self.ICON_SIZE[1] // 2))

            name_surface = self.font_row.render(self.ENEMY_DISPLAY_NAMES[enemy_type], True, Settings.TEXT_COLOR)
            screen.blit(name_surface, (x_name, row_center_y - name_surface.get_height() // 2))

            self._blit_centered(screen, self.font_row, f'{record.killed} / {record.count}',
                                Settings.HIGHLIGHTED_TEXT_COLOR, x_killed,
                                row_center_y - self.font_row.get_height() // 2)
            self._blit_centered(screen, self.font_row, f'{record.score} pts',
                                Settings.HIGHLIGHTED_TEXT_COLOR, x_score,
                                row_center_y - self.font_row.get_height() // 2)
            y += self.ROW_HEIGHT

    def _blit_centered(self, screen: pygame.Surface, font: pygame.font.Font,
                       text: str, color, center_x: int, y: int) -> None:
        text_surface = font.render(text, True, color)
        screen.blit(text_surface, (center_x - text_surface.get_width() // 2, y))
