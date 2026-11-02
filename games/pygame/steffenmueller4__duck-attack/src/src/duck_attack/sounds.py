"""Sound effects: shots and background ambience."""

import random
from pathlib import Path

import pygame

from duck_attack import settings


class RandomSound:
    """A set of sounds; each ``play()`` picks one at random, never the same one twice in a row.

    Stays silent (instead of crashing) when no audio device is available.
    """

    def __init__(self, paths: list[Path], volume: float) -> None:
        self.sounds: list[pygame.mixer.Sound] = []
        if pygame.mixer.get_init():
            for path in paths:
                sound = pygame.mixer.Sound(path)
                sound.set_volume(volume)
                self.sounds.append(sound)
        self.last_played: int | None = None

    def play(self) -> None:
        if not self.sounds:
            return
        choices = [i for i in range(len(self.sounds)) if i != self.last_played] or [0]
        self.last_played = random.choice(choices)
        self.sounds[self.last_played].play()


class AmbientSounds:
    """Plays a random ambient duck sound every few seconds."""

    def __init__(self, paths: list[Path] = settings.AMBIENT_SOUNDS) -> None:
        self.random_sound = RandomSound(paths, settings.AMBIENT_VOLUME)
        self._schedule_next()

    def _schedule_next(self) -> None:
        self.next_in = random.uniform(settings.AMBIENT_MIN_DELAY, settings.AMBIENT_MAX_DELAY)

    def update(self, dt: float) -> None:
        self.next_in -= dt
        if self.next_in <= 0:
            self._schedule_next()
            self.random_sound.play()
