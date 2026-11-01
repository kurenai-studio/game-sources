import os
os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "1"
import pygame
import random
import sys
import time
import copy
from highscores import get_high_score, save_high_score

GAME_NAME = "sudoku"
pygame.init()

WIDTH, HEIGHT = 700, 760
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Sudoku")
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


BG          = (245, 245, 255)
WHITE       = (255, 255, 255)
BLACK       = (0, 0, 0)
GRAY        = (180, 180, 180)
DARK_GRAY   = (80, 80, 80)
LIGHT_BLUE  = (200, 220, 255)
BLUE        = (30, 80, 200)
RED         = (200, 30, 30)
GREEN       = (0, 150, 0)
GOLD        = (200, 160, 0)
GIVEN_COLOR = (20, 20, 80)
USER_COLOR  = (30, 80, 200)
ERROR_COLOR = (220, 60, 60)
PENCIL_COL  = (100, 130, 180)
SEL_COLOR   = (180, 210, 255)
PEER_COLOR  = (225, 235, 248)
SAME_COLOR  = (190, 210, 240)
BOX_COLOR   = (240, 240, 250)

font        = pygame.font.SysFont("Arial", 18, bold=True)
small_font  = pygame.font.SysFont("Arial", 14)
big_font    = pygame.font.SysFont("Arial", 32, bold=True)
cell_font   = pygame.font.SysFont("Arial", 30, bold=True)
pencil_font = pygame.font.SysFont("Arial", 11)
clock       = pygame.time.Clock()

GRID_X, GRID_Y = 50, 100
CELL_SIZE = 60
GRID_SIZE = CELL_SIZE * 9

DIFFICULTIES = {"Easy": 36, "Medium": 28, "Hard": 22}

# ── Puzzle generator ─────────────────────────────────────────────────────────
def is_valid(board, row, col, num):
    if num in board[row]:
        return False
    if num in [board[r][col] for r in range(9)]:
        return False
    br, bc = (row // 3) * 3, (col // 3) * 3
    for r in range(br, br+3):
        for c in range(bc, bc+3):
            if board[r][c] == num:
                return False
    return True

def solve(board):
    # MRV heuristic: pick cell with fewest valid options first
    best, best_count = None, 10
    for r in range(9):
        for c in range(9):
            if board[r][c] == 0:
                count = sum(1 for n in range(1, 10) if is_valid(board, r, c, n))
                if count == 0:
                    return False
                if count < best_count:
                    best_count, best = count, (r, c)
                    if count == 1:
                        break
    if best is None:
        return True
    r, c = best
    nums = [n for n in range(1, 10) if is_valid(board, r, c, n)]
    random.shuffle(nums)
    for n in nums:
        board[r][c] = n
        if solve(board):
            return True
        board[r][c] = 0
    return False

def count_solutions(board, limit=2):
    count = [0]
    def _solve(b):
        if count[0] >= limit:
            return
        best, best_count = None, 10
        for r in range(9):
            for c in range(9):
                if b[r][c] == 0:
                    cnt = sum(1 for n in range(1, 10) if is_valid(b, r, c, n))
                    if cnt == 0:
                        return
                    if cnt < best_count:
                        best_count, best = cnt, (r, c)
                        if cnt == 1:
                            break
        if best is None:
            count[0] += 1
            return
        r, c = best
        for n in range(1, 10):
            if is_valid(b, r, c, n):
                b[r][c] = n
                _solve(b)
                b[r][c] = 0
    _solve([row[:] for row in board])
    return count[0]

def generate_puzzle(difficulty="Medium"):
    board = [[0]*9 for _ in range(9)]
    solve(board)
    solution = [row[:] for row in board]

    givens = DIFFICULTIES[difficulty]
    cells = [(r, c) for r in range(9) for c in range(9)]
    random.shuffle(cells)

    puzzle = [row[:] for row in board]
    removed = 0
    target_remove = 81 - givens

    for r, c in cells:
        if removed >= target_remove:
            break
        val = puzzle[r][c]
        puzzle[r][c] = 0
        if count_solutions(puzzle) == 1:
            removed += 1
        else:
            puzzle[r][c] = val

    return puzzle, solution


class Game:
    def __init__(self, difficulty="Medium"):
        self.difficulty = difficulty
        self.reset()

    def reset(self):
        # Show loading screen during puzzle generation
        screen.fill(BG)
        pygame.draw.rect(screen, (50, 80, 160), (0, 0, WIDTH, 90))
        loading = big_font.render("Generating puzzle...", True, WHITE)
        screen.blit(loading, loading.get_rect(center=(WIDTH//2, HEIGHT//2)))
        diff_t = font.render(self.difficulty, True, GOLD)
        screen.blit(diff_t, diff_t.get_rect(center=(WIDTH//2, HEIGHT//2 + 50)))
        pygame.display.flip()
        pygame.event.pump()
        self.puzzle, self.solution = generate_puzzle(self.difficulty)
        self.board   = [row[:] for row in self.puzzle]   # player's board
        self.pencil  = [[set() for _ in range(9)] for _ in range(9)]
        self.given   = [[self.puzzle[r][c] != 0 for c in range(9)] for r in range(9)]
        self.selected = None
        self.errors  = [[False]*9 for _ in range(9)]
        self.won     = False
        self.start_time = time.time()
        self.elapsed    = 0
        self.high_score = get_high_score(GAME_NAME)
        self.new_high   = False
        self.pencil_mode = False

    def select(self, row, col):
        self.selected = (row, col)

    def input_number(self, n):
        if not self.selected or self.won:
            return
        r, c = self.selected
        if self.given[r][c]:
            return
        if self.pencil_mode:
            if n == 0:
                self.pencil[r][c].clear()
            elif n in self.pencil[r][c]:
                self.pencil[r][c].remove(n)
            else:
                self.pencil[r][c].add(n)
        else:
            self.board[r][c] = n
            self.pencil[r][c].clear()
            # Remove this number from pencil marks in same row/col/box
            if n != 0:
                for i in range(9):
                    self.pencil[r][i].discard(n)
                    self.pencil[i][c].discard(n)
                br, bc = (r//3)*3, (c//3)*3
                for dr in range(3):
                    for dc in range(3):
                        self.pencil[br+dr][bc+dc].discard(n)
            self.validate()
            self.check_win()

    def validate(self):
        self.errors = [[False]*9 for _ in range(9)]
        for r in range(9):
            for c in range(9):
                v = self.board[r][c]
                if v != 0 and v != self.solution[r][c]:
                    self.errors[r][c] = True

    def check_win(self):
        for r in range(9):
            for c in range(9):
                if self.board[r][c] != self.solution[r][c]:
                    return
        self.won = True
        self.elapsed = time.time() - self.start_time
        score = max(0, 10000 - int(self.elapsed * 10))
        if save_high_score(GAME_NAME, score):
            self.new_high = True
        self.high_score = get_high_score(GAME_NAME)

    def get_peers(self, row, col):
        peers = set()
        for i in range(9):
            peers.add((row, i))
            peers.add((i, col))
        br, bc = (row//3)*3, (col//3)*3
        for dr in range(3):
            for dc in range(3):
                peers.add((br+dr, bc+dc))
        return peers

    def draw(self):
        screen.fill(BG)

        # Title / HUD
        pygame.draw.rect(screen, (50, 80, 160), (0, 0, WIDTH, 90))
        title = big_font.render("Sudoku", True, WHITE)
        screen.blit(title, (GRID_X, 12))
        diff_t = font.render(self.difficulty, True, GOLD)
        screen.blit(diff_t, (GRID_X + 160, 20))

        elapsed = self.elapsed if self.won else time.time() - self.start_time
        m, s = int(elapsed)//60, int(elapsed)%60
        time_t = font.render(f"{m:02d}:{s:02d}", True, WHITE)
        screen.blit(time_t, (WIDTH - 120, 20))
        hi_t = small_font.render(f"Best: {self.high_score}", True, GOLD)
        screen.blit(hi_t, (WIDTH - 120, 50))

        pencil_t = font.render(f"Pencil: {'ON' if self.pencil_mode else 'OFF'}", True,
                               (100,255,100) if self.pencil_mode else (200,200,200))
        screen.blit(pencil_t, (GRID_X + 300, 20))

        hint = small_font.render("P=pencil  Del=clear  E/M/H=difficulty  R=new", True, (180,200,255))
        screen.blit(hint, (GRID_X, 65))

        peers = self.get_peers(*self.selected) if self.selected else set()
        sel_val = self.board[self.selected[0]][self.selected[1]] if self.selected else 0

        # Draw cells
        for r in range(9):
            for c in range(9):
                x = GRID_X + c * CELL_SIZE
                y = GRID_Y + r * CELL_SIZE

                # Background
                if self.selected and (r, c) == self.selected:
                    bg = SEL_COLOR
                elif (r, c) in peers:
                    v = self.board[r][c]
                    bg = SAME_COLOR if (sel_val != 0 and v == sel_val) else PEER_COLOR
                elif (r//3 + c//3) % 2 == 0:
                    bg = BOX_COLOR
                else:
                    bg = WHITE
                pygame.draw.rect(screen, bg, (x, y, CELL_SIZE, CELL_SIZE))

                # Number
                val = self.board[r][c]
                if val != 0:
                    if self.errors[r][c]:
                        color = ERROR_COLOR
                    elif self.given[r][c]:
                        color = GIVEN_COLOR
                    else:
                        color = USER_COLOR
                    ns = cell_font.render(str(val), True, color)
                    screen.blit(ns, ns.get_rect(center=(x+CELL_SIZE//2, y+CELL_SIZE//2)))
                elif self.pencil[r][c]:
                    # Pencil marks (3x3 grid of tiny numbers)
                    for n in self.pencil[r][c]:
                        pr = (n-1) // 3
                        pc = (n-1) % 3
                        ps = pencil_font.render(str(n), True, PENCIL_COL)
                        screen.blit(ps, (x + 4 + pc*18, y + 4 + pr*17))

        # Grid lines
        for i in range(10):
            thick = 3 if i % 3 == 0 else 1
            color = DARK_GRAY if i % 3 == 0 else GRAY
            pygame.draw.line(screen, color,
                (GRID_X, GRID_Y + i*CELL_SIZE),
                (GRID_X + GRID_SIZE, GRID_Y + i*CELL_SIZE), thick)
            pygame.draw.line(screen, color,
                (GRID_X + i*CELL_SIZE, GRID_Y),
                (GRID_X + i*CELL_SIZE, GRID_Y + GRID_SIZE), thick)

        # Number buttons
        btn_y = GRID_Y + GRID_SIZE + 20
        for n in range(1, 10):
            bx = GRID_X + (n-1) * (CELL_SIZE + 2)
            br = pygame.Rect(bx, btn_y, CELL_SIZE, 48)
            # Count how many of this number are placed
            placed = sum(1 for row in self.board for v in row if v == n)
            done = placed >= 9
            col = (120,120,120) if done else (50, 80, 160)
            pygame.draw.rect(screen, col, br, border_radius=6)
            ns = cell_font.render(str(n), True, WHITE if not done else GRAY)
            screen.blit(ns, ns.get_rect(center=br.center))

        if self.won:
            overlay = pygame.Surface((WIDTH,HEIGHT), pygame.SRCALPHA)
            overlay.fill((0,0,0,150))
            screen.blit(overlay, (0,0))
            wt = big_font.render("Solved!", True, GOLD)
            st = font.render(f"Time: {m:02d}:{s:02d}", True, WHITE)
            rt = font.render("R = new game  |  E/M/H = difficulty", True, WHITE)
            screen.blit(wt, wt.get_rect(center=(WIDTH//2, HEIGHT//2-50)))
            screen.blit(st, st.get_rect(center=(WIDTH//2, HEIGHT//2)))
            screen.blit(rt, rt.get_rect(center=(WIDTH//2, HEIGHT//2+40)))
            if self.new_high:
                nb = font.render("NEW BEST SCORE!", True, GOLD)
                screen.blit(nb, nb.get_rect(center=(WIDTH//2, HEIGHT//2+70)))

    def handle_click(self, mx, my):
        # Grid click
        if (GRID_X <= mx < GRID_X + GRID_SIZE and
                GRID_Y <= my < GRID_Y + GRID_SIZE):
            c = (mx - GRID_X) // CELL_SIZE
            r = (my - GRID_Y) // CELL_SIZE
            self.select(r, c)
            return
        # Number buttons
        btn_y = GRID_Y + GRID_SIZE + 20
        for n in range(1, 10):
            bx = GRID_X + (n-1) * (CELL_SIZE + 2)
            if pygame.Rect(bx, btn_y, CELL_SIZE, 48).collidepoint(mx, my):
                self.input_number(n)
                return


game = Game("Medium")
running = True
while running:
    clock.tick(60)
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            game.handle_click(*event.pos)
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_r:
                game.reset()
            elif event.key == pygame.K_e:
                game = Game("Easy")
            elif event.key == pygame.K_m:
                game = Game("Medium")
            elif event.key == pygame.K_h:
                game = Game("Hard")
            elif event.key == pygame.K_p:
                game.pencil_mode = not game.pencil_mode
            elif event.key in (pygame.K_DELETE, pygame.K_BACKSPACE):
                game.input_number(0)
            elif pygame.K_1 <= event.key <= pygame.K_9:
                game.input_number(event.key - pygame.K_0)
            elif event.key in (pygame.K_UP, pygame.K_DOWN, pygame.K_LEFT, pygame.K_RIGHT):
                if game.selected:
                    r, c = game.selected
                    if event.key == pygame.K_UP:    r = max(0, r-1)
                    if event.key == pygame.K_DOWN:  r = min(8, r+1)
                    if event.key == pygame.K_LEFT:  c = max(0, c-1)
                    if event.key == pygame.K_RIGHT: c = min(8, c+1)
                    game.select(r, c)

    game.draw()
    pygame.display.flip()

pygame.quit()
sys.exit()
