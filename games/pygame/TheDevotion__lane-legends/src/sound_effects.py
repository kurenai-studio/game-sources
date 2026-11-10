"""
Lane Legends: Human vs AI
sound_effects.py - Procedural 8-bit/Arcade Sound Synthesizer and Audio Manager.

Generates retro arcade WAV audio waveforms dynamically in-memory using Python's standard
library (math, struct, io, wave). Zero external sound file downloads required.
Fails gracefully if the host system lacks an audio device.
"""

import io
import math
import struct
import wave
from typing import Optional, Dict

import pygame
from settings import SOUNDS_DIR


class SoundManager:
    """
    Synthesizes and plays arcade sound effects using pygame.mixer.
    """

    def __init__(self, sample_rate: int = 22050):
        self.sample_rate = sample_rate
        self.enabled = True
        self.sounds: Dict[str, pygame.mixer.Sound] = {}
        self.initialized = False

        self._init_mixer()
        if self.initialized:
            self._generate_all_sounds()

    def _init_mixer(self) -> None:
        """Initialize Pygame mixer safely."""
        try:
            if not pygame.mixer.get_init():
                pygame.mixer.pre_init(self.sample_rate, -16, 1, 512)
                pygame.mixer.init()
            self.initialized = True
        except Exception as e:
            print(f"[SoundManager] Audio device unavailable ({e}). Running in silent mode.")
            self.initialized = False

    def _create_wav_sound(self, duration: float, sample_func) -> Optional[pygame.mixer.Sound]:
        """Synthesize a mono 16-bit PCM WAV sound in memory and return a pygame Sound."""
        if not self.initialized:
            return None

        total_samples = int(self.sample_rate * duration)
        raw_samples = bytearray()

        for i in range(total_samples):
            t = i / self.sample_rate
            val = sample_func(t, duration)
            # Clamp to 16-bit signed int range [-32767, 32767]
            clamped = max(-32767, min(32767, int(val * 32767.0)))
            raw_samples.extend(struct.pack("<h", clamped))

        bio = io.BytesIO()
        with wave.open(bio, "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(self.sample_rate)
            wf.writeframes(raw_samples)

        bio.seek(0)
        try:
            return pygame.mixer.Sound(bio)
        except Exception:
            return None

    def _generate_all_sounds(self) -> None:
        """Synthesize standard arcade audio palette."""
        # 1. Menu Beep
        def menu_beep(t, d):
            freq = 600.0
            envelope = math.exp(-15.0 * t)
            return 0.3 * math.sin(2 * math.pi * freq * t) * envelope

        # 2. Countdown Low Beep (for 3, 2, 1)
        def cd_low(t, d):
            freq = 440.0
            envelope = math.exp(-8.0 * t)
            return 0.45 * (math.sin(2 * math.pi * freq * t) + 0.2 * math.sin(4 * math.pi * freq * t)) * envelope

        # 3. Countdown High Beep (for GO!)
        def cd_high(t, d):
            freq = 880.0
            envelope = math.exp(-6.0 * t)
            return 0.5 * (math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(4 * math.pi * freq * t)) * envelope

        # 4. Nitro Surge (whoosh with frequency rise)
        def nitro_surge(t, d):
            progress = t / d
            freq = 200.0 + progress * 500.0
            # Mix sine with white noise modulation
            noise = (math.sin(12345.67 * t) % 1.0) * 2.0 - 1.0
            envelope = math.sin(math.pi * progress)
            return 0.35 * (math.sin(2 * math.pi * freq * t) * 0.7 + noise * 0.3) * envelope

        # 5. Crash Impact (crunchy low-frequency shock)
        def crash_impact(t, d):
            progress = t / d
            noise = (math.sin(98765.43 * t) % 1.0) * 2.0 - 1.0
            rumble = math.sin(2 * math.pi * 75.0 * t)
            envelope = math.exp(-10.0 * t)
            return 0.65 * (noise * 0.6 + rumble * 0.4) * envelope

        # 6. Pass Obstacle / Chime
        def pass_chime(t, d):
            freq = 987.77  # B5
            envelope = math.exp(-12.0 * t)
            return 0.25 * math.sin(2 * math.pi * freq * t) * envelope

        # 7. Victory Fanfare (triad arpeggio)
        def victory_fanfare(t, d):
            notes = [523.25, 659.25, 783.99, 1046.50]  # C5, E5, G5, C6
            segment = int(t * 4 / d)
            freq = notes[min(segment, 3)]
            seg_t = (t * 4 / d) - segment
            envelope = math.exp(-4.0 * seg_t)
            return 0.4 * (math.sin(2 * math.pi * freq * t) + 0.2 * math.sin(4 * math.pi * freq * t)) * envelope

        # 8. Oil Skid (wobbly pitch slide)
        def oil_skid(t, d):
            freq = 300.0 - 150.0 * (t / d) + 40.0 * math.sin(2 * math.pi * 25.0 * t)
            envelope = math.sin(math.pi * (t / d))
            return 0.3 * math.sin(2 * math.pi * freq * t) * envelope

        # Register synthesized sounds
        sound_defs = {
            "menu_beep": (0.08, menu_beep),
            "countdown_low": (0.22, cd_low),
            "countdown_high": (0.45, cd_high),
            "nitro": (0.60, nitro_surge),
            "crash": (0.40, crash_impact),
            "pass": (0.12, pass_chime),
            "victory": (1.10, victory_fanfare),
            "skid": (0.35, oil_skid),
        }

        for name, (dur, func) in sound_defs.items():
            snd = self._create_wav_sound(dur, func)
            if snd:
                self.sounds[name] = snd

    def play(self, name: str) -> None:
        """Play a sound effect if audio is enabled."""
        if not self.enabled or not self.initialized:
            return
        snd = self.sounds.get(name)
        if snd:
            try:
                snd.play()
            except Exception:
                pass

    def toggle_mute(self) -> bool:
        """Toggle audio enabled/disabled."""
        self.enabled = not self.enabled
        return self.enabled
