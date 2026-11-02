import pygame
import time
import random
import heapq

pygame.init()


white  = (255, 255, 255)
yellow = (255, 255, 102)
black  = (0, 0, 0)
red    = (213, 50, 80)
green  = (0, 255, 0)
blue   = (50, 153, 213)
gray   = (120, 120, 120)


dis_width  = 800
dis_height = 600

dis = pygame.display.set_mode((dis_width, dis_height))
pygame.display.set_caption('🐍 Snake - Dijkstra AI by saksham jaryal')

clock = pygame.time.Clock()

snake_block = 20
snake_speed = 20

font_style = pygame.font.SysFont("bahnschrift", 25)
score_font = pygame.font.SysFont("comicsansms", 30)

def your_score(score):
    value = score_font.render("Score: " + str(score), True, yellow)
    dis.blit(value, [10, 10])

def draw_cell(grid_x, grid_y, color):
    pygame.draw.rect(dis, color, [grid_x * snake_block, grid_y * snake_block, snake_block, snake_block])

def our_snake(snake_list):
    for x, y in snake_list:
     draw_cell(x, y, blue)

def message(msg, color):
    mesg = font_style.render(msg, True, color)
    dis.blit(mesg, [dis_width / 6, dis_height / 3])


GRID_W = dis_width // snake_block
GRID_H = dis_height // snake_block

def to_grid(pos):
    x, y = pos
    return int(x // snake_block), int(y // snake_block)

def to_pixel(cell):
    gx, gy = cell
    return gx * snake_block, gy * snake_block

def neighbors(cell):
    x, y = cell
    for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
        nx, ny = x + dx, y + dy
        if 0 <= nx < GRID_W and 0 <= ny < GRID_H:
            yield (nx, ny)

def dijkstra(start, goal, blocked):
    if start == goal:
        return [start]

    dist = {start: 0}
    prev = {}
    pq = [(0, start)]
    visited = set()

    while pq:
        d, node = heapq.heappop(pq)
        if node in visited:
            continue
        visited.add(node)

        if node == goal:
            path = []
            cur = goal
            while cur != start:
                path.append(cur)
                cur = prev[cur]
            path.append(start)
            path.reverse()
            return path

        for nbr in neighbors(node):
            if nbr in blocked:
                continue
            nd = d + 1
            if nd < dist.get(nbr, 1_000_000):
                dist[nbr] = nd
                prev[nbr] = node
                heapq.heappush(pq, (nd, nbr))

    return []

# ✅ Missing function added here
def place_food(blocked):
    """Randomly place food avoiding the snake’s body."""
    free_cells = [(x, y) for x in range(GRID_W) for y in range(GRID_H) if (x, y) not in blocked]
    if not free_cells:
        return None
    return random.choice(free_cells)

def gameLoop():
    game_over = False
    game_close = False

    head_gx = GRID_W // 2
    head_gy = GRID_H // 2

    x1 = head_gx * snake_block
    y1 = head_gy * snake_block

    x1_change = 0
    y1_change = 0

    snake_List = [(head_gx, head_gy)]
    Length_of_snake = 1
    snake_set = set(snake_List)

    food_cell = place_food(snake_set)
    if food_cell is None:
        message("You Win! No space for food.", black)
        pygame.display.update()
        time.sleep(2)
        return

    ai_mode = True  # AI mode enabled by default

    while not game_over:
        while game_close:
            dis.fill(blue)
            message("You Lost! Press C-Play Again or Q-Quit", red)
            your_score(Length_of_snake - 1)
            pygame.display.update()

            for event in pygame.event.get():
                if event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_q:
                        game_over = True
                        game_close = False
                    if event.key == pygame.K_c:
                        gameLoop()
                if event.type == pygame.QUIT:
                    game_over = True
                    game_close = False

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                game_over = True
 
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_a:
                    ai_mode = not ai_mode
                if not ai_mode:
                    if event.key == pygame.K_LEFT:
                        x1_change = -snake_block
                        y1_change = 0
                    elif event.key == pygame.K_RIGHT:
                        x1_change = snake_block
                        y1_change = 0
                    elif event.key == pygame.K_UP:
                        y1_change = -snake_block
                        x1_change = 0
                    elif event.key == pygame.K_DOWN:
                        y1_change = snake_block
                        x1_change = 0

        head_cell = to_grid((x1, y1))

        # ✅ AI-controlled movement using Dijkstra
        if ai_mode:
            blocked = set(snake_List[:-1])
            path = dijkstra(head_cell, food_cell, blocked)
            if path and len(path) > 1:
                dx_px = (path[1][0] - path[0][0]) * snake_block
                dy_px = (path[1][1] - path[0][1]) * snake_block
                x1_change, y1_change = dx_px, dy_px
            else:
                safe_nbrs = [nbr for nbr in neighbors(head_cell) if nbr not in blocked]
                if safe_nbrs:
                    next_step = safe_nbrs[0]
                    x1_change = (next_step[0] - head_cell[0]) * snake_block
                    y1_change = (next_step[1] - head_cell[1]) * snake_block

        x1 += x1_change
        y1 += y1_change
        new_head = to_grid((x1, y1))

        if x1 < 0 or x1 >= dis_width or y1 < 0 or y1 >= dis_height:
            game_close = True

        snake_List.append(new_head)
        snake_set.add(new_head)
        if len(snake_List) > Length_of_snake:
            tail = snake_List.pop(0)
            snake_set.remove(tail)

        if new_head in snake_List[:-1]:
            game_close = True

        if new_head == food_cell:
            Length_of_snake += 1
            food_cell = place_food(snake_set)

        dis.fill(black)
        draw_cell(food_cell[0], food_cell[1], red)
        our_snake(snake_List)
        your_score(Length_of_snake - 1)
        mode_text = "AI" if ai_mode else "Manual"
        dis.blit(font_style.render(f"Mode: {mode_text} (press 'A' to toggle)", True, white), [10, 40])
        pygame.display.update()

        clock.tick(snake_speed)

    pygame.quit()
    quit()

# Run the game
gameLoop()
