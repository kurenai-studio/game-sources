import pygame
import math
from game import Game

pygame.init()

game = Game()

pygame.display.set_caption("Shooter")
screen = pygame.display.set_mode((1000, 600))
background = pygame.image.load('assets/bg.jpg')

banner = pygame.image.load('assets/banner.png')
banner = pygame.transform.scale(banner, (400, 400))
banner_rect = banner.get_rect()
banner_rect.x = math.ceil(screen.get_width() / 4) 

play_button = pygame.image.load('assets/button.png')
play_button = pygame.transform.scale(play_button, (370, 150))
play_button_rect = play_button.get_rect()
play_button_rect.x = math.ceil(screen.get_width() / 3.33 - 15)
play_button_rect.y = math.ceil(screen.get_height() / 1.5 - 50)


running = True

while running:
    screen.blit(background, (0, -400))
    
    if game.is_playing:
        game.update(screen)
    else:
        screen.blit(play_button, play_button_rect)
        screen.blit(banner, banner_rect)

    pygame.display.flip()
    for event in pygame.event.get():

        if event.type == pygame.QUIT:
            running = False
            pygame.quit()

        elif event.type == pygame.KEYDOWN:
            game.pressed[event.key] = True

            if event.key == pygame.K_SPACE:
                game.player.launch_projectile()

        elif event.type == pygame.KEYUP:
            game.pressed[event.key] = False

        elif event.type == pygame.MOUSEBUTTONDOWN:
            if play_button_rect.collidepoint(event.pos):
                game.start()
