import pygame

from settings import Settings
from src.color_set import ColorSet


class Bar:
    """
    Horizontal bar that shows a value as a part of its maximum, colored by the percentage,
    with an optional outline, background and text.
    """

    def __init__(self, position: tuple[float, float], width: float, height: float, bar_colors: ColorSet,
                 outline_color: tuple[int, int, int] | None = None,
                 background_color: tuple[int, int, int] | None = None,
                 text: str | None = None, text_color: tuple[int, int, int] = Settings.BAR_TEXT_COLOR) -> None:
        """
        Store the look of the bar. A part of the bar is drawn only when its color is given.

        :param position: top left position of the bar
        :param width: width of the full bar
        :param height: height of the bar
        :param bar_colors: colors of the bar for percentage ranges
        :param outline_color: color of the outline, or None when no outline is drawn
        :param background_color: color of the background of the full bar, or None when no background is drawn
        :param text: text drawn before the percentage, or None when no text is drawn
        :param text_color: color of the text
        """
        self._position = position
        self._width = width
        self._height = height
        self._bar_colors = bar_colors
        self._outline_color = outline_color
        self._background_color = background_color
        self._text = text
        self._text_color = text_color

        # Font of the text; bars without text need none
        self._basic_font = pygame.font.Font('font/silkscreen/silkscreen-regular.ttf', 18) if text is not None else None

    @property
    def position(self) -> tuple[float, float]:
        """Top left position of the bar."""
        return self._position

    @property
    def width(self) -> float:
        """Width of the full bar."""
        return self._width

    @property
    def height(self) -> float:
        """Height of the bar."""
        return self._height

    def change_position(self, position: tuple[float, float]) -> None:
        """
        Move the bar.

        :param position: new top left position of the bar
        """
        self._position = position

    def draw(self, surface: pygame.Surface, value: float, max_value: float,
             offset: pygame.math.Vector2 | None = None) -> None:
        """
        Draw the bar filled to value / max_value.
        The text is drawn from 25% up and shortened to the percentage when it does not fit.

        :param surface: surface the bar is drawn on
        :param value: current amount shown by the bar
        :param max_value: amount that fills the whole bar
        :param offset: camera offset added to the position; no offset when None
        """
        if offset is None:
            offset = pygame.math.Vector2()
        offset_position = self._position + offset

        # Create bar rectangle
        bar_width = (self._width * value) / max_value
        bar_rectangle = pygame.rect.Rect(offset_position, (bar_width, self._height)).inflate(-8, -8)

        # Calculate percent
        percent = int(100 * value / max_value)

        # Draw background
        if self._background_color is not None:
            background = pygame.rect.Rect(offset_position, (self._width, self._height))
            pygame.draw.rect(surface, self._background_color, background)

        # Draw bar
        pygame.draw.rect(surface, self._bar_colors.get_color(percent), bar_rectangle)

        # Blit the text
        if self._basic_font is not None and percent >= 25:
            # Create text
            rendered_text = self._basic_font.render(f'{self._text} {percent}%', True, self._text_color)

            # Set text position
            text_rect = rendered_text.get_rect()
            rendered_text_position = [offset_position[0] + bar_width // 2 - text_rect.width // 2,
                                      offset_position[1] + self._height // 2 - text_rect.height // 2]

            # Change text and adjust position if it's too long
            if rendered_text.get_rect().width + 50 > bar_width:
                rendered_text = self._basic_font.render(f'{percent}%', True, self._text_color)
                text_rect = rendered_text.get_rect()
                rendered_text_position[0] = offset_position[0] + bar_width // 2 - text_rect.width // 2

            surface.blit(rendered_text, rendered_text_position)

        # Draw outline
        if self._outline_color is not None:
            outline = pygame.rect.Rect(offset_position, (self._width, self._height))
            pygame.draw.rect(surface, self._outline_color, outline, 1)
