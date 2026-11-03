"""
Game Mode 2: Race vs AI Pathfinder (100% Preserved & Enhanced).
Player races against an AI solving the maze towards its opposite exit.
Backed by the fixed optimal A* solver with non-blocking step dispatching.
"""

import time
import math
import pygame
from typing import Any, List, Tuple, Optional
from ..game_state import BaseGameMode
from config import PYGAME_COLORS
from core.solvers import solve_path
from game.audio import SoundFX

class RaceVsAIMode(BaseGameMode):
    """Mode 2: Race vs AI Pathfinder."""

    def __init__(self, viewport_size=(740, 640), grid_size=20, generator_algo="kruskal", user_data=None, ai_solver="astar"):
        super().__init__(viewport_size, grid_size, generator_algo, user_data)
        self.mode_id = 2

        self.player_pos = (0, 0)
        self.player_goal = (grid_size - 1, grid_size - 1)

        self.ai_pos = (grid_size - 1, grid_size - 1)
        self.ai_goal = (0, 0)

        # Precompute AI optimal trajectory
        ai_res = solve_path(ai_solver, self.ai_pos, self.ai_goal, self.maze)
        self.ai_path: List[Tuple[int, int]] = ai_res.path[1:] if ai_res.path else []
        self.ai_step_idx = 0

        # AI step pacing based on grid size
        self.ai_cooldown = max(0.12, min(0.35, grid_size * 0.012))
        self.last_ai_step_time = time.perf_counter()

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

                    if self.player_pos == self.player_goal:
                        self.game_over = True
                        self.won = True
                        self.game_over_title = "VICTORY! YOU OUTPACED THE AI!"
                        self.game_over_sub = f"Time: {self.elapsed_time:.2f}s | Steps: {self.steps_taken}"
                        self.particles.emit_victory(self.viewport_width, self.viewport_height)
                        SoundFX.play_victory()
                        self.save_score_if_needed(mode_id=2)

        return True

    def update(self, dt: float):
        super().update(dt)
        if self.game_over:
            return

        curr_time = time.perf_counter()
        if curr_time - self.last_ai_step_time >= self.ai_cooldown:
            if self.ai_step_idx < len(self.ai_path):
                self.ai_pos = self.ai_path[self.ai_step_idx]
                self.ai_step_idx += 1
                self.last_ai_step_time = curr_time

                if self.ai_pos == self.ai_goal:
                    self.game_over = True
                    self.won = False
                    self.game_over_title = "DEFEAT! THE AI WON THE RACE!"
                    self.game_over_sub = "The heuristic pathfinder reached the exit first."
                    SoundFX.play_defeat()

    def render(self, surface: pygame.Surface):
        self.draw_maze(surface)

        # Exits
        self.draw_goal(surface, self.player_goal, PYGAME_COLORS["player1"])
        self.draw_goal(surface, self.ai_goal, PYGAME_COLORS["computer"])

        # Entities
        self.draw_entity(surface, self.player_pos, PYGAME_COLORS["player1"])
        self.draw_entity(surface, self.ai_pos, PYGAME_COLORS["computer"])

        self.particles.update_and_draw(surface)

        # Telemetry
        p_dist = math.hypot(self.player_pos[0] - self.player_goal[0], self.player_pos[1] - self.player_goal[1])
        ai_dist = math.hypot(self.ai_pos[0] - self.ai_goal[0], self.ai_pos[1] - self.ai_goal[1])

        telemetry = {
            "mode_id": 2,
            "mode_badge": "MODE 2: RACE",
            "mode_name": "Racer vs AI Pathfinder",
            "elapsed_time": self.elapsed_time,
            "steps": self.steps_taken,
            "p_dist_to_goal": p_dist,
            "ai_dist_to_goal": ai_dist
        }
        self.hud.draw_hud(surface, telemetry)

        if self.game_over:
            self.hud.draw_game_over(surface, self.won, self.game_over_title, self.game_over_sub)
