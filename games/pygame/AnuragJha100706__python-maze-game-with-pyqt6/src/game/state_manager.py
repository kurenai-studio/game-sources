"""
Master State Manager (Pure Pygame).
Manages all game screen transitions, input dispatching, loop lifecycle,
display letterbox presentation, gamepad controllers, and gameplay state routing for Cyber Maze Runner.
"""

import sys
import pygame
from typing import Dict, Any, Optional, Union

from ui.screen_auth import AuthScreen
from ui.screen_menu import MainMenuScreen
from ui.screen_mode_select import ModeSelectScreen
from ui.screen_leaderboard import LeaderboardScreen
from ui.screen_settings import SettingsScreen
from ui.widgets import Button

from game.modes.mode_solo import SoloTimeTrialMode
from game.modes.mode_two_player import TwoPlayerMode
from game.modes.mode_race import RaceVsAIMode
from game.modes.mode_chase import ChaseSurvivalMode
from game.modes.mode_escape import EscapeHeistMode
from database.db_manager import DatabaseManager
from game.audio import SoundFX
from core.display_manager import DisplayManager
from core.input_manager import InputManager

class StateManager:
    """Finite State Machine orchestrating all pure Pygame screens and game modes."""

    def __init__(self, display_or_screen: Union[DisplayManager, pygame.Surface]):
        if isinstance(display_or_screen, DisplayManager):
            self.display_manager = display_or_screen
            self.screen = self.display_manager.virtual_surface
        else:
            self.screen = display_or_screen
            self.display_manager = DisplayManager()
            self.display_manager.virtual_surface = self.screen

        self.width = self.screen.get_width()
        self.height = self.screen.get_height()
        self.clock = pygame.time.Clock()
        self.running = True

        SoundFX.init()
        self.db = DatabaseManager()
        sfx_on = self.db.get_setting("sfx_enabled", "1") == "1"
        SoundFX.set_enabled(sfx_on)

        # Restore saved audio volume levels from database
        try:
            m_vol = float(self.db.get_setting("master_volume", "1.0"))
            s_vol = float(self.db.get_setting("sfx_volume", "1.0"))
            SoundFX.set_master_volume(m_vol)
            SoundFX.set_sfx_volume(s_vol)
        except Exception:
            pass

        # Controller / Gamepad Input Manager
        self.input_manager = InputManager()

        self.user_data: Dict[str, Any] = {"id": 1, "username": "Guest_Runner"}

        # State tracking: AUTH, MENU, MODE_SELECT, PLAYING, PAUSED, LEADERBOARD, SETTINGS
        self.current_state = "AUTH"

        # Screens
        self.auth_screen = AuthScreen((self.width, self.height), self._on_auth_success)
        self.menu_screen = MainMenuScreen((self.width, self.height), self._on_menu_navigate, self.user_data)
        self.mode_select_screen = ModeSelectScreen((self.width, self.height), self._on_launch_game, lambda: self.set_state("MENU"))
        self.leaderboard_screen = LeaderboardScreen((self.width, self.height), lambda: self.set_state("MENU"))
        self.settings_screen = SettingsScreen(
            (self.width, self.height),
            lambda: self.set_state("MENU"),
            display_mgr=self.display_manager,
            input_mgr=self.input_manager
        )

        # Gameplay instance
        self.current_game = None
        self.selected_mode = 0
        self.selected_grid_size = 20

        # Pause Menu Overlay Components
        self.font_pause = pygame.font.SysFont("segoeui", 32, bold=True)
        self.font_hint = pygame.font.SysFont("segoeui", 14)
        cx = self.width // 2
        cy = self.height // 2
        btn_w, btn_h = 240, 46
        self.btn_resume = Button(cx - btn_w // 2, cy - 40, btn_w, btn_h, "RESUME [ESC]", self._resume_game, color=(0, 240, 255), text_color=(11, 14, 23))
        self.btn_retry = Button(cx - btn_w // 2, cy + 18, btn_w, btn_h, "RESTART MISSION [R]", self._restart_game, color=(27, 34, 53), font_size=13)
        self.btn_quit_to_menu = Button(cx - btn_w // 2, cy + 76, btn_w, btn_h, "ABORT TO MENU [Q]", lambda: self.set_state("MENU"), color=(18, 22, 34), hover_color=(239, 71, 111), font_size=13)

    def set_state(self, new_state: str):
        """Transitions state safely."""
        self.current_state = new_state
        if new_state == "LEADERBOARD":
            self.leaderboard_screen.refresh_data()
        elif new_state == "MENU":
            self.menu_screen.set_user(self.user_data)

    def _on_auth_success(self, user_data: Dict[str, Any]):
        self.user_data = user_data
        self.menu_screen.set_user(user_data)
        self.set_state("MENU")

    def _on_menu_navigate(self, target: str):
        if target == "EXIT":
            self.running = False
        else:
            self.set_state(target)

    def _on_launch_game(self, mode_id: int, grid_size: int):
        self.selected_mode = mode_id
        self.selected_grid_size = grid_size
        algo = self.db.get_setting("generator_algo", "kruskal")

        mode_classes = {
            0: SoloTimeTrialMode,
            1: TwoPlayerMode,
            2: RaceVsAIMode,
            3: ChaseSurvivalMode,
            4: EscapeHeistMode
        }
        cls = mode_classes.get(mode_id, SoloTimeTrialMode)
        self.current_game = cls(
            viewport_size=(self.width, self.height),
            grid_size=grid_size,
            generator_algo=algo,
            user_data=self.user_data
        )
        self.set_state("PLAYING")

    def _resume_game(self):
        if self.current_game and not self.current_game.game_over:
            self.current_state = "PLAYING"

    def _restart_game(self):
        self._on_launch_game(self.selected_mode, self.selected_grid_size)

    def run(self):
        """Main game loop ticking at 60 FPS."""
        while self.running:
            dt = self.clock.tick(60) / 1000.0  # Delta time in seconds

            # 1. Event Handling with Hotplugging and Resolution Mapping
            raw_events = pygame.event.get()
            events = []
            for raw_ev in raw_events:
                # Update input manager with device added/removed events
                self.input_manager.handle_event(raw_ev)

                # Global Fullscreen Toggle Hotkey (F11 or Alt+Enter)
                if raw_ev.type == pygame.KEYDOWN:
                    if raw_ev.key == pygame.K_F11 or (raw_ev.key == pygame.K_RETURN and (raw_ev.mod & pygame.KMOD_ALT)):
                        self.display_manager.toggle_fullscreen()
                        continue

                # Inverse mouse projection from physical display to virtual canvas
                mapped_ev = self.display_manager.map_event(raw_ev)
                events.append(mapped_ev)

            # Controller Pause / Unpause Trigger
            if self.input_manager.is_action_just_pressed("PAUSE"):
                if self.current_state == "PLAYING":
                    self.current_state = "PAUSED"
                elif self.current_state == "PAUSED":
                    self._resume_game()

            # Dispatch mapped events
            for event in events:
                if event.type == pygame.QUIT:
                    self.running = False
                    break

                if self.current_state == "AUTH":
                    self.auth_screen.handle_event(event)

                elif self.current_state == "MENU":
                    self.menu_screen.handle_event(event)

                elif self.current_state == "MODE_SELECT":
                    self.mode_select_screen.handle_event(event)

                elif self.current_state == "LEADERBOARD":
                    self.leaderboard_screen.handle_event(event)

                elif self.current_state == "SETTINGS":
                    self.settings_screen.handle_event(event)

                elif self.current_state == "PLAYING":
                    if event.type == pygame.KEYDOWN:
                        if event.key == pygame.K_ESCAPE:
                            self.current_state = "PAUSED"
                        elif event.key == pygame.K_r:
                            self._restart_game()
                        elif event.key == pygame.K_RETURN and self.current_game and self.current_game.game_over:
                            self.set_state("MODE_SELECT")

                elif self.current_state == "PAUSED":
                    self.btn_resume.handle_event(event)
                    self.btn_retry.handle_event(event)
                    self.btn_quit_to_menu.handle_event(event)
                    if event.type == pygame.KEYDOWN:
                        if event.key == pygame.K_ESCAPE:
                            self._resume_game()
                        elif event.key == pygame.K_r:
                            self._restart_game()
                        elif event.key == pygame.K_q:
                            self.set_state("MENU")

            # 2. Update Active Scene Logic
            self.input_manager.update(dt)

            if self.current_state == "AUTH":
                self.auth_screen.update(dt)

            elif self.current_state == "MENU":
                self.menu_screen.update(dt)

            elif self.current_state == "MODE_SELECT":
                self.mode_select_screen.update(dt)

            elif self.current_state == "LEADERBOARD":
                self.leaderboard_screen.update(dt)

            elif self.current_state == "SETTINGS":
                self.settings_screen.update(dt)

            elif self.current_state == "PLAYING" and self.current_game:
                keys = pygame.key.get_pressed()
                self.current_game.handle_input(keys, dt, input_mgr=self.input_manager)
                self.current_game.update(dt)

            elif self.current_state == "PAUSED":
                self.btn_resume.update(dt)
                self.btn_retry.update(dt)
                self.btn_quit_to_menu.update(dt)

            # 3. Render Active Scene to Virtual Surface
            if self.current_state == "AUTH":
                self.auth_screen.render(self.screen)

            elif self.current_state == "MENU":
                self.menu_screen.render(self.screen)

            elif self.current_state == "MODE_SELECT":
                self.mode_select_screen.render(self.screen)

            elif self.current_state == "LEADERBOARD":
                self.leaderboard_screen.render(self.screen)

            elif self.current_state == "SETTINGS":
                self.settings_screen.render(self.screen)

            elif self.current_state in ("PLAYING", "PAUSED") and self.current_game:
                self.current_game.render(self.screen)

                # Render Pause Overlay if paused
                if self.current_state == "PAUSED":
                    overlay = pygame.Surface((self.width, self.height), pygame.SRCALPHA)
                    overlay.fill((11, 14, 23, 220))
                    self.screen.blit(overlay, (0, 0))

                    title_surf = self.font_pause.render("MISSION PAUSED", True, (0, 240, 255))
                    self.screen.blit(title_surf, (self.width // 2 - title_surf.get_width() // 2, self.height // 2 - 110))

                    hint_surf = self.font_hint.render("Select an action to continue protocol", True, (142, 154, 175))
                    self.screen.blit(hint_surf, (self.width // 2 - hint_surf.get_width() // 2, self.height // 2 - 68))

                    self.btn_resume.draw(self.screen)
                    self.btn_retry.draw(self.screen)
                    self.btn_quit_to_menu.draw(self.screen)

            # Present scaled virtual canvas to physical display with letterbox presentation
            self.display_manager.present()

        pygame.quit()
        sys.exit(0)
