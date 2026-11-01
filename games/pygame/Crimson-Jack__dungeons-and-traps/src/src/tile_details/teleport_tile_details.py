from src.tile_details.tile_details import TileDetails
from src.tmx_helper import TmxHelper


class TeleportTileDetails(TileDetails):
    def __init__(self, tile, layer):
        super().__init__(tile, layer)

        self._destination = TmxHelper.get_tiled_object_value('destination', '', self.tile, self.layer)
        self._port_name = TmxHelper.get_tiled_object_value('port_name', '', self.tile, self.layer)

    @property
    def destination(self):
        return self._destination

    @property
    def port_name(self):
        return self._port_name
