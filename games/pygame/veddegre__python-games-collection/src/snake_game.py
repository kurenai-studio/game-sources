import os
os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "1"
import pygame
from highscores import get_high_score, save_high_score
GAME_NAME = "snake"
import random
import sys
from pygame.math import Vector2

# Initialize pygame
pygame.init()

# Game settings
CELL_SIZE = 30
GRID_WIDTH, GRID_HEIGHT = 20, 15
WIDTH, HEIGHT = CELL_SIZE * GRID_WIDTH, CELL_SIZE * GRID_HEIGHT
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Snake Game")
def _set_window_icon():
    base = os.path.dirname(os.path.abspath(__file__))
    for _icon_name in ("icon.bmp", "icon.png"):
        _icon_path = os.path.join(base, _icon_name)
        if os.path.isfile(_icon_path):
            try:
                pygame.display.set_icon(pygame.image.load(_icon_path))
                break
            except pygame.error:
                pass

_set_window_icon()


# Colors
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
GREEN = (0, 200, 0)
RED = (255, 0, 0)
DARK_GREEN = (0, 100, 0)
BLUE = (0, 0, 255)

# Game variables
clock = pygame.time.Clock()
font = pygame.font.SysFont("Arial", 25)

class Snake:
    def __init__(self):
        self.body = [Vector2(5, 8), Vector2(4, 8), Vector2(3, 8)]
        self.direction = Vector2(1, 0)
        self.new_block = False
        
        # Load and scale images
        self.head_up = pygame.Surface((CELL_SIZE, CELL_SIZE))
        self.head_up.fill(GREEN)
        self.head_down = pygame.Surface((CELL_SIZE, CELL_SIZE))
        self.head_down.fill(GREEN)
        self.head_right = pygame.Surface((CELL_SIZE, CELL_SIZE))
        self.head_right.fill(GREEN)
        self.head_left = pygame.Surface((CELL_SIZE, CELL_SIZE))
        self.head_left.fill(GREEN)
        
        self.body_surface = pygame.Surface((CELL_SIZE, CELL_SIZE))
        self.body_surface.fill(DARK_GREEN)
        
    def draw(self):
        # Draw head
        head_rect = pygame.Rect(self.body[0].x * CELL_SIZE, self.body[0].y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
        
        if self.direction == Vector2(0, -1):  # Up
            screen.blit(self.head_up, head_rect)
        elif self.direction == Vector2(0, 1):  # Down
            screen.blit(self.head_down, head_rect)
        elif self.direction == Vector2(1, 0):  # Right
            screen.blit(self.head_right, head_rect)
        else:  # Left
            screen.blit(self.head_left, head_rect)
            
        # Draw eyes on head
        if self.direction == Vector2(0, -1):  # Up
            pygame.draw.circle(screen, BLACK, (head_rect.x + 10, head_rect.y + 10), 3)
            pygame.draw.circle(screen, BLACK, (head_rect.x + CELL_SIZE - 10, head_rect.y + 10), 3)
        elif self.direction == Vector2(0, 1):  # Down
            pygame.draw.circle(screen, BLACK, (head_rect.x + 10, head_rect.y + CELL_SIZE - 10), 3)
            pygame.draw.circle(screen, BLACK, (head_rect.x + CELL_SIZE - 10, head_rect.y + CELL_SIZE - 10), 3)
        elif self.direction == Vector2(1, 0):  # Right
            pygame.draw.circle(screen, BLACK, (head_rect.x + CELL_SIZE - 10, head_rect.y + 10), 3)
            pygame.draw.circle(screen, BLACK, (head_rect.x + CELL_SIZE - 10, head_rect.y + CELL_SIZE - 10), 3)
        else:  # Left
            pygame.draw.circle(screen, BLACK, (head_rect.x + 10, head_rect.y + 10), 3)
            pygame.draw.circle(screen, BLACK, (head_rect.x + 10, head_rect.y + CELL_SIZE - 10), 3)
        
        # Draw body segments
        for segment in self.body[1:]:
            segment_rect = pygame.Rect(segment.x * CELL_SIZE, segment.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
            screen.blit(self.body_surface, segment_rect)
    
    def move(self):
        if self.new_block:
            body_copy = self.body[:]
            body_copy.insert(0, body_copy[0] + self.direction)
            self.body = body_copy
            self.new_block = False
        else:
            body_copy = self.body[:-1]
            body_copy.insert(0, body_copy[0] + self.direction)
            self.body = body_copy
    
    def add_block(self):
        self.new_block = True
    
    def reset(self):
        self.body = [Vector2(5, 8), Vector2(4, 8), Vector2(3, 8)]
        self.direction = Vector2(1, 0)

class Fruit:
    def __init__(self):
        self.position = self.generate_random_pos()
        
    def draw(self):
        fruit_rect = pygame.Rect(self.position.x * CELL_SIZE, self.position.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
        pygame.draw.rect(screen, RED, fruit_rect)
        # Draw highlight
        pygame.draw.circle(screen, WHITE, (fruit_rect.x + CELL_SIZE * 0.7, fruit_rect.y + CELL_SIZE * 0.3), 3)
    
    def generate_random_pos(self):
        x = random.randint(0, GRID_WIDTH - 1)
        y = random.randint(0, GRID_HEIGHT - 1)
        return Vector2(x, y)
    
    def reposition(self, snake_body):
        while True:
            position = self.generate_random_pos()
            if position not in snake_body:
                self.position = position
                break

class Game:
    def __init__(self):
        self.snake = Snake()
        self.fruit = Fruit()
        self.score = 0
        self.game_over = False
        self.high_score = get_high_score(GAME_NAME)
        self.new_high = False
    
    def update(self):
        if not self.game_over:
            self.snake.move()
            self.check_collision()
            self.check_fail()
    
    def draw(self):
        self.draw_grid()
        self.fruit.draw()
        self.snake.draw()
        self.draw_score()
        
        if self.game_over:
            self.draw_game_over()
    
    def check_collision(self):
        if self.fruit.position == self.snake.body[0]:
            self.fruit.reposition(self.snake.body)
            self.snake.add_block()
            self.score += 1
    
    def check_fail(self):
        # Check if snake hits the edge
        if not (0 <= self.snake.body[0].x < GRID_WIDTH and 0 <= self.snake.body[0].y < GRID_HEIGHT):
            self.game_over = True
        
        # Check if snake hits itself
        for segment in self.snake.body[1:]:
            if segment == self.snake.body[0]:
                self.game_over = True
        
        if self.game_over:
            if save_high_score(GAME_NAME, self.score):
                self.new_high = True
            self.high_score = get_high_score(GAME_NAME)
    
    def reset(self):
        self.snake.reset()
        self.fruit.reposition(self.snake.body)
        self.score = 0
        self.game_over = False
        self.new_high = False
        self.high_score = get_high_score(GAME_NAME)
        self.high_score = get_high_score(GAME_NAME)
        self.new_high = False
    
    def draw_grid(self):
        # Draw background
        screen.fill(BLACK)
        
        # Draw grid lines
        for x in range(0, WIDTH, CELL_SIZE):
            pygame.draw.line(screen, (40, 40, 40), (x, 0), (x, HEIGHT))
        for y in range(0, HEIGHT, CELL_SIZE):
            pygame.draw.line(screen, (40, 40, 40), (0, y), (WIDTH, y))
    
    def draw_score(self):
        score_text = font.render(f"Score: {self.score}", True, WHITE)
        screen.blit(score_text, (10, 10))
    
    def draw_game_over(self):
        # Create semi-transparent overlay
        overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 150))
        screen.blit(overlay, (0, 0))
        
        # Draw game over text
        game_over_text = font.render("GAME OVER", True, WHITE)
        restart_text = font.render("Press R to Restart", True, WHITE)
        
        hi_text = font.render(f"Best: {self.high_score}", True, (255, 215, 0))
        screen.blit(game_over_text, (WIDTH // 2 - game_over_text.get_width() // 2, HEIGHT // 2 - 50))
        screen.blit(restart_text, (WIDTH // 2 - restart_text.get_width() // 2, HEIGHT // 2 + 10))
        screen.blit(hi_text, (WIDTH // 2 - hi_text.get_width() // 2, HEIGHT // 2 - 10))
        if self.new_high:
            nb = font.render("NEW BEST!", True, (255, 215, 0))
            screen.blit(nb, (WIDTH // 2 - nb.get_width() // 2, HEIGHT // 2 + 45))

def main():
    game = Game()
    
    # Game loop
    running = True
    SCREEN_UPDATE = pygame.USEREVENT
    pygame.time.set_timer(SCREEN_UPDATE, 150)  # Snake speed - lower is faster
    
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    running = False
            
            if event.type == SCREEN_UPDATE and not game.game_over:
                game.update()
            
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_r and game.game_over:
                    game.reset()
                
                if not game.game_over:
                    if event.key == pygame.K_UP and game.snake.direction.y != 1:
                        game.snake.direction = Vector2(0, -1)
                    if event.key == pygame.K_RIGHT and game.snake.direction.x != -1:
                        game.snake.direction = Vector2(1, 0)
                    if event.key == pygame.K_DOWN and game.snake.direction.y != -1:
                        game.snake.direction = Vector2(0, 1)
                    if event.key == pygame.K_LEFT and game.snake.direction.x != 1:
                        game.snake.direction = Vector2(-1, 0)
        
        game.draw()
        pygame.display.update()
        clock.tick(60)
    
    pygame.quit()
    sys.exit()

if __name__ == "__main__":
    main()
