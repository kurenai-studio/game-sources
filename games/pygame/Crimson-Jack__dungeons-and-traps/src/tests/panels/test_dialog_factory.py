import pygame
import pytest

from settings import Settings
from src.enums.enemy_type import EnemyType
from src.level_stats import LevelStats
from src.panels.dialog_factory import DialogFactory
from src.panels.input_message import InputMessage
from src.panels.menu_box import MenuBox
from src.panels.message import Message
from src.panels.message_box import MessageBox


# MessageBox renders its fonts in the constructor, so Pygame must be initialised around every test.
@pytest.fixture(autouse=True)
def pygame_init():
    pygame.init()
    yield
    pygame.quit()


@pytest.fixture
def screen():
    return pygame.Surface((Settings.WIDTH, Settings.HEIGHT))


EXTRA_BONUS_TEXT = f'EXTRA BONUS +{Settings.LEVEL_COMPLETION_BONUS} pts'


def message_values(messages: list[Message]) -> list[tuple]:
    return [(message.text, message.color, message.size) for message in messages]


def create_level_stats(spawned_enemies: dict[EnemyType, int], killed_enemies: dict[EnemyType, int]) -> LevelStats:
    level_stats = LevelStats()
    for enemy_type, number_of_enemies in spawned_enemies.items():
        for _ in range(number_of_enemies):
            level_stats.record_enemy_spawn(enemy_type)
    for enemy_type, number_of_kills in killed_enemies.items():
        for _ in range(number_of_kills):
            level_stats.record_enemy_kill(enemy_type, 100)
    return level_stats


class TestCreateFirstPageMenu:
    def test_builds_borderless_menu_without_title(self, screen):
        menu = DialogFactory.create_first_page_menu(screen)

        assert isinstance(menu, MenuBox)
        assert (menu.width, menu.height) == (500, 0)
        assert menu.title is None
        assert menu.show_border is False
        assert message_values(menu.items) == [
            ('New Game', Settings.TEXT_COLOR, 35),
            ('Secret Code', Settings.TEXT_COLOR, 25),
            ('Credits', Settings.TEXT_COLOR, 25),
            ('Quit', Settings.TEXT_COLOR, 25),
        ]


class TestCreateGamePausedMenu:
    def test_builds_bordered_menu_with_paused_title(self, screen):
        menu = DialogFactory.create_game_paused_menu(screen)

        assert isinstance(menu, MenuBox)
        assert (menu.width, menu.height) == (740, 200)
        assert message_values([menu.title]) == [('PAUSED', Settings.HIGHLIGHTED_TEXT_COLOR, 40)]
        assert menu.show_border is True
        assert message_values(menu.items) == [
            ('Resume', Settings.TEXT_COLOR, 20),
            ('Restart level', Settings.TEXT_COLOR, 20),
            ('Quit game', Settings.TEXT_COLOR, 20),
        ]


class TestCreateLevelCompletedDialog:
    def test_without_kills_shows_no_enemy_section(self, screen):
        level_stats = create_level_stats({EnemyType.BAT: 2}, {})

        dialog = DialogFactory.create_level_completed_dialog(screen, level_stats)

        assert isinstance(dialog, MessageBox)
        assert (dialog.width, dialog.height, dialog.top_margin) == (740, 196, 20)
        assert message_values(dialog.messages) == [
            ('CONGRATULATIONS', Settings.HIGHLIGHTED_TEXT_COLOR, 40),
            ('Level completed', Settings.TEXT_COLOR, 20),
            ('', Settings.TEXT_COLOR, 15),
            ('', Settings.TEXT_COLOR, 15),
            ('Press the SPACE button to go to the next level', Settings.TEXT_COLOR, 20),
        ]

    def test_with_level_without_enemies_shows_no_bonus(self, screen):
        dialog = DialogFactory.create_level_completed_dialog(screen, LevelStats())

        assert dialog.height == 196
        assert EXTRA_BONUS_TEXT not in [message.text for message in dialog.messages]

    def test_with_one_enemy_group_killed_partially_shows_single_line(self, screen):
        level_stats = create_level_stats({EnemyType.SPIDER_SMALL: 3}, {EnemyType.SPIDER_SMALL: 2})

        dialog = DialogFactory.create_level_completed_dialog(screen, level_stats)

        assert dialog.height == 196 + 2 * 20
        assert message_values(dialog.messages)[3:5] == [
            ('Defeated enemies:', Settings.TEXT_COLOR, 16),
            ('Spiders: 2 / 3 (200 pts)', Settings.TEXT_COLOR, 16),
        ]
        assert EXTRA_BONUS_TEXT not in [message.text for message in dialog.messages]

    def test_with_two_enemy_groups_killed_skips_group_without_kills(self, screen):
        spawned_enemies = {EnemyType.SPIDER_SMALL: 2, EnemyType.MONSTER_RED: 1, EnemyType.BAT: 3}
        killed_enemies = {EnemyType.SPIDER_SMALL: 1, EnemyType.BAT: 3}
        level_stats = create_level_stats(spawned_enemies, killed_enemies)

        dialog = DialogFactory.create_level_completed_dialog(screen, level_stats)

        assert dialog.height == 196 + 3 * 20
        assert message_values(dialog.messages)[3:6] == [
            ('Defeated enemies:', Settings.TEXT_COLOR, 16),
            ('Spiders: 1 / 2 (100 pts)', Settings.TEXT_COLOR, 16),
            ('Bats: 3 / 3 (300 pts)', Settings.TEXT_COLOR, 16),
        ]
        assert EXTRA_BONUS_TEXT not in [message.text for message in dialog.messages]

    def test_with_all_enemy_groups_defeated_shows_every_line_and_bonus(self, screen):
        spawned_enemies = {EnemyType.SPIDER_BIG: 1, EnemyType.MONSTER_RED: 2, EnemyType.BAT: 1}
        level_stats = create_level_stats(spawned_enemies, spawned_enemies)

        dialog = DialogFactory.create_level_completed_dialog(screen, level_stats)

        assert dialog.height == 196 + 4 * 20 + 20
        assert message_values(dialog.messages) == [
            ('CONGRATULATIONS', Settings.HIGHLIGHTED_TEXT_COLOR, 40),
            ('Level completed', Settings.TEXT_COLOR, 20),
            ('', Settings.TEXT_COLOR, 15),
            ('Defeated enemies:', Settings.TEXT_COLOR, 16),
            ('Spiders: 1 / 1 (100 pts)', Settings.TEXT_COLOR, 16),
            ('Goblins: 2 / 2 (200 pts)', Settings.TEXT_COLOR, 16),
            ('Bats: 1 / 1 (100 pts)', Settings.TEXT_COLOR, 16),
            (EXTRA_BONUS_TEXT, Settings.HIGHLIGHTED_TEXT_COLOR, 20),
            ('', Settings.TEXT_COLOR, 15),
            ('Press the SPACE button to go to the next level', Settings.TEXT_COLOR, 20),
        ]


class TestCreateNextLevelDialog:
    @pytest.mark.parametrize('level_name, level_description, expected_top_margin', [
        ('Name', 'Description.', 40),
        (None, 'Description.', 80),
        ('Name', None, 76),
        (None, None, 116),
    ])
    def test_top_margin_depends_on_name_and_description(self, screen, level_name, level_description,
                                                        expected_top_margin):
        dialog = DialogFactory.create_next_level_dialog(screen, 1, level_name, level_description, None)

        assert (dialog.width, dialog.height, dialog.top_margin) == (Settings.WIDTH, Settings.HEIGHT,
                                                                    expected_top_margin)

    def test_with_name_description_and_secret_code_shows_every_section(self, screen):
        dialog = DialogFactory.create_next_level_dialog(screen, 3, 'The Crypt', 'Find the key. Beware of bats!',
                                                        'ABC123')

        assert message_values(dialog.messages) == [
            ('LEVEL 3', Settings.HIGHLIGHTED_TEXT_COLOR, 80),
            ('', Settings.TEXT_COLOR, 20),
            ('The Crypt', Settings.HIGHLIGHTED_TEXT_COLOR, 20),
            ('', Settings.TEXT_COLOR, 20),
            ('Find the key.', Settings.TEXT_COLOR, 16),
            ('Beware of bats!', Settings.TEXT_COLOR, 16),
            ('', Settings.TEXT_COLOR, 80),
            ('The secret code for this level is', Settings.TEXT_COLOR, 16),
            ('ABC123', Settings.HIGHLIGHTED_TEXT_COLOR, 20),
            ('', Settings.TEXT_COLOR, 80),
            ('Press the SPACE button to start', Settings.TEXT_COLOR, 20),
        ]

    @pytest.mark.parametrize('secret_code', [None, ''])
    def test_without_secret_code_hides_secret_code_section(self, screen, secret_code):
        dialog = DialogFactory.create_next_level_dialog(screen, 1, None, None, secret_code)

        assert message_values(dialog.messages) == [
            ('LEVEL 1', Settings.HIGHLIGHTED_TEXT_COLOR, 80),
            ('', Settings.TEXT_COLOR, 80),
            ('Press the SPACE button to start', Settings.TEXT_COLOR, 20),
        ]


class TestCreateGameOverDialog:
    def test_builds_game_over_message(self, screen):
        dialog = DialogFactory.create_game_over_dialog(screen)

        assert (dialog.width, dialog.height, dialog.top_margin) == (740, 130, 20)
        assert message_values(dialog.messages) == [
            ('GAME OVER', Settings.HIGHLIGHTED_TEXT_COLOR, 40),
            ('Press the SPACE button to open summary page', Settings.TEXT_COLOR, 20),
        ]


class TestCreateYouWinDialog:
    def test_builds_you_win_message(self, screen):
        dialog = DialogFactory.create_you_win_dialog(screen)

        assert (dialog.width, dialog.height, dialog.top_margin) == (740, 130, 20)
        assert message_values(dialog.messages) == [
            ('YOU WIN', Settings.HIGHLIGHTED_TEXT_COLOR, 40),
            ('Press the SPACE button to open summary page', Settings.TEXT_COLOR, 20),
        ]


class TestCreateSecretCodeDialog:
    def test_without_response_messages_shows_cancel_hint(self, screen):
        dialog = DialogFactory.create_secret_code_dialog(screen, 'ABC')

        assert (dialog.width, dialog.height, dialog.top_margin) == (740, 270, 20)
        assert isinstance(dialog.messages[2], InputMessage)
        assert message_values(dialog.messages) == [
            ('SECRET CODE', Settings.HIGHLIGHTED_TEXT_COLOR, 40),
            ('to jump to a specific level', Settings.TEXT_COLOR, 16),
            ('ABC', Settings.TEXT_COLOR, 40),
            ('', Settings.TEXT_COLOR, 20),
            ('Press ESC to cancel', Settings.TEXT_COLOR, 20),
        ]

    def test_with_response_messages_replaces_cancel_hint(self, screen):
        response_messages = DialogFactory.create_secret_code_invalid_messages()

        dialog = DialogFactory.create_secret_code_dialog(screen, 'XYZ', response_messages)

        assert dialog.messages[3:] == response_messages


class TestCreateSecretCodeResponseMessages:
    def test_valid_messages(self):
        assert message_values(DialogFactory.create_secret_code_valid_messages()) == [
            ('The code is valid!', Settings.HIGHLIGHTED_TEXT_COLOR, 20),
            ('Press any button to start the game', Settings.TEXT_COLOR, 20),
        ]

    def test_invalid_messages(self):
        assert message_values(DialogFactory.create_secret_code_invalid_messages()) == [
            ('', Settings.TEXT_COLOR, 20),
            ('The code is not valid - please try again!', Settings.TEXT_COLOR, 20),
        ]


class TestCreateCreditsDialog:
    def test_builds_credits_box(self, screen):
        dialog = DialogFactory.create_credits_dialog(screen)

        assert (dialog.width, dialog.height, dialog.top_margin) == (740, 560, 20)
        assert len(dialog.messages) == 25
        assert message_values(dialog.messages[:1]) == [('CREDITS', Settings.HIGHLIGHTED_TEXT_COLOR, 40)]
        assert message_values(dialog.messages[-1:]) == [('Press ESC to return', Settings.TEXT_COLOR, 20)]
