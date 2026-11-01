import pygame
import pytest

from src import level_catalog
from src.enums.game_status import GameStatus
from src.enums.weapon_type import WeaponType
from src.events import Events
from src.keyboard_controller import KeyboardController
from src.panels.dialog_factory import DialogFactory
from src.panels.first_page import FirstPage
from src.panels.loading_page import LoadingPage
from src.panels.menu_box import MenuBox
from src.panels.message_box import MessageBox
from src.panels.studio_page import StudioPage
from tests.conftest import GameUnderTest, KeyboardControllerUnderTest


# --- Keyboard: menu screens (STUDIO_PAGE, LOADING_PAGE, FIRST_PAGE,CREDITS, SECRET_CODE, SECRET_CODE_IS_VALID) ---

FIRST_PAGE_MENU_NEW_GAME = 0
FIRST_PAGE_MENU_SECRET_CODE = 1
FIRST_PAGE_MENU_CREDITS = 2
FIRST_PAGE_MENU_QUIT = 3
SECRET_CODE_LEVEL_INDEX = 1


def key_down_event(key: int, unicode: str = '') -> pygame.event.Event:
    return pygame.event.Event(pygame.KEYDOWN, key=key, unicode=unicode)


def message_texts(messages: list) -> list[str]:
    return [message.text for message in messages]


def enter_studio_page(game: GameUnderTest) -> None:
    game.screen_manager.dispose_first_page()
    game.screen_manager.show_studio_page()


def enter_loading_page(game: GameUnderTest) -> None:
    game.screen_manager.dispose_first_page()
    game.screen_manager.show_loading_page()


def enter_credits(game: GameUnderTest) -> None:
    game.screen_manager.dispose_first_page()
    game.game_manager.set_credits()
    game.screen_manager.load_credits_message_dialog()


def enter_secret_code(game: GameUnderTest, secret_code_text: str = '') -> None:
    game.screen_manager.dispose_first_page()
    game.game_manager.set_secret_code()
    game.keyboard_controller.secret_code_text = secret_code_text
    game.screen_manager.load_secret_code_message_dialog(game.keyboard_controller.secret_code_text)


def enter_secret_code_is_valid(game: GameUnderTest) -> None:
    game.screen_manager.dispose_first_page()
    game.game_manager.clear_settings_for_first_level(SECRET_CODE_LEVEL_INDEX)
    game.game_manager.set_secret_code_is_valid()
    game.keyboard_controller.secret_code_text = level_catalog.LEVELS[SECRET_CODE_LEVEL_INDEX].secret_code
    game.screen_manager.load_secret_code_message_dialog(game.keyboard_controller.secret_code_text,
                                                        DialogFactory.create_secret_code_valid_messages())


class TestKeyboardHandlers:
    def test_every_status_except_unknown_has_keyboard_handler(self, game):
        assert set(game.keyboard_controller.keyboard_handlers) == set(GameStatus) - {GameStatus.UNKNOWN}

    @pytest.mark.refactoring
    def test_unknown_status_ignores_keys(self, game):
        game.game_manager._game_status = GameStatus.UNKNOWN
        first_page = game.screen_manager.first_page
        menu_dialog = game.screen_manager.menu_dialog

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_ESCAPE))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.UNKNOWN
        assert game.screen_manager.first_page is first_page
        assert game.screen_manager.menu_dialog is menu_dialog
        assert game.screen_manager.message_dialog is None


class TestAppendSecretCodeCharacter:
    @pytest.mark.parametrize('secret_code_text, character, expected_secret_code_text', [
        ('c', '1', 'c1'),
        ('', 'a', 'a'),
        ('a' * (KeyboardController.SECRET_CODE_MAX_LENGTH - 1), 'b',
         'a' * (KeyboardController.SECRET_CODE_MAX_LENGTH - 1) + 'b'),
        ('a' * KeyboardController.SECRET_CODE_MAX_LENGTH, 'b', 'a' * KeyboardController.SECRET_CODE_MAX_LENGTH),
        ('c', ' ', 'c'),
        ('c', '!', 'c'),
        ('c', 'ą', 'c'),
        ('c', '', 'c'),
    ], ids=['digit', 'first_letter', 'last_allowed_character', 'beyond_max_length', 'space', 'punctuation',
            'non_ascii_letter', 'key_without_character'])
    def test_append_secret_code_character(self, secret_code_text, character, expected_secret_code_text):
        assert KeyboardControllerUnderTest.append_secret_code_character(secret_code_text, character) == \
            expected_secret_code_text


class TestKeyboardStudioPage:
    @pytest.mark.parametrize('key', [pygame.K_SPACE, pygame.K_ESCAPE, pygame.K_a])
    def test_any_key_opens_loading_page(self, game, key):
        enter_studio_page(game)
        assert isinstance(game.screen_manager.studio_page, StudioPage)

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(key))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.LOADING_PAGE
        assert game.screen_manager.studio_page is None
        assert isinstance(game.screen_manager.loading_page, LoadingPage)
        assert game.screen_manager.first_page is None


class TestKeyboardLoadingPage:
    @pytest.mark.parametrize('key', [pygame.K_SPACE, pygame.K_ESCAPE, pygame.K_a])
    def test_any_key_opens_first_page(self, game, key):
        enter_loading_page(game)
        assert isinstance(game.screen_manager.loading_page, LoadingPage)

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(key))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.FIRST_PAGE
        assert game.screen_manager.loading_page is None
        assert isinstance(game.screen_manager.first_page, FirstPage)
        assert isinstance(game.screen_manager.menu_dialog, MenuBox)


class TestKeyboardFirstPage:
    def test_escape_quits_game(self, game):
        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_ESCAPE))

        assert is_running is False
        assert game.game_manager.game_status == GameStatus.FIRST_PAGE

    @pytest.mark.parametrize('key, start_index, expected_index', [
        (pygame.K_DOWN, FIRST_PAGE_MENU_NEW_GAME, FIRST_PAGE_MENU_SECRET_CODE),
        (pygame.K_s, FIRST_PAGE_MENU_NEW_GAME, FIRST_PAGE_MENU_SECRET_CODE),
        (pygame.K_UP, FIRST_PAGE_MENU_SECRET_CODE, FIRST_PAGE_MENU_NEW_GAME),
        (pygame.K_w, FIRST_PAGE_MENU_SECRET_CODE, FIRST_PAGE_MENU_NEW_GAME),
        (pygame.K_DOWN, FIRST_PAGE_MENU_QUIT, FIRST_PAGE_MENU_NEW_GAME),
        (pygame.K_UP, FIRST_PAGE_MENU_NEW_GAME, FIRST_PAGE_MENU_QUIT),
    ], ids=['down', 's', 'up', 'w', 'down_wraps_to_top', 'up_wraps_to_bottom'])
    def test_arrows_move_menu_selection(self, game, key, start_index, expected_index):
        game.screen_manager.menu_dialog.selected_index = start_index

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(key))

        assert is_running is True
        assert game.screen_manager.menu_dialog.get_selected_index() == expected_index
        assert game.game_manager.game_status == GameStatus.FIRST_PAGE

    @pytest.mark.parametrize('key', [pygame.K_RETURN, pygame.K_SPACE])
    def test_new_game_opens_next_level_dialog(self, game, key):
        game.screen_manager.menu_dialog.selected_index = FIRST_PAGE_MENU_NEW_GAME

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(key))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.NEXT_LEVEL
        assert game.screen_manager.first_page is None
        assert game.screen_manager.menu_dialog is None
        assert isinstance(game.screen_manager.message_dialog, MessageBox)
        assert message_texts(game.screen_manager.message_dialog.messages)[0] == 'LEVEL 1'

    def test_secret_code_opens_secret_code_dialog(self, game):
        game.screen_manager.menu_dialog.selected_index = FIRST_PAGE_MENU_SECRET_CODE

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_RETURN))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.SECRET_CODE
        assert game.screen_manager.first_page is None
        assert game.screen_manager.menu_dialog is None
        assert isinstance(game.screen_manager.message_dialog, MessageBox)
        assert message_texts(game.screen_manager.message_dialog.messages)[0] == 'SECRET CODE'

    def test_credits_opens_credits_dialog(self, game):
        game.screen_manager.menu_dialog.selected_index = FIRST_PAGE_MENU_CREDITS

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_RETURN))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.CREDITS
        assert game.screen_manager.first_page is None
        assert game.screen_manager.menu_dialog is None
        assert isinstance(game.screen_manager.message_dialog, MessageBox)

    def test_quit_quits_game(self, game):
        game.screen_manager.menu_dialog.selected_index = FIRST_PAGE_MENU_QUIT

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_RETURN))

        assert is_running is False
        assert game.game_manager.game_status == GameStatus.FIRST_PAGE

    def test_selected_menu_item_is_remembered_after_returning_to_first_page(self, game):
        game.screen_manager.menu_dialog.selected_index = FIRST_PAGE_MENU_CREDITS
        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_RETURN))

        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_ESCAPE))

        assert game.game_manager.game_status == GameStatus.FIRST_PAGE
        assert game.screen_manager.menu_dialog.get_selected_index() == FIRST_PAGE_MENU_CREDITS


class TestKeyboardCredits:
    def test_escape_returns_to_first_page_and_disposes_dialog(self, game):
        enter_credits(game)

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_ESCAPE))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.FIRST_PAGE
        assert game.screen_manager.message_dialog is None
        assert isinstance(game.screen_manager.first_page, FirstPage)
        assert isinstance(game.screen_manager.menu_dialog, MenuBox)

    @pytest.mark.parametrize('key', [pygame.K_RETURN, pygame.K_SPACE, pygame.K_a])
    def test_other_keys_keep_credits(self, game, key):
        enter_credits(game)
        credits_dialog = game.screen_manager.message_dialog

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(key))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.CREDITS
        assert game.screen_manager.message_dialog is credits_dialog


class TestKeyboardSecretCode:
    def test_typing_alphanumeric_character_appends_it_and_refreshes_dialog(self, game):
        enter_secret_code(game, 'c')
        previous_dialog = game.screen_manager.message_dialog

        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_1, '1'))

        assert game.keyboard_controller.secret_code_text == 'c1'
        assert game.screen_manager.message_dialog is not previous_dialog
        assert game.game_manager.game_status == GameStatus.SECRET_CODE

    def test_typing_beyond_max_length_is_ignored(self, game):
        full_secret_code_text = 'a' * KeyboardController.SECRET_CODE_MAX_LENGTH
        enter_secret_code(game, full_secret_code_text)

        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_b, 'b'))

        assert game.keyboard_controller.secret_code_text == full_secret_code_text

    @pytest.mark.parametrize('key, unicode', [
        (pygame.K_SPACE, ' '),
        (pygame.K_1, '!'),
        (pygame.K_a, 'ą'),
        (pygame.K_LSHIFT, ''),
    ], ids=['space', 'punctuation', 'non_ascii_letter', 'key_without_character'])
    def test_typing_disallowed_character_is_ignored(self, game, key, unicode):
        enter_secret_code(game, 'c')

        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(key, unicode))

        assert game.keyboard_controller.secret_code_text == 'c'
        assert game.game_manager.game_status == GameStatus.SECRET_CODE

    @pytest.mark.parametrize('secret_code_text, expected_secret_code_text', [
        ('c12', 'c1'),
        ('c', ''),
        ('', ''),
    ], ids=['several_characters', 'one_character', 'empty'])
    def test_backspace_removes_last_character(self, game, secret_code_text, expected_secret_code_text):
        enter_secret_code(game, secret_code_text)

        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_BACKSPACE))

        assert game.keyboard_controller.secret_code_text == expected_secret_code_text
        assert game.game_manager.game_status == GameStatus.SECRET_CODE

    def test_return_with_valid_code_prepares_selected_level(self, game):
        enter_secret_code(game, level_catalog.LEVELS[SECRET_CODE_LEVEL_INDEX].secret_code)
        previous_level = game.screen_manager.level

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_RETURN))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.SECRET_CODE_IS_VALID
        assert game.game_manager.level_index == SECRET_CODE_LEVEL_INDEX
        assert game.screen_manager.level is not previous_level
        valid_texts = message_texts(DialogFactory.create_secret_code_valid_messages())
        assert message_texts(game.screen_manager.message_dialog.messages)[-len(valid_texts):] == valid_texts

    def test_return_with_invalid_code_shows_error_and_keeps_level(self, game):
        enter_secret_code(game, 'wrongcode')
        previous_level = game.screen_manager.level

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_RETURN))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.SECRET_CODE
        assert game.game_manager.level_index == 0
        assert game.screen_manager.level is previous_level
        assert game.keyboard_controller.secret_code_text == 'wrongcode'
        invalid_texts = message_texts(DialogFactory.create_secret_code_invalid_messages())
        assert message_texts(game.screen_manager.message_dialog.messages)[-len(invalid_texts):] == invalid_texts

    def test_escape_returns_to_first_page_clears_text_and_disposes_dialog(self, game):
        enter_secret_code(game, 'c1')

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_ESCAPE))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.FIRST_PAGE
        assert game.keyboard_controller.secret_code_text == ''
        assert isinstance(game.screen_manager.first_page, FirstPage)
        assert isinstance(game.screen_manager.menu_dialog, MenuBox)
        assert game.screen_manager.message_dialog is None


class TestKeyboardSecretCodeIsValid:
    @pytest.mark.parametrize('key', [pygame.K_SPACE, pygame.K_RETURN, pygame.K_ESCAPE])
    def test_any_key_opens_next_level_dialog_and_clears_text(self, game, key):
        enter_secret_code_is_valid(game)
        secret_code_dialog = game.screen_manager.message_dialog

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(key))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.NEXT_LEVEL
        assert game.keyboard_controller.secret_code_text == ''
        assert isinstance(game.screen_manager.message_dialog, MessageBox)
        assert game.screen_manager.message_dialog is not secret_code_dialog
        assert message_texts(game.screen_manager.message_dialog.messages)[0] == \
            f'LEVEL {SECRET_CODE_LEVEL_INDEX + 1}'


# --- Keyboard: gameplay (GAME_IS_RUNNING, GAME_IS_PAUSED, key release) ---

PAUSE_MENU_RESUME = 0
PAUSE_MENU_RESTART_LEVEL = 1
PAUSE_MENU_QUIT_GAME = 2


def key_up_event(key: int) -> pygame.event.Event:
    return pygame.event.Event(pygame.KEYUP, key=key)


def enter_game_is_running(game: GameUnderTest) -> None:
    game.screen_manager.dispose_first_page()
    game.game_manager.set_game_is_running()


def enter_game_is_paused(game: GameUnderTest) -> None:
    enter_game_is_running(game)
    game.game_manager.switch_pause_state()
    game.screen_manager.load_game_paused_menu()


class TestKeyboardGameIsRunning:
    @pytest.mark.parametrize('key, expected_movement_vector', [
        (pygame.K_DOWN, (0, 1)),
        (pygame.K_s, (0, 1)),
        (pygame.K_UP, (0, -1)),
        (pygame.K_w, (0, -1)),
        (pygame.K_RIGHT, (1, 0)),
        (pygame.K_d, (1, 0)),
        (pygame.K_LEFT, (-1, 0)),
        (pygame.K_a, (-1, 0)),
    ], ids=['down', 's', 'up', 'w', 'right', 'd', 'left', 'a'])
    def test_movement_key_sets_movement_vector_and_is_tracked(self, game, key, expected_movement_vector):
        enter_game_is_running(game)

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(key))

        assert is_running is True
        assert game.game_manager.player_movement_vector == expected_movement_vector
        assert game.keyboard_controller.active_movement_keys == {key}

    def test_two_movement_keys_give_diagonal_movement(self, game):
        enter_game_is_running(game)

        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_DOWN))
        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_RIGHT))

        assert game.game_manager.player_movement_vector == (1, 1)
        assert game.keyboard_controller.active_movement_keys == {pygame.K_DOWN, pygame.K_RIGHT}

    @pytest.mark.parametrize('key', [pygame.K_LCTRL, pygame.K_LSHIFT])
    def test_weapon_key_starts_using_weapon(self, game, key):
        enter_game_is_running(game)

        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(key))

        assert game.game_manager.player_is_using_weapon is True

    @pytest.mark.refactoring
    @pytest.mark.parametrize('key, collected_weapons, start_weapon, expected_weapon', [
        (pygame.K_x, [WeaponType.NONE, WeaponType.SWORD, WeaponType.BOW], WeaponType.NONE, WeaponType.SWORD),
        (pygame.K_x, [WeaponType.NONE, WeaponType.BOW], WeaponType.NONE, WeaponType.BOW),
        (pygame.K_x, [WeaponType.NONE, WeaponType.SWORD], WeaponType.SWORD, WeaponType.NONE),
        (pygame.K_z, [WeaponType.NONE, WeaponType.SWORD, WeaponType.BOW], WeaponType.NONE, WeaponType.BOW),
        (pygame.K_x, [WeaponType.NONE], WeaponType.NONE, WeaponType.NONE),
    ], ids=['next', 'next_skips_not_collected', 'next_wraps_around', 'previous_wraps_and_skips',
            'nothing_collected'])
    def test_weapon_change_keys_switch_among_collected_weapons(self, game, key, collected_weapons, start_weapon,
                                                               expected_weapon):
        enter_game_is_running(game)
        game.game_manager._collected_weapons = collected_weapons
        game.game_manager._weapon_type = start_weapon

        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(key))

        assert game.game_manager.weapon_type == expected_weapon

    def test_escape_pauses_game_and_resets_movement(self, game):
        enter_game_is_running(game)
        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_DOWN))

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_ESCAPE))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.GAME_IS_PAUSED
        assert game.keyboard_controller.active_movement_keys == set()
        assert game.game_manager.player_movement_vector == (0, 0)
        assert isinstance(game.screen_manager.menu_dialog, MenuBox)
        assert game.screen_manager.menu_dialog.title.text == 'PAUSED'

    def test_other_key_changes_nothing(self, game):
        enter_game_is_running(game)

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_q))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.GAME_IS_RUNNING
        assert game.game_manager.player_movement_vector == (0, 0)
        assert game.keyboard_controller.active_movement_keys == set()


class TestKeyboardMovementKeyRelease:
    @pytest.mark.parametrize('key', [pygame.K_DOWN, pygame.K_s, pygame.K_UP, pygame.K_w,
                                     pygame.K_RIGHT, pygame.K_d, pygame.K_LEFT, pygame.K_a],
                             ids=['down', 's', 'up', 'w', 'right', 'd', 'left', 'a'])
    def test_releasing_tracked_key_reverts_its_movement(self, game, key):
        enter_game_is_running(game)
        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(key))

        game.keyboard_controller.handle_keyboard_buttons_up(key_up_event(key))

        assert game.game_manager.player_movement_vector == (0, 0)
        assert game.keyboard_controller.active_movement_keys == set()

    def test_releasing_one_of_two_keys_keeps_the_other_direction(self, game):
        enter_game_is_running(game)
        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_DOWN))
        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_RIGHT))

        game.keyboard_controller.handle_keyboard_buttons_up(key_up_event(pygame.K_DOWN))

        assert game.game_manager.player_movement_vector == (1, 0)
        assert game.keyboard_controller.active_movement_keys == {pygame.K_RIGHT}

    def test_releasing_untracked_key_changes_nothing(self, game):
        # The key was pressed in another state (e.g. pause menu), so GAME_IS_RUNNING never tracked it.
        enter_game_is_running(game)

        game.keyboard_controller.handle_keyboard_buttons_up(key_up_event(pygame.K_DOWN))

        assert game.game_manager.player_movement_vector == (0, 0)
        assert game.keyboard_controller.active_movement_keys == set()


class TestKeyboardGameIsPaused:
    @pytest.mark.parametrize('key, start_index, expected_index', [
        (pygame.K_DOWN, PAUSE_MENU_RESUME, PAUSE_MENU_RESTART_LEVEL),
        (pygame.K_s, PAUSE_MENU_RESUME, PAUSE_MENU_RESTART_LEVEL),
        (pygame.K_UP, PAUSE_MENU_RESTART_LEVEL, PAUSE_MENU_RESUME),
        (pygame.K_w, PAUSE_MENU_RESTART_LEVEL, PAUSE_MENU_RESUME),
        (pygame.K_UP, PAUSE_MENU_RESUME, PAUSE_MENU_QUIT_GAME),
    ], ids=['down', 's', 'up', 'w', 'up_wraps_to_bottom'])
    def test_arrows_move_menu_selection(self, game, key, start_index, expected_index):
        enter_game_is_paused(game)
        game.screen_manager.menu_dialog.selected_index = start_index

        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(key))

        assert game.screen_manager.menu_dialog.get_selected_index() == expected_index
        assert game.game_manager.game_status == GameStatus.GAME_IS_PAUSED

    @pytest.mark.parametrize('key, selected_index', [
        (pygame.K_ESCAPE, PAUSE_MENU_RESUME),
        (pygame.K_RETURN, PAUSE_MENU_RESUME),
        (pygame.K_SPACE, PAUSE_MENU_RESUME),
    ], ids=['escape', 'resume_with_return', 'resume_with_space'])
    def test_escape_or_resume_continues_game(self, game, key, selected_index):
        enter_game_is_paused(game)
        game.screen_manager.menu_dialog.selected_index = selected_index
        game.keyboard_controller.active_movement_keys.add(pygame.K_DOWN)
        game.game_manager.set_player_movement(0, 1)

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(key))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.GAME_IS_RUNNING
        assert game.screen_manager.menu_dialog is None
        assert game.keyboard_controller.active_movement_keys == set()
        assert game.game_manager.player_movement_vector == (0, 0)

    def test_restart_level_with_lives_left_takes_life_and_rebuilds_level(self, game):
        enter_game_is_paused(game)
        game.screen_manager.menu_dialog.selected_index = PAUSE_MENU_RESTART_LEVEL
        game.game_manager.set_player_is_using_weapon(True)
        lives_before = game.game_manager.lives
        previous_level = game.screen_manager.level

        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_RETURN))

        assert game.game_manager.lives == lives_before - 1
        assert game.game_manager.game_status == GameStatus.NEXT_LEVEL
        assert game.screen_manager.level is not previous_level
        assert game.game_manager.player_is_using_weapon is False
        assert game.screen_manager.menu_dialog is None
        assert message_texts(game.screen_manager.message_dialog.messages)[0] == 'LEVEL 1'

    @pytest.mark.refactoring
    def test_restart_level_with_last_life_posts_game_over_summary(self, game):
        enter_game_is_paused(game)
        game.screen_manager.menu_dialog.selected_index = PAUSE_MENU_RESTART_LEVEL
        game.game_manager._lives = 1
        previous_level = game.screen_manager.level
        pygame.event.clear()

        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_RETURN))

        assert game.game_manager.lives == 0
        # Current behavior: the status goes back to GAME_IS_RUNNING and GAME_OVER_SUMMARY_EVENT sets GAME_OVER later.
        assert game.game_manager.game_status == GameStatus.GAME_IS_RUNNING
        assert len(pygame.event.get(eventtype=Events.GAME_OVER_SUMMARY_EVENT)) == 1
        assert game.screen_manager.level is previous_level
        assert game.screen_manager.menu_dialog is None

    @pytest.mark.refactoring
    def test_quit_game_resets_progress_and_returns_to_first_page(self, game):
        enter_game_is_paused(game)
        game.screen_manager.menu_dialog.selected_index = PAUSE_MENU_QUIT_GAME
        game.game_manager._score = 500
        game.game_manager._lives = 1
        previous_level = game.screen_manager.level

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_RETURN))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.FIRST_PAGE
        assert game.game_manager.score == 0
        assert game.game_manager.lives == 2
        assert game.game_manager.level_index == 0
        assert game.screen_manager.level is not previous_level
        assert isinstance(game.screen_manager.first_page, FirstPage)
        assert isinstance(game.screen_manager.menu_dialog, MenuBox)
        assert game.screen_manager.menu_dialog.title is None


# --- Keyboard: end of level and game (NEXT_LEVEL, LEVEL_COMPLETED, GAME_OVER, YOU_WIN, SUMMARY) ---

def enter_next_level(game: GameUnderTest) -> None:
    game.screen_manager.dispose_first_page()
    game.screen_manager.show_next_level_dialog()


def enter_level_completed(game: GameUnderTest) -> None:
    game.screen_manager.dispose_first_page()
    game.game_manager.set_level_completed()
    game.screen_manager.load_level_completed_message_dialog()


def enter_game_over(game: GameUnderTest) -> None:
    game.screen_manager.dispose_first_page()
    game.game_manager.set_game_over()
    game.screen_manager.load_game_over_message_dialog()


def enter_you_win(game: GameUnderTest) -> None:
    game.screen_manager.dispose_first_page()
    game.game_manager.set_you_win()
    game.screen_manager.load_you_win_message_dialog()


def enter_summary(game: GameUnderTest) -> None:
    game.screen_manager.dispose_first_page()
    game.screen_manager.load_summary_panel(player_won=False)


class TestKeyboardNextLevel:
    @pytest.mark.parametrize('key', [pygame.K_SPACE, pygame.K_RETURN])
    def test_space_or_return_starts_game(self, game, key):
        enter_next_level(game)

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(key))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.GAME_IS_RUNNING
        assert game.screen_manager.message_dialog is None

    @pytest.mark.parametrize('key', [pygame.K_ESCAPE, pygame.K_a])
    def test_other_keys_keep_next_level_dialog(self, game, key):
        enter_next_level(game)
        next_level_dialog = game.screen_manager.message_dialog

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(key))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.NEXT_LEVEL
        assert game.screen_manager.message_dialog is next_level_dialog


class TestKeyboardLevelCompleted:
    @pytest.mark.refactoring
    @pytest.mark.parametrize('key', [pygame.K_SPACE, pygame.K_RETURN])
    def test_space_or_return_prepares_next_level(self, game, key):
        enter_level_completed(game)
        game.game_manager.set_player_is_using_weapon(True)
        level_index_before = game.game_manager.level_index
        level_stats_count_before = len(game.game_manager._level_stats)
        previous_level = game.screen_manager.level

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(key))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.NEXT_LEVEL
        assert game.game_manager.level_index == level_index_before + 1
        assert len(game.game_manager._level_stats) == level_stats_count_before + 1
        assert game.screen_manager.level is not previous_level
        assert game.game_manager.player_is_using_weapon is False
        assert message_texts(game.screen_manager.message_dialog.messages)[0] == f'LEVEL {level_index_before + 2}'

    @pytest.mark.parametrize('key', [pygame.K_ESCAPE, pygame.K_a])
    def test_other_keys_keep_level_completed_dialog(self, game, key):
        enter_level_completed(game)
        level_completed_dialog = game.screen_manager.message_dialog

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(key))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.LEVEL_COMPLETED
        assert game.screen_manager.message_dialog is level_completed_dialog


class TestKeyboardGameOverAndYouWin:
    @pytest.mark.parametrize('enter_status, expected_player_won', [
        (enter_game_over, False),
        (enter_you_win, True),
    ], ids=['game_over', 'you_win'])
    @pytest.mark.parametrize('key', [pygame.K_SPACE, pygame.K_RETURN], ids=['space', 'return'])
    def test_space_or_return_opens_summary(self, game, enter_status, expected_player_won, key):
        enter_status(game)

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(key))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.SUMMARY
        assert game.screen_manager.message_dialog is None
        assert game.screen_manager.summary_panel.current_page_index == 0
        assert game.screen_manager.summary_panel.pages[0].player_won is expected_player_won

    @pytest.mark.parametrize('enter_status, expected_status', [
        (enter_game_over, GameStatus.GAME_OVER),
        (enter_you_win, GameStatus.YOU_WIN),
    ], ids=['game_over', 'you_win'])
    def test_other_key_keeps_dialog(self, game, enter_status, expected_status):
        enter_status(game)
        dialog = game.screen_manager.message_dialog

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_ESCAPE))

        assert is_running is True
        assert game.game_manager.game_status == expected_status
        assert game.screen_manager.message_dialog is dialog
        assert game.screen_manager.summary_panel is None


class TestKeyboardSummary:
    @pytest.mark.parametrize('key', [pygame.K_SPACE, pygame.K_RETURN, pygame.K_RIGHT])
    def test_next_page_keys_go_to_next_page(self, game, key):
        enter_summary(game)

        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(key))

        assert game.screen_manager.summary_panel.current_page_index == 1
        assert game.game_manager.game_status == GameStatus.SUMMARY

    def test_next_page_after_last_page_wraps_to_first(self, game):
        enter_summary(game)
        summary_panel = game.screen_manager.summary_panel
        summary_panel.current_page_index = len(summary_panel.pages) - 1

        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_RIGHT))

        assert game.screen_manager.summary_panel.current_page_index == 0

    def test_left_goes_to_previous_page(self, game):
        enter_summary(game)
        game.screen_manager.summary_panel.current_page_index = 1

        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_LEFT))

        assert game.screen_manager.summary_panel.current_page_index == 0

    def test_left_on_first_page_wraps_to_last(self, game):
        enter_summary(game)

        game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_LEFT))

        summary_panel = game.screen_manager.summary_panel
        assert summary_panel.current_page_index == len(summary_panel.pages) - 1

    @pytest.mark.refactoring
    def test_escape_resets_game_and_returns_to_first_page(self, game):
        enter_summary(game)
        game.game_manager._score = 500
        game.game_manager._lives = 0
        previous_level = game.screen_manager.level

        is_running = game.keyboard_controller.handle_keyboard_buttons_down(key_down_event(pygame.K_ESCAPE))

        assert is_running is True
        assert game.game_manager.game_status == GameStatus.FIRST_PAGE
        assert game.screen_manager.summary_panel is None
        assert game.game_manager.score == 0
        assert game.game_manager.lives == 2
        assert game.game_manager.level_index == 0
        assert game.screen_manager.level is not previous_level
        assert isinstance(game.screen_manager.first_page, FirstPage)
        assert isinstance(game.screen_manager.menu_dialog, MenuBox)
