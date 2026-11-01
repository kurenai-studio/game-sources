import pygame


class BlastEffect:
    """
    A rectangle that grows from the center of the game surface until it reaches the maximum size, then disappears.
    """

    def __init__(self, game_surface: pygame.Surface, steps: int, color: tuple[int, int, int],
                 max_size: tuple[int, int]) -> None:
        """
        Create a hidden blast effect; it is started with run().

        :param game_surface: game surface the rectangle is drawn on
        :param steps: number of updates the rectangle needs to reach the maximum size
        :param color: color of the rectangle
        :param max_size: maximum size of the rectangle
        """
        self._game_surface = game_surface
        self._width = max_size[0]
        self._height = max_size[1]
        self._step_x = self._width / steps
        self._step_y = self._height / steps
        self._color = color
        self._visible = False
        self._base_rectangle = pygame.rect.Rect(0, 0, 0, 0)
        self._rectangle = pygame.rect.Rect(0, 0, 0, 0)
        self._counter = 1

    def run(self) -> None:
        """Start the blast from the smallest rectangle in the center."""
        self._reset()
        self._visible = True

    def update(self) -> None:
        """Grow the rectangle by one step; hide the effect once it reaches the maximum size."""
        if self._visible:
            if self._rectangle.width < self._width and self._rectangle.height < self._height:
                self._rectangle = self._base_rectangle.inflate(self._step_x * self._counter,
                                                               self._step_y * self._counter)
                self._counter += 1
            else:
                self._stop()

    def draw(self) -> None:
        """Draw the rectangle while the effect is visible."""
        if self._visible:
            pygame.draw.rect(self._game_surface, self._color, self._rectangle)

    def _reset(self) -> None:
        self._counter = 1

        # Set base rectangle properties
        self._base_rectangle.width = int(self._step_x)
        self._base_rectangle.height = int(self._step_y)
        top_left_x = int(self._width / 2 - self._step_x / 2)
        top_left_y = int(self._height / 2 - self._step_y / 2)
        self._base_rectangle.topleft = top_left_x, top_left_y

        # Create a copy
        self._rectangle = pygame.rect.Rect(self._base_rectangle)

    def _stop(self) -> None:
        self._visible = False
