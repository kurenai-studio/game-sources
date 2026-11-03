"""
Core Algorithmic and Mathematical Package
Provides Graph representations, Spanning Tree Maze Generators,
Heuristic metrics, and Pathfinding Solvers.
"""

from .graph import Graph
from .heuristics import manhattan_distance, euclidean_distance, chebyshev_distance
from .maze_generators import (
    DisjointSet,
    MazeGenerator,
    KruskalGenerator,
    PrimGenerator,
    WilsonGenerator,
    DFSBacktrackerGenerator,
    generate_maze
)
from .solvers import (
    SolveResult,
    PathfindingSolver,
    AStarSolver,
    DijkstraSolver,
    BidirectionalAStarSolver,
    BFSSolver,
    DFSSolver,
    GreedyBestFirstSolver,
    solve_path
)

__all__ = [
    'Graph',
    'manhattan_distance',
    'euclidean_distance',
    'chebyshev_distance',
    'DisjointSet',
    'MazeGenerator',
    'KruskalGenerator',
    'PrimGenerator',
    'WilsonGenerator',
    'DFSBacktrackerGenerator',
    'generate_maze',
    'SolveResult',
    'PathfindingSolver',
    'AStarSolver',
    'DijkstraSolver',
    'BidirectionalAStarSolver',
    'BFSSolver',
    'DFSSolver',
    'GreedyBestFirstSolver',
    'solve_path'
]
