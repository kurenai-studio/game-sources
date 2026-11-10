"""
Lane Legends: Human vs AI
game.py - Primary Game Engine, State Machine, Input Handling, Physics Loop, and Mode Management.
"""

import sys
import time
import random
from typing import Optional, Dict, Any, List

import pygame
from settings import (
    WINDOW_WIDTH,
    WINDOW_HEIGHT,
    FPS,
    TITLE,
    TRACK_1_LANES,
    TRACK_2_LANES,
    CAR_P1_COLOR,
    CAR_P2_COLOR,
    CAR_AI_COLOR,
    RACE_DISTANCE_METERS,
    METERS_PER_PIXEL,
    DIFFICULTY_EASY,
    DIFFICULTY_MEDIUM,
    DIFFICULTY_HARD,
    DIFFICULTY_PROFILES,
    ACTION_LEFT,
    ACTION_STAY,
    ACTION_RIGHT,
    COLOR_CYAN,
    COLOR_ORANGE,
    COLOR_CRIMSON,
    COLOR_GREEN,
    COLOR_YELLOW,
)
from entities import Car
from track import DualTrackManager
from ai_agent import QLearningAgent
from ai_trainer import ensure_trained_agent
from scoreboard import Scoreboard
from sound_effects import SoundManager
from ui import UIManager, Button


# Game States
STATE_MENU = "menu"
STATE_DIFFICULTY = "difficulty"
STATE_HOW_TO_PLAY = "how_to_play"
STATE_HIGH_SCORES = "high_scores"
STATE_AI_INFO = "ai_info"
STATE_COUNTDOWN = "countdown"
STATE_RACING = "racing"
STATE_PAUSED = "paused"
STATE_RESULTS = "results"

# Game Modes
MODE_VS_AI = "vs_ai"
MODE_PVP = "pvp"


class Game:
    """
    Main Game Controller orchestrating scenes, rendering, AI agent decisions,
    audio, and player inputs.
    """

    def __init__(self):
        pygame.init()
        pygame.display.set_caption(TITLE)
        self.screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
        self.clock = pygame.time.Clock()
        self.running = True

        # Subsystems
        self.sound_mgr = SoundManager()
        self.ui_mgr = UIManager()
        self.scoreboard = Scoreboard()
        self.ai_agent = ensure_trained_agent()

        # State Variables
        self.state = STATE_MENU
        self.mode = MODE_VS_AI
        self.current_difficulty = DIFFICULTY_MEDIUM
        self.show_ai_telemetry = True  # Enabled by default for academic presentation!

        # Race Entities
        self.track_mgr: Optional[DualTrackManager] = None
        self.car_p1: Optional[Car] = None
        self.car_p2: Optional[Car] = None

        # Timers & AI Decision Tracker
        self.countdown_timer = 3.6
        self.race_start_time = 0.0
        self.race_elapsed_time = 0.0
        self.ai_decision_timer = 0.0
        self.ai_latest_telemetry: Optional[Dict[str, Any]] = None
        self.winner_name = ""

        # Setup Menu Buttons
        self.menu_selected_idx = 0
        self.menu_buttons: List[Button] = []
        self._init_menu_buttons()

        # Shared Back Button for Sub-screens
        self.btn_back = Button(
            rect=pygame.Rect(WINDOW_WIDTH // 2 - 110, WINDOW_HEIGHT - 65, 220, 44),
            text="BACK TO MENU",
            tag="back",
            accent_color=COLOR_CYAN,
            font_size=18,
        )

        # Pause Buttons
        self.pause_buttons = [
            Button(pygame.Rect(WINDOW_WIDTH // 2 - 130, WINDOW_HEIGHT // 2 - 50, 260, 46), "RESUME RACE", "resume", COLOR_GREEN),
            Button(pygame.Rect(WINDOW_WIDTH // 2 - 130, WINDOW_HEIGHT // 2 + 10, 260, 46), "RESTART RACE", "restart", COLOR_YELLOW),
            Button(pygame.Rect(WINDOW_WIDTH // 2 - 130, WINDOW_HEIGHT // 2 + 70, 260, 46), "MAIN MENU", "main_menu", COLOR_CRIMSON),
        ]

        # Results Screen Buttons
        self.results_buttons = [
            Button(pygame.Rect(WINDOW_WIDTH // 2 - 250, WINDOW_HEIGHT - 90, 230, 48), "RACE AGAIN", "restart", COLOR_GREEN),
            Button(pygame.Rect(WINDOW_WIDTH // 2 + 20, WINDOW_HEIGHT - 90, 230, 48), "MAIN MENU", "main_menu", COLOR_CYAN),
        ]

    def _init_menu_buttons(self) -> None:
        """Create menu buttons positioned down the center."""
        btn_w = 360
        btn_h = 44
        start_y = 205
        spacing = 58
        bx = (WINDOW_WIDTH - btn_w) // 2

        menu_items = [
            ("PLAY VS AI", "play_vs_ai", COLOR_CYAN),
            ("PLAY WITH FRIEND (2 PLAYERS)", "play_pvp", COLOR_ORANGE),
            ("DIFFICULTY SETTINGS", "difficulty", COLOR_CRIMSON),
            ("HIGH SCORES & RECORDS", "high_scores", COLOR_YELLOW),
            ("HOW TO PLAY & CONTROLS", "how_to_play", COLOR_GREEN),
            ("QUIT GAME", "quit", (180, 50, 60)),
        ]

        self.menu_buttons.clear()
        for idx, (label, tag, col) in enumerate(menu_items):
            self.menu_buttons.append(
                Button(
                    rect=pygame.Rect(bx, start_y + idx * spacing, btn_w, btn_h),
                    text=label,
                    tag=tag,
                    accent_color=col,
                    font_size=20,
                )
            )

    def start_race(self, mode: str) -> None:
        """Initialize a new race with dual tracks, cars, and synced obstacles."""
        self.mode = mode
        diff_profile = DIFFICULTY_PROFILES[self.current_difficulty]

        # Initialize Track Manager with fresh randomized seed
        self.track_mgr = DualTrackManager()

        # Initialize Player 1 Car (Left Track)
        self.car_p1 = Car(
            name="Player 1",
            color=CAR_P1_COLOR,
            lanes=TRACK_1_LANES,
            start_lane=1,
            is_ai=False,
            speed_multiplier=1.0,
        )

        # Initialize Competitor Car (Right Track)
        if self.mode == MODE_VS_AI:
            self.car_p2 = Car(
                name=diff_profile["name"],
                color=CAR_AI_COLOR,
                lanes=TRACK_2_LANES,
                start_lane=1,
                is_ai=True,
                speed_multiplier=diff_profile["speed_multiplier"],
            )
        else:
            self.car_p2 = Car(
                name="Player 2",
                color=CAR_P2_COLOR,
                lanes=TRACK_2_LANES,
                start_lane=1,
                is_ai=False,
                speed_multiplier=1.0,
            )

        self.countdown_timer = 3.6
        self.race_elapsed_time = 0.0
        self.ai_decision_timer = 0.0
        self.ai_latest_telemetry = None
        self.winner_name = ""
        self.state = STATE_COUNTDOWN
        self.sound_mgr.play("countdown_low")

    # -------------------------------------------------------------------------
    # MAIN LOOP
    # -------------------------------------------------------------------------
    def run(self) -> None:
        """Main game loop executing state updates and frame rendering."""
        while self.running:
            dt = self.clock.tick(FPS) / 1000.0
            dt = min(dt, 0.05)  # Cap delta time to prevent physics clipping on lag

            self._handle_events()
            self._update(dt)
            self._render()

            pygame.display.flip()

        pygame.quit()
        sys.exit(0)

    # -------------------------------------------------------------------------
    # EVENT HANDLING
    # -------------------------------------------------------------------------
    def _handle_events(self) -> None:
        mouse_pos = pygame.mouse.get_pos()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False
                return

            if event.type == pygame.KEYDOWN:
                # Global Hotkeys
                if event.key == pygame.K_m:
                    is_audio_on = self.sound_mgr.toggle_mute()
                    msg = "AUDIO: MUTED" if not is_audio_on else "AUDIO: ENABLED"
                    self.ui_mgr.add_notification(msg, COLOR_YELLOW, 1.0)

                elif event.key in (pygame.K_i, pygame.K_e):
                    self.show_ai_telemetry = not self.show_ai_telemetry
                    stat = "ON" if self.show_ai_telemetry else "OFF"
                    self.ui_mgr.add_notification(f"AI TELEMETRY: {stat}", COLOR_CYAN, 1.0)

                elif event.key == pygame.K_r and self.state in (STATE_RACING, STATE_PAUSED, STATE_RESULTS):
                    self.start_race(self.mode)

                # State-specific Keydowns
                if self.state == STATE_MENU:
                    if event.key == pygame.K_UP:
                        self.menu_selected_idx = (self.menu_selected_idx - 1) % len(self.menu_buttons)
                        self.sound_mgr.play("menu_beep")
                    elif event.key == pygame.K_DOWN:
                        self.menu_selected_idx = (self.menu_selected_idx + 1) % len(self.menu_buttons)
                        self.sound_mgr.play("menu_beep")
                    elif event.key == pygame.K_RETURN:
                        self._trigger_menu_action(self.menu_buttons[self.menu_selected_idx].tag)

                elif self.state in (STATE_DIFFICULTY, STATE_HOW_TO_PLAY, STATE_HIGH_SCORES, STATE_AI_INFO):
                    if event.key in (pygame.K_ESCAPE, pygame.K_BACKSPACE, pygame.K_RETURN):
                        self.state = STATE_MENU
                        self.sound_mgr.play("menu_beep")
                    elif self.state == STATE_DIFFICULTY:
                        if event.key == pygame.K_1:
                            self.current_difficulty = DIFFICULTY_EASY
                            self.sound_mgr.play("menu_beep")
                        elif event.key == pygame.K_2:
                            self.current_difficulty = DIFFICULTY_MEDIUM
                            self.sound_mgr.play("menu_beep")
                        elif event.key == pygame.K_3:
                            self.current_difficulty = DIFFICULTY_HARD
                            self.sound_mgr.play("menu_beep")

                elif self.state == STATE_RACING:
                    if event.key in (pygame.K_ESCAPE, pygame.K_p):
                        self.state = STATE_PAUSED
                        self.sound_mgr.play("menu_beep")

                    # Player 1 Lane Change Inputs (Tap A or D)
                    if event.key == pygame.K_a:
                        self.car_p1.change_lane(-1)
                    elif event.key == pygame.K_d:
                        self.car_p1.change_lane(1)

                    # Player 2 Lane Change Inputs in PvP Mode (Tap Left or Right)
                    if self.mode == MODE_PVP:
                        if event.key == pygame.K_LEFT:
                            self.car_p2.change_lane(-1)
                        elif event.key == pygame.K_RIGHT:
                            self.car_p2.change_lane(1)

                elif self.state == STATE_PAUSED:
                    if event.key in (pygame.K_ESCAPE, pygame.K_p):
                        self.state = STATE_RACING
                        self.sound_mgr.play("menu_beep")

            elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                # Mouse Click Handling
                if self.state == STATE_MENU:
                    for btn in self.menu_buttons:
                        if btn.rect.collidepoint(mouse_pos):
                            self.sound_mgr.play("menu_beep")
                            self._trigger_menu_action(btn.tag)
                            break

                elif self.state == STATE_DIFFICULTY:
                    if self.btn_back.rect.collidepoint(mouse_pos):
                        self.sound_mgr.play("menu_beep")
                        self.state = STATE_MENU
                    else:
                        # Check difficulty card clicks
                        card_w = 360
                        start_x = 80
                        gap = 50
                        keys = [DIFFICULTY_EASY, DIFFICULTY_MEDIUM, DIFFICULTY_HARD]
                        for idx, k in enumerate(keys):
                            cx = start_x + idx * (card_w + gap)
                            card_rect = pygame.Rect(cx, 140, card_w, 420)
                            if card_rect.collidepoint(mouse_pos):
                                self.current_difficulty = k
                                self.sound_mgr.play("menu_beep")
                                break

                elif self.state in (STATE_HOW_TO_PLAY, STATE_HIGH_SCORES, STATE_AI_INFO):
                    if self.btn_back.rect.collidepoint(mouse_pos):
                        self.sound_mgr.play("menu_beep")
                        self.state = STATE_MENU

                elif self.state == STATE_PAUSED:
                    for btn in self.pause_buttons:
                        if btn.rect.collidepoint(mouse_pos):
                            self.sound_mgr.play("menu_beep")
                            if btn.tag == "resume":
                                self.state = STATE_RACING
                            elif btn.tag == "restart":
                                self.start_race(self.mode)
                            elif btn.tag == "main_menu":
                                self.state = STATE_MENU
                            break

                elif self.state == STATE_RESULTS:
                    for btn in self.results_buttons:
                        if btn.rect.collidepoint(mouse_pos):
                            self.sound_mgr.play("menu_beep")
                            if btn.tag == "restart":
                                self.start_race(self.mode)
                            elif btn.tag == "main_menu":
                                self.state = STATE_MENU
                            break

    def _trigger_menu_action(self, tag: str) -> None:
        """Handle button click actions from the main menu."""
        if tag == "play_vs_ai":
            self.start_race(MODE_VS_AI)
        elif tag == "play_pvp":
            self.start_race(MODE_PVP)
        elif tag == "difficulty":
            self.state = STATE_DIFFICULTY
        elif tag == "high_scores":
            self.state = STATE_HIGH_SCORES
        elif tag == "ai_info":
            self.state = STATE_AI_INFO
        elif tag == "how_to_play":
            self.state = STATE_HOW_TO_PLAY
        elif tag == "quit":
            self.running = False

    # -------------------------------------------------------------------------
    # UPDATE LOGIC
    # -------------------------------------------------------------------------
    def _update(self, dt: float) -> None:
        self.ui_mgr.update_notifications(dt)

        if self.state == STATE_COUNTDOWN:
            prev_sec = int(self.countdown_timer)
            self.countdown_timer -= dt
            cur_sec = int(self.countdown_timer)

            if cur_sec != prev_sec:
                if cur_sec == 0:
                    self.sound_mgr.play("countdown_high")
                elif cur_sec in (1, 2):
                    self.sound_mgr.play("countdown_low")

            if self.countdown_timer <= 0:
                self.state = STATE_RACING
                self.race_start_time = time.time()

        elif self.state == STATE_RACING:
            self.race_elapsed_time += dt

            # 1. Process continuous keyboard keys (Nitro & Brake)
            keys = pygame.key.get_pressed()

            # Player 1
            if keys[pygame.K_w]:
                if self.car_p1.activate_nitro():
                    if random.random() < 0.05:
                        self.sound_mgr.play("nitro")
            else:
                self.car_p1.deactivate_nitro()

            self.car_p1.set_brake(keys[pygame.K_s])

            # Player 2 (PvP Mode)
            if self.mode == MODE_PVP:
                if keys[pygame.K_UP]:
                    if self.car_p2.activate_nitro():
                        if random.random() < 0.05:
                            self.sound_mgr.play("nitro")
                else:
                    self.car_p2.deactivate_nitro()
                self.car_p2.set_brake(keys[pygame.K_DOWN])

            # AI Opponent (VS_AI Mode)
            elif self.mode == MODE_VS_AI and self.car_p2.is_ai:
                self._update_ai_agent(dt)

            # 2. Update Cars
            self.car_p1.update(dt, self.sound_mgr)
            self.car_p2.update(dt, self.sound_mgr)

            # 3. Update Dual Tracks & Collision Logic
            self.track_mgr.update(dt, self.car_p1, self.car_p2, self.sound_mgr)

            # 4. Check Finish Line Crossing
            total_target_px = RACE_DISTANCE_METERS / METERS_PER_PIXEL

            if self.car_p1.distance_traveled >= total_target_px and not self.car_p1.has_finished:
                self.car_p1.has_finished = True
                self.car_p1.finish_time = self.race_elapsed_time
                self.car_p1.score += 500  # Completion bonus

            if self.car_p2.distance_traveled >= total_target_px and not self.car_p2.has_finished:
                self.car_p2.has_finished = True
                self.car_p2.finish_time = self.race_elapsed_time
                self.car_p2.score += 500  # Completion bonus

            # Conclude race when at least one competitor finishes and other is finished or slightly behind
            if self.car_p1.has_finished or self.car_p2.has_finished:
                self._check_race_finish()

    def _update_ai_agent(self, dt: float) -> None:
        """Execute Q-learning decision making and explainability tracking for AI racer."""
        diff_info = DIFFICULTY_PROFILES[self.current_difficulty]
        reaction_interval = diff_info["reaction_interval"]

        self.ai_decision_timer += dt
        if self.ai_decision_timer >= reaction_interval:
            self.ai_decision_timer = 0.0

            # 1. Sense Environment Radar (Distances to nearest obstacles in Left, Mid, Right)
            dl, dm, dr = self.track_mgr.get_track_radar(track_id=2, car=self.car_p2)

            # 2. Encode Discrete State
            state_key = self.ai_agent.encode_state(self.car_p2.target_lane, dl, dm, dr)

            # 3. Action Selection (Tabular Q-Learning with difficulty calibrated epsilon)
            chosen_action = self.ai_agent.choose_action(
                state_key,
                epsilon=diff_info["epsilon_randomness"],
            )

            # 4. Execute Physical Movement
            if chosen_action == ACTION_LEFT:
                self.car_p2.change_lane(-1)
            elif chosen_action == ACTION_RIGHT:
                self.car_p2.change_lane(1)
            # If ACTION_STAY, maintain lane

            # 5. Nitro Policy: engage boost if clear path ahead & meter meets threshold
            radar = [dl, dm, dr]
            curr_lane_dist = radar[self.car_p2.target_lane]
            if curr_lane_dist > 450.0 and self.car_p2.nitro_meter >= diff_info["nitro_threshold"]:
                if random.random() < diff_info["nitro_chance"]:
                    self.car_p2.activate_nitro()
            else:
                if curr_lane_dist <= 260.0:
                    self.car_p2.deactivate_nitro()

            # 6. Generate Academic Explainability Telemetry
            self.ai_latest_telemetry = self.ai_agent.explain_decision(state_key, chosen_action)

    def _check_race_finish(self) -> None:
        """Determine race winner, record persistent statistics, and switch to results screen."""
        total_px = RACE_DISTANCE_METERS / METERS_PER_PIXEL

        # If both finished or one is sufficiently past the finish
        if (self.car_p1.has_finished and self.car_p2.has_finished) or \
           (self.car_p1.distance_traveled > total_px + 300.0) or \
           (self.car_p2.distance_traveled > total_px + 300.0):

            # Ensure finish times recorded
            if not self.car_p1.has_finished:
                self.car_p1.finish_time = self.race_elapsed_time
            if not self.car_p2.has_finished:
                self.car_p2.finish_time = self.race_elapsed_time

            # Determine Winner (Lowest finish time or higher distance)
            if self.car_p1.has_finished and self.car_p2.has_finished:
                if abs(self.car_p1.finish_time - self.car_p2.finish_time) < 0.05:
                    self.winner_name = "TIE RACE"
                elif self.car_p1.finish_time < self.car_p2.finish_time:
                    self.winner_name = self.car_p1.name
                else:
                    self.winner_name = self.car_p2.name
            elif self.car_p1.has_finished:
                self.winner_name = self.car_p1.name
            else:
                self.winner_name = self.car_p2.name

            # Award winner bonus
            if self.winner_name == self.car_p1.name:
                self.car_p1.score += 800
            elif self.winner_name == self.car_p2.name:
                self.car_p2.score += 800

            # Record in persistent scoreboard
            self.scoreboard.record_race_result(
                mode=self.mode,
                p1_stats={
                    "name": self.car_p1.name,
                    "score": self.car_p1.score,
                    "finish_time": self.car_p1.finish_time,
                    "is_ai": False,
                },
                p2_stats={
                    "name": self.car_p2.name,
                    "score": self.car_p2.score,
                    "finish_time": self.car_p2.finish_time,
                    "is_ai": self.car_p2.is_ai,
                },
                winner_name=self.winner_name,
                difficulty=self.current_difficulty if self.mode == MODE_VS_AI else None,
            )

            self.sound_mgr.play("victory")
            self.state = STATE_RESULTS

    # -------------------------------------------------------------------------
    # RENDERING
    # -------------------------------------------------------------------------
    def _render(self) -> None:
        mouse_pos = pygame.mouse.get_pos()

        if self.state == STATE_MENU:
            # Update mouse hover
            for btn in self.menu_buttons:
                btn.update(mouse_pos)
            self.ui_mgr.render_main_menu(
                self.screen,
                self.menu_buttons,
                self.menu_selected_idx,
                self.current_difficulty,
            )

        elif self.state == STATE_DIFFICULTY:
            self.ui_mgr.render_difficulty_screen(self.screen, self.current_difficulty, self.btn_back)

        elif self.state == STATE_HOW_TO_PLAY:
            self.ui_mgr.render_how_to_play(self.screen, self.btn_back)

        elif self.state == STATE_HIGH_SCORES:
            self.ui_mgr.render_high_scores(
                self.screen,
                self.scoreboard.get_leaderboard(),
                self.scoreboard.get_tallies(),
                self.btn_back,
            )

        elif self.state == STATE_AI_INFO:
            self.ui_mgr.render_ai_info(self.screen, self.btn_back)

        elif self.state in (STATE_COUNTDOWN, STATE_RACING, STATE_PAUSED):
            # 1. Render Tracks, Borders & Obstacles
            self.track_mgr.render(self.screen, self.car_p1, self.car_p2)

            # 2. Render Both Cars
            self.car_p1.render(self.screen)
            self.car_p2.render(self.screen)

            # 3. Render HUD & Speedometers
            self.ui_mgr.render_in_race_hud(
                self.screen,
                car_p1=self.car_p1,
                car_p2=self.car_p2,
                race_distance=RACE_DISTANCE_METERS,
                ai_telemetry=self.ai_latest_telemetry,
                show_telemetry=self.show_ai_telemetry and (self.mode == MODE_VS_AI),
            )

            # 4. Countdown Overlay
            if self.state == STATE_COUNTDOWN:
                self.ui_mgr.render_countdown(self.screen, self.countdown_timer)

            # 5. Pause Menu Overlay
            elif self.state == STATE_PAUSED:
                self.ui_mgr.render_pause_menu(self.screen, self.pause_buttons)

        elif self.state == STATE_RESULTS:
            self.ui_mgr.render_results_screen(
                self.screen,
                winner_name=self.winner_name,
                car_p1=self.car_p1,
                car_p2=self.car_p2,
                buttons=self.results_buttons,
            )
