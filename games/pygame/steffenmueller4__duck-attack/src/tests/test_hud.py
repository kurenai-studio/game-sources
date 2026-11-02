import pygame

from duck_attack import settings
from duck_attack.hud import Hud


def _changed_pixels(screen, background):
    return [
        (x, y)
        for x in range(0, settings.SCREEN_WIDTH, 2)
        for y in range(0, 120, 2)
        if screen.get_at((x, y))[:3] != background
    ]


def test_score_top_right_and_timer_top_left():
    pygame.init()
    screen = pygame.Surface((settings.SCREEN_WIDTH, settings.SCREEN_HEIGHT))
    screen.fill((0, 0, 255))
    Hud().draw(screen, score=120, time_left=42.3)
    changed = _changed_pixels(screen, (0, 0, 255))
    pygame.quit()

    margin = settings.HUD_MARGIN
    left = [x for x, _ in changed if x < settings.SCREEN_WIDTH / 2]
    right = [x for x, _ in changed if x > settings.SCREEN_WIDTH / 2]
    assert left and right
    assert min(left) >= margin
    assert max(right) <= settings.SCREEN_WIDTH - margin
    assert min(y for _, y in changed) >= margin


def test_timer_turns_red_near_the_end():
    pygame.init()
    hud = Hud()
    screen = pygame.Surface((settings.SCREEN_WIDTH, settings.SCREEN_HEIGHT))
    hud.draw(screen, 0, settings.TIME_WARNING + 5)
    assert hud.time_label._key[1] == settings.TEXT_COLOR
    hud.draw(screen, 0, settings.TIME_WARNING - 1)
    assert hud.time_label._key[1] == settings.WARNING_COLOR
    pygame.quit()
