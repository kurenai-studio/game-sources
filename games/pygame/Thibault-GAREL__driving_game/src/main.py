import pygame
import sys
import math

pygame.init()
WIDTH, HEIGHT = 1000, 600
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Voiture avec rebonds sans rotation")


WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
RED = (255, 0, 0)
GRAY = (40, 40, 60)
BLUE = (0, 0, 255)


car_width, car_height = 40, 20
car_x, car_y = 100, 100
car_angle = 0
car_speed = 0
max_speed = 5
acceleration = 0.2
turn_speed = 4

walls = [
    pygame.Rect(50, 50, 700, 10),
    pygame.Rect(50, 540, 700, 10),
    pygame.Rect(50, 50, 10, 500),
    pygame.Rect(740, 50, 10, 500),
    pygame.Rect(200, 150, 410, 10),
    pygame.Rect(200, 150, 10, 300),
    pygame.Rect(400, 250, 10, 300),
    pygame.Rect(600, 150, 10, 300),
]


checkpoints = [
    (180, 110, 40),  # Start / Arrival
    (670, 150, 40),
    (600, 495, 40),
    (400, 210, 40),
    (180, 485, 40)
]

current_checkpoint = 0
laps_completed = 0
best_lap_time = float('inf')
lap_start_time = 0
current_lap_time = 0

# Capteurs
def cast_ray(x, y, angle):
    ray_x, ray_y = x, y
    while 0 <= ray_x < WIDTH and 0 <= ray_y < HEIGHT:
        ray_x += math.cos(math.radians(angle))
        ray_y += math.sin(math.radians(angle))
        for wall in walls:
            if wall.collidepoint(ray_x, ray_y):
                return math.sqrt((ray_x - x) ** 2 + (ray_y - y) ** 2)
    return float('inf')

def draw_sensors(x, y, angle):
    sensor_angles = [-45, -22.5, 0, 22.5, 45]
    for sensor_angle in sensor_angles:
        distance = cast_ray(x, y, angle + sensor_angle)
        end_x = x + math.cos(math.radians(angle + sensor_angle)) * distance
        end_y = y + math.sin(math.radians(angle + sensor_angle)) * distance
        pygame.draw.line(screen, BLUE, (x, y), (end_x, end_y), 1)

def draw_car(x, y, angle):
    car_surface = pygame.Surface((car_width, car_height))
    car_surface.fill(RED)
    car_surface.set_colorkey(BLACK)
    rotated_car = pygame.transform.rotate(car_surface, -angle)
    rect = rotated_car.get_rect(center=(x, y))
    screen.blit(rotated_car, rect.topleft)

def draw_checkpoints():
    font = pygame.font.Font(None, 24)
    for i, (x, y, _) in enumerate(checkpoints):
        color = (255, 255, 0) if i == current_checkpoint else BLUE
        pygame.draw.circle(screen, color, (x, y), 40, 3)
        label = "Départ" if i == 0 else f"{i}"
        text = font.render(label, True, WHITE)
        text_rect = text.get_rect(center=(x, y))
        screen.blit(text, text_rect)


def handle_input(speed, angle):
    keys = pygame.key.get_pressed()
    if keys[pygame.K_z]:
        speed = min(speed + acceleration, max_speed)
    elif keys[pygame.K_s]:
        speed = max(speed - acceleration, -max_speed / 2)
    else:
        speed *= 0.95

    if keys[pygame.K_d]:
        angle += turn_speed
    if keys[pygame.K_q]:
        angle -= turn_speed

    return speed, angle

def update_position(x, y, angle, speed):
    dx = math.cos(math.radians(angle)) * speed
    dy = math.sin(math.radians(angle)) * speed
    return x + dx, y + dy

def check_collision(x, y):
    car_rect = pygame.Rect(0, 0, car_width, car_height)
    car_rect.center = (x, y)
    for wall in walls:
        if car_rect.colliderect(wall):
            return True
    return False

def check_checkpoints(x, y, current_time):
    global current_checkpoint, laps_completed, best_lap_time, lap_start_time, current_lap_time

    cx, cy, radius = checkpoints[current_checkpoint]
    distance = math.hypot(x - cx, y - cy)

    if distance < radius:
        if current_checkpoint == 0:
            if lap_start_time > 0:
                lap_time = current_time - lap_start_time
                laps_completed += 1
                if lap_time < best_lap_time:
                    best_lap_time = lap_time
            lap_start_time = current_time

        current_checkpoint = (current_checkpoint + 1) % len(checkpoints)

    if lap_start_time > 0:
        current_lap_time = current_time - lap_start_time


def main_game_loop():
    global car_x, car_y, car_angle, car_speed
    clock = pygame.time.Clock()
    has_collided = False

    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()

        car_speed, car_angle = handle_input(car_speed, car_angle)


        new_x, new_y = update_position(car_x, car_y, car_angle, car_speed)


        current_time = pygame.time.get_ticks() / 1000.0
        check_checkpoints(car_x, car_y, current_time)



        if check_collision(new_x, new_y):
            if not has_collided:
                car_speed *= -0.3  # rebond sans tourner
                has_collided = True
        else:
            car_x, car_y = new_x, new_y
            has_collided = False


        screen.fill(GRAY)
        for wall in walls:
            pygame.draw.rect(screen, WHITE, wall, border_radius=10)
        draw_sensors(car_x, car_y, car_angle)
        draw_car(car_x, car_y, car_angle)

        draw_checkpoints()


        font = pygame.font.Font(None, 26)
        lap_text = font.render(f"Tours: {laps_completed}", True, WHITE)
        checkpoint_text = font.render(f"Checkpoint: {current_checkpoint}/{len(checkpoints)-1}", True, WHITE)
        time_text = font.render(f"Temps: {current_lap_time:.1f}s", True, WHITE)
        best_text = font.render(f"Meilleur: {best_lap_time:.1f}s", True, WHITE)

        screen.blit(lap_text, (800, 10))
        screen.blit(checkpoint_text, (800, 50))
        screen.blit(time_text, (800, 90))
        screen.blit(best_text, (800, 130))


        pygame.display.flip()
        clock.tick(60)

if __name__ == "__main__":
    main_game_loop()

