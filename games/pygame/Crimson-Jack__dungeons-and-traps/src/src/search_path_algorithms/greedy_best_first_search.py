import math

from src.obstacle_map import ObstacleMap
from src.search_path_algorithms.unique_priority_queue import UniquePriorityQueue


class GreedyBestFirstSearch:
    """Pathfinding algorithm that always expands the tile closest to the goal by Euclidean distance."""

    def __init__(self) -> None:
        self._neighbors_tile_order = [(1, 0), (0, 1), (-1, 0), (0, -1)]
        self._is_end_reached = False
        self._path = list()

    def _get_neighbors(self, tiles: set[tuple[int, int]], tile: tuple[int, int]) -> list[tuple[int, int]]:
        result = []
        for direction in self._neighbors_tile_order:
            neighbor = (tile[0] + direction[0], tile[1] + direction[1])
            if neighbor in tiles:
                result.append(neighbor)
        return result

    @staticmethod
    def heuristic(a: tuple[int, int], b: tuple[int, int]) -> float:
        """
        Calculate the Euclidean distance between two tiles.

        :param a: first tile coordinates
        :param b: second tile coordinates
        :return: Euclidean distance
        """
        return math.sqrt((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2)

    def _generate_path(self, current_item: tuple[int, int],
                       items: dict[tuple[int, int], tuple[int, int] | None]) -> None:
        while items[current_item] is not None:
            self._path.append(items[current_item])
            current_item = items[current_item]

    def search(self, all_tiles: set[tuple[int, int]], start_tile: tuple[int, int], end_tile: tuple[int, int],
               obstacle_map: ObstacleMap | None = None, max_distance: int | None = None) -> list[tuple[int, int]]:
        """
        Find a path from start_tile to end_tile within the given tile set.
        The result is stored in the path property and returned.
        The path is in reverse order (from the tile before end_tile back to start_tile).

        :param all_tiles: set of all walkable tile coordinates
        :param start_tile: starting tile coordinates
        :param end_tile: target tile coordinates
        :param obstacle_map: optional obstacle map used to skip the search entirely when
            start_tile and end_tile are in different, definitely disconnected regions
        :param max_distance: maximum allowed distance (in tiles) from start in each axis, None means no
            distance limit is applied
        :return: path as a list of tile coordinates, empty if end_tile is unreachable
        """
        self._is_end_reached = False
        self._path.clear()

        if obstacle_map is not None:
            start_region_id = obstacle_map.get_region_id(start_tile)
            end_region_id = obstacle_map.get_region_id(end_tile)
            if start_region_id != ObstacleMap.BLOCKED_REGION_ID and start_region_id != end_region_id:
                return self._path

        frontier = UniquePriorityQueue()
        frontier.add(start_tile, 0)
        came_from = dict()
        came_from[start_tile] = None

        while not self._is_end_reached and not frontier.is_empty():
            current_tile, current_tile_priority = frontier.pop()
            if current_tile == end_tile:
                self._is_end_reached = True
                self._generate_path(current_tile, came_from)
            else:
                for next_neighbor in self._get_neighbors(all_tiles, current_tile):
                    if next_neighbor not in came_from:
                        # square shape max distance
                        distance = abs(start_tile[0] - next_neighbor[0]), abs(start_tile[1] - next_neighbor[1])
                        if max_distance is None or (distance[0] <= max_distance and distance[1] <= max_distance):
                            came_from[next_neighbor] = current_tile
                            priority = self.heuristic(end_tile, next_neighbor)
                            frontier.add(next_neighbor, priority)

        return self._path

    @property
    def path(self) -> list[tuple[int, int]]:
        """
        Return the path found by the last search call.

        :return: list of tile coordinates in reverse order, empty if end_tile was unreachable
        """
        return self._path

    @property
    def is_end_reached(self) -> bool:
        """
        Return True if the last search call reached the end_tile.

        :return: True if end_tile was reached, False otherwise
        """
        return self._is_end_reached
