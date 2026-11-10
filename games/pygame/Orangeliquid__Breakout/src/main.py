import pygame
import sys
import random
import math


# Function to randomly determine rgb of blocks
def random_rgb():
    return random.randint(0, 255)


class Player:
    def __init__(self, x, y, player_width, player_height, color, speed, window_width):
        self.rect = pygame.Rect(x, y, player_width, player_height)
        self.color = color
        self.speed = speed
        self.window_width = window_width

    def move(self, direction):
        if direction == "left" and self.rect.left > 0:
            self.rect.x -= self.speed
        elif direction == "right" and self.rect.right < self.window_width:
            self.rect.x += self.speed

    def draw(self, screen):
        pygame.draw.rect(screen, self.color, self.rect)


class Ball:
    def __init__(self, x, y, radius, color, speed):
        self.rect = pygame.Rect(x - radius, y - radius, 2 * radius, 2 * radius)
        self.color = color
        self.speed = speed
        self.angle = math.radians(random.randint(10, 150))
        self.speed_x = self.speed * math.cos(self.angle)
        self.speed_y = -self.speed * math.sin(self.angle)

    def move(self):
        self.rect.x += self.speed_x
        self.rect.y += self.speed_y

    def draw(self, screen):
        pygame.draw.circle(screen, self.color, self.rect.center, self.rect.width // 2)


class Target:
    def __init__(self, x, y, target_width, target_height, color):
        self.rect = pygame.Rect(x, y, target_width, target_height)
        self.color = color
        self.active = True

    def draw(self, screen):
        if self.active:
            pygame.draw.rect(screen, self.color, self.rect)


def main():
    # Initialize Pygame
    pygame.init()

    # Set up the window
    window_width, window_height = 800, 850
    screen = pygame.display.set_mode((window_width, window_height))
    round_number = 1
    num_rows = 1
    num_columns = 8
    player_lives = 3
    pygame.display.set_caption("Breakout")

    target_width = 90
    target_height = 20
    target_spacing = 10
    start_y = 50

    # Creates the player platform
    player = Player(x=(window_width - 150) // 2, y=window_height - 60, player_width=120, player_height=20,
                    color=(255, 165, 0), speed=10, window_width=window_width)

    # Create the ball
    ball = Ball(window_width // 2, player.rect.y - 30, 10, (255, 0, 0), 10)

    # Populates the targets - set to 8 targets per row
    targets = [Target(i * 95, 50, 90, 20, (random.randint(0, 255),
               random.randint(0, 255), random.randint(0, 255))) for i in range(8)]

    # Set up the scoreboard
    score = 0
    font = pygame.font.Font(None, 36)

    # Introductory phase
    intro_text = font.render("Breakout", True, (255, 255, 255),
                             (random_rgb(), random_rgb(), random_rgb()))
    screen.blit(intro_text, (350, 350))
    pygame.display.flip()

    intro_active = True

    # Game loop
    clock = pygame.time.Clock()

    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()

        # Introductory phase - Check for key press to start the game
        if intro_active:
            keys = pygame.key.get_pressed()
            if keys[pygame.K_LEFT] or keys[pygame.K_RIGHT]:
                intro_active = False

        # Game active phase
        else:
            # Handle player movement
            keys = pygame.key.get_pressed()
            if keys[pygame.K_LEFT] or keys[pygame.K_RIGHT]:
                player.move("left" if keys[pygame.K_LEFT] else "right")

            ball.move()

            # Bounce off walls
            if ball.rect.left < 0 or ball.rect.right > window_width:
                ball.speed_x = -ball.speed_x

            if ball.rect.top < 0:
                ball.speed_y = -ball.speed_y

            # Check for collision with the player/platform
            if player.rect.colliderect(ball.rect):
                ball.speed_y = -ball.speed_y  # Bounce off the platform

            # Check for collision with targets
            for target in targets:
                if target.active and target.rect.colliderect(ball.rect):
                    target.active = False

                    # Store the previous position of the ball
                    prev_x, prev_y = ball.rect.x, ball.rect.y

                    # Move the ball away from the target (adjust these values based on your preference)
                    ball.rect.x += ball.speed_x
                    ball.rect.y += ball.speed_y

                    # Calculate the angle of incidence
                    angle_of_incidence = math.atan2(-ball.speed_y, ball.speed_x)

                    # Flip the direction of the ball while preserving the angle
                    angle_of_reflection = math.pi - angle_of_incidence

                    # Speed factor that can be adjusted if need be
                    speed_gain_factor = 1.01
                    new_speed_magnitude = min(math.sqrt(ball.speed_x ** 2 + ball.speed_y ** 2) * speed_gain_factor,
                                              20.0)

                    ball.speed_x = new_speed_magnitude * math.cos(angle_of_reflection)
                    ball.speed_y = -new_speed_magnitude * math.sin(angle_of_reflection)

                    # Move the ball based on the adjusted speed
                    ball.rect.x += ball.speed_x
                    ball.rect.y += ball.speed_y

                    # Check for collisions after the adjustment
                    if any(target.active and target.rect.colliderect(ball.rect) for target in targets):
                        # If the ball is still colliding, revert to the previous position
                        ball.rect.x, ball.rect.y = prev_x, prev_y

                    score += 1  # Increase the score

            # Reset ball if it goes below the player/platform or all targets are hit
            if ball.rect.top > window_height or all(not target.active for target in targets):
                # Deduct a life when the ball goes below the platform
                if ball.rect.top > window_height and player_lives > 0:
                    life_lost = font.render("-1 Life!", True, (255, 255, 255))
                    screen.blit(life_lost, (350, 200))
                    pygame.display.flip()
                    pygame.time.delay(1000)
                    player_lives -= 1

                # Check if there are no more lives
                if player_lives == 0:
                    # Display game over message
                    game_over_text = font.render("Game Over", True, (255, 255, 255))
                    screen.blit(game_over_text, (325, 300))
                    pygame.display.flip()
                    pygame.time.delay(2000)  # Wait for 2 seconds before checking for user input

                    # Ask the user if they want to play again
                    replay_text = font.render("Press Enter to Play Again or Backspace to Exit", True, (255, 255, 255))
                    screen.blit(replay_text, (150, 400))
                    pygame.display.flip()

                    waiting_for_input = True
                    while waiting_for_input:
                        for event in pygame.event.get():
                            if event.type == pygame.QUIT:
                                pygame.quit()
                                sys.exit()
                            elif event.type == pygame.KEYDOWN:
                                if event.key == pygame.K_RETURN:  # Enter key
                                    main()  # Restart the game
                                    waiting_for_input = False
                                elif event.key == pygame.K_BACKSPACE:
                                    pygame.quit()
                                    sys.exit()

                # Reset ball and player position
                ball.rect.x = window_width // 2
                ball.rect.y = player.rect.y - 30
                ball.angle = math.radians(random.randint(10, 150))
                ball.speed_x = 10 * math.cos(ball.angle)
                ball.speed_y = -10 * math.sin(ball.angle)

            # Check if all targets are hit to progress to the next level
            if all(not target.active for target in targets):
                # Display round complete message
                round_text = font.render(f"Round {round_number} Complete!", True, (255, 255, 255))
                screen.blit(round_text, (250, 200))

                # Increase the number of rows and round for the next level
                num_rows += 1
                round_number += 1
                if round_number % 2 == 0:
                    player_lives += 1
                    life_gained_text = font.render(f"Lives increased to {player_lives}!", True, (255, 255, 255))
                    screen.blit(life_gained_text, (250, 100))

                pygame.display.flip()
                pygame.time.delay(2000)

                # Reset targets
                targets = []
                for row in range(num_rows):
                    for column in range(num_columns):
                        target_x = column * (target_width + target_spacing)
                        target_y = start_y + row * (target_height + target_spacing)
                        target_color = (random_rgb(), random_rgb(), random_rgb())
                        targets.append(Target(target_x, target_y, target_width, target_height, target_color))

                # Reset ball and player position
                ball.rect.x = window_width // 2
                ball.rect.y = player.rect.y - 30
                ball.angle = math.radians(random.randint(10, 150))
                ball.speed_x = 10 * math.cos(ball.angle)
                ball.speed_y = -10 * math.sin(ball.angle)

            # Draw background
            screen.fill((0, 0, 0))

            # Draw the player/platform
            player.draw(screen)

            # Draw the ball
            ball.draw(screen)

            # Draw the targets
            for target in targets:
                target.draw(screen)

            # Draw the scoreboard
            score_title = font.render("Score: {}".format(score), True, (255, 255, 255))
            screen.blit(score_title, (20, 10))

            player_lives_title = font.render("Lives: {}".format(player_lives), True, (255, 255, 255))
            screen.blit(player_lives_title, (180, 10))

            #  Draw the current round
            round_title = font.render("Round: {}".format(round_number), True, (255, 255, 255))
            screen.blit(round_title, (360, 10))

            # Draw ball speed for user
            ball_speed = math.sqrt(ball.speed_x ** 2 + ball.speed_y ** 2)
            ball_speed_text = font.render("Ball Speed: {:.2f}".format(ball_speed), True, (255, 255, 255))
            screen.blit(ball_speed_text, (550, 10))

        # Update the display
        pygame.display.flip()

        # Cap the frame rate
        clock.tick(60)


if __name__ == "__main__":
    main()
