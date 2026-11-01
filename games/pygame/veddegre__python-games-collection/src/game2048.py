import os
os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "1"
import pygame
import random
import sys
from highscores import get_high_score, save_high_score

GAME_NAME = "2048"
pygame.init()

WIDTH, HEIGHT = 520, 660
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("2048")
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


# Tile colors
TILE_COLORS = {
    0:    (50,  55,  80),
    2:    (238, 228, 218),
    4:    (237, 224, 200),
    8:    (242, 177, 121),
    16:   (245, 149, 99),
    32:   (246, 124, 95),
    64:   (246, 94,  59),
    128:  (237, 207, 114),
    256:  (237, 204, 97),
    512:  (237, 200, 80),
    1024: (237, 197, 63),
    2048: (237, 194, 46),
    4096: (60,  180, 120),
    8192: (40,  160, 100),
}
TEXT_DARK  = (119, 110, 101)
TEXT_LIGHT = (249, 246, 242)

def tile_text_color(val):
    return TEXT_DARK if val in (2, 4) else TEXT_LIGHT

BG        = (18,  20,  38)
GRID_BG   = (30,  34,  58)
PANEL     = (26,  30,  54)
WHITE     = (255, 255, 255)
GRAY      = (120, 120, 140)
GOLD      = (255, 210, 50)
BLACK     = (0,   0,   0)

GRID_SIZE  = 4
CELL_SIZE  = 108
GRID_PAD   = 12
GRID_X     = (WIDTH - (GRID_SIZE * CELL_SIZE + (GRID_SIZE + 1) * GRID_PAD)) // 2
GRID_Y     = 160
GRID_W     = GRID_SIZE * CELL_SIZE + (GRID_SIZE + 1) * GRID_PAD

title_font = pygame.font.SysFont("Arial", 48, bold=True)
tile_fonts = {
    1: pygame.font.SysFont("Arial", 42, bold=True),   # 1-3 digit
    2: pygame.font.SysFont("Arial", 36, bold=True),   # 4 digit
    3: pygame.font.SysFont("Arial", 28, bold=True),   # 5+ digit
}
info_font  = pygame.font.SysFont("Arial", 18)
small_font = pygame.font.SysFont("Arial", 14)
score_font = pygame.font.SysFont("Arial", 22, bold=True)
clock      = pygame.time.Clock()

def get_tile_font(val):
    digits = len(str(val))
    if digits <= 3: return tile_fonts[1]
    if digits == 4: return tile_fonts[2]
    return tile_fonts[3]

def get_tile_color(val):
    return TILE_COLORS.get(val, (30, 120, 80))


class Game:
    def __init__(self):
        self.reset()

    def reset(self):
        self.board      = [[0]*GRID_SIZE for _ in range(GRID_SIZE)]
        self.score      = 0
        self.best       = get_high_score(GAME_NAME)
        self.new_best   = False
        self.won        = False
        self.over       = False
        self.keep_going = False  # continue after 2048
        self.prev_board = None
        self.prev_score = 0
        self.add_tile()
        self.add_tile()

    def add_tile(self):
        empty = [(r, c) for r in range(GRID_SIZE)
                         for c in range(GRID_SIZE) if self.board[r][c] == 0]
        if empty:
            r, c = random.choice(empty)
            self.board[r][c] = 4 if random.random() < 0.1 else 2

    def save_state(self):
        self.prev_board = [row[:] for row in self.board]
        self.prev_score = self.score

    def undo(self):
        if self.prev_board:
            self.board = [row[:] for row in self.prev_board]
            self.score = self.prev_score
            self.prev_board = None
            self.over  = False

    def slide_row_left(self, row):
        tiles = [x for x in row if x != 0]
        merged = []
        skip = False
        points = 0
        for i in range(len(tiles)):
            if skip:
                skip = False
                continue
            if i + 1 < len(tiles) and tiles[i] == tiles[i+1]:
                val = tiles[i] * 2
                merged.append(val)
                points += val
                skip = True
            else:
                merged.append(tiles[i])
        merged += [0] * (GRID_SIZE - len(merged))
        return merged, points

    def move(self, direction):
        """direction: 'left','right','up','down'. Returns True if board changed."""
        self.save_state()
        moved = False
        total_pts = 0

        def rotate_cw(b):
            return [[b[GRID_SIZE-1-c][r] for c in range(GRID_SIZE)] for r in range(GRID_SIZE)]
        def rotate_ccw(b):
            return [[b[r][GRID_SIZE-1-c] for r in range(GRID_SIZE)] for c in range(GRID_SIZE)]

        b = [row[:] for row in self.board]

        if direction == "right":
            b = [row[::-1] for row in b]
        elif direction == "up":
            b = rotate_ccw(b)
        elif direction == "down":
            b = rotate_cw(b)

        new_b = []
        for row in b:
            new_row, pts = self.slide_row_left(row)
            new_b.append(new_row)
            total_pts += pts
            if new_row != row:
                moved = True

        if direction == "right":
            new_b = [row[::-1] for row in new_b]
        elif direction == "up":
            new_b = rotate_cw(new_b)
        elif direction == "down":
            new_b = rotate_ccw(new_b)

        if moved:
            self.board = new_b
            self.score += total_pts
            self.add_tile()
            # Check win
            if not self.keep_going:
                for row in self.board:
                    if 2048 in row:
                        self.won = True
            # Check game over
            if not self.can_move():
                self.over = True
                if save_high_score(GAME_NAME, self.score):
                    self.new_best = True
                self.best = get_high_score(GAME_NAME)
            # Update best mid-game
            if self.score > self.best:
                save_high_score(GAME_NAME, self.score)
                self.best = self.score
        else:
            self.prev_board = None  # no state change, don't waste undo slot

        return moved

    def can_move(self):
        for r in range(GRID_SIZE):
            for c in range(GRID_SIZE):
                if self.board[r][c] == 0:
                    return True
                if c+1 < GRID_SIZE and self.board[r][c] == self.board[r][c+1]:
                    return True
                if r+1 < GRID_SIZE and self.board[r][c] == self.board[r+1][c]:
                    return True
        return False

    def draw(self):
        screen.fill(BG)

        # Title & scores
        pygame.draw.rect(screen, PANEL, (0, 0, WIDTH, 148))
        pygame.draw.line(screen, (40, 46, 80), (0, 148), (WIDTH, 148), 1)

        title_s = title_font.render("2048", True, GOLD)
        screen.blit(title_s, (GRID_X, 14))

        # Score boxes
        for i, (label, val) in enumerate([("SCORE", self.score), ("BEST", self.best)]):
            bx = GRID_X + GRID_W - 220 + i * 114
            br = pygame.Rect(bx, 14, 104, 60)
            pygame.draw.rect(screen, (40, 46, 80), br, border_radius=8)
            lbl_s = small_font.render(label, True, GRAY)
            screen.blit(lbl_s, lbl_s.get_rect(centerx=br.centerx, y=br.y+8))
            val_s = score_font.render(str(val), True, WHITE)
            screen.blit(val_s, val_s.get_rect(centerx=br.centerx, y=br.y+28))

        # Controls hint
        hint = small_font.render("Arrow keys or WASD to move  |  U = undo  |  R = new game", True, GRAY)
        screen.blit(hint, hint.get_rect(centerx=WIDTH//2, y=90))
        ctrl2 = small_font.render("Merge tiles to reach  2048!", True, (100, 120, 180))
        screen.blit(ctrl2, ctrl2.get_rect(centerx=WIDTH//2, y=112))

        # Grid background
        pygame.draw.rect(screen, GRID_BG,
            (GRID_X - GRID_PAD, GRID_Y - GRID_PAD,
             GRID_W + GRID_PAD*2, GRID_W + GRID_PAD*2), border_radius=10)

        # Tiles
        for r in range(GRID_SIZE):
            for c in range(GRID_SIZE):
                val = self.board[r][c]
                tx = GRID_X + c * (CELL_SIZE + GRID_PAD)
                ty = GRID_Y + r * (CELL_SIZE + GRID_PAD)
                color = get_tile_color(val)
                pygame.draw.rect(screen, color, (tx, ty, CELL_SIZE, CELL_SIZE), border_radius=8)
                if val != 0:
                    f = get_tile_font(val)
                    ts = f.render(str(val), True, tile_text_color(val))
                    screen.blit(ts, ts.get_rect(center=(tx+CELL_SIZE//2, ty+CELL_SIZE//2)))

        # Win overlay (shows once, can keep going)
        if self.won and not self.keep_going:
            overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
            overlay.fill((0, 0, 0, 160))
            screen.blit(overlay, (0, 0))
            wt = title_font.render("You reached 2048!", True, GOLD)
            screen.blit(wt, wt.get_rect(center=(WIDTH//2, HEIGHT//2 - 60)))
            ct = info_font.render("Press C to keep going  |  R for new game", True, WHITE)
            screen.blit(ct, ct.get_rect(center=(WIDTH//2, HEIGHT//2)))

        # Game over overlay
        if self.over:
            overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
            overlay.fill((0, 0, 0, 170))
            screen.blit(overlay, (0, 0))
            gt = title_font.render("Game Over!", True, (220, 80, 80))
            screen.blit(gt, gt.get_rect(center=(WIDTH//2, HEIGHT//2 - 60)))
            st = info_font.render(f"Score: {self.score}", True, WHITE)
            screen.blit(st, st.get_rect(center=(WIDTH//2, HEIGHT//2 - 10)))
            rt = info_font.render("Press R for a new game", True, WHITE)
            screen.blit(rt, rt.get_rect(center=(WIDTH//2, HEIGHT//2 + 30)))
            if self.new_best:
                nb = info_font.render("NEW BEST SCORE!", True, GOLD)
                screen.blit(nb, nb.get_rect(center=(WIDTH//2, HEIGHT//2 + 65)))


game = Game()
running = True

while running:
    clock.tick(60)
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False

        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_r:
                game.reset()
            elif event.key == pygame.K_u:
                game.undo()
            elif event.key == pygame.K_c and game.won and not game.keep_going:
                game.keep_going = True
                game.won = False
            elif not game.over and not (game.won and not game.keep_going):
                if event.key in (pygame.K_LEFT,  pygame.K_a): game.move("left")
                elif event.key in (pygame.K_RIGHT, pygame.K_d): game.move("right")
                elif event.key in (pygame.K_UP,    pygame.K_w): game.move("up")
                elif event.key in (pygame.K_DOWN,  pygame.K_s): game.move("down")

    game.draw()
    pygame.display.flip()

pygame.quit()
sys.exit()
