"""
Mathematical distance and heuristic metrics for grid graph search.
Admissible and consistent heuristics for 4-directional and 8-directional grids.
"""

import math
from typing import Tuple

Point = Tuple[int, int]

def manhattan_distance(p1: Point, p2: Point) -> float:
    """
    Computes Manhattan (L1 norm / taxicab) distance.
    Admissible and consistent for standard 4-connected grid graphs.
    h(p1, p2) = |x1 - x2| + |y1 - y2|
    """
    return float(abs(p1[0] - p2[0]) + abs(p1[1] - p2[1]))

def euclidean_distance(p1: Point, p2: Point) -> float:
    """
    Computes Euclidean (L2 norm) distance.
    Admissible and strictly monotonic for 4-connected and 8-connected grids.
    h(p1, p2) = sqrt((x1 - x2)^2 + (y1 - y2)^2)
    """
    return math.hypot(p1[0] - p2[0], p1[1] - p2[1])

def chebyshev_distance(p1: Point, p2: Point) -> float:
    """
    Computes Chebyshev (L_infinity norm) distance.
    Useful for diagonal movement cost analysis.
    h(p1, p2) = max(|x1 - x2|, |y1 - y2|)
    """
    return float(max(abs(p1[0] - p2[0]), abs(p1[1] - p2[1])))
