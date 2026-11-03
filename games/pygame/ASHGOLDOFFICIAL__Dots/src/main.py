import pygame
import sys
from game_round import GameRound
from screens import IntroScreen, GameFieldScreen, GameOverScreen
from settings import *


class Game:
    def __init__(self):
        pygame.init()
        pygame.display.set_caption('Dots')
        self.screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT), pygame.SCALED)
        self.clock = pygame.time.Clock()

        self.current_screen = IntroScreen()
        self.game_round = None
        self.winner_name = None

        self.round_count = 1

    def run(self):
        while True:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    pygame.quit()
                    sys.exit()
                elif event.type == pygame.MOUSEBUTTONUP and event.button == 1:
                    if self.current_screen:
                        self.current_screen.click(event.pos)

            if type(self.current_screen).__name__ == 'IntroScreen':
                self.current_screen.draw()
                if self.current_screen.stop:
                    self.current_screen = None

            elif not self.game_round:
                print('\n\n\n=== ROUND', self.round_count, '===')
                self.game_round = GameRound()
                self.current_screen = GameFieldScreen(self.game_round)
                self.current_screen.draw()

            elif self.game_round and not self.winner_name:
                turn_made, self.winner_name = self.game_round.run()
                if turn_made:
                    self.current_screen.update()

            elif self.winner_name and type(self.current_screen).__name__ == 'GameFieldScreen':
                self.current_screen = GameOverScreen(self.winner_name)

            elif type(self.current_screen).__name__ == 'GameOverScreen':
                self.current_screen.draw()
                if self.current_screen.stop:
                    self.current_screen = None
                    self.winner_name = None
                    self.game_round = None
                    self.round_count += 1

            pygame.display.update()
            self.clock.tick(FPS)


if __name__ == "__main__":
    game = Game()
    game.run()
