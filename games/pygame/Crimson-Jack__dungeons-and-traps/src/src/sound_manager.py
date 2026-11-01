import time

import pygame

from src.enums.sound_effect import SoundEffect
from src.metaclasses.singleton_meta import SingletonMeta


class SoundManager(metaclass=SingletonMeta):
    def __init__(self):
        self.music_set = 'set_01'
        self.sfx_collection = dict()
        self._load_sfx_collection()

    def _load_sfx_collection(self):
        for item in SoundEffect:
            self.sfx_collection[item] = pygame.mixer.Sound(f'sound/sfx/{self.music_set}/{item}.ogg')

    def play_sfx(self, sound_effect: SoundEffect):
        # NOTE: If there are no inactive channels and the force argument is True,
        # this will find the Channel with the longest running Sound and return it.
        empty_channel = pygame.mixer.find_channel(True)
        empty_channel.play(self.sfx_collection[sound_effect])
