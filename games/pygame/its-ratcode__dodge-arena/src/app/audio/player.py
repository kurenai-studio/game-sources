"""The audio player: sound effects at the volumes from the settings, plus the adaptive music."""

from __future__ import annotations

import multiprocessing
from typing import TYPE_CHECKING

import pygame

from app import config
from app.audio.music import compose_pcm
from app.audio.sounds import build_sound_bank
from app.audio.synth import Synth

if TYPE_CHECKING:
    from app.core.settings import Settings

MUSIC_FADE = 4.0            # how fast the music volume glides to its target (per second)


class AudioPlayer:
    """If there is no audio device, the game still runs: every call quietly does nothing.

    Effects: loudness = master volume x effects volume x the call's own
    ``volume``. Menu sounds can be switched off on their own, and the same
    sound never retriggers faster than ``SOUND_MIN_GAP``.

    Music: composing it takes a few seconds of pure Python, so it happens in a
    separate process (its own CPU core and its own interpreter). A thread would
    not do: Python runs one thread at a time, and sharing would make the game
    stutter. The game starts at once and the music fades in when it is ready;
    if the process can't start, there is simply no music. Channel 0 is kept
    for it, and ``update`` queues one bar at a time at the current intensity,
    so new layers come in exactly on a bar line.
    """

    def __init__(self, settings: Settings, music: bool = True) -> None:
        self.settings = settings
        self.enabled = False
        self.sounds: dict[str, pygame.mixer.Sound] = {}
        self.last_played: dict[str, float] = {}
        self.music: list[list[pygame.mixer.Sound]] | None = None     # [level][bar], once composed
        self.bar = 0                                # the bar playing (or queued) right now
        self.music_volume = 0.0                     # current, gliding toward the target
        self.silent_until = 0.0                     # the music holds off until then (death beat)
        self.composer = None                        # the process composing the music
        self.pending = None                         # its result, until it arrives
        try:
            if not pygame.mixer.get_init():
                pygame.mixer.init(config.AUDIO_RATE, -16, 1, 512)    # mono 16-bit, small buffer = low delay
            rate, size, channels = pygame.mixer.get_init()
        except (pygame.error, TypeError):                            # no device (get_init returned None)
            return
        if abs(size) != 16:                                          # to_sound writes 16-bit samples
            return
        pygame.mixer.set_num_channels(config.AUDIO_CHANNELS)
        pygame.mixer.set_reserved(1)                                 # channel 0: music only
        self.music_channel = pygame.mixer.Channel(0)
        self.channels = channels
        self.synth = Synth(rate)
        self.sounds = {name: self.synth.to_sound(samples, channels)
                       for name, samples in build_sound_bank(self.synth).items()}
        self.enabled = True
        if music:
            self.start_composing(rate)

    # --- Effects -----------------------------------------------------------------------------------
    def loudness(self) -> float:
        o = self.settings.options
        return o["master_volume"] / 100 * o["sfx_volume"] / 100

    def play(self, name: str, volume: float = 1.0) -> bool:
        """Play a sound effect. Returns True if it actually started."""
        sound = self.sounds.get(name)
        if not self.enabled or sound is None:
            return False
        now = pygame.time.get_ticks() / 1000
        if now - self.last_played.get(name, -1.0) < config.SOUND_MIN_GAP:
            return False
        loudness = min(1.0, self.loudness() * volume)
        if loudness <= 0:
            return False
        self.last_played[name] = now
        sound.set_volume(loudness)
        sound.play()
        return True

    def ui(self, name: str) -> bool:
        """A menu sound ("hover", "click" ...), unless menu sounds are switched off."""
        if not self.settings.options["ui_sounds"]:
            return False
        return self.play(name if name in self.sounds else f"ui_{name}")

    # --- Music -------------------------------------------------------------------------------------
    def start_composing(self, rate: int) -> None:
        """Start composing in another process. Music is optional: if that fails, there is none."""
        try:
            self.composer = multiprocessing.get_context("spawn").Pool(1)
            self.pending = self.composer.apply_async(compose_pcm, (rate, self.channels))
        except (OSError, RuntimeError, ValueError):
            self.close()

    def collect_music(self) -> None:
        """Once the composer is done, turn its bytes into Sounds (a few ms) and stop the process."""
        if self.pending is None or not self.pending.ready():
            return
        try:
            self.music = [[pygame.mixer.Sound(buffer=pcm) for pcm in level] for level in self.pending.get()]
        except Exception:                                            # noqa: BLE001 - never crash the game
            self.music = None
        self.close()

    def close(self) -> None:
        """Stop the composer process if it is still running (called when the game quits)."""
        if self.composer is not None:
            self.composer.terminate()
        self.composer = None
        self.pending = None

    def music_target(self, ducked: bool) -> float:
        o = self.settings.options
        return o["master_volume"] / 100 * o["music_volume"] / 100 * (config.MUSIC_DUCK if ducked else 1.0)

    def update(self, dt: float, intensity: int, ducked: bool) -> None:
        """Keep the loop going at ``intensity`` (0 = menus) and glide the volume."""
        if not self.enabled:
            return
        if self.music is None:
            self.collect_music()
            return
        if pygame.time.get_ticks() / 1000 < self.silent_until:
            return
        level = self.music[max(0, min(intensity, len(self.music) - 1))]
        channel = self.music_channel
        if not channel.get_busy():                    # first start, or after a silence: fade in from bar 0
            self.bar = 0
            self.music_volume = 0.0
            channel.set_volume(0.0)
            channel.play(level[0])
        elif channel.get_queue() is None:             # the queued bar has just started: queue the next one
            self.bar = (self.bar + 1) % len(level)
            channel.queue(level[self.bar])
        target = self.music_target(ducked)
        step = MUSIC_FADE * dt
        self.music_volume += max(-step, min(step, target - self.music_volume))
        channel.set_volume(max(0.0, min(1.0, self.music_volume)))

    def silence(self, seconds: float) -> None:
        """Cut the music for a dramatic beat; it fades back in afterwards."""
        if self.enabled:
            self.music_channel.fadeout(120)
            self.silent_until = pygame.time.get_ticks() / 1000 + seconds
