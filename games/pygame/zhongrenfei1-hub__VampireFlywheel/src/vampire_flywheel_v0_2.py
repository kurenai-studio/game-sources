"""
VampireFlywheel V0.2 - 四环飞轮 Roguelite
纯移动控制（WASD / 方向键），所有武器自动攻击。
升级时按 ← → 选卡，Enter/Space 确认。死亡后按 R 重开。
"""
import pygame
import sys
import math
import random

pygame.init()

# ============== 配置 ==============
WIDTH, HEIGHT = 1280, 720
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("VampireFlywheel V0.2 - 四环飞轮 Roguelite")
clock = pygame.time.Clock()

# ---------- 字体（自动适配中文） ----------
def find_cn_font_path():
    for name in ['microsoftyaheiui', 'microsoftyahei', 'msyh', 'simhei',
                 'pingfangsc', 'pingfang', 'stheitisc', 'stheiti',
                 'hiraginosansgb', 'wqy-microhei', 'notosanscjksc',
                 'arialunicode']:
        path = pygame.font.match_font(name)
        if path:
            return path
    return None

CN_FONT = find_cn_font_path()
def mk(size):
    if CN_FONT:
        return pygame.font.Font(CN_FONT, size)
    return pygame.font.Font(None, size + 4)

font_xs = mk(14)
font_s  = mk(18)
font_m  = mk(22)
font_l  = mk(30)
font_xl = mk(40)
font_xxl = mk(60)

# ---------- 颜色 ----------
WHITE = (245, 245, 245)
RED = (255, 70, 70)
DARK_RED = (170, 30, 30)
GREEN = (80, 220, 110)
BLUE = (80, 160, 255)
BLACK = (0, 0, 0)
YELLOW = (255, 220, 60)
GOLD = (255, 200, 0)
PURPLE = (190, 90, 220)
ORANGE = (255, 140, 30)
CYAN = (90, 220, 255)
GRAY = (130, 130, 140)
DARK_GRAY = (50, 50, 60)
DARK_BG = (20, 20, 32)
CARD_BG = (40, 40, 56)
CARD_HL = (90, 90, 130)

# ============== 武器 / 被动 定义 ==============
WEAPONS = {
    "garlic": {"name": "蒜头光环", "desc": "对周围敌人持续灼烧",       "color": (220, 220, 150), "max_level": 5},
    "wand":   {"name": "魔法飞弹", "desc": "自动追踪最近的敌人",       "color": (180, 120, 255), "max_level": 5},
    "whip":   {"name": "皮鞭",     "desc": "水平鞭击身前敌人",         "color": (220, 110, 110), "max_level": 5},
    "halo":   {"name": "火焰旋环", "desc": "环绕身边旋转的火球",       "color": (255, 130, 40),  "max_level": 5},
    "knife":  {"name": "飞刀",     "desc": "朝移动方向射出飞刀",       "color": (200, 220, 230), "max_level": 5},
}
PASSIVES = {
    "max_hp":   {"name": "强壮", "desc": "+20 最大生命",      "color": (255, 110, 110), "max_level": 5},
    "speed":    {"name": "迅捷", "desc": "+10% 移动速度",     "color": (110, 255, 110), "max_level": 5},
    "damage":   {"name": "力量", "desc": "+15% 全武器伤害",   "color": (255, 180, 80),  "max_level": 5},
    "cooldown": {"name": "急速", "desc": "-8% 武器冷却",      "color": (110, 220, 255), "max_level": 5},
    "magnet":   {"name": "磁力", "desc": "+30% 拾取范围",     "color": (220, 110, 255), "max_level": 5},
    "regen":    {"name": "再生", "desc": "+0.5/s 生命恢复",   "color": (255, 90, 160),  "max_level": 5},
    "area":     {"name": "扩张", "desc": "+10% 武器范围",     "color": (255, 240, 150), "max_level": 5},
}

# ============== 游戏状态 ==============
class Game:
    def __init__(self):
        self.reset()
    def reset(self):
        self.player = {
            "pos": pygame.Vector2(WIDTH // 2, HEIGHT // 2),
            "speed": 4.0, "radius": 18,
            "hp": 100, "max_hp": 100, "hp_regen": 0.0,
            "level": 1, "exp": 0, "exp_to_next": 10,
            "damage_mult": 1.0, "cooldown_mult": 1.0,
            "pickup_range": 75, "projectiles_bonus": 0,
            "area_mult": 1.0, "iframes": 0.0,
            "facing": pygame.Vector2(1, 0),
            "weapons": {"garlic": 1},
            "passives": {},
            "weapon_state": {"garlic": {}},
        }
        self.enemies = []
        self.projectiles = []
        self.exp_orbs = []
        self.damage_numbers = []
        self.particles = []
        self.pulses = []
        self.wave = 1
        self.wave_timer = 0.0
        self.wave_duration = 25
        self.enemy_spawn_timer = 0.0
        self.score = 0
        self.kills = 0
        self.elapsed = 0.0
        self.game_over = False
        self.pending_levelups = 0
        self.level_up_cards = None
        self.selected_card = 0
        self.boss_alive = False
        self.next_boss_wave = 3

G = Game()

# ============== 通用辅助 ==============
def deal_damage(e, dmg, src_pos):
    if e["hp"] <= 0:
        return False
    e["hp"] -= dmg
    # 击退
    kb = e["pos"] - src_pos
    if kb.length() > 0:
        kb.normalize_ip()
        e["pos"] += kb * (5 if not e.get("is_boss") else 1.5)
    # 伤害数字
    G.damage_numbers.append({
        "pos": pygame.Vector2(e["pos"].x + random.uniform(-8, 8), e["pos"].y - e["radius"]),
        "value": int(dmg),
        "life": 0.7, "max_life": 0.7,
        "color": YELLOW if dmg < 18 else ORANGE,
    })
    if e["hp"] <= 0:
        if e in G.enemies:
            G.enemies.remove(e)
        # 经验球
        G.exp_orbs.append({"pos": e["pos"].copy(), "value": e.get("exp", 3)})
        # 粒子
        for _ in range(8 if not e.get("is_boss") else 24):
            ang = random.uniform(0, 6.2832)
            spd = random.uniform(1.2, 4.5)
            G.particles.append({
                "type": "blood",
                "pos": e["pos"].copy(),
                "vel": pygame.Vector2(math.cos(ang) * spd, math.sin(ang) * spd),
                "life": 0.5, "max_life": 0.5,
                "color": e.get("blood_color", DARK_RED),
                "size": random.uniform(2, 4),
            })
        G.score += e.get("score", 10)
        G.kills += 1
        if e.get("is_boss"):
            G.boss_alive = False
            for _ in range(8):
                off = pygame.Vector2(random.uniform(-40, 40), random.uniform(-40, 40))
                G.exp_orbs.append({"pos": e["pos"].copy() + off, "value": 6})
        return True
    return False

def spawn_enemy(boss=False):
    side = random.choice(["top", "bottom", "left", "right"])
    if side == "top":    pos = pygame.Vector2(random.randint(0, WIDTH), -40)
    elif side == "bottom": pos = pygame.Vector2(random.randint(0, WIDTH), HEIGHT + 40)
    elif side == "left": pos = pygame.Vector2(-40, random.randint(0, HEIGHT))
    else:                pos = pygame.Vector2(WIDTH + 40, random.randint(0, HEIGHT))

    if boss:
        hp = 180 + G.wave * 70
        G.enemies.append({
            "pos": pos, "speed": 1.3, "hp": hp, "max_hp": hp,
            "radius": 38, "color": (170, 40, 200), "damage": 1.5,
            "exp": 25, "score": 250, "is_boss": True,
            "blood_color": (220, 80, 220),
        })
        G.boss_alive = True
        return

    r = random.random()
    if G.wave >= 3 and r < 0.22:  # 快速
        hp = 7 + G.wave * 2
        G.enemies.append({
            "pos": pos, "speed": 2.9 + G.wave * 0.08, "hp": hp, "max_hp": hp,
            "radius": 12, "color": (255, 130, 130), "damage": 0.5,
            "exp": 3, "score": 12, "type": "fast", "blood_color": DARK_RED,
        })
    elif G.wave >= 4 and r < 0.38:  # 坦克
        hp = 38 + G.wave * 7
        G.enemies.append({
            "pos": pos, "speed": 1.05 + G.wave * 0.04, "hp": hp, "max_hp": hp,
            "radius": 26, "color": (140, 55, 55), "damage": 1.3,
            "exp": 9, "score": 28, "type": "tank", "blood_color": (110, 35, 35),
        })
    else:  # 普通
        hp = 11 + G.wave * 3
        G.enemies.append({
            "pos": pos, "speed": 1.5 + G.wave * 0.10, "hp": hp, "max_hp": hp,
            "radius": 17, "color": RED, "damage": 0.8,
            "exp": 4, "score": 10, "type": "normal", "blood_color": DARK_RED,
        })

# ============== 武器更新 ==============
def upd_garlic(p, lv, dt, st):
    st["timer"] = st.get("timer", 0) + dt
    cd = max(0.18, 0.55 - lv * 0.05) * p["cooldown_mult"]
    if st["timer"] >= cd:
        st["timer"] = 0
        dmg = (5 + lv * 3) * p["damage_mult"]
        rng = (88 + lv * 18) * p["area_mult"]
        hit = False
        for e in G.enemies[:]:
            if (e["pos"] - p["pos"]).length() < rng + e["radius"]:
                deal_damage(e, dmg, p["pos"])
                hit = True
        if hit:
            G.pulses.append({"pos": p["pos"].copy(), "max_r": rng, "r": 0,
                             "life": 0.22, "max_life": 0.22, "color": (220, 220, 150)})

def upd_wand(p, lv, dt, st):
    st["timer"] = st.get("timer", 0) + dt
    cd = max(0.32, 1.0 - lv * 0.08) * p["cooldown_mult"]
    if st["timer"] >= cd and G.enemies:
        st["timer"] = 0
        n = 1 + (lv - 1) // 2 + p["projectiles_bonus"]
        targets = sorted(G.enemies, key=lambda e: (e["pos"] - p["pos"]).length_squared())[:n]
        for t in targets:
            d = t["pos"] - p["pos"]
            d = d.normalize() if d.length() > 0 else pygame.Vector2(1, 0)
            G.projectiles.append({
                "pos": p["pos"].copy(), "vel": d * 9,
                "damage": (10 + lv * 4) * p["damage_mult"],
                "radius": 7, "color": (185, 130, 255), "life": 2.0,
                "homing": True, "target": t, "pierce": 0,
                "type": "wand", "hit_set": set(),
            })

def upd_whip(p, lv, dt, st):
    st["timer"] = st.get("timer", 0) + dt
    cd = max(0.55, 1.3 - lv * 0.09) * p["cooldown_mult"]
    if st["timer"] >= cd:
        st["timer"] = 0
        n = 1 + (lv - 1) // 2
        facing = p["facing"] if p["facing"].length() > 0 else pygame.Vector2(1, 0)
        # 优先朝向左/右
        side_dir = pygame.Vector2(1, 0) if facing.x >= 0 else pygame.Vector2(-1, 0)
        for i in range(n):
            d = side_dir if i % 2 == 0 else -side_dir
            G.particles.append({
                "type": "whip",
                "pos": p["pos"].copy(), "dir": d,
                "length": (115 + lv * 18) * p["area_mult"],
                "damage": (12 + lv * 5) * p["damage_mult"],
                "life": 0.18, "max_life": 0.18,
                "color": (220, 110, 110), "hit_set": set(),
            })

def upd_halo(p, lv, dt, st):
    needed = 2 + (lv - 1) // 2 + p["projectiles_bonus"]
    radius = (74 + lv * 10) * p["area_mult"]
    orbs = st.setdefault("orbs", [])
    st["angle"] = st.get("angle", 0) + dt * 2.6
    while len(orbs) < needed:
        orbs.append({})
    while len(orbs) > needed:
        orbs.pop()
    dmg = (4 + lv * 2) * p["damage_mult"]
    st["dmg_timer"] = st.get("dmg_timer", 0) + dt
    can_hit = st["dmg_timer"] >= 0.22
    if can_hit:
        st["dmg_timer"] = 0
    for i, orb in enumerate(orbs):
        ang = st["angle"] + (6.2832 / needed) * i
        orb["pos"] = p["pos"] + pygame.Vector2(math.cos(ang), math.sin(ang)) * radius
        if can_hit:
            for e in G.enemies[:]:
                if (e["pos"] - orb["pos"]).length() < e["radius"] + 14:
                    deal_damage(e, dmg, orb["pos"])

def upd_knife(p, lv, dt, st):
    st["timer"] = st.get("timer", 0) + dt
    cd = max(0.18, 0.5 - lv * 0.04) * p["cooldown_mult"]
    if st["timer"] >= cd:
        st["timer"] = 0
        n = 1 + (lv - 1) // 2 + p["projectiles_bonus"]
        facing = p["facing"] if p["facing"].length() > 0 else pygame.Vector2(1, 0)
        for i in range(n):
            spread = (i - (n - 1) / 2) * 0.20
            cs, sn = math.cos(spread), math.sin(spread)
            d = pygame.Vector2(facing.x * cs - facing.y * sn,
                               facing.x * sn + facing.y * cs)
            G.projectiles.append({
                "pos": p["pos"].copy(), "vel": d * 13,
                "damage": (6 + lv * 3) * p["damage_mult"],
                "radius": 5, "color": (220, 230, 240), "life": 0.85,
                "homing": False, "pierce": 1 + lv // 3,
                "type": "knife", "hit_set": set(),
            })

WEAPON_UPDATES = {
    "garlic": upd_garlic, "wand": upd_wand, "whip": upd_whip,
    "halo": upd_halo, "knife": upd_knife,
}

# ============== 升级卡牌 ==============
def generate_cards(p):
    pool = []
    for wid, w in WEAPONS.items():
        if wid not in p["weapons"]:
            pool.append(("new_weapon", wid, w["name"], w["desc"], w["color"]))
    for wid, lv in p["weapons"].items():
        if lv < WEAPONS[wid]["max_level"]:
            w = WEAPONS[wid]
            pool.append(("upgrade_weapon", wid, f"{w['name']} Lv{lv + 1}",
                         "强化已拥有武器", w["color"]))
    for pid, pdef in PASSIVES.items():
        cur = p["passives"].get(pid, 0)
        if cur < pdef["max_level"]:
            pool.append(("passive", pid, f"{pdef['name']} Lv{cur + 1}",
                         pdef["desc"], pdef["color"]))
    if len(pool) <= 3:
        return pool
    return random.sample(pool, 3)

def apply_card(card):
    kind, key, *_ = card
    p = G.player
    if kind == "new_weapon":
        p["weapons"][key] = 1
        p["weapon_state"][key] = {}
    elif kind == "upgrade_weapon":
        p["weapons"][key] += 1
    elif kind == "passive":
        p["passives"][key] = p["passives"].get(key, 0) + 1
        recompute_passives()

def recompute_passives():
    p = G.player
    base_speed = 4.0
    base_max_hp = 100
    p["damage_mult"] = 1.0
    p["cooldown_mult"] = 1.0
    p["pickup_range"] = 75
    p["projectiles_bonus"] = 0
    p["area_mult"] = 1.0
    p["hp_regen"] = 0.0
    bonus_hp = 0
    for pid, lv in p["passives"].items():
        if pid == "max_hp":   bonus_hp += 20 * lv
        elif pid == "speed":    base_speed *= (1 + 0.10 * lv)
        elif pid == "damage":   p["damage_mult"] *= (1 + 0.15 * lv)
        elif pid == "cooldown": p["cooldown_mult"] *= (1 - 0.08 * lv)
        elif pid == "magnet":   p["pickup_range"] *= (1 + 0.30 * lv)
        elif pid == "regen":    p["hp_regen"] += 0.5 * lv
        elif pid == "area":     p["area_mult"] *= (1 + 0.10 * lv)
    p["speed"] = base_speed
    new_max = base_max_hp + bonus_hp
    if new_max > p["max_hp"]:
        p["hp"] += (new_max - p["max_hp"])
    p["max_hp"] = new_max

# ============== 绘制 ==============
def draw_grid():
    for x in range(0, WIDTH, 40):
        pygame.draw.line(screen, (28, 28, 42), (x, 0), (x, HEIGHT))
    for y in range(0, HEIGHT, 40):
        pygame.draw.line(screen, (28, 28, 42), (0, y), (WIDTH, y))

def draw_player(p):
    # 无敌闪烁
    if int(p["iframes"] * 20) % 2 == 1:
        pygame.draw.circle(screen, (180, 200, 255), p["pos"], p["radius"])
    else:
        pygame.draw.circle(screen, BLUE, p["pos"], p["radius"])
    pygame.draw.circle(screen, WHITE, p["pos"], p["radius"], 3)
    if p["facing"].length() > 0:
        tip = p["pos"] + p["facing"] * (p["radius"] + 6)
        pygame.draw.circle(screen, YELLOW, tip, 4)

def draw_enemies():
    for e in G.enemies:
        pygame.draw.circle(screen, e["color"], e["pos"], e["radius"])
        pygame.draw.circle(screen, BLACK, e["pos"], e["radius"], 2)
        if e["hp"] < e["max_hp"]:
            bw = int(e["radius"] * 2)
            pct = max(0, e["hp"] / e["max_hp"])
            bx = e["pos"].x - bw // 2
            by = e["pos"].y - e["radius"] - 10
            pygame.draw.rect(screen, (60, 60, 60), (bx, by, bw, 5))
            col = GREEN if pct > 0.5 else (ORANGE if pct > 0.25 else RED)
            pygame.draw.rect(screen, col, (bx, by, int(bw * pct), 5))
        if e.get("is_boss"):
            lab = font_s.render("BOSS", True, GOLD)
            screen.blit(lab, (e["pos"].x - lab.get_width() // 2, e["pos"].y - e["radius"] - 30))

def draw_projectiles():
    for proj in G.projectiles:
        pygame.draw.circle(screen, proj["color"], proj["pos"], proj["radius"])
        pygame.draw.circle(screen, WHITE, proj["pos"], proj["radius"], 1)

def draw_orbs():
    for orb in G.exp_orbs:
        pygame.draw.circle(screen, YELLOW, orb["pos"], 7)
        pygame.draw.circle(screen, WHITE, orb["pos"], 7, 1)

def draw_damage_numbers():
    for d in G.damage_numbers:
        alpha = max(0, min(255, int(255 * (d["life"] / d["max_life"]))))
        txt = font_s.render(str(d["value"]), True, d["color"])
        txt.set_alpha(alpha)
        screen.blit(txt, (d["pos"].x - txt.get_width() // 2, d["pos"].y))

def draw_particles():
    for pt in G.particles:
        if pt.get("type") == "whip":
            life_pct = pt["life"] / pt["max_life"]
            length = pt["length"] * (1 - (1 - life_pct) * 0.15)
            start = pt["pos"]
            end = start + pt["dir"] * length
            width_px = max(2, int(22 * life_pct))
            pygame.draw.line(screen, pt["color"], start, end, width_px)
        else:
            sz = max(1, pt["size"] * (pt["life"] / pt["max_life"]))
            pygame.draw.circle(screen, pt["color"], pt["pos"], sz)

def draw_pulses():
    for ps in G.pulses:
        alpha_pct = ps["life"] / ps["max_life"]
        col = ps.get("color", (220, 220, 150))
        mr = int(ps["max_r"])
        if mr <= 0:
            continue
        s = pygame.Surface((mr * 2 + 4, mr * 2 + 4), pygame.SRCALPHA)
        pygame.draw.circle(s, (*col, int(90 * alpha_pct)), (mr + 2, mr + 2),
                           int(ps["r"]), 6)
        screen.blit(s, (ps["pos"].x - mr - 2, ps["pos"].y - mr - 2))

def draw_halo_orbs():
    st = G.player["weapon_state"].get("halo")
    if not st:
        return
    for orb in st.get("orbs", []):
        if "pos" in orb:
            pygame.draw.circle(screen, (255, 200, 80), orb["pos"], 13)
            pygame.draw.circle(screen, (255, 140, 50), orb["pos"], 10)
            pygame.draw.circle(screen, (255, 240, 200), orb["pos"], 4)

def draw_ui():
    p = G.player
    # HP 条
    pygame.draw.rect(screen, DARK_GRAY, (20, 20, 260, 22))
    pct = max(0, p["hp"] / p["max_hp"])
    pygame.draw.rect(screen, RED, (20, 20, int(260 * pct), 22))
    pygame.draw.rect(screen, WHITE, (20, 20, 260, 22), 2)
    hp_t = font_m.render(f"{int(p['hp'])}/{int(p['max_hp'])}", True, WHITE)
    screen.blit(hp_t, (150 - hp_t.get_width() // 2, 22))

    # EXP 条
    bar_w = 700
    bx = WIDTH // 2 - bar_w // 2
    pygame.draw.rect(screen, DARK_GRAY, (bx, 14, bar_w, 14))
    ep = p["exp"] / p["exp_to_next"] if p["exp_to_next"] > 0 else 0
    pygame.draw.rect(screen, YELLOW, (bx, 14, int(bar_w * ep), 14))
    pygame.draw.rect(screen, WHITE, (bx, 14, bar_w, 14), 1)
    lv = font_l.render(f"LV.{p['level']}", True, YELLOW)
    screen.blit(lv, (WIDTH // 2 - lv.get_width() // 2, 32))

    # 右上信息
    mins = int(G.elapsed // 60); secs = int(G.elapsed % 60)
    info = [
        f"波次 Wave {G.wave}",
        f"得分 {G.score}",
        f"击杀 {G.kills}",
        f"时间 {mins:02d}:{secs:02d}",
    ]
    for i, line in enumerate(info):
        t = font_m.render(line, True, WHITE)
        screen.blit(t, (WIDTH - 20 - t.get_width(), 20 + i * 26))

    # 武器 / 被动 图标
    x0 = 20
    y0 = HEIGHT - 56
    i = 0
    for wid, lv in p["weapons"].items():
        col = WEAPONS[wid]["color"]
        pygame.draw.rect(screen, col, (x0 + i * 46, y0, 40, 40), border_radius=6)
        pygame.draw.rect(screen, WHITE, (x0 + i * 46, y0, 40, 40), 2, border_radius=6)
        n = WEAPONS[wid]["name"][:1]
        nt = font_m.render(n, True, BLACK)
        screen.blit(nt, (x0 + i * 46 + 20 - nt.get_width() // 2,
                         y0 + 20 - nt.get_height() // 2))
        lvt = font_xs.render(str(lv), True, BLACK)
        screen.blit(lvt, (x0 + i * 46 + 30, y0 + 26))
        i += 1
    for pid, lv in p["passives"].items():
        col = PASSIVES[pid]["color"]
        pygame.draw.rect(screen, col, (x0 + i * 46, y0, 40, 40), border_radius=6)
        pygame.draw.rect(screen, WHITE, (x0 + i * 46, y0, 40, 40), 2, border_radius=6)
        n = PASSIVES[pid]["name"][:1]
        nt = font_m.render(n, True, BLACK)
        screen.blit(nt, (x0 + i * 46 + 20 - nt.get_width() // 2,
                         y0 + 20 - nt.get_height() // 2))
        lvt = font_xs.render(str(lv), True, BLACK)
        screen.blit(lvt, (x0 + i * 46 + 30, y0 + 26))
        i += 1

    # 控制提示
    hint = font_xs.render("WASD / 方向键 移动   武器自动攻击   升级时 ←→ 选卡 Enter 确认",
                          True, GRAY)
    screen.blit(hint, (WIDTH // 2 - hint.get_width() // 2, HEIGHT - 22))

def wrap_text(text, fnt, color, x, y, maxw):
    line = ""
    cy = y
    for ch in text:
        test = line + ch
        if fnt.size(test)[0] > maxw and line:
            screen.blit(fnt.render(line, True, color), (x, cy))
            cy += fnt.get_linesize()
            line = ch
        else:
            line = test
    if line:
        screen.blit(fnt.render(line, True, color), (x, cy))

def draw_levelup():
    overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
    overlay.fill((0, 0, 0, 190))
    screen.blit(overlay, (0, 0))
    title = font_xxl.render("升级！", True, GOLD)
    screen.blit(title, (WIDTH // 2 - title.get_width() // 2, 70))
    sub = font_m.render(f"LV.{G.player['level']}    剩余升级 {G.pending_levelups}",
                        True, WHITE)
    screen.blit(sub, (WIDTH // 2 - sub.get_width() // 2, 145))
    hint = font_m.render("← → 选择    Enter / Space 确认", True, GRAY)
    screen.blit(hint, (WIDTH // 2 - hint.get_width() // 2, 175))

    cards = G.level_up_cards or []
    cw, ch = 270, 360
    sp = 30
    total = len(cards) * cw + max(0, len(cards) - 1) * sp
    sx = WIDTH // 2 - total // 2
    for i, card in enumerate(cards):
        kind, key, name, desc, color = card
        x = sx + i * (cw + sp)
        y = HEIGHT // 2 - ch // 2 + 40
        bg = CARD_HL if i == G.selected_card else CARD_BG
        pygame.draw.rect(screen, bg, (x, y, cw, ch), border_radius=14)
        outline = GOLD if i == G.selected_card else GRAY
        pygame.draw.rect(screen, outline, (x, y, cw, ch),
                         5 if i == G.selected_card else 3, border_radius=14)
        # 图标
        pygame.draw.rect(screen, color, (x + 50, y + 30, cw - 100, cw - 100),
                         border_radius=12)
        pygame.draw.rect(screen, WHITE, (x + 50, y + 30, cw - 100, cw - 100),
                         3, border_radius=12)
        # 类型标签
        tag = "新武器" if kind == "new_weapon" else ("武器强化" if kind == "upgrade_weapon" else "被动")
        tag_col = GOLD if kind == "new_weapon" else (CYAN if kind == "upgrade_weapon" else GREEN)
        tt = font_m.render(tag, True, tag_col)
        screen.blit(tt, (x + cw // 2 - tt.get_width() // 2, y + cw - 38))
        # 名称
        nt = font_l.render(name, True, WHITE)
        screen.blit(nt, (x + cw // 2 - nt.get_width() // 2, y + cw - 5))
        # 描述
        wrap_text(desc, font_s, (230, 230, 230), x + 20, y + cw + 40, cw - 40)

def draw_game_over():
    overlay = pygame.Surface((WIDTH, HEIGHT))
    overlay.set_alpha(210); overlay.fill(BLACK)
    screen.blit(overlay, (0, 0))
    t1 = font_xxl.render("GAME OVER", True, RED)
    t2 = font_l.render(
        f"波次 {G.wave}   击杀 {G.kills}   得分 {G.score}   时间 {int(G.elapsed)}s",
        True, WHITE)
    t3 = font_m.render("按 R 重新开始    Esc 退出", True, GRAY)
    screen.blit(t1, (WIDTH // 2 - t1.get_width() // 2, HEIGHT // 2 - 130))
    screen.blit(t2, (WIDTH // 2 - t2.get_width() // 2, HEIGHT // 2 - 30))
    screen.blit(t3, (WIDTH // 2 - t3.get_width() // 2, HEIGHT // 2 + 30))

# ============== 主循环 ==============
running = True
while running:
    dt = clock.tick(60) / 1000.0

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE and G.game_over:
                running = False
            if G.game_over and event.key == pygame.K_r:
                G.reset()
            elif G.level_up_cards is not None:
                if event.key in (pygame.K_LEFT, pygame.K_a):
                    G.selected_card = (G.selected_card - 1) % len(G.level_up_cards)
                elif event.key in (pygame.K_RIGHT, pygame.K_d):
                    G.selected_card = (G.selected_card + 1) % len(G.level_up_cards)
                elif event.key in (pygame.K_RETURN, pygame.K_SPACE, pygame.K_KP_ENTER):
                    apply_card(G.level_up_cards[G.selected_card])
                    G.pending_levelups -= 1
                    if G.pending_levelups > 0:
                        G.level_up_cards = generate_cards(G.player)
                        G.selected_card = 0
                    else:
                        G.level_up_cards = None

    if not G.game_over and G.level_up_cards is None:
        # ---------- 输入 ----------
        keys = pygame.key.get_pressed()
        move = pygame.Vector2(0, 0)
        if keys[pygame.K_w] or keys[pygame.K_UP]:    move.y -= 1
        if keys[pygame.K_s] or keys[pygame.K_DOWN]:  move.y += 1
        if keys[pygame.K_a] or keys[pygame.K_LEFT]:  move.x -= 1
        if keys[pygame.K_d] or keys[pygame.K_RIGHT]: move.x += 1
        if move.length() > 0:
            move.normalize_ip()
            G.player["facing"] = move.copy()
            G.player["pos"] += move * G.player["speed"]
        G.player["pos"].x = max(G.player["radius"],
                                 min(WIDTH - G.player["radius"], G.player["pos"].x))
        G.player["pos"].y = max(G.player["radius"],
                                 min(HEIGHT - G.player["radius"], G.player["pos"].y))

        # ---------- 状态 ----------
        G.elapsed += dt
        if G.player["hp_regen"] > 0:
            G.player["hp"] = min(G.player["max_hp"],
                                 G.player["hp"] + G.player["hp_regen"] * dt)
        if G.player["iframes"] > 0:
            G.player["iframes"] -= dt

        # ---------- 波次 / 刷怪 ----------
        G.wave_timer += dt
        if G.wave_timer >= G.wave_duration:
            G.wave += 1
            G.wave_timer = 0
            if G.wave >= G.next_boss_wave and not G.boss_alive:
                spawn_enemy(boss=True)
                G.next_boss_wave += 3
        G.enemy_spawn_timer += dt
        spawn_rate = max(0.12, 0.7 - G.wave * 0.05)
        if G.enemy_spawn_timer >= spawn_rate:
            G.enemy_spawn_timer = 0
            burst = 1 + G.wave // 3
            for _ in range(burst):
                spawn_enemy()

        # ---------- 敌人 ----------
        for e in G.enemies[:]:
            d = G.player["pos"] - e["pos"]
            if d.length() > 0:
                d.normalize_ip()
                e["pos"] += d * e["speed"]
            if (e["pos"] - G.player["pos"]).length() < G.player["radius"] + e["radius"]:
                if G.player["iframes"] <= 0:
                    G.player["hp"] -= e["damage"]
                    G.player["iframes"] = 0.4
                    if G.player["hp"] <= 0:
                        G.player["hp"] = 0
                        G.game_over = True

        # ---------- 武器 ----------
        for wid, lv in list(G.player["weapons"].items()):
            st = G.player["weapon_state"].setdefault(wid, {})
            WEAPON_UPDATES[wid](G.player, lv, dt, st)

        # ---------- 投射物 ----------
        for proj in G.projectiles[:]:
            proj["life"] -= dt
            if proj.get("homing") and proj.get("target") and proj["target"] in G.enemies:
                to_t = proj["target"]["pos"] - proj["pos"]
                if to_t.length() > 0:
                    to_t.normalize_ip()
                    proj["vel"] += to_t * 0.6
                    if proj["vel"].length() > 12:
                        proj["vel"].scale_to_length(12)
            proj["pos"] += proj["vel"]
            # 出界
            if not (-50 < proj["pos"].x < WIDTH + 50 and -50 < proj["pos"].y < HEIGHT + 50):
                proj["life"] = 0
            for e in G.enemies[:]:
                eid = id(e)
                if eid in proj["hit_set"]:
                    continue
                if (e["pos"] - proj["pos"]).length() < proj["radius"] + e["radius"]:
                    deal_damage(e, proj["damage"], proj["pos"])
                    proj["hit_set"].add(eid)
                    if proj.get("pierce", 0) > 0:
                        proj["pierce"] -= 1
                    else:
                        proj["life"] = 0
                        break
            if proj["life"] <= 0:
                G.projectiles.remove(proj)

        # ---------- 鞭击伤害 ----------
        for pt in G.particles:
            if pt.get("type") == "whip":
                for e in G.enemies[:]:
                    eid = id(e)
                    if eid in pt["hit_set"]:
                        continue
                    rel = e["pos"] - pt["pos"]
                    along = rel.dot(pt["dir"])
                    if 0 <= along <= pt["length"]:
                        perp = (rel - pt["dir"] * along).length()
                        if perp < e["radius"] + 20:
                            deal_damage(e, pt["damage"], pt["pos"])
                            pt["hit_set"].add(eid)

        # ---------- 粒子 / 脉冲 / 数字 ----------
        for pt in G.particles[:]:
            pt["life"] -= dt
            if pt.get("type") == "blood" and "vel" in pt:
                pt["pos"] += pt["vel"]
                pt["vel"] *= 0.90
            if pt["life"] <= 0:
                G.particles.remove(pt)
        for ps in G.pulses[:]:
            ps["life"] -= dt
            ps["r"] = ps["max_r"] * (1 - ps["life"] / ps["max_life"])
            if ps["life"] <= 0:
                G.pulses.remove(ps)
        for dn in G.damage_numbers[:]:
            dn["life"] -= dt
            dn["pos"].y -= 30 * dt
            if dn["life"] <= 0:
                G.damage_numbers.remove(dn)

        # ---------- 经验球 ----------
        for orb in G.exp_orbs[:]:
            d = G.player["pos"] - orb["pos"]
            dist = d.length()
            if dist < G.player["pickup_range"] and dist > 0:
                orb["pos"] += d.normalize() * min(14, dist)
            if dist < G.player["radius"] + 12:
                G.player["exp"] += orb["value"]
                G.exp_orbs.remove(orb)
                while G.player["exp"] >= G.player["exp_to_next"]:
                    G.player["exp"] -= G.player["exp_to_next"]
                    G.player["level"] += 1
                    G.player["exp_to_next"] = int(G.player["exp_to_next"] * 1.28 + 4)
                    G.pending_levelups += 1
        if G.pending_levelups > 0 and G.level_up_cards is None:
            G.level_up_cards = generate_cards(G.player)
            G.selected_card = 0

    # ---------- 绘制 ----------
    screen.fill(DARK_BG)
    draw_grid()
    draw_pulses()
    draw_orbs()
    draw_particles()
    draw_enemies()
    draw_halo_orbs()
    draw_projectiles()
    draw_player(G.player)
    draw_damage_numbers()
    draw_ui()
    if G.level_up_cards is not None:
        draw_levelup()
    if G.game_over:
        draw_game_over()
    pygame.display.flip()

pygame.quit()
sys.exit()
