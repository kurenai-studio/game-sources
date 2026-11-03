"""
Comprehensive Maze Generation Strategy Suite
Implements:
1. Randomized Kruskal's Algorithm (Disjoint Set / Union-Find with rank and path compression)
2. Randomized Prim's Algorithm (Minimum Spanning Tree)
3. Wilson's Algorithm (Loop-Erased Random Walk for unbiased Uniform Spanning Trees)
4. Iterative Depth-First Search Backtracker (Non-recursive, O(1) visited checks)
"""

import random
from collections import deque
from abc import ABC, abstractmethod
from typing import Dict, Set, List, Tuple, Optional
from .graph import Graph, create_grid_graph

Point = Tuple[int, int]

class DisjointSet:
    """
    Disjoint Set Union (DSU / Union-Find) data structure.
    Implements Path Compression and Union by Rank for amortized O(alpha(N)) efficiency.
    """
    def __init__(self, elements: List[Point]):
        self.parent: Dict[Point, Point] = {e: e for e in elements}
        self.rank: Dict[Point, int] = {e: 0 for e in elements}

    def find(self, i: Point) -> Point:
        """Finds root of representative set with recursive path compression."""
        if self.parent[i] != i:
            self.parent[i] = self.find(self.parent[i])
        return self.parent[i]

    def union(self, i: Point, j: Point) -> bool:
        """
        Unites sets containing i and j using rank heuristics.
        Returns True if merged, False if already in the same set (cycle prevention).
        """
        root_i = self.find(i)
        root_j = self.find(j)
        if root_i == root_j:
            return False

        if self.rank[root_i] < self.rank[root_j]:
            self.parent[root_i] = root_j
        elif self.rank[root_i] > self.rank[root_j]:
            self.parent[root_j] = root_i
        else:
            self.parent[root_j] = root_i
            self.rank[root_i] += 1
        return True

class MazeGenerator(ABC):
    """Abstract base class for spanning tree maze generation algorithms."""
    
    @abstractmethod
    def generate(self, width: int, height: int, seed: Optional[int] = None) -> Graph:
        """Generates a perfect spanning tree maze as a Graph instance."""
        pass

    @property
    @abstractmethod
    def name(self) -> str:
        """Human-readable algorithm identifier."""
        pass

    @property
    @abstractmethod
    def description(self) -> str:
        """Academic description of theoretical characteristics and bias."""
        pass


class KruskalGenerator(MazeGenerator):
    """
    Randomized Kruskal's Algorithm using Disjoint Set Forest.
    Theoretical Property: Uniform edge sampling, produces high dead-end density (~30%)
    and short cul-de-sacs with uniform branching characteristics.
    """
    @property
    def name(self) -> str:
        return "Randomized Kruskal's (MST)"

    @property
    def description(self) -> str:
        return "Minimum Spanning Tree via Union-Find. High junction density and balanced branches."

    def generate(self, width: int, height: int, seed: Optional[int] = None) -> Graph:
        if seed is not None:
            random.seed(seed)

        maze = create_grid_graph(width, height)
        all_cells = [(x, y) for x in range(width) for y in range(height)]
        dsu = DisjointSet(all_cells)

        # Generate all internal potential grid edges
        walls: List[Tuple[Point, Point]] = []
        for x in range(width):
            for y in range(height):
                if x + 1 < width:
                    walls.append(((x, y), (x + 1, y)))
                if y + 1 < height:
                    walls.append(((x, y), (x, y + 1)))

        random.shuffle(walls)

        # Connect components without forming cycles
        for u, v in walls:
            if dsu.union(u, v):
                maze.add_bidirectional_edge(u, v)

        return maze


class PrimGenerator(MazeGenerator):
    """
    Randomized Prim's Algorithm.
    Theoretical Property: Grows organically outward from a start point.
    Produces tight, tree-like mazes with very high dead-end density (~35%).
    """
    @property
    def name(self) -> str:
        return "Randomized Prim's (MST)"

    @property
    def description(self) -> str:
        return "Growing tree frontier expansion. Produces short, compact cul-de-sacs."

    def generate(self, width: int, height: int, seed: Optional[int] = None) -> Graph:
        if seed is not None:
            random.seed(seed)

        maze = create_grid_graph(width, height)
        start_cell = (random.randint(0, width - 1), random.randint(0, height - 1))
        
        in_maze: Set[Point] = {start_cell}
        frontier_walls: List[Tuple[Point, Point]] = []

        def add_frontiers(cell: Point):
            x, y = cell
            for dx, dy in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in in_maze:
                    frontier_walls.append((cell, (nx, ny)))

        add_frontiers(start_cell)

        while frontier_walls:
            # Pick a random wall from the frontier list
            idx = random.randrange(len(frontier_walls))
            u, v = frontier_walls.pop(idx)

            if v not in in_maze:
                in_maze.add(v)
                maze.add_bidirectional_edge(u, v)
                add_frontiers(v)

        return maze


class WilsonGenerator(MazeGenerator):
    """
    Wilson's Algorithm using Loop-Erased Random Walks (LERW).
    Theoretical Property: Mathematically unbiased Uniform Spanning Tree (UST).
    Every spanning tree has an identical probability of being generated,
    eliminating directional, corridor-length, or branching bias entirely.
    """
    @property
    def name(self) -> str:
        return "Wilson's Algorithm (Unbiased UST)"

    @property
    def description(self) -> str:
        return "Loop-Erased Random Walk. Generates mathematically provable unbiased Uniform Spanning Trees."

    def generate(self, width: int, height: int, seed: Optional[int] = None) -> Graph:
        if seed is not None:
            random.seed(seed)

        maze = create_grid_graph(width, height)
        unvisited: Set[Point] = {(x, y) for x in range(width) for y in range(height)}

        # Pick initial arbitrary root vertex
        first_cell = (random.randint(0, width - 1), random.randint(0, height - 1))
        unvisited.remove(first_cell)

        def get_neighbors(cell: Point) -> List[Point]:
            x, y = cell
            res = []
            for dx, dy in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < width and 0 <= ny < height:
                    res.append((nx, ny))
            return res

        while unvisited:
            # Start random walk from an unvisited cell
            current = random.choice(list(unvisited))
            walk: List[Point] = [current]
            walk_indices: Dict[Point, int] = {current: 0}

            # Loop-Erased Random Walk until we intersect the existing maze
            while current in unvisited:
                neighbors = get_neighbors(current)
                next_cell = random.choice(neighbors)

                if next_cell in walk_indices:
                    # Loop detected: erase loop
                    erase_idx = walk_indices[next_cell]
                    for node in walk[erase_idx + 1:]:
                        del walk_indices[node]
                    walk = walk[:erase_idx + 1]
                    current = next_cell
                else:
                    walk_indices[next_cell] = len(walk)
                    walk.append(next_cell)
                    current = next_cell

            # Carve path from walk into maze
            for i in range(len(walk) - 1):
                u, v = walk[i], walk[i + 1]
                maze.add_bidirectional_edge(u, v)
                if u in unvisited:
                    unvisited.remove(u)
                if v in unvisited:
                    unvisited.remove(v)

        return maze


class DFSBacktrackerGenerator(MazeGenerator):
    """
    Iterative Depth-First Search Backtracker.
    Theoretical Property: High directional bias, long winding corridors,
    low junction density, few dead ends (~10%).
    Refactored with an explicit stack to eliminate Python recursion limits.
    """
    @property
    def name(self) -> str:
        return "Recursive Backtracker (DFS)"

    @property
    def description(self) -> str:
        return "Iterative stack DFS. Generates long, winding corridors with fewer dead ends."

    def generate(self, width: int, height: int, seed: Optional[int] = None) -> Graph:
        if seed is not None:
            random.seed(seed)

        maze = create_grid_graph(width, height)
        start_cell = (width // 2, height // 2)
        
        visited: Set[Point] = {start_cell}
        stack: List[Point] = [start_cell]

        directions = [(0, -1), (0, 1), (-1, 0), (1, 0)]  # Up, Down, Left, Right

        while stack:
            current = stack[-1]
            x, y = current

            # Find unvisited neighbors
            unvisited_neighbors: List[Point] = []
            for dx, dy in directions:
                nx, ny = x + dx, y + dy
                if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in visited:
                    unvisited_neighbors.append((nx, ny))

            if unvisited_neighbors:
                chosen = random.choice(unvisited_neighbors)
                visited.add(chosen)
                maze.add_bidirectional_edge(current, chosen)
                stack.append(chosen)
            else:
                stack.pop()

        return maze


# Registry of available generator algorithms
GENERATOR_REGISTRY: Dict[str, MazeGenerator] = {
    "kruskal": KruskalGenerator(),
    "prim": PrimGenerator(),
    "wilson": WilsonGenerator(),
    "dfs": DFSBacktrackerGenerator()
}

def generate_maze(algorithm: str = "kruskal", width: int = 20, height: int = 20, seed: Optional[int] = None) -> Graph:
    """Convenience factory function to generate a maze by algorithm name."""
    algo_key = algorithm.lower().strip()
    generator = GENERATOR_REGISTRY.get(algo_key, GENERATOR_REGISTRY["kruskal"])
    return generator.generate(width, height, seed)
