from src.enums.lighting_status import LightingStatus
from src.enums.sound_effect import SoundEffect
from src.sound_manager import SoundManager
from src.sprites.spell import Spell
from src.tile_details.spell_tile_details import SpellTileDetails


class LightingSpell(Spell):
    def __init__(self, image, position, groups, game_manager, spell_tile_details: SpellTileDetails):
        super().__init__(image, position, groups, game_manager)

        # Sound
        self.sound_manager = SoundManager()

        # Name
        self.spell_name = spell_tile_details.spell_name

    def collect(self):
        if self.spell_name == LightingStatus.TWILIGHT:
            self.sound_manager.play_sfx(SoundEffect.COLLECT_LIGHTNING_SPELL_TWILIGHT)
        else:
            self.sound_manager.play_sfx(SoundEffect.COLLECT_LIGHTNING_SPELL)
        self.game_manager.set_lighting_spell(self.spell_name)
        super().kill()
