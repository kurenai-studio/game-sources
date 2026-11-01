from settings import Settings
from src.sprites.wall import Wall


class RemovableWall(Wall):
    def __init__(self, image, position, groups, obstacle_map):
        super().__init__(image, position, groups)
        self.obstacle_map = obstacle_map

    def kill(self):
        super().kill()

        # Reset obstacle map position
        x_tile_position, y_tile_position = self.rect[0] // Settings.TILE_SIZE, self.rect[1] // Settings.TILE_SIZE
        self.obstacle_map[y_tile_position][x_tile_position] = 0
