"""Pure maze generation, breadth-first search, and grid-based game rules."""

import random
from collections import deque
from dataclasses import dataclass

Point = tuple[int, int]
DIRECTIONS: tuple[Point, ...] = ((1, 0), (0, 1), (-1, 0), (0, -1))


@dataclass(frozen=True)
class Maze:
    width: int
    height: int
    floor: frozenset[Point]
    start: Point
    exit: Point


def shortest_path(maze: Maze, start: Point, goal: Point) -> list[Point]:
    """Return an inclusive shortest route, or [] for unreachable endpoints."""
    if start not in maze.floor or goal not in maze.floor:
        return []
    parents: dict[Point, Point | None] = {start: None}
    queue = deque([start])
    while queue:
        cell = queue.popleft()
        if cell == goal:
            path = []
            while cell is not None:
                path.append(cell)
                cell = parents[cell]
            return path[::-1]
        for dx, dy in DIRECTIONS:
            neighbor = (cell[0] + dx, cell[1] + dy)
            if neighbor in maze.floor and neighbor not in parents:
                parents[neighbor] = cell
                queue.append(neighbor)
    return []


def generate_maze(width: int, height: int, seed: int) -> Maze:
    """Carve a perfect maze with an iterative randomized depth-first search.

    Odd dimensions >= 5 leave a solid boundary. A local RNG makes seeds
    reproducible without changing randomness elsewhere in an application.
    """
    if width < 5 or height < 5 or width % 2 == 0 or height % 2 == 0:
        raise ValueError("Maze dimensions must be odd integers of at least 5.")
    rng = random.Random(seed)
    floor = {(1, 1)}
    stack = [(1, 1)]
    while stack:
        x, y = stack[-1]
        candidates = [
            (x + 2 * dx, y + 2 * dy)
            for dx, dy in DIRECTIONS
            if 0 < x + 2 * dx < width - 1
            and 0 < y + 2 * dy < height - 1
            and (x + 2 * dx, y + 2 * dy) not in floor
        ]
        if not candidates:
            stack.pop()
            continue
        nx, ny = rng.choice(candidates)
        floor.update({((x + nx) // 2, (y + ny) // 2), (nx, ny)})
        stack.append((nx, ny))
    # The furthest BFS cell gives each seed a substantial escape route.
    queue = deque([(1, 1)])
    seen = {(1, 1)}
    exit_cell = (1, 1)
    while queue:
        exit_cell = queue.popleft()
        for dx, dy in DIRECTIONS:
            neighbor = (exit_cell[0] + dx, exit_cell[1] + dy)
            if neighbor in floor and neighbor not in seen:
                seen.add(neighbor)
                queue.append(neighbor)
    return Maze(width, height, frozenset(floor), (1, 1), exit_cell)


class Game:
    """One run; movement and enemy ticks are controlled by the caller."""

    def __init__(self, maze: Maze, enemy: Point, player: Point | None = None):
        self.maze = maze
        self.player = maze.start if player is None else player
        self.enemy = enemy
        self.status = "playing"
        self.moves = 0

    @classmethod
    def new(cls, seed: int) -> "Game":
        maze = generate_maze(25, 19, seed)
        # The UI grants a head start before the hunter leaves the entrance.
        return cls(maze, maze.start)

    def move(self, dx: int, dy: int) -> bool:
        if self.status != "playing" or (dx, dy) not in DIRECTIONS:
            return False
        target = (self.player[0] + dx, self.player[1] + dy)
        if target not in self.maze.floor:
            return False
        self.player = target
        self.moves += 1
        if self.player == self.enemy:
            self.status = "lost"
        elif self.player == self.maze.exit:
            self.status = "won"
        return True

    def advance_enemy(self) -> None:
        if self.status != "playing":
            return
        route = shortest_path(self.maze, self.enemy, self.player)
        if len(route) > 1:
            self.enemy = route[1]
        if self.enemy == self.player:
            self.status = "lost"
