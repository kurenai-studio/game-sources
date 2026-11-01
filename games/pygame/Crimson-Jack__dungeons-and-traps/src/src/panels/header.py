import pygame

from settings import Settings
from src.enums.weapon_type import WeaponType
from src.sprite_helper import SpriteHelper


class Header:
    _FONT_PATH = 'font/silkscreen/silkscreen-regular.ttf'
    _BASIC_FONT_SIZE = 24
    _WEAPON_DETAILS_FONT_SIZE = 12

    def __init__(self, screen, header_surface, game_manager):
        self.screen = screen
        self.header_surface = header_surface
        self.game_manager = game_manager

        # Sword and bow images
        self.sword_images = SpriteHelper.get_sword_images_to_header_view()
        self.sword_image = self.sword_images[0]
        self.bow_image = SpriteHelper.get_bow_image_to_header_view()
        self.explosion_image = SpriteHelper.get_explosion_image_to_header_view()

        # Fonts
        self.text_color = Settings.TEXT_COLOR
        self.highlighted_text_color = Settings.HIGHLIGHTED_TEXT_COLOR
        self.basic_font = pygame.font.Font(self._FONT_PATH, self._BASIC_FONT_SIZE)
        self.additional_info_font = pygame.font.Font(self._FONT_PATH, self._BASIC_FONT_SIZE)
        self.weapon_details_font = pygame.font.Font(self._FONT_PATH, self._WEAPON_DETAILS_FONT_SIZE)
        self.text_adjustment = 2
        self.margin = 16

        # Background and border
        self.border = self.header_surface.get_rect()
        self.border = self.border.inflate(-8, -8)
        self.header_surface.fill(Settings.SURFACE_COLOR)
        pygame.draw.rect(self.header_surface, Settings.BACKGROUND_COLOR, self.border)
        pygame.draw.rect(self.header_surface, Settings.BORDER_COLOR, self.border, 4)
        self.inner_background_color = Settings.BACKGROUND_COLOR

        # Surfaces
        self.left_surface = pygame.Surface(
            (self.header_surface.get_width() // 3 - self.margin, Settings.HEADER_HEIGHT - self.margin))
        self.center_surface = pygame.Surface(
            (self.header_surface.get_width() // 3 - self.margin, Settings.HEADER_HEIGHT - self.margin))
        self.right_surface = pygame.Surface(
            (self.header_surface.get_width() // 3 - self.margin, Settings.HEADER_HEIGHT - self.margin))

    def clean(self):
        self.left_surface.fill(self.inner_background_color)
        self.center_surface.fill(self.inner_background_color)
        self.right_surface.fill(self.inner_background_color)

    def draw(self):
        self.draw_left_decorations()
        self.draw_right_decorations()

        self.draw_level(self.left_surface)
        self.draw_weapon(self.center_surface)
        self.draw_score(self.right_surface)

        # Blit each surface to the dashboard
        self.header_surface.blit(self.left_surface, (self.margin // 2, self.margin // 2))
        self.header_surface.blit(self.center_surface, (self.header_surface.get_width() // 3 + self.margin // 2, self.margin // 2))
        self.header_surface.blit(self.right_surface, (self.header_surface.get_width() * 2 // 3 + self.margin // 2, self.margin // 2))

        # Blit dashboard to the main screen
        self.screen.blit(self.header_surface, (0, 0))

    def draw_left_decorations(self):
        left_rect = self.left_surface.get_rect()

        decoration = pygame.rect.Rect(left_rect.left + 4, left_rect.top + 4, 4, 4)
        pygame.draw.rect(self.left_surface, Settings.BORDER_COLOR, decoration)
        decoration = pygame.rect.Rect(left_rect.left + 12, left_rect.top + 4, 4, 4)
        pygame.draw.rect(self.left_surface, Settings.BORDER_COLOR, decoration)
        decoration = pygame.rect.Rect(left_rect.left + 4, left_rect.top + 12, 4, 4)
        pygame.draw.rect(self.left_surface, Settings.BORDER_COLOR, decoration)

        decoration = pygame.rect.Rect(left_rect.left + 4, left_rect.bottom - 8, 4, 4)
        pygame.draw.rect(self.left_surface, Settings.BORDER_COLOR, decoration)
        decoration = pygame.rect.Rect(left_rect.left + 12, left_rect.bottom - 8, 4, 4)
        pygame.draw.rect(self.left_surface, Settings.BORDER_COLOR, decoration)
        decoration = pygame.rect.Rect(left_rect.left + 4, left_rect.bottom - 16, 4, 4)
        pygame.draw.rect(self.left_surface, Settings.BORDER_COLOR, decoration)

    def draw_right_decorations(self):
        right_rect = self.right_surface.get_rect()

        decoration = pygame.rect.Rect(right_rect.right - 8, right_rect.top + 4, 4, 4)
        pygame.draw.rect(self.right_surface, Settings.BORDER_COLOR, decoration)
        decoration = pygame.rect.Rect(right_rect.right - 16, right_rect.top + 4, 4, 4)
        pygame.draw.rect(self.right_surface, Settings.BORDER_COLOR, decoration)
        decoration = pygame.rect.Rect(right_rect.right - 8, right_rect.top + 12, 4, 4)
        pygame.draw.rect(self.right_surface, Settings.BORDER_COLOR, decoration)

        decoration = pygame.rect.Rect(right_rect.right - 8, right_rect.bottom - 8, 4, 4)
        pygame.draw.rect(self.right_surface, Settings.BORDER_COLOR, decoration)
        decoration = pygame.rect.Rect(right_rect.right - 16, right_rect.bottom - 8, 4, 4)
        pygame.draw.rect(self.right_surface, Settings.BORDER_COLOR, decoration)
        decoration = pygame.rect.Rect(right_rect.right - 8, right_rect.bottom - 16, 4, 4)
        pygame.draw.rect(self.right_surface, Settings.BORDER_COLOR, decoration)

    def draw_level(self, surface):
        level_text = self.basic_font.render('Level ', True, self.text_color)
        surface.blit(level_text, (self.margin * 2, surface.get_height() // 2 - level_text.get_rect().height // 2 - self.text_adjustment))
        level_number = self.basic_font.render(f'{self.game_manager.level_index + 1}', True, self.highlighted_text_color)
        surface.blit(level_number, (self.margin * 2 + level_text.get_rect().width, surface.get_height() // 2 - level_text.get_rect().height // 2 - self.text_adjustment))

    def draw_weapon(self, surface):
        if self.game_manager.weapon_type == WeaponType.NONE:
            weapon_text = self.basic_font.render(f'Weapon -', True, self.text_color)
            surface.blit(weapon_text, (self.margin * 2, surface.get_height() // 2 - weapon_text.get_rect().height // 2 - self.text_adjustment))
        elif self.game_manager.weapon_type == WeaponType.SWORD:
            self.set_sword_image()
            weapon_text = self.basic_font.render(f'Weapon', True, self.text_color)
            surface.blit(weapon_text, (self.margin * 2, surface.get_height() // 2 - weapon_text.get_rect().height // 2 - self.text_adjustment))
            surface.blit(self.sword_image, (self.margin * 2 + weapon_text.get_width(), surface.get_height() // 2 - self.sword_image.get_rect().height // 2))
        elif self.game_manager.weapon_type == WeaponType.BOW:
            weapon_text = self.basic_font.render(f'Weapon', True, self.text_color)
            surface.blit(weapon_text, (self.margin * 2, surface.get_height() // 2 - weapon_text.get_rect().height // 2 - self.text_adjustment))
            surface.blit(self.bow_image, (self.margin * 2 + weapon_text.get_width(), surface.get_height() // 2 - self.bow_image.get_rect().height // 2))
            number_of_arrows_text = self.additional_info_font.render(f'({self.game_manager.number_of_arrows})', True,
                                                                     self.highlighted_text_color)
            surface.blit(number_of_arrows_text, (self.margin * 2 + weapon_text.get_width() + self.bow_image.get_rect().width, surface.get_height() // 2 - number_of_arrows_text.get_rect().height // 2 - self.text_adjustment))
        elif self.game_manager.weapon_type == WeaponType.EXPLOSION:
            weapon_text = self.basic_font.render(f'Weapon', True, self.text_color)
            surface.blit(weapon_text, (self.margin * 2, surface.get_height() // 2 - weapon_text.get_rect().height // 2 - self.text_adjustment))
            surface.blit(self.explosion_image, (self.margin * 2 + weapon_text.get_width(), surface.get_height() // 2 - self.bow_image.get_rect().height // 2))
            number_of_explosions_text = self.additional_info_font.render(f'({self.game_manager.number_of_explosions})', True,
                                                                     self.highlighted_text_color)
            surface.blit(number_of_explosions_text, (self.margin * 2 + weapon_text.get_width() + self.bow_image.get_rect().width, surface.get_height() // 2 - number_of_explosions_text.get_rect().height // 2 - self.text_adjustment))

        if len(self.game_manager.collected_weapons) > 1:
            change_weapon_text = self.weapon_details_font.render(
                f'Press Z or X to change weapon', True, self.text_color)
            surface.blit(change_weapon_text, (
                self.margin * 2,
                surface.get_height() // 2 + change_weapon_text.get_rect().height - self.text_adjustment))

    def draw_score(self, surface):
        score_text = self.basic_font.render('Score ', True, self.text_color)
        surface.blit(score_text, (self.margin * 2, surface.get_height() // 2 - score_text.get_rect().height // 2 - self.text_adjustment))
        score_number = self.basic_font.render(f'{self.game_manager.score}', True, self.highlighted_text_color)
        surface.blit(score_number, (self.margin * 2 + score_text.get_rect().width, surface.get_height() // 2 - score_text.get_rect().height // 2 - self.text_adjustment))

    def set_sword_image(self):
        number_of_used_sword_thresholds = self.game_manager.number_of_used_sword_thresholds
        if 0 <= number_of_used_sword_thresholds < len(self.sword_images):
            self.sword_image = self.sword_images[number_of_used_sword_thresholds]
        else:
            self.sword_image = self.sword_images[-1]
