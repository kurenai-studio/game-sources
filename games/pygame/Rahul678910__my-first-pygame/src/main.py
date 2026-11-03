"""
main.py  –  Phase 4 (Complete)
Main menu, procedural gameplay, combat juice (screen shake, particles),
inventory, minimap, stats tracking, game-over screen, and best-floor persistence.

Controls
--------
WASD / Arrows  – Move
Space          – Melee attack (arc in front of player)
F              – Ranged attack (fires glowing projectile)
E              – Descend stairs (when standing on checkpoint platform)
I              – Toggle inventory (1–9 to use/equip)
M              – Toggle minimap
C              – View controls guide (from menu or in-game)
R              – Restart (on game over)
ESC            – Menu / Back / Quit
"""

import math
import os
import random
import sys
import pygame

from settings import (
    TITLE, SCREEN_W, SCREEN_H, FPS, TILE,
    COLS, ROWS,
    DARK_BG, WALL_DARK, WALL_LIT, FLOOR_DARK, FLOOR_LIT,
    CORRIDOR_DARK, CORRIDOR_LIT,
    CHEST_COL, UI_TEXT, UI_HIGHLIGHT, COIN_COL,
    SAVE_FILE,
    T_EMPTY, T_WALL, T_FLOOR, T_CORRIDOR, T_DOOR, T_STAIRS,
)
from dungeon import generate_dungeon, Dungeon
from entities import (
    Player, spawn_enemies,
    Interactable, Chest, Shrine, StairsCheckpoint, MerchantNPC, spawn_interactables,
)
from inventory import (
    Inventory, WorldLoot, Item,
    random_drop, chest_loot, make_key,
    draw_inventory_ui,
    KIND_POTION, KIND_WEAPON, POTION_COL, WEAPON_COL, KEY_COL,
)
from minimap import Minimap
import sfx


# ── Game States ──────────────────────────────────────────────────────────────
STATE_MENU     = "menu"
STATE_CONTROLS = "controls"
STATE_PLAYING  = "playing"
STATE_GAMEOVER = "gameover"

# ── Tile colours ─────────────────────────────────────────────────────────────
TILE_COLOURS = {
    T_EMPTY:    (DARK_BG,       DARK_BG),
    T_WALL:     (WALL_DARK,     WALL_LIT),
    T_FLOOR:    (FLOOR_DARK,    FLOOR_LIT),
    T_CORRIDOR: (CORRIDOR_DARK, CORRIDOR_LIT),
    T_DOOR:     ((60, 40, 20),  (140, 100,  50)),
    T_STAIRS:   ((20, 80, 40),  ( 60, 200, 100)),
}


# ─────────────────────────────────────────────────────────────────────────────
# Best Floor Persistence
# ─────────────────────────────────────────────────────────────────────────────

def load_best_floor() -> int:
    """Read highest reached floor from SAVE_FILE; defaults to 1."""
    if not os.path.exists(SAVE_FILE):
        return 1
    try:
        with open(SAVE_FILE, "r", encoding="utf-8") as f:
            return max(1, int(f.read().strip()))
    except (ValueError, IOError):
        return 1


def save_best_floor(floor: int) -> bool:
    """Write floor to SAVE_FILE if higher than current record. Returns True if record set."""
    best = load_best_floor()
    if floor > best:
        try:
            with open(SAVE_FILE, "w", encoding="utf-8") as f:
                f.write(str(floor))
            return True
        except IOError:
            pass
    return False


# ─────────────────────────────────────────────────────────────────────────────
# Fullscreen Display Support
# ─────────────────────────────────────────────────────────────────────────────

def toggle_fullscreen(current_fullscreen: bool):
    """Toggle between fullscreen and windowed display mode cleanly."""
    new_state = not current_fullscreen
    flags = (pygame.FULLSCREEN | pygame.SCALED) if new_state else (pygame.SCALED | pygame.RESIZABLE)
    try:
        new_screen = pygame.display.set_mode((SCREEN_W, SCREEN_H), flags)
    except pygame.error:
        fallback_flags = pygame.FULLSCREEN if new_state else 0
        new_screen = pygame.display.set_mode((SCREEN_W, SCREEN_H), fallback_flags)
    return new_screen, new_state


# ─────────────────────────────────────────────────────────────────────────────
# Particle Effects (Screen Juice)
# ─────────────────────────────────────────────────────────────────────────────

class Particle:
    """Lightweight 2D visual particle with fading and shrinking."""

    def __init__(
        self,
        x: float, y: float,
        vx: float, vy: float,
        colour: tuple,
        life: int = 24,
        size: int = 3,
    ):
        self.x        = x
        self.y        = y
        self.vx       = vx
        self.vy       = vy
        self.colour   = colour
        self.life     = life
        self.max_life = life
        self.size     = size

    def update(self) -> bool:
        """Advance position and decay life; returns True while alive."""
        self.x += self.vx
        self.y += self.vy
        self.vx *= 0.93
        self.vy *= 0.93
        self.life -= 1
        return self.life > 0

    def draw(self, surface: pygame.Surface, camera) -> None:
        sx, sy = camera.apply(self.x, self.y)
        progress = max(0.0, self.life / self.max_life)
        cur_sz = max(1, int(self.size * progress))
        pygame.draw.circle(surface, self.colour, (sx, sy), cur_sz)


def emit_particles(
    particles: list,
    x: float, y: float,
    colour: tuple,
    count: int = 10,
    speed: float = 2.5,
    life: int = 22,
    size: int = 3,
) -> None:
    """Scatter a burst of particles radiating from (x, y)."""
    for _ in range(count):
        ang = random.uniform(0, 2 * math.pi)
        spd = random.uniform(speed * 0.3, speed)
        vx = math.cos(ang) * spd
        vy = math.sin(ang) * spd
        particles.append(
            Particle(x, y, vx, vy, colour, life=random.randint(max(8, life // 2), life), size=size)
        )


# ─────────────────────────────────────────────────────────────────────────────
# Camera with Screen Shake
# ─────────────────────────────────────────────────────────────────────────────

class Camera:
    """Smooth-following viewport converter with directional screen shake."""

    def __init__(self, world_w: int, world_h: int):
        self.x        = 0.0
        self.y        = 0.0
        self.world_w  = world_w
        self.world_h  = world_h
        self.shake_mag   = 0.0
        self.shake_timer = 0
        self.shake_ox    = 0.0
        self.shake_oy    = 0.0

    def add_shake(self, magnitude: float, duration_ms: int = 150) -> None:
        """Trigger or amplify screen shake."""
        self.shake_mag   = max(self.shake_mag, magnitude)
        self.shake_timer = max(self.shake_timer, duration_ms)

    def update_shake(self, dt_ms: int) -> None:
        """Dampen shake timer and compute jitter offset."""
        if self.shake_timer > 0:
            self.shake_timer -= dt_ms
            self.shake_ox = random.uniform(-self.shake_mag, self.shake_mag)
            self.shake_oy = random.uniform(-self.shake_mag, self.shake_mag)
            self.shake_mag *= 0.88
        else:
            self.shake_mag = 0.0
            self.shake_ox  = 0.0
            self.shake_oy  = 0.0

    def clamp(self) -> None:
        self.x = max(0.0, min(self.x, float(max(0, self.world_w - SCREEN_W))))
        self.y = max(0.0, min(self.y, float(max(0, self.world_h - SCREEN_H))))

    def centre_on(self, tc: int, tr: int) -> None:
        self.x = tc * TILE - SCREEN_W // 2 + TILE // 2
        self.y = tr * TILE - SCREEN_H // 2 + TILE // 2
        self.clamp()

    def follow(self, px: float, py: float) -> None:
        self.x += (px - SCREEN_W / 2 - self.x) * 0.12
        self.y += (py - SCREEN_H / 2 - self.y) * 0.12
        self.clamp()

    def apply(self, wx: float, wy: float):
        """World-pixel -> Screen-pixel with active shake offset."""
        return int(wx - self.x + self.shake_ox), int(wy - self.y + self.shake_oy)

    def visible_tile_range(self):
        c0 = max(0,    int(self.x) // TILE - 1)
        r0 = max(0,    int(self.y) // TILE - 1)
        c1 = min(COLS, c0 + SCREEN_W // TILE + 3)
        r1 = min(ROWS, r0 + SCREEN_H // TILE + 3)
        return c0, r0, c1, r1


# ─────────────────────────────────────────────────────────────────────────────
# Message Log
# ─────────────────────────────────────────────────────────────────────────────

class MessageLog:
    """Displays fading gameplay feedback lines at the bottom-left."""

    DURATION = 200
    MAX_SHOW = 5

    def __init__(self):
        self._msgs: list = []

    def add(self, text: str) -> None:
        self._msgs.append([text, self.DURATION])
        if len(self._msgs) > self.MAX_SHOW * 2:
            self._msgs = self._msgs[-self.MAX_SHOW:]

    def update(self) -> None:
        self._msgs = [[t, f - 1] for t, f in self._msgs if f > 1]

    def draw(self, surface: pygame.Surface, font: pygame.font.Font) -> None:
        visible = [m for m in self._msgs if m[1] > 0][-self.MAX_SHOW:]
        y = SCREEN_H - 90
        for text, frames in reversed(visible):
            alpha = min(255, frames * 3)
            col   = (alpha, alpha, alpha)
            surface.blit(font.render(text, True, col), (8, y))
            y -= 17


# ─────────────────────────────────────────────────────────────────────────────
# Rendering Helpers
# ─────────────────────────────────────────────────────────────────────────────

def _blend_dim(dark: tuple, lit: tuple, t: float = 0.35) -> tuple:
    return tuple(int(d + (l - d) * t) for d, l in zip(dark, lit))


def _draw_tile(surface, tt, sx, sy, lit: bool) -> None:
    dark_c, lit_c = TILE_COLOURS.get(tt, (DARK_BG, DARK_BG))
    col = lit_c if lit else dark_c
    pygame.draw.rect(surface, col, (sx, sy, TILE, TILE))
    if lit and tt in (T_FLOOR, T_CORRIDOR):
        d = tuple(max(0, c - 8) for c in col)
        pygame.draw.rect(surface, d, (sx, sy, TILE, TILE), 1)


def _draw_dungeon(
    surface: pygame.Surface,
    dungeon: Dungeon,
    camera: Camera,
    lit: set,
    explored: set,
) -> None:
    """Render 3-state fog-of-war tiles (lit, explored-dim, unseen)."""
    c0, r0, c1, r1 = camera.visible_tile_range()
    for row in range(r0, r1):
        for col in range(c0, c1):
            tt = dungeon.grid[row][col]
            if tt == T_EMPTY:
                continue
            in_lit = (col, row) in lit
            in_exp = (col, row) in explored
            if not in_lit and not in_exp:
                continue
            sx, sy = camera.apply(col * TILE, row * TILE)
            if in_lit:
                _draw_tile(surface, tt, sx, sy, lit=True)
            else:
                dark_c, lit_c = TILE_COLOURS.get(tt, (DARK_BG, DARK_BG))
                pygame.draw.rect(surface, _blend_dim(dark_c, lit_c), (sx, sy, TILE, TILE))

    # Staircase glow and platform tint
    ec, er = dungeon.exit_pos
    if (ec, er) in lit:
        sx, sy = camera.apply(ec * TILE, er * TILE)
        pulse  = abs(pygame.time.get_ticks() % 1000 - 500) / 500
        gr     = int(TILE * 0.7 + pulse * TILE * 0.3)
        gs     = pygame.Surface((gr * 2, gr * 2), pygame.SRCALPHA)
        pygame.draw.circle(gs, (60, 255, 120, 55), (gr, gr), gr)
        surface.blit(gs, (sx + TILE // 2 - gr, sy + TILE // 2 - gr))

        for dr in range(-1, 2):
            for dc in range(-1, 2):
                px2, py2 = camera.apply((ec + dc) * TILE, (er + dr) * TILE)
                if dr == 0 and dc == 0:
                    continue
                tint = pygame.Surface((TILE, TILE), pygame.SRCALPHA)
                tint.fill((40, 180, 80, 35))
                surface.blit(tint, (px2, py2))


def _draw_interactables(
    surface: pygame.Surface,
    interactables: list,
    camera: Camera,
    lit: set,
) -> None:
    """Draw all world interactables (chests, shrines) if in illuminated tiles."""
    for obj in interactables:
        if (obj.col, obj.row) in lit:
            obj.draw(surface, camera, lit=True)


def _compute_lit(dungeon: Dungeon, pc: int, pr: int, radius: int = 7) -> set:
    lit = set()
    for dr in range(-radius, radius + 1):
        for dc in range(-radius, radius + 1):
            if dr * dr + dc * dc <= radius * radius:
                c, r = pc + dc, pr + dr
                if 0 <= c < COLS and 0 <= r < ROWS:
                    lit.add((c, r))
    return lit


# ─────────────────────────────────────────────────────────────────────────────
# Combat & Interaction Mechanics
# ─────────────────────────────────────────────────────────────────────────────

def _check_projectile_hits(
    projectiles: list,
    player: Player,
    enemies: list,
    particles: list,
    camera: Camera,
    stats: dict,
) -> None:
    """Test live projectiles against targets, trigger particle sparks and shake."""
    for proj in projectiles:
        if not proj.alive:
            continue
        pr = proj.get_rect()
        if proj.owner == "player":
            for enemy in enemies:
                if enemy.alive and pr.colliderect(enemy.get_rect()):
                    enemy.take_damage(proj.damage)
                    enemy.hit_flash = 6
                    proj.alive = False
                    sfx.play_hit()
                    emit_particles(particles, proj.x, proj.y, (200, 230, 255), count=7, speed=2.2)
                    camera.add_shake(2.5, 90)
                    break
        elif player.alive and pr.colliderect(player.get_rect()):
            player.take_damage(proj.damage)
            proj.alive = False
            sfx.play_hurt()
            emit_particles(particles, player.x, player.y, (220, 60, 60), count=9, speed=2.8)
            camera.add_shake(6.0, 180)


def _check_loot_pickup(
    world_loot: list,
    player: Player,
    inventory: Inventory,
    msglog: MessageLog,
    particles: list,
) -> None:
    pr = player.get_rect()
    for loot in world_loot:
        if loot.alive and pr.colliderect(loot.get_rect()):
            if inventory.add(loot.item):
                loot.alive = False
                emit_particles(particles, loot.x, loot.y, loot.item.colour, count=8, speed=1.8, size=2)
                if loot.item.kind == "coin":
                    sfx.play_coin()
                    msglog.add(f"+{loot.item.value} {loot.item.name}")
                elif loot.item.kind == "key":
                    sfx.play_coin()
                    msglog.add(f"Found {loot.item.name}! Use [E] on locked doors.")
                elif loot.item.kind == "weapon":
                    sfx.play_equip()
                    msglog.add(f"Found {loot.item.name} (+{loot.item.value} dmg)")
                else:
                    sfx.play_heal()
                    msglog.add(f"Found {loot.item.name}")


def get_nearest_interactable(interactables: list, player: Player) -> "Interactable | None":
    """Find the closest valid interactable within reach of the player."""
    nearby = [
        obj for obj in interactables
        if obj.can_interact(player) and obj.dist_to(player.x, player.y) <= obj.radius
    ]
    if not nearby:
        return None
    return min(nearby, key=lambda o: o.dist_to(player.x, player.y))


def draw_interaction_prompt(
    surface: pygame.Surface,
    camera: Camera,
    font_med: pygame.font.Font,
    font_small: pygame.font.Font,
    interactable: Interactable,
    player: Player,
) -> None:
    """
    Render a polished floating tooltip prompt directly above the nearby interactable.
    Animates with a subtle vertical bob to attract the player's attention.
    """
    key_label, action_text, subtext = interactable.get_prompt(player)
    sx, sy = camera.apply(interactable.x, interactable.y)

    # Floating bob animation
    bob = int(math.sin(pygame.time.get_ticks() * 0.007) * 3)
    py = sy - 38 + bob

    key_txt = font_med.render(f"[{key_label}]", True, UI_HIGHLIGHT)
    act_txt = font_med.render(action_text, True, (245, 245, 255))

    pad_x = 9
    pad_y = 4
    content_w = key_txt.get_width() + 6 + act_txt.get_width()
    box_w = content_w + pad_x * 2
    box_h = max(key_txt.get_height(), act_txt.get_height()) + pad_y * 2

    # Center horizontally on object
    px = sx - box_w // 2

    # Translucent rounded banner
    pill = pygame.Surface((box_w, box_h), pygame.SRCALPHA)
    pill.fill((16, 14, 26, 225))
    pygame.draw.rect(pill, (110, 100, 150), (0, 0, box_w, box_h), 1, border_radius=4)
    pill.blit(key_txt, (pad_x, pad_y))
    pill.blit(act_txt, (pad_x + key_txt.get_width() + 6, pad_y))
    surface.blit(pill, (px, py))

    # Little pointer triangle pointing downward at object
    arrow = [
        (sx - 4, py + box_h),
        (sx + 4, py + box_h),
        (sx, py + box_h + 4)
    ]
    pygame.draw.polygon(surface, (110, 100, 150), arrow)


# ─────────────────────────────────────────────────────────────────────────────
# HUD & UI Screens
# ─────────────────────────────────────────────────────────────────────────────

def _draw_hud(
    surface: pygame.Surface,
    font: pygame.font.Font,
    dungeon: Dungeon,
    player: Player,
    enemies: list,
    inventory: Inventory,
    best_floor: int,
) -> None:
    alive = sum(1 for e in enemies if e.alive)
    eq = inventory.equipped_weapon
    wep_str = eq.name if eq else "Bare Hands"

    # ── Left HUD: Separated Player Status (Weapons, Healing, Keyring, Valuables) ──
    hud_w, hud_h = 220, 116
    hud_bg = pygame.Surface((hud_w, hud_h), pygame.SRCALPHA)
    hud_bg.fill((16, 14, 26, 200))
    surface.blit(hud_bg, (10, 8))
    pygame.draw.rect(surface, (70, 60, 100), (10, 8, hud_w, hud_h), 1, border_radius=4)

    left_lines = [
        (f"Floor {dungeon.floor}  (Best: {best_floor})", UI_HIGHLIGHT),
        (f"⚔️ Weapon : {wep_str} (+{player.damage_bonus})", (240, 215, 100)),
        (f"🧪 Potions: {inventory.potion_count()}  [Q] Heal", (110, 230, 140)),
        (f"🗝️ Keys   : {inventory.key_count()}", KEY_COL),
        (f"💰 Coins  : {inventory.coins}", COIN_COL),
        (f"👾 Enemies: {alive} remaining", (220, 130, 130)),
    ]
    ly = 13
    for txt, col in left_lines:
        surface.blit(font.render(txt, True, col), (18, ly))
        ly += 17

    # ── Right HUD: Controls Reference ─────────────────────────────────────────
    lines = [
        "[Space] Melee",
        "[F]     Shoot",
        "[Q]     Quick-Heal",
        "[E]     Interact/Shop",
        "[I]     Inventory",
        "[M]     Minimap",
        "[C]     Controls",
        "[F11]   Fullscreen",
        "[ESC]   Menu",
    ]
    x, y = SCREEN_W - 170, 8
    for line in lines:
        col = UI_HIGHLIGHT if line.startswith("[") else UI_TEXT
        surface.blit(font.render(line, True, col), (x, y))
        y += 17

    # ── HP bar ────────────────────────────────────────────────────────────────
    bw, bh = 220, 15
    bx = (SCREEN_W - bw) // 2
    by = SCREEN_H - bh - 8
    pct = max(0.0, player.hp / player.max_hp)
    pygame.draw.rect(surface, (60, 20, 20),   (bx - 1, by - 1, bw + 2, bh + 2))
    pygame.draw.rect(surface, (80,  30,  30), (bx, by, bw, bh))
    pygame.draw.rect(surface, (80, 220, 80),  (bx, by, int(bw * pct), bh))
    pygame.draw.rect(surface, (150, 150, 150), (bx, by, bw, bh), 1)
    surface.blit(
        font.render(f"HP  {player.hp} / {player.max_hp}", True, UI_TEXT),
        (bx + bw + 8, by),
    )


def _draw_shop_modal(
    surface: pygame.Surface,
    font_med: pygame.font.Font,
    font_small: pygame.font.Font,
    inventory: Inventory,
    player: Player,
) -> None:
    """Render the Wandering Merchant's shop modal to spend coins."""
    pw, ph = 480, 360
    px = (SCREEN_W - pw) // 2
    py = (SCREEN_H - ph) // 2

    panel = pygame.Surface((pw, ph), pygame.SRCALPHA)
    panel.fill((16, 14, 28, 240))
    pygame.draw.rect(panel, (180, 150, 70), (0, 0, pw, ph), 2, border_radius=6)

    title = font_med.render("🧙 DUNGEON MERCHANT SHOP", True, (255, 220, 90))
    panel.blit(title, (pw // 2 - title.get_width() // 2, 14))
    sub = font_small.render('"Greetings, traveler! Got shiny coins to trade?"', True, (170, 160, 190))
    panel.blit(sub, (pw // 2 - sub.get_width() // 2, 38))

    pygame.draw.line(panel, (75, 65, 105), (14, 58), (pw - 14, 58))
    coin_txt = font_med.render(f"Your Treasury: {inventory.coins} Gold Coins", True, COIN_COL)
    panel.blit(coin_txt, (20, 64))
    pygame.draw.line(panel, (75, 65, 105), (14, 88), (pw - 14, 88))

    wares = [
        ("1", "Minor Potion",    "+20 HP Recovery",           20,  (60, 220, 100)),
        ("2", "Potion",          "+40 HP Recovery",           45,  (60, 220, 100)),
        ("3", "Major Potion",    "+70 HP Recovery",           80,  (60, 220, 100)),
        ("4", "Dungeon Key",     "Opens Vault Doors",         60,  KEY_COL),
        ("5", "Iron Cleaver",    "Weapon (+12 Damage)",       75,  WEAPON_COL),
        ("6", "Heart Container", "+25 Max HP & Full Heal",   100,  (255, 100, 140)),
    ]

    y = 96
    for key, name, desc, price, col in wares:
        can_afford = inventory.coins >= price
        bg_col = (35, 30, 55) if can_afford else (25, 22, 35)
        text_col = UI_TEXT if can_afford else (110, 100, 120)
        price_col = COIN_COL if can_afford else (130, 100, 70)

        pygame.draw.rect(panel, bg_col, (14, y, pw - 28, 28), border_radius=4)
        pygame.draw.rect(panel, (70, 60, 95), (14, y, pw - 28, 28), 1, border_radius=4)

        k_lbl = font_small.render(f"[{key}]", True, UI_HIGHLIGHT if can_afford else (110, 100, 120))
        n_lbl = font_small.render(f"{name:<16}", True, col if can_afford else (120, 115, 130))
        d_lbl = font_small.render(desc, True, text_col)
        p_lbl = font_small.render(f"{price} Coins", True, price_col)

        panel.blit(k_lbl, (22, y + 5))
        panel.blit(n_lbl, (55, y + 5))
        panel.blit(d_lbl, (185, y + 5))
        panel.blit(p_lbl, (pw - p_lbl.get_width() - 25, y + 5))
        y += 33

    pygame.draw.line(panel, (75, 65, 105), (14, ph - 38), (pw - 14, ph - 38))
    foot = font_small.render("Press [1-6] to Buy    [E], [ESC] or [SPACE] to Close", True, (160, 150, 185))
    panel.blit(foot, (pw // 2 - foot.get_width() // 2, ph - 26))

    surface.blit(panel, (px, py))


def _handle_shop_purchase(key_num: int, inventory: Inventory, player: Player, msglog: MessageLog, particles: list) -> None:
    """Process a trade transaction at the Merchant NPC."""
    prices = {
        1: (20, "Minor Potion", lambda: inventory.add(Item("Minor Potion", KIND_POTION, 20, POTION_COL))),
        2: (45, "Potion", lambda: inventory.add(Item("Potion", KIND_POTION, 40, POTION_COL))),
        3: (80, "Major Potion", lambda: inventory.add(Item("Major Potion", KIND_POTION, 70, POTION_COL))),
        4: (60, "Dungeon Key", lambda: inventory.add(make_key())),
        5: (75, "Iron Cleaver", lambda: inventory.add(Item("Iron Cleaver", KIND_WEAPON, 12, WEAPON_COL))),
        6: (100, "Heart Container", None),
    }
    if key_num not in prices:
        return
    price, name, action = prices[key_num]
    if inventory.coins < price:
        sfx.play_door_locked()
        msglog.add(f"Merchant: 'Not enough coins! You need {price} gold.'")
        return

    # Deduct coins
    inventory.coins -= price
    sfx.play_coin()

    px = getattr(player, "x", 0)
    py = getattr(player, "y", 0)
    if key_num == 6:
        player.max_hp += 25
        player.hp = player.max_hp
        sfx.play_heal()
        msglog.add(f"Bought {name}! Max HP permanently increased to {player.max_hp}!")
        emit_particles(particles, px, py, (255, 100, 140), count=25, speed=3.2, size=4)
    else:
        success = action()
        if success:
            msglog.add(f"Merchant: 'Pleasure doing business! Bought {name}.'")
            emit_particles(particles, px, py, (255, 215, 60), count=18, speed=2.6, size=3)
            if "Potion" in name:
                sfx.play_heal()
            elif "Key" in name:
                sfx.play_coin()
            elif "Weapon" in name or "Cleaver" in name:
                sfx.play_equip()
        else:
            inventory.coins += price
            sfx.play_door_locked()
            msglog.add("Inventory pack is full! Make room first.")


def _draw_menu_screen(
    surface: pygame.Surface,
    font_large: pygame.font.Font,
    font_med: pygame.font.Font,
    font_small: pygame.font.Font,
    best_floor: int,
) -> None:
    """Render the retro dungeon start menu."""
    surface.fill(DARK_BG)

    # Decorative background dungeon grid
    for r in range(0, SCREEN_H, TILE):
        pygame.draw.line(surface, (18, 15, 28), (0, r), (SCREEN_W, r))
    for c in range(0, SCREEN_W, TILE):
        pygame.draw.line(surface, (18, 15, 28), (c, 0), (c, SCREEN_H))

    # Title pulse
    pulse = (pygame.time.get_ticks() % 1200) / 1200.0
    glow_col = (100 + int(30 * math.sin(pulse * math.pi * 2)), 200, 255)

    title = font_large.render(TITLE.upper(), True, glow_col)
    sub   = font_med.render("Procedural Rogue-lite Crawler", True, (160, 150, 190))
    best  = font_med.render(f"🏆 Best Floor Reached: {best_floor}", True, COIN_COL)

    cx = SCREEN_W // 2
    surface.blit(title, (cx - title.get_width() // 2, 130))
    surface.blit(sub,   (cx - sub.get_width() // 2, 200))
    surface.blit(best,  (cx - best.get_width() // 2, 245))

    # Menu choices
    opts = [
        ("[SPACE] or [ENTER]  Start Adventure", UI_HIGHLIGHT),
        ("[C]                  Controls & Guide", UI_TEXT),
        ("[F11]                Toggle Fullscreen", (150, 200, 255)),
        ("[ESC]                Exit Game",        (180, 120, 120)),
    ]
    y = 315
    for label, col in opts:
        btn = font_med.render(label, True, col)
        bx = cx - btn.get_width() // 2
        bg = pygame.Surface((btn.get_width() + 24, btn.get_height() + 10), pygame.SRCALPHA)
        bg.fill((25, 22, 40, 210))
        surface.blit(bg, (bx - 12, y - 5))
        pygame.draw.rect(surface, (70, 60, 100), (bx - 12, y - 5, btn.get_width() + 24, btn.get_height() + 10), 1)
        surface.blit(btn, (bx, y))
        y += 42

    foot = font_small.render("No external assets • Built with Pygame", True, (90, 85, 110))
    surface.blit(foot, (cx - foot.get_width() // 2, SCREEN_H - 30))


def _draw_controls_modal(
    surface: pygame.Surface,
    font_med: pygame.font.Font,
    font_small: pygame.font.Font,
) -> None:
    """Overlay displaying complete controls and gameplay guide."""
    ov = pygame.Surface((SCREEN_W, SCREEN_H), pygame.SRCALPHA)
    ov.fill((8, 6, 14, 225))
    surface.blit(ov, (0, 0))

    pw, ph = 540, 440
    px = (SCREEN_W - pw) // 2
    py = (SCREEN_H - ph) // 2
    panel = pygame.Surface((pw, ph), pygame.SRCALPHA)
    panel.fill((20, 18, 35, 240))
    pygame.draw.rect(panel, (90, 80, 130), (0, 0, pw, ph), 2)

    title = font_med.render("CONTROLS & SURVIVAL GUIDE", True, UI_HIGHLIGHT)
    panel.blit(title, (pw // 2 - title.get_width() // 2, 16))
    pygame.draw.line(panel, (80, 70, 120), (16, 48), (pw - 16, 48))

    controls = [
        ("WASD / Arrows", "Move adventurer (slide along walls)"),
        ("Space",         "Melee attack (wide sweep in facing direction)"),
        ("F",             "Ranged attack (shoot glowing magic bolt)"),
        ("Q / H",         "Quick-Heal (drinks best potion in combat)"),
        ("E",             "Interact (trade with Merchant NPC, chests, doors)"),
        ("I",             "Toggle inventory (weapons, potions, keyring)"),
        ("M",             "Toggle minimap (tracks explored rooms & NPC)"),
        ("F11 / Alt+Enter","Toggle fullscreen display mode"),
        ("ESC",           "Return to menu / exit game"),
    ]
    y = 66
    for key, desc in controls:
        k_txt = font_small.render(f"{key:<15}", True, UI_HIGHLIGHT)
        d_txt = font_small.render(desc, True, UI_TEXT)
        panel.blit(k_txt, (24, y))
        panel.blit(d_txt, (180, y))
        y += 30

    pygame.draw.line(panel, (80, 70, 120), (16, ph - 64), (pw - 16, ph - 64))
    tip = font_small.render("Tip: Spend coins at the Merchant NPC to buy potions, keys, weapons & Max HP!", True, (160, 220, 140))
    panel.blit(tip, (pw // 2 - tip.get_width() // 2, ph - 52))
    close = font_small.render("Press [C], [SPACE] or [ESC] to Close", True, (180, 170, 200))
    panel.blit(close, (pw // 2 - close.get_width() // 2, ph - 28))

    surface.blit(panel, (px, py))


def _draw_game_over_screen(
    surface: pygame.Surface,
    font_large: pygame.font.Font,
    font_med: pygame.font.Font,
    floor: int,
    coins: int,
    kills: int,
    best_floor: int,
    new_record: bool,
) -> None:
    """Render the game-over screen with session stats and record status."""
    ov = pygame.Surface((SCREEN_W, SCREEN_H), pygame.SRCALPHA)
    ov.fill((10, 4, 10, 215))
    surface.blit(ov, (0, 0))

    cx = SCREEN_W // 2
    title = font_large.render("YOU PERISHED", True, (230, 40, 40))
    surface.blit(title, (cx - title.get_width() // 2, 120))

    if new_record:
        rec_txt = font_med.render("★ NEW BEST FLOOR RECORD REACHED! ★", True, (255, 225, 60))
        surface.blit(rec_txt, (cx - rec_txt.get_width() // 2, 185))

    stats = [
        f"Floor Reached   : {floor}",
        f"Coins Collected : {coins}",
        f"Enemies Slain   : {kills}",
        f"All-Time Record : Floor {best_floor}",
    ]
    y = 230
    for line in stats:
        txt = font_med.render(line, True, UI_TEXT)
        surface.blit(txt, (cx - 140, y))
        y += 28

    opts = [
        ("[SPACE] or [R]  Play Again", UI_HIGHLIGHT),
        ("[M]             Main Menu",  UI_TEXT),
        ("[ESC]           Quit",       (180, 120, 120)),
    ]
    y = 380
    for label, col in opts:
        btn = font_med.render(label, True, col)
        surface.blit(btn, (cx - btn.get_width() // 2, y))
        y += 36


# ─────────────────────────────────────────────────────────────────────────────
# Game State Factory
# ─────────────────────────────────────────────────────────────────────────────

def _new_game(floor: int):
    """Instantiate fresh dungeon, player, and entities for a floor."""
    dungeon       = generate_dungeon(floor)
    player        = Player(*dungeon.player_start)
    enemies       = spawn_enemies(dungeon)
    interactables = spawn_interactables(dungeon)
    projectiles   = []
    world_loot    = []
    minimap       = Minimap()
    return dungeon, player, enemies, interactables, projectiles, world_loot, minimap


# ─────────────────────────────────────────────────────────────────────────────
# Main Loop
# ─────────────────────────────────────────────────────────────────────────────

def main() -> None:
    """Entry point — Phase 4 complete game state machine."""
    pygame.init()
    sfx.init_sfx()
    try:
        screen = pygame.display.set_mode((SCREEN_W, SCREEN_H), pygame.SCALED | pygame.RESIZABLE)
    except pygame.error:
        screen = pygame.display.set_mode((SCREEN_W, SCREEN_H))
    is_fullscreen = False
    pygame.display.set_caption(TITLE)
    clock  = pygame.time.Clock()

    font_small = pygame.font.SysFont("consolas", 14)
    font_med   = pygame.font.SysFont("consolas", 18, bold=True)
    font_large = pygame.font.SysFont("consolas", 46, bold=True)

    state      = STATE_MENU
    best_floor = load_best_floor()
    floor      = 1
    total_kills= 0
    new_record = False

    (dungeon, player, enemies,
     interactables, projectiles, world_loot,
     minimap) = _new_game(floor)

    inventory  = Inventory()
    msglog     = MessageLog()
    particles  = []
    camera     = Camera(COLS * TILE, ROWS * TILE)
    camera.centre_on(*dungeon.player_start)

    explored   : set  = set()
    show_inv   : bool = False
    show_map   : bool = False
    show_shop  : bool = False

    while True:
        dt_ms = clock.tick(FPS)
        camera.update_shake(dt_ms)

        # Update closest interactable target for contextual prompts
        active_interactable = None
        if state == STATE_PLAYING and player.alive:
            active_interactable = get_nearest_interactable(interactables, player)

        # ── Events ───────────────────────────────────────────────────────────
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()

            if event.type == pygame.KEYDOWN:
                k = event.key

                # Universal Fullscreen Toggle (F11 or Alt+Enter)
                if k == pygame.K_F11 or (k == pygame.K_RETURN and (pygame.key.get_mods() & pygame.KMOD_ALT)):
                    screen, is_fullscreen = toggle_fullscreen(is_fullscreen)
                    continue

                # ── STATE: MENU ──────────────────────────────────────────────
                if state == STATE_MENU:
                    if k in (pygame.K_SPACE, pygame.K_RETURN):
                        floor = 1
                        total_kills = 0
                        new_record = False
                        (dungeon, player, enemies,
                         interactables, projectiles, world_loot,
                         minimap) = _new_game(floor)
                        inventory = Inventory()
                        msglog = MessageLog()
                        particles.clear()
                        explored = set()
                        show_inv = show_map = False
                        camera.centre_on(*dungeon.player_start)
                        msglog.add("Enter the dungeon… Explore rooms and find the stairs!")
                        state = STATE_PLAYING
                    elif k == pygame.K_c:
                        state = STATE_CONTROLS
                    elif k == pygame.K_ESCAPE:
                        pygame.quit()
                        sys.exit()

                # ── STATE: CONTROLS ──────────────────────────────────────────
                elif state == STATE_CONTROLS:
                    if k in (pygame.K_ESCAPE, pygame.K_c, pygame.K_SPACE, pygame.K_RETURN):
                        state = STATE_MENU

                # ── STATE: GAME OVER ─────────────────────────────────────────
                elif state == STATE_GAMEOVER:
                    if k in (pygame.K_SPACE, pygame.K_r, pygame.K_RETURN):
                        floor = 1
                        total_kills = 0
                        new_record = False
                        (dungeon, player, enemies,
                         interactables, projectiles, world_loot,
                         minimap) = _new_game(floor)
                        inventory = Inventory()
                        msglog = MessageLog()
                        particles.clear()
                        explored = set()
                        show_inv = show_map = False
                        camera.centre_on(*dungeon.player_start)
                        msglog.add("A new soul enters the depths…")
                        state = STATE_PLAYING
                    elif k == pygame.K_m:
                        state = STATE_MENU
                    elif k == pygame.K_ESCAPE:
                        pygame.quit()
                        sys.exit()

                # ── STATE: PLAYING ───────────────────────────────────────────
                elif state == STATE_PLAYING:
                    if k == pygame.K_ESCAPE:
                        if show_shop:
                            show_shop = False
                        elif show_inv:
                            show_inv = False
                        elif show_map:
                            show_map = False
                        else:
                            state = STATE_MENU
                        continue

                    # Shop interaction mode
                    if show_shop:
                        if pygame.K_1 <= k <= pygame.K_6:
                            key_num = k - pygame.K_1 + 1
                            _handle_shop_purchase(key_num, inventory, player, msglog, particles)
                        elif k in (pygame.K_e, pygame.K_SPACE, pygame.K_RETURN):
                            show_shop = False
                        continue

                    # UI toggles
                    if k == pygame.K_i:
                        show_inv = not show_inv
                        show_map = show_shop = False
                    if k == pygame.K_m:
                        show_map = not show_map
                        show_inv = show_shop = False
                    if k == pygame.K_c:
                        state = STATE_CONTROLS

                    # Inventory use (1–9)
                    if show_inv and pygame.K_1 <= k <= pygame.K_9:
                        idx = k - pygame.K_1
                        msg = inventory.use(idx, player)
                        if msg:
                            msglog.add(msg)
                            emit_particles(particles, player.x, player.y, (80, 240, 120), count=10, speed=2.0)

                    # Quick-Heal in active gameplay ([Q] or [H])
                    if not show_inv and not show_shop and k in (pygame.K_q, pygame.K_h):
                        msg = inventory.quick_heal(player)
                        if msg:
                            msglog.add(msg)
                            if "+" in msg or "HP" in msg:
                                emit_particles(particles, player.x, player.y, (80, 240, 120), count=14, speed=2.4)

                    # Attacks & Interactions (only when inventory & shop are closed)
                    if not show_inv and not show_shop:
                        if k == pygame.K_SPACE:
                            swung, hits = player.try_melee(enemies)
                            if swung:
                                sfx.play_melee()
                                fx = player.x + player.facing[0] * 20
                                fy = player.y + player.facing[1] * 20
                                emit_particles(particles, fx, fy, (240, 230, 160), count=5, speed=1.8, size=2)
                                if hits:
                                    sfx.play_hit()
                                    camera.add_shake(4.0, 120)
                                    for h in hits:
                                        emit_particles(particles, h.x, h.y, (255, 220, 80), count=9, speed=2.5)

                        if k == pygame.K_f:
                            proj = player.try_ranged()
                            if proj:
                                sfx.play_shoot()
                                projectiles.append(proj)
                                emit_particles(particles, player.x, player.y, (120, 200, 255), count=5, speed=1.6, size=2)

                        # Contextual interaction key (E)
                        if k == pygame.K_e and active_interactable:
                            if isinstance(active_interactable, MerchantNPC):
                                show_shop = not show_shop
                                show_inv = show_map = False
                                sfx.play_coin()
                                msglog.add("Merchant: 'Greetings! Spend your hard-earned coins here.'")
                            elif isinstance(active_interactable, StairsCheckpoint):
                                sfx.play_descend()
                                floor += 1
                                if save_best_floor(floor):
                                    best_floor = floor
                                    new_record = True
                                (dungeon, player_new, enemies,
                                 interactables, projectiles, world_loot,
                                 minimap) = _new_game(floor)
                                player_new.hp           = player.hp
                                player_new.damage_bonus = player.damage_bonus
                                player = player_new
                                explored = set()
                                show_inv = show_map = show_shop = False
                                camera.centre_on(*dungeon.player_start)
                                camera.add_shake(4.5, 200)
                                emit_particles(particles, player.x, player.y, (60, 255, 120), count=25, speed=3.5, size=4)
                                msglog.add(f"▼ Descended to Floor {floor}!")
                            else:
                                active_interactable.interact({
                                    "player": player,
                                    "floor": floor,
                                    "world_loot": world_loot,
                                    "particles": particles,
                                    "camera": camera,
                                    "msglog": msglog,
                                    "emit_fn": emit_particles,
                                    "inventory": inventory,
                                    "dungeon": dungeon,
                                })

        # ── Update Logic ─────────────────────────────────────────────────────
        if state == STATE_PLAYING:
            if not show_inv and not show_shop:
                keys = pygame.key.get_pressed()
                player.handle_input(keys, dungeon, dt_ms)

            # Player hit reactions
            if player.just_hit:
                camera.add_shake(7.0, 220)
                emit_particles(particles, player.x, player.y, (220, 40, 40), count=12, speed=3.0)
                sfx.play_hurt()
                player.just_hit = False

            # Check player death
            if not player.alive:
                if save_best_floor(floor):
                    best_floor = floor
                    new_record = True
                emit_particles(particles, player.x, player.y, (220, 40, 40), count=30, speed=4.0, size=4)
                camera.add_shake(9.0, 350)
                sfx.play_game_over()
                state = STATE_GAMEOVER

            # Update enemies
            for enemy in enemies:
                if enemy.alive:
                    enemy.update(player, dungeon, projectiles, dt_ms)

            # Update projectiles & collision
            for proj in projectiles:
                proj.update(dungeon.grid)
            _check_projectile_hits(projectiles, player, enemies, particles, camera, None)

            # Dead enemies: drop loot, emit death particles, track stats
            for enemy in enemies:
                if not enemy.alive:
                    total_kills += 1
                    sfx.play_enemy_death()
                    emit_particles(particles, enemy.x, enemy.y, enemy.colour, count=16, speed=3.0, size=3)
                    camera.add_shake(2.0, 80)
                    drop = random_drop(floor)
                    if drop:
                        world_loot.append(WorldLoot(enemy.x, enemy.y, drop))

            # Prune dead entities
            enemies     = [e for e in enemies     if e.alive]
            projectiles = [p for p in projectiles if p.alive]

            # Loot auto-pickup
            _check_loot_pickup(world_loot, player, inventory, msglog, particles)
            world_loot = [l for l in world_loot if l.alive]

            # Follow camera
            camera.follow(player.x, player.y)

            # Fog of war
            pc  = int(player.x) // TILE
            pr  = int(player.y) // TILE
            lit = _compute_lit(dungeon, pc, pr, radius=7)
            explored |= lit
            minimap.update(lit)
            msglog.update()

        # Update particles (all states)
        particles = [p for p in particles if p.update()]

        # ── Rendering ────────────────────────────────────────────────────────
        if state == STATE_MENU:
            _draw_menu_screen(screen, font_large, font_med, font_small, best_floor)

        elif state == STATE_CONTROLS:
            _draw_menu_screen(screen, font_large, font_med, font_small, best_floor)
            _draw_controls_modal(screen, font_med, font_small)

        elif state in (STATE_PLAYING, STATE_GAMEOVER):
            screen.fill(DARK_BG)
            _draw_dungeon(screen, dungeon, camera, lit, explored)
            _draw_interactables(screen, interactables, camera, lit)

            # World loot
            for loot in world_loot:
                lc, lr = int(loot.x) // TILE, int(loot.y) // TILE
                if (lc, lr) in lit:
                    loot.draw(screen, camera)

            # Enemies in lit sight
            for enemy in enemies:
                if (int(enemy.x) // TILE, int(enemy.y) // TILE) in lit:
                    enemy.draw(screen, camera)

            # Projectiles
            for proj in projectiles:
                proj.draw(screen, camera)

            # Particles
            for p in particles:
                p.draw(screen, camera)

            # Player
            if player.alive:
                player.draw(screen, camera)

            # Floating contextual interaction prompt directly over target
            if active_interactable and player.alive and not show_inv and not show_shop:
                draw_interaction_prompt(screen, camera, font_med, font_small, active_interactable, player)

            # HUD & Message log
            _draw_hud(screen, font_small, dungeon, player, enemies, inventory, best_floor)
            msglog.draw(screen, font_small)

            if show_map:
                minimap.draw(screen, dungeon, player.x, player.y)

            if show_inv:
                draw_inventory_ui(screen, font_small, inventory)

            if show_shop:
                _draw_shop_modal(screen, font_med, font_small, inventory, player)

            if state == STATE_GAMEOVER:
                _draw_game_over_screen(
                    screen, font_large, font_med,
                    floor, inventory.coins, total_kills, best_floor, new_record
                )

        pygame.display.flip()


if __name__ == "__main__":
    main()
