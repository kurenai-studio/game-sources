import pygame
import pytest

from settings import Settings
from src.panels.loading_page import LoadingPage


# LoadingPage converts its image in the constructor, so a display mode must be set around every test.
@pytest.fixture(autouse=True)
def pygame_display(monkeypatch):
    monkeypatch.setenv('SDL_VIDEODRIVER', 'dummy')
    pygame.init()
    pygame.display.set_mode((1, 1))
    yield
    pygame.quit()


@pytest.fixture
def screen():
    return pygame.Surface((Settings.WIDTH, Settings.HEIGHT))


class TestLoadingPage:
    def test_scales_image_to_final_size(self, screen):
        loading_page = LoadingPage(screen)

        assert loading_page.background_image.get_size() == LoadingPage.IMAGE_SIZE

    def test_centers_image_on_screen(self, screen):
        loading_page = LoadingPage(screen)

        assert loading_page.image_position == (
            (Settings.WIDTH - LoadingPage.IMAGE_SIZE[0]) // 2,
            (Settings.HEIGHT - LoadingPage.IMAGE_SIZE[1]) // 2,
        )

    def test_draw_blits_image_at_its_position(self, screen):
        loading_page = LoadingPage(screen)
        screen.fill((0, 0, 0))
        loading_page.background_image.fill((255, 0, 0))

        loading_page.draw()

        image_center = (loading_page.image_position[0] + LoadingPage.IMAGE_SIZE[0] // 2,
                        loading_page.image_position[1] + LoadingPage.IMAGE_SIZE[1] // 2)
        assert screen.get_at(image_center)[:3] == (255, 0, 0)
