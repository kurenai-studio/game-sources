import pygame

from src.events import Events
from src.enums.sound_effect import SoundEffect
from src.sound_manager import SoundManager
from src.sprites.removable_wall import RemovableWall


class DemolishedWall(RemovableWall):
    def __init__(self, image, position, groups, obstacle_map):
        super().__init__(image, position, groups, obstacle_map)

        # Sound
        self.sound_manager = SoundManager()

    def kill(self):
        self.sound_manager.play_sfx(SoundEffect.DEMOLISH_WALL)
        super().kill()

        # Raise event to show vanishing point
        pygame.event.post(pygame.event.Event(Events.ADD_VANISHING_POINT_EVENT, {"position": self.rect.topleft}))
