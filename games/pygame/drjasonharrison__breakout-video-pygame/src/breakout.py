"""
BREAKOUT - Classic Arcade Game
Controls: LEFT/RIGHT arrows or A/D to move paddle, SPACE to launch ball, R to restart, Q to quit
"""

import pygame
import sys
import random
import math

# Initialize
pygame.init()

# Screen
WIDTH, HEIGHT = 800, 600
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("BREAKOUT")

# Colors
BG_COLOR = (15, 15, 30)
WHITE = (255, 255, 255)
PADDLE_COLOR = (200, 220, 255)
BALL_COLOR = (255, 255, 255)
TEXT_COLOR = (200, 200, 220)
BALL_TRAIL_COLOR = (100, 100, 180)

BRICK_COLORS = [
    (231, 76, 60),    # Red
    (230, 126, 34),   # Orange
    (241, 196, 15),   # Yellow
    (46, 204, 113),   # Green
    (52, 152, 219),   # Blue
    (155, 89, 182),   # Purple
]

# Game constants
PADDLE_WIDTH = 120
PADDLE_HEIGHT = 14
PADDLE_SPEED = 8
PADDLE_Y = HEIGHT - 50

BALL_RADIUS = 8
BALL_SPEED_INITIAL = 5
BALL_SPEED_MAX = 9

BRICK_ROWS = 6
BRICK_COLS = 10
BRICK_WIDTH = 70
BRICK_HEIGHT = 24
BRICK_PADDING = 4
BRICK_OFFSET_TOP = 80
BRICK_OFFSET_LEFT = (WIDTH - (BRICK_COLS * (BRICK_WIDTH + BRICK_PADDING) - BRICK_PADDING)) // 2

POINTS_PER_ROW = [7, 7, 5, 5, 3, 1]

# Fonts
font_large = pygame.font.SysFont("Arial", 52, bold=True)
font_medium = pygame.font.SysFont("Arial", 28)
font_small = pygame.font.SysFont("Arial", 20)


class Particle:
    def __init__(self, x, y, color):
        self.x = x
        self.y = y
        angle = random.uniform(0, 2 * math.pi)
        speed = random.uniform(1, 4)
        self.vx = math.cos(angle) * speed
        self.vy = math.sin(angle) * speed
        self.life = random.randint(15, 35)
        self.max_life = self.life
        self.color = color
        self.size = random.uniform(2, 5)

    def update(self):
        self.x += self.vx
        self.y += self.vy
        self.vy += 0.1  # gravity
        self.life -= 1

    def draw(self, surface):
        alpha = self.life / self.max_life
        r = int(self.color[0] * alpha)
        g = int(self.color[1] * alpha)
        b = int(self.color[2] * alpha)
        size = max(1, int(self.size * alpha))
        pygame.draw.circle(surface, (r, g, b), (int(self.x), int(self.y)), size)


class Ball:
    def __init__(self):
        self.reset()
        self.trail = []

    def reset(self):
        self.x = WIDTH // 2
        self.y = PADDLE_Y - BALL_RADIUS - 2
        self.vx = 0
        self.vy = 0
        self.launched = False
        self.speed = BALL_SPEED_INITIAL
        self.trail = []

    def launch(self):
        if not self.launched:
            angle = random.uniform(-0.6, 0.6)
            self.vx = math.sin(angle) * self.speed
            self.vy = -math.cos(angle) * self.speed
            self.launched = True

    def update(self, paddle_x):
        if not self.launched:
            self.x = paddle_x
            self.y = PADDLE_Y - BALL_RADIUS - 2
            return

        self.trail.append((self.x, self.y))
        if len(self.trail) > 8:
            self.trail.pop(0)

        self.x += self.vx
        self.y += self.vy

        # Wall collisions
        if self.x - BALL_RADIUS <= 0:
            self.x = BALL_RADIUS
            self.vx = abs(self.vx)
        elif self.x + BALL_RADIUS >= WIDTH:
            self.x = WIDTH - BALL_RADIUS
            self.vx = -abs(self.vx)
        if self.y - BALL_RADIUS <= 0:
            self.y = BALL_RADIUS
            self.vy = abs(self.vy)

    def draw(self, surface):
        for i, (tx, ty) in enumerate(self.trail):
            alpha = (i + 1) / len(self.trail) if self.trail else 1
            size = max(1, int(BALL_RADIUS * alpha * 0.6))
            color = tuple(int(c * alpha * 0.4) for c in BALL_TRAIL_COLOR)
            pygame.draw.circle(surface, color, (int(tx), int(ty)), size)
        pygame.draw.circle(surface, BALL_COLOR, (int(self.x), int(self.y)), BALL_RADIUS)
        # Glow
        glow = pygame.Surface((BALL_RADIUS * 4, BALL_RADIUS * 4), pygame.SRCALPHA)
        pygame.draw.circle(glow, (150, 150, 255, 40), (BALL_RADIUS * 2, BALL_RADIUS * 2), BALL_RADIUS * 2)
        surface.blit(glow, (int(self.x) - BALL_RADIUS * 2, int(self.y) - BALL_RADIUS * 2))


class Brick:
    def __init__(self, x, y, color, points):
        self.rect = pygame.Rect(x, y, BRICK_WIDTH, BRICK_HEIGHT)
        self.color = color
        self.points = points
        self.alive = True

    def draw(self, surface):
        if not self.alive:
            return
        # Main brick
        pygame.draw.rect(surface, self.color, self.rect, border_radius=4)
        # Highlight
        highlight = pygame.Rect(self.rect.x + 2, self.rect.y + 2, self.rect.width - 4, self.rect.height // 2 - 2)
        h_color = tuple(min(255, c + 50) for c in self.color)
        pygame.draw.rect(surface, h_color, highlight, border_radius=3)


class Game:
    def __init__(self):
        self.clock = pygame.time.Clock()
        self.state = "menu"  # menu, playing, gameover, win
        self.score = 0
        self.lives = 3
        self.level = 1
        self.paddle_x = WIDTH // 2
        self.ball = Ball()
        self.bricks = []
        self.particles = []
        self.create_bricks()

    def create_bricks(self):
        self.bricks = []
        for row in range(BRICK_ROWS):
            for col in range(BRICK_COLS):
                x = BRICK_OFFSET_LEFT + col * (BRICK_WIDTH + BRICK_PADDING)
                y = BRICK_OFFSET_TOP + row * (BRICK_HEIGHT + BRICK_PADDING)
                color = BRICK_COLORS[row % len(BRICK_COLORS)]
                points = POINTS_PER_ROW[row % len(POINTS_PER_ROW)]
                self.bricks.append(Brick(x, y, color, points))

    def spawn_particles(self, x, y, color, count=12):
        for _ in range(count):
            self.particles.append(Particle(x, y, color))

    def handle_collisions(self):
        ball = self.ball

        # Paddle collision
        paddle_rect = pygame.Rect(self.paddle_x - PADDLE_WIDTH // 2, PADDLE_Y,
                                   PADDLE_WIDTH, PADDLE_HEIGHT)
        if (ball.vy > 0 and
            paddle_rect.left - BALL_RADIUS < ball.x < paddle_rect.right + BALL_RADIUS and
            paddle_rect.top - BALL_RADIUS < ball.y < paddle_rect.top + BALL_RADIUS + 6):

            # Calculate bounce angle based on where ball hits paddle
            relative_x = (ball.x - self.paddle_x) / (PADDLE_WIDTH / 2)
            relative_x = max(-1, min(1, relative_x))
            angle = relative_x * 1.1  # max ~63 degrees
            ball.vx = math.sin(angle) * ball.speed
            ball.vy = -math.cos(angle) * ball.speed
            ball.y = paddle_rect.top - BALL_RADIUS
            self.spawn_particles(ball.x, ball.y, PADDLE_COLOR, 5)

        # Brick collisions
        ball_rect = pygame.Rect(ball.x - BALL_RADIUS, ball.y - BALL_RADIUS,
                                 BALL_RADIUS * 2, BALL_RADIUS * 2)
        for brick in self.bricks:
            if not brick.alive:
                continue
            if ball_rect.colliderect(brick.rect):
                brick.alive = False
                self.score += brick.points
                self.spawn_particles(brick.rect.centerx, brick.rect.centery, brick.color, 15)

                # Determine collision side
                dx = ball.x - brick.rect.centerx
                dy = ball.y - brick.rect.centery
                if abs(dx / (BRICK_WIDTH / 2 + BALL_RADIUS)) > abs(dy / (BRICK_HEIGHT / 2 + BALL_RADIUS)):
                    ball.vx = -ball.vx
                else:
                    ball.vy = -ball.vy

                # Speed up slightly
                ball.speed = min(BALL_SPEED_MAX, ball.speed + 0.03)
                magnitude = math.sqrt(ball.vx ** 2 + ball.vy ** 2)
                if magnitude > 0:
                    ball.vx = ball.vx / magnitude * ball.speed
                    ball.vy = ball.vy / magnitude * ball.speed
                break

        # Check win
        if all(not b.alive for b in self.bricks):
            self.state = "win"

        # Check ball out of bounds
        if ball.y > HEIGHT + BALL_RADIUS:
            self.lives -= 1
            if self.lives <= 0:
                self.state = "gameover"
            else:
                ball.reset()

    def update(self):
        if self.state != "playing":
            return

        keys = pygame.key.get_pressed()
        if keys[pygame.K_LEFT] or keys[pygame.K_a]:
            self.paddle_x -= PADDLE_SPEED
        if keys[pygame.K_RIGHT] or keys[pygame.K_d]:
            self.paddle_x += PADDLE_SPEED
        self.paddle_x = max(PADDLE_WIDTH // 2, min(WIDTH - PADDLE_WIDTH // 2, self.paddle_x))

        self.ball.update(self.paddle_x)
        self.handle_collisions()

        # Update particles
        for p in self.particles:
            p.update()
        self.particles = [p for p in self.particles if p.life > 0]

    def draw(self):
        screen.fill(BG_COLOR)

        if self.state == "menu":
            self.draw_menu()
            pygame.display.flip()
            return

        # Draw bricks
        for brick in self.bricks:
            brick.draw(screen)

        # Draw paddle
        paddle_rect = pygame.Rect(self.paddle_x - PADDLE_WIDTH // 2, PADDLE_Y,
                                   PADDLE_WIDTH, PADDLE_HEIGHT)
        pygame.draw.rect(screen, PADDLE_COLOR, paddle_rect, border_radius=7)
        # Paddle glow
        glow = pygame.Surface((PADDLE_WIDTH + 20, PADDLE_HEIGHT + 20), pygame.SRCALPHA)
        pygame.draw.rect(glow, (100, 120, 200, 30),
                         (0, 0, PADDLE_WIDTH + 20, PADDLE_HEIGHT + 20), border_radius=10)
        screen.blit(glow, (self.paddle_x - PADDLE_WIDTH // 2 - 10, PADDLE_Y - 10))

        # Draw ball
        self.ball.draw(screen)

        # Draw particles
        for p in self.particles:
            p.draw(screen)

        # HUD
        score_text = font_small.render(f"SCORE: {self.score}", True, TEXT_COLOR)
        lives_text = font_small.render(f"LIVES: {'●' * self.lives}", True, TEXT_COLOR)
        screen.blit(score_text, (20, 15))
        screen.blit(lives_text, (WIDTH - 150, 15))

        # Launch hint
        if not self.ball.launched:
            hint = font_small.render("Press SPACE to launch", True, (120, 120, 160))
            screen.blit(hint, (WIDTH // 2 - hint.get_width() // 2, HEIGHT // 2 + 80))

        # Overlay messages
        if self.state == "gameover":
            self.draw_overlay("GAME OVER", f"Final Score: {self.score}", "Press R to restart")
        elif self.state == "win":
            self.draw_overlay("YOU WIN!", f"Score: {self.score}", "Press R to play again")

        pygame.display.flip()

    def draw_menu(self):
        title = font_large.render("BREAKOUT", True, WHITE)
        screen.blit(title, (WIDTH // 2 - title.get_width() // 2, 180))

        subtitle = font_medium.render("A Classic Arcade Game", True, (120, 120, 180))
        screen.blit(subtitle, (WIDTH // 2 - subtitle.get_width() // 2, 250))

        instructions = [
            "LEFT / RIGHT  or  A / D  —  Move Paddle",
            "SPACE  —  Launch Ball",
            "",
            "Press SPACE to Start"
        ]
        for i, line in enumerate(instructions):
            color = WHITE if i == len(instructions) - 1 else (140, 140, 170)
            text = font_small.render(line, True, color)
            screen.blit(text, (WIDTH // 2 - text.get_width() // 2, 340 + i * 35))

        # Decorative bricks
        for i, color in enumerate(BRICK_COLORS):
            x = WIDTH // 2 - (len(BRICK_COLORS) * 40) // 2 + i * 40
            pygame.draw.rect(screen, color, (x, 290, 35, 16), border_radius=3)

    def draw_overlay(self, title, subtitle, hint):
        overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 150))
        screen.blit(overlay, (0, 0))

        t = font_large.render(title, True, WHITE)
        s = font_medium.render(subtitle, True, TEXT_COLOR)
        h = font_small.render(hint, True, (140, 140, 170))
        screen.blit(t, (WIDTH // 2 - t.get_width() // 2, HEIGHT // 2 - 60))
        screen.blit(s, (WIDTH // 2 - s.get_width() // 2, HEIGHT // 2))
        screen.blit(h, (WIDTH // 2 - h.get_width() // 2, HEIGHT // 2 + 50))

    def restart(self):
        self.score = 0
        self.lives = 3
        self.paddle_x = WIDTH // 2
        self.ball = Ball()
        self.particles = []
        self.create_bricks()
        self.state = "playing"

    def run(self):
        while True:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    pygame.quit()
                    sys.exit()
                if event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_q:
                        pygame.quit()
                        sys.exit()
                    if event.key == pygame.K_SPACE:
                        if self.state == "menu":
                            self.state = "playing"
                        elif self.state == "playing":
                            self.ball.launch()
                    if event.key == pygame.K_r:
                        self.restart()

            self.update()
            self.draw()
            self.clock.tick(60)


if __name__ == "__main__":
    game = Game()
    game.run()
