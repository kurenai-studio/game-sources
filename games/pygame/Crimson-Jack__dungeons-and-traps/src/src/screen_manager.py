import pygame

from settings import Settings
from src.enums.game_status import GameStatus
from src.game_manager import GameManager
from src.level import Level
from src.panels.dashboard import Dashboard
from src.panels.dialog_factory import DialogFactory
from src.panels.first_page import FirstPage
from src.panels.loading_page import LoadingPage
from src.panels.studio_page import StudioPage
from src.panels.header import Header
from src.panels.message import Message
from src.panels.multi_page_panel import MultiPagePanel
from src.panels.summary_collectables_page import SummaryCollectablesPage
from src.panels.summary_enemies_page import SummaryEnemiesPage
from src.panels.summary_trophy_page import SummaryTrophyPage


class ScreenManager:
    """Owns what is currently on screen: surfaces, level, panels, pages and dialogs."""

    # Statuses whose whole screen is the current message_dialog
    MESSAGE_DIALOG_STATUSES = frozenset({
        GameStatus.CREDITS,
        GameStatus.SECRET_CODE,
        GameStatus.SECRET_CODE_IS_VALID,
        GameStatus.NEXT_LEVEL,
        GameStatus.LEVEL_COMPLETED,
        GameStatus.GAME_OVER,
        GameStatus.YOU_WIN,
    })

    def __init__(self, screen: pygame.Surface, game_manager: GameManager) -> None:
        """
        Create the game surfaces, the level, the header and the dashboard.
        Pages, dialogs and the summary panel start empty.

        :param screen: the whole game window
        :param game_manager: shared game state
        """
        self._screen = screen
        self._game_manager = game_manager

        # Game surfaces
        screen_width, screen_height = self._screen.get_size()
        game_surface_size = screen_width, screen_height - Settings.HEADER_HEIGHT - Settings.DASHBOARD_HEIGHT
        header_surface_size = screen_width, Settings.HEADER_HEIGHT
        dashboard_surface_size = screen_width, Settings.DASHBOARD_HEIGHT
        self._game_surface = pygame.Surface(game_surface_size)
        self._header_surface = pygame.Surface(header_surface_size)
        self._dashboard_surface = pygame.Surface(dashboard_surface_size)

        # Game components
        self._level = Level(self._screen, self._game_surface, self._game_manager)
        self._header = Header(self._screen, self._header_surface, self._game_manager)
        self._dashboard = Dashboard(self._screen, self._dashboard_surface, self._game_manager)

        # Studio page, loading page, first page, dialogs and summary panel
        self._studio_page = None
        self._loading_page = None
        self._first_page = None
        self._menu_dialog = None
        self._message_dialog = None
        self._summary_panel = None
        self._first_page_selected_index = 0

    @property
    def level(self) -> Level:
        """Level being played; replaced on restart and level change, so never keep a reference to it."""
        return self._level

    def run_current_screen(self) -> None:
        """
        Run the level or draw the page, dialog or panel that belongs to the current game status.
        Called once per frame.
        """
        status = self._game_manager.game_status
        if status == GameStatus.GAME_IS_RUNNING:
            # Main game logic
            self._level.run()
        elif status == GameStatus.STUDIO_PAGE:
            self._studio_page.draw()
        elif status == GameStatus.LOADING_PAGE:
            self._loading_page.draw()
        elif status == GameStatus.FIRST_PAGE:
            self._first_page.draw()
            self._menu_dialog.draw()
        elif status == GameStatus.GAME_IS_PAUSED:
            self._menu_dialog.draw()
        elif status == GameStatus.SUMMARY:
            self._summary_panel.draw()
        elif status in self.MESSAGE_DIALOG_STATUSES:
            self._message_dialog.draw()

    def show_studio_page(self) -> None:
        """
        Switch to the studio page status, clear the screen and load the studio page.
        """
        self._game_manager.set_studio_page()
        self.clean_screen()
        self._load_studio_page()

    def show_loading_page(self) -> None:
        """
        Switch to the loading page status, clear the screen and load the loading page.
        """
        self._game_manager.set_loading_page()
        self.clean_screen()
        self._load_loading_page()

    def show_first_page(self) -> None:
        """
        Switch to the first page status, clear the screen and load the first page with its menu.
        """
        self._game_manager.set_first_page()
        self.clean_screen()
        self._load_first_page()

    def show_next_level_dialog(self) -> None:
        """
        Switch to the next level status and load the dialog introducing the current level.
        """
        self._game_manager.set_next_level()
        self._load_next_level_message_dialog()

    def rebuild_level(self) -> None:
        """
        Create a new Level object for the current level of game_manager and replace the old one.
        Always access the level through screen_manager.level, never keep a reference to it.
        """
        self._level = Level(self._screen, self._game_surface, self._game_manager)

    def load_credits_message_dialog(self) -> None:
        """
        Create the 'credits' dialog.
        """
        self._message_dialog = DialogFactory.create_credits_dialog(self._screen)

    def load_secret_code_message_dialog(self, secret_code_text: str,
                                        dialog_response_messages: list[Message] | None = None) -> None:
        """
        Create the secret code dialog showing the typed text.

        :param secret_code_text: text typed by the player so far
        :param dialog_response_messages: validation result messages shown below the text, or None
        """
        self._message_dialog = DialogFactory.create_secret_code_dialog(self._screen, secret_code_text,
                                                                       dialog_response_messages)

    def load_game_paused_menu(self) -> None:
        """
        Create the pause menu.
        """
        self._menu_dialog = DialogFactory.create_game_paused_menu(self._screen)

    def load_level_completed_message_dialog(self) -> None:
        """
        Create the level completed dialog with the statistics of the current level.
        """
        self._message_dialog = DialogFactory.create_level_completed_dialog(self._screen,
                                                                           self._game_manager.current_level_stats)

    def load_game_over_message_dialog(self) -> None:
        """
        Create the game over dialog.
        """
        self._message_dialog = DialogFactory.create_game_over_dialog(self._screen)

    def load_you_win_message_dialog(self) -> None:
        """
        Create the 'you win' dialog.
        """
        self._message_dialog = DialogFactory.create_you_win_dialog(self._screen)

    def load_summary_panel(self, player_won: bool) -> None:
        """
        Create the end of game summary panel (trophy, enemies and collectables pages)
        and switch to the summary status.

        :param player_won: True when the player completed the game, False after game over
        """
        diamond_record, key_record, bonus_record = self._game_manager.get_aggregate_collectable_stats()
        pages = (
            [SummaryTrophyPage(self._game_manager.score, player_won)]
            + SummaryEnemiesPage.create_pages(self._game_manager.get_aggregate_kill_stats())
            + [SummaryCollectablesPage(diamond_record, key_record, bonus_record)]
        )
        self._summary_panel = MultiPagePanel(self._screen, pages)
        self._game_manager.set_summary()

    def dispose_studio_page(self) -> None:
        """
        Remove the studio page.
        """
        self._studio_page = None

    def dispose_loading_page(self) -> None:
        """
        Remove the loading page.
        """
        self._loading_page = None

    def dispose_first_page(self) -> None:
        """
        Remove the first page and its menu, remembering the selected menu item for the next visit.
        """
        if self._menu_dialog is not None:
            self._first_page_selected_index = self._menu_dialog.get_selected_index()
        self._first_page = None
        self._menu_dialog = None

    def dispose_menu_dialog(self) -> None:
        """
        Remove the menu dialog.
        """
        self._menu_dialog = None

    def dispose_message_dialog(self) -> None:
        """
        Remove the message dialog.
        """
        self._message_dialog = None

    def dispose_summary_panel(self) -> None:
        """
        Remove the summary panel.
        """
        self._summary_panel = None

    def clean_screen(self) -> None:
        """
        Fill the whole screen with the background color.
        """
        self._screen.fill(Settings.GAME_BACKGROUND_COLOR)

    def refresh_header_surface(self) -> None:
        """
        Clear and redraw the header.
        """
        self._header.clean()
        self._header.draw()

    def refresh_dashboard_surface(self) -> None:
        """
        Clear and redraw the dashboard.
        """
        self._dashboard.clean()
        self._dashboard.draw()

    def refresh_header_and_dashboard_surfaces(self) -> None:
        """
        Clear and redraw both the header and the dashboard.
        """
        self.refresh_header_surface()
        self.refresh_dashboard_surface()

    def select_previous_menu_item(self) -> None:
        """
        Move the selection of the menu on screen to the previous item.
        """
        self._menu_dialog.select_previous()

    def select_next_menu_item(self) -> None:
        """
        Move the selection of the menu on screen to the next item.
        """
        self._menu_dialog.select_next()

    def get_selected_menu_item_index(self) -> int:
        """
        Return the index of the item selected in the menu on screen.

        :return: index of the selected menu item
        """
        return self._menu_dialog.get_selected_index()

    def show_next_summary_page(self) -> None:
        """
        Turn the summary panel to the next page.
        """
        self._summary_panel.next_page()

    def show_previous_summary_page(self) -> None:
        """
        Turn the summary panel to the previous page.
        """
        self._summary_panel.previous_page()

    def _load_studio_page(self) -> None:
        # Create the studio page
        self._studio_page = StudioPage(self._screen)

    def _load_loading_page(self) -> None:
        # Create the loading page
        self._loading_page = LoadingPage(self._screen)

    def _load_first_page(self) -> None:
        # Create the first page and its menu, restoring the menu item selected on the previous visit
        self._first_page = FirstPage(self._screen)
        self._menu_dialog = DialogFactory.create_first_page_menu(self._screen)
        self._menu_dialog.selected_index = self._first_page_selected_index

    def _load_next_level_message_dialog(self) -> None:
        # Create the dialog introducing the current level: number, name, description and secret code
        self._message_dialog = DialogFactory.create_next_level_dialog(self._screen,
                                                                      self._game_manager.level_index + 1,
                                                                      self._game_manager.current_level_details.name,
                                                                      self._game_manager.current_level_details.description,
                                                                      self._game_manager.current_level_details.secret_code)
