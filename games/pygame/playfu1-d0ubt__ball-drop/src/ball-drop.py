# Ball Drop - catch the falling balls in the basket.
# Move with A/D or the left/right arrow keys. Press R to restart after game over.
import random

import pygame

# pygame setup
pygame.init()
screen = pygame.display.set_mode(size=(680,680), flags=pygame.SCALED, ) # opens a 680 x 680 window 
clock = pygame.time.Clock()
running = True      # becomes False when the window is closed, which ends the main loop
dt = 0              # seconds since the last frame (updated at the bottom of the loop)

# game variables
score=0
lives=3
game_over=False                     # True while the game over screen is showing
font = pygame.font.Font(None, 36)   # pygame's default font, size 36
next_bonus = 5                      # score needed for the next speed-up and extra life

# creating the basket (made once, before the loop)
basket = pygame.Rect(0, 0, 100, 20)                                     # left, top, width, height
basket.midbottom = (screen.get_width() / 2, screen.get_height() - 20)   # centred, 20 pixels above the bottom
basket_x = float(basket.x)                                              # exact position, because a Rect only stores whole numbers
basket_speed = 400                                                      # pixels per second


# creating the balls
ball_size = 30
balls = []                    # every ball currently on screen
ball_speed = 200              # pixels per second
spawn_delay = 1.25            # seconds between new balls
spawn_timer = spawn_delay     # starts full, so the first ball appears straight away

def make_ball():
    # makes one ball at the top of the screen with a random x position and colour
    rect = pygame.Rect(0, 0, ball_size, ball_size)
    rect.x = random.randint(5, screen.get_width() - ball_size - 5)
    rect.y = 5
    # "y" is the ball's exact position, because a Rect only stores whole numbers
    return {"rect": rect, "y": float(rect.y), "colour": random.choice(["red", "blue", "green", "yellow"])}
    
def game():
    # runs one frame of gameplay: basket movement, spawning, balls, catches and misses, speed-ups
    # these variables are changed in here, so Python needs to know they're the outside ones
    global basket_x, spawn_timer, score, lives, ball_speed, basket_speed, next_bonus
 
    # move the basket left or right - A/D and the left/right arrow keys
    keys = pygame.key.get_pressed()
    if keys[pygame.K_a] or keys[pygame.K_LEFT]:
        basket_x -= basket_speed * dt
    if keys[pygame.K_d] or keys[pygame.K_RIGHT]:
        basket_x += basket_speed * dt
 
    # keep the basket on screen (5 pixel gap at each edge), then copy the position to the Rect
    basket_x = max(5, min(basket_x, screen.get_width() - basket.width - 5))
    basket.x = round(basket_x)
 
    # spawn a new ball every spawn_delay seconds
    spawn_timer += dt
    if spawn_timer >= spawn_delay:
        balls.append(make_ball())
        spawn_timer = 0
 
    # move every ball, then check for catches and misses
    for ball in balls[:]:         # [:] loops over a copy, so removing balls is safe
        ball["y"] += ball_speed * dt
        ball["rect"].y = round(ball["y"])
 
        if basket.colliderect(ball["rect"]):
            # caught: score a point
            score += 1
            balls.remove(ball)
        elif ball["rect"].top > screen.get_height():
            # missed: the ball fell off the bottom, so lose a life
            lives -= 1
            balls.remove(ball)
 
    # every 5 points: speed everything up and give an extra life
    if score >= next_bonus:
        ball_speed = min(ball_speed + 20, 750)      # limit the maximum speed
        basket_speed = min(basket_speed + 20, 750)  # limit the maximum speed
        lives += 1
        next_bonus += 5

def reset_game():
    # puts everything back to its starting values for a new game
    # (keep these in step with the starting values near the top of the file)
    global score, lives, balls, spawn_timer, basket_x, ball_speed, basket_speed, next_bonus
    score = 0
    lives = 3
    balls = []
    spawn_timer = spawn_delay
    basket_x = (screen.get_width() - basket.width) / 2
    ball_speed = 200
    basket_speed = 400
    next_bonus = 5

while running:
    # poll for events
    # pygame.QUIT event means the user clicked X to close your window
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        # pressing R restarts, but only while the game over screen is showing
        if game_over and event.type == pygame.KEYDOWN and event.key == pygame.K_r:
            reset_game()
            game_over = False

    # fill the screen with a color to wipe away anything from last frame
    screen.fill("Gray")
    
    if not game_over:
        game()   # play one frame
        if lives <= 0:
            game_over = True    # out of lives, so switch to the game over screen
    else:
        # game over screen: the final score and how to restart
        over_text = font.render(f"Game over! Score: {score}", True, "black")
        retry_text = font.render("Press R to retry", True, "black")
        screen.blit(over_text, (200, 300))
        screen.blit(retry_text, (230, 340))

    
    # display the score and lives on the screen
    score_text = font.render(f"Score: {score}", True, "black")
    lives_text = font.render(f"Lives: {lives}", True, "black")
    screen.blit(score_text, (10, 10))
    screen.blit(lives_text, (10, 50))

    #drawing the basket
    pygame.draw.rect(screen, "chocolate3", basket)

    for ball in balls:
        pygame.draw.circle(screen, ball["colour"], ball["rect"].center, ball_size // 2)

    # flip() the display to put your work on screen
    pygame.display.flip()

    # limits FPS to 60
    # dt is delta time in seconds since last frame, used for framerate-
    # independent physics.
    dt = clock.tick(60) / 1000

# the loop has ended (window closed), so print the score and shut pygame down
print("Final score:", score)
pygame.quit()