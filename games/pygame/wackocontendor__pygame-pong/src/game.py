import pygame
import random
import math
from functions import Player, Ball

pygame.init()
screen = pygame.display.set_mode((1280, 720))
pygame.display.set_caption("Pong Replica")
clock = pygame.time.Clock()
running = True
colour_theme = "white"
game_speeds = {
    "slow": 5,
    "medium": 8,
    "fast": 12,
    "lightning": 20
}
game_speed = game_speeds["fast"]

SCR_HEIGHT = screen.get_height()
SCR_WIDTH = screen.get_width()

bat_1 = Player(colour_theme, game_speed, 0, SCR_HEIGHT / 2)
bat_2 = Player(colour_theme, game_speed, SCR_WIDTH - 10, SCR_HEIGHT / 2)
ball = Ball(colour_theme, game_speed, SCR_WIDTH / 2, SCR_HEIGHT / 2)

angle_bound = int(math.degrees(math.atan(SCR_HEIGHT / 2 / SCR_WIDTH / 2)))
ball_angle = random.choice([0, 180]) + random.randint(angle_bound, 2 * angle_bound)
x_multiplier = 1
y_multiplier = 1

while running:

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    screen.fill("black")
    screen.blit(bat_1.surface, bat_1.pos)
    screen.blit(bat_2.surface, bat_2.pos)
    screen.blit(ball.surface, ball.pos)  

    keys = pygame.key.get_pressed()
    if keys[pygame.K_w]:
        bat_1.move(up=True)
    if keys[pygame.K_s]:
        bat_1.move(down=True)
    if keys[pygame.K_UP]:
        bat_2.move(up=True)
    if keys[pygame.K_DOWN]:
        bat_2.move(down=True)

    ball.move(x_multiplier, y_multiplier, ball_angle)
    if ball.pos.x < 0:
        x_multiplier = 1
    if ball.pos.x > SCR_WIDTH:
        x_multiplier = -1
    if ball.pos.y < 0:
        y_multiplier = 1
    if ball.pos.y > SCR_HEIGHT:
        y_multiplier = -1

    pygame.display.update()

    dt = clock.tick(60)

pygame.quit()