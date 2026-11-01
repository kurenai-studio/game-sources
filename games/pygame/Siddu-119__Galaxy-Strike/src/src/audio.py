"""Optional procedural sound effects; the game remains silent-safe."""

import math
import os
from array import array

import pygame


class Audio:
    def __init__(self):
        self.enabled = False
        self.sounds = {}
        self.master_volume = 0.8
        self.music_volume = 0.45
        self.sfx_volume = 0.65
        self.music_channel = None
        self.music_mode = "menu"
        self.music_enabled = False
        try:
            if not pygame.mixer.get_init():
                pygame.mixer.init(frequency=22050, size=-16, channels=1, buffer=512)
            self.music_channel = pygame.mixer.Channel(7)
            self.music_tracks = {
                "menu": self._music_track(0),
                "game": self._music_track(1),
                "boss": self._music_track(2),
                "victory": self._music_track(3),
                "game_over": self._music_track(4),
            }
            self.sounds = {
                "shoot": self._tone(920, 0.065, 0.22, True),
                "hit": self._tone(155, 0.16, 0.28, False),
                "collision": self._tone(115, 0.24, 0.32, False),
                "explosion": self._tone(82, 0.42, 0.38, False),
                "power": self._tone(670, 0.22, 0.28, True),
                "powerup": self._tone(780, 0.2, 0.27, True),
                "boss": self._tone(95, 0.5, 0.32, False),
                "boss_warning": self._tone(72, 0.72, 0.34, False),
                "boss_phase": self._tone(390, 0.42, 0.27, True),
                "boss_defeat": self._tone(230, 0.85, 0.32, True),
                "victory": self._tone(660, 0.9, 0.3, True),
                "game_over": self._tone(130, 0.9, 0.32, False),
                "select": self._tone(530, 0.09, 0.2, True),
            }
            self.sounds["shoot"] = self._load_optional_sound(
                os.path.join("assets", "sounds", "laser.wav"), self.sounds["shoot"]
            )
            self.sounds["powerup"] = self._load_optional_sound(
                os.path.join("assets", "sounds", "powerup.wav"), self.sounds["powerup"]
            )
            self.enabled = True
        except pygame.error as error:
            print(f"Audio is unavailable: {error}")
            self.music_channel = None

    @staticmethod
    def _load_optional_sound(path, fallback):
        try:
            return pygame.mixer.Sound(path)
        except (OSError, pygame.error):
            return fallback

    @staticmethod
    def _music_track(theme):
        sample_rate = 22050
        duration = 4.0
        notes = (
            (110.0, 138.59, 164.81, 146.83),
            (130.81, 164.81, 196.0, 174.61),
            (82.41, 98.0, 110.0, 92.5),
            (261.63, 329.63, 392.0, 523.25),
            (110.0, 103.83, 98.0, 82.41),
        )[theme]
        samples = array("h")
        for index in range(int(sample_rate * duration)):
            progress = index / sample_rate
            bar = int(progress) % len(notes)
            note = notes[bar]
            phase = progress % 1.0
            envelope = min(1.0, phase * 7, (1.0 - phase) * 5)
            pad = (math.sin(math.tau * note * progress) * 0.55 +
                   math.sin(math.tau * note * 1.5 * progress) * 0.2 +
                   math.sin(math.tau * note * 2 * progress) * 0.12)
            samples.append(int(32767 * 0.09 * envelope * pad))
        return pygame.mixer.Sound(buffer=samples.tobytes())

    def set_music_enabled(self, enabled):
        self.music_enabled = enabled
        if not self.enabled:
            return
        if enabled:
            if not self.music_channel.get_busy():
                self.music_channel.play(self.music_tracks[self.music_mode], loops=-1)
            self.music_channel.set_volume(self.music_volume * self.master_volume * 0.7)
        else:
            self.music_channel.stop()

    def set_music_mode(self, mode):
        if mode not in ("menu", "game", "boss", "victory", "game_over"):
            return
        if mode == self.music_mode:
            return
        self.music_mode = mode
        if self.enabled and self.music_enabled:
            self.music_channel.stop()
            self.music_channel.play(self.music_tracks[mode], loops=-1)
            self.music_channel.set_volume(self.music_volume * self.master_volume * 0.7)

    @staticmethod
    def _tone(frequency, duration, volume, sweep):
        sample_rate = 22050
        sample_count = int(sample_rate * duration)
        samples = array("h")
        for index in range(sample_count):
            progress = index / sample_rate
            current_frequency = frequency * (1.0 - 0.65 * progress / duration) if sweep else frequency
            envelope = min(1.0, index / 120, (sample_count - index) / 180)
            value = int(32767 * volume * envelope *
                        math.sin(math.tau * current_frequency * progress))
            samples.append(value)
        if samples.itemsize != 2:
            return pygame.mixer.Sound(buffer=b"")
        return pygame.mixer.Sound(buffer=samples.tobytes())

    def set_volumes(self, music, sfx, master=None):
        self.music_volume = max(0.0, min(1.0, music))
        self.sfx_volume = max(0.0, min(1.0, sfx))
        if master is not None:
            self.master_volume = max(0.0, min(1.0, master))
        if self.enabled and self.music_channel and self.music_channel.get_busy():
            self.music_channel.set_volume(self.music_volume * self.master_volume * 0.7)

    def play(self, name):
        sound = self.sounds.get(name)
        if self.enabled and sound and self.sfx_volume > 0:
            sound.set_volume(self.sfx_volume * self.master_volume)
            sound.play()
