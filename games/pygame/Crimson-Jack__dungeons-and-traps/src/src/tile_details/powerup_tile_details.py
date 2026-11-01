from src.tile_details.tile_details import TileDetails
from src.tmx_helper import TmxHelper


class PowerupTileDetails(TileDetails):
    def __init__(self, tile, layer):
        super().__init__(tile, layer)

        self._powerup_name = TmxHelper.get_tiled_object_value('powerup_name', '', self.tile, self.layer)
        self._powerup_volume = int(TmxHelper.get_tiled_object_value('powerup_volume', 0, self.tile, self.layer))

    @property
    def powerup_name(self):
        return self._powerup_name

    @property
    def powerup_volume(self):
        return self._powerup_volume

