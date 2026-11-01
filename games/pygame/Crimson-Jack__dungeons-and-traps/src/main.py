import pygame
import sys
from src.game import Game


if __name__ == '__main__':
    # Initialize and run the game
    game = Game()
    game.run()
    pygame.quit()
    sys.exit()
