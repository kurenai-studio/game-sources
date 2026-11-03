"""
Game Mode 4: Escape Heist (100% Preserved & Enhanced).
Player collects 8 keys to unlock the exit portal while evading pursuit.
Pressing SPACE uses Wall Breakers to blast through walls, dynamically re-routing graph paths.
"""

import time
import random
import math
import pygame
from typing import Any, List, Set, Tuple, Optional
from ..game_state import BaseGameMode
from config import PYGAME_COLORS
from core.solvers import solve_path
from game.audio import SoundFX

Point = Tuple[int, int]

class EscapeHeistMode(BaseGameMode):
    """Mode 4: Escape Heist with Wall Breakers and Unlock Keys."""

    def __init__(self, viewport_size=(740, 640), grid_size=20, generator_algo="kruskal", user_data=None):
        super().__init__(viewport_size, grid_size, generator_algo, user_data)
        self.mode_id = 4

        self.player_pos: Point = (0, 0)
        self.exit_pos: Point = (grid_size - 1, grid_size - 1)
        self.ai_pos: Point = (0, 0)

        # Robust 2D sampling of 8 unique interior key coordinates
        interior_cells = [
            (x, y) for x in range(1, grid_size - 1)
            for y in range(1, grid_size - 1)
            if (x, y) not in (self.player_pos, self.exit_pos)
        ]
        num_keys = min(8, len(interior_cells))
        self.keys: Set[Point] = set(random.sample(interior_cells, num_keys))
        self.total_keys = num_keys
        self.keys_collected = 0

        self.wall_breaks = 1
        self.unlocked = False

        self.activation_delay = 3.0
        self.ai_activated = False
        self.ai_cooldown = max(0.15, min(0.35, grid_size * 0.015))
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
                
                # Check grid bounds
                if 0 <= nxt[0] < self.grid_size and 0 <= nxt[1] < self.grid_size:
                    # Normal passage move
                    if self.maze.is_edge((self.player_pos, nxt)):
                        self.player_pos = nxt
                        self.steps_taken += 1
                        self.last_player_move = curr_time
                        self._on_player_moved()
                    # Wall Breaker move (Spacebar or Controller BOMB action pressed against wall)
                    elif (keys[pygame.K_SPACE] or (input_mgr and input_mgr.is_action_pressed("BOMB", 0))) and self.wall_breaks > 0:
                        self.maze.add_bidirectional_edge(self.player_pos, nxt)
                        self.wall_breaks -= 1
                        self.player_pos = nxt
                        self.steps_taken += 1
                        self.last_player_move = curr_time
                        
                        # Wall blast explosion effect
                        px, py = self.grid_to_pixel(self.player_pos)
                        self.particles.emit_explosion(px + self.side_length / 2, py + self.side_length / 2, count=35)
                        SoundFX.play_explosion()
                        self._on_player_moved()

        return True

    def _on_player_moved(self):
        px, py = self.grid_to_pixel(self.player_pos)
        self.particles.emit_dust(px + self.side_length / 2, py + self.side_length / 2, (0, 240, 255))
        SoundFX.play_step()

        # Check key collection
        if self.player_pos in self.keys:
            self.keys.remove(self.player_pos)
            self.keys_collected += 1
            self.particles.emit_key_sparkle(px + self.side_length / 2, py + self.side_length / 2)
            SoundFX.play_key()

            # Every 2 keys awards +1 wall breaker and increases AI speed
            if self.keys_collected % 2 == 0:
                self.wall_breaks += 1
                self.ai_cooldown = max(0.08, self.ai_cooldown * 0.85)

            if len(self.keys) == 0:
                self.unlocked = True

        # Check exit
        if self.player_pos == self.exit_pos and self.unlocked:
            self.game_over = True
            self.won = True
            self.game_over_title = "HEIST SUCCESSFUL! YOU ESCAPED!"
            self.game_over_sub = f"All {self.total_keys} keys gathered in {self.elapsed_time:.2f}s with {self.steps_taken} steps."
            self.particles.emit_victory(self.viewport_width, self.viewport_height)
            SoundFX.play_victory()
            self.save_score_if_needed(mode_id=4)

    def update(self, dt: float):
        super().update(dt)
        if self.game_over:
            return

        curr_time = time.perf_counter()
        if not self.ai_activated:
            if self.elapsed_time >= self.activation_delay:
                self.ai_activated = True
                self.last_ai_step = curr_time
            return

        if curr_time - self.last_ai_step >= self.ai_cooldown:
            path_res = solve_path("astar", self.ai_pos, self.player_pos, self.maze)
            if len(path_res.path) >= 2:
                self.ai_pos = path_res.path[1]
                self.last_ai_step = curr_time

                # Proximity alert if close
                dist = math.hypot(self.player_pos[0] - self.ai_pos[0], self.player_pos[1] - self.ai_pos[1])
                if dist <= 4.0:
                    SoundFX.play_radar()

                if self.ai_pos == self.player_pos:
                    self.game_over = True
                    self.won = False
                    self.game_over_title = "BUSTED BY SECURITY!"
                    self.game_over_sub = "Captured before unlocking the exit."
                    SoundFX.play_defeat()

    def render(self, surface: pygame.Surface):
        self.draw_maze(surface)

        # Draw Keys (Gold)
        for key in self.keys:
            px, py = self.grid_to_pixel(key)
            k_rect = pygame.Rect(px + 1, py + 1, self.side_length - 2, self.side_length - 2)
            pygame.draw.rect(surface, PYGAME_COLORS["key"], k_rect, border_radius=3)

        # Draw Exit (Red if locked, Emerald if unlocked)
        exit_color = PYGAME_COLORS["goal"] if self.unlocked else PYGAME_COLORS["computer"]
        self.draw_goal(surface, self.exit_pos, exit_color)

        # Draw Player & AI
        self.draw_entity(surface, self.player_pos, PYGAME_COLORS["player1"])
        if not self.ai_activated:
            if int(time.time() * 4) % 2 == 0:
                self.draw_entity(surface, self.ai_pos, (180, 180, 180))
        else:
            self.draw_entity(surface, self.ai_pos, PYGAME_COLORS["computer"])

        self.particles.update_and_draw(surface)

        # Telemetry
        ai_dist = math.hypot(self.player_pos[0] - self.ai_pos[0], self.player_pos[1] - self.ai_pos[1])

        telemetry = {
            "mode_id": 4,
            "mode_badge": "MODE 4: ESCAPE",
            "mode_name": "Heist & Wall Demolition",
            "elapsed_time": self.elapsed_time,
            "steps": self.steps_taken,
            "keys_left": len(self.keys),
            "wall_breaks": self.wall_breaks,
            "ai_distance": ai_dist
        }
        self.hud.draw_hud(surface, telemetry)

        if self.game_over:
            self.hud.draw_game_over(surface, self.won, self.game_over_title, self.game_over_sub)
