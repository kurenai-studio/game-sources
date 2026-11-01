from src.enums.sound_effect import SoundEffect
from src.sound_manager import SoundManager
from src.sprites.powerup import Powerup


class LifePowerup(Powerup):
    def __init__(self, image, position, groups, game_manager):
        super().__init__(image, position, groups, game_manager)

        # Sound
        self.sound_manager = SoundManager()

    def collect(self):
        self.sound_manager.play_sfx(SoundEffect.COLLECT_LIFE)
        self.game_manager.collect_life_powerup()
        super().kill()
