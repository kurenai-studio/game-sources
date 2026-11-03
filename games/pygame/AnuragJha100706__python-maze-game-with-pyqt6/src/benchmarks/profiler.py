"""
Scientific Algorithm Profiler.
Measures execution time in microseconds (time.perf_counter_ns)
and peak heap memory in kilobytes (tracemalloc).
"""

import time
import tracemalloc
from typing import Dict, Any, Callable, Tuple
from core.graph import Graph
from core.solvers import solve_path, SolveResult
from core.maze_generators import generate_maze

Point = Tuple[int, int]

def profile_solver(
    algorithm: str,
    start: Point,
    goal: Point,
    maze: Graph,
    heuristic: str = "manhattan"
) -> Dict[str, Any]:
    """
    Profiles a pathfinding solver, recording high-resolution runtime,
    peak memory allocation, nodes expanded, and path length.
    """
    tracemalloc.start()
    t_start = time.perf_counter_ns()

    res: SolveResult = solve_path(algorithm, start, goal, maze, heuristic)

    t_end = time.perf_counter_ns()
    _, peak_bytes = tracemalloc.get_traced_memory()
    tracemalloc.stop()

    duration_us = (t_end - t_start) / 1000.0
    peak_kb = peak_bytes / 1024.0

    return {
        "algorithm": algorithm,
        "heuristic": heuristic,
        "runtime_us": duration_us,
        "peak_memory_kb": peak_kb,
        "nodes_expanded": res.nodes_expanded,
        "path_length": res.path_length,
        "found": res.found
    }

def profile_generator(algorithm: str, width: int, height: int) -> Dict[str, Any]:
    """Profiles a maze generation algorithm."""
    tracemalloc.start()
    t_start = time.perf_counter_ns()

    maze: Graph = generate_maze(algorithm, width, height)

    t_end = time.perf_counter_ns()
    _, peak_bytes = tracemalloc.get_traced_memory()
    tracemalloc.stop()

    duration_us = (t_end - t_start) / 1000.0
    peak_kb = peak_bytes / 1024.0

    return {
        "algorithm": algorithm,
        "grid_size": width,
        "runtime_us": duration_us,
        "peak_memory_kb": peak_kb,
        "total_vertices": len(maze.get_vertices()),
        "total_edges": len(maze.get_edges())
    }
