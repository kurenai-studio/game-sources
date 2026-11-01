"""Audio playback wrapper around ``pygame.mixer.music``.

``position_ms()`` is the single clock used by rendering and hit
detection. It is based on ``pygame.mixer.music.get_pos()`` (milliseconds
since playback started) with a monotonic fallback while pygame still
reports "-2" (before the stream actually begins). Once the stream ends
the position freezes at the end-of-song timestamp so late notes keep a
stable reference.
"""

from __future__ import annotations

import time

import pygame


class AudioEngine:
    def __init__(self):
        self._start_perf: float | None = None
        self._ever_busy = False
        self._ended = False
        self._frozen = 0.0
        self.path: str | None = None
        self.volume: float = 1.0

    def set_volume(self, volume: float) -> None:
        """Master music volume, 0.0 - 1.0."""
        self.volume = max(0.0, min(1.0, float(volume)))
        try:
            pygame.mixer.music.set_volume(self.volume)
        except pygame.error:
            pass

    def play(self, path: str) -> None:
        pygame.mixer.music.load(path)
        pygame.mixer.music.set_volume(self.volume)
        pygame.mixer.music.play()
        self.path = path
        self._start_perf = time.perf_counter()
        self._ever_busy = False
        self._ended = False
        self._frozen = 0.0

    def stop(self) -> None:
        try:
            pygame.mixer.music.stop()
        except pygame.error:
            pass
        try:
            # release the file handle: Windows keeps the music file locked
            # while SDL_mixer holds it, which makes delete/move fail
            pygame.mixer.music.unload()
        except pygame.error:
            pass
        self._start_perf = None
        self._ended = False

    def position_ms(self) -> float:
        if self._start_perf is None:
            return 0.0
        if self._ended:
            return self._frozen

        pos = pygame.mixer.music.get_pos()
        if pos is not None and pos >= 0:
            value = float(pos)
        else:
            value = (time.perf_counter() - self._start_perf) * 1000.0

        busy = pygame.mixer.music.get_busy()
        if busy:
            self._ever_busy = True
        elif self._ever_busy or value > 750.0:
            self._ended = True
            self._frozen = value
            return value
        return value

    @property
    def finished(self) -> bool:
        return self._ended

    @property
    def playing(self) -> bool:
        return self._start_perf is not None and not self._ended
