#Se importan las librerias necesarias
import pygame
import random

# Inicializar pygame
pygame.init()

#------------------------------------------------------------------------------#
# Constantes
CONTROLS = "ARROWS"  # Valores posibles: "ARROWS" o "WASD"
DEFAULT_CELL_SIZE = 20  # o cualquier valor que sea el predeterminado
DEFAULT_TIME = 100  # valor predeterminado para el tiempo
DEFAULT_LIVES = 3  # número predeterminado de vidas
DEFAULT_SCORE = 0  # puntuación predeterminada
UI_HEIGHT = 40
WIDTH, HEIGHT = 640, 480 + UI_HEIGHT
CELL_SIZE = 40
GRID_WIDTH = WIDTH // CELL_SIZE
GRID_HEIGHT = (HEIGHT - UI_HEIGHT) // CELL_SIZE
WALL = 1
PATH = 0
CURRENT_LANGUAGE = "es"  # Predeterminado en español

# Variables globales
lives = 3
level_time = 50
score = 0
total_score = 0
current_level = 1
player_pos = [0, 0]
end_pos = [GRID_WIDTH-1, GRID_HEIGHT-1]


# Colores
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
RED = (255, 0, 0)
BLUE = (0, 0, 255)
GREEN = (0, 255, 0)

# Ventana y reloj
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Laberinto")
clock = pygame.time.Clock()

#------------------------------------------------------------------------------#

LANGUAGES = {
    "es": {
        "lives": "Vidas",
        "time": "Tiempo",
        "level_score": "Puntaje Nivel",
        "total_score": "Puntaje Total",
        "level": "Nivel",
        "instructionsdesc": [
            "En este juego de laberinto tu eres un cubo rojo",
            "que quiere salir, y tienes que llegar",
            "hasta la meta de cada nivel(cubo verde).",
            "Acumula puntos, y si completas varios niveles, ¡ganas!"
        ],
        "back": "Volver",
        "win": "¡Has ganado el juego!",
        "completed": "¡Has completado el nivel!",
        "game_over": "¡Juego Terminado!",
        "game_title": "El laberinto de Mike",
        "current_high_score": "Récord actual",
        "single_game": "Juego Solo",
        "auto_game": "Juego Automático",
        "instructions": "Instrucciones",
        "settings": "Ajustes",
        "exit": "Salir",
        "controls": "Configuración de Teclas",
        "use_arrows": "Usar Flechas",
        "use_wasd": "Usar WASD"
    },
    "en": {
        "lives": "Lives",
        "time": "Time",
        "level_score": "Level Score",
        "total_score": "Total Score",
        "level": "Level",
        "instructionsdesc": [
            "In this maze game you are a red cube",
            "that wants to get out, and you have to reach",
            "the goal of each level(green cube).",
            "Earn points, and if you complete several levels, you win!"
        ],
        "back": "Back",
        "win": "You have won the game!",
        "completed": "You have completed the level!",
        "game_over": "Game Over!",
        "game_title": "Mike's Maze Game",
        "current_high_score": "Current High Score",
        "single_game": "Single Game",
        "auto_game": "Auto Game",
        "instructions": "Instructions",
        "settings": "Settings",
        "exit": "Exit",
        "controls": "Controls Settings",
        "use_arrows": "Use Arrows",
        "use_wasd": "Use WASD"
    }
}

#------------------------------------------------------------------------------#

# Clase Celda para representar cada celda del laberinto
class Cell:
    def __init__(self, x, y):
        self.x = x
        self.y = y
        self.walls = {"top": True, "right": True, "bottom": True, "left": True}
        self.visited = False

    def check_neighbors(self, grid):
        neighbors = []

        if self.x > 0:
            left = grid[self.y][self.x - 1]
            if not left.visited:
                neighbors.append(("left", left))
        if self.x < GRID_WIDTH - 1:
            right = grid[self.y][self.x + 1]
            if not right.visited:
                neighbors.append(("right", right))
        if self.y > 0:
            top = grid[self.y - 1][self.x]
            if not top.visited:
                neighbors.append(("top", top))
        if self.y < GRID_HEIGHT - 1:
            bottom = grid[self.y + 1][self.x]
            if not bottom.visited:
                neighbors.append(("bottom", bottom))

        if neighbors:
            return random.choice(neighbors)
        else:
            return None
        
#------------------------------------------------------------------------------#

# Función para cambiar el idioma
def change_language(lang):
    global CURRENT_LANGUAGE
    CURRENT_LANGUAGE = lang

def reset_game_variables():
    global maze, player_pos, level_time, score, total_score, lives, GRID_WIDTH, GRID_HEIGHT, CELL_SIZE, current_level

    CELL_SIZE = 40
    GRID_WIDTH = WIDTH // CELL_SIZE
    GRID_HEIGHT = (HEIGHT - UI_HEIGHT) // CELL_SIZE
    maze = generate_maze()
    player_pos = [0, 0]
    level_time = 100
    score = 0
    total_score = 0
    lives = 3  # asumiendo que empiezas con 3 vidas
    current_level = 1


# Función para eliminar las paredes entre dos celdas
def remove_walls(cellA, cellB, direction):
    if direction == "left":
        cellA.walls["left"] = False
        cellB.walls["right"] = False
    elif direction == "right":
        cellA.walls["right"] = False
        cellB.walls["left"] = False
    elif direction == "top":
        cellA.walls["top"] = False
        cellB.walls["bottom"] = False
    elif direction == "bottom":
        cellA.walls["bottom"] = False
        cellB.walls["top"] = False

# Función para generar el laberinto
def generate_maze():
    grid = [[Cell(x, y) for x in range(GRID_WIDTH)] for y in range(GRID_HEIGHT)]
    start_cell = grid[0][0]
    stack = [start_cell]
    while stack:
        current_cell = stack[-1]
        current_cell.visited = True
        neighbor_data = current_cell.check_neighbors(grid)
        if neighbor_data:
            direction, next_cell = neighbor_data
            remove_walls(current_cell, next_cell, direction)
            stack.append(next_cell)
        else:
            stack.pop()

    return grid

# Función para verificar si el jugador puede moverse a una celda
def can_move_to(x, y, direction):
    current_cell = maze[y][x]
    if direction == "left" and x > 0:
        return not current_cell.walls["left"]
    if direction == "right" and x < GRID_WIDTH - 1:
        return not current_cell.walls["right"]
    if direction == "up" and y > 0:
        return not current_cell.walls["top"]
    if direction == "down" and y < GRID_HEIGHT - 1:
        return not current_cell.walls["bottom"]
    return False

# Función para obtener el puntaje más alto
def get_high_score():
    try:
        with open("high_score.txt", "r") as f:
            return int(f.read())
    except FileNotFoundError:
        return 0

# Función para establecer el puntaje más alto
def set_high_score(score):
    with open("high_score.txt", "w") as f:
        f.write(str(score))

# Función para dibujar la interfaz de usuario
def draw_ui():
    global exit_button
    pygame.draw.rect(screen, (150, 150, 150, 50), (0, 0, WIDTH, UI_HEIGHT))
    font = pygame.font.SysFont(None, 25)
    exit_font = pygame.font.SysFont(None, 30)
    
    lives_text = font.render(f"{LANGUAGES[CURRENT_LANGUAGE]['lives']}: {lives}", True, BLACK)
    time_text = font.render(f"{LANGUAGES[CURRENT_LANGUAGE]['time']}: {level_time}", True, BLACK)
    score_text = font.render(f"{LANGUAGES[CURRENT_LANGUAGE]['level_score']}: {score}", True, BLACK)
    total_score_text = font.render(f"{LANGUAGES[CURRENT_LANGUAGE]['total_score']}: {total_score}", True, BLACK)
    level_text = font.render(f"{LANGUAGES[CURRENT_LANGUAGE]['level']}: {current_level}", True, BLACK)
    
    exit_text = exit_font.render(LANGUAGES[CURRENT_LANGUAGE]['exit'], True, BLACK)
    exit_button = pygame.draw.rect(screen, RED, (WIDTH - 80, 5, 70, 30))
    screen.blit(exit_text, (WIDTH - 75, 10))
    
    screen.blit(lives_text, (10, 10))
    screen.blit(time_text, (WIDTH - 200, 10))
    screen.blit(score_text, (WIDTH / 2 - 50, 10))
    screen.blit(total_score_text, (WIDTH / 2 - 50, 25))
    screen.blit(level_text, (WIDTH - 200, 25))

# Función para dibujar el laberinto
def draw():
    screen.fill(WHITE)
    for y in range(GRID_HEIGHT):
        for x in range(GRID_WIDTH):
            cell = maze[y][x]
            if cell.walls["top"]:
                pygame.draw.line(screen, RED, (x*CELL_SIZE, y*CELL_SIZE+ UI_HEIGHT), ((x+1)*CELL_SIZE, y*CELL_SIZE+ UI_HEIGHT))
            if cell.walls["right"]:
                pygame.draw.line(screen, RED, ((x+1)*CELL_SIZE, y*CELL_SIZE+ UI_HEIGHT), ((x+1)*CELL_SIZE, (y+1)*CELL_SIZE+ UI_HEIGHT))
            if cell.walls["bottom"]:
                pygame.draw.line(screen, RED, ((x+1)*CELL_SIZE, (y+1)*CELL_SIZE+ UI_HEIGHT), (x*CELL_SIZE, (y+1)*CELL_SIZE+ UI_HEIGHT))
            if cell.walls["left"]:
                pygame.draw.line(screen, RED, (x*CELL_SIZE, (y+1)*CELL_SIZE+ UI_HEIGHT), (x*CELL_SIZE, y*CELL_SIZE+ UI_HEIGHT))

    pygame.draw.rect(screen, BLUE, (player_pos[0]*CELL_SIZE, player_pos[1]*CELL_SIZE + UI_HEIGHT, CELL_SIZE, CELL_SIZE))
    pygame.draw.rect(screen, GREEN, (end_pos[0]*CELL_SIZE, end_pos[1]*CELL_SIZE + UI_HEIGHT, CELL_SIZE, CELL_SIZE))

    draw_ui()
    pygame.display.flip()

# Función para jugar automáticamente
def auto_play():
    global CELL_SIZE, GRID_WIDTH, GRID_HEIGHT, maze, player_pos, end_pos
    reset_game_variables()
    cell_sizes = [50, 40, 30, 20, 10]

    for size in cell_sizes:
        CELL_SIZE = size
        GRID_WIDTH = WIDTH // CELL_SIZE
        GRID_HEIGHT = (HEIGHT - UI_HEIGHT) // CELL_SIZE
        player_pos = [0, 0]
        
        # Establecer la posición de la meta para el primer laberinto en modo automático
        if size == 50:
            end_pos = [0, 0]
        else:
            end_pos = [GRID_WIDTH-1, GRID_HEIGHT-1]
            
        maze = generate_maze()
        solve_maze_automatically()

# Función para resolver el laberinto automáticamente
def solve_maze_automatically():
    global player_pos, maze

    stack = [player_pos.copy()]  # Una pila para seguir las posiciones
    visited = set()  # Un conjunto para las posiciones ya visitadas

    while stack:
        current_pos = stack[-1]
        x, y = current_pos
        visited.add(tuple(current_pos))

        # Actualizamos la posición del jugador y lo dibujamos
        player_pos = current_pos
        draw()
        for event in pygame.event.get():
            if event.type == pygame.MOUSEBUTTONDOWN:
                x, y = pygame.mouse.get_pos()
                if exit_button.collidepoint(x, y):
                    main_menu()
                    return
        pygame.time.wait(50)  # Agregar un pequeño retraso para que se pueda observar el movimiento

        if player_pos == end_pos:  # Si llegamos al final, terminamos
            print("¡He encontrado la salida!")
            break

        neighbors = get_valid_neighbors(x, y)

        unvisited_neighbors = [n for n in neighbors if tuple(n) not in visited]

        if unvisited_neighbors:  # Si hay vecinos no visitados
            stack.append(unvisited_neighbors[0])  # Añadimos el primer vecino no visitado a la pila
        else:  # Si no hay vecinos válidos
            stack.pop()  # Retrocedemos

# Función para obtener los vecinos válidos
def get_valid_neighbors(x, y):
    directions = [("right", 1, 0), ("down", 0, 1), ("left", -1, 0), ("up", 0, -1)]  # right, down, left, up
    neighbors = []

    for direction, dx, dy in directions:
        nx, ny = x + dx, y + dy
        if 0 <= nx < GRID_WIDTH and 0 <= ny < GRID_HEIGHT and can_move_to(x, y, direction):
            neighbors.append([nx, ny])

    return neighbors

#------------------------------------------------------------------------------#

# Pantalla para instrucciones
def instructions_screen():
    running = True
    while running:
        screen.fill(WHITE)
        
        font = pygame.font.SysFont(None, 30)
        instructions = LANGUAGES[CURRENT_LANGUAGE]["instructionsdesc"]
        
        y_offset = 100
        for line in instructions:
            text = font.render(line, True, BLACK)
            screen.blit(text, (WIDTH // 2 - text.get_width() // 2, y_offset))
            y_offset += 40

        # Dibujo del botón "Volver"
        button_back = pygame.draw.rect(screen, BLUE, (WIDTH // 2 - 70, 350, 140, 40))
        text_back = font.render(LANGUAGES[CURRENT_LANGUAGE]["back"], True, BLACK)
        screen.blit(text_back, (WIDTH // 2 - text_back.get_width() // 2, 355))
        
        pygame.display.flip()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                exit()
            if event.type == pygame.MOUSEBUTTONDOWN:
                x, y = pygame.mouse.get_pos()
                if button_back.collidepoint(x, y):
                    return
  
# Pantalla de ajustes
def settings_screen():
    global CONTROLS
    running = True
    font = pygame.font.SysFont(None, 30)
    subtitle_font = pygame.font.SysFont(None, 35)
    
    while running:
        screen.fill(WHITE)
        
        # Subtitulo de idioma (localizado)
        language_subtitle = subtitle_font.render(LANGUAGES[CURRENT_LANGUAGE]["settings"], True, BLACK)
        screen.blit(language_subtitle, (WIDTH // 2 - language_subtitle.get_width() // 2, 70))
        
        # Dibujo del botón "Inglés"
        button_english = pygame.draw.rect(screen, BLUE, (WIDTH // 2 - 70, 120, 140, 40))
        text_english = font.render("English", True, BLACK)
        screen.blit(text_english, (WIDTH // 2 - text_english.get_width() // 2, 125))
        
        # Dibujo del botón "Español"
        button_spanish = pygame.draw.rect(screen, BLUE, (WIDTH // 2 - 70, 170, 140, 40))
        text_spanish = font.render("Español", True, BLACK)
        screen.blit(text_spanish, (WIDTH // 2 - text_spanish.get_width() // 2, 175))
        
        # Subtitulo de configuración de teclas (localizado)
        controls_subtitle = subtitle_font.render(LANGUAGES[CURRENT_LANGUAGE]["controls"], True, BLACK)
        screen.blit(controls_subtitle, (WIDTH // 2 - controls_subtitle.get_width() // 2, 250))
        
        # Dibujo del botón "Flechas"
        button_arrows = pygame.draw.rect(screen, BLUE, (WIDTH // 2 - 100, 300, 200, 40))
        text_arrows = font.render(LANGUAGES[CURRENT_LANGUAGE]["use_arrows"], True, BLACK)
        screen.blit(text_arrows, (WIDTH // 2 - text_arrows.get_width() // 2, 305))
        
        # Dibujo del botón "WASD"
        button_wasd = pygame.draw.rect(screen, BLUE, (WIDTH // 2 - 100, 350, 200, 40))
        text_wasd = font.render(LANGUAGES[CURRENT_LANGUAGE]["use_wasd"], True, BLACK)
        screen.blit(text_wasd, (WIDTH // 2 - text_wasd.get_width() // 2, 355))
        
        # Dibujo del botón "Volver"
        button_back = pygame.draw.rect(screen, BLUE, (WIDTH // 2 - 70, 430, 140, 40))
        text_back = font.render(LANGUAGES[CURRENT_LANGUAGE]["back"], True, BLACK)
        screen.blit(text_back, (WIDTH // 2 - text_back.get_width() // 2, 435))
        
        pygame.display.flip()

        for event in pygame.event.get():
            if event.type == pygame.MOUSEBUTTONDOWN:
                x, y = pygame.mouse.get_pos()
                if button_arrows.collidepoint(x, y):
                    CONTROLS = "ARROWS"
                    running = False
                elif button_wasd.collidepoint(x, y):
                    CONTROLS = "WASD"
                    running = False
                elif button_back.collidepoint(x, y):
                    running = False
                elif button_english.collidepoint(x, y):
                    change_language("en")
                    running = False
                elif button_spanish.collidepoint(x, y):
                    change_language("es")
                    running = False

#Pantalla Menu Principal
def main_menu():
    global CELL_SIZE
    CELL_SIZE = 40
    menu_font = pygame.font.SysFont(None, 40)
    button_font = pygame.font.SysFont(None, 30)
    title = menu_font.render(LANGUAGES[CURRENT_LANGUAGE]["game_title"], True, BLACK)
    high_score_text = button_font.render(f"{LANGUAGES[CURRENT_LANGUAGE]['current_high_score']}: {get_high_score()}", True, BLACK)

    buttons = {
        LANGUAGES[CURRENT_LANGUAGE]["single_game"]: mainGame,
        LANGUAGES[CURRENT_LANGUAGE]["auto_game"]: auto_play,
        LANGUAGES[CURRENT_LANGUAGE]["instructions"]: instructions_screen,
        LANGUAGES[CURRENT_LANGUAGE]["settings"]: settings_screen,
        LANGUAGES[CURRENT_LANGUAGE]["exit"]: pygame.quit
    }

    while True:
        title = menu_font.render(LANGUAGES[CURRENT_LANGUAGE]["game_title"], True, BLACK)
        high_score_text = button_font.render(f"{LANGUAGES[CURRENT_LANGUAGE]['current_high_score']}: {get_high_score()}", True, BLACK)

        buttons = {
            LANGUAGES[CURRENT_LANGUAGE]["single_game"]: mainGame,
            LANGUAGES[CURRENT_LANGUAGE]["auto_game"]: auto_play,
            LANGUAGES[CURRENT_LANGUAGE]["instructions"]: instructions_screen,
            LANGUAGES[CURRENT_LANGUAGE]["settings"]: settings_screen,
            LANGUAGES[CURRENT_LANGUAGE]["exit"]: pygame.quit
        }
        screen.fill(WHITE)
        screen.blit(title, (WIDTH / 2 - title.get_width() / 2, 50))
        screen.blit(high_score_text, (WIDTH - high_score_text.get_width() - 10, 10))

        y_offset = 150
        for text, func in buttons.items():
            text_surf = button_font.render(text, True, BLACK)
            text_rect = text_surf.get_rect(center=(WIDTH / 2, y_offset))
            pygame.draw.rect(screen, (150, 150, 150), text_rect.inflate(10, 10))
            screen.blit(text_surf, text_rect.topleft)
            y_offset += 50

        pygame.display.flip()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                return
            elif event.type == pygame.MOUSEBUTTONDOWN:
                if event.button == 1:  # Left click
                    y_offset = 150
                    for text, func in buttons.items():
                        text_surf = button_font.render(text, True, BLACK)
                        text_rect = text_surf.get_rect(center=(WIDTH / 2, y_offset))
                        if text_rect.inflate(10, 10).collidepoint(event.pos) and func:
                            func()
                        y_offset += 50

#------------------------------------------------------------------------------#

# Función principal del juego
def mainGame():
    # Añadir al inicio de mainGame():
    reset_game_variables()
    start_ticks = pygame.time.get_ticks()
    global maze, player_pos, level_time, score, total_score, lives, GRID_WIDTH, GRID_HEIGHT, CELL_SIZE, current_level, exit_button

    running = True
    maze = generate_maze()

    while running:
        for event in pygame.event.get():
            if event.type == pygame.MOUSEBUTTONDOWN:
                x, y = pygame.mouse.get_pos()
                if exit_button.collidepoint(x, y):
                    main_menu()
                    return
            if event.type == pygame.KEYDOWN:
                if CONTROLS == "ARROWS":
                    if event.key == pygame.K_UP and can_move_to(player_pos[0], player_pos[1], "up"):
                        player_pos[1] -= 1
                    elif event.key == pygame.K_DOWN and can_move_to(player_pos[0], player_pos[1], "down"):
                        player_pos[1] += 1
                    elif event.key == pygame.K_LEFT and can_move_to(player_pos[0], player_pos[1], "left"):
                        player_pos[0] -= 1
                    elif event.key == pygame.K_RIGHT and can_move_to(player_pos[0], player_pos[1], "right"):
                        player_pos[0] += 1
                elif CONTROLS == "WASD":
                    if event.key == pygame.K_w and can_move_to(player_pos[0], player_pos[1], "up"):
                        player_pos[1] -= 1
                    elif event.key == pygame.K_s and can_move_to(player_pos[0], player_pos[1], "down"):
                        player_pos[1] += 1
                    elif event.key == pygame.K_a and can_move_to(player_pos[0], player_pos[1], "left"):
                        player_pos[0] -= 1
                    elif event.key == pygame.K_d and can_move_to(player_pos[0], player_pos[1], "right"):
                        player_pos[0] += 1


        # Dentro del bucle principal de mainGame(), antes de llamar a draw():
        seconds_passed = (pygame.time.get_ticks() - start_ticks) / 1000
        level_time = max(50 - int(seconds_passed), 0)
        score = level_time
        if total_score > get_high_score():
            set_high_score(total_score)
        
        if level_time == 0:
            lives -= 1
            if lives <= 0:
                print(LANGUAGES[CURRENT_LANGUAGE]['game_over'])
                if total_score > get_high_score():
                    set_high_score(total_score)
                main_menu()
                return
            else:
                player_pos = [0, 0]
                start_ticks = pygame.time.get_ticks()
                draw()

        # Cuando el jugador llega al final:
        if player_pos == end_pos:
            print(LANGUAGES[CURRENT_LANGUAGE]['completed'])
            total_score += score
            score = 0
            current_level += 1  # Aumenta el nivel
            # Reducir el tamaño de la celda si no es menor que 30
            if CELL_SIZE > 30:
                CELL_SIZE -= 5
                GRID_WIDTH = WIDTH // CELL_SIZE
                GRID_HEIGHT = (HEIGHT - UI_HEIGHT) // CELL_SIZE
                maze = generate_maze()
                player_pos = [0, 0]
                
                # Reiniciar el tiempo para el nuevo nivel
                start_ticks = pygame.time.get_ticks()
                level_time = 100
                
            else:
                print(LANGUAGES[CURRENT_LANGUAGE]['win'])
                if total_score > get_high_score():
                    set_high_score(total_score)
                main_menu()
                return
            
        draw()
        clock.tick(60)

    pygame.quit()

#------------------------------------------------------------------------------#
# Iniciar el juego
if __name__ == "__main__":
    main_menu()