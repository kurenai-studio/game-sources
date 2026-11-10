# --------------------------------------
# Importaciones
# --------------------------------------
import pygame
import random
import os

# --------------------------------------
# Inicializaciones
# --------------------------------------
pygame.init()
screen = pygame.display.set_mode((800, 600))
pygame.display.set_caption("Juego de la serpiente")
clock = pygame.time.Clock()

# --------------------------------------
# Variables y configuraciones
# --------------------------------------
WIDTH, HEIGHT = 800, 600
GRID_SIZE = 20
GRID_WIDTH = WIDTH // GRID_SIZE 
GRID_HEIGHT = HEIGHT // GRID_SIZE
FPS = 10
FOOD_COLOR = (255, 0, 0)
SNAKE_COLOR = (0, 255, 0)
BG_COLOR = (0, 0, 0)
FONT_COLOR = (255, 255, 255)

# --------------------------------------
# Funciones
# --------------------------------------

def draw_text(text, size, color, x, y):
    font = pygame.font.SysFont(None, size)
    text_surface = font.render(text, True, color)
    text_rect = text_surface.get_rect(center=(x, y))
    screen.blit(text_surface, text_rect)

def read_record():
    if os.path.exists('record.txt'):
        with open('record.txt', 'r') as file:
            return int(file.read())
    else:
        return 0

def save_record(record, score):
    if score > record:
        with open('record.txt', 'w') as file:
            file.write(str(score))

def get_direction_to_food(snake_head, food_position):
    x, y = snake_head
    food_x, food_y = food_position
    if food_x > x:
        return (1, 0)
    elif food_x < x:
        return (-1, 0)
    elif food_y > y:
        return (0, 1)
    else:
        return (0, -1)

def is_valid_position(position, snake_body):
    x, y = position
    return 0 <= x < GRID_WIDTH and 0 <= y < GRID_HEIGHT and position not in snake_body

def get_new_direction(current_direction, snake_head, snake_body):
    food_direction = get_direction_to_food(snake_head, food.position)
    directions = [food_direction, current_direction]
    left_turn = {(1, 0): (0, -1), (-1, 0): (0, 1), (0, 1): (1, 0), (0, -1): (-1, 0)}
    right_turn = {(1, 0): (0, 1), (-1, 0): (0, -1), (0, 1): (-1, 0), (0, -1): (1, 0)}
    directions.append(left_turn[current_direction])
    directions.append(right_turn[current_direction])
    for direction in directions:
        if is_valid_position((snake_head[0] + direction[0], snake_head[1] + direction[1]), snake_body):
            return direction
    return current_direction

# --------------------------------------
# Clases
# --------------------------------------

class Snake:
    def __init__(self):
        self.body = [(GRID_WIDTH // 2, GRID_HEIGHT // 2)]
        self.direction = (1, 0)
        self.score = 0

    def move(self):
        head = self.body[-1]
        if player_choice == '1':
            new_head = (head[0] + self.direction[0], head[1] + self.direction[1])
            self.body.append(new_head)
            if new_head == food.position:
                food.spawn()
                self.score += 1
            else:
                self.body.pop(0)
        elif player_choice == '2':
            self.direction = get_new_direction(self.direction, head, self.body)
            new_head = (head[0] + self.direction[0], head[1] + self.direction[1])
            self.body.append(new_head)
            if new_head == food.position:
                food.spawn()
                self.score += 1
            else:
                self.body.pop(0)

        if self.check_collision():
            global game_over
            game_over = True

    def check_collision(self):
        head = self.body[-1]
        return head in self.body[:-1] or head[0] < 0 or head[0] >= GRID_WIDTH or head[1] < 0 or head[1] >= GRID_HEIGHT

class Food:
    def __init__(self):
        self.position = (random.randint(0, GRID_WIDTH-1), random.randint(0, GRID_HEIGHT-1))

    def spawn(self):
        self.position = (random.randint(0, GRID_WIDTH-1), random.randint(0, GRID_HEIGHT-1))

# --------------------------------------
# Inicializaciones de juego
# --------------------------------------

snake = Snake()
food = Food()
record = read_record()
game_over = False

# --------------------------------------
# Bucle principal del juego
# --------------------------------------
clock = pygame.time.Clock()
game_over = False

screen.fill(BG_COLOR)
draw_text("Presiona '1' para jugar", 36, FONT_COLOR, WIDTH//2, HEIGHT//2 - 50)
draw_text("Presiona '2' para ver a la IA jugar", 36, FONT_COLOR, WIDTH//2, HEIGHT//2 + 50)
pygame.display.flip()

player_choice = None
while player_choice not in ('1', '2'):
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            pygame.quit()
            exit()
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_1:
                player_choice = '1'
            elif event.key == pygame.K_2:
                player_choice = '2'

if player_choice == '2':
    while not game_over:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                game_over = True

        snake.move()

        if snake.check_collision():
            game_over = True

        screen.fill(BG_COLOR)

        for segment in snake.body:
            pygame.draw.rect(screen, SNAKE_COLOR, (segment[0]*GRID_SIZE, segment[1]*GRID_SIZE, GRID_SIZE, GRID_SIZE))

        pygame.draw.rect(screen, FOOD_COLOR, (food.position[0]*GRID_SIZE, food.position[1]*GRID_SIZE, GRID_SIZE, GRID_SIZE))

        draw_text(f"Puntos: {snake.score}", 36, FONT_COLOR, WIDTH//2, 50)
        draw_text(f"Record: {record}", 36, FONT_COLOR, WIDTH//2, 100)

        pygame.display.flip()
        clock.tick(FPS)

elif player_choice == '1':
    while not game_over:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                game_over = True
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_w and snake.direction != (0, 1):
                    snake.direction = (0, -1)
                elif event.key == pygame.K_s and snake.direction != (0, -1):
                    snake.direction = (0, 1)
                elif event.key == pygame.K_a and snake.direction != (1, 0):
                    snake.direction = (-1, 0)
                elif event.key == pygame.K_d and snake.direction != (-1, 0):
                    snake.direction = (1, 0)

        snake.move()

        if snake.check_collision():
            game_over = True
                
        if snake.score >= 30:
            game_over = True

        screen.fill(BG_COLOR)

        for segment in snake.body:
            pygame.draw.rect(screen, SNAKE_COLOR, (segment[0]*GRID_SIZE, segment[1]*GRID_SIZE, GRID_SIZE, GRID_SIZE))

        pygame.draw.rect(screen, FOOD_COLOR, (food.position[0]*GRID_SIZE, food.position[1]*GRID_SIZE, GRID_SIZE, GRID_SIZE))

        draw_text(f"Puntos: {snake.score}", 36, FONT_COLOR, WIDTH//2, 50)
        draw_text(f"Record: {record}", 36, FONT_COLOR, WIDTH//2, 100)

        pygame.display.flip()
        clock.tick(FPS)

# Pantalla de win/lose
screen.fill(BG_COLOR)
if snake.score >= 30:
    draw_text("¡Ganaste!", 48, FONT_COLOR, WIDTH//2, HEIGHT//2)
else:
    draw_text(f"Perdiste. Puntuación: {snake.score}", 36, FONT_COLOR, WIDTH//2, HEIGHT//2)

pygame.display.flip()

# Esperar por 3 segundos antes de cerrar la ventana
pygame.time.delay(3000)

pygame.quit()

# Guardar el récord si es necesario
def save_record(record, score):
    if score > record:
        with open('record.txt', 'w') as file:
            file.write(str(score))

record = read_record()

## Mostrar el récord actual
print(f'Record actual: {record}')

# Actualizar el récord si es necesario
if snake.score > record:
    save_record(record, snake.score)
    print(f'¡Nuevo récord! Puntuación: {snake.score}')
