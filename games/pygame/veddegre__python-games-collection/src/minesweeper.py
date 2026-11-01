import os
os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "1"
import pygame
import random
import sys
import time
from highscores import get_high_score, save_high_score

GAME_NAME = "minesweeper"
pygame.init()

CELL  = 36
COLS, ROWS = 16, 16
MINES = 40
HUD_H = 60
WIDTH  = COLS * CELL
HEIGHT = ROWS * CELL + HUD_H
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Minesweeper")
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


BLACK   = (0, 0, 0)
WHITE   = (255, 255, 255)
GRAY    = (180, 180, 180)
DARK_G  = (100, 100, 100)
LGRAY   = (210, 210, 210)
RED     = (220, 40, 40)
YELLOW  = (255, 215, 0)
GREEN   = (0, 180, 0)
BLUE    = (0, 80, 220)
BG      = (30, 30, 50)
CELL_COV= (70, 90, 130)
CELL_REV= (200, 200, 215)
FLAG_R  = (220, 50, 50)

NUM_COLORS = [None, BLUE, GREEN, RED, (0,0,128), (128,0,0), (0,128,128), BLACK, DARK_G]

font       = pygame.font.SysFont("Arial", 22, bold=True)
small_font = pygame.font.SysFont("Arial", 18)
big_font   = pygame.font.SysFont("Arial", 34, bold=True)
clock      = pygame.time.Clock()

def make_grid():
    return [[{"mine": False, "revealed": False, "flagged": False, "adj": 0}
             for _ in range(COLS)] for _ in range(ROWS)]

def place_mines(grid, avoid_r, avoid_c):
    placed = 0
    while placed < MINES:
        r = random.randint(0, ROWS - 1)
        c = random.randint(0, COLS - 1)
        if not grid[r][c]["mine"] and (abs(r - avoid_r) > 1 or abs(c - avoid_c) > 1):
            grid[r][c]["mine"] = True
            placed += 1
    # Compute adjacency counts
    for r in range(ROWS):
        for c in range(COLS):
            if grid[r][c]["mine"]:
                continue
            count = 0
            for dr in (-1, 0, 1):
                for dc in (-1, 0, 1):
                    nr, nc = r + dr, c + dc
                    if 0 <= nr < ROWS and 0 <= nc < COLS and grid[nr][nc]["mine"]:
                        count += 1
            grid[r][c]["adj"] = count

def reveal(grid, r, c):
    if not (0 <= r < ROWS and 0 <= c < COLS):
        return
    cell = grid[r][c]
    if cell["revealed"] or cell["flagged"]:
        return
    cell["revealed"] = True
    if cell["adj"] == 0 and not cell["mine"]:
        for dr in (-1, 0, 1):
            for dc in (-1, 0, 1):
                if dr == 0 and dc == 0:
                    continue
                reveal(grid, r + dr, c + dc)

def count_flags(grid):
    return sum(grid[r][c]["flagged"] for r in range(ROWS) for c in range(COLS))

def check_win(grid):
    for r in range(ROWS):
        for c in range(COLS):
            cell = grid[r][c]
            if not cell["mine"] and not cell["revealed"]:
                return False
    return True  # All non-mine cells revealed = win (mines stay hidden/flagged)

def reveal_all_mines(grid):
    for r in range(ROWS):
        for c in range(COLS):
            if grid[r][c]["mine"]:
                grid[r][c]["revealed"] = True

def draw_cell(r, c, cell, hit_r=None, hit_c=None):
    x = c * CELL
    y = r * CELL + HUD_H
    if cell["revealed"]:
        color = RED if (cell["mine"] and r == hit_r and c == hit_c) else \
                (255, 100, 100) if cell["mine"] else CELL_REV
        pygame.draw.rect(screen, color, (x, y, CELL, CELL))
        pygame.draw.rect(screen, DARK_G, (x, y, CELL, CELL), 1)
        if cell["mine"]:
            pygame.draw.circle(screen, BLACK, (x + CELL // 2, y + CELL // 2), CELL // 4)
        elif cell["adj"] > 0:
            num = font.render(str(cell["adj"]), True, NUM_COLORS[cell["adj"]])
            screen.blit(num, num.get_rect(center=(x + CELL // 2, y + CELL // 2)))
    else:
        pygame.draw.rect(screen, CELL_COV, (x, y, CELL, CELL))
        pygame.draw.rect(screen, (100, 120, 160), (x, y, CELL, CELL), 1)
        # 3D bevel
        pygame.draw.line(screen, (120, 150, 200), (x, y), (x + CELL - 1, y), 2)
        pygame.draw.line(screen, (120, 150, 200), (x, y), (x, y + CELL - 1), 2)
        pygame.draw.line(screen, (40, 55, 90), (x + CELL - 1, y), (x + CELL - 1, y + CELL - 1), 2)
        pygame.draw.line(screen, (40, 55, 90), (x, y + CELL - 1), (x + CELL - 1, y + CELL - 1), 2)
        if cell["flagged"]:
            # Flag pole
            pygame.draw.line(screen, BLACK, (x + CELL // 2, y + 8), (x + CELL // 2, y + CELL - 8), 2)
            # Flag
            pygame.draw.polygon(screen, FLAG_R, [
                (x + CELL // 2, y + 8),
                (x + CELL - 8, y + 14),
                (x + CELL // 2, y + 20)
            ])

def draw_hud(flags_left, elapsed, high_score, game_over, won):
    pygame.draw.rect(screen, BG, (0, 0, WIDTH, HUD_H))
    pygame.draw.line(screen, DARK_G, (0, HUD_H - 1), (WIDTH, HUD_H - 1), 1)

    mine_surf = font.render(f"Mines: {max(0, MINES - flags_left)}/{MINES}", True, RED)
    screen.blit(mine_surf, (10, 18))

    t = elapsed if not (won or game_over) else elapsed
    time_surf = font.render(f"Time: {t:.0f}s", True, WHITE)
    screen.blit(time_surf, (WIDTH // 2 - time_surf.get_width() // 2, 18))

    hi_surf = small_font.render(f"Best: {high_score}s" if high_score else "Best: --", True, YELLOW)
    screen.blit(hi_surf, (WIDTH - hi_surf.get_width() - 10, 20))

def reset():
    return (make_grid(), False, False, False, None, None,
            None, get_high_score(GAME_NAME), False)

grid, game_over, won, mines_placed, hit_r, hit_c, start_time, high_score, new_high = reset()
running = True
elapsed = 0

while running:
    clock.tick(60)
    if start_time and not game_over and not won:
        elapsed = time.time() - start_time

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_r:
                grid, game_over, won, mines_placed, hit_r, hit_c, start_time, high_score, new_high = reset()
                elapsed = 0

        if event.type == pygame.MOUSEBUTTONDOWN:
            mx, my = event.pos
            if my < HUD_H:
                continue
            c = mx // CELL
            r = (my - HUD_H) // CELL
            if not (0 <= r < ROWS and 0 <= c < COLS):
                continue
            cell = grid[r][c]

            if event.button == 1 and not game_over and not won:  # Left click
                if cell["flagged"]:
                    continue
                if cell["revealed"] and cell["adj"] > 0:
                    # Chord click: if flagged neighbours == adj number, reveal all unflagged neighbours
                    flagged_around = sum(
                        1 for dr in (-1,0,1) for dc in (-1,0,1)
                        if (dr or dc) and 0 <= r+dr < ROWS and 0 <= c+dc < COLS
                        and grid[r+dr][c+dc]["flagged"]
                    )
                    if flagged_around == cell["adj"]:
                        for dr in (-1,0,1):
                            for dc in (-1,0,1):
                                if (dr or dc) and 0 <= r+dr < ROWS and 0 <= c+dc < COLS:
                                    nb = grid[r+dr][c+dc]
                                    if not nb["flagged"] and not nb["revealed"]:
                                        if nb["mine"]:
                                            game_over = True
                                            hit_r, hit_c = r+dr, c+dc
                                            reveal_all_mines(grid)
                                        else:
                                            reveal(grid, r+dr, c+dc)
                    if not game_over and check_win(grid):
                        won = True
                        elapsed = time.time() - start_time
                        if not high_score or elapsed < high_score:
                            from highscores import load_scores
                            import json, os
                            scores = load_scores()
                            if "minesweeper_time" not in scores or elapsed < scores["minesweeper_time"]:
                                scores["minesweeper_time"] = elapsed
                                with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "scores.json"), "w") as f:
                                    json.dump(scores, f, indent=2)
                                new_high = True
                            high_score = scores.get("minesweeper_time", None)
                    continue
                if cell["revealed"]:
                    continue
                if not mines_placed:
                    place_mines(grid, r, c)
                    mines_placed = True
                    start_time = time.time()
                if cell["mine"]:
                    game_over = True
                    hit_r, hit_c = r, c
                    reveal_all_mines(grid)
                else:
                    reveal(grid, r, c)
                if not game_over and check_win(grid):
                        won = True
                        elapsed = time.time() - start_time
                        if not high_score or elapsed < high_score:
                            from highscores import save_high_score as shs, load_scores
                            import json, os
                            scores = load_scores()
                            if "minesweeper_time" not in scores or elapsed < scores["minesweeper_time"]:
                                scores["minesweeper_time"] = elapsed
                                with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "scores.json"), "w") as f:
                                    json.dump(scores, f, indent=2)
                                new_high = True
                            high_score = scores.get("minesweeper_time", None)

            elif event.button == 3 and not game_over and not won:  # Right click - flag
                if not cell["revealed"]:
                    cell["flagged"] = not cell["flagged"]

    # Draw
    screen.fill((50, 60, 80))
    for r in range(ROWS):
        for c in range(COLS):
            draw_cell(r, c, grid[r][c], hit_r, hit_c)

    draw_hud(count_flags(grid), elapsed, 
             f"{high_score:.0f}" if high_score else None,
             game_over, won)

    if game_over or won:
        overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 150))
        screen.blit(overlay, (0, 0))
        if won:
            msg = big_font.render("YOU WIN!", True, GREEN)
            sub = font.render(f"Time: {elapsed:.1f}s", True, WHITE)
        else:
            msg = big_font.render("BOOM!", True, RED)
            sub = font.render("You hit a mine!", True, WHITE)
        rst = small_font.render("Press R to restart", True, WHITE)
        screen.blit(msg, (WIDTH // 2 - msg.get_width() // 2, HEIGHT // 2 - 60))
        screen.blit(sub, (WIDTH // 2 - sub.get_width() // 2, HEIGHT // 2 - 10))
        screen.blit(rst, (WIDTH // 2 - rst.get_width() // 2, HEIGHT // 2 + 30))
        if new_high:
            nb = font.render("NEW BEST TIME!", True, YELLOW)
            screen.blit(nb, (WIDTH // 2 - nb.get_width() // 2, HEIGHT // 2 + 58))

    pygame.display.flip()

pygame.quit()
sys.exit()
