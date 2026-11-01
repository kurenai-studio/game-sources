import pygame
import pytest

from src.bar import Bar
from src.color_set import ColorSet

BAR_COLOR = (255, 0, 0)
BACKGROUND_COLOR = (0, 0, 255)
TEXT_COLOR = (255, 255, 255)
SURFACE_SIZE = (200, 40)


# Bars with text load a font, which needs the pygame font module
@pytest.fixture(autouse=True)
def initialize_fonts():
    pygame.font.init()
    yield
    pygame.font.quit()


def create_bar(position=(0, 0), draw_text=False):
    return Bar(position=position, width=100, height=20, bar_colors=ColorSet([((0, 100), BAR_COLOR)]),
               background_color=BACKGROUND_COLOR, text='Energy' if draw_text else None, text_color=TEXT_COLOR)


def draw_on_new_surface(bar, value, offset=None):
    surface = pygame.Surface(SURFACE_SIZE)
    bar.draw(surface, value, 100, offset)
    return surface


def surfaces_are_equal(first_surface, second_surface):
    return pygame.image.tobytes(first_surface, 'RGB') == pygame.image.tobytes(second_surface, 'RGB')


class TestBarGeometry:
    def test_properties_return_constructor_values(self):
        bar = create_bar(position=(5, 7))
        assert (bar.position, bar.width, bar.height) == ((5, 7), 100, 20)

    def test_change_position_moves_bar(self):
        bar = create_bar()

        bar.change_position((30, 10))

        assert bar.position == (30, 10)


class TestBarDraw:
    def test_bar_fills_part_of_background_matching_value(self):
        surface = draw_on_new_surface(create_bar(), 50)

        # Half of the 100 pixel wide bar, shrunk by 4 pixels on each side
        assert surface.get_at((10, 10))[:3] == BAR_COLOR
        assert surface.get_at((45, 10))[:3] == BAR_COLOR
        assert surface.get_at((48, 10))[:3] == BACKGROUND_COLOR
        assert surface.get_at((80, 10))[:3] == BACKGROUND_COLOR
        assert surface.get_at((2, 10))[:3] == BACKGROUND_COLOR

    def test_offset_moves_bar(self):
        surface = draw_on_new_surface(create_bar(), 50, pygame.math.Vector2(30, 0))

        assert surface.get_at((32, 10))[:3] == BACKGROUND_COLOR
        assert surface.get_at((40, 10))[:3] == BAR_COLOR

    def test_text_is_not_drawn_below_25_percent(self):
        assert surfaces_are_equal(draw_on_new_surface(create_bar(draw_text=True), 20),
                                  draw_on_new_surface(create_bar(draw_text=False), 20))

    def test_text_is_drawn_from_25_percent(self):
        assert not surfaces_are_equal(draw_on_new_surface(create_bar(draw_text=True), 80),
                                      draw_on_new_surface(create_bar(draw_text=False), 80))

    def test_text_moves_with_offset(self):
        bar_drawn_with_offset = draw_on_new_surface(create_bar(draw_text=True), 80, pygame.math.Vector2(30, 0))
        bar_placed_further = draw_on_new_surface(create_bar(position=(30, 0), draw_text=True), 80)

        assert surfaces_are_equal(bar_drawn_with_offset, bar_placed_further)
