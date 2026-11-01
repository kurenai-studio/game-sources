from src.sprites.bow_powerup import BowPowerup
from src.sprites.energy_powerup import EnergyPowerup
from src.sprites.explosion_powerup import ExplosionPowerup
from src.sprites.life_powerup import LifePowerup
from src.sprites.sword_powerup import SwordPowerup
from src.tile_details.powerup_tile_details import PowerupTileDetails


class PowerupFactory:
    @staticmethod
    def create(tile_details: PowerupTileDetails, **kwargs):
        image = kwargs["image"]
        position = kwargs["position"]
        groups = kwargs["groups"]
        game_manager = kwargs["game_manager"]

        if tile_details.powerup_name == 'sword':
            return SwordPowerup(image, position, groups, game_manager)
        elif tile_details.powerup_name == 'bow':
            return BowPowerup(image, position, groups, game_manager, tile_details.powerup_volume)
        elif tile_details.powerup_name == 'explosion':
            return ExplosionPowerup(image, position, groups, game_manager, tile_details.powerup_volume)
        elif tile_details.powerup_name == 'energy':
            return EnergyPowerup(image, position, groups, game_manager, tile_details.powerup_volume)
        elif tile_details.powerup_name == 'life':
            return LifePowerup(image, position, groups, game_manager)
        else:
            raise ValueError(f'Unknown powerup name: {tile_details}')
