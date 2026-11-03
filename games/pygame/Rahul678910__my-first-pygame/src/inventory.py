"""
inventory.py  –  Categorized Inventory System
Item definitions, Inventory management, WorldLoot pickup items, and UI renderer.

Features:
- Completely separated sections for Weapons, Healing Potions, and Keyring/Valuables.
- Persistent equipped weapon tracking with hotkey weapon swapping.
- Quick-Heal ability [Q] / [H] to heal during active gameplay without opening menus.
- Dedicated Keyring and Treasury display.
- Integrated procedural audio playback via sfx module.
"""

import random
from dataclasses import dataclass
from typing import Optional, List

import pygame

from settings import (
    TILE, SCREEN_W, SCREEN_H,
    POTION_COL, WEAPON_COL, COIN_COL,
    UI_TEXT, UI_HIGHLIGHT,
    LOOT_DROP_CHANCE, CHEST_LOOT_COUNT,
)
import sfx

# ── Item kinds ────────────────────────────────────────────────────────────────
KIND_POTION = "potion"
KIND_WEAPON = "weapon"
KIND_COIN   = "coin"
KIND_KEY    = "key"

KEY_COL     = (255, 215, 60)

ITEM_COLOURS = {
    KIND_POTION: POTION_COL,
    KIND_WEAPON: WEAPON_COL,
    KIND_COIN:   COIN_COL,
    KIND_KEY:    KEY_COL,
}

_CATEGORY_ORDER = {
    KIND_WEAPON: 0,
    KIND_POTION: 1,
    KIND_KEY:    2,
}

# ── Item pools ────────────────────────────────────────────────────────────────
_POTIONS = [
    ("Minor Potion",  KIND_POTION, 20),
    ("Potion",        KIND_POTION, 40),
    ("Major Potion",  KIND_POTION, 70),
]
_WEAPONS = [
    ("Dagger",        KIND_WEAPON,  3),
    ("Short Sword",   KIND_WEAPON,  6),
    ("Long Sword",    KIND_WEAPON, 10),
    ("Battle Axe",    KIND_WEAPON, 15),
    ("War Hammer",    KIND_WEAPON, 18),
]
_COINS = [
    ("Coins",         KIND_COIN,  10),
    ("Silver",        KIND_COIN,  25),
    ("Gold",          KIND_COIN,  50),
]


# ─────────────────────────────────────────────────────────────────────────────
# Item dataclass
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class Item:
    """A single collectable item."""
    name:   str
    kind:   str    # KIND_POTION | KIND_WEAPON | KIND_COIN | KIND_KEY
    value:  int    # HP restored / damage bonus / coin count
    colour: tuple


def random_item(floor: int = 1, rng=None) -> Item:
    """Return a random Item, value scaled slightly by floor."""
    if rng is None:
        rng = random
    pool = rng.choices(
        [_POTIONS, _WEAPONS, _COINS],
        weights=[0.40, 0.25, 0.35],
    )[0]
    name, kind, base = rng.choice(pool)
    value = max(1, int(base * (1 + (floor - 1) * 0.12)))
    return Item(name=name, kind=kind, value=value, colour=ITEM_COLOURS[kind])


def random_drop(floor: int = 1, rng=None) -> Optional[Item]:
    """Return an Item with probability LOOT_DROP_CHANCE, else None."""
    r = rng or random
    return random_item(floor, rng) if r.random() < LOOT_DROP_CHANCE else None


def make_key(name: str = "Dungeon Key") -> Item:
    """Instantiate a key item used to unlock vault doors."""
    return Item(name=name, kind=KIND_KEY, value=1, colour=KEY_COL)


def chest_loot(floor: int = 1, rng=None, guaranteed_key: bool = False) -> list:
    """Return a list of CHEST_LOOT_COUNT random items for a chest opening."""
    r = rng or random
    items = [random_item(floor, r) for _ in range(CHEST_LOOT_COUNT)]
    if guaranteed_key:
        items[0] = make_key()
    return items


# ─────────────────────────────────────────────────────────────────────────────
# WorldLoot — item lying on the floor
# ─────────────────────────────────────────────────────────────────────────────

class WorldLoot:
    """An Item placed in the world waiting to be collected."""

    DRAW_RADIUS   = 6
    PICKUP_RADIUS = 10

    def __init__(self, x: float, y: float, item: Item):
        self.x     = x
        self.y     = y
        self.item  = item
        self.alive = True

    def draw(self, surface: pygame.Surface, camera) -> None:
        if not self.alive:
            return
        sx, sy = camera.apply(int(self.x), int(self.y))
        r = self.DRAW_RADIUS
        glow = pygame.Surface((r * 4, r * 4), pygame.SRCALPHA)
        pygame.draw.circle(glow, (*self.item.colour, 90), (r * 2, r * 2), r * 2)
        surface.blit(glow, (sx - r * 2, sy - r * 2))
        pygame.draw.circle(surface, self.item.colour, (sx, sy), r)
        pygame.draw.circle(surface, (255, 255, 200), (sx, sy), r, 1)

    def get_rect(self) -> pygame.Rect:
        r = self.PICKUP_RADIUS
        return pygame.Rect(self.x - r, self.y - r, r * 2, r * 2)


# ─────────────────────────────────────────────────────────────────────────────
# Inventory with Distinct Sections
# ─────────────────────────────────────────────────────────────────────────────

class Inventory:
    """
    Manages player equipment, consumables, and valuables in distinct sections:
      1. Weapons section: equipped weapon + carried alternate weapons.
      2. Healing section: health potions with quick-heal [Q] support.
      3. Keyring & Valuables: dedicated keys storage and gold counter.
    """

    MAX_SLOTS = 16

    def __init__(self):
        self.items: List[Item] = []
        self.coins: int = 0
        self.equipped_weapon: Optional[Item] = None

    def _sort_items(self) -> None:
        """Keep items grouped: Weapons -> Potions -> Keys."""
        self.items.sort(key=lambda it: _CATEGORY_ORDER.get(it.kind, 99))

    # ── Section Accessors ─────────────────────────────────────────────────────

    @property
    def weapons(self) -> List[Item]:
        """Return all carried weapons in the pack."""
        return [it for it in self.items if it.kind == KIND_WEAPON]

    @property
    def potions(self) -> List[Item]:
        """Return all healing potions in the pack."""
        return [it for it in self.items if it.kind == KIND_POTION]

    @property
    def keys(self) -> List[Item]:
        """Return all keys on the keyring."""
        return [it for it in self.items if it.kind == KIND_KEY]

    def key_count(self) -> int:
        """Return total number of keys held."""
        return len(self.keys)

    def potion_count(self) -> int:
        """Return total number of potions held."""
        return len(self.potions)

    def weapon_count(self) -> int:
        """Return total number of carried weapons."""
        return len(self.weapons)

    # ── Adding & Storing ──────────────────────────────────────────────────────

    def add(self, item: Item) -> bool:
        """Add item to inventory. Coins add straight to treasury."""
        if item.kind == KIND_COIN:
            self.coins += item.value
            return True
        if len(self.items) >= self.MAX_SLOTS:
            return False
        self.items.append(item)
        self._sort_items()
        return True

    # ── Keys & Doors ──────────────────────────────────────────────────────────

    def has_key(self) -> bool:
        """Return True if holding at least one key."""
        return any(it.kind == KIND_KEY for it in self.items)

    def consume_key(self) -> bool:
        """Consume one key from the keyring. Returns True on success."""
        for i, it in enumerate(self.items):
            if it.kind == KIND_KEY:
                self.items.pop(i)
                return True
        return False

    # ── Weapon Equipping ──────────────────────────────────────────────────────

    def equip_weapon(self, item: Item, player) -> str:
        """
        Equip a weapon. Swaps out previously equipped weapon if present,
        retaining it in the inventory instead of losing it.
        """
        old_weapon = self.equipped_weapon
        if item in self.items:
            self.items.remove(item)

        self.equipped_weapon = item
        player.damage_bonus = item.value
        if hasattr(player, "equipped_weapon"):
            player.equipped_weapon = item

        if old_weapon is not None:
            self.items.append(old_weapon)
            self._sort_items()

        sfx.play_equip()
        return f"Equipped {item.name}  (+{item.value} dmg)"

    # ── Healing & Potions ─────────────────────────────────────────────────────

    def use_potion(self, item: Item, player) -> str:
        """Drink a healing potion to restore HP."""
        if item in self.items:
            self.items.remove(item)
        heal = min(item.value, player.max_hp - player.hp)
        player.hp += heal
        sfx.play_heal()
        return f"+{heal} HP  ({item.name})"

    def quick_heal(self, player) -> str:
        """
        Instantly drink the best available potion without opening menus.
        Selects the largest potion to maximize recovery in battle.
        """
        if player.hp >= player.max_hp:
            return "HP is already full!"
        potions = self.potions
        if not potions:
            return "No healing potions in inventory!"
        # Pick the most potent potion
        best = max(potions, key=lambda p: p.value)
        return self.use_potion(best, player)

    # ── Generic Index Dispatch ────────────────────────────────────────────────

    def use(self, idx: int, player) -> str:
        """Use/equip item at the given index in items."""
        if not (0 <= idx < len(self.items)):
            return ""
        item = self.items[idx]
        if item.kind == KIND_POTION:
            return self.use_potion(item, player)
        if item.kind == KIND_WEAPON:
            return self.equip_weapon(item, player)
        if item.kind == KIND_KEY:
            return f"{item.name}: Press [E] on locked doors to open"
        return ""

    def drop(self, idx: int) -> Optional[Item]:
        """Remove and return the item at idx."""
        return self.items.pop(idx) if 0 <= idx < len(self.items) else None


# ─────────────────────────────────────────────────────────────────────────────
# Categorized Inventory UI Renderer
# ─────────────────────────────────────────────────────────────────────────────

_PANEL_W = 380
_PANEL_H = 430
_SLOT_H  = 22


def draw_inventory_ui(
    surface: pygame.Surface,
    font: pygame.font.Font,
    inventory: Inventory,
) -> None:
    """
    Draw a clean, categorized 3-section inventory panel:
      1. WEAPONS & EQUIPMENT (Equipped weapon card + Weapons in bag)
      2. HEALING & APOTHECARY (Potions list + Quick-Heal tip)
      3. KEYRING & VALUABLES (Dungeon keys counter + Gold treasury)
    """
    panel = pygame.Surface((_PANEL_W, _PANEL_H), pygame.SRCALPHA)
    panel.fill((18, 16, 28, 235))
    pygame.draw.rect(panel, (90, 80, 130), (0, 0, _PANEL_W, _PANEL_H), 2, border_radius=6)

    # ── Top Title & Valuables Summary ─────────────────────────────────────────
    title = font.render("─── INVENTORY & EQUIPMENT ───", True, UI_HIGHLIGHT)
    panel.blit(title, (_PANEL_W // 2 - title.get_width() // 2, 8))

    # Coins and Keys summary bar
    coins_lbl = font.render(f"Gold: {inventory.coins}", True, COIN_COL)
    keys_lbl  = font.render(f"Keys: {inventory.key_count()}", True, KEY_COL)
    panel.blit(coins_lbl, (16, 28))
    panel.blit(keys_lbl,  (_PANEL_W - keys_lbl.get_width() - 16, 28))
    pygame.draw.line(panel, (75, 65, 105), (10, 48), (_PANEL_W - 10, 48))

    curr_y = 54
    slot_num = 1

    # ── SECTION 1: WEAPONS & EQUIPMENT ────────────────────────────────────────
    sec1_hdr = font.render("⚔️  WEAPONS & COMBAT GEAR", True, (240, 210, 100))
    panel.blit(sec1_hdr, (14, curr_y))
    curr_y += 18

    # Equipped Weapon Card
    eq = inventory.equipped_weapon
    eq_name = f"Equipped: {eq.name} (+{eq.value} dmg)" if eq else "Equipped: Bare Hands (+0 dmg)"
    eq_col  = (255, 235, 140) if eq else (150, 145, 165)
    eq_bg   = pygame.Surface((_PANEL_W - 24, 20), pygame.SRCALPHA)
    eq_bg.fill((45, 38, 70, 200))
    panel.blit(eq_bg, (12, curr_y))
    pygame.draw.rect(panel, (110, 95, 150), (12, curr_y, _PANEL_W - 24, 20), 1, border_radius=3)
    panel.blit(font.render(eq_name, True, eq_col), (20, curr_y + 2))
    curr_y += 24

    # Carried alternate weapons
    weapons = inventory.weapons
    if not weapons:
        panel.blit(font.render("  (No alternate weapons in pack)", True, (110, 100, 125)), (16, curr_y))
        curr_y += 18
    else:
        for it in weapons:
            key_tag = f"[{slot_num}]" if slot_num <= 9 else "   "
            bg = (40, 36, 65) if slot_num <= 9 else (28, 25, 45)
            pygame.draw.rect(panel, bg, (12, curr_y - 1, _PANEL_W - 24, _SLOT_H), border_radius=3)
            pygame.draw.circle(panel, it.colour, (24, curr_y + _SLOT_H // 2 - 1), 4)
            lbl = font.render(f"{key_tag} {it.name:<15} +{it.value} dmg", True, UI_TEXT)
            panel.blit(lbl, (34, curr_y + 2))
            curr_y += _SLOT_H
            slot_num += 1

    curr_y += 6
    pygame.draw.line(panel, (65, 58, 90), (12, curr_y), (_PANEL_W - 12, curr_y))
    curr_y += 8

    # ── SECTION 2: HEALING & APOTHECARY ───────────────────────────────────────
    sec2_hdr = font.render("🧪  HEALING & POTIONS", True, (100, 230, 140))
    panel.blit(sec2_hdr, (14, curr_y))
    tip_txt = font.render("[Q] Quick-Heal", True, (140, 210, 160))
    panel.blit(tip_txt, (_PANEL_W - tip_txt.get_width() - 16, curr_y))
    curr_y += 18

    potions = inventory.potions
    if not potions:
        panel.blit(font.render("  (No healing potions in pack)", True, (110, 100, 125)), (16, curr_y))
        curr_y += 18
    else:
        for it in potions:
            if curr_y > _PANEL_H - 95:
                panel.blit(font.render("  …more potions…", True, (110, 100, 125)), (16, curr_y))
                break
            key_tag = f"[{slot_num}]" if slot_num <= 9 else "   "
            bg = (35, 48, 45) if slot_num <= 9 else (25, 35, 35)
            pygame.draw.rect(panel, bg, (12, curr_y - 1, _PANEL_W - 24, _SLOT_H), border_radius=3)
            pygame.draw.circle(panel, it.colour, (24, curr_y + _SLOT_H // 2 - 1), 4)
            lbl = font.render(f"{key_tag} {it.name:<15} +{it.value} HP", True, UI_TEXT)
            panel.blit(lbl, (34, curr_y + 2))
            curr_y += _SLOT_H
            slot_num += 1

    curr_y += 6
    pygame.draw.line(panel, (65, 58, 90), (12, curr_y), (_PANEL_W - 12, curr_y))
    curr_y += 8

    # ── SECTION 3: KEYRING & VALUABLES ────────────────────────────────────────
    sec3_hdr = font.render("🗝️  KEYRING & VALUABLES", True, KEY_COL)
    panel.blit(sec3_hdr, (14, curr_y))
    curr_y += 18

    keys = inventory.keys
    if not keys:
        panel.blit(font.render("  No keys held  (Find keys in chests to open vault doors)", True, (140, 130, 150)), (16, curr_y))
    else:
        key_count = len(keys)
        pygame.draw.circle(panel, KEY_COL, (24, curr_y + 7), 5)
        panel.blit(font.render(f"  {key_count} Dungeon Key(s) ready", True, (255, 230, 120)), (34, curr_y))
        hint = font.render("  [E] Unlocks heavy vault doors automatically", True, (160, 150, 175))
        panel.blit(hint, (34, curr_y + 15))

    # ── Footer ────────────────────────────────────────────────────────────────
    fy = _PANEL_H - 38
    pygame.draw.line(panel, (75, 65, 105), (10, fy), (_PANEL_W - 10, fy))
    foot = font.render("[1-9] Use/Equip    [Q] Quick-Heal    [I] Close", True, (150, 140, 180))
    panel.blit(foot, (_PANEL_W // 2 - foot.get_width() // 2, fy + 6))
    slots_txt = font.render(f"Pack Slots: {len(inventory.items)}/{inventory.MAX_SLOTS}", True, (120, 115, 140))
    panel.blit(slots_txt, (16, fy + 20))

    ox = (surface.get_width()  - _PANEL_W) // 2
    oy = (surface.get_height() - _PANEL_H) // 2
    surface.blit(panel, (ox, oy))
