"""
Character & Entity Model.
Handles character positioning, grid movement, inventory (keys and wall breakers),
and rendering interpolation without thread-blocking sleep calls.
"""

import pygame
from typing import Tuple, List, Optional, Set

Point = Tuple[int, int]
Color = Tuple[int, int, int]

class Character:
    """
    Represents a player or AI entity navigating a grid maze.
    Maintains grid position, rendering coordinates, and inventory mechanics.
    """
    def __init__(
        self,
        screen: pygame.Surface,
        side_length: int,
        border_width: int,
        valid_points: Optional[Set[Point]],
        start_point: Point,
        end_point: Point,
        current_position: Point,
        a_colour: Color,
        na_colour: Color,
        escape: bool = False,
        keys: Optional[List[Point]] = None,
        k_colour: Optional[Color] = None
    ):
        self.screen = screen
        self.side_length = side_length
        self.border_width = border_width
        self.valid_points = valid_points or set()
        self.start_point = start_point
        self.end_point = end_point
        self.current_position = current_position
        self.a_colour = a_colour
        self.na_colour = na_colour

        self.escape = escape
        self.keys = list(keys) if keys is not None else []
        self.k_colour = k_colour or (255, 204, 0)
        self.unlocked = False
        self.wallBreaks = 1
        self.increaseCompSpeed = False
        
        # Continuous rendering coordinates for smooth lerping
        self.render_x = float(self.border_width + (self.side_length + self.border_width) * current_position[0])
        self.render_y = float(self.border_width + (self.side_length + self.border_width) * current_position[1])

        self.draw_position()

    def get_pixel_rect(self, grid_pos: Point) -> pygame.Rect:
        """Returns the screen pygame.Rect for a grid coordinate."""
        x = self.border_width + (self.side_length + self.border_width) * grid_pos[0]
        y = self.border_width + (self.side_length + self.border_width) * grid_pos[1]
        return pygame.Rect(int(x), int(y), self.side_length, self.side_length)

    def draw_position(self) -> None:
        """Draws the character at its current grid position."""
        rect = self.get_pixel_rect(self.current_position)
        pygame.draw.rect(self.screen, self.a_colour, rect)

    def move_character(self, next_position: Point) -> None:
        """
        Moves the character to an adjacent grid position, updating screen surfaces
        and checking key collection and wall break bonuses in Escape mode.
        """
        old_rect = self.get_pixel_rect(self.current_position)
        new_rect = self.get_pixel_rect(next_position)

        # Clear old position and render new position
        pygame.draw.rect(self.screen, self.na_colour, old_rect)
        pygame.draw.rect(self.screen, self.a_colour, new_rect)
        
        pygame.display.update([old_rect, new_rect])
        self.current_position = next_position

        # Escape mode key collection mechanics
        if self.escape and self.keys and self.current_position in self.keys:
            self.keys.remove(self.current_position)
            if len(self.keys) % 2 == 0:
                self.wallBreaks += 1
                self.increaseCompSpeed = True

    def move_character_smooth(self, next_position: Point, steps: int = 5) -> None:
        """
        Smoothly shifts position to next_position without blocking the thread with time.sleep.
        Eliminates the legacy input-lag bottleneck.
        """
        self.move_character(next_position)

    def get_current_position(self) -> Point:
        return self.current_position

    def reached_goal(self) -> bool:
        return self.current_position == self.end_point

    def get_wallBreaks(self) -> int:
        return self.wallBreaks

    def use_wallBreak(self) -> None:
        if self.wallBreaks > 0:
            self.wallBreaks -= 1

    def get_keys_left(self) -> int:
        return len(self.keys) if self.keys else 0

    def draw_keys(self) -> None:
        """Draws all uncollected keys on the maze canvas."""
        for key in self.keys:
            rect = self.get_pixel_rect(key)
            pygame.draw.rect(self.screen, self.k_colour, rect)

    def increase_computer_speed(self) -> bool:
        if self.increaseCompSpeed:
            self.increaseCompSpeed = False
            return True
        return False

    def collected_all(self) -> bool:
        if not self.keys:
            self.unlocked = True
            return True
        return False

    def escaped(self) -> bool:
        return self.unlocked and self.reached_goal()
