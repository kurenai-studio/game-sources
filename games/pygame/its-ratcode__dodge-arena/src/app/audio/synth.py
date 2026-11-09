"""A tiny software synthesizer.

Everything works on plain lists of float samples between -1 and 1:
oscillators (sine, triangle, square, saw), filtered noise, envelopes, pitch
sweeps, vibrato and mixing. ``to_sound`` turns a list into a pygame Sound.
"""

import math
import random
from array import array

import pygame

Samples = list[float]
CLICK_GUARD = 0.006         # s of fade at the end of every sound, so it never ends with a click


class Synth:
    def __init__(self, rate: int) -> None:
        self.rate = rate

    def _envelope(self, i: int, n: int, attack_n: int, decay: float, tail_n: int) -> float:
        """Rise over ``attack_n`` samples, then fall away exponentially, with a short fade at the very end."""
        env = min(1.0, i / attack_n) * math.exp(-decay * i / self.rate)
        if n - i < tail_n:
            env *= (n - i) / tail_n
        return env

    def tone(self, freq: float, duration: float, *, freq_end: float | None = None, wave: str = "sine",
             attack: float = 0.004, decay: float = 8.0, volume: float = 0.5,
             vibrato_rate: float = 0.0, vibrato_depth: float = 0.0) -> Samples:
        """One note. The pitch slides smoothly (exponentially) from ``freq`` to ``freq_end``."""
        n = max(1, int(duration * self.rate))
        ratio = freq_end / freq if freq_end else 1.0
        attack_n = max(1, int(attack * self.rate))
        tail_n = min(n, max(1, int(CLICK_GUARD * self.rate)))
        out = [0.0] * n
        phase = 0.0
        for i in range(n):
            f = freq * ratio ** (i / n) if ratio != 1.0 else freq
            if vibrato_depth:
                f *= 1 + vibrato_depth * math.sin(math.tau * vibrato_rate * i / self.rate)
            phase = (phase + f / self.rate) % 1.0          # advance by the *current* pitch: no jumps
            if wave == "sine":
                s = math.sin(math.tau * phase)
            elif wave == "triangle":
                s = 4 * abs(phase - 0.5) - 1
            elif wave == "square":
                s = 0.8 if phase < 0.5 else -0.8           # a bit quieter: squares sound loud
            else:                                          # "saw"
                s = 2 * phase - 1
            out[i] = s * self._envelope(i, n, attack_n, decay, tail_n) * volume
        return out

    def noise(self, duration: float, *, decay: float = 8.0, volume: float = 0.5, smooth: float = 1.0,
              attack: float = 0.002) -> Samples:
        """White noise through a simple low-pass filter: ``smooth`` below 1 makes it darker and softer."""
        n = max(1, int(duration * self.rate))
        attack_n = max(1, int(attack * self.rate))
        tail_n = min(n, max(1, int(CLICK_GUARD * self.rate)))
        boost = min(3.0, 1.0 / max(0.1, smooth) ** 0.5)   # filtering loses loudness; give some back
        out = [0.0] * n
        y = 0.0
        for i in range(n):
            y += smooth * (random.uniform(-1, 1) - y)
            out[i] = y * self._envelope(i, n, attack_n, decay, tail_n) * volume * boost
        return out

    def mix(self, *parts: tuple[Samples, float]) -> Samples:
        """Add ``(samples, start time in s)`` pairs together into one buffer."""
        length = max(int(start * self.rate) + len(samples) for samples, start in parts)
        out = [0.0] * length
        for samples, start in parts:
            offset = int(start * self.rate)
            for i, v in enumerate(samples):
                out[offset + i] += v
        return out

    def arpeggio(self, freqs: list[float], step: float, note_len: float, *, wave: str = "triangle",
                 volume: float = 0.3, decay: float = 14.0) -> Samples:
        """Notes played one after another, ``step`` seconds apart."""
        return self.mix(*((self.tone(f, note_len, wave=wave, volume=volume, decay=decay), i * step)
                          for i, f in enumerate(freqs)))

    def bell(self, freqs: list[float], duration: float, *, decay: float = 3.0, volume: float = 0.3,
             stagger: float = 0.0) -> Samples:
        """A chime: several sine partials, the higher ones quieter and dying faster."""
        return self.mix(*((self.tone(f, duration, decay=decay * (1 + i * 0.6), volume=volume / (1 + i * 0.5)),
                           i * stagger) for i, f in enumerate(freqs)))

    @staticmethod
    def to_pcm(samples: Samples, channels: int = 1) -> bytes:
        """Float samples -> raw 16-bit audio bytes (copied to both sides for stereo)."""
        pcm = array("h", (int(max(-1.0, min(1.0, v)) * 32767) for v in samples))
        if channels == 2:
            stereo = array("h", bytes(len(pcm) * 4))
            stereo[0::2] = pcm
            stereo[1::2] = pcm
            pcm = stereo
        return pcm.tobytes()

    @staticmethod
    def to_sound(samples: Samples, channels: int = 1) -> pygame.mixer.Sound:
        """Float samples -> a pygame Sound."""
        return pygame.mixer.Sound(buffer=Synth.to_pcm(samples, channels))
