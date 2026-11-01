import pygame

from src.events import Events
from src.enums.sound_effect import SoundEffect
from src.sound_manager import SoundManager
from src.sprites.removable_wall import RemovableWall
from src.tile_details.key_and_door_tile_details import KeyAndDoorTileDetails


class Door(RemovableWall):
    def __init__(self, image, position, groups, details: KeyAndDoorTileDetails, obstacle_map):
        super().__init__(image, position, groups, obstacle_map)

        # Sound
        self.sound_manager = SoundManager()

        self.key_name = details.key_name

    def kill(self):
        self.sound_manager.play_sfx(SoundEffect.OPEN_DOOR)
        super().kill()
        # Raise event to refresh obstacle map
        pygame.event.post(pygame.event.Event(Events.REFRESH_OBSTACLE_MAP_EVENT))
