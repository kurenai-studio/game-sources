"""Small synthesized sound palette with no external audio assets."""

from __future__ import annotations

from array import array
import math

import pygame


class ProceduralAudio:
    """Generate arcade tones at runtime and fail gracefully without audio."""

    SAMPLE_RATE = 22_050

    def __init__(self, enabled: bool = True):
        self.enabled = False
        self.music_channel: pygame.mixer.Channel | None = None
        self.sounds: dict[str, pygame.mixer.Sound] = {}
        if not enabled:
            return

        try:
            if pygame.mixer.get_init() is None:
                pygame.mixer.init(
                    frequency=self.SAMPLE_RATE,
                    size=-16,
                    channels=1,
                    buffer=512,
                )
            self.sounds = {
                "shoot": self._tone(720, 70, 0.16, sweep=-180),
                "hit": self._tone(150, 100, 0.22, sweep=-70),
                "powerup": self._tone(520, 190, 0.2, sweep=420),
                "boss": self._tone(86, 480, 0.2, sweep=-18),
                "ambient": self._chord((110, 165, 220), 1_800, 0.07),
                "danger": self._chord((82, 123, 164), 1_200, 0.09),
            }
            self.music_channel = pygame.mixer.Channel(0)
            self.enabled = True
        except pygame.error:
            self.sounds = {}
            self.music_channel = None

    def play(self, name: str) -> None:
        if self.enabled and name in self.sounds:
            self.sounds[name].play()

    def switch_music(self, boss_active: bool) -> None:
        if not self.enabled or self.music_channel is None:
            return
        selected = self.sounds["danger" if boss_active else "ambient"]
        self.music_channel.stop()
        self.music_channel.play(selected, loops=-1, fade_ms=250)

    def stop(self) -> None:
        if self.music_channel is not None:
            self.music_channel.fadeout(200)

    def _tone(
        self,
        frequency: float,
        duration_ms: int,
        volume: float,
        sweep: float = 0.0,
    ) -> pygame.mixer.Sound:
        sample_count = int(self.SAMPLE_RATE * duration_ms / 1_000)
        values = array("h")
        for index in range(sample_count):
            progress = index / max(1, sample_count - 1)
            current_frequency = frequency + sweep * progress
            envelope = min(1.0, progress * 12) * (1.0 - progress) ** 1.5
            phase = 2 * math.pi * current_frequency * index / self.SAMPLE_RATE
            values.append(int(32_767 * volume * envelope * math.sin(phase)))
        return pygame.mixer.Sound(buffer=values.tobytes())

    def _chord(
        self,
        frequencies: tuple[float, ...],
        duration_ms: int,
        volume: float,
    ) -> pygame.mixer.Sound:
        sample_count = int(self.SAMPLE_RATE * duration_ms / 1_000)
        values = array("h")
        divisor = max(1, len(frequencies))
        for index in range(sample_count):
            progress = index / max(1, sample_count - 1)
            envelope = math.sin(math.pi * progress) ** 0.65
            wave = sum(
                math.sin(2 * math.pi * frequency * index / self.SAMPLE_RATE)
                for frequency in frequencies
            ) / divisor
            values.append(int(32_767 * volume * envelope * wave))
        return pygame.mixer.Sound(buffer=values.tobytes())
