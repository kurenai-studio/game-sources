"""
tests/test_inventory.py
Pytest tests for inventory logic and item interaction.
Run with: pytest tests/
"""

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from inventory import (
    Inventory, Item,
    KIND_POTION, KIND_WEAPON, KIND_COIN, KIND_KEY,
    random_item, chest_loot, make_key,
)


class DummyPlayer:
    """Mock Player object with hp, max_hp, damage_bonus, and position attributes."""
    def __init__(self, hp=50, max_hp=100, damage_bonus=0, x=0, y=0):
        self.hp = hp
        self.max_hp = max_hp
        self.damage_bonus = damage_bonus
        self.x = x
        self.y = y


# ── Inventory Add & Slot Limit ────────────────────────────────────────────────

def test_add_items_and_capacity():
    """Inventory should hold items up to MAX_SLOTS and reject overflow."""
    inv = Inventory()
    assert len(inv.items) == 0

    # Add max non-coin items
    for i in range(Inventory.MAX_SLOTS):
        item = Item(name=f"Sword {i}", kind=KIND_WEAPON, value=i + 1, colour=(200, 200, 50))
        assert inv.add(item) is True
    assert len(inv.items) == Inventory.MAX_SLOTS

    # Trying to add one more should return False and not expand list
    extra_item = Item(name="Extra Potion", kind=KIND_POTION, value=20, colour=(60, 220, 100))
    assert inv.add(extra_item) is False
    assert len(inv.items) == Inventory.MAX_SLOTS


def test_coins_auto_collect():
    """Coins must add directly to the coin counter and not consume slots."""
    inv = Inventory()
    coin1 = Item(name="Coins", kind=KIND_COIN, value=25, colour=(255, 215, 0))
    coin2 = Item(name="Gold", kind=KIND_COIN, value=50, colour=(255, 215, 0))

    assert inv.add(coin1) is True
    assert inv.coins == 25
    assert len(inv.items) == 0  # No slot consumed

    assert inv.add(coin2) is True
    assert inv.coins == 75
    assert len(inv.items) == 0


# ── Using Potions (Healing) ───────────────────────────────────────────────────

def test_use_potion_heals_player():
    """Using a potion restores player HP up to max_hp and consumes the item."""
    inv = Inventory()
    player = DummyPlayer(hp=40, max_hp=100)
    potion = Item(name="Potion", kind=KIND_POTION, value=30, colour=(60, 220, 100))
    inv.add(potion)

    msg = inv.use(0, player)
    assert "+30 HP" in msg
    assert player.hp == 70
    assert len(inv.items) == 0


def test_use_potion_caps_at_max_hp():
    """Healing should never exceed player.max_hp."""
    inv = Inventory()
    player = DummyPlayer(hp=90, max_hp=100)
    major_potion = Item(name="Major Potion", kind=KIND_POTION, value=50, colour=(60, 220, 100))
    inv.add(major_potion)

    msg = inv.use(0, player)
    assert "+10 HP" in msg
    assert player.hp == 100
    assert len(inv.items) == 0


# ── Using Weapons (Equipping) ─────────────────────────────────────────────────

def test_equip_weapon():
    """Equipping a weapon applies damage bonus and removes item from inventory."""
    inv = Inventory()
    player = DummyPlayer(damage_bonus=0)
    weapon = Item(name="Battle Axe", kind=KIND_WEAPON, value=15, colour=(200, 200, 50))
    inv.add(weapon)

    msg = inv.use(0, player)
    assert "Equipped Battle Axe" in msg
    assert "+15 dmg" in msg
    assert player.damage_bonus == 15
    assert len(inv.items) == 0


# ── Drop and Out-of-bounds ────────────────────────────────────────────────────

def test_drop_item():
    """Dropping an item removes and returns it."""
    inv = Inventory()
    item = Item(name="Short Sword", kind=KIND_WEAPON, value=6, colour=(200, 200, 50))
    inv.add(item)

    dropped = inv.drop(0)
    assert dropped == item
    assert len(inv.items) == 0
    assert inv.drop(99) is None


def test_use_invalid_index():
    """Using an out-of-range index returns empty string and leaves player unaffected."""
    inv = Inventory()
    player = DummyPlayer(hp=50)
    msg = inv.use(5, player)
    assert msg == ""
    assert player.hp == 50


# ── Loot Generation ───────────────────────────────────────────────────────────

def test_chest_loot_count():
    """Chest loot generator should return the configured number of items."""
    from settings import CHEST_LOOT_COUNT
    items = chest_loot(floor=1)
    assert len(items) == CHEST_LOOT_COUNT
    for item in items:
        assert isinstance(item, Item)
        assert item.value > 0


# ── Keys & Unlocking ──────────────────────────────────────────────────────────

def test_key_item_and_inventory_consume():
    """Keys should occupy a slot, show helpful use text, and be consumable."""
    inv = Inventory()
    assert inv.has_key() is False
    assert inv.consume_key() is False

    key = make_key()
    assert key.kind == KIND_KEY
    assert inv.add(key) is True
    assert inv.has_key() is True

    player = DummyPlayer()
    msg = inv.use(0, player)
    assert "Press [E] on locked doors" in msg
    assert inv.has_key() is True  # using from inventory doesn't discard, consuming at door does

    assert inv.consume_key() is True
    assert inv.has_key() is False
    assert inv.consume_key() is False


def test_guaranteed_key_in_chest_loot():
    """Guaranteed key flag should ensure a key item is in the generated loot."""
    loot = chest_loot(floor=1, guaranteed_key=True)
    assert any(it.kind == KIND_KEY for it in loot)


# ── Categorized Sections & Quick-Heal ─────────────────────────────────────────

def test_inventory_separate_sections():
    """Weapons, potions, and keys must be accessible via dedicated section properties."""
    inv = Inventory()
    inv.add(Item("Sword", KIND_WEAPON, 10, (200, 200, 50)))
    inv.add(Item("Potion", KIND_POTION, 30, (60, 220, 100)))
    inv.add(make_key())

    assert len(inv.weapons) == 1
    assert inv.weapons[0].name == "Sword"

    assert len(inv.potions) == 1
    assert inv.potions[0].name == "Potion"

    assert len(inv.keys) == 1
    assert inv.key_count() == 1


def test_quick_heal():
    """Quick heal should consume the best potion and restore HP without menu."""
    inv = Inventory()
    player = DummyPlayer(hp=30, max_hp=100)

    # When no potions are held
    assert "No healing potions" in inv.quick_heal(player)
    assert player.hp == 30

    # Add a minor and a major potion; quick heal should pick the best
    inv.add(Item("Minor Potion", KIND_POTION, 20, (60, 220, 100)))
    inv.add(Item("Major Potion", KIND_POTION, 70, (60, 220, 100)))

    msg = inv.quick_heal(player)
    assert "+70 HP" in msg
    assert player.hp == 100
    assert len(inv.potions) == 1
    assert inv.potions[0].name == "Minor Potion"

    # Already at full HP
    msg_full = inv.quick_heal(player)
    assert "already full" in msg_full


def test_weapon_swapping_preserves_old_weapon():
    """Equipping a new weapon swaps the previous weapon back into inventory."""
    inv = Inventory()
    player = DummyPlayer(damage_bonus=0)

    sword1 = Item("Short Sword", KIND_WEAPON, 6, (200, 200, 50))
    sword2 = Item("War Hammer", KIND_WEAPON, 18, (200, 200, 50))

    inv.add(sword1)
    inv.add(sword2)
    assert len(inv.weapons) == 2

    # Equip sword 1
    inv.use(0, player)
    assert player.damage_bonus == 6
    assert inv.equipped_weapon.name == "Short Sword"
    assert len(inv.weapons) == 1

    # Equip sword 2 (War Hammer); Short Sword should return to pack
    inv.use(0, player)
    assert player.damage_bonus == 18
    assert inv.equipped_weapon.name == "War Hammer"
    assert len(inv.weapons) == 1
    assert inv.weapons[0].name == "Short Sword"


def test_shop_purchase_deducts_coins_and_gives_item():
    """Buying from merchant should deduct coins and place item in correct section."""
    from main import _handle_shop_purchase

    inv = Inventory()
    inv.coins = 100
    player = DummyPlayer(hp=50, max_hp=100)

    class DummyLog:
        def __init__(self): self.messages = []
        def add(self, m): self.messages.append(m)

    log = DummyLog()

    # Buy Minor Potion for 20 coins
    _handle_shop_purchase(1, inv, player, log, [])
    assert inv.coins == 80
    assert len(inv.potions) == 1
    assert inv.potions[0].name == "Minor Potion"

    # Buy Dungeon Key for 60 coins
    _handle_shop_purchase(4, inv, player, log, [])
    assert inv.coins == 20
    assert len(inv.keys) == 1
    assert inv.key_count() == 1

    # Attempt to buy Iron Cleaver for 75 coins (insufficient funds: 20 < 75)
    _handle_shop_purchase(5, inv, player, log, [])
    assert inv.coins == 20  # Coins unchanged
    assert len(inv.weapons) == 0
    assert "Not enough coins" in log.messages[-1]


if __name__ == "__main__":
    import inspect
    funcs = [obj for name, obj in inspect.getmembers(sys.modules[__name__])
             if inspect.isfunction(obj) and name.startswith("test_")]
    passed = 0
    for fn in funcs:
        fn()
        passed += 1
        print(f"  ✓ {fn.__name__}")
    print(f"\nAll {passed} inventory tests passed!")

