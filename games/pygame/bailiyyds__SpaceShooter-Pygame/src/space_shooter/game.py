"""主循环与游戏流程：菜单 → 游戏 → 结算。负责碰撞检测、计分、特效与 HUD。"""
import json
import math
import os
import random
import array
import pygame
from settings import *
from entities import Player, PowerUp, Particle
from waves import WaveManager

FONT_NAMES = "microsoftyahei,simhei,pingfangsc,notosanscjksc,notosanscjk,wenquanyimicrohei,arial"
SAVE_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "highscore.json")


def load_highscore():
    try:
        with open(SAVE_FILE, encoding="utf-8") as f:
            return int(json.load(f).get("highscore", 0))
    except (OSError, ValueError):
        return 0


def save_highscore(score):
    try:
        with open(SAVE_FILE, "w", encoding="utf-8") as f:
            json.dump({"highscore": score}, f)
    except OSError:
        pass


def make_tone(freq, duration, volume=0.3, slide=0.0, noise=False):
    """用代码合成音效（方波 / 噪声），不依赖外部音频文件。"""
    rate = 22050
    n = int(rate * duration)
    buf = array.array("h")
    phase = 0.0
    for i in range(n):
        t = i / n
        f = freq * (1 + slide * t)
        phase += f / rate
        if noise:
            v = random.uniform(-1, 1)
        else:
            v = 1.0 if (phase % 1.0) < 0.5 else -1.0
        env = (1 - t) ** 2
        buf.append(int(v * env * volume * 32767))
    return pygame.mixer.Sound(buffer=buf.tobytes())


class Game:
    def __init__(self, autopilot=False, fixed_dt=None):
        pygame.init()
        self.audio = False
        try:
            pygame.mixer.init(22050, -16, 1, 512)
            self.sounds = {
                "shoot": make_tone(880, 0.06, 0.12, slide=-0.5),
                "boom": make_tone(120, 0.25, 0.25, noise=True),
                "hurt": make_tone(200, 0.3, 0.3, slide=-0.6),
                "power": make_tone(520, 0.25, 0.2, slide=1.0),
            }
            self.audio = True
        except pygame.error:
            self.sounds = {}
        self.screen = pygame.display.set_mode((WIDTH, HEIGHT))
        pygame.display.set_caption(TITLE)
        self.canvas = pygame.Surface((WIDTH, HEIGHT))
        self.clock = pygame.time.Clock()
        self.font = pygame.font.SysFont(FONT_NAMES, 20)
        self.big = pygame.font.SysFont(FONT_NAMES, 44, bold=True)
        self.small = pygame.font.SysFont(FONT_NAMES, 14)
        self.autopilot = autopilot
        self.fixed_dt = fixed_dt
        self.highscore = load_highscore()
        self.stars = [(random.uniform(0, WIDTH), random.uniform(0, HEIGHT), random.choice((1, 1, 2, 3)))
                      for _ in range(90)]
        self.state = "menu"
        self.reset()

    # ---------------- 流程 ----------------
    def reset(self):
        self.player = Player()
        self.enemies, self.bullets, self.powerups, self.particles = [], [], [], []
        self.waves = WaveManager()
        self.score = 0
        self.combo = 0
        self.combo_timer = 0.0
        self.shake = 0.0
        self.banner_text, self.banner_time = "", 0.0
        self.time = 0.0

    def banner(self, text):
        self.banner_text, self.banner_time = text, 1.6

    def sound(self, name):
        if self.audio and name in self.sounds:
            self.sounds[name].play()

    def burst(self, x, y, color, count):
        self.particles.extend(Particle(x, y, color) for _ in range(count))

    def on_enemy_killed(self, enemy):
        self.combo += 1
        self.combo_timer = 1.5
        multiplier = 1 + min(self.combo // 5, 4) * 0.5         # 连杀倍率，最高 x3
        self.score += int(enemy.score * multiplier)
        self.burst(enemy.x, enemy.y, enemy.color, 14)
        self.shake = max(self.shake, 0.08)
        self.sound("boom")
        if random.random() < POWERUP_CHANCE:
            self.powerups.append(PowerUp(enemy.x, enemy.y, random.choice(("power", "power", "shield", "heal"))))

    # ---------------- 输入 ----------------
    def read_input(self):
        if self.autopilot:
            return self.autopilot_input()
        k = pygame.key.get_pressed()
        mx = (k[pygame.K_d] or k[pygame.K_RIGHT]) - (k[pygame.K_a] or k[pygame.K_LEFT])
        my = (k[pygame.K_s] or k[pygame.K_DOWN]) - (k[pygame.K_w] or k[pygame.K_UP])
        return (mx, my), bool(k[pygame.K_SPACE] or k[pygame.K_j])

    def autopilot_input(self):
        """演示 / 自动测试用 AI：躲避最近的敌弹，否则对准最近的敌人。"""
        p = self.player
        threat = [b for b in self.bullets if not b.friendly and b.y < p.y + 10 and abs(b.x - p.x) < 40 and p.y - b.y < 160]
        if threat:
            b = min(threat, key=lambda b: p.y - b.y)
            return (1 if b.x < p.x else -1, 0.3), True
        targets = [e for e in self.enemies if e.alive and e.y > 0]
        if targets:
            e = min(targets, key=lambda e: abs(e.x - p.x) + (HEIGHT - e.y) * 0.3)
            dx = e.x - p.x
            return (max(-1, min(1, dx / 30)), (HEIGHT - 110 - p.y) / 60), True
        return ((WIDTH / 2 - p.x) / 60, 0), True

    # ---------------- 更新 ----------------
    def update(self, dt):
        self.time += dt
        for i, (x, y, s) in enumerate(self.stars):       # 视差星空
            y += s * 40 * dt
            self.stars[i] = (x, y - HEIGHT if y > HEIGHT else y, s)
        self.banner_time = max(0.0, self.banner_time - dt)
        self.shake = max(0.0, self.shake - dt)
        for p in self.particles:
            p.update(dt, self)
        self.particles = [p for p in self.particles if p.alive]
        if self.state != "playing":
            return

        move, firing = self.read_input()
        self.player.update(dt, self, move, firing)
        self.waves.update(dt, self)
        for group in (self.enemies, self.bullets, self.powerups):
            for obj in group:
                obj.update(dt, self)

        self.collide()

        self.enemies = [e for e in self.enemies if e.alive]
        self.bullets = [b for b in self.bullets if b.alive]
        self.powerups = [p for p in self.powerups if p.alive]
        self.combo_timer -= dt
        if self.combo_timer <= 0:
            self.combo = 0

        if self.player.hp <= 0:
            self.state = "over"
            self.burst(self.player.x, self.player.y, WHITE, 40)
            if self.score > self.highscore:
                self.highscore = self.score
                save_highscore(self.score)

    def collide(self):
        p = self.player
        for b in self.bullets:
            if not b.alive:
                continue
            if b.friendly:
                for e in self.enemies:
                    if e.alive and b.collides(e):
                        b.alive = False
                        e.damage(1, self)
                        break
            elif b.collides(p):
                b.alive = False
                p.hit(self)
        for e in self.enemies:
            if e.alive and e.collides(p):
                e.damage(99, self)
                p.hit(self)
        for u in self.powerups:
            if u.alive and u.collides(p):
                u.alive = False
                self.sound("power")
                if u.kind == "power":
                    p.power = min(3, p.power + 1)
                    p.power_timer = 10
                elif u.kind == "shield":
                    p.shield = 8
                else:
                    p.hp = min(PLAYER_HP, p.hp + 1)

    # ---------------- 绘制 ----------------
    def text(self, font, s, color, center=None, topleft=None):
        img = font.render(s, True, color)
        rect = img.get_rect(center=center) if center else img.get_rect(topleft=topleft)
        self.canvas.blit(img, rect)

    def draw(self):
        c = self.canvas
        c.fill(BG)
        for x, y, s in self.stars:
            shade = 60 + s * 50
            pygame.draw.rect(c, (shade, shade, shade + 20), (x, y, s, s))
        for group in (self.powerups, self.bullets, self.enemies):
            for obj in group:
                obj.draw(c)
        if self.state == "playing":
            self.player.draw(c)
        for p in self.particles:
            p.draw(c)
        self.draw_hud()

        ox = oy = 0
        if self.shake > 0:
            ox, oy = random.randint(-4, 4), random.randint(-4, 4)
        self.screen.fill(BG)
        self.screen.blit(c, (ox, oy))
        pygame.display.flip()

    def draw_hud(self):
        p = self.player
        if self.state == "menu":
            self.text(self.big, "太空射击", CYAN, center=(WIDTH / 2, HEIGHT * 0.36))
            self.text(self.font, "WASD 移动 · 空格 射击", WHITE, center=(WIDTH / 2, HEIGHT * 0.5))
            self.text(self.font, "按 Enter 开始", YELLOW, center=(WIDTH / 2, HEIGHT * 0.56))
            self.text(self.small, f"最高分 {self.highscore}", GREY, center=(WIDTH / 2, HEIGHT * 0.63))
            return
        self.text(self.font, f"分数 {self.score}", WHITE, topleft=(14, 10))
        self.text(self.small, f"最高 {max(self.highscore, self.score)}   第 {self.waves.wave} 波", GREY, topleft=(14, 36))
        for i in range(PLAYER_HP):
            col = RED if i < p.hp else (60, 40, 50)
            pygame.draw.circle(self.canvas, col, (WIDTH - 20 - i * 20, 22), 7)
        if p.power > 1:
            self.text(self.small, f"火力 Lv{p.power}  {p.power_timer:.0f}s", YELLOW, topleft=(WIDTH - 130, 36))
        if self.combo >= 5:
            mult = 1 + min(self.combo // 5, 4) * 0.5
            self.text(self.font, f"{self.combo} 连杀  x{mult:g}", ORANGE, center=(WIDTH / 2, 70))
        if self.banner_time > 0:
            self.text(self.big, self.banner_text, WHITE, center=(WIDTH / 2, HEIGHT * 0.4))
        if self.state == "over":
            self.text(self.big, "游戏结束", RED, center=(WIDTH / 2, HEIGHT * 0.4))
            self.text(self.font, f"得分 {self.score}   最高 {self.highscore}", WHITE, center=(WIDTH / 2, HEIGHT * 0.48))
            self.text(self.font, "按 Enter 重新开始", YELLOW, center=(WIDTH / 2, HEIGHT * 0.54))

    # ---------------- 主循环 ----------------
    def handle_events(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return False
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    return False
                if event.key == pygame.K_RETURN and self.state in ("menu", "over"):
                    self.reset()
                    self.state = "playing"
        return True

    def run(self, max_frames=None, on_frame=None):
        frame = 0
        running = True
        while running:
            dt = self.fixed_dt or min(self.clock.tick(FPS) / 1000.0, 1 / 20)   # 限制最大步长，防止卡顿后穿模
            running = self.handle_events()
            self.update(dt)
            self.draw()
            frame += 1
            if on_frame:
                on_frame(self, frame)
            if max_frames and frame >= max_frames:
                break
        pygame.quit()
