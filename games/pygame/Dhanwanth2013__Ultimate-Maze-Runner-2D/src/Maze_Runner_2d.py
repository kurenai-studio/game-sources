import pygame
import random
import sys
import os
import json
from collections import deque
import copy

# Initialization
pygame.init()
clock = pygame.time.Clock()

# Constants and default values
DEFAULT_MAZE_SIZE = 21  # Must be odd
MAZE_PIXEL_SIZE = 630   # The desired pixel width/height of the maze area (e.g. 630px)
INFO_BAR_HEIGHT = 100  # For info bar height
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
screen = None

SAVE_FILE = "maze_save.json"
LEADERBOARD_FILE = "leaderboard.json"
KEY_BINDINGS_FILE = "key_bindings.json"
GREEN=(50,225,50)
RED=(255,0,0)

# Themes (palette of colors)
THEMES = {
    "Classic": {
        "wall": (0, 0, 0),
        "path": (255, 255, 255),
        "player": (50, 50, 255),
        "exit": (255, 255, 120),
        "trail": (100, 149, 237),
        "hint": (255, 140, 0, 180),
        "background": (135, 206, 235),
        "info_bar": (40, 40, 40),
        "line": (200, 200, 200),
        "text": (255, 255, 255),
        "highlight": (255, 255, 120)
    },
    "Dark": {
        "wall": (20, 20, 20),
        "path": (30, 30, 30),
        "player": (0, 255, 255),
        "exit": (255, 100, 100),
        "trail": (0, 100, 255),
        "hint": (0, 255, 255, 180),
        "background": (10, 10, 10),
        "info_bar": (10, 10, 10),
        "line": (60, 60, 60),
        "text": (200, 200, 200),
        "highlight": (255, 100, 100)
    },
    "Forest": {
        "wall": (34, 50, 20),
        "path": (170, 220, 140),
        "player": (20, 100, 20),
        "exit": (255, 220, 145),
        "trail": (60, 100, 20),
        "hint": (0, 100, 0, 180),
        "background": (130, 170, 110),
        "info_bar": (20, 40, 10),
        "line": (100, 140, 60),
        "text": (220, 220, 180),
        "highlight": (255, 220, 145)
    },
    "Sunset": {
        "wall": (80, 30, 0),
        "path": (255, 190, 140),
        "player": (255, 50, 0),
        "exit": (255, 255, 120),
        "trail": (255, 120, 20),
        "hint": (255, 140, 0, 180),
        "background": (255, 150, 100),
        "info_bar": (100, 50, 10),
        "line": (200, 160, 120),
        "text": (255, 220, 180),
        "highlight": (255, 255, 120)
    }
}

# Default key bindings
DEFAULT_KEYS = {
    "UP": [pygame.K_w, pygame.K_UP],
    "DOWN": [pygame.K_s, pygame.K_DOWN],
    "LEFT": [pygame.K_a, pygame.K_LEFT],
    "RIGHT": [pygame.K_d, pygame.K_RIGHT],
    "HINT": [pygame.K_h],
    "PAUSE": [pygame.K_p],
    "RESTART": [pygame.K_r],
    "NEWMAZE": [pygame.K_n],
    "MENU": [pygame.K_m],
    "QUIT": [pygame.K_ESCAPE],
    "TOGGLE_HINT": [pygame.K_t],
    "SAVE": [pygame.K_F5],
    "LOAD": [pygame.K_F9],
}

# Globals for maze
maze = []
MAZE_WIDTH = DEFAULT_MAZE_SIZE
MAZE_HEIGHT = DEFAULT_MAZE_SIZE
CELL_SIZE = MAZE_PIXEL_SIZE // MAZE_WIDTH

# Game State variables
player_pos = None
exit_pos = None
trail = []
win = False
steps = 0
start_time = 0
hint_path = None
hint_start_time = None
HINT_DURATION = 4000  # ms
show_hint_path = True
paused = False
pause_menu_index = 0

# Current selections and states
current_theme_name = "Classic"
current_theme = THEMES[current_theme_name]
difficulty_sizes = [(15, 15), (21, 21), (31, 31)]
current_size_index = 1  # Default medium size
current_maze_backup = None
current_maze_player_pos = None
current_maze_exit_pos = None

# Zoom & Pan Variables
zoom_level = 1.0
min_zoom = 0.5
max_zoom = 3.0
pan_offset_x = 0
pan_offset_y = 0
dragging = False
drag_start = (0, 0)
pan_start = (0, 0)

# Fonts
font = pygame.font.SysFont(None, 28)
font_large = pygame.font.SysFont(None, 44)
font_menu = pygame.font.SysFont(None, 50, bold=True)

def save_game():
    global maze, player_pos, exit_pos, trail, steps, start_time
    try:
        save_data = {
            "maze": maze,
            "maze_width": MAZE_WIDTH,
            "maze_height": MAZE_HEIGHT,
            "player_pos": player_pos,
            "exit_pos": exit_pos,
            "trail": trail,
            "steps": steps,
            "elapsed_time": pygame.time.get_ticks() - start_time,
            "theme": current_theme_name,
            "show_hint_path": show_hint_path,
            "zoom_level": zoom_level,
            "pan_offset_x": pan_offset_x,
            "pan_offset_y": pan_offset_y
        }
        with open(SAVE_FILE, "w") as f:
            json.dump(save_data, f)
        return True
    except Exception as e:
        print("Save failed:", e)
        return False

def load_game():
    global maze, MAZE_WIDTH, MAZE_HEIGHT, player_pos, exit_pos, trail, steps, start_time
    global current_theme_name, current_theme
    global show_hint_path, zoom_level, pan_offset_x, pan_offset_y
    try:
        with open(SAVE_FILE, "r") as f:
            save_data = json.load(f)
        maze = save_data["maze"]
        MAZE_WIDTH = save_data["maze_width"]
        MAZE_HEIGHT = save_data["maze_height"]
        player_pos = save_data["player_pos"]
        exit_pos = save_data["exit_pos"]
        trail = save_data["trail"]
        steps = save_data["steps"]
        start_time = pygame.time.get_ticks() - save_data.get("elapsed_time", 0)
        current_theme_name = save_data.get("theme", "Classic")
        current_theme = THEMES.get(current_theme_name, THEMES["Classic"])
        show_hint_path = save_data.get("show_hint_path", True)
        zoom_level = save_data.get("zoom_level", 1.0)
        pan_offset_x = save_data.get("pan_offset_x", 0)
        pan_offset_y = save_data.get("pan_offset_y", 0)
        compute_cell_size()
        return True
    except Exception as e:
        print("Load failed:", e)
        return False

def save_leaderboard(time_sec, steps_):
    leaderboard = []
    try:
        if os.path.exists(LEADERBOARD_FILE):
            with open(LEADERBOARD_FILE, "r") as f:
                leaderboard = json.load(f)
    except:
        pass
    leaderboard.append({"time": time_sec, "steps": steps_})
    leaderboard.sort(key=lambda x: x["time"])
    leaderboard = leaderboard[:10]
    try:
        with open(LEADERBOARD_FILE, "w") as f:
            json.dump(leaderboard, f)
    except Exception as e:
        print("Leaderboard save failed:", e)

def load_leaderboard():
    try:
        if os.path.exists(LEADERBOARD_FILE):
            with open(LEADERBOARD_FILE, "r") as f:
                return json.load(f)
    except:
        pass
    return []

def save_key_bindings(bindings):
    try:
        with open(KEY_BINDINGS_FILE, "w") as f:
            json.dump(bindings, f)
    except Exception as e:
        print("Failed to save key bindings:", e)

def load_key_bindings():
    try:
        if os.path.exists(KEY_BINDINGS_FILE):
            with open(KEY_BINDINGS_FILE, "r") as f:
                return json.load(f)
    except:
        pass
    return DEFAULT_KEYS.copy()

key_bindings = load_key_bindings()

def compute_cell_size():
    global CELL_SIZE
    CELL_SIZE = max(5, MAZE_PIXEL_SIZE // MAZE_WIDTH)

def maze_generate_data(width, height):
    maze_data = [[1 for _ in range(width)] for _ in range(height)]
    stack = []
    cx = random.randrange(1, width, 2)
    cy = random.randrange(1, height, 2)
    maze_data[cy][cx] = 0
    stack.append((cx, cy))

    while stack:
        cx, cy = stack[-1]
        neighbors = []
        for dx, dy in [(0,1),(0,-1),(1,0),(-1,0)]:
            nx, ny = cx + dx*2, cy + dy*2
            if 0 < nx < width-1 and 0 < ny < height-1:
                if maze_data[ny][nx] == 1:
                    neighbors.append((nx, ny))
        if neighbors:
            nx, ny = random.choice(neighbors)
            wall_x, wall_y = cx + (nx - cx)//2, cy + (ny - cy)//2
            maze_data[wall_y][wall_x] = 0
            maze_data[ny][nx] = 0
            stack.append((nx, ny))
        else:
            stack.pop()
    return maze_data

def maze_generator_visual(offset_x, offset_y):
    global maze
    maze = [[1 for _ in range(MAZE_WIDTH)] for _ in range(MAZE_HEIGHT)]
    stack = []

    cx = random.randrange(1, MAZE_WIDTH, 2)
    cy = random.randrange(1, MAZE_HEIGHT, 2)
    maze[cy][cx] = 0
    stack.append((cx, cy))

    while stack:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            elif event.type == pygame.MOUSEBUTTONDOWN:
                if event.button == 4:
                    zoom_in()
                elif event.button == 5:
                    zoom_out()

        screen.fill(current_theme["background"])

        draw_maze(None, offset_x, offset_y)
        cur_cell = stack[-1]
        rect = pygame.Rect(offset_x + cur_cell[0]*CELL_SIZE*zoom_level,
                           offset_y + cur_cell[1]*CELL_SIZE*zoom_level,
                           CELL_SIZE*zoom_level, CELL_SIZE*zoom_level)
        pygame.draw.rect(screen, current_theme["highlight"], rect)

        pygame.display.flip()
        clock.tick(60)

        cx, cy = stack[-1]

        neighbors = []
        for dx, dy in [(0,1),(0,-1),(1,0),(-1,0)]:
            nx, ny = cx + dx*2, cy + dy*2
            if 0 < nx < MAZE_WIDTH-1 and 0 < ny < MAZE_HEIGHT-1:
                if maze[ny][nx] == 1:
                    neighbors.append((nx, ny))

        if neighbors:
            nx, ny = random.choice(neighbors)
            wall_x, wall_y = cx + (nx - cx)//2, cy + (ny - cy)//2
            maze[wall_y][wall_x] = 0
            maze[ny][nx] = 0
            stack.append((nx, ny))
        else:
            stack.pop()

def draw_maze(hint_path=None, offset_x=0, offset_y=0):
    for y in range(MAZE_HEIGHT):
        for x in range(MAZE_WIDTH):
            rect = pygame.Rect(offset_x + x*CELL_SIZE*zoom_level,
                               offset_y + y*CELL_SIZE*zoom_level,
                               CELL_SIZE*zoom_level, CELL_SIZE*zoom_level)
            if maze[y][x] == 1:
                pygame.draw.rect(screen, current_theme["wall"], rect)
            else:
                pygame.draw.rect(screen, current_theme["path"], rect)

    if hint_path and show_hint_path:
        for cx, cy in hint_path:
            hint_rect = pygame.Rect(offset_x + cx*CELL_SIZE*zoom_level + CELL_SIZE*zoom_level/4,
                                    offset_y + cy*CELL_SIZE*zoom_level + CELL_SIZE*zoom_level/4,
                                    CELL_SIZE*zoom_level/2, CELL_SIZE*zoom_level/2)
            s = pygame.Surface((hint_rect.width, hint_rect.height), pygame.SRCALPHA)
            s.fill(current_theme["hint"])
            screen.blit(s, (hint_rect.x, hint_rect.y))

    for y in range(MAZE_HEIGHT + 1):
        pygame.draw.line(screen, current_theme["line"], (offset_x, offset_y + y*CELL_SIZE*zoom_level),
                         (offset_x + CELL_SIZE*MAZE_WIDTH*zoom_level, offset_y + y*CELL_SIZE*zoom_level))
    for x in range(MAZE_WIDTH + 1):
        pygame.draw.line(screen, current_theme["line"], (offset_x + x*CELL_SIZE*zoom_level, offset_y),
                         (offset_x + x*CELL_SIZE*zoom_level, offset_y + CELL_SIZE*MAZE_HEIGHT*zoom_level))

def draw_player(pos, trail, offset_x=0, offset_y=0):
    for tpos in trail:
        rect = pygame.Rect(offset_x + tpos[0]*CELL_SIZE*zoom_level + CELL_SIZE*zoom_level/4,
                           offset_y + tpos[1]*CELL_SIZE*zoom_level + CELL_SIZE*zoom_level/4,
                           CELL_SIZE*zoom_level/2, CELL_SIZE*zoom_level/2)
        pygame.draw.rect(screen, current_theme["trail"], rect)
    rect = pygame.Rect(offset_x + pos[0]*CELL_SIZE*zoom_level + CELL_SIZE*zoom_level/6,
                       offset_y + pos[1]*CELL_SIZE*zoom_level + CELL_SIZE*zoom_level/6,
                       CELL_SIZE*zoom_level*2/3, CELL_SIZE*zoom_level*2/3)
    pygame.draw.rect(screen, current_theme["player"], rect)

def draw_exit(pos, highlight=False, offset_x=0, offset_y=0):
    rect = pygame.Rect(offset_x + pos[0]*CELL_SIZE*zoom_level + CELL_SIZE*zoom_level/6,
                       offset_y + pos[1]*CELL_SIZE*zoom_level + CELL_SIZE*zoom_level/6,
                       CELL_SIZE*zoom_level*2/3, CELL_SIZE*zoom_level*2/3)
    color = current_theme["highlight"] if highlight else current_theme["exit"]
    pygame.draw.rect(screen, color, rect)

def draw_info_bar(messages, color=None):
    bar_rect = pygame.Rect(0, SCREEN_HEIGHT - INFO_BAR_HEIGHT, SCREEN_WIDTH, INFO_BAR_HEIGHT)
    pygame.draw.rect(screen, current_theme["info_bar"], bar_rect)
    padding_top = 15
    line_height = 24
    col = color if color else current_theme["text"]
    for i, message in enumerate(messages):
        text = font.render(message, True, col)
        text_rect = text.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT - INFO_BAR_HEIGHT + padding_top + i*line_height))
        screen.blit(text, text_rect)

def find_start_exit():
    start, exit = None, None
    for y in range(MAZE_HEIGHT):
        for x in range(MAZE_WIDTH):
            if maze[y][x] == 0:
                start = [x, y]
                break
        if start: break
    for y in range(MAZE_HEIGHT-1, -1, -1):
        for x in range(MAZE_WIDTH-1, -1, -1):
            if maze[y][x] == 0:
                exit = [x, y]
                break
        if exit: break
    return start, exit

def can_move(pos, direction):
    x, y = pos
    dx, dy = direction
    nx, ny = x + dx, y + dy
    if 0 <= nx < MAZE_WIDTH and 0 <= ny < MAZE_HEIGHT and maze[ny][nx] == 0:
        return True
    return False

def bfs_shortest_path(start, goal):
    queue = deque([start])
    visited = {tuple(start): None}
    while queue:
        current = queue.popleft()
        if current == goal:
            path = []
            while current != start:
                path.append(current)
                current = visited[current]
            path.reverse()
            return path
        for dx, dy in [(0,1),(0,-1),(1,0),(-1,0)]:
            neighbor = (current[0]+dx, current[1]+dy)
            if (0 <= neighbor[0] < MAZE_WIDTH and 0 <= neighbor[1] < MAZE_HEIGHT
                and maze[neighbor[1]][neighbor[0]] == 0 and neighbor not in visited):
                visited[neighbor] = current
                queue.append(neighbor)
    return None

# Power-ups
power_ups = []

class PowerUp:
    def __init__(self, x, y, type_):
        self.x = x
        self.y = y
        self.type = type_
        self.collected = False

def place_power_ups(count=5):
    global power_ups
    power_ups = []
    empty_cells = [(x, y) for y in range(MAZE_HEIGHT) for x in range(MAZE_WIDTH) if maze[y][x] == 0]
    random.shuffle(empty_cells)
    for _ in range(count):
        if empty_cells:
            x,y = empty_cells.pop()
            power_ups.append(PowerUp(x, y, "hint"))

def draw_power_ups(offset_x=0, offset_y=0):
    hint_color = (255, 200, 0)
    for pu in power_ups:
        if not pu.collected:
            rect = pygame.Rect(offset_x + pu.x*CELL_SIZE*zoom_level + CELL_SIZE*zoom_level/3,
                               offset_y + pu.y*CELL_SIZE*zoom_level + CELL_SIZE*zoom_level/3,
                               CELL_SIZE*zoom_level/3, CELL_SIZE*zoom_level/3)
            color = hint_color if pu.type == "hint" else hint_color
            pygame.draw.ellipse(screen, color, rect)

def collect_power_up():
    global power_ups, hint_path, hint_start_time
    for pu in power_ups:
        if not pu.collected and pu.x == player_pos[0] and pu.y == player_pos[1]:
            pu.collected = True
            if pu.type == "hint":
                path = bfs_shortest_path(tuple(player_pos), tuple(exit_pos))
                if path:
                    hint_path = path
                    hint_start_time = pygame.time.get_ticks()

def zoom_in():
    global zoom_level
    zoom_level = min(max_zoom, zoom_level * 1.1)

def zoom_out():
    global zoom_level
    zoom_level = max(min_zoom, zoom_level / 1.1)

def handle_pan_event(event):
    global dragging, drag_start, pan_start, pan_offset_x, pan_offset_y
    if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
        dragging = True
        drag_start = event.pos
        pan_start = (pan_offset_x, pan_offset_y)
    elif event.type == pygame.MOUSEBUTTONUP and event.button == 1:
        dragging = False
    elif event.type == pygame.MOUSEMOTION:
        if dragging:
            dx = event.pos[0] - drag_start[0]
            dy = event.pos[1] - drag_start[1]
            pan_offset_x = pan_start[0] + dx
            pan_offset_y = pan_start[1] + dy

def draw_menu_selected(selected_idx, options, title="Menu", subtitle=None):
    screen.fill(current_theme["background"])
    title_text = font_menu.render(title, True, current_theme["text"])
    title_rect = title_text.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT//6))
    screen.blit(title_text, title_rect)

    for i, option in enumerate(options):
        color = current_theme["highlight"] if i == selected_idx else current_theme["text"]
        option_text = font_large.render(option, True, color)
        option_rect = option_text.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT//3 + i*60))
        screen.blit(option_text, option_rect)

    if subtitle:
        subtitle_text = font.render(subtitle, True, current_theme["text"])
        subtitle_rect = subtitle_text.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT - 50))
        screen.blit(subtitle_text, subtitle_rect)

    pygame.display.flip()

def main_menu():
    options = ["Start Game", "Leaderboard", "Settings", "Exit"]
    selected = 0
    while True:
        draw_menu_selected(selected, options, title="Maze Explorer 2D")
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_UP:
                    selected = (selected - 1) % len(options)
                elif event.key == pygame.K_DOWN:
                    selected = (selected + 1) % len(options)
                elif event.key == pygame.K_RETURN:
                    return options[selected]
                elif event.key == pygame.K_ESCAPE:
                    pygame.quit()
                    sys.exit()
        clock.tick(30)

def choose_maze_size_menu():
    options = ["Small (15x15)", "Medium (21x21)", "Large (31x31)"]
    selected = current_size_index
    while True:
        draw_menu_selected(selected, options, title="Choose Difficulty")
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_UP:
                    selected = (selected - 1) % len(options)
                elif event.key == pygame.K_DOWN:
                    selected = (selected + 1) % len(options)
                elif event.key == pygame.K_RETURN:
                    return difficulty_sizes[selected], selected
                elif event.key == pygame.K_ESCAPE:
                    return None, None
        clock.tick(30)

def theme_select_menu():
    options = list(THEMES.keys())
    selected = options.index(current_theme_name)
    while True:
        draw_menu_selected(selected, options, title="Select Theme")
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_UP:
                    selected = (selected - 1) % len(options)
                elif event.key == pygame.K_DOWN:
                    selected = (selected + 1) % len(options)
                elif event.key == pygame.K_RETURN:
                    return options[selected]
                elif event.key == pygame.K_ESCAPE:
                    return None
        clock.tick(30)

def settings_menu():
    global current_theme_name, current_theme, show_hint_path
    options = ["Select Theme", "Toggle Hint Path Visibility", "Back"]
    selected = 0
    while True:
        display_values = ["On" if show_hint_path else "Off"]
        option_display = [
            f"{options[0]}: {current_theme_name}",
            f"{options[1]}: {display_values[0]}",
            options[2]
        ]
        draw_menu_selected(selected, option_display, title="Settings")
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_UP:
                    selected = (selected - 1) % len(options)
                elif event.key == pygame.K_DOWN:
                    selected = (selected + 1) % len(options)
                elif event.key == pygame.K_RETURN:
                    if selected == 0:
                        chosen = theme_select_menu()
                        if chosen:
                            current_theme_name = chosen
                            current_theme = THEMES[chosen]
                    elif selected == 1:
                        show_hint_path = not show_hint_path
                    elif selected == 2:
                        return
                elif event.key == pygame.K_ESCAPE:
                    return
        clock.tick(30)

def draw_leaderboard_menu():
    leaderboard = load_leaderboard()
    selected = 0
    while True:
        screen.fill(current_theme["background"])
        title_text = font_menu.render("Leaderboard - Top Times", True, current_theme["text"])
        title_rect = title_text.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT//8))
        screen.blit(title_text, title_rect)

        for i, entry in enumerate(leaderboard):
            text = f"{i+1}. Time: {entry['time']}s, Steps: {entry['steps']}"
            color = current_theme["highlight"] if i == selected else current_theme["text"]
            entry_text = font_large.render(text, True, color)
            entry_rect = entry_text.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT//4 + i*40))
            screen.blit(entry_text, entry_rect)

        instructions = font.render("Press ESC to return", True, current_theme["text"])
        instr_rect = instructions.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT - 40))
        screen.blit(instructions, instr_rect)

        pygame.display.flip()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    return
        clock.tick(30)

def draw_pause_menu():
    global paused, pause_menu_index
    options = ["Resume", "Restart", "New Maze", "Save Game", "Load Game", "Settings", "Main Menu", "Quit"]
    while paused:
        draw_menu_selected(pause_menu_index, options, title="Paused")
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_UP:
                    pause_menu_index = (pause_menu_index - 1) % len(options)
                elif event.key == pygame.K_DOWN:
                    pause_menu_index = (pause_menu_index + 1) % len(options)
                elif event.key == pygame.K_RETURN:
                    choice = options[pause_menu_index]
                    if choice == "Resume":
                        return "resume"
                    elif choice == "Restart":
                        return "restart"
                    elif choice == "New Maze":
                        return "new_maze"
                    elif choice == "Save Game":
                        saved = save_game()
                        if saved:
                            draw_info_bar(["Game saved successfully!"], GREEN)
                        else:
                            draw_info_bar(["Game save failed!"], RED)
                        pygame.display.flip()
                        pygame.time.delay(1500)
                    elif choice == "Load Game":
                        loaded = load_game()
                        if loaded:
                            draw_info_bar(["Game loaded!"], GREEN)
                        else:
                            draw_info_bar(["Load failed!"], RED)
                        pygame.display.flip()
                        pygame.time.delay(1500)
                    elif choice == "Settings":
                        settings_menu()
                    elif choice == "Main Menu":
                        return "main_menu"
                    elif choice == "Quit":
                        pygame.quit()
                        sys.exit()
                elif event.key == key_bindings["PAUSE"][0]:
                    return "resume"
        clock.tick(30)

def draw_win_message():
    overlay = pygame.Surface((SCREEN_WIDTH, SCREEN_HEIGHT - INFO_BAR_HEIGHT))
    overlay.set_alpha(180)
    overlay.fill((0, 0, 0))
    screen.blit(overlay, (0, 0))
    msg1 = "🎉 You found the exit! 🎉"
    msg2 = "Press N for New Maze, R to Restart, M for Menu, or ESC to Quit"
    text1 = font_large.render(msg1, True, (50, 255, 50))
    text2 = font.render(msg2, True, (50, 255, 50))
    rect1 = text1.get_rect(center=(SCREEN_WIDTH // 2, (SCREEN_HEIGHT - INFO_BAR_HEIGHT) // 2 - 20))
    rect2 = text2.get_rect(center=(SCREEN_WIDTH // 2, (SCREEN_HEIGHT - INFO_BAR_HEIGHT) // 2 + 30))
    screen.blit(text1, rect1)
    screen.blit(text2, rect2)

def game_loop(maze_width, maze_height):
    global MAZE_WIDTH, MAZE_HEIGHT, maze, SCREEN_WIDTH, SCREEN_HEIGHT, screen, CELL_SIZE
    global player_pos, exit_pos, trail, win, steps, start_time
    global hint_path, hint_start_time, show_hint_path
    global zoom_level, pan_offset_x, pan_offset_y
    MAZE_WIDTH, MAZE_HEIGHT = maze_width, maze_height

    compute_cell_size()

    maze_pixel_width = CELL_SIZE * MAZE_WIDTH * zoom_level
    maze_pixel_height = CELL_SIZE * MAZE_HEIGHT * zoom_level

    full_w, full_h = pygame.display.Info().current_w, pygame.display.Info().current_h

    SCREEN_WIDTH = full_w
    SCREEN_HEIGHT = full_h
    screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT), pygame.FULLSCREEN)
    pygame.display.set_caption("Maze Explorer 2D - Generation & Play")

    offset_x = (SCREEN_WIDTH - maze_pixel_width) // 2 + pan_offset_x
    offset_y = (SCREEN_HEIGHT - INFO_BAR_HEIGHT - maze_pixel_height) // 2 + pan_offset_y

    if zoom_level < min_zoom or zoom_level > max_zoom:
        zoom_level = 1.0

    trail = []
    win = False
    steps = 0
    start_time = pygame.time.get_ticks()
    hint_path = None
    hint_start_time = None

    keys_pressed = set()
    MOVE_DELAY = 150
    last_move_time = 0

    place_power_ups()

    running = True
    while running:
        clock.tick(60)
        current_time = pygame.time.get_ticks()

        for event in pygame.event.get():
            if event.type in (pygame.MOUSEBUTTONDOWN, pygame.MOUSEBUTTONUP, pygame.MOUSEMOTION):
                handle_pan_event(event)
                if event.type == pygame.MOUSEBUTTONDOWN:
                    if event.button == 4:
                        zoom_in()
                    elif event.button == 5:
                        zoom_out()

            if event.type == pygame.QUIT:
                running = False
                break
            if event.type == pygame.KEYDOWN:
                keys_pressed.add(event.key)
                if event.key in key_bindings["QUIT"]:
                    running = False
                    break
                elif event.key in key_bindings["PAUSE"]:
                    global paused
                    paused = not paused
                    if paused:
                        result = draw_pause_menu()
                        paused = False
                        if result == "restart":
                            return "restart_same"
                        elif result == "new_maze":
                            return "new_maze"
                        elif result == "main_menu":
                            return "main_menu"
                        elif result == "resume":
                            pass
                elif event.key in key_bindings["RESTART"] and not paused:
                    return "restart_same"
                elif event.key in key_bindings["NEWMAZE"] and not paused:
                    return "new_maze"
                elif event.key in key_bindings["MENU"] and not paused:
                    return "main_menu"
                elif event.key in key_bindings["HINT"] and not paused:
                    path = bfs_shortest_path(tuple(player_pos), tuple(exit_pos))
                    if path:
                        hint_path = path
                        hint_start_time = current_time
                elif event.key in key_bindings["TOGGLE_HINT"]:
                    show_hint_path = not show_hint_path
                elif event.key in key_bindings["SAVE"]:
                    if save_game():
                        draw_info_bar(["Game saved successfully!"], (50, 255, 50))
                    else:
                        draw_info_bar(["Game save failed!"], (255, 0, 0))
                    pygame.display.flip()
                    pygame.time.delay(1000)
                elif event.key in key_bindings["LOAD"]:
                    if load_game():
                        draw_info_bar(["Game loaded!"], (50, 255, 50))
                    else:
                        draw_info_bar(["Load failed!"], (255, 0, 0))
                    pygame.display.flip()
                    pygame.time.delay(1000)

            if event.type == pygame.KEYUP:
                keys_pressed.discard(event.key)

        if hint_path and current_time - hint_start_time > HINT_DURATION:
            hint_path = None

        if not win and not paused and current_time - last_move_time > MOVE_DELAY:
            direction_map = {}
            for d in ["UP", "DOWN", "LEFT", "RIGHT"]:
                for k in key_bindings[d]:
                    direction_map[k] = {
                        "UP": (0, -1),
                        "DOWN": (0, 1),
                        "LEFT": (-1, 0),
                        "RIGHT": (1, 0)
                    }[d]

            moved = False
            for k in keys_pressed:
                if k in direction_map and can_move(player_pos, direction_map[k]):
                    dx, dy = direction_map[k]
                    trail.append(player_pos[:])
                    player_pos[0] += dx
                    player_pos[1] += dy
                    steps += 1
                    moved = True
                    collect_power_up()
                    break
            if moved:
                last_move_time = current_time

        win = (player_pos == exit_pos)

        screen.fill(current_theme["background"])

        top_offset_x = (SCREEN_WIDTH - CELL_SIZE * MAZE_WIDTH * zoom_level) // 2 + pan_offset_x
        top_offset_y = (SCREEN_HEIGHT - INFO_BAR_HEIGHT - CELL_SIZE * MAZE_HEIGHT * zoom_level) // 2 + pan_offset_y

        draw_maze(hint_path, top_offset_x, top_offset_y)
        draw_power_ups(top_offset_x, top_offset_y)
        draw_exit(exit_pos, highlight=True, offset_x=top_offset_x, offset_y=top_offset_y)
        draw_player(player_pos, trail, offset_x=top_offset_x, offset_y=top_offset_y)

        elapsed_sec = (current_time - start_time) // 1000

        if win:
            draw_win_message()
            save_leaderboard(elapsed_sec, steps)
            draw_info_bar([
                f"Time: {elapsed_sec}s | Steps: {steps}",
                f"N: New Maze | R: Restart | M: Menu | ESC: Quit"
            ], (50, 255, 50))
        else:
            draw_info_bar([
                "Use WASD/Arrow keys to move. P: Pause",
                f"Time: {elapsed_sec}s | Steps: {steps}",
                "H: Hint path | T: Toggle hint path",
                "Save(F5) Load(F9) | Mouse wheel to zoom | Drag to pan"
            ], current_theme["text"])

        pygame.display.flip()

    return "exit"

def run():
    global maze, MAZE_WIDTH, MAZE_HEIGHT, player_pos, exit_pos, CELL_SIZE
    global current_size_index, current_theme_name, current_theme
    global show_hint_path, zoom_level, pan_offset_x, pan_offset_y
    global trail, steps, start_time, paused

    info = pygame.display.Info()
    global SCREEN_WIDTH, SCREEN_HEIGHT, screen
    SCREEN_WIDTH, SCREEN_HEIGHT = info.current_w, info.current_h
    screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT), pygame.FULLSCREEN)

    running = True
    while running:
        choice = main_menu()
        if choice == "Exit":
            pygame.quit()
            sys.exit()
        elif choice == "Leaderboard":
            draw_leaderboard_menu()
        elif choice == "Settings":
            settings_menu()
        elif choice == "Start Game":
            res = choose_maze_size_menu()
            if res is None:
                continue
            size, idx = res
            if size is None:
                continue
            current_size_index = idx
            MAZE_WIDTH, MAZE_HEIGHT = size
            current_theme_name = current_theme_name or "Classic"
            current_theme = THEMES.get(current_theme_name, THEMES["Classic"])
            CELL_SIZE = MAZE_PIXEL_SIZE // MAZE_WIDTH
            zoom_level = 1.0
            pan_offset_x = 0
            pan_offset_y = 0
            show_hint_path = True
            maze = maze_generate_data(MAZE_WIDTH, MAZE_HEIGHT)
            player_pos, exit_pos = find_start_exit()
            trail = []
            steps = 0
            start_time = pygame.time.get_ticks()
            paused = False
            while True:
                result = game_loop(MAZE_WIDTH, MAZE_HEIGHT)
                if result == "exit":
                    pygame.quit()
                    sys.exit()
                elif result == "main_menu":
                    break
                elif result == "new_maze":
                    maze = maze_generate_data(MAZE_WIDTH, MAZE_HEIGHT)
                    player_pos, exit_pos = find_start_exit()
                    trail = []
                    steps = 0
                    start_time = pygame.time.get_ticks()
                    zoom_level = 1.0
                    pan_offset_x = 0
                    pan_offset_y = 0
                elif result == "restart_same":
                    trail = []
                    steps = 0
                    start_time = pygame.time.get_ticks()
                    player_pos, exit_pos = find_start_exit()
                    zoom_level = 1.0
                    pan_offset_x = 0
                    pan_offset_y = 0

if __name__ == "__main__":
    run()


