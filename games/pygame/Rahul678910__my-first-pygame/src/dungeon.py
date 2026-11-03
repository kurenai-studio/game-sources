"""
dungeon.py
Procedural dungeon generation: random rooms, 2-wide corridors, MST connectivity,
stair checkpoint platform, and spawn placement.

Key improvements over Phase 1–3:
  • Rooms are smaller and more numerous → less boxy feel
  • Corridors are 2 tiles wide → player never gets stuck
  • MST (Prim's) + extra loops → every room reachable, multiple routes
  • Stairs are placed in a distinct 3×3 platform in the room farthest from the start
  • Exit room is always the room with the greatest Manhattan distance from start

Public API
----------
generate_dungeon(floor, seed) -> Dungeon
is_walkable(grid, col, row)   -> bool
"""

import random
from dataclasses import dataclass, field
from typing import List, Tuple

from settings import (
    COLS, ROWS,
    ROOM_MIN_W, ROOM_MAX_W, ROOM_MIN_H, ROOM_MAX_H,
    MIN_ROOMS, MAX_ROOMS, CORRIDOR_WIDTH,
    FLOOR_ENEMY_MULT,
    T_EMPTY, T_WALL, T_FLOOR, T_CORRIDOR, T_DOOR, T_STAIRS,
)


# ─────────────────────────────────────────────────────────────────────────────
# Data structures
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class Room:
    """Axis-aligned rectangular room in tile coordinates."""
    x: int   # left column
    y: int   # top row
    w: int   # width  in tiles
    h: int   # height in tiles

    @property
    def cx(self) -> int:
        return self.x + self.w // 2

    @property
    def cy(self) -> int:
        return self.y + self.h // 2

    @property
    def inner_tiles(self) -> List[Tuple[int, int]]:
        """All (col, row) floor tiles inside the room (border excluded)."""
        return [
            (c, r)
            for c in range(self.x + 1, self.x + self.w - 1)
            for r in range(self.y + 1, self.y + self.h - 1)
        ]

    def intersects(self, other: "Room", margin: int = 1) -> bool:
        """True if this room overlaps *other* (with a safety margin)."""
        return (
            self.x - margin < other.x + other.w and
            self.x + self.w + margin > other.x and
            self.y - margin < other.y + other.h and
            self.y + self.h + margin > other.y
        )

    def manhattan(self, other: "Room") -> int:
        return abs(self.cx - other.cx) + abs(self.cy - other.cy)


@dataclass
class Dungeon:
    """All dungeon data passed between modules."""
    grid:         List[List[int]]
    rooms:        List[Room]
    player_start: Tuple[int, int]   # (col, row) tile
    exit_pos:     Tuple[int, int]   # stairs tile (col, row)
    floor:        int

    enemy_spawns: List[Tuple[int, int]] = field(default_factory=list)
    chest_spawns: List[Tuple[int, int]] = field(default_factory=list)
    shrine_spawn: Tuple[int, int] = None
    merchant_spawn: Tuple[int, int] = None
    locked_doors: set = field(default_factory=set)
    vault_chests: List[Tuple[int, int]] = field(default_factory=list)
    key_chests:   set = field(default_factory=set)


# ─────────────────────────────────────────────────────────────────────────────
# Grid helpers
# ─────────────────────────────────────────────────────────────────────────────

def _empty_grid() -> List[List[int]]:
    return [[T_EMPTY] * COLS for _ in range(ROWS)]


def _carve_room(grid: List[List[int]], room: Room) -> None:
    """Stamp a room onto the grid: border = T_WALL, interior = T_FLOOR."""
    for r in range(room.y, room.y + room.h):
        for c in range(room.x, room.x + room.w):
            if r == room.y or r == room.y + room.h - 1:
                grid[r][c] = T_WALL
            elif c == room.x or c == room.x + room.w - 1:
                grid[r][c] = T_WALL
            else:
                grid[r][c] = T_FLOOR


def _place_corridor_tile(grid: List[List[int]], c: int, r: int) -> None:
    """
    Stamp one corridor tile.
    - T_EMPTY → T_CORRIDOR  (open rock between rooms)
    - T_WALL  → T_CORRIDOR  (punches a doorway through a room's border wall)
    - T_FLOOR / T_STAIRS    (room interior wins — left unchanged)
    """
    if 0 <= r < ROWS and 0 <= c < COLS:
        if grid[r][c] in (T_EMPTY, T_WALL):   # overwrite walls to create openings
            grid[r][c] = T_CORRIDOR


def _carve_corridor(
    grid: List[List[int]],
    ax: int, ay: int,
    bx: int, by: int,
    rng: random.Random,
) -> None:
    """
    Carve a CORRIDOR_WIDTH-wide L-shaped corridor between (ax,ay) and (bx,by).

    The corridor is 2 tiles wide so the player is never squeezed into a
    single-pixel gap. The expansion direction (up/down for horizontal
    segments, left/right for vertical) is chosen randomly for variety.
    """
    expand_h = rng.choice([-1, 1])   # horizontal segment expands ± row
    expand_v = rng.choice([-1, 1])   # vertical segment expands ± col

    if rng.random() < 0.5:
        # Horizontal first, then vertical
        hx1, hx2, hy = min(ax, bx), max(ax, bx), ay
        vx, vy1, vy2 = bx, min(ay, by), max(ay, by)
    else:
        # Vertical first, then horizontal
        vx, vy1, vy2 = ax, min(ay, by), max(ay, by)
        hx1, hx2, hy = min(ax, bx), max(ax, bx), by

    for c in range(hx1, hx2 + 1):
        for w in range(CORRIDOR_WIDTH):
            _place_corridor_tile(grid, c, hy + expand_h * w)

    for r in range(vy1, vy2 + 1):
        for w in range(CORRIDOR_WIDTH):
            _place_corridor_tile(grid, vx + expand_v * w, r)


def _add_walls_around_corridors(grid: List[List[int]]) -> None:
    """Turn T_EMPTY tiles adjacent to any corridor into T_WALL (gives edges)."""
    neighbours = [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]
    for r in range(ROWS):
        for c in range(COLS):
            if grid[r][c] == T_CORRIDOR:
                for dr, dc in neighbours:
                    nr, nc = r + dr, c + dc
                    if 0 <= nr < ROWS and 0 <= nc < COLS:
                        if grid[nr][nc] == T_EMPTY:
                            grid[nr][nc] = T_WALL


def _carve_stair_platform(
    grid: List[List[int]],
    col: int, row: int,
) -> None:
    """
    Carve a clear 3×3 floor platform centred on (col, row) and place
    T_STAIRS at the centre.  This creates a visible checkpoint the player
    must physically reach to descend.
    """
    for r in range(row - 1, row + 2):
        for c in range(col - 1, col + 2):
            if 0 <= r < ROWS and 0 <= c < COLS:
                grid[r][c] = T_FLOOR          # clear obstacles
    grid[row][col] = T_STAIRS                  # stamp the stair tile


# ─────────────────────────────────────────────────────────────────────────────
# Connectivity — Prim's MST + extra loop edges
# ─────────────────────────────────────────────────────────────────────────────

def _mst_connections(
    rooms: List[Room],
    rng: random.Random,
) -> List[Tuple[int, int]]:
    """
    Build a Minimum Spanning Tree over *rooms* (Manhattan distance) using
    Prim's algorithm, then add ≥ 2 extra edges to create loop paths.

    Returns
    -------
    list of (i, j) index pairs to connect with corridors.
    """
    n = len(rooms)
    if n < 2:
        return []

    in_tree  = {0}
    not_tree = set(range(1, n))
    edges    = []

    while not_tree:
        best_dist = float("inf")
        best_pair = (0, 1)
        for i in in_tree:
            for j in not_tree:
                d = rooms[i].manhattan(rooms[j])
                if d < best_dist:
                    best_dist = d
                    best_pair = (i, j)
        edges.append(best_pair)
        in_tree.add(best_pair[1])
        not_tree.discard(best_pair[1])

    # Extra loop connections (at least 2, up to n//3) to give the player
    # alternative routes when a path is blocked by enemies.
    extra = max(2, n // 3)
    for _ in range(extra):
        i = rng.randint(0, n - 1)
        j = rng.randint(0, n - 1)
        if i != j:
            edges.append((i, j))

    return edges


# ─────────────────────────────────────────────────────────────────────────────
# BFS reachability (used by tests + internal validation)
# ─────────────────────────────────────────────────────────────────────────────

def _flood_reachable(
    grid: List[List[int]],
    start: Tuple[int, int],
) -> set:
    """BFS from (col, row) *start*; returns set of all reachable walkable tiles."""
    walkable = {T_FLOOR, T_CORRIDOR, T_DOOR, T_STAIRS}
    visited  = {start}
    queue    = [start]
    while queue:
        c, r = queue.pop()
        for dc, dr in [(1,0),(-1,0),(0,1),(0,-1)]:
            nxt = (c+dc, r+dr)
            nc, nr = nxt
            if nxt not in visited and 0 <= nr < ROWS and 0 <= nc < COLS:
                if grid[nr][nc] in walkable:
                    visited.add(nxt)
                    queue.append(nxt)
    return visited


def _pick_random_floor(
    room: Room,
    rng: random.Random,
) -> Tuple[int, int]:
    """Return a random interior floor tile from *room*."""
    return rng.choice(room.inner_tiles)


# ─────────────────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────────────────

def generate_dungeon(floor: int = 1, seed: int = None) -> Dungeon:
    """
    Build and return a procedurally generated Dungeon.

    Generation steps
    ----------------
    1. Place small random rooms (no overlap).
    2. Connect all rooms with a Prim's MST + extra loop corridors.
       Corridors are 2 tiles wide — the player is never squeezed.
    3. Walls are filled around all corridors.
    4. Player starts in the room nearest the top-left.
       Exit stairs are placed in the room **farthest** from the start,
       with a 3×3 clear checkpoint platform.
    5. Enemies and chests are assigned to non-start rooms.

    Parameters
    ----------
    floor : int   Current floor (affects room count, enemy density).
    seed  : int | None   Optional RNG seed (None = random each run).
    """
    rng = random.Random(seed)

    # Scale room count with depth (capped)
    target_rooms = min(MAX_ROOMS, MIN_ROOMS + (floor - 1))

    grid : List[List[int]] = _empty_grid()
    rooms: List[Room]      = []

    # ── 1. Place rooms ────────────────────────────────────────────────────────
    for _ in range(400):          # generous attempt budget
        if len(rooms) >= target_rooms:
            break
        w = rng.randint(ROOM_MIN_W, ROOM_MAX_W)
        h = rng.randint(ROOM_MIN_H, ROOM_MAX_H)
        x = rng.randint(1, COLS - w - 2)
        y = rng.randint(1, ROWS - h - 2)
        nr = Room(x, y, w, h)
        if not any(nr.intersects(existing) for existing in rooms):
            _carve_room(grid, nr)
            rooms.append(nr)

    # Fallback guarantee
    if len(rooms) < 2:
        rooms = [Room(2, 2, 6, 5), Room(COLS - 10, ROWS - 9, 6, 5)]
        for room in rooms:
            _carve_room(grid, room)

    # ── 2. Connect rooms (MST + extra loops → multiple paths) ─────────────────
    for i, j in _mst_connections(rooms, rng):
        _carve_corridor(grid, rooms[i].cx, rooms[i].cy,
                              rooms[j].cx, rooms[j].cy, rng)

    # ── 3. Wall borders around corridors ──────────────────────────────────────
    _add_walls_around_corridors(grid)

    # ── 4. Choose start / exit (farthest pair) ────────────────────────────────
    # Start = room closest to top-left corner of the map
    start_room = min(rooms, key=lambda r: r.cx + r.cy)
    # Exit   = room with greatest Manhattan distance from start
    exit_room  = max(
        [r for r in rooms if r is not start_room],
        key=lambda r: start_room.manhattan(r),
    )

    player_start = _pick_random_floor(start_room, rng)
    exit_col, exit_row = exit_room.cx, exit_room.cy
    _carve_stair_platform(grid, exit_col, exit_row)

    # ── 5. Spawn hints (enemies + chests, skip start room) ────────────────────
    enemy_spawns: List[Tuple[int, int]] = []
    chest_spawns: List[Tuple[int, int]] = []

    non_start = [r for r in rooms if r is not start_room]
    for room in non_start:
        tiles = room.inner_tiles
        if not tiles:
            continue
        max_enemies = min(len(tiles), max(1, int(3 * (FLOOR_ENEMY_MULT ** (floor - 1)))))
        n_en = rng.randint(1, max_enemies)
        chosen = rng.sample(tiles, n_en)
        enemy_spawns.extend(chosen)
        if rng.random() < 0.45:
            remaining = [t for t in tiles if t not in chosen]
            if remaining:
                chest_spawns.append(rng.choice(remaining))

    # ── 6. Shrine spawn (mystic altar placed in an exploration room) ─────────
    shrine_spawn = None
    shrine_rooms = [r for r in non_start if r is not exit_room]
    if shrine_rooms:
        s_room = rng.choice(shrine_rooms)
        candidates = [t for t in s_room.inner_tiles if t not in enemy_spawns and t not in chest_spawns]
        if candidates:
            shrine_spawn = rng.choice(candidates)

    # ── 7. Locked Vault Room & Doors ──────────────────────────────────────────
    locked_doors: set = set()
    vault_chests: List[Tuple[int, int]] = []
    key_chests:   set = set()

    vault_candidates = [
        r for r in non_start
        if r is not exit_room and (shrine_spawn is None or shrine_spawn not in r.inner_tiles)
    ]
    if vault_candidates:
        def _find_room_doorways(rm: Room):
            doors = []
            for c in range(rm.x, rm.x + rm.w):
                for r in (rm.y, rm.y + rm.h - 1):
                    if 0 <= r < ROWS and 0 <= c < COLS and grid[r][c] in (T_CORRIDOR, T_DOOR):
                        doors.append((c, r))
            for r in range(rm.y, rm.y + rm.h):
                for c in (rm.x, rm.x + rm.w - 1):
                    if 0 <= r < ROWS and 0 <= c < COLS and grid[r][c] in (T_CORRIDOR, T_DOOR):
                        doors.append((c, r))
            return list(set(doors))

        # Select a side chamber with 1-2 doorway connections
        candidates_with_doors = [r for r in vault_candidates if _find_room_doorways(r)]
        if candidates_with_doors:
            vault_room = min(candidates_with_doors, key=lambda rm: len(_find_room_doorways(rm)))
            doorways = _find_room_doorways(vault_room)
            for dc, dr in doorways:
                grid[dr][dc] = T_DOOR
                locked_doors.add((dc, dr))

            # Guaranteed high-tier Vault Chest inside the vault
            vault_inner = [t for t in vault_room.inner_tiles if t not in enemy_spawns]
            if vault_inner:
                vt = rng.choice(vault_inner)
                vault_chests.append(vt)
                if vt in chest_spawns:
                    chest_spawns.remove(vt)

            # Designate an accessible chest outside the vault to contain the Dungeon Key
            outside_chests = [c for c in chest_spawns if c not in vault_room.inner_tiles]
            if outside_chests:
                key_chests.add(rng.choice(outside_chests))
            else:
                outside_rooms = [r for r in non_start if r is not vault_room and r is not exit_room]
                target_room = rng.choice(outside_rooms) if outside_rooms else start_room
                free_tiles = [t for t in target_room.inner_tiles if t not in enemy_spawns and t not in chest_spawns]
                if free_tiles:
                    kc = rng.choice(free_tiles)
                    chest_spawns.append(kc)
                    key_chests.add(kc)

    # ── 8. Merchant spawn (Friendly NPC in the starting room safe zone) ─────────
    merchant_spawn = None
    start_candidates = [
        t for t in start_room.inner_tiles
        if t != player_start and (abs(t[0] - player_start[0]) + abs(t[1] - player_start[1]) >= 2)
    ]
    if start_candidates:
        merchant_spawn = start_candidates[0]
    elif start_room.inner_tiles:
        non_center = [t for t in start_room.inner_tiles if t != player_start]
        if non_center:
            merchant_spawn = non_center[0]

    return Dungeon(
        grid         = grid,
        rooms        = rooms,
        player_start = player_start,
        exit_pos     = (exit_col, exit_row),
        floor        = floor,
        enemy_spawns = enemy_spawns,
        chest_spawns = chest_spawns,
        shrine_spawn = shrine_spawn,
        merchant_spawn = merchant_spawn,
        locked_doors = locked_doors,
        vault_chests = vault_chests,
        key_chests   = key_chests,
    )


# ─────────────────────────────────────────────────────────────────────────────
# Utility
# ─────────────────────────────────────────────────────────────────────────────

def is_walkable(grid: List[List[int]], col: int, row: int) -> bool:
    """Return True if tile at (col, row) can be walked on."""
    if not (0 <= row < ROWS and 0 <= col < COLS):
        return False
    return grid[row][col] in {T_FLOOR, T_CORRIDOR, T_DOOR, T_STAIRS}
