"""
Game Mode 3: Chase Survival (100% Preserved & Enhanced).
Player starts at start point; Hunter AI activates after a 3-second delay.
Upgraded with dynamic shortest-path pursuit calculations and proximity radar alerts.
"""

import time
import math
import pygame
from typing import Any, Optional
from ..game_state import BaseGameMode
from config import PYGAME_COLORS
from core.solvers import solve_path
from game.audio import SoundFX

class ChaseSurvivalMode(BaseGameMode):
    """Mode 3: Chase Survival vs Hunter AI."""

    def __init__(self, viewport_size=(740, 640), grid_size=20, generator_algo="kruskal", user_data=None):
        super().__init__(viewport_size, grid_size, generator_algo, user_data)
        self.mode_id = 3

        self.player_pos = (0, 0)
        self.exit_pos = (grid_size - 1, grid_size - 1)
        self.ai_pos = (0, 0)

        # 3.0 second initial grace period before hunter AI starts pursuing
        self.activation_delay = 3.0
        self.ai_activated = False
        self.ai_cooldown = max(0.12, min(0.30, grid_size * 0.010))
        self.last_ai_step = 0.0

        self.player_cooldown = 0.08
        self.last_player_move = 0.0

    def handle_input(self, keys: Any, dt: float, input_mgr: Optional[Any] = None) -> bool:
        if self.game_over:
            return True

        curr_time = time.perf_counter()
        if curr_time - self.last_player_move >= self.player_cooldown:
            dx, dy = 0, 0
            if input_mgr:
                dx, dy = input_mgr.get_movement(player=0)
                if dx != 0 and dy != 0: dy = 0
            if dx == 0 and dy == 0:
                if keys[pygame.K_RIGHT] or keys[pygame.K_d]: dx, dy = 1, 0
                elif keys[pygame.K_LEFT] or keys[pygame.K_a]: dx, dy = -1, 0
                elif keys[pygame.K_UP] or keys[pygame.K_w]: dx, dy = 0, -1
                elif keys[pygame.K_DOWN] or keys[pygame.K_s]: dx, dy = 0, 1

            if dx != 0 or dy != 0:
                nxt = (self.player_pos[0] + dx, self.player_pos[1] + dy)
                if self.maze.is_edge((self.player_pos, nxt)):
                    self.player_pos = nxt
                    self.steps_taken += 1
                    self.last_player_move = curr_time
                    px, py = self.grid_to_pixel(self.player_pos)
                    self.particles.emit_dust(px + self.side_length / 2, py + self.side_length / 2, (0, 240, 255))
                    SoundFX.play_step()

                    if self.player_pos == self.exit_pos:
                        self.game_over = True
                        self.won = True
                        self.game_over_title = "SURVIVED! YOU ESCAPED THE HUNTER!"
                        self.game_over_sub = f"Evaded pursuit in {self.elapsed_time:.2f}s with {self.steps_taken} steps."
                        self.particles.emit_victory(self.viewport_width, self.viewport_height)
                        SoundFX.play_victory()
                        self.save_score_if_needed(mode_id=3)

        return True

    def update(self, dt: float):
        super().update(dt)
        if self.game_over:
            return

        curr_time = time.perf_counter()

        # Check activation countdown
        if not self.ai_activated:
            if self.elapsed_time >= self.activation_delay:
                self.ai_activated = True
                self.last_ai_step = curr_time
            return

        # Active pursuit via dynamic A* intercept calculation
        if curr_time - self.last_ai_step >= self.ai_cooldown:
            path_res = solve_path("astar", self.ai_pos, self.player_pos, self.maze)
            if len(path_res.path) >= 2:
                self.ai_pos = path_res.path[1]
                self.last_ai_step = curr_time

                # Proximity alert if close
                dist = math.hypot(self.ai_pos[0] - self.player_pos[0], self.ai_pos[1] - self.player_pos[1])
                if dist <= 4.0:
                    SoundFX.play_radar()

                # Check if caught
                if self.ai_pos == self.player_pos:
                    self.game_over = True
                    self.won = False
                    self.game_over_title = "BUSTED! THE HUNTER CAUGHT YOU!"
                    self.game_over_sub = f"Captured after {self.elapsed_time:.2f}s."
                    SoundFX.play_defeat()

    def render(self, surface: pygame.Surface):
        self.draw_maze(surface)
        self.draw_goal(surface, self.exit_pos, PYGAME_COLORS["goal"])

        # Entities
        self.draw_entity(surface, self.player_pos, PYGAME_COLORS["player1"])

        # Draw AI (blinks during grace period)
        if not self.ai_activated:
            if int(time.time() * 4) % 2 == 0:
                self.draw_entity(surface, self.ai_pos, (180, 180, 180))
        else:
            self.draw_entity(surface, self.ai_pos, PYGAME_COLORS["computer"])

        self.particles.update_and_draw(surface)

        # Telemetry
        ai_dist = math.hypot(self.player_pos[0] - self.ai_pos[0], self.player_pos[1] - self.ai_pos[1])

        telemetry = {
            "mode_id": 3,
            "mode_badge": "MODE 3: CHASE",
            "mode_name": "Hunter Survival",
            "elapsed_time": self.elapsed_time,
            "steps": self.steps_taken,
            "ai_distance": ai_dist
        }
        self.hud.draw_hud(surface, telemetry)

        if self.game_over:
            self.hud.draw_game_over(surface, self.won, self.game_over_title, self.game_over_sub)
