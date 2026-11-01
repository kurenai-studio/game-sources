from src.tile_details.tile_details import TileDetails
from src.tmx_helper import TmxHelper


class SpellTileDetails(TileDetails):
    def __init__(self, tile, layer):
        super().__init__(tile, layer)

        self._spell_name = TmxHelper.get_tiled_object_value('spell_name', '', self.tile, self.layer)

    @property
    def spell_name(self):
        return self._spell_name
