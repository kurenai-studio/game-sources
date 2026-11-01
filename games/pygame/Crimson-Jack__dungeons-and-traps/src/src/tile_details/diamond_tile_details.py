from src.tile_details.tile_details import TileDetails
from src.tmx_helper import TmxHelper


class DiamondTileDetails(TileDetails):
    def __init__(self, tile, layer):
        super().__init__(tile, layer)

        self._score = int(TmxHelper.get_tiled_object_value('score', 0, self.tile, self.layer))

    @property
    def score(self):
        return self._score

    @classmethod
    def from_properties(cls, score):
        instance = cls(None, None)
        instance._score = score
        return instance
