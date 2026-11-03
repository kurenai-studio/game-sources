"""
entities.py  –  Phase 2
Player, Enemy (Chaser / Patroller / Shooter), and Projectile classes.

Public API
----------
spawn_enemies(dungeon) -> list[Enemy]
    Instantiate and return all enemies from dungeon.enemy_spawns.
"""

import math
import random

import pygame

from settings import (
    TILE, COLS, ROWS,
    PLAYER_COL, PLAYER_HP, PLAYER_SPEED, PLAYER_DAMAGE, PLAYER_RANGE,
    ENEMY_COL, ENEMY_STATS,
    HEALTH_BAR_FG, HEALTH_BAR_BG,
    FLOOR_HP_MULT, FLOOR_SPEED_MULT,
    CHEST_COL, CHEST_OPEN_COL, SHRINE_COL, SHRINE_USED_COL,
    UI_HIGHLIGHT, UI_TEXT,
    T_FLOOR, T_CORRIDOR, T_DOOR, T_STAIRS,
)
from dungeon import is_walkable
from inventory import chest_loot, WorldLoot, Item
import sfx

# Pixel radius used for circle-vs-wall collision checks
_ENTITY_RADIUS = TILE // 2 - 4


# ─────────────────────────────────────────────────────────────────────────────
# Internal movement helper
# ─────────────────────────────────────────────────────────────────────────────

def _can_move(grid, px: float, py: float, radius: int = 10, locked_doors: set = None) -> bool:
    """
    Return True if a circle of *radius* pixels centred at (px, py)
    does not overlap any non-walkable tile or locked door.
    Tests the 4 cardinal compass points around the circle.
    """
    for dx, dy in [(-radius, 0), (radius, 0), (0, -radius), (0, radius)]:
        c = int(px + dx) // TILE
        r = int(py + dy) // TILE
        if not is_walkable(grid, c, r):
            return False
        if locked_doors and (c, r) in locked_doors:
            return False
    return True


# ─────────────────────────────────────────────────────────────────────────────
# Projectile
# ─────────────────────────────────────────────────────────────────────────────

class Projectile:
    """A small fast-moving projectile fired by the player or a Shooter enemy."""

    SPEED  = 5.0
    RADIUS = 4

    def __init__(
        self,
        x: float, y: float,
        dx: float, dy: float,
        damage: int, owner: str, colour: tuple,
    ):
        self.x      = x
        self.y      = y
        self.dx     = dx        # unit direction vector
        self.dy     = dy
        self.damage = damage
        self.owner  = owner     # "player" or "enemy"
        self.colour = colour
        self.alive  = True

    def update(self, grid) -> None:
        """Advance the projectile; deactivate on wall contact."""
        self.x += self.dx * self.SPEED
        self.y += self.dy * self.SPEED
        c = int(self.x) // TILE
        r = int(self.y) // TILE
        if not is_walkable(grid, c, r):
            self.alive = False

    def draw(self, surface: pygame.Surface, camera) -> None:
        if not self.alive:
            return
        sx, sy = camera.apply(int(self.x), int(self.y))
        # Soft glow halo
        glow_r = self.RADIUS * 3
        glow   = pygame.Surface((glow_r * 2, glow_r * 2), pygame.SRCALPHA)
        pygame.draw.circle(glow, (*self.colour, 70), (glow_r, glow_r), glow_r)
        surface.blit(glow, (sx - glow_r, sy - glow_r))
        pygame.draw.circle(surface, self.colour, (sx, sy), self.RADIUS)

    def get_rect(self) -> pygame.Rect:
        r = self.RADIUS
        return pygame.Rect(self.x - r, self.y - r, r * 2, r * 2)


# ─────────────────────────────────────────────────────────────────────────────
# Base Entity
# ─────────────────────────────────────────────────────────────────────────────

class Entity:
    """Shared base class for Player and Enemy."""

    def __init__(
        self,
        x: float, y: float,
        hp: int, speed: float,
        colour: tuple,
        radius: int = _ENTITY_RADIUS,
    ):
        self.x      = x
        self.y      = y
        self.hp     = hp
        self.max_hp = hp
        self.speed  = speed
        self.colour = colour
        self.radius = radius
        self.alive  = True

    # ── Damage ───────────────────────────────────────────────────────────────
    def take_damage(self, amount: int) -> None:
        """Subtract *amount* HP; mark dead when HP reaches zero."""
        self.hp = max(0, self.hp - amount)
        if self.hp == 0:
            self.alive = False

    # ── Geometry ─────────────────────────────────────────────────────────────
    def get_rect(self) -> pygame.Rect:
        r = self.radius
        return pygame.Rect(self.x - r, self.y - r, r * 2, r * 2)

    def dist_to(self, other: "Entity") -> float:
        return math.hypot(self.x - other.x, self.y - other.y)

    # ── HUD element ──────────────────────────────────────────────────────────
    def draw_health_bar(
        self,
        surface: pygame.Surface,
        camera,
        w: int = 30, h: int = 5, y_off: int = -18,
    ) -> None:
        """Render a thin HP bar above the entity."""
        sx, sy = camera.apply(int(self.x), int(self.y))
        bx = sx - w // 2
        by = sy + y_off
        pct = self.hp / self.max_hp
        pygame.draw.rect(surface, HEALTH_BAR_BG, (bx, by, w, h))
        pygame.draw.rect(surface, HEALTH_BAR_FG, (bx, by, int(w * pct), h))
        pygame.draw.rect(surface, (180, 180, 180), (bx, by, w, h), 1)


# ─────────────────────────────────────────────────────────────────────────────
# Player
# ─────────────────────────────────────────────────────────────────────────────

class Player(Entity):
    """Player character — keyboard-controlled, melee + ranged attacks."""

    MELEE_COOLDOWN  = 400   # ms between melee swings
    RANGED_COOLDOWN = 600   # ms between shots

    def __init__(self, tile_col: int, tile_row: int):
        px = tile_col * TILE + TILE // 2
        py = tile_row * TILE + TILE // 2
        super().__init__(px, py, PLAYER_HP, PLAYER_SPEED, PLAYER_COL)
        self.facing        = (1.0, 0.0)   # normalised direction vector
        self._melee_timer  = 0
        self._ranged_timer = 0
        self.hit_flash     = 0            # frames of white flash when hurt
        self.damage_bonus  = 0            # added by equipped weapons (Phase 3)
        self.just_hit      = False        # flag for screen shake and particles (Phase 4)

    def handle_input(
        self,
        keys: pygame.key.ScancodeWrapper,
        dungeon,
        dt_ms: int,
    ) -> None:
        """Move the player and tick attack cooldowns."""
        dx = dy = 0.0
        if keys[pygame.K_LEFT]  or keys[pygame.K_a]: dx -= 1
        if keys[pygame.K_RIGHT] or keys[pygame.K_d]: dx += 1
        if keys[pygame.K_UP]    or keys[pygame.K_w]: dy -= 1
        if keys[pygame.K_DOWN]  or keys[pygame.K_s]: dy += 1

        if dx or dy:
            length  = math.hypot(dx, dy)
            dx /= length
            dy /= length
            self.facing = (dx, dy)

        # Separate-axis collision so the player slides along walls and locked doors
        locked = getattr(dungeon, "locked_doors", None)
        nx, ny = self.x + dx * self.speed, self.y + dy * self.speed
        if _can_move(dungeon.grid, nx, self.y, locked_doors=locked):
            self.x = nx
        if _can_move(dungeon.grid, self.x, ny, locked_doors=locked):
            self.y = ny

        self._melee_timer  = max(0, self._melee_timer  - dt_ms)
        self._ranged_timer = max(0, self._ranged_timer - dt_ms)
        self.hit_flash     = max(0, self.hit_flash - 1)

    def try_melee(self, enemies: list) -> tuple:
        """
        Swing melee weapon.
        Returns (swung: bool, hits: list[Enemy]).
        """
        if self._melee_timer > 0:
            return False, []
        self._melee_timer = self.MELEE_COOLDOWN
        hits = []
        for enemy in enemies:
            if not enemy.alive:
                continue
            d = self.dist_to(enemy)
            if d <= PLAYER_RANGE:
                ex = (enemy.x - self.x) / max(d, 1)
                ey = (enemy.y - self.y) / max(d, 1)
                if ex * self.facing[0] + ey * self.facing[1] > 0.25:
                    enemy.take_damage(PLAYER_DAMAGE + self.damage_bonus)
                    enemy.hit_flash = 6
                    hits.append(enemy)
        return True, hits

    def try_ranged(self) -> "Projectile | None":
        """
        Fire a projectile in the current facing direction.
        Returns a Projectile instance or None if still on cooldown.
        """
        if self._ranged_timer > 0:
            return None
        self._ranged_timer = self.RANGED_COOLDOWN
        return Projectile(
            self.x, self.y,
            self.facing[0], self.facing[1],
            damage=15, owner="player",
            colour=(100, 200, 255),
        )

    def take_damage(self, amount: int) -> None:
        super().take_damage(amount)
        self.hit_flash = 10
        self.just_hit = True

    def draw(self, surface: pygame.Surface, camera) -> None:
        sx, sy = camera.apply(int(self.x), int(self.y))
        col = (255, 255, 255) if self.hit_flash > 0 else self.colour
        pygame.draw.circle(surface, col,          (sx, sy), self.radius)
        pygame.draw.circle(surface, (200, 240, 255), (sx, sy), self.radius, 2)
        # Facing indicator dot
        fx = sx + int(self.facing[0] * (self.radius + 5))
        fy = sy + int(self.facing[1] * (self.radius + 5))
        pygame.draw.circle(surface, (255, 255, 255), (fx, fy), 3)
        self.draw_health_bar(surface, camera, w=44, h=6, y_off=-24)


# ─────────────────────────────────────────────────────────────────────────────
# Enemy base
# ─────────────────────────────────────────────────────────────────────────────

class Enemy(Entity):
    """Base enemy — provides scaled stats, drawing, and movement helpers."""

    def __init__(self, tile_col: int, tile_row: int, etype: str, floor: int = 1):
        stats = ENEMY_STATS[etype]
        hp    = int(stats["hp"]    * FLOOR_HP_MULT    ** (floor - 1))
        speed = stats["speed"] * FLOOR_SPEED_MULT ** (floor - 1)
        px = tile_col * TILE + TILE // 2
        py = tile_row * TILE + TILE // 2
        super().__init__(px, py, hp, speed, ENEMY_COL[etype])
        self.etype          = etype
        self.damage         = stats["damage"]
        self.sight          = stats["sight"]
        self.state          = "idle"
        self.hit_flash      = 0
        self._attack_timer  = 0

    # ── Shared movement ───────────────────────────────────────────────────────
    def _move_toward(self, tx: float, ty: float, grid, locked_doors: set = None) -> None:
        """Step toward target pixel position with wall and door collision."""
        dx = tx - self.x
        dy = ty - self.y
        dist = math.hypot(dx, dy)
        if dist < 2:
            return
        dx /= dist
        dy /= dist
        nx, ny = self.x + dx * self.speed, self.y + dy * self.speed
        if _can_move(grid, nx, self.y, radius=8, locked_doors=locked_doors):
            self.x = nx
        if _can_move(grid, self.x, ny, radius=8, locked_doors=locked_doors):
            self.y = ny

    # ── Rendering ─────────────────────────────────────────────────────────────
    def draw(self, surface: pygame.Surface, camera) -> None:
        sx, sy = camera.apply(int(self.x), int(self.y))
        col = (255, 255, 255) if self.hit_flash > 0 else self.colour
        self.hit_flash = max(0, self.hit_flash - 1)
        r = self.radius
        pygame.draw.rect(surface, col,         (sx - r, sy - r, r * 2, r * 2))
        pygame.draw.rect(surface, (255,255,255),(sx - r, sy - r, r * 2, r * 2), 1)
        self.draw_health_bar(surface, camera)


# ─────────────────────────────────────────────────────────────────────────────
# Chaser — sprints straight at the player
# ─────────────────────────────────────────────────────────────────────────────

class Chaser(Enemy):
    """Activates when the player enters sight range; charges and melee-hits."""

    ATTACK_RANGE    = TILE * 1.2
    ATTACK_COOLDOWN = 700    # ms

    def __init__(self, tile_col: int, tile_row: int, floor: int = 1):
        super().__init__(tile_col, tile_row, "chaser", floor)

    def update(
        self, player: Player, dungeon, projectiles: list, dt_ms: int
    ) -> None:
        self._attack_timer = max(0, self._attack_timer - dt_ms)
        d = self.dist_to(player)
        if d <= self.sight:
            self.state = "chase"
        if self.state == "chase":
            locked = getattr(dungeon, "locked_doors", None)
            if d > self.ATTACK_RANGE:
                self._move_toward(player.x, player.y, dungeon.grid, locked_doors=locked)
            elif self._attack_timer == 0:
                player.take_damage(self.damage)
                self._attack_timer = self.ATTACK_COOLDOWN


# ─────────────────────────────────────────────────────────────────────────────
# Patroller — wanders waypoints, chases on sight
# ─────────────────────────────────────────────────────────────────────────────

class Patroller(Enemy):
    """Loops through random waypoints in its spawn room; chases when player spotted."""

    ATTACK_RANGE    = TILE * 1.3
    ATTACK_COOLDOWN = 900

    def __init__(self, tile_col: int, tile_row: int, room, floor: int = 1):
        super().__init__(tile_col, tile_row, "patrol", floor)
        rng   = random.Random()
        inner = room.inner_tiles
        n     = min(4, max(1, len(inner)))
        self._waypoints = [
            (c * TILE + TILE // 2, r * TILE + TILE // 2)
            for c, r in rng.sample(inner, n)
        ]
        self._wp_idx = 0

    def update(
        self, player: Player, dungeon, projectiles: list, dt_ms: int
    ) -> None:
        self._attack_timer = max(0, self._attack_timer - dt_ms)
        d = self.dist_to(player)
        locked = getattr(dungeon, "locked_doors", None)
        if d <= self.sight:
            self.state = "chase"

        if self.state == "chase":
            if d > self.ATTACK_RANGE:
                self._move_toward(player.x, player.y, dungeon.grid, locked_doors=locked)
            elif self._attack_timer == 0:
                player.take_damage(self.damage)
                self._attack_timer = self.ATTACK_COOLDOWN
        else:
            if self._waypoints:
                tx, ty = self._waypoints[self._wp_idx]
                self._move_toward(tx, ty, dungeon.grid, locked_doors=locked)
                if math.hypot(self.x - tx, self.y - ty) < TILE * 0.5:
                    self._wp_idx = (self._wp_idx + 1) % len(self._waypoints)


# ─────────────────────────────────────────────────────────────────────────────
# Shooter — keeps its distance, fires projectiles
# ─────────────────────────────────────────────────────────────────────────────

class Shooter(Enemy):
    """Maintains a preferred standoff distance and fires homing-free projectiles."""

    PREFERRED_DIST = TILE * 5
    SHOOT_COOLDOWN = 1200

    def __init__(self, tile_col: int, tile_row: int, floor: int = 1):
        super().__init__(tile_col, tile_row, "shooter", floor)

    def update(
        self, player: Player, dungeon, projectiles: list, dt_ms: int
    ) -> None:
        self._attack_timer = max(0, self._attack_timer - dt_ms)
        d = self.dist_to(player)
        locked = getattr(dungeon, "locked_doors", None)
        if d <= self.sight:
            self.state = "chase"
        if self.state != "chase":
            return

        # Maintain preferred standoff distance
        if d < self.PREFERRED_DIST * 0.7:
            dx = (self.x - player.x) / max(d, 1)
            dy = (self.y - player.y) / max(d, 1)
            nx, ny = self.x + dx * self.speed, self.y + dy * self.speed
            if _can_move(dungeon.grid, nx, self.y, radius=8, locked_doors=locked): self.x = nx
            if _can_move(dungeon.grid, self.x, ny, radius=8, locked_doors=locked): self.y = ny
        elif d > self.PREFERRED_DIST * 1.3:
            self._move_toward(player.x, player.y, dungeon.grid, locked_doors=locked)

        # Fire when ready
        if self._attack_timer == 0:
            dx = player.x - self.x
            dy = player.y - self.y
            dist = math.hypot(dx, dy) or 1
            projectiles.append(Projectile(
                self.x, self.y,
                dx / dist, dy / dist,
                damage=self.damage, owner="enemy",
                colour=(200, 80, 255),
            ))
            self._attack_timer = self.SHOOT_COOLDOWN


# ─────────────────────────────────────────────────────────────────────────────
# Factory
# ─────────────────────────────────────────────────────────────────────────────

def spawn_enemies(dungeon) -> list:
    """
    Instantiate Enemy objects for every spawn point in *dungeon*.

    Enemy types are chosen randomly with weighted probabilities:
      50 % Chaser, 30 % Patroller, 20 % Shooter.

    Parameters
    ----------
    dungeon : Dungeon
        A fully-generated dungeon (enemy_spawns populated).

    Returns
    -------
    list[Enemy]
    """
    rng     = random.Random()
    types   = ["chaser", "patrol", "shooter"]
    weights = [0.50,     0.30,     0.20]

    # Build tile → room lookup so Patrollers know their room's waypoints
    room_map: dict = {}
    for room in dungeon.rooms:
        for tc, tr in room.inner_tiles:
            room_map[(tc, tr)] = room

    enemies = []
    for tc, tr in dungeon.enemy_spawns:
        etype = rng.choices(types, weights)[0]
        if etype == "chaser":
            enemies.append(Chaser(tc, tr, floor=dungeon.floor))
        elif etype == "patrol":
            room = room_map.get((tc, tr), dungeon.rooms[0])
            enemies.append(Patroller(tc, tr, room, floor=dungeon.floor))
        else:
            enemies.append(Shooter(tc, tr, floor=dungeon.floor))
    return enemies


# ─────────────────────────────────────────────────────────────────────────────
# Interactable System (Chests, Shrines, Stairs, Foundation for NPCs/Doors)
# ─────────────────────────────────────────────────────────────────────────────

class Interactable:
    """
    Base class for interactive dungeon objects.
    Provides proximity detection, prompt information, and interaction dispatch.
    """

    def __init__(self, col: int, row: int, radius: float = TILE * 1.35):
        self.col    = col
        self.row    = row
        self.x      = col * TILE + TILE // 2
        self.y      = row * TILE + TILE // 2
        self.radius = radius

    def dist_to(self, px: float, py: float) -> float:
        """Distance from entity to player center."""
        return math.hypot(self.x - px, self.y - py)

    def can_interact(self, player) -> bool:
        """Return True if the player can currently trigger an interaction."""
        return True

    def get_prompt(self, player) -> tuple:
        """Return (key_name, action_label, subtext) for the interaction HUD prompt."""
        return "E", "Interact", ""

    def interact(self, context: dict) -> None:
        """Execute interaction logic."""
        pass

    def draw(self, surface: pygame.Surface, camera, lit: bool) -> None:
        """Render object in the game world."""
        pass


class Chest(Interactable):
    """
    Treasure chest requiring deliberate interaction ([E] Open Chest).
    Opens to scatter random loot, coins, and equipment into the world.
    """

    def __init__(self, col: int, row: int, has_key: bool = False):
        super().__init__(col, row)
        self.is_open = False
        self.has_key = has_key

    def can_interact(self, player) -> bool:
        return not self.is_open

    def get_prompt(self, player) -> tuple:
        return "E", "Open Chest", "Treasure"

    def interact(self, context: dict) -> None:
        if self.is_open:
            return
        self.is_open = True
        floor       = context.get("floor", 1)
        loot_items  = chest_loot(floor, guaranteed_key=self.has_key)
        world_loot  = context.get("world_loot", [])
        particles   = context.get("particles", [])
        camera      = context.get("camera", None)
        msglog      = context.get("msglog", None)

        for item in loot_items:
            ox = random.uniform(-10, 10)
            oy = random.uniform(-10, 10)
            world_loot.append(WorldLoot(self.x + ox, self.y + oy, item))

        if context.get("emit_fn"):
            context["emit_fn"](particles, self.x, self.y, (255, 215, 0), count=22, speed=3.2, size=3)
        if camera:
            camera.add_shake(3.2, 130)
        sfx.play_chest()
        if msglog:
            if self.has_key:
                msglog.add("Chest unlocked! A gleaming Dungeon Key was inside!")
            else:
                msglog.add("Chest unlocked! Gold & loot burst out.")

    def draw(self, surface: pygame.Surface, camera, lit: bool) -> None:
        if not lit:
            return
        sx, sy = camera.apply(self.col * TILE, self.row * TILE)
        pad    = TILE // 5
        rect   = (sx + pad, sy + pad, TILE - pad * 2, TILE - pad * 2)

        if not self.is_open:
            # Closed chest with brass trim and keyhole
            pygame.draw.rect(surface, CHEST_COL, rect)
            pygame.draw.rect(surface, (205, 175, 80), rect, 2)
            pygame.draw.circle(surface, (80, 50, 10), (sx + TILE // 2, sy + TILE // 2), 3)
            # Gentle pulsing sheen
            pulse = abs(pygame.time.get_ticks() % 1400 - 700) / 700
            if pulse > 0.5:
                pygame.draw.circle(surface, (255, 235, 130), (sx + TILE // 2, sy + TILE // 2), 2)
        else:
            # Opened chest (open dark interior + wooden lid lifted back)
            pygame.draw.rect(surface, CHEST_OPEN_COL, rect)
            inner = (sx + pad + 2, sy + pad + 3, TILE - pad * 2 - 4, TILE - pad * 2 - 5)
            pygame.draw.rect(surface, (45, 30, 15), inner)
            pygame.draw.rect(surface, (130, 100, 45), rect, 1)
            # Open lid flap
            pygame.draw.rect(surface, CHEST_COL, (sx + pad - 2, sy + pad - 4, TILE - pad * 2 + 4, 4))


class VaultChest(Chest):
    """Special gilded chest found inside locked vault rooms with superior rewards."""

    def get_prompt(self, player) -> tuple:
        return "E", "Open Vault Chest", "Grand Treasure"

    def interact(self, context: dict) -> None:
        if self.is_open:
            return
        self.is_open = True
        floor       = context.get("floor", 1)
        # Vault rewards: High tier potion, weapon upgrade, and large gold cache
        loot_items  = [
            Item("Major Potion", "potion", 70, (60, 220, 100)),
            Item("War Hammer", "weapon", 18 + floor * 2, (200, 200, 50)),
            Item("Treasure Hoard", "coin", 75 + floor * 20, (255, 215, 0)),
        ]
        world_loot  = context.get("world_loot", [])
        particles   = context.get("particles", [])
        camera      = context.get("camera", None)
        msglog      = context.get("msglog", None)

        for item in loot_items:
            ox = random.uniform(-10, 10)
            oy = random.uniform(-10, 10)
            world_loot.append(WorldLoot(self.x + ox, self.y + oy, item))

        if context.get("emit_fn"):
            context["emit_fn"](particles, self.x, self.y, (255, 215, 0), count=30, speed=3.8, size=4)
        if camera:
            camera.add_shake(4.2, 160)
        sfx.play_chest()
        if msglog:
            msglog.add("Vault Chest unlocked! A grand treasure hoard is yours!")

    def draw(self, surface: pygame.Surface, camera, lit: bool) -> None:
        if not lit:
            return
        sx, sy = camera.apply(self.col * TILE, self.row * TILE)
        pad    = TILE // 5
        rect   = (sx + pad, sy + pad, TILE - pad * 2, TILE - pad * 2)

        if not self.is_open:
            # Gilded Royal Vault Chest (ornate purple and gold)
            pygame.draw.rect(surface, (135, 35, 145), rect)
            pygame.draw.rect(surface, (255, 215, 60), rect, 2)
            pygame.draw.circle(surface, (255, 235, 120), (sx + TILE // 2, sy + TILE // 2), 4)
            pulse = abs(pygame.time.get_ticks() % 1000 - 500) / 500
            if pulse > 0.4:
                pygame.draw.circle(surface, (255, 255, 220), (sx + TILE // 2, sy + TILE // 2), 2)
        else:
            super().draw(surface, camera, lit)


class Door(Interactable):
    """
    A locked vault door requiring a Dungeon Key to open ([E] Unlock Door).
    Blocks physical passage until unlocked.
    """

    def __init__(self, col: int, row: int):
        super().__init__(col, row, radius=TILE * 1.4)
        self.is_locked = True
        self.is_open   = False

    def can_interact(self, player) -> bool:
        return not self.is_open

    def get_prompt(self, player) -> tuple:
        return "E", "Unlock Door", "Use Key"

    def interact(self, context: dict) -> None:
        if self.is_open:
            return
        inventory = context.get("inventory")
        dungeon   = context.get("dungeon")
        msglog    = context.get("msglog")
        camera    = context.get("camera")
        particles = context.get("particles", [])
        emit_fn   = context.get("emit_fn")

        if inventory and inventory.consume_key():
            self.is_locked = False
            self.is_open   = True
            if dungeon and hasattr(dungeon, "locked_doors"):
                dungeon.locked_doors.discard((self.col, self.row))
            sfx.play_door_unlock()
            if msglog:
                msglog.add("Unlocked the heavy door with a Dungeon Key!")
            if emit_fn:
                emit_fn(particles, self.x, self.y, (255, 215, 60), count=24, speed=3.0, size=3)
            if camera:
                camera.add_shake(3.5, 140)
        else:
            sfx.play_door_locked()
            if msglog:
                msglog.add("The door is locked. Find a Dungeon Key!")
            if camera:
                camera.add_shake(1.8, 90)

    def draw(self, surface: pygame.Surface, camera, lit: bool) -> None:
        if not lit:
            return
        sx, sy = camera.apply(self.col * TILE, self.row * TILE)
        rect   = (sx, sy, TILE, TILE)

        if not self.is_open:
            # Sturdy locked door: iron-reinforced timber with golden keyhole plaque
            pygame.draw.rect(surface, (75, 45, 25), rect)
            pygame.draw.rect(surface, (120, 100, 80), rect, 2)
            pygame.draw.line(surface, (50, 45, 55), (sx, sy + 10), (sx + TILE, sy + 10), 2)
            pygame.draw.line(surface, (50, 45, 55), (sx, sy + TILE - 10), (sx + TILE, sy + TILE - 10), 2)
            # Golden keyhole plaque
            pygame.draw.rect(surface, (215, 180, 50), (sx + TILE // 2 - 4, sy + TILE // 2 - 6, 8, 12))
            pygame.draw.circle(surface, (30, 20, 10), (sx + TILE // 2, sy + TILE // 2 - 2), 2)
            pygame.draw.line(surface, (30, 20, 10), (sx + TILE // 2, sy + TILE // 2 - 2), (sx + TILE // 2, sy + TILE // 2 + 3), 2)
        else:
            # Open doorway with door panel swung ajar to the side
            pygame.draw.rect(surface, (45, 40, 58), rect)
            pygame.draw.rect(surface, (35, 30, 45), rect, 1)
            pygame.draw.rect(surface, (75, 45, 25), (sx + 2, sy + 2, 6, TILE - 4))
            pygame.draw.rect(surface, (120, 100, 80), (sx + 2, sy + 2, 6, TILE - 4), 1)


class Shrine(Interactable):
    """
    Ancient runic shrine offering recovery or a damage empowerment blessing.
    Completes the explore -> interact -> reward loop.
    """

    def __init__(self, col: int, row: int):
        super().__init__(col, row)
        self.used = False

    def can_interact(self, player) -> bool:
        return not self.used

    def get_prompt(self, player) -> tuple:
        if player.hp < player.max_hp:
            return "E", "Pray at Shrine", "Heal HP"
        return "E", "Pray at Shrine", "Bless Weapon"

    def interact(self, context: dict) -> None:
        if self.used:
            return
        self.used = True
        player    = context.get("player")
        msglog    = context.get("msglog")
        particles = context.get("particles", [])
        camera    = context.get("camera")
        emit_fn   = context.get("emit_fn")

        if player.hp < player.max_hp:
            heal = min(40, player.max_hp - player.hp)
            player.hp += heal
            if msglog:
                msglog.add(f"Divine warmth heals your wounds! (+{heal} HP)")
            if emit_fn:
                emit_fn(particles, self.x, self.y, (80, 255, 140), count=26, speed=3.2, size=3)
        else:
            player.damage_bonus += 5
            if msglog:
                msglog.add("Ancient spirits empower your weapon! (+5 Damage)")
            if emit_fn:
                emit_fn(particles, self.x, self.y, (120, 210, 255), count=26, speed=3.6, size=3)

        if camera:
            camera.add_shake(4.0, 160)
        sfx.play_shrine()

    def draw(self, surface: pygame.Surface, camera, lit: bool) -> None:
        if not lit:
            return
        sx, sy = camera.apply(self.col * TILE, self.row * TILE)
        cx, cy = sx + TILE // 2, sy + TILE // 2

        # Carved stone altar pedestal
        base_rect = (sx + 4, sy + 10, TILE - 8, TILE - 14)
        pygame.draw.rect(surface, (55, 50, 70), base_rect)
        pygame.draw.rect(surface, (95, 90, 120), base_rect, 1)

        if not self.used:
            # Levitating, pulsing arcane crystal
            pulse = abs(pygame.time.get_ticks() % 1000 - 500) / 500
            orb_r = int(5 + pulse * 2)
            glow_r = orb_r + 6
            glow = pygame.Surface((glow_r * 2, glow_r * 2), pygame.SRCALPHA)
            pygame.draw.circle(glow, (100, 200, 255, 65), (glow_r, glow_r), glow_r)
            surface.blit(glow, (cx - glow_r, cy - 4 - glow_r))
            pygame.draw.circle(surface, SHRINE_COL, (cx, cy - 4), orb_r)
            pygame.draw.circle(surface, (230, 250, 255), (cx, cy - 4), max(1, orb_r - 2))
        else:
            # Depleted stone relic
            pygame.draw.circle(surface, SHRINE_USED_COL, (cx, cy - 4), 4)
            pygame.draw.circle(surface, (45, 40, 55), (cx, cy - 4), 4, 1)


class StairsCheckpoint(Interactable):
    """Exit stairs platform checkpoint leading to deeper dungeon floors."""

    def __init__(self, col: int, row: int):
        super().__init__(col, row, radius=TILE * 1.5)

    def can_interact(self, player) -> bool:
        return True

    def get_prompt(self, player) -> tuple:
        return "E", "Descend Stairs", "Go deeper"


class MerchantNPC(Interactable):
    """
    Friendly Wandering Merchant NPC that sells potions, weapons, keys,
    and vitality upgrades in exchange for collected coins.
    """

    def __init__(self, col: int, row: int):
        super().__init__(col, row, radius=TILE * 1.5)

    def can_interact(self, player) -> bool:
        return True

    def get_prompt(self, player) -> tuple:
        return "E", "Trade with Merchant", "Spend Coins"

    def interact(self, context: dict) -> None:
        """Trigger opening of Merchant Shop."""
        open_shop_fn = context.get("open_shop_fn")
        if open_shop_fn:
            open_shop_fn()
        sfx.play_coin()
        msglog = context.get("msglog")
        if msglog:
            msglog.add("Merchant: 'Greetings, traveler! Take a look at my wares.'")

    def draw(self, surface: pygame.Surface, camera, lit: bool) -> None:
        if not lit:
            return
        sx, sy = camera.apply(self.col * TILE, self.row * TILE)
        cx, cy = sx + TILE // 2, sy + TILE // 2

        # Merchant stall mat
        mat_rect = (sx + 2, sy + 6, TILE - 4, TILE - 8)
        pygame.draw.rect(surface, (70, 45, 30), mat_rect, border_radius=3)
        pygame.draw.rect(surface, (150, 110, 60), mat_rect, 1, border_radius=3)

        # Cloaked merchant body (emerald & gold traveler's robe)
        pygame.draw.circle(surface, (30, 110, 75), (cx, cy), 8)
        # Golden hood
        pygame.draw.circle(surface, (230, 195, 70), (cx, cy - 3), 5)
        # Face shadow & gleaming eyes
        pygame.draw.circle(surface, (30, 25, 35), (cx, cy - 2), 3)
        pygame.draw.circle(surface, (120, 220, 255), (cx - 1, cy - 3), 1)
        pygame.draw.circle(surface, (120, 220, 255), (cx + 1, cy - 3), 1)

        # Ambient lantern glow
        pulse = abs(pygame.time.get_ticks() % 1200 - 600) / 600
        glow_r = int(14 + pulse * 4)
        glow = pygame.Surface((glow_r * 2, glow_r * 2), pygame.SRCALPHA)
        pygame.draw.circle(glow, (255, 210, 80, 50), (glow_r, glow_r), glow_r)
        surface.blit(glow, (cx + 7 - glow_r, cy - 4 - glow_r))

        # Brass lantern
        pygame.draw.circle(surface, (255, 220, 90), (cx + 7, cy - 4), 3)
        pygame.draw.rect(surface, (160, 110, 30), (cx + 6, cy - 7, 2, 3))


def spawn_interactables(dungeon) -> list:
    """
    Instantiate all interactable objects (chests, vault chests, locked doors, shrine, merchant, stairs)
    for the current dungeon floor.
    """
    items = []
    # Regular Chests (one designated as key-bearer)
    key_chests = getattr(dungeon, "key_chests", set())
    for tc, tr in dungeon.chest_spawns:
        has_key = (tc, tr) in key_chests
        items.append(Chest(tc, tr, has_key=has_key))

    # Vault Chests
    for tc, tr in getattr(dungeon, "vault_chests", []):
        items.append(VaultChest(tc, tr))

    # Locked Doors
    for dc, dr in getattr(dungeon, "locked_doors", set()):
        items.append(Door(dc, dr))

    # Merchant NPC (Friendly shopkeeper in safe zone)
    if getattr(dungeon, "merchant_spawn", None):
        mc, mr = dungeon.merchant_spawn
        items.append(MerchantNPC(mc, mr))

    # Shrine
    if getattr(dungeon, "shrine_spawn", None):
        sc, sr = dungeon.shrine_spawn
        items.append(Shrine(sc, sr))

    # Exit Stairs
    ec, er = dungeon.exit_pos
    items.append(StairsCheckpoint(ec, er))
    return items
