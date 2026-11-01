from src.enums.sound_effect import SoundEffect
from src.sound_manager import SoundManager
from src.sprites.powerup import Powerup


class EnergyPowerup(Powerup):
    def __init__(self, image, position, groups, game_manager, powerup_volume):
        super().__init__(image, position, groups, game_manager)

        # Sound
        self.sound_manager = SoundManager()

        # Volume
        self.volume = powerup_volume

    def activate(self):
        self.sound_manager.play_sfx(SoundEffect.COLLECT_ENERGY)
        self.game_manager.increase_player_energy(self.volume)
        super().kill()
