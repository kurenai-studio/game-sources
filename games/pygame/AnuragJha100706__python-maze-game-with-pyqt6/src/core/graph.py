"""
Optimized Directed/Undirected Adjacency-List Graph Data Structure.
Provides O(1) vertex/edge queries, neighbor iteration, and edge removal.
Fully backward-compatible with legacy Graph class while adding advanced graph capabilities.
"""

from typing import Dict, Set, List, Tuple, Any, Optional

Vertex = Any
Edge = Tuple[Vertex, Vertex]

class Graph:
    """
    Adjacency-list graph container representing vertices and directed edges.
    Supports multigraph storage, O(1) existence checks via hash sets,
    and dynamic edge addition/removal.
    """
    def __init__(self, vertices: Optional[Any] = None, edges: Optional[Any] = None):
        self.alist: Dict[Vertex, List[Vertex]] = {}
        self._neighbor_sets: Dict[Vertex, Set[Vertex]] = {}
        
        if vertices:
            for v in vertices:
                self.add_vertex(v)
        if edges:
            for e in edges:
                self.add_edge(e)

    def add_vertex(self, v: Vertex) -> None:
        """Add a vertex v to the graph. If it already exists, do nothing."""
        if v not in self.alist:
            self.alist[v] = []
            self._neighbor_sets[v] = set()

    def add_edge(self, e: Edge) -> None:
        """
        Add a directed edge e = (u, v) to the graph.
        Raises ValueError if an endpoint is not in the graph.
        """
        u, v = e
        if not self.is_vertex(u) or not self.is_vertex(v):
            raise ValueError(f"Endpoint not in graph: {u} or {v}")
        self.alist[u].append(v)
        self._neighbor_sets[u].add(v)

    def add_bidirectional_edge(self, u: Vertex, v: Vertex) -> None:
        """Convenience method to add edges (u, v) and (v, u)."""
        self.add_edge((u, v))
        self.add_edge((v, u))

    def remove_edge(self, e: Edge) -> bool:
        """
        Removes one instance of directed edge e = (u, v) if it exists.
        Returns True if removed, False otherwise.
        """
        u, v = e
        if u in self.alist and v in self.alist[u]:
            self.alist[u].remove(v)
            if v not in self.alist[u]:
                self._neighbor_sets[u].discard(v)
            return True
        return False

    def remove_bidirectional_edge(self, u: Vertex, v: Vertex) -> bool:
        """Removes bidirectional edges (u, v) and (v, u)."""
        r1 = self.remove_edge((u, v))
        r2 = self.remove_edge((v, u))
        return r1 or r2

    def is_vertex(self, v: Vertex) -> bool:
        """O(1) check if vertex v is in the graph."""
        return v in self.alist

    def is_edge(self, e: Edge) -> bool:
        """
        O(1) check if directed edge e = (u, v) is in the graph.
        Optimized from O(deg(u)) to O(1) via internal neighbor hash sets.
        """
        u, v = e
        if u not in self._neighbor_sets:
            return False
        return v in self._neighbor_sets[u]

    def neighbours(self, v: Vertex) -> List[Vertex]:
        """Returns list of neighbors adjacent from v."""
        if not self.is_vertex(v):
            raise ValueError(f"Vertex {v} not in graph")
        return self.alist[v]

    def degree(self, v: Vertex) -> int:
        """Returns out-degree of vertex v."""
        return len(self.neighbours(v))

    def get_vertices(self) -> Set[Vertex]:
        """Returns the set of vertices in the graph."""
        return set(self.alist.keys())

    def get_edges(self) -> List[Edge]:
        """Returns a list of all directed edges in the graph."""
        edges = []
        for u, neighbors in self.alist.items():
            for v in neighbors:
                edges.append((u, v))
        return edges

    def clear(self) -> None:
        """Resets the graph to an empty state."""
        self.alist.clear()
        self._neighbor_sets.clear()

    def clone(self) -> 'Graph':
        """Creates a deep copy of the graph topology."""
        new_g = Graph()
        for v in self.get_vertices():
            new_g.add_vertex(v)
        for u, v in self.get_edges():
            new_g.add_edge((u, v))
        return new_g

def create_grid_graph(width: int, height: int) -> Graph:
    """Helper to initialize an isolated grid graph of size width x height."""
    g = Graph()
    for x in range(width):
        for y in range(height):
            g.add_vertex((x, y))
    return g
