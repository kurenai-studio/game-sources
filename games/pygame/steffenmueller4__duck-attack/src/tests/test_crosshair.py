import pygame

from duck_attack import settings
from duck_attack.crosshair import make_crosshair_cursor
from duck_attack.game import Game


def test_crosshair_cursor_is_scaled_with_hotspot_on_red_dot():
    pygame.init()
    pygame.display.set_mode((100, 100))
    cursor = make_crosshair_cursor()
    pygame.quit()

    surface = cursor.data[1]
    assert surface.get_size() == (settings.CROSSHAIR_SIZE, settings.CROSSHAIR_SIZE)
    x, y = cursor.data[0]
    assert abs(x - settings.CROSSHAIR_SIZE / 2) <= 2
    assert y < settings.CROSSHAIR_SIZE / 2


def test_game_uses_crosshair_cursor():
    game = Game()
    assert pygame.mouse.get_cursor().type == "color"
    game.run(max_frames=1)
