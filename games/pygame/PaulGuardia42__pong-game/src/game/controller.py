import sys

import pygame

from .model import PongModel
from .view import PongView


class PongController:
    def __init__(self):
        pygame.init()
        pygame.display.set_caption("Pong")
        self.screen = pygame.display.set_mode((960, 540))
        self.clock = pygame.time.Clock()
        self.model = PongModel()
        self.view = PongView(self.screen)

    def handle_events(self) -> bool:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return False

            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    if self.model.state == "playing":
                        self.model.state = "menu"
                        self.model.mode = None
                    elif self.model.state == "game_over":
                        self.model.state = "menu"
                        self.model.mode = None
                    elif self.model.state == "menu":
                        return False

                if self.model.state == "menu":
                    if event.key == pygame.K_1:
                        self.model.start_game("single")
                    elif event.key == pygame.K_2:
                        self.model.start_game("two_player")
                    elif event.key == pygame.K_q:
                        return False

                elif self.model.state == "game_over":
                    if event.key in (pygame.K_RETURN, pygame.K_SPACE):
                        self.model.state = "menu"
                    elif event.key == pygame.K_1:
                        self.model.start_game("single")
                    elif event.key == pygame.K_2:
                        self.model.start_game("two_player")

        return True

    def update(self, dt: float) -> None:
        if self.model.state == "playing":
            keys = pygame.key.get_pressed()
            self.model.update(dt, keys)

    def run(self) -> None:
        while True:
            dt = self.clock.tick(60) / 1000.0
            running = self.handle_events()
            if not running:
                pygame.quit()
                sys.exit()

            self.update(dt)
            self.view.render(self.model)
            pygame.display.flip()
