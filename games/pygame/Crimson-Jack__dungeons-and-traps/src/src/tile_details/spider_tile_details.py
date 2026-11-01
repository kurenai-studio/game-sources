from src.game_helper import GameHelper
from src.tile_details.tile_details import TileDetails
from src.tmx_helper import TmxHelper


class SpiderTileDetails(TileDetails):
    def __init__(self, tile, layer):
        super().__init__(tile, layer)

        self._speed = GameHelper.multiply_by_tile_size_ratio(TmxHelper.get_tiled_object_value('speed', 1, self.tile, self.layer))
        self._net_length = int(TmxHelper.get_tiled_object_value('net_length', 1, self.tile, self.layer))
        self._motion_schedule = GameHelper.convert_string_to_tuple(TmxHelper.get_tiled_object_value('motion_schedule', '', self.tile, self.layer))
        self._energy = int(TmxHelper.get_tiled_object_value('energy', 100, self.tile, self.layer))
        self._damage_power = int(TmxHelper.get_tiled_object_value('damage_power', 1, self.tile, self.layer))
        self._score = int(TmxHelper.get_tiled_object_value('score', 0, self.tile, self.layer))

    @property
    def speed(self):
        return self._speed

    @property
    def net_length(self):
        return self._net_length

    @property
    def motion_schedule(self):
        return self._motion_schedule

    @property
    def energy(self):
        return self._energy

    @property
    def damage_power(self):
        return self._damage_power

    @property
    def score(self):
        return self._score
