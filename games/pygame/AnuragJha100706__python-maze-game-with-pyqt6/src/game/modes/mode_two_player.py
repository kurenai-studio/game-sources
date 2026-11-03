"""
Game Mode 1: Two Player PvP (100% Preserved & Enhanced).
Player 1 (Arrow keys, Cyan) vs Player 2 (WASD keys, Purple).
Symmetric synchronized polling ensures zero latency discrepancy.
Dual telemetry HUD tracks distance-to-goal for each racer in real time.
"""

import time
import math
import pygame
from typing import Any, Optional
from ..game_state import BaseGameMode
from config import PYGAME_COLORS
from game.audio import SoundFX

class TwoPlayerMode(BaseGameMode):
    """Mode 1: Two Player Local PvP Racing."""

    def __init__(self, viewport_size=(740, 640), grid_size=20, generator_algo="kruskal", user_data=None):
        super().__init__(viewport_size, grid_size, generator_algo, user_data)
        self.mode_id = 1

        # Opposite corner starts
        self.p1_pos = (0, 0)
        self.p1_goal = (grid_size - 1, grid_size - 1)

        self.p2_pos = (grid_size - 1, grid_size - 1)
        self.p2_goal = (0, 0)

        self.p1_cooldown = 0.08
        self.p2_cooldown = 0.08
        self.last_p1_time = 0.0
        self.last_p2_time = 0.0

        self.p1_steps = 0
        self.p2_steps = 0
        self.winner = 0

    def handle_input(self, keys: Any, dt: float, input_mgr: Optional[Any] = None) -> bool:
        if self.game_over:
            return True

        curr_time = time.perf_counter()

        # Player 1 (Arrow Keys or Gamepad 0)
        if curr_time - self.last_p1_time >= self.p1_cooldown:
            dx, dy = 0, 0
            if input_mgr and input_mgr.is_controller_connected():
                dx, dy = input_mgr.get_movement(player=0)
                if dx != 0 and dy != 0: dy = 0
            if dx == 0 and dy == 0:
                if keys[pygame.K_RIGHT]: dx, dy = 1, 0
                elif keys[pygame.K_LEFT]: dx, dy = -1, 0
                elif keys[pygame.K_UP]: dx, dy = 0, -1
                elif keys[pygame.K_DOWN]: dx, dy = 0, 1

            if dx != 0 or dy != 0:
                nxt = (self.p1_pos[0] + dx, self.p1_pos[1] + dy)
                if self.maze.is_edge((self.p1_pos, nxt)):
                    self.p1_pos = nxt
                    self.p1_steps += 1
                    self.last_p1_time = curr_time
                    px, py = self.grid_to_pixel(self.p1_pos)
                    self.particles.emit_dust(px + self.side_length / 2, py + self.side_length / 2, (0, 240, 255))
                    SoundFX.play_step()

                    if self.p1_pos == self.p1_goal:
                        self.game_over = True
                        self.won = True
                        self.winner = 1
                        self.game_over_title = "PLAYER 1 WINS!"
                        self.game_over_sub = f"P1 reached the exit in {self.elapsed_time:.2f}s ({self.p1_steps} steps)!"
                        self.particles.emit_victory(self.viewport_width, self.viewport_height)
                        SoundFX.play_victory()
                        self.steps_taken = self.p1_steps
                        self.save_score_if_needed(mode_id=1)

        # Player 2 (WASD Keys or Gamepad 1)
        if not self.game_over and curr_time - self.last_p2_time >= self.p2_cooldown:
            dx2, dy2 = 0, 0
            if input_mgr and len(getattr(input_mgr, "controllers", {})) > 1:
                dx2, dy2 = input_mgr.get_movement(player=1)
                if dx2 != 0 and dy2 != 0: dy2 = 0
            if dx2 == 0 and dy2 == 0:
                if keys[pygame.K_d]: dx2, dy2 = 1, 0
                elif keys[pygame.K_a]: dx2, dy2 = -1, 0
                elif keys[pygame.K_w]: dx2, dy2 = 0, -1
                elif keys[pygame.K_s]: dx2, dy2 = 0, 1

            if dx2 != 0 or dy2 != 0:
                nxt2 = (self.p2_pos[0] + dx2, self.p2_pos[1] + dy2)
                if self.maze.is_edge((self.p2_pos, nxt2)):
                    self.p2_pos = nxt2
                    self.p2_steps += 1
                    self.last_p2_time = curr_time
                    px, py = self.grid_to_pixel(self.p2_pos)
                    self.particles.emit_dust(px + self.side_length / 2, py + self.side_length / 2, (123, 44, 191))
                    SoundFX.play_step()

                    if self.p2_pos == self.p2_goal:
                        self.game_over = True
                        self.won = True
                        self.winner = 2
                        self.game_over_title = "PLAYER 2 WINS!"
                        self.game_over_sub = f"P2 reached the exit in {self.elapsed_time:.2f}s ({self.p2_steps} steps)!"
                        self.particles.emit_victory(self.viewport_width, self.viewport_height)
                        SoundFX.play_victory()
                        self.steps_taken = self.p2_steps
                        self.save_score_if_needed(mode_id=1)

        return True

    def render(self, surface: pygame.Surface):
        self.draw_maze(surface)

        # Draw Exits (P1 goal Cyan, P2 goal Purple)
        self.draw_goal(surface, self.p1_goal, PYGAME_COLORS["player1"])
        self.draw_goal(surface, self.p2_goal, PYGAME_COLORS["player2"])

        # Draw Players
        self.draw_entity(surface, self.p1_pos, PYGAME_COLORS["player1"])
        self.draw_entity(surface, self.p2_pos, PYGAME_COLORS["player2"])

        self.particles.update_and_draw(surface)

        # Telemetry
        p1_dist = math.hypot(self.p1_pos[0] - self.p1_goal[0], self.p1_pos[1] - self.p1_goal[1])
        p2_dist = math.hypot(self.p2_pos[0] - self.p2_goal[0], self.p2_pos[1] - self.p2_goal[1])

        telemetry = {
            "mode_id": 1,
            "mode_badge": "MODE 1: PVP",
            "mode_name": "Two-Player Dual Race",
            "elapsed_time": self.elapsed_time,
            "steps": self.p1_steps + self.p2_steps,
            "p1_dist": p1_dist,
            "p2_dist": p2_dist
        }
        self.hud.draw_hud(surface, telemetry)

        if self.game_over:
            self.hud.draw_game_over(surface, True, self.game_over_title, self.game_over_sub)
