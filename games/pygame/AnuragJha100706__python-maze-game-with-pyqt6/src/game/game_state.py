"""
Base Game Mode Architecture.
Calculates dynamic grid viewport dimensions, renders mazes with antialiased borders,
manages entities and particle systems, and provides state interfaces for Modes 0-4.
"""

import time
import math
import pygame
from typing import Dict, Any, Tuple, Optional, Set
from core.graph import Graph
from core.maze_generators import generate_maze
from .character import Character
from .hud import GameHUD
from .particles import ParticleSystem
from config import PYGAME_COLORS, GAME_MODES
from database.db_manager import DatabaseManager

Point = Tuple[int, int]

class BaseGameMode:
    """Base class for all 5 preserved game modes."""

    def __init__(
        self,
        viewport_size: Tuple[int, int] = (740, 640),
        grid_size: int = 20,
        generator_algo: str = "kruskal",
        user_data: Optional[Dict[str, Any]] = None
    ):
        self.viewport_width, self.viewport_height = viewport_size
        self.grid_size = grid_size
        self.generator_algo = generator_algo
        self.user_data = user_data or {"id": 1, "username": "Guest"}
        self.db = DatabaseManager()

        # HUD and Particle Systems
        self.hud_height = 60
        self.hud = GameHUD(self.viewport_width, self.hud_height)
        self.particles = ParticleSystem()

        # Timing and state
        self.start_time = time.perf_counter()
        self.elapsed_time = 0.0
        self.game_over = False
        self.won = False
        self.steps_taken = 0
        self.game_over_title = ""
        self.game_over_sub = ""
        self.score_saved = False

        # Compute optimal cell sizing to fit maze viewport
        avail_w = self.viewport_width - 40
        avail_h = self.viewport_height - self.hud_height - 30
        avail_dim = min(avail_w, avail_h)
        cell_pitch = max(6, (avail_dim - 10) // grid_size)
        self.border_width = max(2, cell_pitch // 6)
        self.side_length = max(4, cell_pitch - self.border_width)

        # Maze Origin (centered in viewport above HUD)
        total_maze_w = grid_size * (self.side_length + self.border_width) + self.border_width
        total_maze_h = grid_size * (self.side_length + self.border_width) + self.border_width
        self.origin_x = max(20, (self.viewport_width - total_maze_w) // 2)
        self.origin_y = max(15, (self.viewport_height - self.hud_height - total_maze_h) // 2)

        # Generate Maze Graph
        self.maze: Graph = generate_maze(self.generator_algo, self.grid_size, self.grid_size)
        self.vertices: Set[Point] = self.maze.get_vertices()

        # Default start and goal
        self.start_pos: Point = (0, 0)
        self.goal_pos: Point = (grid_size - 1, grid_size - 1)

    def grid_to_pixel(self, pt: Point) -> Tuple[int, int]:
        """Converts grid coordinate (x, y) to viewport pixel (px, py)."""
        px = self.origin_x + self.border_width + (self.side_length + self.border_width) * pt[0]
        py = self.origin_y + self.border_width + (self.side_length + self.border_width) * pt[1]
        return px, py

    def draw_maze(self, surface: pygame.Surface):
        """Renders the maze background, passages, and goal threshold."""
        surface.fill(PYGAME_COLORS["background"])

        passage_col = PYGAME_COLORS["passage"]
        wall_col = PYGAME_COLORS["wall"]

        # Background grid bounding box
        total_w = self.grid_size * (self.side_length + self.border_width) + self.border_width
        total_h = self.grid_size * (self.side_length + self.border_width) + self.border_width
        maze_rect = pygame.Rect(self.origin_x, self.origin_y, total_w, total_h)
        
        # Subtle outer glow & border
        pygame.draw.rect(surface, (18, 24, 38), maze_rect.inflate(8, 8), border_radius=6)
        pygame.draw.rect(surface, (0, 240, 255), maze_rect.inflate(8, 8), width=1, border_radius=6)
        pygame.draw.rect(surface, wall_col, maze_rect, border_radius=4)

        # Tactical corner brackets around arena
        c_len = 14
        mr = maze_rect.inflate(8, 8)
        pygame.draw.line(surface, (0, 240, 255), (mr.x, mr.y), (mr.x + c_len, mr.y), 2)
        pygame.draw.line(surface, (0, 240, 255), (mr.x, mr.y), (mr.x, mr.y + c_len), 2)
        pygame.draw.line(surface, (0, 240, 255), (mr.right - c_len, mr.bottom), (mr.right, mr.bottom), 2)
        pygame.draw.line(surface, (0, 240, 255), (mr.right, mr.bottom - c_len), (mr.right, mr.bottom), 2)

        # Draw cell passages and edge corridors
        s = self.side_length
        b = self.border_width
        ox = self.origin_x
        oy = self.origin_y

        for x in range(self.grid_size):
            for y in range(self.grid_size):
                cell_rect = pygame.Rect(ox + b + (s + b) * x, oy + b + (s + b) * y, s, s)
                pygame.draw.rect(surface, passage_col, cell_rect)

                # Right corridor
                if x < self.grid_size - 1 and self.maze.is_edge(((x, y), (x + 1, y))):
                    corr = pygame.Rect(ox + b + (s + b) * x + s, oy + b + (s + b) * y, b, s)
                    pygame.draw.rect(surface, passage_col, corr)

                # Down corridor
                if y < self.grid_size - 1 and self.maze.is_edge(((x, y), (x, y + 1))):
                    corr = pygame.Rect(ox + b + (s + b) * x, oy + b + (s + b) * y + s, s, b)
                    pygame.draw.rect(surface, passage_col, corr)

    def draw_goal(self, surface: pygame.Surface, pos: Point, color: Tuple[int, int, int] = PYGAME_COLORS["goal"]):
        """Draws exit portal with pulsating concentric neon rings."""
        px, py = self.grid_to_pixel(pos)
        s = self.side_length
        center_x = px + s // 2
        center_y = py + s // 2

        # Pulsating outer halo
        pulse = 0.5 + 0.5 * math.sin(time.time() * 5.0)
        glow_r = int((s // 2) * (1.1 + 0.2 * pulse))
        
        glow_surf = pygame.Surface((s * 3, s * 3), pygame.SRCALPHA)
        pygame.draw.circle(glow_surf, (*color, int(50 * pulse)), (s * 3 // 2, s * 3 // 2), glow_r)
        surface.blit(glow_surf, (center_x - s * 3 // 2, center_y - s * 3 // 2))

        # Main Portal Cell
        r = pygame.Rect(px, py, s, s)
        pygame.draw.rect(surface, color, r, border_radius=4)
        pygame.draw.rect(surface, (255, 255, 255), r, width=1, border_radius=4)

        # Concentric Core
        inner_r = max(2, s // 4)
        pygame.draw.circle(surface, (255, 255, 255), (center_x, center_y), inner_r)

    def draw_entity(self, surface: pygame.Surface, pos: Point, color: Tuple[int, int, int]):
        """Draws a player or AI character with dynamic glow halo and core."""
        px, py = self.grid_to_pixel(pos)
        s = self.side_length
        center_x = px + s // 2
        center_y = py + s // 2

        # Soft outer glow
        glow_surf = pygame.Surface((s * 2, s * 2), pygame.SRCALPHA)
        pygame.draw.circle(glow_surf, (*color, 65), (s, s), s // 2 + 2)
        surface.blit(glow_surf, (center_x - s, center_y - s))

        # Entity Base
        r = pygame.Rect(px + 1, py + 1, s - 2, s - 2)
        pygame.draw.rect(surface, color, r, border_radius=3)

        # Bright Inner Core
        core_r = max(2, s // 4)
        pygame.draw.circle(surface, (255, 255, 255), (center_x, center_y), core_r)

    def save_score_if_needed(self, mode_id: int):
        """Saves game completion to SQLite."""
        if not self.score_saved and self.won and self.user_data:
            self.score_saved = True
            uid = self.user_data.get("id", 1)
            self.db.save_gameplay_record(
                user_id=uid,
                mode_id=mode_id,
                grid_size=self.grid_size,
                time_seconds=round(self.elapsed_time, 2),
                steps_taken=self.steps_taken,
                generator_algorithm=self.generator_algo,
                won=True
            )

    def handle_input(self, keys: Any, dt: float) -> bool:
        """Subclasses override to process keyboard events."""
        return True

    def update(self, dt: float):
        """Subclasses override to update game logic."""
        if not self.game_over:
            self.elapsed_time = time.perf_counter() - self.start_time

    def render(self, surface: pygame.Surface):
        """Subclasses override to render the scene."""
        pass
