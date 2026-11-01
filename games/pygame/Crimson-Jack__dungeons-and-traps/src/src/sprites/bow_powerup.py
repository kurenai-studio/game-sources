from src.enums.sound_effect import SoundEffect
from src.sound_manager import SoundManager
from src.sprites.powerup import Powerup


class BowPowerup(Powerup):
    def __init__(self, image, position, groups, game_manager, powerup_volume):
        super().__init__(image, position, groups, game_manager)

        # Sound
        self.sound_manager = SoundManager()

        # Volume
        self.number_of_arrows = powerup_volume

    def collect(self):
        self.sound_manager.play_sfx(SoundEffect.COLLECT_BOW)
        self.game_manager.collect_bow_powerup(self.number_of_arrows)
        super().kill()
