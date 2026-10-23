import pytest
import pygame

@pytest.fixture(scope="session", autouse=True)
def pygame_initialize():
    pygame.init()
    pygame.display.set_mode((800, 600))
    yield
    pygame.quit()
