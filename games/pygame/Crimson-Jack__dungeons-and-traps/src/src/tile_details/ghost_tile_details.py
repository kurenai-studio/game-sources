from src.game_helper import GameHelper
from src.tile_details.tile_details import TileDetails
from src.tmx_helper import TmxHelper


class GhostTileDetails(TileDetails):
    def __init__(self, tile, layer):
        super().__init__(tile, layer)

        self._speed = GameHelper.multiply_by_tile_size_ratio(TmxHelper.get_tiled_object_value('speed', 1, self.tile, self.layer))
        self._damage_power = int(TmxHelper.get_tiled_object_value('damage_power', 1, self.tile, self.layer))

    @property
    def speed(self):
        return self._speed

    @property
    def damage_power(self):
        return self._damage_power
