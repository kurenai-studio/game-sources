import pygame


class TiltEffect:
    """Shakes the game view vertically with a fading sequence of offsets."""

    OFFSET_VALUES = (-25, 20, -15, 14, -9, 9, -6, 5, -5, 4, -5, 4, -4, 3, -4, 3, -3, 2, -3, 2, -2, 2, -2,
                     1, -1, 1, -1, 1, -1, 1, -1, 1)
    BASE_CURSOR_INCREMENT = 0.75

    def __init__(self) -> None:
        self._is_enabled = False
        self._cursor = 0
        self._cursor_increment = self.BASE_CURSOR_INCREMENT

    def enable(self, cursor_increment: float | None = None) -> None:
        """
        Start the effect.

        :param cursor_increment: speed of moving through the offsets; the base speed when None
        """
        self._is_enabled = True

        if cursor_increment is not None:
            self._cursor_increment = cursor_increment
        else:
            self._cursor_increment = self.BASE_CURSOR_INCREMENT

    def next_offset(self) -> pygame.math.Vector2 | None:
        """
        Return the offset of the current frame and move to the next one.
        The effect turns itself off after the last offset.

        :return: vertical offset of the game view, or None when the effect is not running
        """
        offset = None

        if self._is_enabled:
            if self._cursor < len(self.OFFSET_VALUES):
                offset = pygame.math.Vector2()
                offset.y = self.OFFSET_VALUES[int(self._cursor)]
                self._cursor += self._cursor_increment
            else:
                self._is_enabled = False
                self._cursor = 0

        return offset
