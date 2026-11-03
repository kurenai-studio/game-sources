"""
Procedural Audio Synthesizer (Pure Python & Pygame).
Generates dynamic sound effects directly in memory (sine, triangle, white noise)
without requiring external .wav or .mp3 audio asset files.
"""

import math
import struct
import array
import random
import pygame
from typing import Optional

class SoundFX:
    """Procedural Synthesizer for tactile arcade audio feedback."""

    _initialized = False
    _enabled = True
    _master_volume: float = 1.0
    _sfx_volume: float = 1.0

    _base_volumes = {
        "hover": 0.15,
        "click": 0.28,
        "step": 0.12,
        "explosion": 0.35,
        "key": 0.25,
        "radar": 0.22,
        "victory": 0.25,
        "defeat": 0.25
    }

    _snd_hover: Optional[pygame.mixer.Sound] = None
    _snd_click: Optional[pygame.mixer.Sound] = None
    _snd_step: Optional[pygame.mixer.Sound] = None
    _snd_explosion: Optional[pygame.mixer.Sound] = None
    _snd_key: Optional[pygame.mixer.Sound] = None
    _snd_radar: Optional[pygame.mixer.Sound] = None
    _snd_victory: Optional[pygame.mixer.Sound] = None
    _snd_defeat: Optional[pygame.mixer.Sound] = None

    @classmethod
    def init(cls):
        """Initializes mixer and synthesizes audio waveform cache."""
        if cls._initialized:
            return

        try:
            if not pygame.mixer.get_init():
                pygame.mixer.init(frequency=44100, size=-16, channels=1, buffer=512)
        except Exception:
            cls._enabled = False
            return

        sample_rate = 44100

        def _make_sound(samples: array.array, sound_key: str) -> Optional[pygame.mixer.Sound]:
            try:
                raw_bytes = samples.tobytes()
                snd = pygame.mixer.Sound(buffer=raw_bytes)
                base = cls._base_volumes.get(sound_key, 0.25)
                snd.set_volume(base * cls._master_volume * cls._sfx_volume)
                return snd
            except Exception:
                return None

        # 1. Hover Blip (High frequency soft sine pulse, 20ms)
        n = int(sample_rate * 0.02)
        s_hover = array.array('h')
        for i in range(n):
            t = i / sample_rate
            env = 1.0 - (i / n)  # Linear decay
            val = int(32767 * 0.15 * env * math.sin(2 * math.pi * 950 * t))
            s_hover.append(max(-32767, min(32767, val)))
        cls._snd_hover = _make_sound(s_hover, "hover")

        # 2. Click Chirp (Upward frequency chirp, 40ms)
        n = int(sample_rate * 0.04)
        s_click = array.array('h')
        for i in range(n):
            t = i / sample_rate
            freq = 400 + 800 * (i / n)
            env = 1.0 - (i / n)
            val = int(32767 * 0.28 * env * math.sin(2 * math.pi * freq * t))
            s_click.append(max(-32767, min(32767, val)))
        cls._snd_click = _make_sound(s_click, "click")

        # 3. Soft Footstep Tick (12ms low frequency)
        n = int(sample_rate * 0.015)
        s_step = array.array('h')
        for i in range(n):
            t = i / sample_rate
            env = 1.0 - (i / n)
            val = int(32767 * 0.12 * env * math.sin(2 * math.pi * 180 * t))
            s_step.append(max(-32767, min(32767, val)))
        cls._snd_step = _make_sound(s_step, "step")

        # 4. Wall Demolition Blast (Noise + low-frequency punch, 240ms)
        n = int(sample_rate * 0.24)
        s_expl = array.array('h')
        for i in range(n):
            t = i / sample_rate
            env = (1.0 - (i / n)) ** 2
            sub = math.sin(2 * math.pi * (80 - 40 * (i / n)) * t)
            noise = (random.random() * 2.0 - 1.0) * 0.6
            val = int(32767 * 0.35 * env * (sub * 0.6 + noise * 0.4))
            s_expl.append(max(-32767, min(32767, val)))
        cls._snd_explosion = _make_sound(s_expl, "explosion")

        # 5. Golden Key Pickup (Ascending triad arpeggio, 160ms)
        n = int(sample_rate * 0.16)
        s_key = array.array('h')
        notes = [523.25, 659.25, 783.99, 1046.50]  # C5, E5, G5, C6
        chunk = n // len(notes)
        for i in range(n):
            note_idx = min(len(notes) - 1, i // chunk)
            freq = notes[note_idx]
            sub_i = i % chunk
            env = 1.0 - (sub_i / chunk)
            t = i / sample_rate
            val = int(32767 * 0.25 * env * math.sin(2 * math.pi * freq * t))
            s_key.append(max(-32767, min(32767, val)))
        cls._snd_key = _make_sound(s_key, "key")

        # 6. Radar Proximity Alert (Pulsing high alert, 70ms)
        n = int(sample_rate * 0.07)
        s_radar = array.array('h')
        for i in range(n):
            t = i / sample_rate
            env = math.sin(math.pi * (i / n))
            val = int(32767 * 0.22 * env * math.sin(2 * math.pi * 880 * t))
            s_radar.append(max(-32767, min(32767, val)))
        cls._snd_radar = _make_sound(s_radar, "radar")

        # 7. Victory Fanfare (Celebratory melody, 420ms)
        n = int(sample_rate * 0.42)
        s_vic = array.array('h')
        vic_notes = [523.25, 659.25, 783.99, 1046.50]
        step = n // 4
        for i in range(n):
            idx = min(3, i // step)
            freq = vic_notes[idx]
            t = i / sample_rate
            env = 1.0 - ((i % step) / step)
            val = int(32767 * 0.25 * env * math.sin(2 * math.pi * freq * t))
            s_vic.append(max(-32767, min(32767, val)))
        cls._snd_victory = _make_sound(s_vic, "victory")

        # 8. Defeat Chime (Descending minor cadence, 350ms)
        n = int(sample_rate * 0.35)
        s_def = array.array('h')
        def_notes = [440.0, 415.3, 392.0, 349.2]
        step = n // 4
        for i in range(n):
            idx = min(3, i // step)
            freq = def_notes[idx]
            t = i / sample_rate
            env = 1.0 - ((i % step) / step)
            val = int(32767 * 0.25 * env * math.sin(2 * math.pi * freq * t))
            s_def.append(max(-32767, min(32767, val)))
        cls._snd_defeat = _make_sound(s_def, "defeat")

        cls._initialized = True

    @classmethod
    def set_master_volume(cls, vol: float):
        """Sets Master Volume scalar (0.0 to 1.0) and updates all sounds."""
        cls._master_volume = max(0.0, min(1.0, float(vol)))
        cls._apply_volumes()

    @classmethod
    def get_master_volume(cls) -> float:
        return cls._master_volume

    @classmethod
    def set_sfx_volume(cls, vol: float):
        """Sets Sound Effects Volume scalar (0.0 to 1.0) and updates all sounds."""
        cls._sfx_volume = max(0.0, min(1.0, float(vol)))
        cls._apply_volumes()

    @classmethod
    def get_sfx_volume(cls) -> float:
        return cls._sfx_volume

    @classmethod
    def _apply_volumes(cls):
        """Recalculates and assigns dynamic volume gain to all cached sounds."""
        sound_map = {
            "hover": cls._snd_hover,
            "click": cls._snd_click,
            "step": cls._snd_step,
            "explosion": cls._snd_explosion,
            "key": cls._snd_key,
            "radar": cls._snd_radar,
            "victory": cls._snd_victory,
            "defeat": cls._snd_defeat
        }
        eff_mult = cls._master_volume * cls._sfx_volume if cls._enabled else 0.0
        for key, snd in sound_map.items():
            if snd:
                base = cls._base_volumes.get(key, 0.25)
                try:
                    snd.set_volume(max(0.0, min(1.0, base * eff_mult)))
                except Exception:
                    pass

    @classmethod
    def set_enabled(cls, enabled: bool):
        cls._enabled = enabled
        cls._apply_volumes()

    @classmethod
    def is_enabled(cls) -> bool:
        return cls._enabled

    @classmethod
    def play_test_beep(cls):
        """Plays a tactile chirp to test volume levels."""
        if cls._enabled and cls._snd_click:
            try: cls._snd_click.play()
            except Exception: pass

    @classmethod
    def play_hover(cls):
        if cls._enabled and cls._snd_hover:
            try: cls._snd_hover.play()
            except Exception: pass

    @classmethod
    def play_click(cls):
        if cls._enabled and cls._snd_click:
            try: cls._snd_click.play()
            except Exception: pass

    @classmethod
    def play_step(cls):
        if cls._enabled and cls._snd_step:
            try: cls._snd_step.play()
            except Exception: pass

    @classmethod
    def play_explosion(cls):
        if cls._enabled and cls._snd_explosion:
            try: cls._snd_explosion.play()
            except Exception: pass

    @classmethod
    def play_key(cls):
        if cls._enabled and cls._snd_key:
            try: cls._snd_key.play()
            except Exception: pass

    @classmethod
    def play_radar(cls):
        if cls._enabled and cls._snd_radar:
            try: cls._snd_radar.play()
            except Exception: pass

    @classmethod
    def play_victory(cls):
        if cls._enabled and cls._snd_victory:
            try: cls._snd_victory.play()
            except Exception: pass

    @classmethod
    def play_defeat(cls):
        if cls._enabled and cls._snd_defeat:
            try: cls._snd_defeat.play()
            except Exception: pass

