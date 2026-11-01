from collections.abc import Callable
from unittest.mock import Mock

import pygame
import pytest

import src.game_manager
from settings import Settings
from src.custom_event_controller import CustomEventController
from src.enums.game_status import GameStatus
from src.game import Game
from src.game_manager import GameManager
from src.keyboard_controller import KeyboardController
from src.level import Level
from src.panels.dashboard import Dashboard
from src.panels.first_page import FirstPage
from src.panels.header import Header
from src.panels.loading_page import LoadingPage
from src.panels.menu_box import MenuBox
from src.panels.message_box import MessageBox
from src.panels.multi_page_panel import MultiPagePanel
from src.panels.studio_page import StudioPage
from src.screen_manager import ScreenManager


class ScreenManagerUnderTest:
    """
    Real screen manager for integration tests; exposes its private pages, dialogs and panels under public names
    and passes everything else to the screen manager.
    """

    def __init__(self, screen_manager: ScreenManager) -> None:
        self.wrapped_screen_manager = screen_manager

    def __getattr__(self, name: str):
        return getattr(self.wrapped_screen_manager, name)

    @property
    def header(self) -> Header:
        return self.wrapped_screen_manager._header

    @property
    def dashboard(self) -> Dashboard:
        return self.wrapped_screen_manager._dashboard

    @property
    def studio_page(self) -> StudioPage | None:
        return self.wrapped_screen_manager._studio_page

    @property
    def loading_page(self) -> LoadingPage | None:
        return self.wrapped_screen_manager._loading_page

    @property
    def first_page(self) -> FirstPage | None:
        return self.wrapped_screen_manager._first_page

    @property
    def message_dialog(self) -> MessageBox | None:
        return self.wrapped_screen_manager._message_dialog

    @property
    def menu_dialog(self) -> MenuBox | None:
        return self.wrapped_screen_manager._menu_dialog

    @property
    def summary_panel(self) -> MultiPagePanel | None:
        return self.wrapped_screen_manager._summary_panel


class KeyboardControllerUnderTest:
    """
    Real keyboard controller for integration tests; exposes its private state and secret code helper under public
    names and passes everything else to the keyboard controller.
    """

    def __init__(self, keyboard_controller: KeyboardController) -> None:
        self.wrapped_keyboard_controller = keyboard_controller

    def __getattr__(self, name: str):
        return getattr(self.wrapped_keyboard_controller, name)

    @property
    def secret_code_text(self) -> str:
        return self.wrapped_keyboard_controller._secret_code_text

    @secret_code_text.setter
    def secret_code_text(self, secret_code_text: str) -> None:
        self.wrapped_keyboard_controller._secret_code_text = secret_code_text

    @property
    def active_movement_keys(self) -> set[int]:
        return self.wrapped_keyboard_controller._active_movement_keys

    @property
    def keyboard_handlers(self) -> dict[GameStatus, Callable[[pygame.event.Event], bool]]:
        return self.wrapped_keyboard_controller._keyboard_handlers

    @staticmethod
    def append_secret_code_character(secret_code_text: str, character: str) -> str:
        return KeyboardController._append_secret_code_character(secret_code_text, character)


class CustomEventControllerUnderTest:
    """
    Real custom event controller for integration tests; exposes its private handler table under a public name
    and passes everything else to the custom event controller.
    """

    def __init__(self, custom_event_controller: CustomEventController) -> None:
        self.wrapped_custom_event_controller = custom_event_controller

    def __getattr__(self, name: str):
        return getattr(self.wrapped_custom_event_controller, name)

    @property
    def custom_event_handlers(self) -> dict[int, Callable[[pygame.event.Event], None]]:
        return self.wrapped_custom_event_controller._custom_event_handlers


class GameUnderTest:
    """Real game for integration tests; the only place that reads the private components of Game."""

    def __init__(self, game: Game) -> None:
        self.game = game

    @property
    def game_manager(self) -> GameManager:
        return self.game._game_manager

    @property
    def screen_manager(self) -> ScreenManagerUnderTest:
        return ScreenManagerUnderTest(self.game._screen_manager)

    @property
    def keyboard_controller(self) -> KeyboardControllerUnderTest:
        return KeyboardControllerUnderTest(self.game._keyboard_controller)

    @property
    def custom_event_controller(self) -> CustomEventControllerUnderTest:
        return CustomEventControllerUnderTest(self.game._custom_event_controller)


def pytest_configure(config):
    # Tests that reach into private members while a refactoring is in progress; review and remove them afterwards
    config.addinivalue_line('markers', 'refactoring: scaffolding test for a refactoring; review and remove afterwards')


# Game() calls pygame.init() and loads level 1 in its constructor, so the SDL drivers must be
# switched to dummy before construction and Pygame must be shut down after every test.
@pytest.fixture
def new_game(monkeypatch):
    monkeypatch.setenv('SDL_VIDEODRIVER', 'dummy')
    monkeypatch.setenv('SDL_AUDIODRIVER', 'dummy')
    monkeypatch.setattr(Settings, 'FULL_SCREEN_MODE', False)

    game = GameUnderTest(Game())
    yield game

    pygame.event.clear()
    pygame.quit()


# Most integration tests start from the first page, as the player does after the studio and loading pages
@pytest.fixture
def game(new_game):
    new_game.screen_manager.dispose_studio_page()
    new_game.screen_manager.show_first_page()
    return new_game


# Replaces the level and both panels with mocks so custom events can be checked by the calls the controllers make.
@pytest.fixture
def game_with_mocked_components(game):
    screen_manager = game.screen_manager.wrapped_screen_manager
    screen_manager._level = Mock(spec=Level)
    screen_manager._header = Mock(spec=Header)
    screen_manager._dashboard = Mock(spec=Dashboard)
    pygame.event.clear()
    return game


@pytest.fixture
def set_timer_mock(monkeypatch):
    set_timer_mock = Mock()
    monkeypatch.setattr(pygame.time, 'set_timer', set_timer_mock)
    return set_timer_mock


# SoundManager loads sound files through pygame.mixer, which is irrelevant for the game state
@pytest.fixture
def game_manager(monkeypatch):
    monkeypatch.setattr(src.game_manager, 'SoundManager', Mock())
    return GameManager()


# pygame.event.post needs an initialized pygame; the mock records the posted events instead
@pytest.fixture
def post_event_mock(monkeypatch):
    post_event_mock = Mock()
    monkeypatch.setattr(pygame.event, 'post', post_event_mock)
    return post_event_mock
