import os
os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "1"
import pygame
import random
import sys
import math
from highscores import get_high_score, save_high_score

GAME_NAME = "breakout"
pygame.init()

WIDTH, HEIGHT = 800, 600
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Breakout")
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


BLACK  = (0, 0, 0)
WHITE  = (255, 255, 255)
GRAY   = (80, 80, 80)
YELLOW = (255, 220, 0)
CYAN   = (0, 220, 255)

font       = pygame.font.SysFont("Arial", 28)
small_font = pygame.font.SysFont("Arial", 20)
clock      = pygame.time.Clock()

# Brick grid
COLS, ROWS = 10, 7
BRICK_W, BRICK_H = 70, 22
BRICK_PAD = 4
BRICK_TOP = 60

BRICK_COLORS = [
    (255, 60, 60),   # row 0 - red    (3 pts)
    (255, 120, 0),   # row 1 - orange (2 pts)
    (255, 220, 0),   # row 2 - yellow (2 pts)
    (0, 220, 80),    # row 3 - green  (1 pt)
    (0, 180, 255),   # row 4 - blue   (1 pt)
    (180, 0, 255),   # row 5 - purple (1 pt)
    (200, 200, 200), # row 6 - gray   (1 pt)
]
BRICK_PTS = [3, 2, 2, 1, 1, 1, 1]

PADDLE_W, PADDLE_H = 110, 14
BALL_R = 9

def make_bricks():
    bricks = []
    total_w = COLS * (BRICK_W + BRICK_PAD) - BRICK_PAD
    x_start = (WIDTH - total_w) // 2
    for r in range(ROWS):
        for c in range(COLS):
            x = x_start + c * (BRICK_W + BRICK_PAD)
            y = BRICK_TOP + r * (BRICK_H + BRICK_PAD)
            bricks.append({"x": x, "y": y, "alive": True, "color": BRICK_COLORS[r], "pts": BRICK_PTS[r]})
    return bricks

def reset():
    bricks = make_bricks()
    paddle_x = WIDTH // 2 - PADDLE_W // 2
    paddle_y = HEIGHT - 50
    angle = random.uniform(math.pi * 0.25, math.pi * 0.75)
    speed = 6
    ball = {"x": float(WIDTH // 2), "y": float(paddle_y - BALL_R - 2),
            "vx": speed * math.cos(angle), "vy": -speed * math.sin(angle)}
    return bricks, paddle_x, paddle_y, ball, 0, False, False, get_high_score(GAME_NAME), False

bricks, paddle_x, paddle_y, ball, score, game_over, won, high_score, new_high = reset()
lives = 3
ball_launched = False

def launch_ball():
    global ball, ball_launched
    angle = random.uniform(math.pi * 0.3, math.pi * 0.7)
    speed = 6
    ball["vx"] = speed * math.cos(angle)
    ball["vy"] = -abs(speed * math.sin(angle))
    ball_launched = True

def draw_paddle(x, y):
    pygame.draw.rect(screen, CYAN, (x, y, PADDLE_W, PADDLE_H), border_radius=7)
    pygame.draw.rect(screen, WHITE, (x, y, PADDLE_W, PADDLE_H), 2, border_radius=7)

def draw_ball(b):
    pygame.draw.circle(screen, WHITE, (int(b["x"]), int(b["y"])), BALL_R)
    pygame.draw.circle(screen, CYAN,  (int(b["x"]) - 3, int(b["y"]) - 3), 3)

def draw_bricks(bricks):
    for br in bricks:
        if not br["alive"]:
            continue
        pygame.draw.rect(screen, br["color"], (br["x"], br["y"], BRICK_W, BRICK_H), border_radius=4)
        # Highlight
        pygame.draw.rect(screen, (min(255, br["color"][0]+60), min(255, br["color"][1]+60), min(255, br["color"][2]+60)),
                         (br["x"]+2, br["y"]+2, BRICK_W-4, 5), border_radius=2)
        pygame.draw.rect(screen, BLACK, (br["x"], br["y"], BRICK_W, BRICK_H), 1, border_radius=4)

running = True
lives = 3

while running:
    dt = clock.tick(60)

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_SPACE:
                if not ball_launched and not game_over and not won:
                    launch_ball()
                elif game_over or won:
                    bricks, paddle_x, paddle_y, ball, score, game_over, won, high_score, new_high = reset()
                    lives = 3
                    ball_launched = False
            if event.key == pygame.K_r and (game_over or won):
                bricks, paddle_x, paddle_y, ball, score, game_over, won, high_score, new_high = reset()
                lives = 3
                ball_launched = False

    if not game_over and not won:
        # Paddle movement
        keys = pygame.key.get_pressed()
        if keys[pygame.K_LEFT]  and paddle_x > 0:              paddle_x -= 9
        if keys[pygame.K_RIGHT] and paddle_x < WIDTH - PADDLE_W: paddle_x += 9

        if not ball_launched:
            ball["x"] = paddle_x + PADDLE_W / 2
            ball["y"] = paddle_y - BALL_R - 1
        else:
            ball["x"] += ball["vx"]
            ball["y"] += ball["vy"]

            # Wall collisions
            if ball["x"] - BALL_R <= 0:
                ball["x"] = BALL_R
                ball["vx"] = abs(ball["vx"])
            if ball["x"] + BALL_R >= WIDTH:
                ball["x"] = WIDTH - BALL_R
                ball["vx"] = -abs(ball["vx"])
            if ball["y"] - BALL_R <= 0:
                ball["y"] = BALL_R
                ball["vy"] = abs(ball["vy"])

            # Fell off bottom
            if ball["y"] > HEIGHT + BALL_R:
                lives -= 1
                ball_launched = False
                ball["x"] = float(paddle_x + PADDLE_W / 2)
                ball["y"] = float(paddle_y - BALL_R - 1)
                if lives <= 0:
                    game_over = True
                    if save_high_score(GAME_NAME, score):
                        new_high = True
                    high_score = get_high_score(GAME_NAME)

            # Paddle collision
            if (ball["y"] + BALL_R >= paddle_y and
                ball["y"] - BALL_R <= paddle_y + PADDLE_H and
                ball["x"] >= paddle_x and ball["x"] <= paddle_x + PADDLE_W and
                ball["vy"] > 0):
                rel = (ball["x"] - paddle_x) / PADDLE_W - 0.5  # -0.5 to 0.5
                speed = math.hypot(ball["vx"], ball["vy"])
                angle = math.pi / 2 + rel * math.pi * 0.6
                ball["vx"] = speed * math.cos(math.pi - angle)
                ball["vy"] = -abs(speed * math.sin(angle))

            # Brick collisions
            for br in bricks:
                if not br["alive"]:
                    continue
                bx, by = br["x"], br["y"]
                # Closest point on brick rect to ball center
                cx = max(bx, min(ball["x"], bx + BRICK_W))
                cy = max(by, min(ball["y"], by + BRICK_H))
                dist = math.hypot(ball["x"] - cx, ball["y"] - cy)
                if dist <= BALL_R:
                    br["alive"] = False
                    score += br["pts"]
                    # Determine bounce direction
                    if abs(ball["x"] - cx) > abs(ball["y"] - cy):
                        ball["vx"] *= -1
                    else:
                        ball["vy"] *= -1
                    break

            # Win check
            if all(not br["alive"] for br in bricks):
                won = True
                if save_high_score(GAME_NAME, score):
                    new_high = True
                high_score = get_high_score(GAME_NAME)

    # Draw
    screen.fill((10, 10, 30))
    draw_bricks(bricks)
    draw_paddle(paddle_x, paddle_y)
    draw_ball(ball)

    # HUD
    sc_text = font.render(f"Score: {score}", True, WHITE)
    screen.blit(sc_text, (10, 10))
    hi_text = small_font.render(f"Best: {high_score}", True, YELLOW)
    screen.blit(hi_text, (10, 40))
    for i in range(lives):
        pygame.draw.circle(screen, CYAN, (WIDTH - 20 - i * 22, 20), 7)

    if not ball_launched and not game_over and not won:
        hint = small_font.render("Press SPACE to launch", True, GRAY)
        screen.blit(hint, (WIDTH // 2 - hint.get_width() // 2, HEIGHT // 2 + 60))

    if game_over or won:
        overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 170))
        screen.blit(overlay, (0, 0))
        msg = "YOU WIN!" if won else "GAME OVER"
        color = (0, 255, 100) if won else (255, 60, 60)
        mt = font.render(msg, True, color)
        st = font.render(f"Score: {score}", True, WHITE)
        rt = small_font.render("Press R or SPACE to restart", True, WHITE)
        screen.blit(mt, (WIDTH // 2 - mt.get_width() // 2, HEIGHT // 2 - 60))
        screen.blit(st, (WIDTH // 2 - st.get_width() // 2, HEIGHT // 2 - 15))
        screen.blit(rt, (WIDTH // 2 - rt.get_width() // 2, HEIGHT // 2 + 30))
        if new_high:
            nb = font.render("NEW HIGH SCORE!", True, YELLOW)
            screen.blit(nb, (WIDTH // 2 - nb.get_width() // 2, HEIGHT // 2 + 60))

    pygame.display.flip()

pygame.quit()
sys.exit()
