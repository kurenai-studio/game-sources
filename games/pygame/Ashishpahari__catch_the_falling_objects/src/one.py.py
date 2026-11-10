#Name:Ashish Pahari 
#ERP=:RU-26-02321
#Problem Statement:62: Catch the Falling Objects Game
"""
Catch the Falling Objects

Run game:  python one.py
Run tests: python one.py --test

Controls:
LEFT arrow  - Move basket left by 10 pixels
RIGHT arrow - Move basket right by 10 pixels
ESC         - Quit game
"""



import pygame
import random
import sys

# Initialize Pygame
pygame.init()

# Screen settings
WIDTH = 500
HEIGHT = 600

screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Catch the Falling Objects")

# Colors
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
BLUE = (0, 100, 255)
RED = (255, 0, 0)
GREEN = (0, 180, 0)

# Basket settings
basket_width = 80
basket_height = 20
basket_x = 210
basket_y = 560
basket_speed = 350

# Ball settings
ball_width = 20
ball_height = 20
ball_speed = 5

# Score and lives
score = 0
lives = 3

# Fonts
font = pygame.font.SysFont(None, 35)
big_font = pygame.font.SysFont(None, 60)

# Create one ball
def create_ball():
    return {
        "x": random.randint(0, WIDTH - ball_width),
        "y": 0
    }

# Only one ball at a time
ball = create_ball()

# Clock
clock = pygame.time.Clock()

# Game status
running = True
game_over = False

# Main game loop
while running:

    # Frame time
    dt = clock.tick(60) / 1000

    # Handle events
    for event in pygame.event.get():

        if event.type == pygame.QUIT:
            running = False

        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False

    if not game_over:

        # Smooth basket movement
        keys = pygame.key.get_pressed()

        if keys[pygame.K_LEFT]:
            basket_x -= basket_speed * dt

        if keys[pygame.K_RIGHT]:
            basket_x += basket_speed * dt

        # Keep basket inside screen
        basket_x = max(
            0,
            min(basket_x, WIDTH - basket_width)
        )

        # Basket rectangle
        basket = pygame.Rect(
            round(basket_x),
            basket_y,
            basket_width,
            basket_height
        )

        # Move one falling ball
        ball["y"] += ball_speed

        falling_ball = pygame.Rect(
            ball["x"],
            ball["y"],
            ball_width,
            ball_height
        )

        # Check collision
        if basket.colliderect(falling_ball):

            score += 1

            # Create next ball after catching
            ball = create_ball()

        # Check missed ball
        elif ball["y"] > HEIGHT:

            lives -= 1

            if lives <= 0:
                lives = 0
                game_over = True

            else:
                # Create next ball after missing
                ball = create_ball()

    # Background
    screen.fill(WHITE)

    # Draw basket
    pygame.draw.rect(
        screen,
        BLUE,
        (
            round(basket_x),
            basket_y,
            basket_width,
            basket_height
        ),
        border_radius=5
    )

    # Draw one ball
    if not game_over:

        pygame.draw.ellipse(
            screen,
            RED,
            (
                ball["x"],
                ball["y"],
                ball_width,
                ball_height
            )
        )

    # Display score
    score_text = font.render(
        "Score: " + str(score),
        True,
        BLACK
    )
    screen.blit(score_text, (20, 20))

    # Display lives
    lives_text = font.render(
        "Lives: " + str(lives),
        True,
        GREEN
    )
    screen.blit(lives_text, (370, 20))

    # Game Over screen
    if game_over:

        over_text = big_font.render(
            "GAME OVER",
            True,
            RED
        )

        final_score = font.render(
            "Final Score: " + str(score),
            True,
            BLACK
        )

        exit_text = font.render(
            "Press ESC to Exit",
            True,
            GREEN
        )

        screen.blit(over_text, (100, 240))
        screen.blit(final_score, (165, 310))
        screen.blit(exit_text, (145, 370))

    # Update display
    pygame.display.update()

# Quit Pygame
pygame.quit()
sys.exit()


