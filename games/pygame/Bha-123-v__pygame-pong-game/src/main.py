import sys
import pygame
from pygame.locals import QUIT, KEYDOWN, KEYUP

# Initialize Pygame and prepare the game environment.
pygame.init()

# ------------------------------------------------------------
# Game configuration
# ------------------------------------------------------------
# These values control the size of the game window and the speed
# of movement and animation. Keeping them centralized makes the
# game easier to adjust later.
WIDTH, HEIGHT = 900, 600
FPS = 60

# Colors used throughout the game.
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
GRAY = (60, 60, 60)
ACCENT = (92, 198, 255)

# Paddle and ball sizing.
PADDLE_WIDTH = 16
PADDLE_HEIGHT = 100
PADDLE_SPEED = 480
BALL_RADIUS = 10
BALL_SPEED = 350
MAX_SCORE = 7

# Paddle color unlock system. Each color has a required survival time
# in seconds before it becomes available in one-player mode.
PADDLE_COLORS = {
    "classic": WHITE,
    "cyan": (92, 198, 255),
    "mint": (110, 255, 180),
    "violet": (180, 120, 255),
    "gold": (255, 198, 80),
}
PADDLE_UNLOCKS = {
    "classic": 0,
    "cyan": 10,
    "mint": 20,
    "violet": 40,
    "gold": 70,
}


# ------------------------------------------------------------
# Model layer
# ------------------------------------------------------------
# The model holds the game data and rules. It does not handle
# rendering or user input directly.

class Paddle:
    """Represents one player's paddle on the screen."""

    def __init__(self, x, y, width, height, speed, up_key, down_key, player_name="Player", color=WHITE):
        # Position and size of the paddle.
        self.x = x
        self.y = y
        self.width = width
        self.height = height

        # Paddle movement speed and key bindings.
        self.speed = speed
        self.up_key = up_key
        self.down_key = down_key
        self.player_name = player_name
        self.color = color

        # Score for this paddle.
        self.score = 0

    def move(self, direction, dt):
        """Move the paddle up or down.

        direction: -1 moves up, 1 moves down.
        dt: time since the last frame, used for frame-rate independence.
        """
        self.y += direction * self.speed * dt

    def clamp(self):
        """Keep the paddle inside the game window bounds."""
        if self.y < 0:
            self.y = 0
        elif self.y + self.height > HEIGHT:
            self.y = HEIGHT - self.height

    def rect(self):
        """Return the paddle as a Pygame rectangle for drawing and collision checks."""
        return pygame.Rect(self.x, self.y, self.width, self.height)


class Ball:
    """Represents the moving ball in the game."""

    def __init__(self, x, y, radius, speed):
        self.x = x
        self.y = y
        self.radius = radius
        self.speed = speed
        self.vx = 0
        self.vy = 0

        # Make sure the ball starts with a valid direction.
        self.reset()

    def reset(self):
        """Place the ball in the center and launch it in a random direction."""
        self.x = WIDTH / 2
        self.y = HEIGHT / 2

        # Randomly choose the starting horizontal and vertical direction.
        self.vx = self.speed * self.random_direction()
        self.vy = self.speed * self.random_direction()

    def random_direction(self):
        """Return either -1 or 1 so the ball can move in either direction."""
        import random
        return random.choice([-1, 1])

    def update(self, dt):
        """Move the ball using the current velocity and frame time."""
        self.x += self.vx * dt
        self.y += self.vy * dt

    def bounce_wall(self):
        """Bounce the ball off the top and bottom walls."""
        if self.y - self.radius <= 0:
            self.y = self.radius
            self.vy *= -1
        elif self.y + self.radius >= HEIGHT:
            self.y = HEIGHT - self.radius
            self.vy *= -1

    def handle_paddle_collision(self, paddle):
        """Detect and resolve collisions between the ball and a paddle."""
        # Ball is moving left and colliding with the left paddle.
        if self.vx < 0 and self.x - self.radius <= paddle.x + paddle.width and self.x - self.radius >= paddle.x:
            if paddle.y <= self.y <= paddle.y + paddle.height:
                self.x = paddle.x + paddle.width + self.radius
                self.vx *= -1

                # Adjust vertical direction based on where the ball hits the paddle.
                collision_point = (self.y - (paddle.y + paddle.height / 2)) / (paddle.height / 2)
                self.vy = collision_point * self.speed * 1.25

        # Ball is moving right and colliding with the right paddle.
        elif self.vx > 0 and self.x + self.radius >= paddle.x and self.x + self.radius <= paddle.x + paddle.width:
            if paddle.y <= self.y <= paddle.y + paddle.height:
                self.x = paddle.x - self.radius
                self.vx *= -1

                # Adjust vertical direction based on where the ball hits the paddle.
                collision_point = (self.y - (paddle.y + paddle.height / 2)) / (paddle.height / 2)
                self.vy = collision_point * self.speed * 1.25


class PongModel:
    """Stores all game state and game rules."""

    def __init__(self):
        # Game mode determines whether the right paddle is controlled by a player
        # or by the CPU.
        self.mode = "single"  # Options: "single" or "two_player"

        # Create the left and right paddles.
        self.left_paddle = Paddle(
            30,
            HEIGHT / 2 - PADDLE_HEIGHT / 2,
            PADDLE_WIDTH,
            PADDLE_HEIGHT,
            PADDLE_SPEED,
            pygame.K_w,
            pygame.K_s,
            "Left",
            PADDLE_COLORS["classic"],
        )

        self.right_paddle = Paddle(
            WIDTH - 30 - PADDLE_WIDTH,
            HEIGHT / 2 - PADDLE_HEIGHT / 2,
            PADDLE_WIDTH,
            PADDLE_HEIGHT,
            PADDLE_SPEED,
            pygame.K_UP,
            pygame.K_DOWN,
            "Right",
            WHITE,
        )

        # Create the ball.
        self.ball = Ball(WIDTH / 2, HEIGHT / 2, BALL_RADIUS, BALL_SPEED)

        # High score and paddle unlock system for one-player mode.
        self.high_score_seconds = 0.0
        self.current_survival_seconds = 0.0
        self.selected_paddle_color = "classic"
        self.unlocked_paddle_colors = ["classic"]
        self.refresh_unlocks()

    def switch_mode(self, mode):
        """Change between single-player and two-player gameplay."""
        self.mode = mode
        self.reset_round()

    def reset_round(self):
        """Reset paddles and ball to their starting positions."""
        self.left_paddle.y = HEIGHT / 2 - PADDLE_HEIGHT / 2
        self.right_paddle.y = HEIGHT / 2 - PADDLE_HEIGHT / 2
        self.ball.reset()

    def refresh_unlocks(self):
        """Unlock paddle colors based on the best one-player survival time."""
        unlocked = []
        for color_name, unlock_time in sorted(PADDLE_UNLOCKS.items(), key=lambda item: item[1]):
            if self.high_score_seconds >= unlock_time:
                unlocked.append(color_name)

        self.unlocked_paddle_colors = unlocked if unlocked else ["classic"]

        if self.selected_paddle_color not in self.unlocked_paddle_colors:
            self.selected_paddle_color = self.unlocked_paddle_colors[0]

        self.left_paddle.color = PADDLE_COLORS[self.selected_paddle_color]

    def cycle_paddle_color(self, direction=1):
        """Move through unlocked paddle colors."""
        if not self.unlocked_paddle_colors:
            return

        current_index = self.unlocked_paddle_colors.index(self.selected_paddle_color)
        next_index = (current_index + direction) % len(self.unlocked_paddle_colors)
        self.selected_paddle_color = self.unlocked_paddle_colors[next_index]
        self.left_paddle.color = PADDLE_COLORS[self.selected_paddle_color]

    def update(self, dt, keys):
        """Update the game state for one frame.

        dt: elapsed time since last frame.
        keys: dictionary containing pressed keys.
        """
        if self.is_game_over():
            return

        # Update paddle positions based on current mode.
        if self.mode == "single":
            self.update_single_player_paddles(dt, keys)
            self.current_survival_seconds += dt
            self.high_score_seconds = max(self.high_score_seconds, self.current_survival_seconds)
            self.refresh_unlocks()
        else:
            self.update_two_player_paddles(dt, keys)
            self.current_survival_seconds = 0.0

        # Move the ball and handle collisions with walls and paddles.
        self.ball.update(dt)
        self.ball.bounce_wall()
        self.ball.handle_paddle_collision(self.left_paddle)
        self.ball.handle_paddle_collision(self.right_paddle)

        # Award points when the ball passes a paddle.
        if self.ball.x - self.ball.radius <= 0:
            self.right_paddle.score += 1
            self.current_survival_seconds = 0.0
            self.reset_round()
        elif self.ball.x + self.ball.radius >= WIDTH:
            self.left_paddle.score += 1
            self.reset_round()

        # Prevent paddles from leaving the screen.
        self.left_paddle.clamp()
        self.right_paddle.clamp()

    def update_single_player_paddles(self, dt, keys):
        """Handle left-player keyboard control and CPU control for the right paddle."""
        # Left paddle controlled by user.
        if keys.get(pygame.K_w):
            self.left_paddle.move(-1, dt)
        if keys.get(pygame.K_s):
            self.left_paddle.move(1, dt)

        # Right paddle is controlled by simple AI.
        target_y = self.ball.y - self.right_paddle.height / 2
        diff = target_y - self.right_paddle.y

        if abs(diff) > 3:
            direction = 1 if diff > 0 else -1
            self.right_paddle.move(direction, dt)

    def update_two_player_paddles(self, dt, keys):
        """Handle keyboard movement for both paddles in local two-player mode."""
        # Left paddle uses W and S.
        if keys.get(pygame.K_w):
            self.left_paddle.move(-1, dt)
        if keys.get(pygame.K_s):
            self.left_paddle.move(1, dt)

        # Right paddle uses arrow keys.
        if keys.get(pygame.K_UP):
            self.right_paddle.move(-1, dt)
        if keys.get(pygame.K_DOWN):
            self.right_paddle.move(1, dt)

    def is_game_over(self):
        """Return True if one player has reached the winning score."""
        return self.left_paddle.score >= MAX_SCORE or self.right_paddle.score >= MAX_SCORE

    def winner(self):
        """Return the winner name if a player reached the target score."""
        if self.left_paddle.score >= MAX_SCORE:
            return "Left Player"
        if self.right_paddle.score >= MAX_SCORE:
            return "Right Player"
        return None


# ------------------------------------------------------------
# Controller layer
# ------------------------------------------------------------
# The controller handles keyboard events and updates the model.

class PongController:
    def __init__(self, model):
        self.model = model
        self.keys = {}

    def handle_event(self, event):
        """React to Pygame events such as key presses and releases."""
        if event.type == KEYDOWN:
            self.keys[event.key] = True

            # Press 1 to play against the CPU.
            if event.key == pygame.K_1:
                self.model.switch_mode("single")

            # Press 2 to play local two-player mode.
            elif event.key == pygame.K_2:
                self.model.switch_mode("two_player")

            # Press R to reset the score and round.
            elif event.key == pygame.K_r:
                self.model.left_paddle.score = 0
                self.model.right_paddle.score = 0
                self.model.current_survival_seconds = 0.0
                self.model.reset_round()

            # Press C or X to cycle through unlocked paddle colors.
            elif event.key == pygame.K_c:
                self.model.cycle_paddle_color(1)
            elif event.key == pygame.K_x:
                self.model.cycle_paddle_color(-1)

            # Escape exits the game.
            elif event.key == pygame.K_ESCAPE:
                pygame.quit()
                sys.exit()

        elif event.type == KEYUP:
            self.keys[event.key] = False

    def update(self, dt):
        """Advance the simulation by one frame."""
        self.model.update(dt, self.keys)


# ------------------------------------------------------------
# View layer
# ------------------------------------------------------------
# The view is responsible for drawing the game on the screen.

class PongView:
    def __init__(self, screen, model):
        self.screen = screen
        self.model = model

        # Fonts used for score and status text.
        self.font = pygame.font.SysFont(None, 48)
        self.small_font = pygame.font.SysFont(None, 28)

    def draw(self):
        """Render the entire game scene."""
        # Fill the screen with a black background.
        self.screen.fill(BLACK)

        # Draw a center dashed line to mimic a tennis court feel.
        for y in range(0, HEIGHT, 20):
            pygame.draw.rect(self.screen, GRAY, (WIDTH / 2 - 2, y, 4, 14))

        # Draw paddles and the ball.
        left_rect = self.model.left_paddle.rect()
        right_rect = self.model.right_paddle.rect()
        pygame.draw.rect(self.screen, self.model.left_paddle.color, left_rect)
        pygame.draw.rect(self.screen, self.model.right_paddle.color, right_rect)
        pygame.draw.circle(self.screen, ACCENT, (int(self.model.ball.x), int(self.model.ball.y)), self.model.ball.radius)

        # Draw both player scores.
        left_score_text = self.font.render(str(self.model.left_paddle.score), True, WHITE)
        right_score_text = self.font.render(str(self.model.right_paddle.score), True, WHITE)
        self.screen.blit(left_score_text, (WIDTH / 2 - 60, 20))
        self.screen.blit(right_score_text, (WIDTH / 2 + 30, 20))

        # Display the current one-player survival score and current paddle color.
        high_score_label = self.small_font.render(f"High score: {self.model.high_score_seconds:.1f}s", True, WHITE)
        self.screen.blit(high_score_label, (20, 20))

        color_text = self.model.selected_paddle_color.title()
        color_label = self.small_font.render(f"Color: {color_text}   C/X to change", True, WHITE)
        self.screen.blit(color_label, (20, 52))

        # Show the selected play mode.
        mode_label = self.small_font.render(
            "Mode: 1-player vs CPU" if self.model.mode == "single" else "Mode: 2-player local",
            True,
            WHITE
        )
        self.screen.blit(mode_label, (20, HEIGHT - 35))

        # Also display unlocked colors for a junior developer to understand the system.
        unlocked_text = ", ".join(self.model.unlocked_paddle_colors)
        unlocked_label = self.small_font.render(f"Unlocked: {unlocked_text}", True, WHITE)
        self.screen.blit(unlocked_label, (600, HEIGHT - 35))

        # If someone reached the win condition, display a winner message.
        if self.model.is_game_over():
            winner = self.model.winner()
            winner_text = self.font.render(f"{winner} wins!", True, ACCENT)
            self.screen.blit(winner_text, (WIDTH / 2 - 130, HEIGHT / 2 - 30))

        # Update the visible display.
        pygame.display.flip()


# ------------------------------------------------------------
# Main game loop
# ------------------------------------------------------------
class PongGame:
    def __init__(self):
        # Create the game window and set the title.
        self.screen = pygame.display.set_mode((WIDTH, HEIGHT))
        pygame.display.set_caption("Pong")
        self.clock = pygame.time.Clock()

        # Build the model, controller, and view.
        self.model = PongModel()
        self.controller = PongController(self.model)
        self.view = PongView(self.screen, self.model)

    def run(self):
        """Main loop for the entire game."""
        while True:
            # Limit the frame rate and calculate delta time.
            dt = self.clock.tick(FPS) / 1000.0

            # Handle all events (keyboard input, quit, etc.)
            for event in pygame.event.get():
                if event.type == QUIT:
                    pygame.quit()
                    sys.exit()
                self.controller.handle_event(event)

            # Update game logic and then render everything.
            self.controller.update(dt)
            self.view.draw()


# Start the game when the script is executed directly.
if __name__ == "__main__":
    game = PongGame()
    game.run()
