"""
tests/test_dungeon.py
Pytest tests for dungeon generation (Phase 1).
Run with: pytest tests/
"""

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from dungeon import generate_dungeon, _flood_reachable, Room
from settings import T_EMPTY, T_FLOOR, T_CORRIDOR, T_DOOR, T_STAIRS, COLS, ROWS


# ── Helper ────────────────────────────────────────────────────────────────────

def _all_floor_tiles(dungeon):
    """Collect all walkable (col, row) tiles from the dungeon grid."""
    walkable = {T_FLOOR, T_CORRIDOR, T_DOOR, T_STAIRS}
    tiles = []
    for r in range(ROWS):
        for c in range(COLS):
            if dungeon.grid[r][c] in walkable:
                tiles.append((c, r))
    return tiles


# ── Room overlap ──────────────────────────────────────────────────────────────

def test_rooms_do_not_overlap():
    """No two rooms should overlap (rooms are separated by at least 1 tile)."""
    for seed in range(10):
        dungeon = generate_dungeon(floor=1, seed=seed)
        rooms   = dungeon.rooms
        for i, a in enumerate(rooms):
            for j, b in enumerate(rooms):
                if i >= j:
                    continue
                assert not a.intersects(b, margin=0), (
                    f"seed={seed}: Room {i} {vars(a)} overlaps Room {j} {vars(b)}"
                )


# ── Minimum room count ────────────────────────────────────────────────────────

def test_minimum_rooms_generated():
    """Every dungeon must have at least 2 rooms."""
    for seed in range(10):
        dungeon = generate_dungeon(floor=1, seed=seed)
        assert len(dungeon.rooms) >= 2, (
            f"seed={seed}: only {len(dungeon.rooms)} room(s) generated"
        )


# ── All rooms reachable from player start ─────────────────────────────────────

def test_all_rooms_reachable():
    """
    BFS from player_start must reach every room centre and the exit tile.
    This validates that corridors properly connect all rooms.
    """
    for seed in range(10):
        dungeon   = generate_dungeon(floor=1, seed=seed)
        reachable = _flood_reachable(dungeon.grid, dungeon.player_start)

        for i, room in enumerate(dungeon.rooms):
            # room centre should be reachable
            centre = (room.cx, room.cy)
            # centre might land on a wall; check at least one inner tile
            inner  = room.inner_tiles
            assert any(t in reachable for t in inner), (
                f"seed={seed}: Room {i} has no reachable inner tile"
            )

        assert dungeon.exit_pos in reachable, (
            f"seed={seed}: exit {dungeon.exit_pos} not reachable from {dungeon.player_start}"
        )


# ── Exit tile is a stairs tile ────────────────────────────────────────────────

def test_exit_tile_is_stairs():
    """The exit position must be marked T_STAIRS in the grid."""
    for seed in range(5):
        dungeon = generate_dungeon(floor=1, seed=seed)
        ec, er  = dungeon.exit_pos
        assert dungeon.grid[er][ec] == T_STAIRS, (
            f"seed={seed}: exit tile type is {dungeon.grid[er][ec]}, expected T_STAIRS"
        )


# ── Player start is walkable ──────────────────────────────────────────────────

def test_player_start_is_walkable():
    """Player start tile must be a floor tile."""
    from settings import T_FLOOR
    for seed in range(10):
        dungeon = generate_dungeon(floor=1, seed=seed)
        pc, pr  = dungeon.player_start
        tile    = dungeon.grid[pr][pc]
        assert tile in {T_FLOOR, T_CORRIDOR, T_DOOR}, (
            f"seed={seed}: player start ({pc},{pr}) has tile type {tile}"
        )


# ── Room dataclass helpers ────────────────────────────────────────────────────

def test_room_centre():
    r = Room(x=4, y=2, w=8, h=6)
    assert r.cx == 8
    assert r.cy == 5

def test_room_inner_tiles_excludes_border():
    r = Room(x=0, y=0, w=5, h=4)
    inner = r.inner_tiles
    for c, row in inner:
        assert 0 < c < 4  and 0 < row < 3, f"Border tile in inner_tiles: ({c},{row})"


# ── Interactable System Tests ────────────────────────────────────────────────

def test_interactables_spawn_and_manual_chest_open():
    """Verify that interactables spawn properly and chests must be opened manually."""
    from entities import spawn_interactables, Chest, StairsCheckpoint, Shrine

    dungeon = generate_dungeon(floor=1, seed=42)
    interactables = spawn_interactables(dungeon)

    # Must contain chests and exit stairs
    chests = [o for o in interactables if isinstance(o, Chest)]
    stairs = [o for o in interactables if isinstance(o, StairsCheckpoint)]

    assert len(stairs) == 1
    assert len(chests) == len(dungeon.chest_spawns) + len(getattr(dungeon, "vault_chests", []))

    # Test manual chest opening
    if chests:
        chest = chests[0]
        assert chest.can_interact(None) is True
        assert chest.is_open is False
        assert chest.get_prompt(None)[0] == "E"

        world_loot = []
        context = {
            "floor": 1,
            "world_loot": world_loot,
            "particles": [],
            "camera": None,
            "msglog": None,
        }
        chest.interact(context)

        # After interaction: chest is open, loot is created, and cannot interact again
        assert chest.is_open is True
        assert chest.can_interact(None) is False
        assert len(world_loot) > 0


# ── Vault, Doors, and Keys ───────────────────────────────────────────────────

def test_vault_and_locked_doors_generation():
    """Verify vault rooms, locked doors, and key chest assignment."""
    for seed in range(10):
        dungeon = generate_dungeon(floor=1, seed=seed)
        assert hasattr(dungeon, "locked_doors")
        assert hasattr(dungeon, "vault_chests")
        assert hasattr(dungeon, "key_chests")

        # Every locked door position must be in the grid as T_DOOR
        for dc, dr in dungeon.locked_doors:
            assert dungeon.grid[dr][dc] == T_DOOR

        # The exit stairs must never be locked behind a vault door
        assert dungeon.exit_pos not in dungeon.locked_doors


def test_door_interaction_and_unlock():
    """Door blocks until opened with a key, then updates dungeon.locked_doors."""
    from entities import Door
    from inventory import Inventory, make_key

    dungeon = generate_dungeon(floor=1, seed=123)
    dc, dr = 10, 10
    dungeon.locked_doors.add((dc, dr))

    door = Door(dc, dr)
    assert door.is_locked is True
    assert door.is_open is False
    assert door.can_interact(None) is True

    inv = Inventory()
    context = {
        "inventory": inv,
        "dungeon": dungeon,
        "msglog": None,
        "particles": [],
        "camera": None,
    }

    # Interacting without key fails
    door.interact(context)
    assert door.is_locked is True
    assert door.is_open is False
    assert (dc, dr) in dungeon.locked_doors

    # Interacting with key succeeds
    inv.add(make_key())
    door.interact(context)
    assert door.is_locked is False
    assert door.is_open is True
    assert door.can_interact(None) is False
    assert (dc, dr) not in dungeon.locked_doors
    assert inv.has_key() is False


def test_vault_chest_interaction():
    """Vault chests should open and generate high-tier rewards."""
    from entities import VaultChest

    vchest = VaultChest(5, 5)
    assert vchest.is_open is False
    assert vchest.can_interact(None) is True

    world_loot = []
    context = {
        "floor": 2,
        "world_loot": world_loot,
        "particles": [],
        "camera": None,
        "msglog": None,
    }
    vchest.interact(context)
    assert vchest.is_open is True
    assert vchest.can_interact(None) is False
    assert len(world_loot) > 0


def test_merchant_npc_spawns_and_interacts():
    """Merchant NPC should spawn in the safe zone and be trade-ready."""
    from entities import spawn_interactables, MerchantNPC

    dungeon = generate_dungeon(floor=1, seed=77)
    assert dungeon.merchant_spawn is not None

    interactables = spawn_interactables(dungeon)
    merchants = [o for o in interactables if isinstance(o, MerchantNPC)]
    assert len(merchants) == 1

    merchant = merchants[0]
    assert merchant.can_interact(None) is True
    assert merchant.get_prompt(None)[0] == "E"
    assert "Merchant" in merchant.get_prompt(None)[1]

    opened = False
    def mock_open_shop():
        nonlocal opened
        opened = True

    merchant.interact({"open_shop_fn": mock_open_shop, "msglog": None})
    assert opened is True


if __name__ == "__main__":
    import inspect
    funcs = [obj for name, obj in inspect.getmembers(sys.modules[__name__])
             if inspect.isfunction(obj) and name.startswith("test_")]
    passed = 0
    for fn in funcs:
        fn()
        passed += 1
        print(f"  ✓ {fn.__name__}")
    print(f"\nAll {passed} dungeon tests passed!")

