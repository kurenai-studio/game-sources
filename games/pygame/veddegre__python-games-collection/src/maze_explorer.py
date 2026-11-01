import os
os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "1"
import pygame
import random
import sys
import time
from highscores import get_low_score, save_low_score, get_best_time, save_best_time

TIME_KEY = "maze_explorer_time"

GAME_NAME = "maze_explorer"

# Initialize pygame
pygame.init()

# Screen settings
CELL_SIZE = 40
MAZE_WIDTH, MAZE_HEIGHT = 17, 17
WIDTH, HEIGHT = CELL_SIZE * MAZE_WIDTH, CELL_SIZE * MAZE_HEIGHT + 50  # Extra bar at top
MAZE_OFFSET_Y = 50  # Maze drawn below HUD
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Maze Explorer")
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
RED = (200, 0, 0)
BLUE = (0, 0, 200)
GOLD = (255, 215, 0)
GRAY = (100, 100, 100)
DARK_RED = (180, 0, 0)
LIGHT_RED = (255, 50, 50)
DARK_GREEN = (0, 120, 0)
LIGHT_GREEN = (0, 255, 0)

# Game variables
clock = pygame.time.Clock()
font = pygame.font.SysFont(None, 36)
small_font = pygame.font.SysFont(None, 26)

class Button:
    def __init__(self, x, y, width, height, text, action=None, colors=(DARK_GREEN, LIGHT_GREEN)):
        self.rect = pygame.Rect(x, y, width, height)
        self.text = text
        self.action = action
        self.is_hovered = False
        self.colors = colors  # (normal_color, hover_color)
    
    def draw(self):
        # Draw the button
        color = self.colors[1] if self.is_hovered else self.colors[0]
        pygame.draw.rect(screen, color, self.rect, border_radius=10)
        pygame.draw.rect(screen, WHITE, self.rect, 2, border_radius=10)
        
        # Draw the text
        text_surf = small_font.render(self.text, True, WHITE)
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

class Cell:
    def __init__(self, row, col):
        self.row = row
        self.col = col
        self.walls = {"top": True, "right": True, "bottom": True, "left": True}

    def draw(self):
        x, y = self.col * CELL_SIZE, self.row * CELL_SIZE + MAZE_OFFSET_Y
        pygame.draw.rect(screen, BLACK, (x, y, CELL_SIZE, CELL_SIZE))
        if self.walls["top"]:
            pygame.draw.line(screen, WHITE, (x, y), (x + CELL_SIZE, y), 2)
        if self.walls["right"]:
            pygame.draw.line(screen, WHITE, (x + CELL_SIZE, y), (x + CELL_SIZE, y + CELL_SIZE), 2)
        if self.walls["bottom"]:
            pygame.draw.line(screen, WHITE, (x, y + CELL_SIZE), (x + CELL_SIZE, y + CELL_SIZE), 2)
        if self.walls["left"]:
            pygame.draw.line(screen, WHITE, (x, y), (x, y + CELL_SIZE), 2)

def _new_open_grid():
    """Fully open interior; outer border stays walled."""
    grid = [[Cell(row, col) for col in range(MAZE_WIDTH)] for row in range(MAZE_HEIGHT)]
    for row in grid:
        for cell in row:
            cell.walls = {"top": False, "right": False, "bottom": False, "left": False}
    for c in range(MAZE_WIDTH):
        grid[0][c].walls["top"] = True
        grid[MAZE_HEIGHT - 1][c].walls["bottom"] = True
    for r in range(MAZE_HEIGHT):
        grid[r][0].walls["left"] = True
        grid[r][MAZE_WIDTH - 1].walls["right"] = True
    return grid


def _divide_region(grid, r0, c0, height, width):
    """Recursive division: add walls with a single gap (room-like, winding layout)."""
    if height < 2 or width < 2:
        return
    can_split_h = height >= 3
    can_split_v = width >= 3
    if not can_split_h and not can_split_v:
        return
    use_vertical = can_split_v and (
        not can_split_h or width > height or (width == height and random.random() < 0.5)
    )
    if use_vertical:
        wall_col = random.randrange(c0 + 1, c0 + width)
        gap_row = random.randrange(r0, r0 + height)
        for r in range(r0, r0 + height):
            if r == gap_row:
                continue
            grid[r][wall_col - 1].walls["right"] = True
            grid[r][wall_col].walls["left"] = True
        _divide_region(grid, r0, c0, height, wall_col - c0)
        _divide_region(grid, r0, wall_col, height, c0 + width - wall_col)
    else:
        wall_row = random.randrange(r0 + 1, r0 + height)
        gap_col = random.randrange(c0, c0 + width)
        for c in range(c0, c0 + width):
            if c == gap_col:
                continue
            grid[wall_row - 1][c].walls["bottom"] = True
            grid[wall_row][c].walls["top"] = True
        _divide_region(grid, r0, c0, wall_row - r0, width)
        _divide_region(grid, wall_row, c0, r0 + height - wall_row, width)


def _generate_division_maze():
    grid = _new_open_grid()
    _divide_region(grid, 0, 0, MAZE_HEIGHT, MAZE_WIDTH)
    return grid


def _path_length(grid, start, goal):
    """BFS distance along open passages (unique path in a perfect maze)."""
    sr, sc = start
    gr, gc = goal
    if (sr, sc) == (gr, gc):
        return 0
    seen = {(sr, sc)}
    queue = [(sr, sc, 0)]
    while queue:
        r, c, steps = queue.pop(0)
        cell = grid[r][c]
        for dr, dc, wall in (
            (-1, 0, "top"),
            (1, 0, "bottom"),
            (0, -1, "left"),
            (0, 1, "right"),
        ):
            if cell.walls[wall]:
                continue
            nr, nc = r + dr, c + dc
            if (nr, nc) == (gr, gc):
                return steps + 1
            if (nr, nc) in seen:
                continue
            seen.add((nr, nc))
            queue.append((nr, nc, steps + 1))
    return 0


def generate_maze(goal):
    """Pick the longest start→goal route among many division mazes (one path, no loops)."""
    goal_t = tuple(goal)
    best_grid = None
    best_len = -1
    for _ in range(150):
        grid = _generate_division_maze()
        plen = _path_length(grid, (0, 0), goal_t)
        if plen > best_len:
            best_len = plen
            best_grid = grid
    return best_grid


def can_move(player, direction, grid):
    row, col = player
    if direction == "up" and not grid[row][col].walls["top"]:
        return True
    if direction == "right" and not grid[row][col].walls["right"]:
        return True
    if direction == "down" and not grid[row][col].walls["bottom"]:
        return True
    if direction == "left" and not grid[row][col].walls["left"]:
        return True
    return False

def reset_game(goal):
    grid = generate_maze(goal)
    player = [0, 0]
    return grid, player, False, time.time(), 0

def draw_hud(moves, elapsed, best_moves, best_time):
    pygame.draw.rect(screen, (0, 0, 40), (0, 0, WIDTH, MAZE_OFFSET_Y))
    pygame.draw.line(screen, GRAY, (0, MAZE_OFFSET_Y - 1), (WIDTH, MAZE_OFFSET_Y - 1), 1)
    moves_text = small_font.render(f"Moves: {moves}", True, WHITE)
    screen.blit(moves_text, (10, 14))
    time_text = small_font.render(f"Time: {elapsed:.1f}s", True, WHITE)
    screen.blit(time_text, (WIDTH // 2 - time_text.get_width() // 2, 14))
    best_parts = []
    if best_moves is not None:
        best_parts.append(f"{best_moves} moves")
    if best_time is not None:
        best_parts.append(f"{best_time:.1f}s")
    if best_parts:
        best_text = small_font.render("Best: " + "  |  ".join(best_parts), True, GOLD)
        screen.blit(best_text, (WIDTH - best_text.get_width() - 10, 14))

def main():
    goal = [MAZE_HEIGHT - 1, MAZE_WIDTH - 1]
    grid = generate_maze(goal)
    player = [0, 0]
    win = False
    start_time = time.time()
    moves = 0
    win_elapsed = None
    best_moves = get_low_score(GAME_NAME)
    best_time = get_best_time(TIME_KEY)
    new_best = False

    button_width = 180
    button_height = 50
    win_overlay_y = HEIGHT // 2

    def do_restart():
        nonlocal grid, player, win, start_time, moves, new_best
        grid, player, win, start_time, moves = reset_game(goal)
        new_best = False
        return True

    restart_button = Button(WIDTH//2 - button_width - 10, win_overlay_y + 70,
                            button_width, button_height, "Restart", do_restart)
    quit_button = Button(WIDTH//2 + 10, win_overlay_y + 70,
                         button_width, button_height, "Quit Game",
                         lambda: pygame.event.post(pygame.event.Event(pygame.QUIT)),
                         colors=(DARK_RED, LIGHT_RED))

    running = True
    while running:
        mouse_pos = pygame.mouse.get_pos()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    running = False

            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_r and win:
                    do_restart()
                elif not win:
                    moved = False
                    if event.key == pygame.K_UP and can_move(player, "up", grid):
                        player[0] -= 1; moved = True
                    elif event.key == pygame.K_RIGHT and can_move(player, "right", grid):
                        player[1] += 1; moved = True
                    elif event.key == pygame.K_DOWN and can_move(player, "down", grid):
                        player[0] += 1; moved = True
                    elif event.key == pygame.K_LEFT and can_move(player, "left", grid):
                        player[1] -= 1; moved = True
                    if moved:
                        moves += 1

            if win:
                if restart_button.handle_event(event):
                    pass
                quit_button.handle_event(event)

        if player == goal and not win:
            win = True
            win_elapsed = time.time() - start_time
            new_best = save_low_score(GAME_NAME, moves) or save_best_time(TIME_KEY, win_elapsed)
            best_moves = get_low_score(GAME_NAME)
            best_time = get_best_time(TIME_KEY)

        elapsed = win_elapsed if win_elapsed is not None else (time.time() - start_time)

        # Drawing
        screen.fill(BLACK)

        # HUD
        draw_hud(moves, elapsed, best_moves, best_time)

        # Maze
        for row in grid:
            for cell in row:
                cell.draw()

        # Goal
        goal_x = goal[1] * CELL_SIZE + CELL_SIZE // 2
        goal_y = goal[0] * CELL_SIZE + CELL_SIZE // 2 + MAZE_OFFSET_Y
        pygame.draw.circle(screen, GOLD, (goal_x, goal_y), CELL_SIZE // 3)

        # Player
        player_x = player[1] * CELL_SIZE + CELL_SIZE // 2
        player_y = player[0] * CELL_SIZE + CELL_SIZE // 2 + MAZE_OFFSET_Y
        pygame.draw.circle(screen, RED, (player_x, player_y), CELL_SIZE // 3)

        if win:
            overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
            overlay.fill((0, 0, 0, 180))
            screen.blit(overlay, (0, 0))

            win_text = font.render("You Win!", True, GREEN)
            screen.blit(win_text, win_text.get_rect(center=(WIDTH // 2, win_overlay_y - 20)))

            stats_text = small_font.render(f"{moves} moves  |  {elapsed:.1f}s", True, WHITE)
            screen.blit(stats_text, stats_text.get_rect(center=(WIDTH // 2, win_overlay_y + 20)))

            if new_best:
                nb_text = small_font.render("New Best!", True, GOLD)
                screen.blit(nb_text, nb_text.get_rect(center=(WIDTH // 2, win_overlay_y + 44)))

            r_text = small_font.render("Press R to restart", True, WHITE)
            screen.blit(r_text, r_text.get_rect(center=(WIDTH // 2, win_overlay_y + 140)))

            restart_button.check_hover(mouse_pos)
            quit_button.check_hover(mouse_pos)
            restart_button.draw()
            quit_button.draw()

        pygame.display.flip()
        clock.tick(60)

    pygame.quit()
    sys.exit()

if __name__ == "__main__":
    main()
