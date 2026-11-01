import math
import pygame

from src.game_helper import GameHelper


class ExplodeEffect:
    """Rings of an explosion that grow from a position until they reach the maximum size, then disappear."""

    # Rings drawn inside the explosion rectangle: (inflate_x, inflate_y, line_width),
    # given for the base tile size and scaled to the current tile size
    RINGS = ((-7, -33, 1), (-33, -7, 1), (-40, -87, 4), (-87, -40, 4), (-93, -133, 7), (-133, -93, 7))

    def __init__(self, game_surface: pygame.Surface, steps: int, color: tuple[int, int, int],
                 max_size: tuple[int, int]) -> None:
        """
        Create a hidden explosion effect; it is started with run().

        :param game_surface: game surface the rings are drawn on
        :param steps: number of updates the rings need to reach the maximum size
        :param color: color of the rings
        :param max_size: maximum size of the explosion rectangle
        """
        self._game_surface = game_surface
        self._width = max_size[0]
        self._height = max_size[1]
        self._step_x = self._width / steps
        self._step_y = self._height / steps
        self._color = color
        self._rings = [(round(GameHelper.multiply_by_tile_size_ratio(inflate_x)),
                        round(GameHelper.multiply_by_tile_size_ratio(inflate_y)),
                        round(GameHelper.multiply_by_tile_size_ratio(line_width, 1)))
                       for inflate_x, inflate_y, line_width in self.RINGS]
        self._visible = False
        self._base_rectangle = pygame.rect.Rect(0, 0, 0, 0)
        self._rectangle = pygame.rect.Rect(0, 0, 0, 0)
        self._counter = 1

    def run(self, position: tuple[int, int]) -> None:
        """
        Start the explosion from the smallest rings centered at the position.

        :param position: center of the explosion on the game surface
        """
        self._reset(position)
        self._visible = True

    def update(self) -> None:
        """Grow the rings by one step; hide the effect once they reach the maximum size."""
        if self._visible:
            if self._rectangle.width < self._width and self._rectangle.height < self._height:
                self._rectangle = self._base_rectangle.inflate(self._step_x * self._counter,
                                                               self._step_y * self._counter)
                self._counter += 1
            else:
                self._stop()

    def draw(self) -> None:
        """Draw the rings while the effect is visible."""
        if self._visible:
            for inflate_x, inflate_y, line_width in self._rings:
                pygame.draw.arc(self._game_surface, self._color, self._rectangle.inflate(inflate_x, inflate_y),
                                0, 2 * math.pi, line_width)

    def _reset(self, position: tuple[int, int]) -> None:
        self._counter = 1

        # Set base rectangle properties
        self._base_rectangle.width = int(self._step_x)
        self._base_rectangle.height = int(self._step_y)
        top_left_x = int(position[0] - self._step_x / 2)
        top_left_y = int(position[1] - self._step_y / 2)
        self._base_rectangle.topleft = top_left_x, top_left_y

        # Create a copy
        self._rectangle = pygame.rect.Rect(self._base_rectangle)

    def _stop(self) -> None:
        self._visible = False
