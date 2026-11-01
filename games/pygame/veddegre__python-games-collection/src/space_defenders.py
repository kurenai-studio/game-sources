import os
os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "1"
import pygame
import random
import sys
import math
from highscores import get_high_score, save_high_score

GAME_NAME = "space_defenders"

pygame.init()

WIDTH, HEIGHT = 800, 600
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Space Defenders")
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


BLACK  = (0, 0, 0)
WHITE  = (255, 255, 255)
GREEN  = (0, 255, 0)
RED    = (255, 60, 60)
YELLOW = (255, 220, 0)
CYAN   = (0, 220, 255)
ORANGE = (255, 140, 0)
PURPLE = (180, 0, 255)

font       = pygame.font.SysFont(None, 36)
small_font = pygame.font.SysFont(None, 26)
clock      = pygame.time.Clock()

stars = [(random.randint(0, WIDTH), random.randint(0, HEIGHT), random.uniform(0.3, 1.5)) for _ in range(120)]

def draw_stars():
    for sx, sy, _ in stars:
        pygame.draw.circle(screen, (180, 180, 180), (int(sx), int(sy)), 1)

player_w, player_h = 60, 40
player_x = WIDTH // 2 - player_w // 2
player_y = HEIGHT - player_h - 20
player_speed = 8

bullets = []
bullet_w, bullet_h, bullet_speed = 5, 15, 12

ENEMY_TYPES = {
    "basic":  {"color": RED,    "w": 46, "h": 36, "hp": 1, "pts": 1, "speed": 2.0},
    "fast":   {"color": CYAN,   "w": 34, "h": 28, "hp": 1, "pts": 2, "speed": 4.5},
    "tank":   {"color": ORANGE, "w": 56, "h": 44, "hp": 3, "pts": 5, "speed": 1.2},
    "zigzag": {"color": PURPLE, "w": 40, "h": 34, "hp": 2, "pts": 3, "speed": 2.5},
}

enemies = []
explosions = []

BOSS_SCORE_THRESHOLD = 20
boss = None
boss_spawned_at = 0

class Boss:
    def __init__(self):
        self.w, self.h = 140, 80
        self.x = WIDTH // 2 - self.w // 2
        self.y = 30
        self.max_hp = 30
        self.hp = self.max_hp
        self.speed = 2.5
        self.dir = 1
        self.shoot_timer = 0
        self.shoot_interval = 90
        self.bullets = []
        self.alive = True
        self.phase = 1

    def update(self):
        self.x += self.speed * self.dir
        if self.x <= 0 or self.x + self.w >= WIDTH:
            self.dir *= -1
        if self.hp <= self.max_hp // 2 and self.phase == 1:
            self.phase = 2
            self.speed = 4.0
            self.shoot_interval = 50
        self.shoot_timer += 1
        if self.shoot_timer >= self.shoot_interval:
            self.shoot_timer = 0
            for offset in [-30, 0, 30]:
                self.bullets.append([self.x + self.w // 2 + offset, self.y + self.h])
        for b in self.bullets[:]:
            b[1] += 5
            if b[1] > HEIGHT:
                self.bullets.remove(b)

    def draw(self):
        color = YELLOW if self.phase == 1 else ORANGE
        pygame.draw.rect(screen, color, (self.x, self.y, self.w, self.h), border_radius=8)
        pygame.draw.rect(screen, WHITE,  (self.x, self.y, self.w, self.h), 2, border_radius=8)
        eye_y = self.y + self.h // 3
        pygame.draw.circle(screen, RED, (int(self.x + self.w * 0.3), eye_y), 8)
        pygame.draw.circle(screen, RED, (int(self.x + self.w * 0.7), eye_y), 8)
        bar_w = self.w
        filled = int(bar_w * self.hp / self.max_hp)
        pygame.draw.rect(screen, (80, 0, 0),  (self.x, self.y - 14, bar_w, 8))
        pygame.draw.rect(screen, (0, 220, 0), (self.x, self.y - 14, filled, 8))
        lbl = small_font.render("BOSS", True, WHITE)
        screen.blit(lbl, (self.x + self.w // 2 - lbl.get_width() // 2, self.y + self.h + 2))
        for b in self.bullets:
            pygame.draw.rect(screen, RED, (b[0] - 3, b[1], 6, 14))

    def hit(self, dmg=1):
        self.hp -= dmg
        if self.hp <= 0:
            self.alive = False

def draw_player(x, y):
    pygame.draw.polygon(screen, GREEN, [
        (x + player_w // 2, y - 12),
        (x + player_w, y + player_h),
        (x + player_w // 2, y + player_h - 10),
        (x, y + player_h)
    ])
    pygame.draw.rect(screen, (0, 180, 0), (x + player_w // 2 - 8, y - 4, 16, player_h + 4), border_radius=4)

def draw_enemy(e):
    t = ENEMY_TYPES[e["type"]]
    x, y, w, h = e["x"], e["y"], t["w"], t["h"]
    color = t["color"]
    pygame.draw.rect(screen, color, (x, y, w, h), border_radius=6)
    pygame.draw.rect(screen, WHITE,  (x, y, w, h), 1, border_radius=6)
    pygame.draw.circle(screen, WHITE, (x + w // 4, y + h // 2), 4)
    pygame.draw.circle(screen, WHITE, (x + 3 * w // 4, y + h // 2), 4)
    if t["hp"] > 1 and e["hp"] > 0:
        for i in range(e["hp"]):
            pygame.draw.rect(screen, WHITE, (x + 4 + i * 10, y + h - 8, 7, 5))

def draw_explosion(exp):
    age_ratio = exp["age"] / exp["max_age"]
    alpha = int(255 * (1 - age_ratio))
    r = int(exp["radius"] * age_ratio * 2)
    if r < 2:
        return
    surf = pygame.Surface((r * 2, r * 2), pygame.SRCALPHA)
    pygame.draw.circle(surf, (*exp["color"], alpha), (r, r), r)
    screen.blit(surf, (exp["x"] - r, exp["y"] - r))

def spawn_explosion(x, y, color=(255, 140, 0)):
    explosions.append({"x": x, "y": y, "radius": 20, "age": 0, "max_age": 20, "color": color})

def rect_collide(ax, ay, aw, ah, bx, by, bw, bh):
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by

score = 0
high_score = get_high_score(GAME_NAME)
new_high = False
game_over = False
running = True
enemy_spawn_timer = 0
SPAWN_INTERVAL = 55

def reset():
    global player_x, bullets, enemies, boss, boss_spawned_at
    global score, game_over, new_high, enemy_spawn_timer
    player_x = WIDTH // 2 - player_w // 2
    bullets.clear()
    enemies.clear()
    explosions.clear()
    boss = None
    boss_spawned_at = 0
    score = 0
    game_over = False
    new_high = False
    enemy_spawn_timer = 0

def spawn_enemy():
    if score < 5:
        choices = ["basic"] * 8 + ["fast"] * 2
    elif score < 15:
        choices = ["basic"] * 5 + ["fast"] * 3 + ["tank"] * 1 + ["zigzag"] * 1
    else:
        choices = ["basic"] * 3 + ["fast"] * 3 + ["tank"] * 2 + ["zigzag"] * 2
    etype = random.choice(choices)
    t = ENEMY_TYPES[etype]
    enemies.append({
        "type": etype,
        "x": random.randint(0, WIDTH - t["w"]),
        "y": -t["h"],
        "hp": t["hp"],
        "zigzag_t": 0,
    })

while running:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_SPACE and not game_over:
                bullets.append([player_x + player_w // 2 - bullet_w // 2, player_y])
            if event.key == pygame.K_r and game_over:
                reset()

    if not game_over:
        keys = pygame.key.get_pressed()
        if keys[pygame.K_LEFT]  and player_x > 0:               player_x -= player_speed
        if keys[pygame.K_RIGHT] and player_x < WIDTH - player_w: player_x += player_speed

        enemy_spawn_timer += 1
        interval = max(20, SPAWN_INTERVAL - score)
        if enemy_spawn_timer >= interval:
            spawn_enemy()
            enemy_spawn_timer = 0

        if boss is None and score >= BOSS_SCORE_THRESHOLD and score // BOSS_SCORE_THRESHOLD > boss_spawned_at // BOSS_SCORE_THRESHOLD:
            boss = Boss()
            boss_spawned_at = score

        for b in bullets[:]:
            b[1] -= bullet_speed
            if b[1] < 0:
                bullets.remove(b)

        for e in enemies[:]:
            t = ENEMY_TYPES[e["type"]]
            if e["type"] == "zigzag":
                e["zigzag_t"] += 0.08
                e["x"] += math.sin(e["zigzag_t"]) * 3
            e["y"] += t["speed"]
            if e["y"] > HEIGHT:
                enemies.remove(e)
                continue
            if rect_collide(e["x"], e["y"], t["w"], t["h"], player_x, player_y, player_w, player_h):
                game_over = True
                spawn_explosion(player_x + player_w // 2, player_y + player_h // 2, (0, 200, 255))
                if save_high_score(GAME_NAME, score): new_high = True
                high_score = get_high_score(GAME_NAME)

        for b in bullets[:]:
            for e in enemies[:]:
                t = ENEMY_TYPES[e["type"]]
                if rect_collide(b[0], b[1], bullet_w, bullet_h, e["x"], e["y"], t["w"], t["h"]):
                    if b in bullets: bullets.remove(b)
                    e["hp"] -= 1
                    if e["hp"] <= 0:
                        spawn_explosion(e["x"] + t["w"] // 2, e["y"] + t["h"] // 2, t["color"])
                        score += t["pts"]
                        if e in enemies: enemies.remove(e)
                    break

        if boss:
            boss.update()
            for b in bullets[:]:
                if rect_collide(b[0], b[1], bullet_w, bullet_h, boss.x, boss.y, boss.w, boss.h):
                    if b in bullets: bullets.remove(b)
                    boss.hit()
                    if not boss.alive:
                        spawn_explosion(boss.x + boss.w // 2, boss.y + boss.h // 2, YELLOW)
                        score += 15
                        boss = None
                    break
            if boss:
                for bb in boss.bullets[:]:
                    if rect_collide(bb[0] - 3, bb[1], 6, 14, player_x, player_y, player_w, player_h):
                        game_over = True
                        spawn_explosion(player_x + player_w // 2, player_y + player_h // 2, (0, 200, 255))
                        if save_high_score(GAME_NAME, score): new_high = True
                        high_score = get_high_score(GAME_NAME)

        for exp in explosions[:]:
            exp["age"] += 1
            if exp["age"] >= exp["max_age"]:
                explosions.remove(exp)

    screen.fill(BLACK)
    draw_stars()

    if not game_over:
        draw_player(player_x, player_y)
    for b in bullets:
        pygame.draw.rect(screen, GREEN, (b[0], b[1], bullet_w, bullet_h))
    for e in enemies:
        draw_enemy(e)
    if boss:
        boss.draw()
    for exp in explosions:
        draw_explosion(exp)

    score_text = font.render(f"Score: {score}", True, WHITE)
    screen.blit(score_text, (10, 10))
    hi_text = small_font.render(f"Best: {high_score}", True, YELLOW)
    screen.blit(hi_text, (10, 44))

    if boss:
        warn = font.render("!! BOSS !!", True, YELLOW)
        screen.blit(warn, (WIDTH // 2 - warn.get_width() // 2, 8))

    # Legend
    legend_items = [("Basic", RED), ("Fast", CYAN), ("Tank", ORANGE), ("Zigzag", PURPLE)]
    for i, (lname, lcolor) in enumerate(legend_items):
        pygame.draw.rect(screen, lcolor, (WIDTH - 100, 10 + i * 20, 12, 12), border_radius=2)
        lt = small_font.render(lname, True, WHITE)
        screen.blit(lt, (WIDTH - 84, 9 + i * 20))

    if game_over:
        overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 160))
        screen.blit(overlay, (0, 0))
        go_text  = font.render("GAME OVER", True, RED)
        sc_text  = font.render(f"Final Score: {score}", True, WHITE)
        rst_text = font.render("Press R to Restart", True, WHITE)
        screen.blit(go_text,  (WIDTH // 2 - go_text.get_width()  // 2, HEIGHT // 2 - 70))
        screen.blit(sc_text,  (WIDTH // 2 - sc_text.get_width()  // 2, HEIGHT // 2 - 20))
        screen.blit(rst_text, (WIDTH // 2 - rst_text.get_width() // 2, HEIGHT // 2 + 30))
        if new_high:
            nb = font.render("NEW HIGH SCORE!", True, YELLOW)
            screen.blit(nb, (WIDTH // 2 - nb.get_width() // 2, HEIGHT // 2 + 70))

    pygame.display.flip()
    clock.tick(60)

pygame.quit()
sys.exit()
