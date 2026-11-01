import pygame

from settings import Settings
from src.bar import Bar
from src.color_set import ColorSet
from src.game_helper import GameHelper
from src.sprites.diamond import Diamond
from src.sprites.key import Key
from src.sprite_helper import SpriteHelper
from src.tile_details.diamond_tile_details import DiamondTileDetails
from src.tile_details.key_and_door_tile_details import KeyAndDoorTileDetails


class Dashboard:
    _FONT_PATH = 'font/silkscreen/silkscreen-regular.ttf'
    _BASIC_FONT_SIZE = 24

    def __init__(self, screen, dashboard_surface, game_manager):
        self.screen = screen
        self.dashboard_surface = dashboard_surface
        self.game_manager = game_manager

        # Life image
        self.life_image = SpriteHelper.get_life_sprite()

        # Fonts
        self.text_color = Settings.TEXT_COLOR
        self.basic_font = pygame.font.Font(self._FONT_PATH, self._BASIC_FONT_SIZE)
        self.text_adjustment = 2
        self.margin = 16

        # Background and border
        self.border = self.dashboard_surface.get_rect()
        self.border = self.border.inflate(-8, -8)
        self.dashboard_surface.fill(Settings.SURFACE_COLOR)
        pygame.draw.rect(self.dashboard_surface, Settings.BACKGROUND_COLOR, self.border)
        pygame.draw.rect(self.dashboard_surface, Settings.BORDER_COLOR, self.border, 4)
        self.inner_background_color = Settings.BACKGROUND_COLOR

        # Surfaces
        self.left_top_surface = pygame.Surface(
            (self.dashboard_surface.get_width() // 2 - self.margin, Settings.DASHBOARD_HEIGHT // 2 - self.margin // 2))
        self.right_top_surface = pygame.Surface(
            (self.dashboard_surface.get_width() // 2 - self.margin, Settings.DASHBOARD_HEIGHT // 2 - self.margin // 2))
        self.left_bottom_surface = pygame.Surface(
            (self.dashboard_surface.get_width() // 2 - self.margin, Settings.DASHBOARD_HEIGHT // 2 - self.margin // 2))
        self.right_bottom_surface = pygame.Surface(
            (self.dashboard_surface.get_width() // 2 - self.margin, Settings.DASHBOARD_HEIGHT // 2 - self.margin // 2))

        # Energy bars
        self.energy_bar_margin = 20
        bar_width = self.right_top_surface.get_width() - 2 * self.energy_bar_margin
        bar_half_width = self.right_top_surface.get_width() // 2 - 2 * self.energy_bar_margin
        bar_height = 25
        bar_left = self.energy_bar_margin
        bar_top = self.right_top_surface.get_height() // 2 - (bar_height // 2)
        bar_colors = ColorSet([
                ((0, 20), (255, 60, 0)),        # Red
                ((21, 40), (255, 158, 87)),     # Dark orange
                ((41, 60), (243, 244, 180)),    # Rotten green
                ((61, 80), (189, 244, 180)),    # Light green
                ((81, 100), (122, 231, 104))    # Dark green
            ])

        self.player_energy_bar = Bar(
            position=(bar_left, bar_top),
            width=bar_width,
            height=bar_height,
            bar_colors=bar_colors,
            outline_color=Settings.BORDER_COLOR,
            background_color=Settings.SURFACE_COLOR,
            text='Energy',
            text_color=Settings.BAR_TEXT_COLOR)

        self.player_small_energy_bar = Bar(
            position=(bar_left, bar_top),
            width=bar_half_width,
            height=bar_height,
            bar_colors=bar_colors,
            outline_color=Settings.BORDER_COLOR,
            background_color=Settings.SURFACE_COLOR,
            text='You',
            text_color=Settings.BAR_TEXT_COLOR)

        self.boss_small_energy_bar = Bar(
            position=(bar_left + bar_half_width + 10, bar_top),
            width=bar_half_width,
            height=bar_height,
            bar_colors=bar_colors,
            outline_color=Settings.BORDER_COLOR,
            background_color=Settings.SURFACE_COLOR,
            text='Boss',
            text_color=Settings.BAR_TEXT_COLOR)

    def clean(self):
        self.left_top_surface.fill(self.inner_background_color)
        self.right_top_surface.fill(self.inner_background_color)
        self.left_bottom_surface.fill(self.inner_background_color)
        self.right_bottom_surface.fill(self.inner_background_color)

    def draw(self):
        self.draw_energy_bar(self.left_top_surface)
        self.draw_keys(self.right_top_surface)
        self.draw_lives(self.left_bottom_surface)
        self.draw_diamonds(self.right_bottom_surface)

        # Blit each surface to the dashboard
        self.dashboard_surface.blit(self.left_top_surface, (self.margin // 2, self.margin // 2))
        self.dashboard_surface.blit(self.right_top_surface, (self.dashboard_surface.get_width() // 2 + self.margin // 2, self.margin // 2))
        self.dashboard_surface.blit(self.left_bottom_surface, (self.margin // 2, Settings.DASHBOARD_HEIGHT // 2))
        self.dashboard_surface.blit(self.right_bottom_surface, (self.dashboard_surface.get_width() // 2 + self.margin // 2, Settings.DASHBOARD_HEIGHT // 2))

        # Blit dashboard to the main screen
        self.screen.blit(self.dashboard_surface, (0, self.screen.get_height() - Settings.DASHBOARD_HEIGHT))

    def draw_lives(self, surface):
        lives_counter_text = self.basic_font.render(f'Lives', True, self.text_color)
        surface.blit(lives_counter_text, (self.margin * 2, self.left_top_surface.get_height() // 2 - lives_counter_text.get_rect().height // 2 - self.text_adjustment))

        count = 0
        for item in range(self.game_manager.lives):
            surface.blit(self.life_image, (self.margin * 3 + lives_counter_text.get_width() + (count * GameHelper.BASE_TILE_SIZE), 0))
            count += 1

    def draw_energy_bar(self, surface):
        if not self.game_manager.is_boss_visible:
            self.player_energy_bar.draw(surface, self.game_manager.player_energy, self.game_manager.player_max_energy)
        else:
            self.player_small_energy_bar.draw(surface, self.game_manager.player_energy, self.game_manager.player_max_energy)
            self.boss_small_energy_bar.draw(surface, self.game_manager.boss_energy, self.game_manager.boss_max_energy)

    def draw_keys(self, surface):
        keys_text = self.basic_font.render(f'Keys', True, self.text_color)
        surface.blit(keys_text, (self.margin * 2, self.right_bottom_surface.get_height() // 2 - keys_text.get_rect().height // 2 - self.text_adjustment))

        count = 0
        for item in self.game_manager.keys:
            if item.alive():
                # Copy sprite for dashboard - semi transparent
                transparent_image = Key(item.base_size_image, item.rect.topleft, tuple(), item.game_manager, KeyAndDoorTileDetails.from_properties(item.key_name, item.score))
                transparent_image.base_size_image.set_alpha(100)
                surface.blit(transparent_image.base_size_image, (self.margin * 3 + keys_text.get_width() + (count * GameHelper.BASE_TILE_SIZE), 0))
            else:
                # Use original sprite
                surface.blit(item.base_size_image, (self.margin * 3 + keys_text.get_width() + (count * GameHelper.BASE_TILE_SIZE), 0))
            count += 1

    def draw_diamonds(self, surface):
        diamonds_text = self.basic_font.render(f'Gems', True, self.text_color, )
        surface.blit(diamonds_text, (self.margin * 2, self.right_bottom_surface.get_height() // 2 - diamonds_text.get_rect().height // 2 - self.text_adjustment))

        count = 0
        for item in self.game_manager.diamonds:
            if item.alive():
                # Copy sprite for dashboard - semi transparent
                transparent_image = Diamond(item.base_size_image, item.rect.topleft, tuple(), item.game_manager, DiamondTileDetails.from_properties(item.score))
                transparent_image.base_size_image.set_alpha(100)
                surface.blit(transparent_image.base_size_image, (self.margin * 3 + diamonds_text.get_width() + (count * GameHelper.BASE_TILE_SIZE), 0))
            else:
                # Use original sprite
                surface.blit(item.base_size_image, (self.margin * 3 + diamonds_text.get_width() + (count * GameHelper.BASE_TILE_SIZE), 0))
            count += 1
