print("EchoMaze is starting!")

import pygame

# Start Pygame
pygame.init()

# Game settings
TILE_SIZE = 50

LEVEL = [
    "############",
    "#P.........#",
    "#.###......#",
    "#...#......#",
    "#...#..##..#",
    "#..........#",
    "#.........G#",
    "############"
]

ROWS = len(LEVEL)
COLS = len(LEVEL[0])

WIDTH = COLS * TILE_SIZE
HEIGHT = ROWS * TILE_SIZE + 70

# Colors
BACKGROUND = (25, 30, 50)
FLOOR_COLOR = (52, 65, 85)
WALL_COLOR = (115, 130, 160)
PLAYER_COLOR = (100, 210, 255)
GOAL_COLOR = (100, 230, 150)
WHITE = (255, 255, 255)

# Create game window
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("EchoMaze")

clock = pygame.time.Clock()
font = pygame.font.SysFont(None, 28)

# Find walls, player and exit
walls = set()
player_x = 1
player_y = 1
goal_x = 10
goal_y = 6


# Time-loop variables
start_x = 1
start_y = 1

recorded_moves = []
ghosts = []
turn_count = 0

GHOST_COLOR = (180, 130, 255)


for row in range(ROWS):
    for col in range(COLS):
        tile = LEVEL[row][col]

        if tile == "#":
            walls.add((col, row))

        elif tile == "P":
            player_x = col
            player_y = row
            start_x = col
            start_y = row

        elif tile == "G":
            goal_x = col
            goal_y = row


# Move the player

def move_player(dx, dy):
    global player_x, player_y, turn_count

    new_x = player_x + dx
    new_y = player_y + dy

    # Check whether the destination is valid.
    if (
        0 <= new_x < COLS
        and 0 <= new_y < ROWS
        and (new_x, new_y) not in walls
    ):
        player_x = new_x
        player_y = new_y

    # Record the attempted action.
    # Even hitting a wall uses one turn.
    recorded_moves.append((dx, dy))

    turn_count += 1

    # Move each ghost by one recorded action.
    for ghost in ghosts:
        move_index = turn_count - 1

        if move_index < len(ghost["moves"]):
            ghost_dx, ghost_dy = ghost["moves"][move_index]

            ghost_new_x = ghost["x"] + ghost_dx
            ghost_new_y = ghost["y"] + ghost_dy

            if (
                0 <= ghost_new_x < COLS
                and 0 <= ghost_new_y < ROWS
                and (ghost_new_x, ghost_new_y) not in walls
            ):
                ghost["x"] = ghost_new_x
                ghost["y"] = ghost_new_y


def restart_loop():
    global player_x, player_y
    global recorded_moves, turn_count

    # Save the current loop as a new ghost.
    if len(recorded_moves) > 0:
        new_ghost = {
            "x": start_x,
            "y": start_y,
            "moves": recorded_moves.copy()
        }

        ghosts.append(new_ghost)

    # Reset all ghosts to their starting positions.
    for ghost in ghosts:
        ghost["x"] = start_x
        ghost["y"] = start_y

    # Reset the player.
    player_x = start_x
    player_y = start_y

    # Start a new recording.
    recorded_moves = []
    turn_count = 0

    print("New time loop! Ghosts:", len(ghosts))


# Draw the maze
def draw_maze():
    for row in range(ROWS):
        for col in range(COLS):
            x = col * TILE_SIZE
            y = row * TILE_SIZE

            rect = pygame.Rect(
                x, y, TILE_SIZE, TILE_SIZE
            )

            if (col, row) in walls:
                color = WALL_COLOR
            else:
                color = FLOOR_COLOR

            pygame.draw.rect(screen, color, rect)
            pygame.draw.rect(
                screen, BACKGROUND, rect, 1
            )


# Draw the player and exit
def draw_objects():
    # Exit
    goal_rect = pygame.Rect(
        goal_x * TILE_SIZE + 10,
        goal_y * TILE_SIZE + 10,
        30, 30
    )
    pygame.draw.rect(
        screen, GOAL_COLOR, goal_rect
    )

    # Draw ghost characters
    for ghost in ghosts:
        ghost_center_x = ghost["x"] * TILE_SIZE + TILE_SIZE // 2
        ghost_center_y = ghost["y"] * TILE_SIZE + TILE_SIZE // 2

        pygame.draw.circle(
            screen,
            GHOST_COLOR,
            (ghost_center_x, ghost_center_y),
            14,
            3
        )

    # Player
    center_x = player_x * TILE_SIZE + 25
    center_y = player_y * TILE_SIZE + 25

    pygame.draw.circle(
        screen,
        PLAYER_COLOR,
        (center_x, center_y),
        17
    )


# Main game loop
running = True

while running:

    for event in pygame.event.get():

        if event.type == pygame.QUIT:
            running = False

        
        if event.type == pygame.KEYDOWN:

            if event.key == pygame.K_ESCAPE:
                running = False

            elif event.key == pygame.K_r:
                restart_loop()

            elif event.key in (pygame.K_UP, pygame.K_w):
                move_player(0, -1)

            elif event.key in (pygame.K_DOWN, pygame.K_s):
                move_player(0, 1)

            elif event.key in (pygame.K_LEFT, pygame.K_a):
                move_player(-1, 0)

            elif event.key in (pygame.K_RIGHT, pygame.K_d):
                move_player(1, 0)


    # Draw everything
    screen.fill(BACKGROUND)

    draw_maze()
    draw_objects()

    # Check if the player reached the exit
    
    if player_x == goal_x and player_y == goal_y:
        message = "LEVEL COMPLETE!"
    else:
        message = (
            f"Ghosts: {len(ghosts)} | "
            f"Turn: {turn_count} | "
            "R: New Loop | ESC: Quit"
        )


    text = font.render(
        message, True, WHITE
    )

    screen.blit(
        text, (20, ROWS * TILE_SIZE + 20)
    )

    pygame.display.flip()
    clock.tick(60)

pygame.quit()
