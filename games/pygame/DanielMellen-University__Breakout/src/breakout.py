import pygame
import random
import math

# Initialize Pygame
pygame.init()

# Define Hardcoded Colors as RGB Tuples
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
RED = (255, 0, 0)
DARK_ORANGE = (255, 100, 0)
LIGHT_ORANGE = (255, 170, 0)
YELLOW = (255, 255, 0)
MAGENTA = (255, 0, 255)
PINK = (255, 20, 147)
CYAN = (0, 255, 255)
BLUE = (0, 0, 255)  # For slow time glow

# Power-Up Types Dictionary
POWER_UP_TYPES = {
    "slow_time": {
        "saturated_color": BLUE,
        "effect": "slow_time",
        "duration_add": 10 * 60,  # 10 seconds
        "message": "+slow"
    },
    "extend_platform": {
        "saturated_color": (128, 0, 128),  # Purple
        "effect": "extend_platform",
        "hits_add": 5,  # 5 ball hits
        "message": "+size"
    },
    "extra_ball": {
        "saturated_color": (0, 255, 0),  # Green
        "effect": "extra_ball",
        "message": "+ball"
    },
    "extra_life": {
        "saturated_color": PINK,
        "effect": "extra_life",
        "message": "+life"
    },
    "bomb": {
        "saturated_color": CYAN,
        "effect": "bomb",
        "message": "+bomb"
    }
}

# Brick Hit Colors
BRICK_HIT_COLORS = [RED, DARK_ORANGE, LIGHT_ORANGE, YELLOW]

# Global Flashing Function
def get_flashing_color(frame_count, saturated_color):
    period = 120
    t = abs((frame_count % period) / (period / 2) - 1)
    return (
        int(saturated_color[0] + (WHITE[0] - saturated_color[0]) * t),
        int(saturated_color[1] + (WHITE[1] - saturated_color[1]) * t),
        int(saturated_color[2] + (WHITE[2] - saturated_color[2]) * t)
    )

class PowerUpMessage:
    def __init__(self, x, y, text, color, screen_height):
        self.x = x
        self.y = y
        self.text = text
        self.color = color
        self.font = pygame.font.Font(None, int(screen_height / 30))
        self.velocity_y = -screen_height / 600
        self.lifetime = 5 * 60
        self.max_lifetime = self.lifetime

    def update(self):
        self.y += self.velocity_y
        self.lifetime -= 1

    def draw(self, screen):
        if self.lifetime > 0:
            alpha = int(255 * (self.lifetime / self.max_lifetime))
            text_surface = self.font.render(self.text, True, self.color)
            text_surface.set_alpha(alpha)
            text_rect = text_surface.get_rect(center=(self.x, self.y))
            screen.blit(text_surface, text_rect)

class TimeRipple:
    def __init__(self, x, y, screen_width, screen_height, color=CYAN):
        self.x = x
        self.y = y
        self.radius = 0
        self.max_radius = max(screen_width, screen_height) / 1.5
        self.lifetime = 300  # 5 seconds at 60 FPS
        self.max_lifetime = self.lifetime
        self.start_radius = 10
        self.radius_increase = (self.max_radius - self.start_radius) / self.lifetime
        self.radius = self.start_radius
        self.color = color

    def update(self):
        self.radius += self.radius_increase
        self.lifetime -= 1

    def get_distortion_offset(self, x, y):
        # Calculate distance from the ripple center
        distance = math.sqrt((x - self.x) ** 2 + (y - self.y) ** 2)
        
        # Check if the point is within the ripple’s current radius
        if distance < self.radius:
            wave_width = 50  # Width of the distortion wave band
            wave_position = (self.radius - distance) / wave_width            
            
            # Apply distortion only within the wave band (0 to 1)
            if 0 <= wave_position <= 1:
                A = 3  # Base amplitude of distortion
                frequency = 10  # Frequency for wavy, molecular-like effect
                sigma = 0.2  # Controls smoothness of the distortion fade
                omega = 0.1  # Phase shift speed for dynamic effect
                t = self.max_lifetime - self.lifetime  # Time since ripple started
                
                # Scale amplitude with remaining lifetime for gradual fade
                amplitude = A * (self.lifetime / self.max_lifetime)
                
                # Gaussian envelope for smooth distortion transition
                base_offset = math.exp(- ((wave_position - 0.5) / sigma) ** 2)
                
                # Distortion with oscillation and time-dependent shift
                offset = amplitude * base_offset * math.sin(frequency * wave_position * math.pi - omega * t)
                
                # Calculate direction from center to point
                angle = math.atan2(y - self.y, x - self.x)
                
                # Radial and tangential components for a swirling effect
                radial_offset = offset
                tangential_offset = 0 * offset  # Half the radial offset for swirl
                
                offset_x = radial_offset * math.cos(angle) - tangential_offset * math.sin(angle)
                offset_y = radial_offset * math.sin(angle) + tangential_offset * math.cos(angle)
                
                return offset_x, offset_y

        # No distortion outside the wave band or ripple radius
        return 0, 0

    def draw(self, screen):
        if self.lifetime > 0:
            alpha = int(255 * (self.lifetime / self.max_lifetime))
            surface = pygame.Surface((self.radius * 2, self.radius * 2), pygame.SRCALPHA)
            pygame.draw.circle(surface, (*self.color, alpha // 2), (self.radius, self.radius), self.radius, 2)
            screen.blit(surface, (self.x - self.radius, self.y - self.radius))

class Menu:
    def __init__(self, screen, screen_width, screen_height, title="Select Starting Level", options=[f"Level {i}" for i in range(1, 5)]):
        self.screen = screen
        self.screen_width = screen_width
        self.screen_height = screen_height
        self.font = pygame.font.Font(None, int(screen_height / 20))
        self.title = self.font.render(title, True, WHITE)
        self.options = options
        self.selected = 0
        self.clock = pygame.time.Clock()
        self.frame_count = 0

    def run(self):
        while True:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    raise SystemExit
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_UP:
                        self.selected = (self.selected - 1) % len(self.options)
                    elif event.key == pygame.K_DOWN:
                        self.selected = (self.selected + 1) % len(self.options)
                    elif event.key == pygame.K_RETURN:
                        return self.selected
                elif event.type == pygame.MOUSEMOTION:
                    mouse_pos = event.pos
                    for i, option in enumerate(self.options):
                        text = self.font.render(option, True, WHITE)
                        text_rect = text.get_rect(center=(self.screen_width // 2, self.screen_height // 2 + i * int(self.screen_height / 15)))
                        if text_rect.collidepoint(mouse_pos):
                            self.selected = i
                elif event.type == pygame.MOUSEBUTTONDOWN:
                    if event.button == 1:
                        return self.selected
            self.frame_count += 1
            self.draw()
            pygame.display.flip()
            self.clock.tick(60)

    def draw(self):
        self.screen.fill(BLACK)
        title_rect = self.title.get_rect(center=(self.screen_width // 2, self.screen_height // 4))
        self.screen.blit(self.title, title_rect)
        for i, option in enumerate(self.options):
            if i == self.selected:
                period = 120
                t = abs((self.frame_count % period) / (period / 2) - 1)
                color = (
                    int(WHITE[0] + (MAGENTA[0] - WHITE[0]) * t),
                    int(WHITE[1] + (MAGENTA[1] - WHITE[1]) * t),
                    int(WHITE[2] + (MAGENTA[2] - WHITE[2]) * t)
                )
            else:
                color = WHITE
            text = self.font.render(option, True, color)
            text_rect = text.get_rect(center=(self.screen_width // 2, self.screen_height // 2 + i * int(self.screen_height / 15)))
            self.screen.blit(text, text_rect)

class TitleMenu(Menu):
    def __init__(self, screen, screen_width, screen_height):
        super().__init__(screen, screen_width, screen_height, "Breakout", ["Start", "Level Select", "Quit"])

    def run(self):
        result = super().run()
        return 'start' if result == 0 else 'level_select' if result == 1 else 'quit' if result == 2 else None

class LevelSelectMenu(Menu):
    def __init__(self, screen, screen_width, screen_height):
        super().__init__(screen, screen_width, screen_height, "Select Level", [f"Level {i}" for i in range(1, 5)])

    def run(self):
        result = super().run()
        return result + 1 if result is not None else None

class PauseMenu(Menu):
    def __init__(self, screen, screen_width, screen_height):
        super().__init__(screen, screen_width, screen_height, "Paused", ["Resume", "Restart Level", "Level Select", "Quit"])

    def run(self):
        result = super().run()
        return 'resume' if result == 0 else 'restart' if result == 1 else 'level_select' if result == 2 else 'quit' if result == 3 else None

class Paddle:
    def __init__(self, y, width, height, screen_width):
        self.x = screen_width // 2 - width // 2
        self.y = y
        self.width = width
        self.height = height
        self.velocity = screen_width / 100
        self.default_width = width
        self.increased_width = width * 1.5
        self.is_expanded = False
        self.expand_hits = 0
        self.pulse_timer = 0
        self.pulse_scale = 1.0

    def move(self, direction, screen_width):
        self.x += self.velocity * (-1 if direction == "left" else 1)
        self.x = max(0, min(self.x, screen_width - self.width))

    def update(self):
        if self.pulse_timer > 0:
            self.pulse_timer -= 1
            self.pulse_scale = 1.0 + 0.2 * abs(math.sin(self.pulse_timer * math.pi / 10))
            if self.pulse_timer == 0:
                self.pulse_scale = 1.0

    def draw(self, screen, ripples):
        scaled_width = self.width * self.pulse_scale
        scaled_height = self.height * self.pulse_scale
        center_x = self.x + self.width / 2
        center_y = self.y + self.height / 2
        offset_x, offset_y = 0, 0
        for ripple in ripples:
            dx, dy = ripple.get_distortion_offset(center_x, center_y)
            offset_x += dx
            offset_y += dy
        scaled_x = self.x - (scaled_width - self.width) / 2 + offset_x
        scaled_y = self.y - (scaled_height - self.height) / 2 + offset_y
        pygame.draw.rect(screen, WHITE, (scaled_x, scaled_y, scaled_width, scaled_height))

class Ball:
    def __init__(self, paddle, speed, ball_radius, screen_width, screen_height, x=None, y=None):
        self.screen_width = screen_width
        self.screen_height = screen_height
        if x is None:
            self.x = paddle.x + paddle.width // 2
            self.y = paddle.y - ball_radius
            self.attached = True
        else:
            self.x = x
            self.y = y
            self.attached = False
        self.radius = ball_radius
        self.speed = speed
        self.default_speed = speed
        self.dx = 0
        self.dy = 0
        self.slow_timer = 0

    def launch(self):
        if self.attached == True:
            self.attached = False
            angle = random.uniform(-math.pi / 4, math.pi / 4)
            self.dx = self.speed * math.sin(angle)
            self.dy = -self.speed * math.cos(angle)

    def move(self):
        if not self.attached:
            self.x += self.dx
            self.y += self.dy

    def update(self):
        if self.slow_timer > 0:
            self.slow_timer -= 1
            if self.slow_timer == 0:
                magnitude = (self.dx**2 + self.dy**2)**0.5
                if magnitude != 0:
                    self.dx = self.dx / magnitude * self.default_speed
                    self.dy = self.dy / magnitude * self.default_speed
                self.speed = self.default_speed

    def check_collision(self, paddle, bricks, game):
        hit_bricks = []
        particles = []
        if self.attached:
            self.x = paddle.x + paddle.width // 2
            return hit_bricks, particles

        if self.x - self.radius < 0:
            self.x = self.radius
            self.dx = -self.dx
            angle = math.atan2(self.dy, self.dx)
            angle += random.uniform(-math.radians(3), math.radians(3))
            self.dx = self.speed * math.cos(angle)
            self.dy = self.speed * math.sin(angle)
            for _ in range(8):
                particles.append(Particle(self.x, self.y, WHITE))
        elif self.x + self.radius > self.screen_width:
            self.x = self.screen_width - self.radius
            self.dx = -self.dx
            angle = math.atan2(self.dy, self.dx)
            angle += random.uniform(-math.radians(3), math.radians(3))
            self.dx = self.speed * math.cos(angle)
            self.dy = self.speed * math.sin(angle)
            for _ in range(8):
                particles.append(Particle(self.x, self.y, WHITE))
        if self.y - self.radius < 0:
            self.y = self.radius
            self.dy = -self.dy
            angle = math.atan2(self.dy, self.dx)
            angle += random.uniform(-math.radians(3), math.radians(3))
            self.dx = self.speed * math.cos(angle)
            self.dy = self.speed * math.sin(angle)
            for _ in range(8):
                particles.append(Particle(self.x, self.y, WHITE))

        paddle_rect = pygame.Rect(paddle.x, paddle.y, paddle.width, paddle.height)
        ball_rect = pygame.Rect(self.x - self.radius, self.y - self.radius, self.radius * 2, self.radius * 2)
        if ball_rect.colliderect(paddle_rect):
            offset = (self.x - (paddle.x + paddle.width / 2)) / (paddle.width / 2)
            angle = offset * (math.pi / 4)
            self.dx = self.speed * math.sin(angle)
            self.dy = -self.speed * math.cos(angle)
            paddle.pulse_timer = 20
            if paddle.expand_hits > 0:
                paddle.expand_hits -= 1
                if paddle.expand_hits == 0:
                    paddle.is_expanded = False
                    paddle.width = paddle.default_width
            for _ in range(8):
                particles.append(Particle(self.x, paddle.y, WHITE))

        for brick in bricks:
            if not brick.broken and ball_rect.colliderect((brick.x, brick.y, brick.width, brick.height)):
                hit_bricks.append(brick)
                overlap_left = self.x + self.radius - brick.x
                overlap_right = brick.x + brick.width - (self.x - self.radius)
                overlap_top = self.y + self.radius - brick.y
                overlap_bottom = brick.y + brick.height - (self.y - self.radius)
                min_overlap = min(overlap_left, overlap_right, overlap_top, overlap_bottom)
                if min_overlap in (overlap_left, overlap_right):
                    self.dx = -self.dx
                    particle_x = brick.x if min_overlap == overlap_left else brick.x + brick.width
                    particle_y = self.y
                else:
                    self.dy = -self.dy
                    particle_x = self.x
                    particle_y = brick.y if min_overlap == overlap_top else brick.y + brick.height
                particle_color = POWER_UP_TYPES[brick.power_up_type]["saturated_color"] if brick.power_up_type else brick.color
                for _ in range(8):
                    particles.append(Particle(particle_x, particle_y, particle_color))

        return hit_bricks, particles

    def draw(self, screen, ripples, distortion_grid=None):
        offset_x, offset_y = 0, 0
        for ripple in ripples:
            dx, dy = ripple.get_distortion_offset(self.x, self.y)
            offset_x += dx
            offset_y += dy
        if distortion_grid:
            grid_x = int(self.x / 50) % len(distortion_grid)
            grid_y = int(self.y / 50) % len(distortion_grid[0])
            dx, dy = distortion_grid[grid_x][grid_y]
            offset_x += dx
            offset_y += dy
        pygame.draw.circle(screen, WHITE, (int(self.x + offset_x), int(self.y + offset_y)), self.radius)

class Brick:
    def __init__(self, x, y, width, height, hits, power_up_type=None):
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.hits = hits
        self.max_hits = hits
        if power_up_type:
            self.power_up_type = power_up_type
        elif random.random() < 0.03:  # Additional 3% chance for bombs
            self.power_up_type = "bomb"
        elif random.randint(1, 20) == 1:  # Existing 5% chance for random power-up
            self.power_up_type = random.choice(list(POWER_UP_TYPES.keys()))
        else:
            self.power_up_type = None
        if self.power_up_type:
            self.hits = 1
            self.max_hits = 1
        self.color = self.get_color()
        self.broken = False
        self.pulse_timer = 0
        self.pulse_scale = 1.0

    def get_color(self):
        if self.power_up_type:
            return None
        return BRICK_HIT_COLORS[min(self.hits - 1, len(BRICK_HIT_COLORS) - 1)]

    def hit(self):
        self.hits -= 1
        if self.hits <= 0:
            self.broken = True
        else:
            self.color = self.get_color()
            self.pulse_timer = 20

    def update(self):
        if self.pulse_timer > 0:
            self.pulse_timer -= 1
            self.pulse_scale = 1.0 + 0.2 * abs(math.sin(self.pulse_timer * math.pi / 10))
            if self.pulse_timer == 0:
                self.pulse_scale = 1.0

    def draw(self, screen, frame_count, ripples, distortion_grid=None):
        if not self.broken:
            if self.power_up_type:
                saturated_color = POWER_UP_TYPES[self.power_up_type]["saturated_color"]
                color = get_flashing_color(frame_count, saturated_color)
            else:
                color = self.color
            scaled_width = self.width * self.pulse_scale
            scaled_height = self.height * self.pulse_scale
            center_x = self.x + self.width / 2
            center_y = self.y + self.height / 2
            offset_x, offset_y = 0, 0
            for ripple in ripples:
                dx, dy = ripple.get_distortion_offset(center_x, center_y)
                offset_x += dx
                offset_y += dy
            if distortion_grid:
                grid_x = int(center_x / 50) % len(distortion_grid)
                grid_y = int(center_y / 50) % len(distortion_grid[0])
                dx, dy = distortion_grid[grid_x][grid_y]
                offset_x += dx
                offset_y += dy
            scaled_x = self.x - (scaled_width - self.width) / 2 + offset_x
            scaled_y = self.y - (scaled_height - self.height) / 2 + offset_y
            pygame.draw.rect(screen, color, (scaled_x, scaled_y, scaled_width, scaled_height))

class Particle:
    def __init__(self, x, y, color, bomb=False):
        self.x = x
        self.y = y        
        self.color = color if color is not None else YELLOW
        self.dx = random.uniform(-2, 2)
        self.dy = random.uniform(-2, 2)
        self.inner_color = WHITE  # Center color
        self.outer_color = CYAN   # Outer color
        self.radius = 5  # Particle radius
        self.bomb = bomb
        self.lifetime = 300 if bomb else 60
        self.max_lifetime = self.lifetime

    def update(self):
        self.x += self.dx
        self.y += self.dy
        self.lifetime -= 1
        
    def get_color(self, alpha):
        if not self.bomb:
            return self.color
        
        # Calculate the distance from the particle to the center of its explosion zone
        distance_to_center = (self.max_lifetime - self.lifetime) / self.max_lifetime
        # Set outer_weight to be higher when it is closer to the explosion center
        outer_weight = distance_to_center

        inner_weight = 1 - outer_weight
        
        color = (
            int(self.outer_color[0] * outer_weight + self.inner_color[0] * inner_weight),
            int(self.outer_color[1] * outer_weight + self.inner_color[1] * inner_weight),
            int(self.outer_color[2] * outer_weight + self.inner_color[2] * inner_weight)
        )

        return color
    
    def draw(self, screen, ripples, distortion_grid=None):
        if self.lifetime > 0:
            alpha = int(255 * (self.lifetime / self.max_lifetime))
            final_color = self.get_color(alpha)
            
            # Distortion effects
            offset_x, offset_y = 0, 0
            if ripples:
                for ripple in ripples:
                    dx, dy = ripple.get_distortion_offset(self.x, self.y)
                    offset_x += dx
                    offset_y += dy
            if distortion_grid:
                grid_x = int(self.x / 50) % len(distortion_grid)
                grid_y = int(self.y / 50) % len(distortion_grid[0])
                dx, dy = distortion_grid[grid_x][grid_y]
                offset_x += dx
                offset_y += dy
            surface = pygame.Surface((self.radius * 2, self.radius * 2), pygame.SRCALPHA)
            pygame.draw.circle(surface, (*final_color, alpha), (self.radius, self.radius), self.radius)
            screen.blit(surface, (int(self.x + offset_x - self.radius), int(self.y + offset_y - self.radius)))

class PowerUp:
    def __init__(self, x, y, power_type, screen_height):
        self.x = x
        self.y = y
        self.width = screen_height / 30
        self.height = screen_height / 30
        self.power_type = power_type
        self.velocity = screen_height / 300
        self.saturated_color = POWER_UP_TYPES[power_type]["saturated_color"]

    def move(self):
        self.y += self.velocity

    def draw(self, screen, frame_count, ripples, distortion_grid=None):
        color = get_flashing_color(frame_count, self.saturated_color)
        center_x = self.x + self.width / 2
        center_y = self.y + self.height / 2
        offset_x, offset_y = 0, 0
        for ripple in ripples:
            dx, dy = ripple.get_distortion_offset(center_x, center_y)
            offset_x += dx
            offset_y += dy
        if distortion_grid:
            grid_x = int(center_x / 50) % len(distortion_grid)
            grid_y = int(center_y / 50) % len(distortion_grid[0])
            dx, dy = distortion_grid[grid_x][grid_y]
            offset_x += dx
            offset_y += dy
        pygame.draw.rect(screen, color, (self.x + offset_x, self.y + offset_y, self.width, self.height))

    def apply_effect(self, paddle, balls, game):
        effect = POWER_UP_TYPES[self.power_type]["effect"]
        message = POWER_UP_TYPES[self.power_type]["message"]
        color = POWER_UP_TYPES[self.power_type]["saturated_color"]
        game.power_up_messages.append(PowerUpMessage(self.x + self.width / 2, self.y, message, color, game.screen_height))
        
        if effect == "slow_time":
            for ball in balls:
                if ball.slow_timer > 0:
                    ball.slow_timer += POWER_UP_TYPES[self.power_type]["duration_add"]
                else:
                    ball.speed *= 0.5
                    magnitude = (ball.dx**2 + ball.dy**2)**0.5
                    if magnitude != 0:
                        ball.dx = ball.dx / magnitude * ball.speed
                        ball.dy = ball.dy / magnitude * ball.speed
                    ball.slow_timer = POWER_UP_TYPES[self.power_type]["duration_add"]
                game.slow_time_active = max(game.slow_time_active, ball.slow_timer)
        elif effect == "extend_platform":
            paddle.expand_hits += POWER_UP_TYPES[self.power_type]["hits_add"]
            if not paddle.is_expanded:
                paddle.is_expanded = True
                paddle.width = paddle.increased_width
        elif effect == "extra_ball":
            new_x = random.uniform(game.margin, game.screen_width - game.margin)
            new_y = game.top_margin
            current_speed = balls[0].speed if balls else game.base_speed * game.speed_multiplier
            new_ball = Ball(paddle, current_speed, game.ball_radius, game.screen_width, game.screen_height, x=new_x, y=new_y)
            angle = random.uniform(math.pi / 4, 3 * math.pi / 4)
            new_ball.dx = new_ball.speed * math.cos(angle)
            new_ball.dy = new_ball.speed * math.sin(angle)
            new_ball.attached = False
            if balls and balls[0].slow_timer > 0:
                new_ball.speed *= 0.5
                magnitude = (new_ball.dx**2 + new_ball.dy**2)**0.5
                if magnitude != 0:
                    new_ball.dx = new_ball.dx / magnitude * new_ball.speed
                    new_ball.dy = new_ball.dy / magnitude * new_ball.speed
                new_ball.slow_timer = balls[0].slow_timer
            balls.append(new_ball)
        elif effect == "extra_life":
            game.lives += 1

class Game:
    def __init__(self, screen, screen_width, screen_height, level):
        self.screen = screen
        self.screen_width = screen_width
        self.screen_height = screen_height
        self.level = level
        self.clock = pygame.time.Clock()
        self.font = pygame.font.Font(None, int(screen_height / 20))
        self.frame_count = 0

        self.margin = screen_width / 20
        self.top_margin = screen_height / 10
        self.gap = screen_width / 200

        original_brick_columns = 13
        original_brick_width = (screen_width - 2 * self.margin - (original_brick_columns - 1) * self.gap) / original_brick_columns
        new_brick_width = 0.4 * original_brick_width
        new_columns = int((screen_width - 2 * self.margin + self.gap) // (new_brick_width + self.gap))
        self.brick_columns = new_columns
        self.brick_width = new_brick_width
        self.brick_height = new_brick_width / 3

        self.paddle_width = screen_width / 10
        self.paddle_height = screen_height / 60
        self.paddle_y = screen_height - screen_height / 20 - self.paddle_height
        self.ball_radius = self.paddle_height / 2

        self.paddle = Paddle(self.paddle_y, self.paddle_width, self.paddle_height, screen_width)
        self.base_speed = 3 * 1.5
        self.speed_multiplier = 1.5 * (1.05 ** (self.level - 1))
        self.balls = [Ball(self.paddle, self.base_speed * self.speed_multiplier, self.ball_radius, screen_width, screen_height)]
        self.bricks = self.create_bricks()
        self.power_ups = []
        self.power_up_messages = []
        self.particles = []
        self.score = 0
        self.lives = 3
        self.paused = False
        self.running = True
        self.slow_time_active = 0
        self.slow_time_particles = []
        self.time_ripples = []

    def create_bricks(self):
        random.seed(None)
        nx, ny = 10, 25
        noise_grid = [[random.uniform(0, 1) for _ in range(nx)] for _ in range(ny)]

        def get_noise_value(u, v):
            ix = min(int(u * (nx - 1)), nx - 2)
            iy = min(int(v * (ny - 1)), ny - 2)
            fx = u * (nx - 1) - ix
            fy = v * (ny - 1) - iy
            a = noise_grid[iy][ix]
            b = noise_grid[iy][ix + 1]
            c = noise_grid[iy + 1][ix]
            d = noise_grid[iy + 1][ix + 1]
            return (1 - fx) * (1 - fy) * a + fx * (1 - fy) * b + (1 - fx) * fy * c + fx * fy * d

        rows = min(10 + self.level * 2 + 5, 25)
        bricks = []
        for i in range(rows):
            for j in range(self.brick_columns):
                u = j / (self.brick_columns - 1)
                v = i / (rows - 1)
                if get_noise_value(u, v) > 0.5:
                    base_chance = random.random()
                    if self.level == 1:
                        if base_chance < 0.65: hits = 1
                        elif base_chance < 0.85: hits = 2
                        elif base_chance < 0.95: hits = 3
                        else: hits = 4
                    elif self.level == 2:
                        if base_chance < 0.45: hits = 1
                        elif base_chance < 0.70: hits = 2
                        elif base_chance < 0.90: hits = 3
                        else: hits = 4
                    elif self.level == 3:
                        if base_chance < 0.25: hits = 1
                        elif base_chance < 0.50: hits = 2
                        elif base_chance < 0.80: hits = 3
                        else: hits = 4
                    else:
                        if base_chance < 0.10: hits = 1
                        elif base_chance < 0.35: hits = 2
                        elif base_chance < 0.70: hits = 3
                        else: hits = 4
                    x = self.margin + j * (self.brick_width + self.gap)
                    y = self.top_margin + i * (self.brick_height + self.gap)
                    bricks.append(Brick(x, y, self.brick_width, self.brick_height, hits))
        return bricks

    def handle_events(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT: raise SystemExit
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_SPACE:
                    for ball in self.balls:
                        ball.launch()
                elif event.key in (pygame.K_p, pygame.K_ESCAPE): self.paused = True
        keys = pygame.key.get_pressed()
        if keys[pygame.K_LEFT]: self.paddle.move("left", self.screen_width)
        if keys[pygame.K_RIGHT]: self.paddle.move("right", self.screen_width)

    def update(self):
        self.frame_count += 1
        self.paddle.update()
        
        for brick in self.bricks:
            brick.update()
        
        if self.slow_time_active > 0:
            self.slow_time_active -= 1
            if random.random() < 0.3:
                x = random.uniform(0, self.screen_width)
                y = random.uniform(0, self.screen_height)
                self.slow_time_particles.append(Particle(x, y, BLUE))

        balls_to_remove = []
        for ball in self.balls[:]:
            ball.update()
            ball.move()
            hit_bricks, new_particles = ball.check_collision(self.paddle, self.bricks, self)
            self.particles.extend(new_particles)
            bombs_triggered = []
            for brick in hit_bricks:
                if brick.power_up_type == "bomb":
                    bombs_triggered.append(brick)
                    brick.broken = True
                    bomb_rect = pygame.Rect(brick.x - self.brick_width * 2, brick.y - self.brick_height * 2,
                                             self.brick_width * 6, self.brick_height * 6)
                    
                    for power_up in self.power_ups[:]:
                      if bomb_rect.colliderect((power_up.x, power_up.y, power_up.width, power_up.height)):
                        self.power_ups.remove(power_up)
                    
                    self.score += 10
                    self.time_ripples.append(TimeRipple(brick.x + brick.width / 2, brick.y + brick.height / 2, self.screen_width, self.screen_height, CYAN))
                    for surrounding_brick in [b for b in self.bricks if not b.broken and bomb_rect.colliderect((b.x, b.y, b.width, b.height))]:
                        if surrounding_brick.power_up_type is None:  # Only break bricks without power-ups
                            surrounding_brick.broken = True
                            for _ in range(40):
                                self.particles.append(Particle(surrounding_brick.x + surrounding_brick.width / 2,\
                                                            surrounding_brick.y + surrounding_brick.height / 2,
                                                            CYAN, bomb=True))
                    self.power_up_messages.append(PowerUpMessage(brick.x + brick.width / 2, brick.y, "+bomb", CYAN, self.screen_height))
                else:
                    brick.hit()
                    power_up_chance = random.random()
                    if not brick.broken and not brick.power_up_type and power_up_chance < 0.02:
                        brick.power_up_type = random.choice(list(POWER_UP_TYPES.keys()))
                        brick.hits = 1
                        brick.max_hits = 1
                    if brick.broken:
                        self.score += 10
                        if brick.power_up_type and brick.power_up_type != "bomb":
                            self.power_ups.append(PowerUp(brick.x + brick.width // 2, brick.y, brick.power_up_type, self.screen_height))
            
            if ball.y > self.screen_height:
                balls_to_remove.append(ball)
        
        for ball in balls_to_remove:
            if ball in self.balls:
                self.balls.remove(ball)
        
        if not self.balls:
            if self.lives > 0:
                self.lives -= 1
                new_ball = Ball(self.paddle, self.base_speed * self.speed_multiplier, self.ball_radius, self.screen_width, self.screen_height)
                self.balls.append(new_ball)
            else:
                self.running = False

        for power_up in self.power_ups[:]:
            power_up.move()
            if power_up.y > self.screen_height:
                self.power_ups.remove(power_up)
            elif pygame.Rect(power_up.x, power_up.y, power_up.width, power_up.height).colliderect((self.paddle.x, self.paddle.y, self.paddle.width, self.paddle.height)):
                power_up.apply_effect(self.paddle, self.balls, self)
                self.power_ups.remove(power_up)

        for message in self.power_up_messages[:]:
            message.update()
            if message.lifetime <= 0:
                self.power_up_messages.remove(message)

        for particle in self.particles[:]:
            particle.update()
            if particle.lifetime <= 0: self.particles.remove(particle)

        for particle in self.slow_time_particles[:]:
            particle.update()
            if particle.lifetime <= 0: self.slow_time_particles.remove(particle)

        for ripple in self.time_ripples[:]:
            ripple.update()
            if ripple.lifetime <= 0:
                self.time_ripples.remove(ripple)

        if all(brick.broken for brick in self.bricks):
            self.level += 1
            self.bricks = self.create_bricks()
            self.speed_multiplier = 1.5 * (1.05 ** (self.level - 1))
            self.balls = [Ball(self.paddle, self.base_speed * self.speed_multiplier, self.ball_radius, self.screen_width, self.screen_height)]
            self.paddle.width = self.paddle.default_width
            self.paddle.expand_hits = 0
            self.paddle.is_expanded = False

    def draw(self):
        distortion_grid = None
        if self.slow_time_active > 0:
            grid_size = 50
            grid_width = self.screen_width // grid_size + 1
            grid_height = self.screen_height // grid_size + 1
            distortion_grid = [[(0, 0) for _ in range(grid_height)] for _ in range(grid_width)]
            center_x = self.screen_width / 2
            center_y = self.screen_height / 2
            A1 = 10
            k1 = 0.02
            omega1 = 0.03
            A2 = 5
            k2 = 0.04
            omega2 = 0.05
            for i in range(grid_width):
                for j in range(grid_height):
                    x = i * grid_size
                    y = j * grid_size
                    dx = x - center_x
                    dy = y - center_y
                    d = math.sqrt(dx**2 + dy**2)
                    if d > 0:
                        offset = A1 * math.sin(k1 * d - omega1 * self.frame_count) + A2 * math.sin(k2 * d - omega2 * self.frame_count)
                        dx = offset * (dx / d)
                        dy = offset * (dy / d)
                    else:
                        dx = 0
                        dy = 0
                    distortion_grid[i][j] = (dx, dy)

        self.screen.fill(BLACK)
        if self.slow_time_active > 0:
            period = 120
            t = (self.frame_count % period) / period
            glow_alpha = int(150 + 75 * math.sin(t * 2 * math.pi))
            glow_surface = pygame.Surface((self.screen_width, self.screen_height), pygame.SRCALPHA)
            pygame.draw.rect(glow_surface, (*BLUE, glow_alpha), (0, 0, self.screen_width, self.screen_height))
            tint_surface = pygame.Surface((self.screen_width, self.screen_height), pygame.SRCALPHA)
            tint_surface.fill((*BLUE, int(30 + 20 * math.sin(t * 2 * math.pi))))
            self.screen.blit(tint_surface, (0, 0))        
        score_text = self.font.render(f"Score: {self.score}", True, WHITE)
        level_text = self.font.render(f"Level: {self.level}", True, WHITE)
        lives_text = self.font.render(f"Lives: {self.lives}", True, WHITE)
        score_x, score_y = self.margin, 10
        level_x, level_y = self.screen_width // 2 - level_text.get_width() // 2, 10
        lives_x, lives_y = self.screen_width - self.margin - lives_text.get_width(), 10
        for ripple in self.time_ripples:
            dx, dy = ripple.get_distortion_offset(score_x, score_y)
            score_x += dx
            score_y += dy
            dx, dy = ripple.get_distortion_offset(level_x, level_y)
            level_x += dx
            level_y += dy
            dx, dy = ripple.get_distortion_offset(lives_x, lives_y)
            lives_x += dx
            lives_y += dy
        if distortion_grid:
            grid_x = int(score_x / 50) % len(distortion_grid)
            grid_y = int(score_y / 50) % len(distortion_grid[0])
            dx, dy = distortion_grid[grid_x][grid_y]
            score_x += dx
            score_y += dy
            grid_x = int(level_x / 50) % len(distortion_grid)
            grid_y = int(level_y / 50) % len(distortion_grid[0])
            dx, dy = distortion_grid[grid_x][grid_y]
            level_x += dx
            level_y += dy
            grid_x = int(lives_x / 50) % len(distortion_grid)
            grid_y = int(lives_y / 50) % len(distortion_grid[0])
            dx, dy = distortion_grid[grid_x][grid_y]
            lives_x += dx
            lives_y += dy
        self.screen.blit(score_text, (score_x, score_y))
        self.screen.blit(score_text, (score_x, score_y))
        self.screen.blit(level_text, (level_x, level_y))
        self.screen.blit(lives_text, (lives_x, lives_y))
        
        for ripple in self.time_ripples:
            ripple.draw(self.screen)

        self.paddle.draw(self.screen, self.time_ripples)
        for ball in self.balls: 
            ball.draw(self.screen, self.time_ripples, distortion_grid)
        for brick in self.bricks:
            brick.draw(self.screen, self.frame_count, self.time_ripples, distortion_grid)
        for power_up in self.power_ups: 
            power_up.draw(self.screen, self.frame_count, self.time_ripples, distortion_grid)
        for particle in self.particles: 
            particle.draw(self.screen, self.time_ripples, distortion_grid)
        for particle in self.slow_time_particles: 
            particle.draw(self.screen, self.time_ripples, distortion_grid)
        for message in self.power_up_messages: 
            message.draw(self.screen)
        self.screen.blit(level_text, (level_x, level_y))
        self.screen.blit(lives_text, (lives_x, lives_y))
        pygame.display.flip()

    def run(self):
        while self.running:
            if self.paused:
                pause_menu = PauseMenu(self.screen, self.screen_width, self.screen_height)
                action = pause_menu.run()
                if action == 'resume':
                    for i in range(3, 0, -1):
                        self.draw()
                        countdown_text = self.font.render(f"Resuming in {i}...", True, WHITE)
                        countdown_rect = countdown_text.get_rect(center=(self.screen_width // 2, self.screen_height // 2))
                        padding = 20
                        bg_rect = countdown_rect.inflate(padding * 2, padding * 2)
                        pygame.draw.rect(self.screen, BLACK, bg_rect)
                        pygame.draw.rect(self.screen, WHITE, bg_rect, 2)
                        self.screen.blit(countdown_text, countdown_rect)
                        pygame.display.flip()
                        pygame.time.wait(1000)
                    self.paused = False
                elif action == 'restart':
                    return 'restart'
                elif action == 'level_select':
                    return 'level_select'
                elif action == 'quit':
                    return 'quit'
            else:
                self.handle_events()
                self.update()
                self.draw()
                self.clock.tick(60)
        return 'title' if self.lives <= 0 else None

def get_primary_monitor_resolution():
    display_sizes = pygame.display.get_desktop_sizes()
    if not display_sizes:
        return pygame.display.Info().current_w, pygame.display.Info().current_h
    max_area = 0
    primary_size = (0, 0)
    for size in display_sizes:
        area = size[0] * size[1]
        if area > max_area:
            max_area = area
            primary_size = size
    return primary_size

def main():
    primary_width, primary_height = get_primary_monitor_resolution()
    screen = pygame.display.set_mode((primary_width, primary_height), pygame.FULLSCREEN)
    pygame.display.set_caption("Breakout")
    clock = pygame.time.Clock()

    state = 'title'
    title_menu = TitleMenu(screen, primary_width, primary_height)
    level_select_menu = LevelSelectMenu(screen, primary_width, primary_height)
    game = None

    while True:
        if state == 'title':
            result = title_menu.run()
            if result == 'start':
                game = Game(screen, primary_width, primary_height, 1)
                state = 'playing'
            elif result == 'level_select':
                state = 'level_select'
            elif result == 'quit':
                break
        elif state == 'level_select':
            level = level_select_menu.run()
            if level:
                game = Game(screen, primary_width, primary_height, level)
                state = 'playing'
        elif state == 'playing':
            result = game.run()
            if result == 'title':
                state = 'title'
            elif result == 'level_select':
                state = 'level_select'
            elif result == 'restart':
                game = Game(screen, primary_width, primary_height, game.level)
            elif result == 'quit':
                break
        clock.tick(60)
    pygame.quit()

if __name__ == "__main__":
    main()
