"""游戏实体：玩家、敌人、子弹、道具、粒子。所有实体都用圆形碰撞体。"""
import math
import random
import pygame
from settings import *


class Entity:
    radius = 10

    def __init__(self, x, y):
        self.x, self.y = float(x), float(y)
        self.vx = self.vy = 0.0
        self.alive = True

    def update(self, dt, game):
        self.x += self.vx * dt
        self.y += self.vy * dt
        if self.y < -60 or self.y > HEIGHT + 60 or self.x < -60 or self.x > WIDTH + 60:
            self.alive = False

    def collides(self, other):
        dx, dy = self.x - other.x, self.y - other.y
        r = self.radius + other.radius
        return dx * dx + dy * dy <= r * r          # 比较平方，省去开方


class Player(Entity):
    radius = 12

    def __init__(self):
        super().__init__(WIDTH / 2, HEIGHT - 90)
        self.hp = PLAYER_HP
        self.fire_timer = 0.0
        self.invincible = 0.0
        self.power = 1                # 火力等级 1~3
        self.power_timer = 0.0
        self.shield = 0.0

    def update(self, dt, game, move=(0, 0), firing=False):
        mx, my = move
        length = math.hypot(mx, my)
        if length > 1:
            mx, my = mx / length, my / length          # 斜向移动不加速
        self.x = min(max(self.x + mx * PLAYER_SPEED * dt, 20), WIDTH - 20)
        self.y = min(max(self.y + my * PLAYER_SPEED * dt, 40), HEIGHT - 30)

        self.fire_timer -= dt
        self.invincible = max(0.0, self.invincible - dt)
        self.shield = max(0.0, self.shield - dt)
        if self.power > 1:
            self.power_timer -= dt
            if self.power_timer <= 0:
                self.power = 1
        if firing and self.fire_timer <= 0:
            self.fire_timer = PLAYER_FIRE_INTERVAL
            self.shoot(game)

    def shoot(self, game):
        spreads = {1: [0], 2: [-8, 8], 3: [-14, 0, 14]}[self.power]
        for offset in spreads:
            angle = math.radians(offset * 0.6)
            game.bullets.append(Bullet(self.x + offset, self.y - 18,
                                       math.sin(angle) * BULLET_SPEED, -math.cos(angle) * BULLET_SPEED, friendly=True))
        game.sound("shoot")

    def hit(self, game):
        if self.invincible > 0:
            return
        if self.shield > 0:
            self.shield = 0
            self.invincible = 0.5
            return
        self.hp -= 1
        self.invincible = PLAYER_INVINCIBLE
        game.shake = 0.3
        game.burst(self.x, self.y, CYAN, 18)
        game.sound("hurt")

    def draw(self, surf):
        if self.invincible > 0 and int(self.invincible * 20) % 2 == 0:
            return                                     # 无敌时闪烁
        x, y = self.x, self.y
        pygame.draw.polygon(surf, CYAN, [(x, y - 18), (x - 14, y + 12), (x, y + 6), (x + 14, y + 12)])
        pygame.draw.polygon(surf, WHITE, [(x, y - 10), (x - 4, y + 2), (x + 4, y + 2)])
        flame = random.randint(6, 12)
        pygame.draw.polygon(surf, ORANGE, [(x - 5, y + 9), (x + 5, y + 9), (x, y + 9 + flame)])
        if self.shield > 0:
            pygame.draw.circle(surf, GREEN, (int(x), int(y)), 24, 2)


class Bullet(Entity):
    def __init__(self, x, y, vx, vy, friendly):
        super().__init__(x, y)
        self.vx, self.vy = vx, vy
        self.friendly = friendly
        self.radius = 4 if friendly else 5

    def draw(self, surf):
        if self.friendly:
            pygame.draw.rect(surf, YELLOW, (self.x - 2, self.y - 8, 4, 14), border_radius=2)
        else:
            pygame.draw.circle(surf, PURPLE, (int(self.x), int(self.y)), self.radius)
            pygame.draw.circle(surf, WHITE, (int(self.x), int(self.y)), 2)


class Enemy(Entity):
    """三种敌人：
    grunt  直线俯冲
    weaver 正弦摆动
    gunner 停在上方并向玩家发射子弹
    """
    STATS = {
        "grunt": dict(hp=1, speed=150, radius=13, score=10, color=RED),
        "weaver": dict(hp=2, speed=110, radius=14, score=20, color=ORANGE),
        "gunner": dict(hp=5, speed=70, radius=18, score=50, color=PURPLE),
    }

    def __init__(self, x, kind, speed_scale=1.0):
        super().__init__(x, -30)
        st = self.STATS[kind]
        self.kind = kind
        self.hp = st["hp"]
        self.radius = st["radius"]
        self.score = st["score"]
        self.color = st["color"]
        self.vy = st["speed"] * speed_scale
        self.t = random.random() * 6
        self.base_x = x
        self.fire_timer = random.uniform(0.8, 1.6)
        self.flash = 0.0

    def update(self, dt, game):
        self.t += dt
        self.flash = max(0.0, self.flash - dt)
        if self.kind == "weaver":
            self.x = self.base_x + math.sin(self.t * 3) * 60
        elif self.kind == "gunner":
            if self.y > 140:
                self.vy = 0                         # 到达位置后悬停射击
            self.fire_timer -= dt
            if self.fire_timer <= 0 and self.y > 0:
                self.fire_timer = 1.4
                dx, dy = game.player.x - self.x, game.player.y - self.y
                d = math.hypot(dx, dy) or 1
                for spread in (-0.25, 0, 0.25):    # 三向弹
                    a = math.atan2(dy, dx) + spread
                    game.bullets.append(Bullet(self.x, self.y + 10, math.cos(a) * ENEMY_BULLET_SPEED,
                                               math.sin(a) * ENEMY_BULLET_SPEED, friendly=False))
        super().update(dt, game)

    def damage(self, amount, game):
        self.hp -= amount
        self.flash = 0.06
        if self.hp <= 0:
            self.alive = False
            game.on_enemy_killed(self)

    def draw(self, surf):
        c = WHITE if self.flash > 0 else self.color
        x, y, r = int(self.x), int(self.y), self.radius
        if self.kind == "grunt":
            pygame.draw.polygon(surf, c, [(x, y + r), (x - r, y - r // 2), (x + r, y - r // 2)])
        elif self.kind == "weaver":
            pygame.draw.polygon(surf, c, [(x, y + r), (x - r, y), (x, y - r), (x + r, y)])
        else:
            pygame.draw.circle(surf, c, (x, y), r)
            pygame.draw.circle(surf, BG, (x, y), r - 6)
            pygame.draw.circle(surf, c, (x, y), 5)


class PowerUp(Entity):
    radius = 11

    def __init__(self, x, y, kind):
        super().__init__(x, y)
        self.kind = kind          # "power" 火力 / "shield" 护盾 / "heal" 回血
        self.vy = 90
        self.t = 0

    def update(self, dt, game):
        self.t += dt
        super().update(dt, game)

    def draw(self, surf):
        color = {"power": YELLOW, "shield": GREEN, "heal": RED}[self.kind]
        r = self.radius + math.sin(self.t * 8) * 2
        pygame.draw.circle(surf, color, (int(self.x), int(self.y)), int(r), 2)
        label = {"power": "P", "shield": "S", "heal": "+"}[self.kind]
        txt = Particle.font().render(label, True, color)
        surf.blit(txt, txt.get_rect(center=(self.x, self.y)))


class Particle:
    _font = None

    @classmethod
    def font(cls):
        if cls._font is None:
            cls._font = pygame.font.SysFont("arial", 14, bold=True)
        return cls._font

    def __init__(self, x, y, color):
        a = random.uniform(0, math.tau)
        s = random.uniform(60, 260)
        self.x, self.y = x, y
        self.vx, self.vy = math.cos(a) * s, math.sin(a) * s
        self.life = self.max_life = random.uniform(0.25, 0.6)
        self.color = color
        self.alive = True

    def update(self, dt, game):
        self.x += self.vx * dt
        self.y += self.vy * dt
        self.vx *= 0.92
        self.vy *= 0.92
        self.life -= dt
        self.alive = self.life > 0

    def draw(self, surf):
        k = self.life / self.max_life
        size = max(1, int(4 * k))
        pygame.draw.rect(surf, self.color, (self.x, self.y, size, size))
