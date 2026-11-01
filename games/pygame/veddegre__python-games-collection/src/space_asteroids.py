import os
os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "1"
from highscores import get_high_score, save_high_score
GAME_NAME = "space_asteroids"
import pygame
import random
import math
import sys

# Initialize pygame
pygame.init()

# Screen settings
WIDTH, HEIGHT = 800, 600
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Space Asteroids")
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
RED = (255, 0, 0)
YELLOW = (255, 255, 0)

# Game variables
clock = pygame.time.Clock()
font = pygame.font.SysFont('Arial', 30)
score_font = pygame.font.SysFont('Arial', 25)
player_speed = 5
bullet_speed = 10
bullet_cooldown = 15
game_over = False
score = 0

class Player:
    def __init__(self):
        self.x = WIDTH // 2
        self.y = HEIGHT - 50
        self.width = 30
        self.height = 40
        self.speed = player_speed
        self.cooldown = 0
    
    def draw(self):
        # Draw ship body
        pygame.draw.polygon(screen, WHITE, [
            (self.x, self.y - self.height // 2),  # tip
            (self.x - self.width // 2, self.y + self.height // 2),  # left corner
            (self.x, self.y + self.height // 4),  # middle bottom
            (self.x + self.width // 2, self.y + self.height // 2)   # right corner
        ])
        
        # Draw engine flame effect
        flame_height = random.randint(10, 20)
        pygame.draw.polygon(screen, YELLOW, [
            (self.x - 5, self.y + self.height // 4),
            (self.x, self.y + self.height // 4 + flame_height),
            (self.x + 5, self.y + self.height // 4)
        ])
    
    def move(self, direction):
        if direction == "left" and self.x > self.width // 2:
            self.x -= self.speed
        if direction == "right" and self.x < WIDTH - self.width // 2:
            self.x += self.speed
    
    def update(self):
        if self.cooldown > 0:
            self.cooldown -= 1

class Bullet:
    def __init__(self, x, y):
        self.x = x
        self.y = y
        self.radius = 4
        self.speed = bullet_speed
    
    def draw(self):
        pygame.draw.circle(screen, RED, (self.x, self.y), self.radius)
    
    def update(self):
        self.y -= self.speed
    
    def off_screen(self):
        return self.y < 0

class Asteroid:
    def __init__(self):
        self.size = random.randint(15, 45)
        self.x = random.randint(self.size, WIDTH - self.size)
        self.y = random.randint(-50, -10)
        self.speed_y = random.uniform(1.5, 4)
        self.speed_x = random.uniform(-1, 1)
        self.rotation = 0
        self.rotation_speed = random.uniform(-2, 2)
        
        # Generate irregular shape points
        self.points = []
        for i in range(8):  # 8 points to make the asteroid shape
            angle = 2 * math.pi * i / 8
            distance = self.size * random.uniform(0.7, 1.0)
            self.points.append((
                distance * math.cos(angle),
                distance * math.sin(angle)
            ))
    
    def draw(self):
        # Transform rotation
        rotated_points = []
        for point in self.points:
            x = point[0] * math.cos(self.rotation) - point[1] * math.sin(self.rotation)
            y = point[0] * math.sin(self.rotation) + point[1] * math.cos(self.rotation)
            rotated_points.append((self.x + x, self.y + y))
        
        pygame.draw.polygon(screen, WHITE, rotated_points, 2)
    
    def update(self):
        self.y += self.speed_y
        self.x += self.speed_x
        self.rotation += self.rotation_speed * 0.01
        
        # Bounce off the sides
        if self.x <= self.size or self.x >= WIDTH - self.size:
            self.speed_x = -self.speed_x
    
    def off_screen(self):
        return self.y > HEIGHT + self.size
    
    def collision(self, other_x, other_y, other_radius):
        # Simple circle collision
        distance = math.sqrt((self.x - other_x)**2 + (self.y - other_y)**2)
        return distance < self.size + other_radius

class Explosion:
    def __init__(self, x, y, size):
        self.x = x
        self.y = y
        self.size = size
        self.particles = []
        self.lifetime = 30
        
        # Create particles
        for _ in range(20):
            speed = random.uniform(1, 4)
            angle = random.uniform(0, 2 * math.pi)
            self.particles.append({
                'x': 0,
                'y': 0,
                'dx': speed * math.cos(angle),
                'dy': speed * math.sin(angle),
                'size': random.randint(1, 3)
            })
    
    def draw(self):
        intensity = min(255, int(255 * (self.lifetime / 30)))
        for particle in self.particles:
            pygame.draw.circle(screen, (intensity, intensity // 2, 0), 
                              (int(self.x + particle['x']), int(self.y + particle['y'])), 
                              particle['size'])
    
    def update(self):
        self.lifetime -= 1
        for particle in self.particles:
            particle['x'] += particle['dx']
            particle['y'] += particle['dy']
    
    def finished(self):
        return self.lifetime <= 0

class Star:
    def __init__(self):
        self.x = random.randint(0, WIDTH)
        self.y = random.randint(0, HEIGHT)
        self.size = random.uniform(0.5, 2)
        self.speed = random.uniform(0.1, 0.5)
    
    def draw(self):
        pygame.draw.circle(screen, WHITE, (int(self.x), int(self.y)), int(self.size))
    
    def update(self):
        self.y += self.speed
        if self.y > HEIGHT:
            self.y = 0
            self.x = random.randint(0, WIDTH)

def main():
    global game_over, score
    
    # Game objects
    player = Player()
    bullets = []
    asteroids = []
    explosions = []
    
    # Create stars for background
    stars = [Star() for _ in range(100)]
    
    # Asteroid spawn timer
    asteroid_timer = 0
    asteroid_spawn_rate = 30  # frames between spawns
    
    # Game loop
    running = True
    
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    running = False
            
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_r and game_over:
                    # Restart game
                    player = Player()
                    bullets = []
                    asteroids = []
                    explosions = []
                    game_over = False
                    score = 0
        
        # Get keys pressed
        keys = pygame.key.get_pressed()
        
        if not game_over:
            # Player movement
            if keys[pygame.K_LEFT]:
                player.move("left")
            if keys[pygame.K_RIGHT]:
                player.move("right")
            
            # Shooting
            if keys[pygame.K_SPACE] and player.cooldown == 0:
                bullets.append(Bullet(player.x, player.y - player.height // 2))
                player.cooldown = bullet_cooldown
            
            # Update player
            player.update()
            
            # Update bullets
            for bullet in bullets[:]:
                bullet.update()
                if bullet.off_screen():
                    bullets.remove(bullet)
            
            # Spawn asteroids
            asteroid_timer += 1
            if asteroid_timer >= asteroid_spawn_rate:
                asteroids.append(Asteroid())
                asteroid_timer = 0
                # Gradually increase difficulty
                if asteroid_spawn_rate > 10:
                    asteroid_spawn_rate = max(10, asteroid_spawn_rate - 0.1)
            
            # Update asteroids
            for asteroid in asteroids[:]:
                asteroid.update()
                
                # Check collision with player
                if asteroid.collision(player.x, player.y, player.width // 2):
                    explosions.append(Explosion(player.x, player.y, player.width))
                    game_over = True
                    save_high_score(GAME_NAME, score)
                
                # Check collision with bullets
                for bullet in bullets[:]:
                    if asteroid.collision(bullet.x, bullet.y, bullet.radius):
                        explosions.append(Explosion(asteroid.x, asteroid.y, asteroid.size))
                        if bullet in bullets:
                            bullets.remove(bullet)
                        if asteroid in asteroids:
                            asteroids.remove(asteroid)
                            score += 1
                        break
                
                # Remove off-screen asteroids
                if asteroid.off_screen() and asteroid in asteroids:
                    asteroids.remove(asteroid)
        
        # Update explosions
        for explosion in explosions[:]:
            explosion.update()
            if explosion.finished():
                explosions.remove(explosion)
        
        # Update stars
        for star in stars:
            star.update()
        
        # Drawing
        screen.fill(BLACK)
        
        # Draw stars
        for star in stars:
            star.draw()
        
        # Draw bullets
        for bullet in bullets:
            bullet.draw()
        
        # Draw asteroids
        for asteroid in asteroids:
            asteroid.draw()
        
        # Draw explosions
        for explosion in explosions:
            explosion.draw()
        
        # Draw player if game's not over
        if not game_over:
            player.draw()
        
        # Draw score
        score_text = score_font.render(f"Score: {score}", True, WHITE)
        screen.blit(score_text, (10, 10))
        hi_text = score_font.render(f"Best: {get_high_score(GAME_NAME)}", True, (255, 215, 0))
        screen.blit(hi_text, (10, 36))
        
        # Draw game over
        if game_over:
            game_over_text = font.render("GAME OVER", True, WHITE)
            restart_text = font.render("Press R to Restart", True, WHITE)
            screen.blit(game_over_text, (WIDTH // 2 - game_over_text.get_width() // 2, HEIGHT // 2 - 30))
            screen.blit(restart_text, (WIDTH // 2 - restart_text.get_width() // 2, HEIGHT // 2 + 10))
        
        pygame.display.flip()
        clock.tick(60)
    
    pygame.quit()
    sys.exit()

if __name__ == "__main__":
    main()
