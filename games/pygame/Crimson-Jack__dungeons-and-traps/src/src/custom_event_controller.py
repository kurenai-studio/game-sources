from collections.abc import Callable

import pygame

from settings import Settings
from src.events import Events
from src.game_manager import GameManager
from src.screen_manager import ScreenManager


class CustomEventController:
    """Reacts to custom game events posted by sprites and timers."""

    # Timer durations (milliseconds)
    TELEPORT_TO_NEXT_LEVEL_DELAY_MS = 2500
    RESPAWN_AFTER_LOST_LIFE_DELAY_MS = 2000
    RESPAWN_AFTER_TELEPORT_DELAY_MS = 1000
    END_OF_GAME_SUMMARY_DELAY_MS = 2500

    def __init__(self, game_manager: GameManager, screen_manager: ScreenManager) -> None:
        """
        Build the table that maps each custom event type to its handler.

        :param game_manager: shared game state
        :param screen_manager: level, panels, pages and dialogs currently on screen
        """
        self._game_manager = game_manager
        self._screen_manager = screen_manager

        # Custom event type -> handler
        self._custom_event_handlers = self._create_custom_event_handlers()

    def handle_custom_events(self, event: pygame.event.Event) -> None:
        """
        Run the handler registered for the event type. Events without a handler are ignored.

        :param event: any pygame event taken from the event queue
        """
        handler = self._custom_event_handlers.get(event.type)
        if handler is not None:
            handler(event)

    def _create_custom_event_handlers(self) -> dict[int, Callable[[pygame.event.Event], None]]:
        # Create the table that maps each custom event type to its handler.
        # Handlers read self._screen_manager.level on every call, because the level object is replaced
        # on restart and level change.
        return {
            Events.CHANGE_SCORE_EVENT:
                lambda _event: self._screen_manager.refresh_header_surface(),
            Events.COLLECT_DIAMOND_EVENT:
                lambda _event: self._screen_manager.refresh_header_and_dashboard_surfaces(),
            Events.COLLECT_KEY_EVENT:
                lambda _event: self._screen_manager.refresh_header_and_dashboard_surfaces(),
            Events.COLLECT_LIFE_EVENT:
                lambda _event: self._screen_manager.refresh_dashboard_surface(),
            Events.CHANGE_WEAPON_CAPACITY_EVENT:
                lambda _event: self._screen_manager.refresh_header_surface(),
            Events.CHANGE_ENERGY_EVENT:
                lambda _event: self._screen_manager.refresh_dashboard_surface(),
            Events.CHANGE_WEAPON_EVENT:
                lambda _event: self._screen_manager.refresh_header_surface(),
            Events.EXIT_POINT_IS_OPEN_EVENT:
                lambda _event: self._screen_manager.level.show_exit_point(),
            Events.START_TELEPORT_PLAYER_TO_NEXT_LEVEL_EVENT:
                self._handle_start_teleport_player_to_next_level_event,
            Events.FINISH_TELEPORT_PLAYER_TO_NEXT_LEVEL_EVENT:
                self._handle_finish_teleport_player_to_next_level_event,
            Events.NEXT_LEVEL_EVENT:
                self._handle_next_level_event,
            Events.REMOVE_OBSTACLES_EVENT:
                lambda _event: self._screen_manager.level.remove_obstacles(),
            Events.REFRESH_OBSTACLE_MAP_EVENT:
                lambda _event: self._screen_manager.level.refresh_obstacle_map(),
            Events.PLAYER_TILE_POSITION_CHANGED_EVENT:
                lambda _event: self._screen_manager.level.inform_about_player_tile_position(),
            Events.PLAYER_IS_NOT_USING_WEAPON_EVENT:
                lambda _event: self._game_manager.set_player_is_using_weapon(False),
            Events.ADD_PARTICLE_EFFECT_EVENT:
                lambda event: self._screen_manager.level.add_particle_effect(
                    event.dict.get("position"),
                    event.dict.get("number_of_sparks"),
                    event.dict.get("colors")),
            Events.PARTICLE_EVENT:
                lambda _event:
                self._screen_manager.level.add_spark_to_particle_effect(),
            Events.ADD_TOMBSTONE_EVENT:
                lambda event:
                self._screen_manager.level.add_tombstone(
                    event.dict.get("position")),
            Events.ADD_BOSS_TOMBSTONE_EVENT:
                lambda event:
                self._screen_manager.level.add_boss_tombstone(
                    event.dict.get("position")),
            Events.ADD_VANISHING_POINT_EVENT:
                lambda event:
                self._screen_manager.level.add_vanishing_point(
                    event.dict.get("position")),
            Events.CREATE_EGG_EVENT:
                lambda event:
                self._screen_manager.level.create_egg(
                    event.dict.get("position")),
            Events.CREATE_MONSTER_EVENT:
                lambda event:
                self._screen_manager.level.create_monster(
                    event.dict.get("position")),
            Events.CREATE_BOSS_OCTOPUS_EVENT:
                self._handle_create_boss_octopus_event,
            Events.PLAYER_LOST_LIFE_EVENT:
                self._handle_player_lost_life_event,
            Events.TELEPORT_PLAYER_EVENT:
                self._handle_teleport_player_event,
            Events.RESPAWN_PLAYER_EVENT:
                self._handle_respawn_player_event,
            Events.CREATE_EXPLODE_EFFECT_EVENT:
                lambda event:
                self._screen_manager.level.show_explode_effect(
                    event.dict.get("position")),
            Events.GAME_OVER_EVENT:
                self._handle_game_over_event,
            Events.GAME_OVER_SUMMARY_EVENT:
                self._handle_game_over_summary_event,
            Events.YOU_WIN_EVENT:
                lambda _event: pygame.time.set_timer(
                    Events.YOU_WIN_SUMMARY_EVENT,
                    self.END_OF_GAME_SUMMARY_DELAY_MS),
            Events.YOU_WIN_SUMMARY_EVENT:
                self._handle_you_win_summary_event,
            Events.TILT_EFFECT_EVENT:
                lambda event: self._screen_manager.level.enable_tilt_effect(
                    event.dict.get("tilt_cursor_increment_value")),
        }

    def _handle_start_teleport_player_to_next_level_event(self, _event: pygame.event.Event) -> None:
        # Show the player vanishing point and schedule the end of the teleport to the next level
        self._screen_manager.level.show_player_vanishing_point()
        pygame.time.set_timer(
            pygame.event.Event(Events.FINISH_TELEPORT_PLAYER_TO_NEXT_LEVEL_EVENT), self.TELEPORT_TO_NEXT_LEVEL_DELAY_MS)

    def _handle_finish_teleport_player_to_next_level_event(self, _event: pygame.event.Event) -> None:
        # Cancel the teleport timer and let the game manager move on to the next level
        pygame.time.set_timer(Events.FINISH_TELEPORT_PLAYER_TO_NEXT_LEVEL_EVENT, 0)
        self._game_manager.load_next_level()

    def _handle_next_level_event(self, _event: pygame.event.Event) -> None:
        # Mark the level as completed, award the bonus when all enemies are defeated and show the level completed dialog
        self._game_manager.set_level_completed()
        if self._game_manager.current_level_stats.all_enemies_defeated():
            self._game_manager.award_completion_bonus(Settings.LEVEL_COMPLETION_BONUS)
        self._screen_manager.load_level_completed_message_dialog()

    def _handle_create_boss_octopus_event(self, _event: pygame.event.Event) -> None:
        # Create the boss octopus and refresh the dashboard
        self._screen_manager.level.create_boss_octopus()
        self._screen_manager.refresh_dashboard_surface()

    def _handle_player_lost_life_event(self, _event: pygame.event.Event) -> None:
        # Show the player tombstone and schedule the respawn
        self._screen_manager.level.show_player_tombstone()
        pygame.time.set_timer(Events.RESPAWN_PLAYER_EVENT, self.RESPAWN_AFTER_LOST_LIFE_DELAY_MS)

    def _handle_teleport_player_event(self, event: pygame.event.Event) -> None:
        # Show the player vanishing point and schedule the respawn at the teleport destination ("position")
        self._screen_manager.level.show_player_vanishing_point()
        pygame.time.set_timer(
            pygame.event.Event(Events.RESPAWN_PLAYER_EVENT, {"position": event.dict.get("position")}),
            self.RESPAWN_AFTER_TELEPORT_DELAY_MS)

    def _handle_respawn_player_event(self, event: pygame.event.Event) -> None:
        # Cancel the respawn timer, put the weapon away, respawn the player and refresh the dashboard
        player_new_position = event.dict.get("position")
        pygame.time.set_timer(Events.RESPAWN_PLAYER_EVENT, 0)
        self._game_manager.set_player_is_using_weapon(False)
        self._screen_manager.level.respawn_player(player_new_position)
        self._screen_manager.refresh_dashboard_surface()

    def _handle_game_over_event(self, _event: pygame.event.Event) -> None:
        # Show the player tombstone and schedule the game over summary
        self._screen_manager.level.show_player_tombstone()
        pygame.time.set_timer(Events.GAME_OVER_SUMMARY_EVENT, self.END_OF_GAME_SUMMARY_DELAY_MS)

    def _handle_game_over_summary_event(self, _event: pygame.event.Event) -> None:
        # Cancel the summary timer, switch to the game over status, show its dialog and refresh the dashboard
        pygame.time.set_timer(Events.GAME_OVER_SUMMARY_EVENT, 0)
        self._game_manager.set_game_over()
        self._screen_manager.load_game_over_message_dialog()
        self._screen_manager.refresh_dashboard_surface()

    def _handle_you_win_summary_event(self, _event: pygame.event.Event) -> None:
        # Cancel the summary timer, switch to the 'you win' status, show its dialog and refresh the dashboard
        pygame.time.set_timer(Events.YOU_WIN_SUMMARY_EVENT, 0)
        self._game_manager.set_you_win()
        self._screen_manager.load_you_win_message_dialog()
        self._screen_manager.refresh_dashboard_surface()
