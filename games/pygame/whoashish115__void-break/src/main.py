import pygame
import math
import random
import sys
import os
import json
from pygame.locals import *

pygame.init()
pygame.mixer.init()

info = pygame.display.Info()
SCREEN_WIDTH, SCREEN_HEIGHT = info.current_w, info.current_h
screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT), pygame.RESIZABLE)
pygame.display.set_caption("Void Break")

BACKGROUND = (5, 5, 10)
GRID_COLOR = (15, 15, 25)
UI_BG = (20, 20, 35, 220)
UI_ACCENT = (180, 180, 200)
UI_HIGHLIGHT = (120, 180, 255)
UI_SILVER = (160, 170, 190)
UI_DARK_SILVER = (80, 90, 110)
TEXT_COLOR = (220, 220, 240)

FPS = 60
PADDLE_WIDTH = SCREEN_WIDTH // 8
PADDLE_HEIGHT = SCREEN_HEIGHT // 40
PADDLE_Y = SCREEN_HEIGHT - SCREEN_HEIGHT // 10
BALL_RADIUS = SCREEN_WIDTH // 80
BRICK_WIDTH = SCREEN_WIDTH // 15
BRICK_HEIGHT = SCREEN_HEIGHT // 25
BRICK_ROWS = 8
BRICK_COLS = 13
MAX_LEVEL = 100

POWERUP_EXTRA_LIFE = 1
POWERUP_EXPAND_PADDLE = 2
POWERUP_MULTI_BALL = 3
POWERUP_LASER = 4
POWERUP_SLOW_BALL = 5
POWERUP_FAST_BALL = 6
POWERUP_SHIELD = 7
POWERUP_DAMAGE_BOOST = 8

STATE_MENU = 0
STATE_PLAYING = 1
STATE_GAME_OVER = 2
STATE_LEVEL_COMPLETE = 3
STATE_PAUSED = 4
STATE_HIGH_SCORES = 5
STATE_SETTINGS = 6

DIFFICULTY_EASY = 0
DIFFICULTY_NORMAL = 1
DIFFICULTY_HARD = 2
DIFFICULTY_EXPERT = 3

class Ball:
    def __init__(self, x, y, game):
        self.x = x
        self.y = y
        base_speed = 6 + (game.level - 1) * 0.05
        self.dx = random.choice([-base_speed, -base_speed*0.8, base_speed*0.8, base_speed])
        self.dy = -base_speed
        self.radius = BALL_RADIUS
        self.active = True
        self.stuck_to_paddle = True
        self.game = game
        self.damage = 1
        self.trail = []
        self.trail_length = 6
        self.color = (100, 150, 255)

    def move(self, paddle, bricks, powerups):
        if not self.active:
            return

        if self.stuck_to_paddle:
            self.x = paddle.x + paddle.width // 2
            self.y = paddle.y - self.radius - 5
            return

        self.x += self.dx
        self.y += self.dy

        self.trail.append((self.x, self.y))
        if len(self.trail) > self.trail_length:
            self.trail.pop(0)

        if self.x - self.radius < 0:
            self.x = self.radius
            self.dx *= -1
            self.game.play_sound("wall")
        elif self.x + self.radius > SCREEN_WIDTH:
            self.x = SCREEN_WIDTH - self.radius
            self.dx *= -1
            self.game.play_sound("wall")

        if self.y - self.radius < 0:
            self.y = self.radius
            self.dy *= -1
            self.game.play_sound("wall")

        paddle_rect = pygame.Rect(paddle.x, paddle.y, paddle.width, paddle.height)
        ball_rect = pygame.Rect(self.x - self.radius, self.y - self.radius, 
                               self.radius * 2, self.radius * 2)

        if ball_rect.colliderect(paddle_rect):
            relative_x = (self.x - (paddle.x + paddle.width/2)) / (paddle.width/2)
            angle = relative_x * 0.8
            speed = math.sqrt(self.dx**2 + self.dy**2)
            self.dx = speed * math.sin(angle)
            self.dy = -speed * math.cos(angle)
            self.y = paddle.y - self.radius - 1
            self.game.play_sound("paddle")

        if self.y - self.radius > SCREEN_HEIGHT:
            self.active = False
            self.game.lives -= 1
            self.game.play_sound("life_lost")
            return

        for brick in bricks:
            if not brick.destroyed:
                brick_rect = pygame.Rect(brick.x, brick.y, brick.width, brick.height)

                if ball_rect.colliderect(brick_rect):
                    overlap_left = self.x + self.radius - brick.x
                    overlap_right = brick.x + brick.width - (self.x - self.radius)
                    overlap_top = self.y + self.radius - brick.y
                    overlap_bottom = brick.y + brick.height - (self.y - self.radius)

                    min_overlap = min(overlap_left, overlap_right, overlap_top, overlap_bottom)

                    if min_overlap == overlap_left or min_overlap == overlap_right:
                        self.dx *= -1
                    else:
                        self.dy *= -1

                    brick.hit(self.damage)
                    self.game.score += brick.points
                    self.game.play_sound("brick_hit")
                    break

        for powerup in powerups:
            if not powerup.collected:
                powerup_rect = pygame.Rect(powerup.x, powerup.y, powerup.width, powerup.height)

                if ball_rect.colliderect(powerup_rect):
                    powerup.collect()
                    self.game.play_sound("powerup")
                    break

    def draw(self, surface):
        if not self.active:
            return

        for i, (trail_x, trail_y) in enumerate(self.trail):
            alpha = int(150 * i / len(self.trail))
            radius = int(self.radius * 0.7 * i / len(self.trail))
            trail_surf = pygame.Surface((radius*2, radius*2), pygame.SRCALPHA)
            pygame.draw.circle(trail_surf, (*self.color, alpha), (radius, radius), radius)
            surface.blit(trail_surf, (trail_x - radius, trail_y - radius))

        pygame.draw.circle(surface, self.color, (int(self.x), int(self.y)), self.radius)
        pygame.draw.circle(surface, UI_SILVER, (int(self.x), int(self.y)), self.radius, 2)

        if self.damage > 1:
            font = pygame.font.SysFont("Arial", 12, bold=True)
            dmg_text = font.render(f"{self.damage}x", True, (255, 100, 100))
            surface.blit(dmg_text, (int(self.x) - dmg_text.get_width()//2, 
                                  int(self.y) - dmg_text.get_height()//2))

class Paddle:
    def __init__(self, game):
        self.game = game
        self.width = PADDLE_WIDTH
        self.height = PADDLE_HEIGHT
        self.x = SCREEN_WIDTH // 2 - self.width // 2
        self.y = PADDLE_Y
        self.speed = SCREEN_WIDTH // 80
        self.laser_active = False
        self.laser_cooldown = 0
        self.expanded = False
        self.expanded_timer = 0
        self.original_width = PADDLE_WIDTH
        self.lasers = []
        self.shield_active = False
        self.shield_timer = 0
        self.damage_boost = 0
        self.damage_timer = 0
        self.color = (150, 100, 255)

    def move(self, direction):
        self.x += direction * self.speed
        if self.x < 0:
            self.x = 0
        if self.x > SCREEN_WIDTH - self.width:
            self.x = SCREEN_WIDTH - self.width

    def shoot_laser(self):
        if self.laser_active and self.laser_cooldown <= 0:
            positions = [self.x + 10, self.x + self.width - 14]
            for pos in positions:
                self.lasers.append(Laser(pos, self.y - 20, self.game))
            self.laser_cooldown = 8

    def update(self):
        if self.laser_active:
            self.laser_cooldown -= 1
            if self.laser_cooldown <= 0:
                self.laser_active = False

        if self.expanded:
            self.expanded_timer -= 1
            if self.expanded_timer <= 0:
                self.width = self.original_width
                self.expanded = False

        if self.shield_active:
            self.shield_timer -= 1
            if self.shield_timer <= 0:
                self.shield_active = False

        if self.damage_boost > 0:
            self.damage_timer -= 1
            if self.damage_timer <= 0:
                self.damage_boost = 0
                for ball in self.game.balls:
                    ball.damage = max(1, ball.damage - self.damage_boost)

        for laser in self.lasers[:]:
            laser.update()
            if not laser.active:
                self.lasers.remove(laser)

    def draw(self, surface):
        for i in range(self.height):
            color_factor = 1.0 - (i / self.height) * 0.3
            color = (
                int(self.color[0] * color_factor),
                int(self.color[1] * color_factor),
                int(self.color[2] * color_factor)
            )
            pygame.draw.line(surface, color, 
                            (self.x, self.y + i), 
                            (self.x + self.width, self.y + i))

        pygame.draw.rect(surface, UI_SILVER, (self.x, self.y, self.width, self.height), 2, 5)

        if self.laser_active:
            pygame.draw.rect(surface, (255, 100, 100), 
                            (self.x, self.y - 20, self.width, 5), border_radius=2)

        if self.shield_active:
            shield_radius = self.width // 2
            shield_surf = pygame.Surface((shield_radius*2, shield_radius*2), pygame.SRCALPHA)
            pygame.draw.circle(shield_surf, (100, 200, 255, 100), 
                              (shield_radius, shield_radius), shield_radius, 4)
            surface.blit(shield_surf, (self.x + self.width//2 - shield_radius, 
                                     self.y - shield_radius))

        for laser in self.lasers:
            laser.draw(surface)

class Brick:
    def __init__(self, x, y, brick_type, level, game):
        self.x = x
        self.y = y
        self.width = BRICK_WIDTH
        self.height = BRICK_HEIGHT
        self.destroyed = False
        self.brick_type = brick_type
        self.level = level
        self.game = game
        self.enemy = False
        self.shoot_cooldown = 0
        self.attack_speed = max(20, 150 - level * 0.5)

        base_health = brick_type
        level_multiplier = 1 + (level - 1) * 0.2
        self.max_health = max(1, int(base_health * level_multiplier))
        self.health = self.max_health

        if brick_type >= 5 and random.random() < min(0.3 + level * 0.01, 0.8):
            self.enemy = True
            self.max_health = max(2, int(self.max_health * 1.5))
            self.health = self.max_health

        self.points = 10 * brick_type * (1 + level * 0.1)
        hue = random.random()
        if hue < 0.16: self.color = (255, 100, 100)
        elif hue < 0.33: self.color = (100, 255, 100)
        elif hue < 0.5: self.color = (100, 100, 255)
        elif hue < 0.66: self.color = (255, 255, 100)
        elif hue < 0.83: self.color = (255, 100, 255)
        else: self.color = (100, 255, 255)

    def hit(self, damage):
        self.health -= damage
        if self.health <= 0:
            self.destroyed = True
            drop_chance = 0.1 + min(self.level * 0.005, 0.3)
            if random.random() < drop_chance:
                self.game.spawn_powerup(self.x + self.width // 2, self.y + self.height // 2)

    def update(self):
        if self.enemy and not self.destroyed:
            self.shoot_cooldown -= 1
            if self.shoot_cooldown <= 0:
                if random.random() < 0.7:
                    self.game.enemy_projectiles.append(
                        EnemyProjectile(
                            self.x + self.width // 2,
                            self.y + self.height,
                            self.game.paddle.x + self.game.paddle.width // 2,
                            self.game.paddle.y,
                            self.game
                        )
                    )
                self.shoot_cooldown = self.attack_speed

    def draw(self, surface):
        if self.destroyed:
            return

        health_ratio = self.health / self.max_health
        intensity = 0.3 + 0.7 * health_ratio
        display_color = (
            int(self.color[0] * intensity),
            int(self.color[1] * intensity),
            int(self.color[2] * intensity)
        )

        pygame.draw.rect(surface, display_color, (self.x, self.y, self.width, self.height), border_radius=3)

        border_color = (
            max(display_color[0] - 40, 0),
            max(display_color[1] - 40, 0),
            max(display_color[2] - 40, 0)
        )
        pygame.draw.rect(surface, border_color, (self.x, self.y, self.width, self.height), 2, border_radius=3)

        if self.max_health > 1:
            bar_width = self.width - 10
            bar_height = 4
            bar_x = self.x + 5
            bar_y = self.y + self.height - 8

            pygame.draw.rect(surface, (50, 50, 50), (bar_x, bar_y, bar_width, bar_height))
            health_width = int(bar_width * health_ratio)
            health_color = (
                int(255 * (1 - health_ratio)),
                int(255 * health_ratio),
                50
            )
            pygame.draw.rect(surface, health_color, (bar_x, bar_y, health_width, bar_height))

        if self.enemy:
            pygame.draw.circle(surface, (255, 50, 50), 
                              (self.x + self.width // 2, self.y + 8), 3)
            pygame.draw.circle(surface, (255, 150, 150), 
                              (self.x + self.width // 2, self.y + 8), 3, 1)

class EnemyProjectile:
    def __init__(self, x, y, target_x, target_y, game):
        self.x = x
        self.y = y
        self.radius = 4
        self.speed = 5
        self.active = True
        self.game = game
        self.color = (255, 80, 80)

        dx = target_x - x + random.uniform(-20, 20)
        dy = target_y - y + random.uniform(-10, 10)
        dist = max(1, math.sqrt(dx*dx + dy*dy))
        self.dx = dx / dist * self.speed
        self.dy = dy / dist * self.speed

    def update(self):
        self.x += self.dx
        self.y += self.dy
        if self.y > SCREEN_HEIGHT or self.x < 0 or self.x > SCREEN_WIDTH:
            self.active = False

    def draw(self, surface):
        pygame.draw.circle(surface, self.color, (int(self.x), int(self.y)), self.radius)
        pygame.draw.circle(surface, (255, 150, 150), (int(self.x), int(self.y)), self.radius, 1)

class PowerUp:
    def __init__(self, x, y, game):
        self.x = x
        self.y = y
        self.width = 30
        self.height = 15
        self.speed = 4
        self.collected = False
        self.game = game
        self.pulse = 0
        self.pulse_dir = 1

        power_weights = {
            POWERUP_EXTRA_LIFE: 8,
            POWERUP_EXPAND_PADDLE: 12,
            POWERUP_MULTI_BALL: 10,
            POWERUP_LASER: 8,
            POWERUP_SLOW_BALL: 6,
            POWERUP_FAST_BALL: 6,
            POWERUP_SHIELD: 5,
            POWERUP_DAMAGE_BOOST: 5
        }

        self.power_type = random.choices(
            list(power_weights.keys()), 
            weights=list(power_weights.values())
        )[0]

        if self.power_type == POWERUP_EXTRA_LIFE:
            self.color = (255, 100, 100)
            self.text = "+1"
        elif self.power_type == POWERUP_EXPAND_PADDLE:
            self.color = (100, 255, 100)
            self.text = "++"
        elif self.power_type == POWERUP_MULTI_BALL:
            self.color = (100, 100, 255)
            self.text = "MB"
        elif self.power_type == POWERUP_LASER:
            self.color = (255, 100, 255)
            self.text = "LZ"
        elif self.power_type == POWERUP_SLOW_BALL:
            self.color = (150, 150, 255)
            self.text = "SL"
        elif self.power_type == POWERUP_FAST_BALL:
            self.color = (255, 255, 100)
            self.text = "SP"
        elif self.power_type == POWERUP_SHIELD:
            self.color = (100, 200, 255)
            self.text = "SH"
        elif self.power_type == POWERUP_DAMAGE_BOOST:
            self.color = (255, 150, 100)
            self.text = "DM"

    def move(self):
        self.y += self.speed
        if self.y > SCREEN_HEIGHT:
            self.collected = True

    def update(self):
        self.pulse += 0.1 * self.pulse_dir
        if self.pulse > 5:
            self.pulse_dir = -1
        elif self.pulse < 0:
            self.pulse_dir = 1

    def collect(self):
        self.collected = True

        if self.power_type == POWERUP_EXTRA_LIFE:
            self.game.lives += 1
        elif self.power_type == POWERUP_EXPAND_PADDLE:
            self.game.paddle.expanded = True
            self.game.paddle.expanded_timer = 600
            self.game.paddle.width = min(self.game.paddle.original_width + 50, SCREEN_WIDTH // 5)
        elif self.power_type == POWERUP_MULTI_BALL:
            for _ in range(2):
                new_ball = Ball(self.game.paddle.x + self.game.paddle.width // 2, 
                               self.game.paddle.y - 20, self.game)
                new_ball.stuck_to_paddle = True
                self.game.balls.append(new_ball)
        elif self.power_type == POWERUP_LASER:
            self.game.paddle.laser_active = True
            self.game.paddle.laser_cooldown = 300
        elif self.power_type == POWERUP_SLOW_BALL:
            for ball in self.game.balls:
                ball.dx *= 0.7
                ball.dy *= 0.7
        elif self.power_type == POWERUP_FAST_BALL:
            for ball in self.game.balls:
                ball.dx *= 1.3
                ball.dy *= 1.3
        elif self.power_type == POWERUP_SHIELD:
            self.game.paddle.shield_active = True
            self.game.paddle.shield_timer = 450
        elif self.power_type == POWERUP_DAMAGE_BOOST:
            self.game.paddle.damage_boost += 1
            self.game.paddle.damage_timer = 600
            for ball in self.game.balls:
                ball.damage += 1

    def draw(self, surface):
        if self.collected:
            return

        if self.pulse > 0:
            glow_surf = pygame.Surface((self.width + self.pulse*2, self.height + self.pulse*2), pygame.SRCALPHA)
            pygame.draw.rect(glow_surf, (*self.color, 50), 
                            (0, 0, self.width + self.pulse*2, self.height + self.pulse*2), 
                            border_radius=8)
            surface.blit(glow_surf, (self.x - self.pulse, self.y - self.pulse))

        pygame.draw.rect(surface, self.color, (self.x, self.y, self.width, self.height), 0, 5)
        pygame.draw.rect(surface, UI_SILVER, (self.x, self.y, self.width, self.height), 2, 5)

        font = pygame.font.SysFont("Arial", 14, bold=True)
        text = font.render(self.text, True, (255, 255, 255))
        text_rect = text.get_rect(center=(self.x + self.width//2, self.y + self.height//2))
        surface.blit(text, text_rect)

class Laser:
    def __init__(self, x, y, game):
        self.x = x
        self.y = y
        self.width = 4
        self.height = 20
        self.speed = 15
        self.active = True
        self.game = game

    def update(self):
        self.y -= self.speed
        if self.y < 0:
            self.active = False

        for brick in self.game.bricks:
            if not brick.destroyed:
                brick_rect = pygame.Rect(brick.x, brick.y, brick.width, brick.height)
                laser_rect = pygame.Rect(self.x, self.y, self.width, self.height)
                if brick_rect.colliderect(laser_rect):
                    brick.hit(2)
                    self.active = False
                    break

    def draw(self, surface):
        pygame.draw.rect(surface, (255, 100, 100), (self.x, self.y, self.width, self.height))
        pygame.draw.rect(surface, (255, 200, 200), (self.x, self.y, self.width, self.height//2))

class Game:
    def __init__(self):
        self.load_sounds()
        self.level = 1
        self.max_level = MAX_LEVEL
        self.state = STATE_MENU
        self.menu_option = 0
        self.font_large = pygame.font.SysFont("Arial", 48, bold=True)
        self.font_medium = pygame.font.SysFont("Arial", 32)
        self.font_small = pygame.font.SysFont("Arial", 24)
        self.font_tiny = pygame.font.SysFont("Arial", 16)
        self.high_score = 0
        self.high_scores = []
        self.load_high_scores()
        self.settings = {
            "sound_volume": 0.5,
            "difficulty": DIFFICULTY_NORMAL
        }
        self.reset()

    def reset(self):
        self.paddle = Paddle(self)
        self.balls = [Ball(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2, self)]
        self.bricks = []
        self.powerups = []
        self.enemy_projectiles = []
        self.lives = 3
        self.score = 0
        self.level_complete = False
        self.create_level(self.level)

    def load_sounds(self):
        self.sounds = {}
        try:
            self.sounds["brick_hit"] = pygame.mixer.Sound(buffer=bytes([0] * 100))
            self.sounds["paddle"] = pygame.mixer.Sound(buffer=bytes([0] * 100))
            self.sounds["powerup"] = pygame.mixer.Sound(buffer=bytes([0] * 100))
            self.sounds["life_lost"] = pygame.mixer.Sound(buffer=bytes([0] * 100))
            self.sounds["wall"] = pygame.mixer.Sound(buffer=bytes([0] * 100))
            self.sounds["level_complete"] = pygame.mixer.Sound(buffer=bytes([0] * 100))
        except:
            pass

    def play_sound(self, sound_name):
        if sound_name in self.sounds and self.settings["sound_volume"] > 0:
            self.sounds[sound_name].set_volume(self.settings["sound_volume"])
            self.sounds[sound_name].play()

    def spawn_powerup(self, x, y):
        self.powerups.append(PowerUp(x, y, self))

    def create_level(self, level):
        self.bricks = []
        self.powerups = []
        self.enemy_projectiles = []

        enemy_chance = min(0.1 + (level - 1) * 0.02, 0.5)

        pattern_type = level % 8
        if level <= 10:
            pattern_type = level % 4
        elif level <= 30:
            pattern_type = 4 + (level % 3)
        else:
            pattern_type = 7 + (level % 3)

        self.create_pattern(pattern_type, level, enemy_chance)

    def create_pattern(self, pattern_type, level, enemy_chance):
        if pattern_type == 0:
            for row in range(4 + min(level // 3, 4)):
                for col in range(BRICK_COLS):
                    brick_type = 1 + min((row + level) // 2, 3)
                    if random.random() < enemy_chance:
                        brick_type = max(5, brick_type)
                    x = col * (BRICK_WIDTH + 5) + 50
                    y = row * (BRICK_HEIGHT + 5) + 100
                    self.bricks.append(Brick(x, y, brick_type, level, self))

        elif pattern_type == 1:
            for row in range(5 + min(level // 2, 3)):
                for col in range(BRICK_COLS):
                    if (row + col) % 2 == 0:
                        brick_type = 1 + min(level // 3, 3)
                        if random.random() < enemy_chance:
                            brick_type = max(5, brick_type)
                        x = col * (BRICK_WIDTH + 5) + 50
                        y = row * (BRICK_HEIGHT + 5) + 100
                        self.bricks.append(Brick(x, y, brick_type, level, self))

        elif pattern_type == 2:
            rows = 5 + min(level // 2, 3)
            for row in range(rows):
                for col in range(BRICK_COLS - row):
                    brick_type = 1 + min((row + level) // 2, 4)
                    if random.random() < enemy_chance:
                        brick_type = max(5, brick_type)
                    x = (col + row/2) * (BRICK_WIDTH + 5) + 50
                    y = row * (BRICK_HEIGHT + 5) + 100
                    self.bricks.append(Brick(x, y, brick_type, level, self))

        elif pattern_type == 3:
            for row in range(6):
                for col in range(BRICK_COLS):
                    if col < 3 or col > BRICK_COLS - 4 or (2 < col < BRICK_COLS - 3 and row < 2):
                        brick_type = 2 + min(level // 2, 3)
                        if random.random() < enemy_chance:
                            brick_type = max(5, brick_type)
                        x = col * (BRICK_WIDTH + 5) + 50
                        y = row * (BRICK_HEIGHT + 5) + 100
                        self.bricks.append(Brick(x, y, brick_type, level, self))

        elif pattern_type == 4:
            for row in range(6):
                for col in range(BRICK_COLS):
                    if (row == 2 or row == 3 or col == 5 or col == 6 or 
                        (row in [1,4] and col in [4,7])):
                        brick_type = 2 + min(level // 2, 4)
                        if random.random() < enemy_chance:
                            brick_type = max(5, brick_type)
                        x = col * (BRICK_WIDTH + 5) + 50
                        y = row * (BRICK_HEIGHT + 5) + 100
                        self.bricks.append(Brick(x, y, brick_type, level, self))

        elif pattern_type == 5:
            center_x, center_y = SCREEN_WIDTH // 2, 200
            for i in range(30 + level * 2):
                angle = i * 0.3
                radius = 50 + i * 4
                x = center_x + radius * math.cos(angle)
                y = center_y + radius * math.sin(angle)
                brick_type = 1 + min(i // 8, 4)
                if random.random() < enemy_chance:
                    brick_type = max(5, brick_type)
                self.bricks.append(Brick(x, y, brick_type, level, self))

        elif pattern_type == 6:
            for cluster in range(5 + level // 3):
                cluster_x = random.randint(100, SCREEN_WIDTH - 100)
                cluster_y = random.randint(100, 400)
                for i in range(8 + level // 2):
                    x = cluster_x + random.randint(-60, 60)
                    y = cluster_y + random.randint(-30, 30)
                    if 50 < x < SCREEN_WIDTH - 50 and 100 < y < 500:
                        brick_type = 2 + min(level // 3, 4)
                        if random.random() < enemy_chance * 1.5:
                            brick_type = max(5, brick_type)
                        self.bricks.append(Brick(x, y, brick_type, level, self))

        elif pattern_type >= 7:
            for row in range(6 + min(level // 5, 4)):
                for col in range(BRICK_COLS):
                    if (row * col + level) % (3 + level // 10) == 0:
                        brick_type = 2 + min((row + col + level) // 3, 5)
                        if random.random() < enemy_chance:
                            brick_type = max(5, brick_type)
                        x = col * (BRICK_WIDTH + 5) + 50
                        y = row * (BRICK_HEIGHT + 5) + 100
                        self.bricks.append(Brick(x, y, brick_type, level, self))

    def load_high_scores(self):
        try:
            if os.path.exists("highscores.json"):
                with open("highscores.json", "r") as f:
                    self.high_scores = json.load(f)
                    self.high_scores.sort(key=lambda x: x["score"], reverse=True)
                    self.high_scores = self.high_scores[:10]
                    if self.high_scores:
                        self.high_score = self.high_scores[0]["score"]
        except:
            self.high_scores = []

    def save_high_score(self):
        if self.score > 0:
            self.high_scores.append({
                "name": "Player",
                "score": self.score,
                "level": self.level
            })
            self.high_scores.sort(key=lambda x: x["score"], reverse=True)
            self.high_scores = self.high_scores[:10]
            if self.high_scores:
                self.high_score = self.high_scores[0]["score"]
            try:
                with open("highscores.json", "w") as f:
                    json.dump(self.high_scores, f)
            except:
                pass

    def draw_static_background(self, surface):
        surface.fill(BACKGROUND)

        grid_size = 50
        for x in range(0, SCREEN_WIDTH, grid_size):
            pygame.draw.line(surface, GRID_COLOR, (x, 0), (x, SCREEN_HEIGHT), 1)
        for y in range(0, SCREEN_HEIGHT, grid_size):
            pygame.draw.line(surface, GRID_COLOR, (0, y), (SCREEN_WIDTH, y), 1)

    def draw_menu(self, surface):
        self.draw_static_background(surface)

        title = self.font_large.render("VOID BREAK", True, UI_SILVER)
        title_rect = title.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT//4))

        for i in range(3, 0, -1):
            glow_surf = pygame.Surface((title.get_width() + i*8, title.get_height() + i*8), pygame.SRCALPHA)
            pygame.draw.rect(glow_surf, (*UI_SILVER, 20), 
                            (0, 0, title.get_width() + i*8, title.get_height() + i*8), 
                            border_radius=10)
            surface.blit(glow_surf, (title_rect.x - i*4, title_rect.y - i*4))

        surface.blit(title, title_rect)

        options = ["START GAME", "HIGH SCORES", "SETTINGS", "QUIT"]
        self.menu_rects = []

        for i, option in enumerate(options):
            color = UI_HIGHLIGHT if i == self.menu_option else UI_ACCENT
            text = self.font_medium.render(option, True, color)
            text_rect = text.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT//2 + i * 70))
            self.menu_rects.append(text_rect)

            if i == self.menu_option:
                pygame.draw.circle(surface, UI_HIGHLIGHT, (text_rect.left - 30, text_rect.centery), 8)

            surface.blit(text, text_rect)

        high_score_text = self.font_small.render(f"High Score: {self.high_score}", True, UI_SILVER)
        high_score_rect = high_score_text.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT - 80))
        surface.blit(high_score_text, high_score_rect)

        level_text = self.font_small.render(f"Levels: 1-{MAX_LEVEL}", True, UI_ACCENT)
        level_rect = level_text.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT - 40))
        surface.blit(level_text, level_rect)

    def draw_game_over(self, surface):
        self.draw_static_background(surface)

        game_over = self.font_large.render("GAME OVER", True, (255, 100, 100))
        game_over_rect = game_over.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT//3))
        surface.blit(game_over, game_over_rect)

        score_text = self.font_medium.render(f"FINAL SCORE: {self.score}", True, TEXT_COLOR)
        score_rect = score_text.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT//2))
        surface.blit(score_text, score_rect)

        level_text = self.font_medium.render(f"LEVEL REACHED: {self.level}", True, UI_SILVER)
        level_rect = level_text.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT//2 + 40))
        surface.blit(level_text, level_rect)

        high_score_text = self.font_medium.render(f"HIGH SCORE: {self.high_score}", True, UI_SILVER)
        high_score_rect = high_score_text.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT//2 + 80))
        surface.blit(high_score_text, high_score_rect)

        options = ["PLAY AGAIN", "MAIN MENU"]
        self.menu_rects = []

        for i, option in enumerate(options):
            color = UI_HIGHLIGHT if i == self.menu_option else UI_ACCENT
            text = self.font_medium.render(option, True, color)
            text_rect = text.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT//2 + 150 + i * 70))
            self.menu_rects.append(text_rect)

            if i == self.menu_option:
                pygame.draw.circle(surface, UI_HIGHLIGHT, (text_rect.left - 30, text_rect.centery), 8)

            surface.blit(text, text_rect)

    def draw_level_complete(self, surface):
        self.draw_static_background(surface)

        complete = self.font_large.render(f"LEVEL {self.level} COMPLETE!", True, UI_HIGHLIGHT)
        complete_rect = complete.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT//3))
        surface.blit(complete, complete_rect)

        score_text = self.font_medium.render(f"SCORE: {self.score}", True, TEXT_COLOR)
        score_rect = score_text.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT//2))
        surface.blit(score_text, score_rect)

        next_level = min(self.level + 1, self.max_level)
        next_text = self.font_medium.render(f"Next: Level {next_level}", True, UI_SILVER)
        next_rect = next_text.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT//2 + 40))
        surface.blit(next_text, next_rect)

        if self.level < self.max_level:
            options = ["NEXT LEVEL", "MAIN MENU"]
        else:
            options = ["YOU WIN! PLAY AGAIN", "MAIN MENU"]

        self.menu_rects = []
        for i, option in enumerate(options):
            color = UI_HIGHLIGHT if i == self.menu_option else UI_ACCENT
            text = self.font_medium.render(option, True, color)
            text_rect = text.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT//2 + 150 + i * 70))
            self.menu_rects.append(text_rect)

            if i == self.menu_option:
                pygame.draw.circle(surface, UI_HIGHLIGHT, (text_rect.left - 30, text_rect.centery), 8)

            surface.blit(text, text_rect)

    def draw_pause_screen(self, surface):
        overlay = pygame.Surface((SCREEN_WIDTH, SCREEN_HEIGHT), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 180))
        surface.blit(overlay, (0, 0))

        panel_width = SCREEN_WIDTH // 2
        panel_height = SCREEN_HEIGHT // 3
        panel_x = SCREEN_WIDTH // 2 - panel_width // 2
        panel_y = SCREEN_HEIGHT // 2 - panel_height // 2

        pygame.draw.rect(surface, UI_BG, (panel_x, panel_y, panel_width, panel_height), border_radius=15)
        pygame.draw.rect(surface, UI_SILVER, (panel_x, panel_y, panel_width, panel_height), 3, border_radius=15)

        pause_text = self.font_large.render("GAME PAUSED", True, UI_SILVER)
        pause_rect = pause_text.get_rect(center=(SCREEN_WIDTH//2, panel_y + panel_height//4))
        surface.blit(pause_text, pause_rect)

        instructions = [
            "Press P to resume",
            "Press ESC for menu",
            f"Level: {self.level}",
            f"Score: {self.score}"
        ]

        for i, line in enumerate(instructions):
            text = self.font_medium.render(line, True, UI_ACCENT)
            text_rect = text.get_rect(center=(SCREEN_WIDTH//2, panel_y + panel_height//2 + i * 40))
            surface.blit(text, text_rect)

    def draw_high_scores(self, surface):
        self.draw_static_background(surface)

        title = self.font_large.render("HIGH SCORES", True, UI_SILVER)
        title_rect = title.get_rect(center=(SCREEN_WIDTH//2, 80))
        surface.blit(title, title_rect)

        panel_width = SCREEN_WIDTH // 2
        panel_height = SCREEN_HEIGHT // 1.5
        panel_x = SCREEN_WIDTH // 2 - panel_width // 2
        panel_y = 120

        pygame.draw.rect(surface, UI_BG, (panel_x, panel_y, panel_width, panel_height), border_radius=15)
        pygame.draw.rect(surface, UI_SILVER, (panel_x, panel_y, panel_width, panel_height), 3, border_radius=15)

        headers = ["RANK", "SCORE", "LEVEL"]
        for i, header in enumerate(headers):
            text = self.font_medium.render(header, True, UI_SILVER)
            x_pos = panel_x + (i + 1) * (panel_width // 4)
            surface.blit(text, (x_pos - text.get_width()//2, panel_y + 20))

        if not self.high_scores:
            no_scores = self.font_medium.render("No high scores yet!", True, UI_ACCENT)
            surface.blit(no_scores, (SCREEN_WIDTH//2 - no_scores.get_width()//2, SCREEN_HEIGHT//2))
        else:
            for i, score in enumerate(self.high_scores[:10]):
                y_pos = panel_y + 80 + i * 45

                rank_text = self.font_small.render(f"{i+1}.", True, UI_SILVER)
                surface.blit(rank_text, (panel_x + panel_width//4 - rank_text.get_width()//2, y_pos))

                score_text = self.font_small.render(str(score["score"]), True, UI_ACCENT)
                surface.blit(score_text, (panel_x + 2*panel_width//4 - score_text.get_width()//2, y_pos))

                level_text = self.font_small.render(str(score.get("level", 1)), True, UI_ACCENT)
                surface.blit(level_text, (panel_x + 3*panel_width//4 - level_text.get_width()//2, y_pos))

        back_text = self.font_medium.render("Click anywhere or press ESC to return", True, UI_ACCENT)
        back_rect = back_text.get_rect(center=(SCREEN_WIDTH//2, SCREEN_HEIGHT - 60))
        surface.blit(back_text, back_rect)

    def draw_settings(self, surface):
        self.draw_static_background(surface)

        title = self.font_large.render("SETTINGS", True, UI_SILVER)
        title_rect = title.get_rect(center=(SCREEN_WIDTH//2, 80))
        surface.blit(title, title_rect)

        panel_width = SCREEN_WIDTH // 2
        panel_height = SCREEN_HEIGHT // 2
        panel_x = SCREEN_WIDTH // 2 - panel_width // 2
        panel_y = 120

        pygame.draw.rect(surface, UI_BG, (panel_x, panel_y, panel_width, panel_height), border_radius=15)
        pygame.draw.rect(surface, UI_SILVER, (panel_x, panel_y, panel_width, panel_height), 3, border_radius=15)

        difficulty_names = ["Easy", "Normal", "Hard", "Expert"]
        settings = [
            f"Sound Volume: {int(self.settings['sound_volume'] * 100)}%",
            f"Difficulty: {difficulty_names[self.settings['difficulty']]}"
        ]

        self.menu_rects = []
        for i, setting in enumerate(settings):
            y_pos = panel_y + panel_height//4 + i * 80

            if i == self.menu_option:
                pygame.draw.rect(surface, (60, 60, 70), 
                                (panel_x + 20, y_pos - 10, panel_width - 40, 50), border_radius=10)
                pygame.draw.rect(surface, UI_HIGHLIGHT, 
                                (panel_x + 20, y_pos - 10, panel_width - 40, 50), 2, border_radius=10)

            text = self.font_medium.render(setting, True, UI_ACCENT)
            text_rect = text.get_rect(center=(SCREEN_WIDTH//2, y_pos +15))
            self.menu_rects.append(text_rect)
            surface.blit(text, text_rect)

        back_text = self.font_medium.render("Click anywhere or press ESC to return", True, UI_ACCENT)
        back_rect = back_text.get_rect(center=(SCREEN_WIDTH//2, panel_y + panel_height - 30))
        surface.blit(back_text, back_rect)

    def draw_hud(self, surface):
        hud_height = 80
        hud_surf = pygame.Surface((SCREEN_WIDTH, hud_height), pygame.SRCALPHA)

        for i in range(hud_height):
            alpha = 200 - int(100 * (i / hud_height))
            pygame.draw.line(hud_surf, (*UI_BG[:3], alpha), (0, i), (SCREEN_WIDTH, i))

        surface.blit(hud_surf, (0, 0))
        pygame.draw.line(surface, UI_SILVER, (0, hud_height), (SCREEN_WIDTH, hud_height), 2)

        score_text = self.font_small.render(f"SCORE: {self.score}", True, UI_SILVER)
        surface.blit(score_text, (20, 15))

        high_score_text = self.font_small.render(f"HIGH: {self.high_score}", True, UI_SILVER)
        surface.blit(high_score_text, (20, 45))

        lives_text = self.font_small.render(f"LIVES: {self.lives}", True, UI_SILVER)
        surface.blit(lives_text, (SCREEN_WIDTH - lives_text.get_width() - 20, 15))

        level_text = self.font_small.render(f"LEVEL: {self.level}/{self.max_level}", True, UI_SILVER)
        surface.blit(level_text, (SCREEN_WIDTH - level_text.get_width() - 20, 45))

        indicators = []
        if self.paddle.laser_active:
            indicators.append(("LASER", (255, 100, 100)))
        if self.paddle.expanded:
            indicators.append(("EXPAND", (100, 255, 100)))
        if self.paddle.shield_active:
            indicators.append(("SHIELD", (100, 200, 255)))
        if self.paddle.damage_boost > 0:
            indicators.append((f"DMG x{self.paddle.damage_boost+1}", (255, 150, 100)))

        for i, (text, color) in enumerate(indicators):
            indicator = self.font_tiny.render(text, True, color)
            x_pos = SCREEN_WIDTH // 2 - (len(indicators) * 60) // 2 + i * 60
            surface.blit(indicator, (x_pos, 55))

    def update(self):
        if self.state != STATE_PLAYING:
            return

        self.paddle.update()

        for brick in self.bricks:
            brick.update()

        for projectile in self.enemy_projectiles[:]:
            projectile.update()

            if not self.paddle.shield_active:
                paddle_rect = pygame.Rect(self.paddle.x, self.paddle.y, self.paddle.width, self.paddle.height)
                proj_rect = pygame.Rect(
                    projectile.x - projectile.radius,
                    projectile.y - projectile.radius,
                    projectile.radius * 2,
                    projectile.radius * 2
                )

                if proj_rect.colliderect(paddle_rect):
                    self.lives -= 1
                    self.play_sound("life_lost")
                    self.enemy_projectiles.remove(projectile)
                    break

            if not projectile.active:
                self.enemy_projectiles.remove(projectile)

        for powerup in self.powerups[:]:
            powerup.update()
            powerup.move()

            paddle_rect = pygame.Rect(self.paddle.x, self.paddle.y, self.paddle.width, self.paddle.height)
            powerup_rect = pygame.Rect(powerup.x, powerup.y, powerup.width, powerup.height)

            if powerup_rect.colliderect(paddle_rect):
                powerup.collect()
                self.play_sound("powerup")
                powerup.collected = True

            if powerup.collected:
                self.powerups.remove(powerup)

        for ball in self.balls[:]:
            ball.move(self.paddle, self.bricks, self.powerups)
            if not ball.active:
                self.balls.remove(ball)

        if len(self.balls) == 0 and self.lives > 0:
            new_ball = Ball(self.paddle.x + self.paddle.width // 2, self.paddle.y - 20, self)
            new_ball.stuck_to_paddle = True
            self.balls.append(new_ball)

        if all(brick.destroyed for brick in self.bricks):
            self.state = STATE_LEVEL_COMPLETE
            self.play_sound("level_complete")

        if self.lives <= 0 and len(self.balls) == 0:
            self.state = STATE_GAME_OVER
            self.save_high_score()

    def draw(self, surface):
        self.draw_static_background(surface)

        for brick in self.bricks:
            brick.draw(surface)

        for powerup in self.powerups:
            powerup.draw(surface)

        for projectile in self.enemy_projectiles:
            projectile.draw(surface)

        self.paddle.draw(surface)

        for ball in self.balls:
            ball.draw(surface)

        self.draw_hud(surface)

        if self.state == STATE_MENU:
            self.draw_menu(surface)
        elif self.state == STATE_GAME_OVER:
            self.draw_game_over(surface)
        elif self.state == STATE_LEVEL_COMPLETE:
            self.draw_level_complete(surface)
        elif self.state == STATE_PAUSED:
            self.draw_pause_screen(surface)
        elif self.state == STATE_HIGH_SCORES:
            self.draw_high_scores(surface)
        elif self.state == STATE_SETTINGS:
            self.draw_settings(surface)

    def handle_input(self):
        keys = pygame.key.get_pressed()

        if self.state == STATE_PLAYING:
            if keys[K_LEFT] or keys[K_a]:
                self.paddle.move(-1)
            if keys[K_RIGHT] or keys[K_d]:
                self.paddle.move(1)

            if (keys[K_SPACE] or keys[K_z]) and self.paddle.laser_active:
                self.paddle.shoot_laser()

        for event in pygame.event.get():
            if event.type == QUIT:
                return False

            elif event.type == KEYDOWN:
                if event.key == K_ESCAPE:
                    if self.state in [STATE_HIGH_SCORES, STATE_SETTINGS, STATE_PAUSED]:
                        self.state = STATE_MENU
                        self.menu_option = 0
                    elif self.state == STATE_PLAYING:
                        self.state = STATE_PAUSED
                    else:
                        return False

                elif event.key == K_p and self.state == STATE_PLAYING:
                    self.state = STATE_PAUSED
                elif event.key == K_p and self.state == STATE_PAUSED:
                    self.state = STATE_PLAYING

                elif event.key == K_SPACE and self.state == STATE_PLAYING:
                    for ball in self.balls:
                        if ball.stuck_to_paddle:
                            ball.stuck_to_paddle = False

                elif event.key == K_UP:
                    if self.state in [STATE_MENU, STATE_GAME_OVER, STATE_LEVEL_COMPLETE]:
                        self.menu_option = (self.menu_option - 1) % 4
                    elif self.state == STATE_SETTINGS:
                        self.menu_option = (self.menu_option - 1) % 2

                elif event.key == K_DOWN:
                    if self.state in [STATE_MENU, STATE_GAME_OVER, STATE_LEVEL_COMPLETE]:
                        self.menu_option = (self.menu_option + 1) % 4
                    elif self.state == STATE_SETTINGS:
                        self.menu_option = (self.menu_option + 1) % 2

                elif event.key == K_RETURN:
                    self.handle_menu_selection()

                elif event.key == K_LEFT and self.state == STATE_SETTINGS:
                    if self.menu_option == 0:
                        self.settings["sound_volume"] = max(0, self.settings["sound_volume"] - 0.1)
                    elif self.menu_option == 1:
                        self.settings["difficulty"] = max(0, self.settings["difficulty"] - 1)

                elif event.key == K_RIGHT and self.state == STATE_SETTINGS:
                    if self.menu_option == 0:
                        self.settings["sound_volume"] = min(1, self.settings["sound_volume"] + 0.1)
                    elif self.menu_option == 1:
                        self.settings["difficulty"] = min(3, self.settings["difficulty"] + 1)

            elif event.type == MOUSEBUTTONDOWN:
                if event.button == 1:
                    self.handle_mouse_click(event.pos)

            elif event.type == MOUSEMOTION:
                if hasattr(self, 'menu_rects'):
                    for i, rect in enumerate(self.menu_rects):
                        if rect.collidepoint(event.pos):
                            self.menu_option = i
                            break

        return True

    def handle_menu_selection(self):
        if self.state == STATE_MENU:
            if self.menu_option == 0:
                self.reset()
                self.state = STATE_PLAYING
            elif self.menu_option == 1:
                self.state = STATE_HIGH_SCORES
            elif self.menu_option == 2:
                self.state = STATE_SETTINGS
                self.menu_option = 0
            elif self.menu_option == 3:
                return False

        elif self.state == STATE_GAME_OVER:
            if self.menu_option == 0:
                self.reset()
                self.state = STATE_PLAYING
            elif self.menu_option == 1:
                self.state = STATE_MENU
                self.menu_option = 0

        elif self.state == STATE_LEVEL_COMPLETE:
            if self.menu_option == 0:
                self.level += 1
                if self.level > self.max_level:
                    self.level = 1
                self.reset()
                self.state = STATE_PLAYING
            elif self.menu_option == 1:
                self.state = STATE_MENU
                self.menu_option = 0
        return True

    def handle_mouse_click(self, pos):
        if self.state in [STATE_HIGH_SCORES, STATE_SETTINGS]:
            self.state = STATE_MENU
            self.menu_option = 0
            return

        if hasattr(self, 'menu_rects'):
            for i, rect in enumerate(self.menu_rects):
                if rect.collidepoint(pos):
                    self.menu_option = i
                    self.handle_menu_selection()
                    break

def main():
    clock = pygame.time.Clock()
    game = Game()

    running = True
    while running:
        running = game.handle_input()

        if game.state == STATE_PLAYING:
            game.update()

        game.draw(screen)
        pygame.display.flip()
        clock.tick(FPS)

    pygame.quit()
    sys.exit()

if __name__ == "__main__":
    main()