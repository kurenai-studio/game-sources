"""Tiny sound effects generated with math, so the game needs no audio files."""
import array
import math
import random

import pygame

RATE = 44100


class Sounds:
    def __init__(self):
        self.enabled = False
        self.muted = False
        try:
            if not pygame.mixer.get_init():
                pygame.mixer.init(RATE, -16, 1, 512)
            _, _, self.channels = pygame.mixer.get_init()
            self.sounds = {
                "card": self._make(self._noise(0.06)),
                "chip": self._make(self._click(2600, 0.03) + [0.0] * 1500 + self._click(3100, 0.03)),
                "win": self._make(sum((self._tone(f, 0.13) for f in (660, 880, 1320)), [])),
            }
            self.enabled = True
        except pygame.error:
            pass    # no audio device: play silently

    def play(self, name):
        if self.enabled and not self.muted:
            self.sounds[name].play()

    def toggle_mute(self):
        self.muted = not self.muted

    # --- waveform builders: lists of floats in -1..1 ---
    def _noise(self, secs):
        n = int(RATE * secs)
        return [random.uniform(-1, 1) * 0.35 * (1 - i / n) ** 3 for i in range(n)]

    def _click(self, freq, secs):
        n = int(RATE * secs)
        return [math.sin(2 * math.pi * freq * i / RATE) * 0.4 * math.exp(-i / (n / 6)) for i in range(n)]

    def _tone(self, freq, secs):
        n = int(RATE * secs)
        return [math.sin(2 * math.pi * freq * i / RATE) * 0.3 * (1 - i / n) for i in range(n)]

    def _make(self, samples):
        data = array.array("h")
        for v in samples:
            data.extend([int(max(-1.0, min(1.0, v)) * 32767)] * self.channels)
        return pygame.mixer.Sound(buffer=data.tobytes())
