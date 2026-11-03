"""
Game Mode 0: Solo Time Trial (100% Preserved & Enhanced).
Player navigates from start corner to opposite exit against the clock.
Features live millisecond digital stopwatch, step counter, path optimality scoring,
and celebratory particle victory fireworks.
"""

import time
import random
import pygame
from typing import Tuple, Dict, Any, Optional
from ..game_state import BaseGameMode
from config import PYGAME_COLORS
from core.solvers import solve_path
from game.audio import SoundFX

class SoloTimeTrialMode(BaseGameMode):
    """Mode 0: Solo Time Trial."""

    def __init__(self, viewport_size=(740, 640), grid_size=20, generator_algo="kruskal", user_data=None):
        super().__init__(viewport_size, grid_size, generator_algo, user_data)
        self.mode_id = 0
        
        # Random start & end corner placement (preserving original 4-corner mechanic)
        corners = [
            ((0, 0), (grid_size - 1, grid_size - 1)),
            ((grid_size - 1, grid_size - 1), (0, 0)),
            ((0, grid_size - 1), (grid_size - 1, 0)),
            ((grid_size - 1, 0), (0, grid_size - 1))
        ]
        self.start_pos, self.goal_pos = random.choice(corners)
        self.player_pos = self.start_pos

        # Calculate theoretical shortest path for optimality ratio
        opt_res = solve_path("astar", self.start_pos, self.goal_pos, self.maze)
        self.optimal_steps = opt_res.path_length

        self.move_cooldown = 0.08  # Responsive 80ms repeat rate
        self.last_move_time = 0.0

    def handle_input(self, keys: Any, dt: float, input_mgr: Optional[Any] = None) -> bool:
        if self.game_over:
            return True

        curr_time = time.perf_counter()
        if curr_time - self.last_move_time < self.move_cooldown:
            return True

        dx, dy = 0, 0
        if input_mgr:
            dx, dy = input_mgr.get_movement(player=0)
            if dx != 0 and dy != 0:
                dy = 0  # Prioritize primary axis for crisp grid movement

        if dx == 0 and dy == 0:
            if keys[pygame.K_RIGHT] or keys[pygame.K_d]:
                dx, dy = 1, 0
            elif keys[pygame.K_LEFT] or keys[pygame.K_a]:
                dx, dy = -1, 0
            elif keys[pygame.K_UP] or keys[pygame.K_w]:
                dx, dy = 0, -1
            elif keys[pygame.K_DOWN] or keys[pygame.K_s]:
                dx, dy = 0, 1

        if dx != 0 or dy != 0:
            target = (self.player_pos[0] + dx, self.player_pos[1] + dy)
            if self.maze.is_edge((self.player_pos, target)):
                self.player_pos = target
                self.steps_taken += 1
                self.last_move_time = curr_time
                px, py = self.grid_to_pixel(self.player_pos)
                self.particles.emit_dust(px + self.side_length / 2, py + self.side_length / 2)

                SoundFX.play_step()

                # Check victory
                if self.player_pos == self.goal_pos:
                    self.game_over = True
                    self.won = True
                    self.elapsed_time = curr_time - self.start_time
                    ratio = (self.optimal_steps / max(1, self.steps_taken)) * 100.0
                    self.game_over_title = "MAZE CLEARED!"
                    self.game_over_sub = f"Time: {self.elapsed_time:.2f}s | Steps: {self.steps_taken} (Optimality: {ratio:.0f}%)"
                    self.particles.emit_victory(self.viewport_width, self.viewport_height)
                    SoundFX.play_victory()
                    self.save_score_if_needed(mode_id=0)

        return True

    def render(self, surface: pygame.Surface):
        self.draw_maze(surface)
        self.draw_goal(surface, self.goal_pos, PYGAME_COLORS["goal"])
        self.draw_entity(surface, self.player_pos, PYGAME_COLORS["player1"])
        self.particles.update_and_draw(surface)

        # Telemetry
        telemetry = {
            "mode_id": 0,
            "mode_badge": "MODE 0: SOLO",
            "mode_name": "Time Trial Challenge",
            "elapsed_time": self.elapsed_time,
            "steps": self.steps_taken
        }
        self.hud.draw_hud(surface, telemetry)

        if self.game_over:
            self.hud.draw_game_over(surface, self.won, self.game_over_title, self.game_over_sub)
