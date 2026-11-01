from collections.abc import Callable

import pygame

from src.enums.game_status import GameStatus
from src.events import Events
from src.game_manager import GameManager
from src.panels.dialog_factory import DialogFactory
from src.screen_manager import ScreenManager


class KeyboardController:
    """Reacts to keyboard input according to the current game status."""

    SECRET_CODE_MAX_LENGTH = 16

    def __init__(self, game_manager: GameManager, screen_manager: ScreenManager) -> None:
        """
        Start with empty secret code text and no pressed movement keys,
        and build the table that maps each game status to its key down handler.

        :param game_manager: shared game state
        :param screen_manager: level, panels, pages and dialogs currently on screen
        """
        self._game_manager = game_manager
        self._screen_manager = screen_manager

        # Secret code input text
        self._secret_code_text = ''

        # Tracks movement keys pressed in GAME_IS_RUNNING so KEYUP events from other states are ignored
        self._active_movement_keys = set()

        # Game status -> keyboard (key down) handler
        self._keyboard_handlers = self._create_keyboard_handlers()

    def handle_keyboard_buttons_down(self, event: pygame.event.Event) -> bool:
        """
        Run the key down handler registered for the current game status.
        Statuses without a handler ignore the key.

        :param event: KEYDOWN event
        :return: False when the player chose to quit the game, True otherwise
        """
        handler = self._keyboard_handlers.get(self._game_manager.game_status)
        if handler is None:
            return True
        return handler(event)

    def handle_keyboard_buttons_up(self, event: pygame.event.Event) -> None:
        """
        Revert the movement of a released movement key, if it was pressed while the game was running.

        :param event: KEYUP event
        """
        if event.key in self._active_movement_keys:
            self._active_movement_keys.discard(event.key)
            if event.key in (pygame.K_DOWN, pygame.K_s):
                self._game_manager.set_player_movement(0, -1)
            if event.key in (pygame.K_UP, pygame.K_w):
                self._game_manager.set_player_movement(0, 1)
            if event.key in (pygame.K_RIGHT, pygame.K_d):
                self._game_manager.set_player_movement(-1, 0)
            if event.key in (pygame.K_LEFT, pygame.K_a):
                self._game_manager.set_player_movement(1, 0)

    def _create_keyboard_handlers(self) -> dict[GameStatus, Callable[[pygame.event.Event], bool]]:
        # Create the table that maps each game status to its key down handler
        return {
            GameStatus.GAME_IS_RUNNING: self._handle_game_is_running_keys,
            GameStatus.STUDIO_PAGE: self._handle_studio_page_keys,
            GameStatus.LOADING_PAGE: self._handle_loading_page_keys,
            GameStatus.FIRST_PAGE: self._handle_first_page_keys,
            GameStatus.CREDITS: self._handle_credits_keys,
            GameStatus.SECRET_CODE: self._handle_secret_code_keys,
            GameStatus.SECRET_CODE_IS_VALID: self._handle_secret_code_is_valid_keys,
            GameStatus.NEXT_LEVEL: self._handle_next_level_keys,
            GameStatus.GAME_IS_PAUSED: self._handle_game_is_paused_keys,
            GameStatus.LEVEL_COMPLETED: self._handle_level_completed_keys,
            GameStatus.GAME_OVER: self._handle_game_over_keys,
            GameStatus.YOU_WIN: self._handle_you_win_keys,
            GameStatus.SUMMARY: self._handle_summary_keys,
        }

    def _handle_game_is_running_keys(self, event: pygame.event.Event) -> bool:
        # Move the player, use or switch the weapon, or pause the game
        if event.key in (pygame.K_DOWN, pygame.K_s):
            self._active_movement_keys.add(event.key)
            self._game_manager.set_player_movement(0, 1)
        if event.key in (pygame.K_UP, pygame.K_w):
            self._active_movement_keys.add(event.key)
            self._game_manager.set_player_movement(0, -1)
        if event.key in (pygame.K_RIGHT, pygame.K_d):
            self._active_movement_keys.add(event.key)
            self._game_manager.set_player_movement(1, 0)
        if event.key in (pygame.K_LEFT, pygame.K_a):
            self._active_movement_keys.add(event.key)
            self._game_manager.set_player_movement(-1, 0)
        if event.key in (pygame.K_LCTRL, pygame.K_LSHIFT):
            self._game_manager.set_player_is_using_weapon(True)
        if event.key == pygame.K_x:
            self._game_manager.set_next_weapon()
        if event.key == pygame.K_z:
            self._game_manager.set_previous_weapon()
        if event.key == pygame.K_ESCAPE:
            # Open pause dialog and pause the game
            self._active_movement_keys.clear()
            self._game_manager.reset_player_movement()
            self._game_manager.switch_pause_state()
            self._screen_manager.load_game_paused_menu()
        return True

    def _handle_studio_page_keys(self, _event: pygame.event.Event) -> bool:
        # Close the studio page and show the loading page on any key
        self._screen_manager.dispose_studio_page()
        self._screen_manager.show_loading_page()
        return True

    def _handle_loading_page_keys(self, _event: pygame.event.Event) -> bool:
        # Close the loading page and show the first page on any key
        self._screen_manager.dispose_loading_page()
        self._screen_manager.show_first_page()
        return True

    def _handle_first_page_keys(self, event: pygame.event.Event) -> bool:
        # Move through the first page menu and run the selected item: new game, secret code, credits or quit
        if event.key == pygame.K_ESCAPE:
            # Quit
            return False
        elif event.key in (pygame.K_UP, pygame.K_w):
            # Move to the previous menu item
            self._screen_manager.select_previous_menu_item()
        elif event.key in (pygame.K_DOWN, pygame.K_s):
            # Move to the next menu item
            self._screen_manager.select_next_menu_item()
        elif event.key in (pygame.K_RETURN, pygame.K_SPACE):
            selected = self._screen_manager.get_selected_menu_item_index()
            if selected == 0:
                # New Game
                self._screen_manager.dispose_first_page()
                self._screen_manager.show_next_level_dialog()
            elif selected == 1:
                # Secret Code
                self._screen_manager.dispose_first_page()
                self._game_manager.set_secret_code()
                self._screen_manager.load_secret_code_message_dialog(self._secret_code_text)
            elif selected == 2:
                # Credits
                self._screen_manager.dispose_first_page()
                self._game_manager.set_credits()
                self._screen_manager.load_credits_message_dialog()
            elif selected == 3:
                # Quit
                return False
        return True

    def _handle_credits_keys(self, event: pygame.event.Event) -> bool:
        # Close the credits dialog and show the first page on Escape
        if event.key == pygame.K_ESCAPE:
            # Close credits dialog and show first page
            self._screen_manager.dispose_message_dialog()
            self._screen_manager.show_first_page()
        return True

    def _handle_secret_code_keys(self, event: pygame.event.Event) -> bool:
        # Edit the secret code text, validate it on Return or go back to the first page on Escape
        if event.key == pygame.K_ESCAPE:
            # Close secret code dialog and show first page
            self._secret_code_text = ''
            self._screen_manager.dispose_message_dialog()
            self._screen_manager.show_first_page()
        elif event.key == pygame.K_RETURN:
            # Validate secret code
            secret_code_level_index = self._game_manager.validate_secret_code(self._secret_code_text)
            if secret_code_level_index is not None:
                # Prepare selected level and change game status
                self._game_manager.clear_settings_for_first_level(secret_code_level_index)
                self._screen_manager.rebuild_level()
                self._game_manager.set_secret_code_is_valid()
                self._screen_manager.load_secret_code_message_dialog(self._secret_code_text,
                                                                    DialogFactory.create_secret_code_valid_messages())
            else:
                # Show error message
                self._screen_manager.load_secret_code_message_dialog(self._secret_code_text,
                                                                    DialogFactory.create_secret_code_invalid_messages())
        elif event.key == pygame.K_BACKSPACE:
            # Remove last char
            self._secret_code_text = self._secret_code_text[:-1]
            self._screen_manager.load_secret_code_message_dialog(self._secret_code_text)
        else:
            self._secret_code_text = self._append_secret_code_character(self._secret_code_text, event.unicode)
            self._screen_manager.load_secret_code_message_dialog(self._secret_code_text)
        return True

    def _handle_secret_code_is_valid_keys(self, _event: pygame.event.Event) -> bool:
        # Close secret code dialog and open next level dialog
        self._screen_manager.dispose_message_dialog()
        self._screen_manager.show_next_level_dialog()
        self._secret_code_text = ''
        return True

    def _handle_next_level_keys(self, event: pygame.event.Event) -> bool:
        # Close the next level dialog and start the game on Return or Space
        if event.key in (pygame.K_RETURN, pygame.K_SPACE):
            # Close next level dialog and continue the game
            self._screen_manager.dispose_message_dialog()
            self._game_manager.set_game_is_running()
            self._screen_manager.clean_screen()
            self._screen_manager.refresh_header_surface()
            self._screen_manager.refresh_dashboard_surface()
        return True

    def _handle_game_is_paused_keys(self, event: pygame.event.Event) -> bool:
        # Move through the pause menu and run the selected item: resume, restart level or quit to the first page
        if event.key == pygame.K_ESCAPE:
            # Close pause menu and continue the game
            self._resume_from_pause()
        elif event.key in (pygame.K_UP, pygame.K_w):
            # Move to the previous menu item
            self._screen_manager.select_previous_menu_item()
        elif event.key in (pygame.K_DOWN, pygame.K_s):
            # Move to the next menu item
            self._screen_manager.select_next_menu_item()
        elif event.key in (pygame.K_RETURN, pygame.K_SPACE):
            selected = self._screen_manager.get_selected_menu_item_index()
            if selected == 0:
                # Resume
                self._resume_from_pause()
            elif selected == 1:
                # Restart level or trigger game over if no lives left
                self._screen_manager.dispose_menu_dialog()
                self._game_manager.decrease_number_of_lives()
                if self._game_manager.lives > 0:
                    self._game_manager.clear_settings_for_current_level()
                    self._start_level_intro()
                else:
                    self._game_manager.set_game_is_running()
                    pygame.event.post(pygame.event.Event(Events.GAME_OVER_SUMMARY_EVENT))
            elif selected == 2:
                # Quit to main menu and reset all progress
                self._screen_manager.dispose_menu_dialog()
                self._reset_game_and_show_first_page()
        return True

    def _handle_level_completed_keys(self, event: pygame.event.Event) -> bool:
        # Close the level completed dialog and prepare the next level on Return or Space
        if event.key in (pygame.K_RETURN, pygame.K_SPACE):
            # Close level completed dialog, load next level and open next level dialog
            self._screen_manager.dispose_message_dialog()
            self._game_manager.clear_settings_for_next_level()
            self._start_level_intro()
        return True

    def _handle_game_over_keys(self, event: pygame.event.Event) -> bool:
        # Close the game over dialog and show the summary on Return or Space
        if event.key in (pygame.K_RETURN, pygame.K_SPACE):
            self._screen_manager.dispose_message_dialog()
            self._screen_manager.load_summary_panel(player_won=False)
        return True

    def _handle_you_win_keys(self, event: pygame.event.Event) -> bool:
        # Close the 'you win' dialog and show the summary on Return or Space
        if event.key in (pygame.K_RETURN, pygame.K_SPACE):
            self._screen_manager.dispose_message_dialog()
            self._screen_manager.load_summary_panel(player_won=True)
        return True

    def _handle_summary_keys(self, event: pygame.event.Event) -> bool:
        # Turn the summary pages, or reset the game and show the first page on Escape
        if event.key in (pygame.K_RETURN, pygame.K_SPACE, pygame.K_RIGHT):
            self._screen_manager.show_next_summary_page()
        elif event.key == pygame.K_LEFT:
            self._screen_manager.show_previous_summary_page()
        elif event.key == pygame.K_ESCAPE:
            self._screen_manager.dispose_summary_panel()
            self._reset_game_and_show_first_page()
        return True

    def _start_level_intro(self) -> None:
        # Put the weapon away, rebuild the level and show the next level dialog
        self._game_manager.set_player_is_using_weapon(False)
        self._screen_manager.rebuild_level()
        self._screen_manager.show_next_level_dialog()

    def _resume_from_pause(self) -> None:
        # Forget pressed movement keys, stop the player, close the pause menu and continue the game
        self._active_movement_keys.clear()
        self._game_manager.reset_player_movement()
        self._screen_manager.dispose_menu_dialog()
        self._game_manager.switch_pause_state()

    def _reset_game_and_show_first_page(self) -> None:
        # Reset all progress, rebuild the first level and show the first page
        self._game_manager.clear_settings_for_first_level()
        self._screen_manager.rebuild_level()
        self._screen_manager.show_first_page()

    @classmethod
    def _append_secret_code_character(cls, secret_code_text: str, character: str) -> str:
        # Append the typed character, which may be empty, and return the new text;
        # only ASCII letters and digits are accepted, up to SECRET_CODE_MAX_LENGTH characters
        if len(secret_code_text) < cls.SECRET_CODE_MAX_LENGTH and character.isascii() and character.isalnum():
            return secret_code_text + character
        return secret_code_text
