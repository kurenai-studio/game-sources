from src.enums.search_path_algorithm import SearchPathAlgorithm
from src.game_helper import GameHelper
from src.tile_details.monster_tile_details import MonsterTileDetails


class MonsterTileDetailsFactory:
    @staticmethod
    def create(monster_name: str):
        if monster_name == 'monster-enemy-blue-deaf':
            tile_details = MonsterTileDetails(None, None)
            tile_details.set_all_properties(
                GameHelper.multiply_by_tile_size_ratio(3.2),
                20,
                100,
                2,
                50,
                SearchPathAlgorithm.GREEDY_BEST_FIRST_SEARCH,
                True
            )
            return tile_details
        elif monster_name == 'monster-enemy-green-deaf':
            tile_details = MonsterTileDetails(None, None)
            tile_details.set_all_properties(
                GameHelper.multiply_by_tile_size_ratio(5.0),
                10,
                200,
                4,
                170,
                SearchPathAlgorithm.GREEDY_BEST_FIRST_SEARCH,
                True
            )
            return tile_details
        elif monster_name == 'monster-enemy-red-deaf':
            tile_details = MonsterTileDetails(None, None)
            tile_details.set_all_properties(
                GameHelper.multiply_by_tile_size_ratio(6.5),
                5,
                500,
                1,
                300,
                SearchPathAlgorithm.GREEDY_BEST_FIRST_SEARCH,
                True
            )
            return tile_details
        else:
            raise ValueError(f'Unknown name: {monster_name}')
