from src.game_helper import GameHelper
from src.tile_details.tile_details import TileDetails
from src.tmx_helper import TmxHelper


class FireFlameTileDetails(TileDetails):
    def __init__(self, tile, layer):
        super().__init__(tile, layer)

        self._direction = TmxHelper.get_tiled_object_value('direction', 'right', self.tile, self.layer)
        self._fire_length = int(TmxHelper.get_tiled_object_value('fire_length', 1, self.tile, self.layer))
        self._speed = GameHelper.multiply_by_tile_size_ratio(TmxHelper.get_tiled_object_value('speed', 1, self.tile, self.layer))
        self._motion_schedule = GameHelper.convert_string_to_tuple(TmxHelper.get_tiled_object_value('motion_schedule', '', self.tile, self.layer))
        self._damage_power = int(TmxHelper.get_tiled_object_value('damage_power', 1, self.tile, self.layer))

    @property
    def direction(self):
        return self._direction

    @property
    def fire_length(self):
        return self._fire_length

    @property
    def speed(self):
        return self._speed

    @property
    def motion_schedule(self):
        return self._motion_schedule

    @property
    def damage_power(self):
        return self._damage_power
