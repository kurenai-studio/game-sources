import json
import os
import random
import sys
import pygame


def res(p):
    return os.path.join(
        getattr(sys, "_MEIPASS", os.path.dirname(os.path.abspath(__file__))), p
    )


# Frozen builds can't write next to the bundle (temp dir / read-only .app), so saves go to the home folder.
if getattr(sys, "frozen", False):
    SAVE_DIR = os.path.join(os.path.expanduser("~"), ".space_evader")
else:
    SAVE_DIR = os.path.dirname(os.path.abspath(__file__))
os.makedirs(SAVE_DIR, exist_ok=True)


def save_file(p):
    return os.path.join(SAVE_DIR, p)


pygame.init()

# 1. Window settings and clock
WIDTH, HEIGHT = 800, 600
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Space Evader")
clock = pygame.time.Clock()

# 2. player variables
player_x = 375
player_y = 500
player_size = 50
player_speed = 5

# 3. METEORITES
meteor_size = 40
meteor_speed = 4
num_meteors = 4

# 4. ENEMY SPACESHIP
enemy_size = 50
enemy_x = WIDTH // 2 - enemy_size // 2
enemy_y = 60
enemy_speed_x = 3
enemy_alive = True
enemy_respawn_timer = 0

# boss variables
boss_size = 90
boss_x = WIDTH // 2 - boss_size // 2
boss_y = 40
boss_speed_x = 3
boss_hp = 100
boss_max_hp = 100
boss_alive = False
boss_shoot_timer = 0
boss_phase = 1
next_boss_score = 100

# 5. LASERS
lasers = []
laser_speed = 10
laser_width = 5
laser_height = 15
shoot_cooldown = 0
RAPID_FIRE_DELAY = 8

# Enemy lasers
enemy_lasers = []
enemy_laser_speed = 7
enemy_shoot_timer = 0

# power-ups
powerups = []
powerup_speed = 3
POWERUP_TYPES = ["life", "shield", "rapid", "double"]
POWERUP_COLORS = {
    "shield": ((0, 150, 255), "S"),
    "rapid": ((255, 140, 0), "R"),
}

shield_timer = 0
rapid_timer = 0
double_timer = 0

# particles
particles = []

# 6. image load
player_img = pygame.image.load(res("player.png")).convert_alpha()
player_img = pygame.transform.scale(player_img, (player_size, player_size))

meteor_img = pygame.image.load(res("meteor.png")).convert_alpha()
meteor_img = pygame.transform.scale(meteor_img, (meteor_size, meteor_size))

life_img = pygame.image.load(res("life.png")).convert_alpha()
life_img = pygame.transform.scale(life_img, (25, 25))

coin_img = pygame.image.load(res("coin.png")).convert_alpha()
coin_img = pygame.transform.scale(coin_img, (25, 25))

default_background = pygame.image.load(res("default_background.jpg")).convert()
bg_img = pygame.transform.scale(default_background, (WIDTH, HEIGHT))

enemy_spaceship_img = pygame.image.load(res("enemy_spaceship.png")).convert_alpha()
enemy_spaceship_img = pygame.transform.scale(
    enemy_spaceship_img, (enemy_size, enemy_size)
)

boss_img = pygame.image.load(res("boss.png")).convert_alpha()
boss_img = pygame.transform.scale(
    boss_img, (boss_size, boss_size)
)

# ===== SHOP DATA =====
SKINS = [
    {"name": "Default", "file": "player.png", "price": 0},
    {"name": "Skin 2", "file": "player_skin2.png", "price": 50},
    {"name": "Skin 3", "file": "player_skin3.png", "price": 100},
]
for skin in SKINS:
    skin_img = pygame.image.load(res(skin["file"])).convert_alpha()
    skin["img"] = pygame.transform.scale(skin_img, (player_size, player_size))
    skin["icon"] = pygame.transform.scale(skin_img, (30, 30))

UPGRADES = [
    {"id": "lives", "name": "Extra starting life", "base_price": 40, "max_level": 2},
    {"id": "speed", "name": "Ship speed", "base_price": 30, "max_level": 3},
    {"id": "duration", "name": "Power-up duration", "base_price": 50, "max_level": 3},
]

# 7. background and fonts
bg_y = 0
bg_speed = 2

font = pygame.font.SysFont("Arial", 30)
small_font = pygame.font.SysFont("Arial", 20, bold=True)
title_font = pygame.font.SysFont("Arial", 50, bold=True)

# 8. high score
score = 0
try:
    with open(save_file("highscore.txt"), "r") as file:
        highscore = int(file.read())
except (FileNotFoundError, ValueError):
    highscore = 0

# coins
coins = 0
try:
    with open(save_file("coins.txt"), "r") as file:
        coins = int(file.read())
except (FileNotFoundError, ValueError):
    coins = 0

# shop save
shop = {
    "owned_skins": [0],
    "selected_skin": 0,
    "upgrades": {"lives": 0, "speed": 0, "duration": 0},
}
try:
    with open(save_file("shop.json"), "r") as file:
        shop.update(json.load(file))
except (FileNotFoundError, ValueError):
    pass

lives = 3
game_state = "MENU"
meteors = []

shop_index = 0
shop_message = ""
shop_message_until = 0


def save_highscore(val):
    with open(save_file("highscore.txt"), "w") as file:
        file.write(str(val))


def save_coins(val):
    with open(save_file("coins.txt"), "w") as file:
        file.write(str(val))


def save_shop():
    with open(save_file("shop.json"), "w") as file:
        json.dump(shop, file)


def create_explosion(x, y, color=(255, 165, 0)):
    for _ in range(15):
        particles.append(
            {
                "x": x,
                "y": y,
                "vx": random.uniform(-4, 4),
                "vy": random.uniform(-4, 4),
                "radius": random.randint(3, 6),
                "color": color,
                "lifetime": random.randint(15, 25),
            }
        )


def draw_coins(x, y, center=False):
    text = font.render(str(coins), True, (255, 215, 0))
    total_width = coin_img.get_width() + 8 + text.get_width()
    if center:
        x = x - total_width // 2
    icon_y = y + (text.get_height() - coin_img.get_height()) // 2
    screen.blit(coin_img, (x, icon_y))
    screen.blit(text, (x + coin_img.get_width() + 8, y))


def fire_laser():
    laser_x = player_x + (player_size // 2) - (laser_width // 2)
    lasers.append(pygame.Rect(laser_x, player_y, laser_width, laser_height))


def damage_player():
    global lives, game_state
    cx = player_x + player_size // 2
    cy = player_y + player_size // 2

    if shield_timer > 0:
        create_explosion(cx, cy, (0, 150, 255))
        return

    lives -= 1
    create_explosion(cx, cy, (255, 0, 0))
    if lives <= 0:
        game_state = "GAME_OVER"
        save_highscore(highscore)
        save_coins(coins)


def apply_powerup(kind):
    global lives, shield_timer, rapid_timer, double_timer
    if kind == "life":
        if lives < get_start_lives() + 2:
            lives += 1
    elif kind == "shield":
        shield_timer = get_powerup_duration()
    elif kind == "rapid":
        rapid_timer = get_powerup_duration()
    elif kind == "double":
        double_timer = get_powerup_duration()


def draw_powerup(p_up):
    rect = p_up["rect"]
    kind = p_up["type"]
    if kind == "life":
        screen.blit(life_img, rect)
    elif kind == "double":
        screen.blit(coin_img, rect)
    else:
        color, letter = POWERUP_COLORS[kind]
        pygame.draw.circle(screen, color, rect.center, 13)
        pygame.draw.circle(screen, (255, 255, 255), rect.center, 13, 2)
        label = small_font.render(letter, True, (255, 255, 255))
        screen.blit(label, label.get_rect(center=rect.center))


# UPGRADES
def upgrade_level(upgrade_id):
    return shop["upgrades"].get(upgrade_id, 0)


def upgrade_price(upg):
    return upg["base_price"] * (upgrade_level(upg["id"]) + 1)


def get_start_lives():
    return 3 + upgrade_level("lives")


def get_player_speed():
    return 5 + upgrade_level("speed")


def get_powerup_duration():
    return 600 + 120 * upgrade_level("duration")


# SHOP
menu_overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
menu_overlay.fill((0, 0, 0, 110))


def shop_items():
    return [("skin", i) for i in range(len(SKINS))] + [
        ("upgrade", i) for i in range(len(UPGRADES))
    ]


def shop_action(index):
    global coins, shop_message, shop_message_until
    kind, i = shop_items()[index]
    message = ""

    if kind == "skin":
        skin = SKINS[i]
        if i in shop["owned_skins"]:
            shop["selected_skin"] = i
            message = "Equipped"
        elif coins >= skin["price"]:
            coins -= skin["price"]
            shop["owned_skins"].append(i)
            shop["selected_skin"] = i
            message = "Bought and equipped!"
        else:
            message = "Not enough coins"
    else:
        upg = UPGRADES[i]
        level = upgrade_level(upg["id"])
        price = upgrade_price(upg)
        if level >= upg["max_level"]:
            message = "Already at max level"
        elif coins >= price:
            coins -= price
            shop["upgrades"][upg["id"]] = level + 1
            message = "Upgraded!"
        else:
            message = "Not enough coins"

    shop_message = message
    shop_message_until = pygame.time.get_ticks() + 1500
    save_coins(coins)
    save_shop()


def draw_shop():
    screen.blit(menu_overlay, (0, 0))

    title = title_font.render("SHOP", True, (0, 255, 255))
    screen.blit(title, (WIDTH // 2 - title.get_width() // 2, 30))
    draw_coins(WIDTH // 2, 100, center=True)

    if pygame.time.get_ticks() < shop_message_until:
        msg = small_font.render(shop_message, True, (255, 215, 0))
        screen.blit(msg, (WIDTH // 2 - msg.get_width() // 2, 138))

    y = 170
    for index, (kind, i) in enumerate(shop_items()):
        if kind == "skin":
            skin = SKINS[i]
            label = f"Skin: {skin['name']}"
            if shop["selected_skin"] == i:
                status = "EQUIPPED"
            elif i in shop["owned_skins"]:
                status = "Owned"
            else:
                status = f"{skin['price']} coins"
            screen.blit(skin["icon"], (110, y))
        else:
            upg = UPGRADES[i]
            level = upgrade_level(upg["id"])
            label = f"{upg['name']} ({level}/{upg['max_level']})"
            if level >= upg["max_level"]:
                status = "MAX"
            else:
                status = f"{upgrade_price(upg)} coins"

        selected = index == shop_index
        color = (255, 215, 0) if selected else (255, 255, 255)

        label_text = font.render(label, True, color)
        status_text = font.render(status, True, color)
        screen.blit(label_text, (160, y))
        screen.blit(status_text, (WIDTH - 110 - status_text.get_width(), y))
        if selected:
            pygame.draw.rect(screen, color, (95, y - 8, WIDTH - 190, 46), 2)
        y += 55

    draw_button(back_button)

    hint = small_font.render(
        "CLICK or ENTER = buy / equip   |   ESC = back", True, (200, 200, 200)
    )
    screen.blit(hint, (WIDTH // 2 - hint.get_width() // 2, 552))


# MENU BUTTONS
menu_buttons = [
    {"label": "PLAY", "action": "play", "rect": pygame.Rect(WIDTH // 2 - 130, 310, 260, 55)},
    {"label": "SHOP", "action": "shop", "rect": pygame.Rect(WIDTH // 2 - 130, 380, 260, 55)},
    {"label": "QUIT", "action": "quit", "rect": pygame.Rect(WIDTH // 2 - 130, 450, 260, 55)},
]


def draw_button(button):
    rect = button["rect"]
    hovered = rect.collidepoint(pygame.mouse.get_pos())

    fill = (0, 110, 140, 230) if hovered else (20, 30, 60, 200)
    border = (0, 255, 255) if hovered else (90, 140, 180)

    panel = pygame.Surface(rect.size, pygame.SRCALPHA)
    pygame.draw.rect(panel, fill, panel.get_rect(), border_radius=12)
    screen.blit(panel, rect)
    pygame.draw.rect(screen, border, rect, 3, border_radius=12)

    text = font.render(button["label"], True, (255, 255, 255))
    screen.blit(text, text.get_rect(center=rect.center))


# clickable shop
back_button = {
    "label": "BACK",
    "action": "back",
    "rect": pygame.Rect(WIDTH // 2 - 100, 492, 200, 44),
}


def shop_row_rect(index):
    return pygame.Rect(95, 170 + index * 55 - 8, WIDTH - 190, 46)


game_over_buttons = [
    {"label": "RESTART", "action": "restart", "rect": pygame.Rect(WIDTH // 2 - 270, 395, 260, 50)},
    {"label": "MENU", "action": "menu", "rect": pygame.Rect(WIDTH // 2 + 10, 395, 260, 50)},
]


def reset_game():
    global player_x, player_y, meteor_speed, score, lives, lasers, enemy_lasers, meteors
    global enemy_x, enemy_alive, enemy_respawn_timer, enemy_shoot_timer, powerups
    global particles, shield_timer, rapid_timer, double_timer, shoot_cooldown
    global player_speed, player_img
    global boss_alive, boss_hp, boss_max_hp, boss_x, boss_shoot_timer, next_boss_score, boss_phase

    player_x = 375
    player_y = 500
    player_speed = get_player_speed()
    player_img = SKINS[shop["selected_skin"]]["img"]
    enemy_x = WIDTH // 2 - enemy_size // 2
    enemy_alive = True
    enemy_respawn_timer = 0
    enemy_shoot_timer = 0

    boss_alive = False
    boss_hp = 100
    boss_max_hp = 100
    boss_x = WIDTH // 2 - boss_size // 2
    boss_shoot_timer = 0
    boss_speed_x = 3
    next_boss_score = 100
    boss_phase = 1

    meteor_speed = 4
    score = 0
    lives = get_start_lives()
    lasers = []
    enemy_lasers = []
    powerups = []
    particles = []
    shield_timer = 0
    rapid_timer = 0
    double_timer = 0
    shoot_cooldown = 0

    meteors = []
    for i in range(num_meteors):
        x = random.randint(0, WIDTH - meteor_size)
        y = random.randint(-500, -meteor_size)
        meteors.append(pygame.Rect(x, y, meteor_size, meteor_size))


# 9. main loop
running = True
while running:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if game_state == "MENU":
                for button in menu_buttons:
                    if button["rect"].collidepoint(event.pos):
                        if button["action"] == "play":
                            reset_game()
                            game_state = "PLAYING"
                        elif button["action"] == "shop":
                            game_state = "SHOP"
                        elif button["action"] == "quit":
                            running = False

            elif game_state == "SHOP":
                if back_button["rect"].collidepoint(event.pos):
                    game_state = "MENU"
                else:
                    for index in range(len(shop_items())):
                        if shop_row_rect(index).collidepoint(event.pos):
                            shop_index = index
                            shop_action(index)

            elif game_state == "GAME_OVER":
                for button in game_over_buttons:
                    if button["rect"].collidepoint(event.pos):
                        if button["action"] == "restart":
                            reset_game()
                            game_state = "PLAYING"
                        elif button["action"] == "menu":
                            game_state = "MENU"

        if event.type == pygame.MOUSEMOTION and game_state == "SHOP":
            for index in range(len(shop_items())):
                if shop_row_rect(index).collidepoint(event.pos):
                    shop_index = index

        if event.type == pygame.KEYDOWN:
            if game_state == "MENU":
                if event.key == pygame.K_SPACE or event.key == pygame.K_RETURN:
                    reset_game()
                    game_state = "PLAYING"
                elif event.key == pygame.K_s:
                    game_state = "SHOP"

            elif game_state == "PLAYING":
                if event.key == pygame.K_SPACE:
                    fire_laser()
                    shoot_cooldown = RAPID_FIRE_DELAY

            elif game_state == "SHOP":
                if event.key == pygame.K_UP:
                    shop_index = (shop_index - 1) % len(shop_items())
                elif event.key == pygame.K_DOWN:
                    shop_index = (shop_index + 1) % len(shop_items())
                elif event.key == pygame.K_RETURN:
                    shop_action(shop_index)
                elif event.key == pygame.K_ESCAPE:
                    game_state = "MENU"

            elif game_state == "GAME_OVER":
                if event.key == pygame.K_r:
                    reset_game()
                    game_state = "PLAYING"
                elif event.key == pygame.K_m or event.key == pygame.K_ESCAPE:
                    game_state = "MENU"

    # --- GAME LOGIC ---
    bg_y += bg_speed
    if bg_y >= HEIGHT:
        bg_y = 0

    for p in particles[:]:
        p["x"] += p["vx"]
        p["y"] += p["vy"]
        p["radius"] -= 0.2
        p["lifetime"] -= 1
        if p["lifetime"] <= 0 or p["radius"] <= 0:
            particles.remove(p)

    if game_state == "PLAYING":
        keys = pygame.key.get_pressed()
        if (keys[pygame.K_LEFT] or keys[pygame.K_a]) and player_x > 0:
            player_x -= player_speed
        if (
            keys[pygame.K_RIGHT] or keys[pygame.K_d]
        ) and player_x < WIDTH - player_size:
            player_x += player_speed
        if (keys[pygame.K_UP] or keys[pygame.K_w]) and player_y > 0:
            player_y -= player_speed
        if (
            keys[pygame.K_DOWN] or keys[pygame.K_s]
        ) and player_y < HEIGHT - player_size:
            player_y += player_speed

        player_x = max(0, min(player_x, WIDTH - player_size))
        player_y = max(0, min(player_y, HEIGHT - player_size))

        player_rect = pygame.Rect(player_x, player_y, player_size, player_size)

        if score > highscore:
            highscore = score

        # Check Boss Spawn
        if not boss_alive and score >= next_boss_score:
            boss_alive = True
            boss_hp = 100 + (score // 100) * 40
            boss_max_hp = boss_hp
            boss_phase = 1
            boss_speed_x = 3
            boss_x = WIDTH // 2 - boss_size // 2

        # Effect timers
        if shield_timer > 0:
            shield_timer -= 1
        if rapid_timer > 0:
            rapid_timer -= 1
        if double_timer > 0:
            double_timer -= 1
        if shoot_cooldown > 0:
            shoot_cooldown -= 1

        # Rapid fire: holding space
        if rapid_timer > 0 and keys[pygame.K_SPACE] and shoot_cooldown <= 0:
            fire_laser()
            shoot_cooldown = RAPID_FIRE_DELAY

        coin_mult = 2 if double_timer > 0 else 1

        # Power-ups
        for p_up in powerups[:]:
            p_up["rect"].y += powerup_speed
            if p_up["rect"].y > HEIGHT:
                powerups.remove(p_up)
            elif player_rect.colliderect(p_up["rect"]):
                apply_powerup(p_up["type"])
                powerups.remove(p_up)

        # BOSS LOGIC
        if boss_alive:
            hp_percentage =  boss_hp / boss_max_hp

            if hp_percentage > 0.6:
                boss_phase = 1
            elif hp_percentage > 0.25:
                boss_phase = 2
            else:
                boss_phase = 3

            if boss_phase == 1:
                current_speed = 3
            elif boss_phase == 2:
                current_speed = 5
            else:
                current_speed = 8

            boss_x += current_speed if boss_speed_x > 0 else -current_speed
            if boss_x <= 0 or boss_x >= WIDTH - boss_size:
                boss_speed_x *= -1

            boss_shoot_timer += 1

            if boss_phase == 1 and boss_shoot_timer >= 45:
                boss_shoot_timer = 0
                enemy_lasers.append(pygame.Rect(boss_x + 15, boss_y + boss_size, 6, 18))
                enemy_lasers.append(pygame.Rect(boss_x + boss_size - 21, boss_y + boss_size, 6, 18))

            elif boss_phase == 2 and boss_shoot_timer >= 30:
                boss_shoot_timer = 0
                enemy_lasers.append(pygame.Rect(boss_x + 10, boss_y + boss_size, 6, 18))
                enemy_lasers.append(pygame.Rect(boss_x + boss_size // 2 - 3, boss_y + boss_size, 6, 18))
                enemy_lasers.append(pygame.Rect(boss_x + boss_size - 16, boss_y + boss_size, 6, 18))

            elif boss_phase == 3 and boss_shoot_timer >= 12:
                boss_shoot_timer = 0
                shot_x = random.randint(boss_x + 10, boss_x + boss_size - 15)
                enemy_lasers.append(pygame.Rect(shot_x, boss_y + boss_size, 7, 20))

        # Regular Enemy Logic
        elif enemy_alive:
            enemy_x += enemy_speed_x
            if enemy_x <= 0 or enemy_x >= WIDTH - enemy_size:
                enemy_speed_x *= -1

            enemy_shoot_timer += 1
            if enemy_shoot_timer >= 60:
                enemy_shoot_timer = 0
                e_laser_x = enemy_x + (enemy_size // 2) - 2
                enemy_lasers.append(
                    pygame.Rect(e_laser_x, enemy_y + enemy_size, 5, 15)
                )
        else:
            enemy_respawn_timer -= 1
            if enemy_respawn_timer <= 0:
                enemy_x = random.randint(0, WIDTH - enemy_size)
                enemy_alive = True

        # Enemy lasers
        for e_laser in enemy_lasers[:]:
            e_laser.y += enemy_laser_speed
            if e_laser.y > HEIGHT:
                enemy_lasers.remove(e_laser)
            elif player_rect.colliderect(e_laser):
                enemy_lasers.remove(e_laser)
                damage_player()

        # Meteors
        for meteor in meteors:
            meteor.y += meteor_speed

            if meteor.y > HEIGHT:
                meteor.y = -meteor_size
                meteor.x = random.randint(0, WIDTH - meteor_size)

            if player_rect.colliderect(meteor):
                meteor.y = -meteor_size
                meteor.x = random.randint(0, WIDTH - meteor_size)
                damage_player()

        # Player lasers
        for laser in lasers[:]:
            laser.y -= laser_speed
            if laser.y < -laser_height:
                lasers.remove(laser)
                continue

            # Boss hit
            if boss_alive:
                boss_rect = pygame.Rect(boss_x, boss_y, boss_size, boss_size)
                if laser.colliderect(boss_rect):
                    boss_hp -= 1
                    create_explosion(laser.x, laser.y, (255, 200, 0))
                    lasers.remove(laser)
                    if boss_hp <= 0:
                        boss_alive = False
                        score += 50
                        coins += 20 * coin_mult
                        next_boss_score = score + 100
                        create_explosion(
                            boss_x + boss_size // 2,
                            boss_y + boss_size // 2,
                            (255, 50, 0),
                        )
                        # Drop powerup
                        powerups.append(
                            {
                                "rect": pygame.Rect(
                                    boss_x + boss_size // 2, boss_y + 30, 25, 25
                                ),
                                "type": random.choice(POWERUP_TYPES),
                            }
                        )
                    continue

            # Enemy hit
            if enemy_alive and not boss_alive:
                enemy_rect = pygame.Rect(
                    enemy_x, enemy_y, enemy_size, enemy_size
                )
                if laser.colliderect(enemy_rect):
                    score += 5
                    coins += 3 * coin_mult
                    enemy_alive = False
                    enemy_respawn_timer = 180
                    create_explosion(
                        enemy_x + enemy_size // 2,
                        enemy_y + enemy_size // 2,
                        (255, 50, 50),
                    )

                    if random.random() < 0.5:
                        powerups.append(
                            {
                                "rect": pygame.Rect(enemy_x + 12, enemy_y, 25, 25),
                                "type": random.choice(POWERUP_TYPES),
                            }
                        )

                    lasers.remove(laser)
                    continue

            # Meteor hit
            for meteor in meteors:
                if laser.colliderect(meteor):
                    score += 1
                    coins += 1 * coin_mult
                    meteor_speed += 0.05
                    create_explosion(
                        meteor.x + meteor_size // 2,
                        meteor.y + meteor_size // 2,
                        (255, 165, 0),
                    )
                    meteor.y = -meteor_size
                    meteor.x = random.randint(0, WIDTH - meteor_size)
                    if laser in lasers:
                        lasers.remove(laser)
                    break

    # --- RENDERING ---
    screen.blit(bg_img, (0, bg_y))
    screen.blit(bg_img, (0, bg_y - HEIGHT))

    if game_state == "MENU":
        screen.blit(menu_overlay, (0, 0))

        title_text = title_font.render("SPACE EVADER", True, (0, 255, 255))
        title_shadow = title_font.render("SPACE EVADER", True, (0, 60, 80))
        high_score_text = font.render(
            f"High Score: {highscore}", True, (255, 215, 0)
        )

        title_x = WIDTH // 2 - title_text.get_width() // 2
        screen.blit(title_shadow, (title_x + 3, 113))
        screen.blit(title_text, (title_x, 110))
        screen.blit(
            high_score_text,
            (WIDTH // 2 - high_score_text.get_width() // 2, 195),
        )
        draw_coins(WIDTH // 2, 240, center=True)

        for button in menu_buttons:
            draw_button(button)

        hint = small_font.render(
            "SPACE / ENTER = play   |   S = shop", True, (200, 200, 200)
        )
        screen.blit(hint, (WIDTH // 2 - hint.get_width() // 2, 550))

    elif game_state == "SHOP":
        draw_shop()

    elif game_state == "PLAYING":
        screen.blit(player_img, (player_x, player_y))

        if shield_timer > 0 and (shield_timer > 120 or (shield_timer // 6) % 2 == 0):
            pygame.draw.circle(
                screen,
                (0, 150, 255),
                (player_x + player_size // 2, player_y + player_size // 2),
                player_size // 2 + 8,
                3,
            )

        for meteor in meteors:
            screen.blit(meteor_img, meteor)

        if boss_alive:
            screen.blit(boss_img, (boss_x, boss_y))

            # Boss Health Bar
            bar_w = 300
            bar_h = 18
            bar_x = WIDTH // 2 - bar_w // 2
            bar_y = 15
            fill_w = max(0, int((boss_hp / boss_max_hp) * bar_w))

            if boss_phase == 1:
                bar_color = (255, 50, 50)
            elif boss_phase == 2:
                bar_color = (255, 140, 0)
            else:
                bar_color = (200, 0, 255)

            pygame.draw.rect(screen, (50, 0, 0), (bar_x, bar_y, bar_w, bar_h))
            pygame.draw.rect(screen, bar_color, (bar_x, bar_y, fill_w, bar_h))
            pygame.draw.rect(screen, (255, 255, 255), (bar_x, bar_y, bar_w, bar_h), 2)

            b_label = small_font.render("BOSS", True, (255, 255, 255))
            screen.blit(b_label, (WIDTH // 2 - b_label.get_width() // 2, bar_y + 18))

        elif enemy_alive:
            screen.blit(enemy_spaceship_img, (enemy_x, enemy_y))

        for e_laser in enemy_lasers:
            pygame.draw.rect(screen, (255, 50, 50), e_laser)

        for laser in lasers:
            pygame.draw.rect(screen, (0, 255, 255), laser)

        for p_up in powerups:
            draw_powerup(p_up)

        for p in particles:
            pygame.draw.circle(
                screen, p["color"], (int(p["x"]), int(p["y"])), int(p["radius"])
            )

        score_text = font.render(f"Score: {score}", True, (255, 255, 255))
        high_score_text = font.render(
            f"High Score: {highscore}", True, (255, 215, 0)
        )

        screen.blit(score_text, (10, 10))
        screen.blit(high_score_text, (10, 45))
        draw_coins(10, 80)

        effects = [
            ("Shield", shield_timer, (0, 150, 255)),
            ("Rapid fire", rapid_timer, (255, 140, 0)),
            ("2x coins", double_timer, (255, 215, 0)),
        ]
        effect_y = 120
        for name, timer, color in effects:
            if timer > 0:
                effect_text = small_font.render(
                    f"{name}: {timer // 60 + 1}s", True, color
                )
                screen.blit(effect_text, (10, effect_y))
                effect_y += 24

        for i in range(lives):
            screen.blit(life_img, (WIDTH - 35 - (i * 30), 15))

    elif game_state == "GAME_OVER":
        for p in particles:
            pygame.draw.circle(
                screen, p["color"], (int(p["x"]), int(p["y"])), int(p["radius"])
            )

        game_over_text = title_font.render("GAME OVER", True, (255, 50, 50))
        score_text = font.render(f"Score: {score}", True, (255, 255, 255))
        high_score_text = font.render(
            f"High Score: {highscore}", True, (255, 215, 0)
        )

        screen.blit(
            game_over_text, (WIDTH // 2 - game_over_text.get_width() // 2, 150)
        )
        screen.blit(score_text, (WIDTH // 2 - score_text.get_width() // 2, 240))
        screen.blit(
            high_score_text,
            (WIDTH // 2 - high_score_text.get_width() // 2, 280),
        )
        draw_coins(WIDTH // 2, 320, center=True)

        for button in game_over_buttons:
            draw_button(button)

        hint = small_font.render(
            "CLICK or R = restart   |   M = menu", True, (200, 200, 200)
        )
        screen.blit(hint, (WIDTH // 2 - hint.get_width() // 2, 552))

    pygame.display.flip()
    clock.tick(60)

pygame.quit()
sys.exit()
