import sys

import pygame
from pygame.math import Vector2

from core import Color, Configs, Game, show_splash_screen

SCREEN_UPDATE = pygame.USEREVENT
pygame.time.set_timer(SCREEN_UPDATE, 150)

KEY_DIRECTIONS = {
    pygame.K_UP: Vector2(0, -1),
    pygame.K_DOWN: Vector2(0, 1),
    pygame.K_LEFT: Vector2(-1, 0),
    pygame.K_RIGHT: Vector2(1, 0),
}

# Init Game class
main_game = Game(Configs)


# Show at start
show_splash_screen()
################
## Game Loop ###
################
while True:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            pygame.quit()
            sys.exit()

        if event.type == SCREEN_UPDATE:
            main_game.update()

        if event.type == pygame.KEYDOWN and event.key in KEY_DIRECTIONS:
            main_game.snake.change_direction(KEY_DIRECTIONS[event.key])

    Configs.screen.fill(Color.WALL_PRIMARY)
    main_game.draw_elements()
    pygame.display.update()
    Configs.clock.tick(60)
