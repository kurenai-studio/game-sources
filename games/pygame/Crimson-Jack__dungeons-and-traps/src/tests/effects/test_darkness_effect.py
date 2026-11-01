import pygame
import pytest

from src.effects.darkness_effect import DarknessEffect
from src.enums.lighting_status import LightingStatus

SCREEN_SIZE = (600, 600)
CENTER = (300, 300)
WHITE = (255, 255, 255)


def draw_darkness(lighting_status, light_center=CENTER, screen=None, darkness_effect=None):
    # A given darkness_effect must be created with the given screen
    screen = screen or pygame.Surface(SCREEN_SIZE)
    darkness_effect = darkness_effect or DarknessEffect(screen, [0, 0], SCREEN_SIZE)
    screen.fill(WHITE)
    darkness_effect.draw(lighting_status, light_center)
    return screen


def get_brightness(screen, point):
    # Darkness is black with transparency over a white screen, so all color channels are equal
    return screen.get_at(point)[0]


def white_covered_with_black(alpha):
    return 255 * (255 - alpha) / 255


class TestDarknessEffect:
    def test_light_on_draws_nothing(self):
        screen = draw_darkness(LightingStatus.LIGHT_ON)

        assert get_brightness(screen, CENTER) == 255
        assert get_brightness(screen, (0, 0)) == 255

    def test_twilight_leaves_half_lit_circle_around_player(self):
        screen = draw_darkness(LightingStatus.TWILIGHT)

        ((twilight_radius, twilight_alpha),) = DarknessEffect.LIGHT_CIRCLES[LightingStatus.TWILIGHT]
        assert get_brightness(screen, CENTER) == pytest.approx(white_covered_with_black(twilight_alpha), abs=2)
        # Just outside the twilight radius
        assert get_brightness(screen, (CENTER[0] + twilight_radius + 5, CENTER[1])) == 0

    def test_torchlight_darkens_towards_the_edge(self):
        screen = draw_darkness(LightingStatus.TORCHLIGHT)

        # Between the radii of the smallest (200) and the next (220) circle the alpha is 50
        assert get_brightness(screen, CENTER) == 255
        assert get_brightness(screen, (CENTER[0] + 210, CENTER[1])) == pytest.approx(white_covered_with_black(50),
                                                                                     abs=2)
        # Outside the largest circle (280)
        assert get_brightness(screen, (CENTER[0] + 290, CENTER[1])) == 0

    def test_next_frame_clears_previous_light_circle(self):
        screen = pygame.Surface(SCREEN_SIZE)
        darkness_effect = DarknessEffect(screen, [0, 0], SCREEN_SIZE)
        first_center = (150, 300)
        second_center = (450, 300)
        draw_darkness(LightingStatus.TWILIGHT, first_center, screen, darkness_effect)

        draw_darkness(LightingStatus.TWILIGHT, second_center, screen, darkness_effect)

        assert get_brightness(screen, first_center) == 0
        assert get_brightness(screen, second_center) > 0
