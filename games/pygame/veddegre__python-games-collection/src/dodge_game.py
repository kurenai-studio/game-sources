import os
os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "1"
from highscores import get_high_score, save_high_score
GAME_NAME = "dodge_game"
import pygame
import random

# Initialize pygame
pygame.init()

# Screen dimensions
SCREEN_WIDTH = 600
SCREEN_HEIGHT = 800

# Colors
WHITE = (255, 255, 255)
RED = (255, 0, 0)
BLUE = (0, 0, 255)
BLACK = (0, 0, 0)
DARK_RED = (180, 0, 0)
LIGHT_RED = (255, 50, 50)

# Create the screen
screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
pygame.display.set_caption("Catch the Falling Objects")
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


# Fonts
myFont = pygame.font.SysFont("monospace", 35)
game_over_font = pygame.font.SysFont("monospace", 50)
button_font = pygame.font.SysFont("monospace", 30)

# Clock to control speed
clock = pygame.time.Clock()

class Button:
    def __init__(self, x, y, width, height, text, action=None):
        self.rect = pygame.Rect(x, y, width, height)
        self.text = text
        self.action = action
        self.is_hovered = False
    
    def draw(self):
        # Draw the button
        color = LIGHT_RED if self.is_hovered else DARK_RED
        pygame.draw.rect(screen, color, self.rect, border_radius=10)
        pygame.draw.rect(screen, WHITE, self.rect, 2, border_radius=10)
        
        # Draw the text
        text_surf = button_font.render(self.text, True, WHITE)
        text_rect = text_surf.get_rect(center=self.rect.center)
        screen.blit(text_surf, text_rect)
    
    def check_hover(self, mouse_pos):
        self.is_hovered = self.rect.collidepoint(mouse_pos)
        return self.is_hovered
    
    def handle_event(self, event):
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if self.is_hovered and self.action:
                return self.action()
        return False

def set_level(score, object_speed):
    if score < 20:
        speed = object_speed
    elif score < 40:
        speed = object_speed + 3
    elif score < 60:
        speed = object_speed + 6
    else:
        speed = object_speed + 9
    return speed

# Detect collision function
def detect_collision(player_pos, object_pos):
    p_x, p_y = player_pos
    o_x, o_y = object_pos

    if (o_x < p_x + player_size and o_x + object_size > p_x) \
       and (o_y < p_y + player_size and o_y + object_size > p_y):
        return True
    return False

def reset_game():
    # Reset all game variables
    global player_pos, object_list, score, game_over, player_alive
    
    player_pos = [SCREEN_WIDTH // 2, SCREEN_HEIGHT - player_size * 2]
    object_list = [[random.randint(0, SCREEN_WIDTH - object_size), 0]]
    score = 0
    game_over = False
    player_alive = True

def quit_game():
    global running
    running = False
    return True

# Player settings
player_size = 80
player_pos = [SCREEN_WIDTH // 2, SCREEN_HEIGHT - player_size * 2]

# Object settings
object_size = 50
object_list = [[random.randint(0, SCREEN_WIDTH - object_size), 0]]
object_speed = 10

# Game state
score = 0
game_over = False
player_alive = True
running = True

# Game-over layout (stacked so text does not overlap buttons)
BTN_W, BTN_H = 300, 60
GO_TITLE_Y = SCREEN_HEIGHT // 3
GO_SCORE_Y = GO_TITLE_Y + 72
GO_BEST_Y = GO_SCORE_Y + 48
GO_RESTART_Y = GO_BEST_Y + 52
GO_QUIT_Y = GO_RESTART_Y + BTN_H + 16
GO_HINT_Y = GO_QUIT_Y + BTN_H + 28

restart_button = Button(
    SCREEN_WIDTH // 2 - BTN_W // 2, GO_RESTART_Y, BTN_W, BTN_H, "Restart", reset_game
)
quit_button = Button(
    SCREEN_WIDTH // 2 - BTN_W // 2, GO_QUIT_Y, BTN_W, BTN_H, "Quit Game", quit_game
)

# Main game loop
while running:
    mouse_pos = pygame.mouse.get_pos()
    
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False
        
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_r and game_over:
                reset_game()
        
        # Check button clicks when game is over
        if game_over:
            restart_button.handle_event(event)
            quit_button.handle_event(event)

    screen.fill(WHITE)
    
    # Game is active
    if player_alive:
        keys = pygame.key.get_pressed()
        
        if keys[pygame.K_LEFT] and player_pos[0] > 0:
            player_pos[0] -= 10
        if keys[pygame.K_RIGHT] and player_pos[0] < SCREEN_WIDTH - player_size:
            player_pos[0] += 10

        # Generate new objects
        if len(object_list) < 5 and random.random() < 0.1:
            x_pos = random.randint(0, SCREEN_WIDTH - object_size)
            y_pos = 0
            object_list.append([x_pos, y_pos])

        # Move objects down and detect collisions
        for obj in object_list[:]:
            if obj[1] >= 0 and obj[1] < SCREEN_HEIGHT:
                obj[1] += set_level(score, object_speed)
            else:
                object_list.remove(obj)
                score += 1

            if detect_collision(player_pos, obj):
                player_alive = False
                game_over = True
                if save_high_score(GAME_NAME, score):
                    pass  # new high recorded

            pygame.draw.rect(screen, RED, (obj[0], obj[1], object_size, object_size))

        # Draw player
        pygame.draw.rect(screen, BLUE, (player_pos[0], player_pos[1], player_size, player_size))

        # Display score
        text = myFont.render(f"Score: {score}", True, BLACK)
        screen.blit(text, (10, 10))
        hi_live = myFont.render(f"Best: {get_high_score(GAME_NAME)}", True, (180, 120, 0))
        screen.blit(hi_live, (10, 45))

    # Game over screen
    else:
        # Draw objects and player in their last positions (frozen)
        for obj in object_list:
            pygame.draw.rect(screen, RED, (obj[0], obj[1], object_size, object_size))
        
        pygame.draw.rect(screen, BLUE, (player_pos[0], player_pos[1], player_size, player_size))
        
        # Create semi-transparent overlay
        overlay = pygame.Surface((SCREEN_WIDTH, SCREEN_HEIGHT), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 180))
        screen.blit(overlay, (0, 0))
        
        game_over_text = game_over_font.render("GAME OVER", True, WHITE)
        screen.blit(
            game_over_text,
            (SCREEN_WIDTH // 2 - game_over_text.get_width() // 2, GO_TITLE_Y),
        )

        final_score_text = myFont.render(f"Final Score: {score}", True, WHITE)
        screen.blit(
            final_score_text,
            (SCREEN_WIDTH // 2 - final_score_text.get_width() // 2, GO_SCORE_Y),
        )

        high_score_val = get_high_score(GAME_NAME)
        hi_text = myFont.render(f"Best: {high_score_val}", True, (255, 215, 0))
        screen.blit(
            hi_text,
            (SCREEN_WIDTH // 2 - hi_text.get_width() // 2, GO_BEST_Y),
        )
        
        # Check button hover for highlighting
        restart_button.check_hover(mouse_pos)
        quit_button.check_hover(mouse_pos)
        
        # Draw buttons
        restart_button.draw()
        quit_button.draw()
        
        key_text = myFont.render("or press R to restart", True, WHITE)
        screen.blit(
            key_text,
            (SCREEN_WIDTH // 2 - key_text.get_width() // 2, GO_HINT_Y),
        )

    clock.tick(30)
    pygame.display.update()

pygame.quit()
