"""
Comprehensive Pathfinding & Graph Search Solver Suite.
Implements:
1. A* Heuristic Search (Optimal heap priority, Manhattan/Euclidean/Chebyshev)
2. Dijkstra's Algorithm (Uniform Cost Search)
3. Bidirectional A* Search (Dual-frontier convergence)
4. Breadth-First Search (BFS)
5. Depth-First Search (DFS)
6. Greedy Best-First Search (GBFS)
"""

import time
import heapq
import itertools
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from collections import deque
from typing import Dict, Set, List, Tuple, Callable, Optional, Any
from .graph import Graph
from .heuristics import manhattan_distance, euclidean_distance, chebyshev_distance

Point = Tuple[int, int]

@dataclass
class SolveResult:
    """Encapsulates the mathematical and computational metrics of a search run."""
    path: List[Point]
    nodes_expanded: int
    execution_time_us: float
    path_cost: float
    closed_set: Set[Point] = field(default_factory=set)
    steps_history: Optional[List[Dict[str, Any]]] = None

    @property
    def found(self) -> bool:
        return len(self.path) > 0

    @property
    def path_length(self) -> int:
        return max(0, len(self.path) - 1)


class PathfindingSolver(ABC):
    """Abstract base class for graph pathfinding algorithms."""

    @abstractmethod
    def solve(
        self,
        start: Point,
        goal: Point,
        graph: Graph,
        heuristic_fn: Callable[[Point, Point], float] = manhattan_distance,
        record_history: bool = False
    ) -> SolveResult:
        """Finds a path between start and goal on the given Graph."""
        pass

    @property
    @abstractmethod
    def name(self) -> str:
        pass


class AStarSolver(PathfindingSolver):
    """
    A* Search Algorithm with provably optimal priority queue implementation.
    Sorts strictly by f(n) = g(n) + h(n), using a monotonic tie-breaker counter
    to avoid coordinate tuple comparison errors.
    """
    @property
    def name(self) -> str:
        return "A* Heuristic Search"

    def solve(
        self,
        start: Point,
        goal: Point,
        graph: Graph,
        heuristic_fn: Callable[[Point, Point], float] = manhattan_distance,
        record_history: bool = False
    ) -> SolveResult:
        start_time = time.perf_counter_ns()
        
        counter = itertools.count()
        # open_set stores tuples: (f_score, tie_breaker, vertex)
        h_start = heuristic_fn(start, goal)
        open_set: List[Tuple[float, int, Point]] = [(h_start, next(counter), start)]
        
        came_from: Dict[Point, Point] = {}
        g_score: Dict[Point, float] = {start: 0.0}
        f_score: Dict[Point, float] = {start: h_start}
        closed_set: Set[Point] = set()
        
        nodes_expanded = 0
        history = [] if record_history else None

        while open_set:
            current_f, _, current = heapq.heappop(open_set)

            if current == goal:
                elapsed_us = (time.perf_counter_ns() - start_time) / 1000.0
                path = self._reconstruct_path(came_from, current)
                return SolveResult(
                    path=path,
                    nodes_expanded=nodes_expanded,
                    execution_time_us=elapsed_us,
                    path_cost=g_score[goal],
                    closed_set=closed_set,
                    steps_history=history
                )

            if current in closed_set:
                continue

            closed_set.add(current)
            nodes_expanded += 1

            if record_history:
                history.append({
                    "current": current,
                    "frontier": {item[2] for item in open_set},
                    "closed": set(closed_set),
                    "f": current_f,
                    "g": g_score.get(current, 0.0)
                })

            for neighbor in graph.neighbours(current):
                if neighbor in closed_set:
                    continue

                tentative_g = g_score[current] + 1.0  # Unit grid edge weight

                if tentative_g < g_score.get(neighbor, float('inf')):
                    came_from[neighbor] = current
                    g_score[neighbor] = tentative_g
                    f_val = tentative_g + heuristic_fn(neighbor, goal)
                    f_score[neighbor] = f_val
                    heapq.heappush(open_set, (f_val, next(counter), neighbor))

        elapsed_us = (time.perf_counter_ns() - start_time) / 1000.0
        return SolveResult(
            path=[],
            nodes_expanded=nodes_expanded,
            execution_time_us=elapsed_us,
            path_cost=float('inf'),
            closed_set=closed_set,
            steps_history=history
        )

    def _reconstruct_path(self, came_from: Dict[Point, Point], current: Point) -> List[Point]:
        path = [current]
        while current in came_from:
            current = came_from[current]
            path.append(current)
        path.reverse()
        return path


class DijkstraSolver(PathfindingSolver):
    """
    Dijkstra's Algorithm (Uniform Cost Search).
    Equivalent to A* with h(n) = 0. Explores spherically outward along lowest g(n).
    """
    @property
    def name(self) -> str:
        return "Dijkstra's Algorithm"

    def solve(
        self,
        start: Point,
        goal: Point,
        graph: Graph,
        heuristic_fn: Callable[[Point, Point], float] = manhattan_distance,
        record_history: bool = False
    ) -> SolveResult:
        # Dijkstra is A* with a zero heuristic
        zero_heuristic = lambda a, b: 0.0
        solver = AStarSolver()
        res = solver.solve(start, goal, graph, zero_heuristic, record_history)
        return res


class BidirectionalAStarSolver(PathfindingSolver):
    """
    Bidirectional A* Search.
    Expands two simultaneous search frontiers from start and goal,
    terminating when the frontiers intersect at a midpoint vertex.
    Reduces explored search volume substantially.
    """
    @property
    def name(self) -> str:
        return "Bidirectional A* Search"

    def solve(
        self,
        start: Point,
        goal: Point,
        graph: Graph,
        heuristic_fn: Callable[[Point, Point], float] = manhattan_distance,
        record_history: bool = False
    ) -> SolveResult:
        start_time = time.perf_counter_ns()
        
        if start == goal:
            return SolveResult([start], 0, 0.0, 0.0, {start})

        counter_f = itertools.count()
        counter_b = itertools.count()

        # Forward search state
        open_f = [(heuristic_fn(start, goal), next(counter_f), start)]
        came_from_f: Dict[Point, Point] = {}
        g_f: Dict[Point, float] = {start: 0.0}
        closed_f: Set[Point] = set()

        # Backward search state
        open_b = [(heuristic_fn(goal, start), next(counter_b), goal)]
        came_from_b: Dict[Point, Point] = {}
        g_b: Dict[Point, float] = {goal: 0.0}
        closed_b: Set[Point] = set()

        nodes_expanded = 0
        intersect_node: Optional[Point] = None

        while open_f and open_b:
            # Step Forward
            _, _, curr_f = heapq.heappop(open_f)
            if curr_f not in closed_f:
                closed_f.add(curr_f)
                nodes_expanded += 1

                if curr_f in closed_b:
                    intersect_node = curr_f
                    break

                for nxt in graph.neighbours(curr_f):
                    if nxt in closed_f: continue
                    tentative = g_f[curr_f] + 1.0
                    if tentative < g_f.get(nxt, float('inf')):
                        came_from_f[nxt] = curr_f
                        g_f[nxt] = tentative
                        f_score = tentative + heuristic_fn(nxt, goal)
                        heapq.heappush(open_f, (f_score, next(counter_f), nxt))

            # Step Backward
            _, _, curr_b = heapq.heappop(open_b)
            if curr_b not in closed_b:
                closed_b.add(curr_b)
                nodes_expanded += 1

                if curr_b in closed_f:
                    intersect_node = curr_b
                    break

                for nxt in graph.neighbours(curr_b):
                    if nxt in closed_b: continue
                    tentative = g_b[curr_b] + 1.0
                    if tentative < g_b.get(nxt, float('inf')):
                        came_from_b[nxt] = curr_b
                        g_b[nxt] = tentative
                        f_score = tentative + heuristic_fn(nxt, start)
                        heapq.heappush(open_b, (f_score, next(counter_b), nxt))

        elapsed_us = (time.perf_counter_ns() - start_time) / 1000.0

        if intersect_node is not None:
            # Reconstruct forward path
            p_f = []
            curr = intersect_node
            while curr in came_from_f:
                p_f.append(curr)
                curr = came_from_f[curr]
            p_f.append(start)
            p_f.reverse()

            # Reconstruct backward path
            p_b = []
            curr = intersect_node
            while curr in came_from_b:
                curr = came_from_b[curr]
                p_b.append(curr)

            total_path = p_f + p_b
            cost = float(len(total_path) - 1)
            return SolveResult(total_path, nodes_expanded, elapsed_us, cost, closed_f | closed_b)

        return SolveResult([], nodes_expanded, elapsed_us, float('inf'), closed_f | closed_b)


class BFSSolver(PathfindingSolver):
    """Breadth-First Search (BFS) finding unweighted shortest paths."""
    @property
    def name(self) -> str:
        return "Breadth-First Search (BFS)"

    def solve(
        self,
        start: Point,
        goal: Point,
        graph: Graph,
        heuristic_fn: Callable[[Point, Point], float] = manhattan_distance,
        record_history: bool = False
    ) -> SolveResult:
        start_time = time.perf_counter_ns()
        queue = deque([start])
        came_from: Dict[Point, Point] = {}
        visited: Set[Point] = {start}
        nodes_expanded = 0

        while queue:
            current = queue.popleft()
            nodes_expanded += 1

            if current == goal:
                elapsed_us = (time.perf_counter_ns() - start_time) / 1000.0
                path = [current]
                while current in came_from:
                    current = came_from[current]
                    path.append(current)
                path.reverse()
                return SolveResult(path, nodes_expanded, elapsed_us, float(len(path) - 1), visited)

            for neighbor in graph.neighbours(current):
                if neighbor not in visited:
                    visited.add(neighbor)
                    came_from[neighbor] = current
                    queue.append(neighbor)

        elapsed_us = (time.perf_counter_ns() - start_time) / 1000.0
        return SolveResult([], nodes_expanded, elapsed_us, float('inf'), visited)


class DFSSolver(PathfindingSolver):
    """Depth-First Search (DFS) exploratory pathfinder (non-optimal)."""
    @property
    def name(self) -> str:
        return "Depth-First Search (DFS)"

    def solve(
        self,
        start: Point,
        goal: Point,
        graph: Graph,
        heuristic_fn: Callable[[Point, Point], float] = manhattan_distance,
        record_history: bool = False
    ) -> SolveResult:
        start_time = time.perf_counter_ns()
        stack = [start]
        came_from: Dict[Point, Point] = {}
        visited: Set[Point] = {start}
        nodes_expanded = 0

        while stack:
            current = stack.pop()
            nodes_expanded += 1

            if current == goal:
                elapsed_us = (time.perf_counter_ns() - start_time) / 1000.0
                path = [current]
                while current in came_from:
                    current = came_from[current]
                    path.append(current)
                path.reverse()
                return SolveResult(path, nodes_expanded, elapsed_us, float(len(path) - 1), visited)

            for neighbor in graph.neighbours(current):
                if neighbor not in visited:
                    visited.add(neighbor)
                    came_from[neighbor] = current
                    stack.append(neighbor)

        elapsed_us = (time.perf_counter_ns() - start_time) / 1000.0
        return SolveResult([], nodes_expanded, elapsed_us, float('inf'), visited)


class GreedyBestFirstSolver(PathfindingSolver):
    """Greedy Best-First Search (GBFS) prioritizing solely h(n). Fast but non-optimal."""
    @property
    def name(self) -> str:
        return "Greedy Best-First Search (GBFS)"

    def solve(
        self,
        start: Point,
        goal: Point,
        graph: Graph,
        heuristic_fn: Callable[[Point, Point], float] = manhattan_distance,
        record_history: bool = False
    ) -> SolveResult:
        start_time = time.perf_counter_ns()
        counter = itertools.count()
        open_set = [(heuristic_fn(start, goal), next(counter), start)]
        came_from: Dict[Point, Point] = {}
        visited: Set[Point] = set()
        nodes_expanded = 0

        while open_set:
            _, _, current = heapq.heappop(open_set)

            if current == goal:
                elapsed_us = (time.perf_counter_ns() - start_time) / 1000.0
                path = [current]
                while current in came_from:
                    current = came_from[current]
                    path.append(current)
                path.reverse()
                return SolveResult(path, nodes_expanded, elapsed_us, float(len(path) - 1), visited)

            if current in visited:
                continue
            visited.add(current)
            nodes_expanded += 1

            for neighbor in graph.neighbours(current):
                if neighbor not in visited:
                    came_from[neighbor] = current
                    heapq.heappush(open_set, (heuristic_fn(neighbor, goal), next(counter), neighbor))

        elapsed_us = (time.perf_counter_ns() - start_time) / 1000.0
        return SolveResult([], nodes_expanded, elapsed_us, float('inf'), visited)


# Registry of available solvers
SOLVER_REGISTRY: Dict[str, PathfindingSolver] = {
    "astar": AStarSolver(),
    "dijkstra": DijkstraSolver(),
    "bidirectional_astar": BidirectionalAStarSolver(),
    "bfs": BFSSolver(),
    "dfs": DFSSolver(),
    "gbfs": GreedyBestFirstSolver()
}

def solve_path(
    algorithm: str = "astar",
    start: Point = (0, 0),
    goal: Point = (0, 0),
    graph: Optional[Graph] = None,
    heuristic: str = "manhattan"
) -> SolveResult:
    """Convenience factory function to execute a pathfinding solve."""
    if graph is None:
        raise ValueError("Graph cannot be None")
    
    algo_key = algorithm.lower().strip()
    solver = SOLVER_REGISTRY.get(algo_key, SOLVER_REGISTRY["astar"])
    
    heur_map = {
        "manhattan": manhattan_distance,
        "euclidean": euclidean_distance,
        "chebyshev": chebyshev_distance
    }
    h_fn = heur_map.get(heuristic.lower().strip(), manhattan_distance)
    return solver.solve(start, goal, graph, h_fn)
