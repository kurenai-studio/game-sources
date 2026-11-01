import os
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = '1'
import pygame, random, sys, math
from highscores import get_high_score, save_high_score

GAME_NAME  = "hyper_bounce"
WIDTH, HEIGHT = 800, 620
PADDLE_W   = 108
PADDLE_H   = 12
PADDLE_Y   = HEIGHT - 48
BALL_R     = 8
BASE_SPEED = 6.5

# ── Palette ───────────────────────────────────────────────────────────────────
BG_TOP    = (4,   4,  18)
BG_BOT    = (8,  10,  28)
WHITE     = (230, 232, 255)
GOLD      = (255, 210,  50)
DIM_WHITE = (110, 114, 150)

CELL_COLORS = [
    (255,  40, 160),  # hot pink
    (180,  30, 255),  # violet
    (0,   160, 255),  # electric blue
    (0,   230, 180),  # teal
    (0,   220,  80),  # acid green
    (255, 200,   0),  # laser gold
    (255, 110,   0),  # neon orange
    (100, 200, 255),  # sky blue
]

# ── Grid / cell constants ─────────────────────────────────────────────────────
COLS      = 10
ROWS      = 8
CELL_W    = 64
CELL_H    = 22
CELL_PAD  = 5
CELL_TOP  = 68
TOTAL_W   = COLS * (CELL_W + CELL_PAD) - CELL_PAD
GRID_X0   = (WIDTH - TOTAL_W) // 2

def cell_rect(r, c):
    x = GRID_X0 + c * (CELL_W + CELL_PAD)
    y = CELL_TOP + r * (CELL_H + CELL_PAD)
    return x, y

def color_for(r, c, level):
    return CELL_COLORS[(r + level) % len(CELL_COLORS)]

def pts_for(r):
    return max(1, ROWS - r)

# ── Level layouts ─────────────────────────────────────────────────────────────
def make_layout(level):
    cells = []

    def add(r, c):
        x, y = cell_rect(r, c)
        cells.append({"x": float(x), "y": float(y),
                       "w": CELL_W, "h": CELL_H,
                       "alive": True,
                       "color": color_for(r, c, level),
                       "pts":   pts_for(r)})

    lv = (level - 1) % 8

    if lv == 0:   # Solid grid
        for r in range(5):
            for c in range(COLS): add(r, c)

    elif lv == 1:  # Checkerboard
        for r in range(6):
            for c in range(COLS):
                if (r + c) % 2 == 0: add(r, c)

    elif lv == 2:  # Diamond outline
        cr, cc = 3, 4
        for r in range(ROWS):
            for c in range(COLS):
                if abs(r - cr) + abs(c - cc) in (3, 4, 5): add(r, c)

    elif lv == 3:  # Fortress — border + top row
        for r in range(7):
            add(r, 0); add(r, 1)
            add(r, COLS-1); add(r, COLS-2)
        for c in range(COLS): add(0, c)

    elif lv == 4:  # X pattern
        for r in range(ROWS):
            for c in range(COLS):
                cf = c * (ROWS-1) / (COLS-1)
                if abs(cf - r) < 1.1 or abs(cf - (ROWS-1-r)) < 1.1: add(r, c)

    elif lv == 5:  # Random scatter
        rng = random.Random(level * 7)
        positions = [(r, c) for r in range(ROWS) for c in range(COLS)]
        for r, c in rng.sample(positions, 40): add(r, c)

    elif lv == 6:  # Concentric rings
        cr, cc = 3.5, 4.5
        for r in range(ROWS):
            for c in range(COLS):
                d = math.hypot(r - cr, c - cc)
                if 1.4 < d < 2.4 or 3.0 < d < 4.0 or 4.8 < d < 5.5: add(r, c)

    elif lv == 7:  # Zigzag channel
        for r in range(7):
            for c in range(COLS):
                hole = (r * 2 + 3) % COLS
                if abs(c - hole) > 1: add(r, c)

    return cells

# ── Cell drawing ──────────────────────────────────────────────────────────────
def draw_cell(screen, cell):
    c = cell["color"]
    x, y, w, h = cell["x"], cell["y"], cell["w"], cell["h"]
    pygame.draw.rect(screen, c, (x, y, w, h), border_radius=4)
    bright = tuple(min(255, v+90) for v in c)
    pygame.draw.rect(screen, bright, (x+3, y+2, w-6, 5), border_radius=2)
    dark = tuple(max(0, v-50) for v in c)
    pygame.draw.rect(screen, dark, (x+2, y+h-5, w-4, 4), border_radius=2)
    glow = tuple(min(255, v+25) for v in c)
    pygame.draw.rect(screen, glow, (x, y, w, h), 1, border_radius=4)

# ── Ball + trail ──────────────────────────────────────────────────────────────
def draw_ball(screen, ball, trail):
    n = len(trail)
    for i, (tx, ty) in enumerate(trail):
        frac = i / max(n, 1)
        cg = int(100 + 120*frac)
        cb = int(160 + 95*frac)
        r2 = max(1, int(BALL_R * 0.3 + BALL_R * 0.5 * frac))
        pygame.draw.circle(screen, (0, cg, cb), (int(tx), int(ty)), r2)
    pygame.draw.circle(screen, (0, 220, 255), (int(ball["x"]), int(ball["y"])), BALL_R)
    pygame.draw.circle(screen, WHITE, (int(ball["x"])-2, int(ball["y"])-2), 3)

# ── Paddle ────────────────────────────────────────────────────────────────────
def draw_paddle(screen, px, pulse):
    base = (0, 200, 255)
    col  = tuple(int(base[i] + (255-base[i])*max(0.0, pulse)) for i in range(3))
    pygame.draw.rect(screen, col, (px, PADDLE_Y, PADDLE_W, PADDLE_H), border_radius=6)
    pygame.draw.circle(screen, WHITE, (px + PADDLE_W//2, PADDLE_Y + PADDLE_H//2), 5)
    bright = tuple(min(255, v+60) for v in col)
    pygame.draw.rect(screen, bright, (px, PADDLE_Y, PADDLE_W, PADDLE_H), 2, border_radius=6)

# ── Floaters ──────────────────────────────────────────────────────────────────
floaters = []

def add_floater(x, y, pts, color):
    floaters.append({"x": float(x), "y": float(y), "text": f"+{pts}",
                     "color": color, "life": 40, "max_life": 40})

# ── Ball launch ───────────────────────────────────────────────────────────────
def launch_ball(ball, speed):
    angle = random.uniform(math.pi*0.3, math.pi*0.7)
    ball["vx"] = speed * math.cos(angle)
    ball["vy"] = -abs(speed * math.sin(angle))

# ── Ball vs rect collision ────────────────────────────────────────────────────
def ball_hits_cell(ball, cell):
    cx = max(cell["x"], min(ball["x"], cell["x"] + cell["w"]))
    cy = max(cell["y"], min(ball["y"], cell["y"] + cell["h"]))
    return math.hypot(ball["x"] - cx, ball["y"] - cy) <= BALL_R

def bounce_cell(ball, cell):
    # Determine which axis to flip based on penetration depth
    cx = max(cell["x"], min(ball["x"], cell["x"] + cell["w"]))
    cy = max(cell["y"], min(ball["y"], cell["y"] + cell["h"]))
    if abs(ball["x"] - cx) > abs(ball["y"] - cy):
        ball["vx"] *= -1
    else:
        ball["vy"] *= -1

# ── Main ──────────────────────────────────────────────────────────────────────
if __name__ == '__main__':
    pygame.init()
    screen = pygame.display.set_mode((WIDTH, HEIGHT))
    pygame.display.set_caption("Hyper Bounce")
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
    
    
    font       = pygame.font.SysFont("Arial", 26, bold=True)
    small_font = pygame.font.SysFont("Arial", 18)
    big_font   = pygame.font.SysFont("Arial", 42, bold=True)
    float_font = pygame.font.SysFont("Arial", 16, bold=True)
    clock      = pygame.time.Clock()

    TRANSITION_FRAMES = 90

    def new_game():
        floaters.clear()
        return {
            "level":        1,
            "score":        0,
            "lives":        3,
            "high_score":   get_high_score(GAME_NAME),
            "new_high":     False,
            "game_over":    False,
            "transitioning":False,
            "trans_timer":  0,
            "cells":        make_layout(1),
            "paddle_x":     float(WIDTH//2 - PADDLE_W//2),
            "ball":         {"x": float(WIDTH//2), "y": float(PADDLE_Y - BALL_R - 2),
                             "vx": 0.0, "vy": 0.0},
            "launched":     False,
            "trail":        [],
            "paddle_pulse": 0.0,
            "ball_speed":   BASE_SPEED,
        }

    def start_level(gs):
        gs["cells"]     = make_layout(gs["level"])
        gs["ball"]      = {"x": float(gs["paddle_x"] + PADDLE_W/2),
                           "y": float(PADDLE_Y - BALL_R - 2),
                           "vx": 0.0, "vy": 0.0}
        gs["launched"]  = False
        gs["trail"].clear()
        gs["ball_speed"]= BASE_SPEED + (gs["level"]-1) * 0.35
        floaters.clear()

    gs = new_game()

    running = True
    while running:
        clock.tick(60)

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    running = False
                elif event.key == pygame.K_r:
                    gs = new_game()
                elif event.key == pygame.K_SPACE:
                    if gs["game_over"]:
                        gs = new_game()
                    elif gs["transitioning"]:
                        gs["trans_timer"] = 0
                    elif not gs["launched"]:
                        launch_ball(gs["ball"], gs["ball_speed"])
                        gs["launched"] = True

        if gs["transitioning"]:
            gs["trans_timer"] -= 1
            if gs["trans_timer"] <= 0:
                gs["transitioning"] = False
                start_level(gs)

        elif not gs["game_over"]:
            keys = pygame.key.get_pressed()
            if keys[pygame.K_LEFT]  and gs["paddle_x"] > 0:
                gs["paddle_x"] -= 10
            if keys[pygame.K_RIGHT] and gs["paddle_x"] < WIDTH - PADDLE_W:
                gs["paddle_x"] += 10

            gs["paddle_pulse"] = max(0.0, gs["paddle_pulse"] - 0.05)

            ball = gs["ball"]
            if not gs["launched"]:
                ball["x"] = gs["paddle_x"] + PADDLE_W/2
                ball["y"] = float(PADDLE_Y - BALL_R - 1)
            else:
                gs["trail"].append((ball["x"], ball["y"]))
                if len(gs["trail"]) > 8: gs["trail"].pop(0)

                ball["x"] += ball["vx"]
                ball["y"] += ball["vy"]

                # Walls
                if ball["x"] - BALL_R <= 0:
                    ball["x"] = float(BALL_R); ball["vx"] = abs(ball["vx"])
                if ball["x"] + BALL_R >= WIDTH:
                    ball["x"] = float(WIDTH - BALL_R); ball["vx"] = -abs(ball["vx"])
                if ball["y"] - BALL_R <= 0:
                    ball["y"] = float(BALL_R); ball["vy"] = abs(ball["vy"])

                # Lost ball
                if ball["y"] > HEIGHT + BALL_R:
                    gs["lives"] -= 1
                    gs["launched"] = False
                    gs["trail"].clear()
                    ball["x"] = gs["paddle_x"] + PADDLE_W/2
                    ball["y"] = float(PADDLE_Y - BALL_R - 1)
                    if gs["lives"] <= 0:
                        gs["game_over"] = True
                        if save_high_score(GAME_NAME, gs["score"]): gs["new_high"] = True
                        gs["high_score"] = get_high_score(GAME_NAME)

                # Paddle
                if (ball["vy"] > 0 and
                        ball["y"] + BALL_R >= PADDLE_Y and
                        ball["y"] - BALL_R <= PADDLE_Y + PADDLE_H and
                        gs["paddle_x"] <= ball["x"] <= gs["paddle_x"] + PADDLE_W):
                    rel   = (ball["x"] - gs["paddle_x"]) / PADDLE_W - 0.5
                    speed = math.hypot(ball["vx"], ball["vy"])
                    angle = math.pi/2 + rel * math.pi * 0.55
                    ball["vx"] = speed * math.cos(math.pi - angle)
                    ball["vy"] = -abs(speed * math.sin(angle))
                    gs["paddle_pulse"] = 1.0

                # Cells
                for cell in gs["cells"]:
                    if not cell["alive"]: continue
                    if ball_hits_cell(ball, cell):
                        cell["alive"] = False
                        gs["score"] += cell["pts"]
                        add_floater(cell["x"] + cell["w"]//2,
                                    cell["y"] - 8, cell["pts"], cell["color"])
                        bounce_cell(ball, cell)
                        break

                # Level clear
                if all(not c["alive"] for c in gs["cells"]):
                    gs["level"] += 1
                    gs["transitioning"] = True
                    gs["trans_timer"]   = TRANSITION_FRAMES
                    if save_high_score(GAME_NAME, gs["score"]): gs["new_high"] = True
                    gs["high_score"] = get_high_score(GAME_NAME)

        # Floaters
        for f in floaters[:]:
            f["y"] -= 1.2; f["life"] -= 1
            if f["life"] <= 0: floaters.remove(f)

        # ── Draw ──────────────────────────────────────────────────────────────
        screen.fill(BG_TOP)
        pygame.draw.rect(screen, BG_BOT, (0, HEIGHT//2, WIDTH, HEIGHT//2))

        # Scanlines
        sl = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        for y in range(0, HEIGHT, 40):
            pygame.draw.line(sl, (255,255,255,8), (0,y), (WIDTH,y))
        screen.blit(sl, (0,0))

        for cell in gs["cells"]:
            if cell["alive"]: draw_cell(screen, cell)

        draw_paddle(screen, int(gs["paddle_x"]), gs["paddle_pulse"])
        draw_ball(screen, gs["ball"], gs["trail"])

        for f in floaters:
            alpha = int(255 * f["life"] / f["max_life"])
            s = float_font.render(f["text"], True, f["color"])
            s.set_alpha(alpha)
            screen.blit(s, (int(f["x"]) - s.get_width()//2, int(f["y"])))

        # Lives
        for i in range(gs["lives"]):
            ox = WIDTH - 18 - i*22
            pygame.draw.circle(screen, (0,200,255), (ox,22), 7)
            pygame.draw.circle(screen, WHITE, (ox-2,19), 2)

        # HUD
        sc = font.render(f"Score: {gs['score']}", True, WHITE)
        screen.blit(sc, (12, 10))
        hi = small_font.render(f"Best: {gs['high_score']}", True, GOLD)
        screen.blit(hi, (12, 40))
        lv = font.render(f"Level {gs['level']}", True, (180, 60, 230))
        screen.blit(lv, (WIDTH//2 - lv.get_width()//2, 10))

        if not gs["launched"] and not gs["game_over"] and not gs["transitioning"]:
            hint = small_font.render("SPACE to launch", True, DIM_WHITE)
            screen.blit(hint, (WIDTH//2 - hint.get_width()//2, PADDLE_Y - 34))

        # Transition overlay
        if gs["transitioning"]:
            ov = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
            alpha = int(160 * gs["trans_timer"] / TRANSITION_FRAMES)
            ov.fill((0, 0, 0, alpha))
            screen.blit(ov, (0,0))
            lt = big_font.render(f"LEVEL {gs['level']}", True, (180, 60, 230))
            st = font.render("Get ready...", True, WHITE)
            sk = small_font.render("SPACE to skip", True, DIM_WHITE)
            screen.blit(lt, (WIDTH//2 - lt.get_width()//2, HEIGHT//2 - 50))
            screen.blit(st, (WIDTH//2 - st.get_width()//2, HEIGHT//2 + 10))
            screen.blit(sk, (WIDTH//2 - sk.get_width()//2, HEIGHT//2 + 44))

        # Game over
        if gs["game_over"]:
            ov = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
            ov.fill((0, 0, 0, 175))
            screen.blit(ov, (0,0))
            go  = big_font.render("GAME OVER", True, (255,60,100))
            sc2 = font.render(f"Score: {gs['score']}  |  Level {gs['level']}", True, WHITE)
            rt  = small_font.render("SPACE or R to play again  |  ESC to menu", True, DIM_WHITE)
            screen.blit(go,  (WIDTH//2 - go.get_width()//2,  HEIGHT//2 - 70))
            screen.blit(sc2, (WIDTH//2 - sc2.get_width()//2, HEIGHT//2))
            screen.blit(rt,  (WIDTH//2 - rt.get_width()//2,  HEIGHT//2 + 44))
            if gs["new_high"]:
                nb = font.render("NEW BEST!", True, GOLD)
                screen.blit(nb, (WIDTH//2 - nb.get_width()//2, HEIGHT//2 + 78))

        pygame.display.flip()

    pygame.quit(); sys.exit()
