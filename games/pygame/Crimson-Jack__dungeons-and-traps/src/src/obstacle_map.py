from collections import deque


class ObstacleMap:
    """Merged 2D grid of all blocking layers used by enemy pathfinding."""

    BLOCKED_REGION_ID = -1

    def __init__(self, layers: list[list[list[int]] | None] | None = None) -> None:
        """
        Build the obstacle map by combining all provided layers into one.
        Layers may contain None values — these are silently skipped.

        :param layers: list of 2D tile grids to merge; each grid cell is 0 (free) or 1 (blocked)
        """
        self._items = list()
        self._region_ids = list()

        blocking_layers = list()
        if layers is not None:
            for layer in layers:
                if layer is not None:
                    blocking_layers.append(layer)

        if len(blocking_layers) > 0:
            # Get size: layers, rows and columns
            number_of_layers = len(blocking_layers)
            number_of_rows = 0
            number_of_columns = 0

            if number_of_layers > 0:
                number_of_rows = len(blocking_layers[0])
                if number_of_rows > 0:
                    number_of_columns = len(blocking_layers[0][0])

            # Combine layers into one layer
            for row in range(0, number_of_rows):
                self._items.append([])

                for column in range(0, number_of_columns):
                    new_value = False
                    for layer_index in range(0, number_of_layers):
                        new_value = new_value or bool(blocking_layers[layer_index][row][column])

                    self._items[row].append(int(new_value))

        self.calculate_regions()

    @property
    def items(self) -> list[list[int]]:
        """Merged grid of the map; each cell is 0 (free) or 1 (blocked)."""
        return self._items

    def calculate_regions(self) -> None:
        """
        Recompute connected-component region ids for every free tile in self._items.
        Always re-scans the current self._items, so it stays correct both on initial build
        and after in-place runtime mutations.
        """
        number_of_rows = len(self._items)
        number_of_columns = len(self._items[0]) if number_of_rows > 0 else 0

        self._region_ids = list()
        for row_index in range(number_of_rows):
            self._region_ids.append([])
            for column_index in range(number_of_columns):
                self._region_ids[row_index].append(ObstacleMap.BLOCKED_REGION_ID)

        if number_of_rows == 0 or number_of_columns == 0:
            return

        next_region_id = 0

        for row_index in range(number_of_rows):
            for column_index in range(number_of_columns):
                if self._items[row_index][column_index] != 0:
                    continue
                if self._region_ids[row_index][column_index] != ObstacleMap.BLOCKED_REGION_ID:
                    continue

                self._assign_region(row_index, column_index, next_region_id, number_of_rows, number_of_columns)
                next_region_id += 1

    def get_region_id(self, tile_position: tuple[int, int]) -> int:
        """
        Return the region id for a tile.

        :param tile_position: tile coordinates as (x, y), i.e. (column, row)
        :return: id of the free region the tile belongs to, or BLOCKED_REGION_ID for a blocked tile
        """
        column, row = tile_position
        return self._region_ids[row][column]

    def _assign_region(self, start_row: int, start_column: int, region_id: int,
                       number_of_rows: int, number_of_columns: int) -> None:
        # Flood-fill (BFS) from a free tile, assigning region_id to every reachable free tile
        neighbor_offsets = ((-1, 0), (1, 0), (0, -1), (0, 1))
        tiles_to_visit = deque()
        tiles_to_visit.append((start_row, start_column))
        self._region_ids[start_row][start_column] = region_id

        while tiles_to_visit:
            current_row, current_column = tiles_to_visit.popleft()

            for row_offset, column_offset in neighbor_offsets:
                neighbor_row = current_row + row_offset
                neighbor_column = current_column + column_offset

                if not (0 <= neighbor_row < number_of_rows and 0 <= neighbor_column < number_of_columns):
                    continue
                if self._items[neighbor_row][neighbor_column] != 0:
                    continue
                if self._region_ids[neighbor_row][neighbor_column] != ObstacleMap.BLOCKED_REGION_ID:
                    continue

                self._region_ids[neighbor_row][neighbor_column] = region_id
                tiles_to_visit.append((neighbor_row, neighbor_column))
