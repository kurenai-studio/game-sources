#!/usr/bin/env python3
"""Generates Shiftborn's retro sound effects as 16-bit mono WAV files.

A tiny sfxr-style synth: one oscillator per layer (square, saw, triangle,
sine or noise) with a frequency slide, optional vibrato and arpeggio, an
attack/sustain/decay envelope with punch, and a one-pole low-pass filter.
No third-party packages. Output is deterministic (fixed seeds), so the
files can be regenerated and diffed.

Usage: python3 tools/generate_sfx.py [output_dir]
Default output: assets/audio/sfx/<name>_<variant>.wav
"""

import math
import os
import random
import struct
import sys
import wave
from dataclasses import dataclass, replace

SAMPLE_RATE = 44100
PEAK = 0.8  # Headroom below full scale after normalising.
FADE_OUT = 0.004  # Seconds of fade at the end to avoid a click.


@dataclass(frozen=True)
class Voice:
    wave: str = "square"  # square | saw | triangle | sine | noise
    freq: float = 440.0  # Start frequency in Hz.
    slide: float = 0.0  # Frequency change in octaves per second.
    duty: float = 0.5  # Square wave duty cycle.
    vibrato_depth: float = 0.0  # Fraction of the frequency.
    vibrato_rate: float = 0.0  # Hz.
    attack: float = 0.0  # Seconds.
    sustain: float = 0.05  # Seconds at full volume.
    decay: float = 0.15  # Seconds to silence.
    punch: float = 0.0  # Extra volume at the start of sustain (0..1).
    lowpass: float = 1.0  # 1 = off; lower values darken the sound.
    arpeggio: tuple = ()  # Frequency multipliers, stepped evenly.
    volume: float = 1.0  # Mix level when layered.
    min_freq: float = 20.0


@dataclass(frozen=True)
class Sound:
    name: str
    layers: tuple
    variants: int = 1
    # Per-variant random spread (octaves) applied to every layer's frequency.
    pitch_spread: float = 0.0
    seed: int = 1


def envelope(voice: Voice, t: float) -> float:
    if t < voice.attack:
        return t / voice.attack
    t -= voice.attack
    if t < voice.sustain:
        return 1.0 + voice.punch * (1.0 - t / voice.sustain)
    t -= voice.sustain
    if t < voice.decay:
        return 1.0 - t / voice.decay
    return 0.0


def duration(voice: Voice) -> float:
    return voice.attack + voice.sustain + voice.decay


def oscillator(voice: Voice, phase: float, wrapped: bool, rng: random.Random, noise: list) -> float:
    if voice.wave == "square":
        return 1.0 if phase < voice.duty else -1.0
    if voice.wave == "saw":
        return 2.0 * phase - 1.0
    if voice.wave == "triangle":
        return 4.0 * abs(phase - 0.5) - 1.0
    if voice.wave == "sine":
        return math.sin(2.0 * math.pi * phase)
    # Noise: a new random value per oscillator cycle, like sfxr.
    if wrapped:
        noise[0] = rng.uniform(-1.0, 1.0)
    return noise[0]


def render_voice(voice: Voice, rng: random.Random) -> list:
    length = duration(voice)
    samples = []
    phase = 0.0
    filtered = 0.0
    noise = [rng.uniform(-1.0, 1.0)]
    for i in range(int(length * SAMPLE_RATE)):
        t = i / SAMPLE_RATE
        freq = voice.freq * (2.0 ** (voice.slide * t))
        if voice.arpeggio:
            step = min(int(t / length * len(voice.arpeggio)), len(voice.arpeggio) - 1)
            freq *= voice.arpeggio[step]
        if voice.vibrato_depth > 0.0:
            freq *= 1.0 + voice.vibrato_depth * math.sin(2.0 * math.pi * voice.vibrato_rate * t)
        phase += max(freq, voice.min_freq) / SAMPLE_RATE
        wrapped = phase >= 1.0
        phase %= 1.0
        filtered += voice.lowpass * (oscillator(voice, phase, wrapped, rng, noise) - filtered)
        samples.append(filtered * envelope(voice, t) * voice.volume)
    return samples


def render(sound: Sound, variant: int) -> list:
    rng = random.Random(sound.seed * 1000 + variant)
    pitch = 2.0 ** rng.uniform(-sound.pitch_spread, sound.pitch_spread)
    mixed: list = []
    for layer in sound.layers:
        samples = render_voice(replace(layer, freq=layer.freq * pitch), rng)
        mixed.extend([0.0] * max(0, len(samples) - len(mixed)))
        for i, value in enumerate(samples):
            mixed[i] += value
    return normalise(mixed)


def normalise(samples: list) -> list:
    peak = max((abs(s) for s in samples), default=0.0)
    if peak == 0.0:
        return samples
    out = [s * PEAK / peak for s in samples]
    fade = min(len(out), int(FADE_OUT * SAMPLE_RATE))
    for i in range(fade):
        out[-1 - i] *= i / fade
    return out


def write_wav(path: str, samples: list) -> None:
    with wave.open(path, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples))


# Frequency ratios for arpeggios: major triad up an octave.
MAJOR = (1.0, 1.26, 1.5, 2.0)
FANFARE = (1.0, 1.26, 1.5, 2.0, 2.52, 3.0)

SOUNDS = (
    # Warrior.
    Sound("axe_swing", (Voice("noise", 1800, slide=-3.0, attack=0.02, sustain=0.05, decay=0.12, lowpass=0.35),),
          variants=3, pitch_spread=0.15, seed=11),
    Sound("axe_hit", (
        Voice("noise", 900, sustain=0.01, decay=0.07, punch=0.6, lowpass=0.5),
        Voice("square", 180, slide=-4.0, duty=0.3, sustain=0.01, decay=0.08, volume=0.6),
    ), variants=3, pitch_spread=0.2, seed=12),
    # Mage.
    Sound("bolt_cast", (Voice("square", 520, slide=2.5, duty=0.25, sustain=0.02, decay=0.1, lowpass=0.6),),
          variants=3, pitch_spread=0.1, seed=21),
    Sound("bolt_hit", (
        Voice("noise", 3000, sustain=0.005, decay=0.06, lowpass=0.7, volume=0.8),
        Voice("sine", 900, slide=-3.0, sustain=0.01, decay=0.05, volume=0.5),
    ), variants=2, pitch_spread=0.15, seed=22),
    # A hit on the form an enemy resists: a dull, low clank.
    Sound("hit_resisted", (
        Voice("square", 140, slide=-1.0, duty=0.15, sustain=0.01, decay=0.06, lowpass=0.25),
        Voice("noise", 250, sustain=0.005, decay=0.04, lowpass=0.2, volume=0.6),
    ), variants=2, pitch_spread=0.1, seed=13),
    # A critical hit: a bright metallic ping on top of the hit.
    Sound("crit", (
        Voice("square", 1400, slide=1.5, duty=0.2, sustain=0.02, decay=0.12, lowpass=0.7),
        Voice("triangle", 2100, sustain=0.02, decay=0.1, volume=0.5),
    ), variants=2, pitch_spread=0.06, seed=14),
    # Enemies.
    Sound("enemy_death", (
        Voice("noise", 600, slide=-2.0, sustain=0.02, decay=0.18, punch=0.5, lowpass=0.45),
        Voice("square", 330, slide=-5.0, sustain=0.02, decay=0.12, volume=0.5),
    ), variants=3, pitch_spread=0.2, seed=31),
    # Player.
    Sound("player_hurt", (
        Voice("saw", 260, slide=-3.5, sustain=0.03, decay=0.14, punch=0.4, lowpass=0.5),
        Voice("noise", 500, sustain=0.02, decay=0.08, lowpass=0.4, volume=0.5),
    ), variants=2, pitch_spread=0.08, seed=41),
    Sound("player_death", (
        Voice("square", 400, slide=-1.6, duty=0.4, vibrato_depth=0.04, vibrato_rate=9, sustain=0.15, decay=0.9, lowpass=0.5),
        Voice("noise", 300, slide=-1.0, sustain=0.05, decay=0.6, lowpass=0.25, volume=0.5),
    ), seed=42),
    # Shift.
    Sound("shift_to_mage", (
        Voice("square", 300, slide=4.0, duty=0.25, sustain=0.05, decay=0.12, lowpass=0.5),
        Voice("sine", 600, slide=4.0, sustain=0.05, decay=0.12, volume=0.5),
    ), seed=51),
    Sound("shift_to_warrior", (
        Voice("square", 700, slide=-4.0, duty=0.4, sustain=0.05, decay=0.12, lowpass=0.5),
        Voice("noise", 400, slide=-2.0, sustain=0.03, decay=0.1, lowpass=0.3, volume=0.4),
    ), seed=52),
    # Perfect shift: a bright rising chime over a soft whoosh.
    Sound("perfect_shift", (
        Voice("square", 784, duty=0.25, sustain=0.18, decay=0.25, arpeggio=(1.0, 1.25, 1.5, 2.0), lowpass=0.65),
        Voice("triangle", 1568, slide=0.5, sustain=0.15, decay=0.3, volume=0.5),
        Voice("noise", 2500, slide=-2.0, attack=0.02, sustain=0.05, decay=0.25, lowpass=0.3, volume=0.35),
    ), seed=54),
    Sound("shift_burst", (
        Voice("noise", 200, slide=-1.5, sustain=0.04, decay=0.35, punch=0.8, lowpass=0.3),
        Voice("sine", 110, slide=-2.0, sustain=0.05, decay=0.3, volume=0.8),
    ), seed=53),
    # Boss.
    Sound("boss_roar", (
        Voice("saw", 120, slide=-0.8, vibrato_depth=0.08, vibrato_rate=12, attack=0.05, sustain=0.35, decay=0.5, lowpass=0.35),
        Voice("noise", 180, slide=-1.0, attack=0.05, sustain=0.3, decay=0.45, lowpass=0.2, volume=0.6),
    ), seed=71),
    Sound("boss_swap", (
        Voice("square", 220, slide=3.0, duty=0.3, sustain=0.08, decay=0.2, lowpass=0.4),
        Voice("square", 880, slide=-3.0, duty=0.3, sustain=0.08, decay=0.2, lowpass=0.4, volume=0.6),
    ), seed=72),
    Sound("boss_shot", (Voice("square", 700, slide=-3.5, duty=0.35, sustain=0.03, decay=0.14, lowpass=0.5),), seed=73),
    Sound("boss_dash", (Voice("noise", 900, slide=-2.5, attack=0.1, sustain=0.15, decay=0.25, lowpass=0.3),), seed=74),
    # Progression and UI.
    Sound("level_up", (
        Voice("square", 523, sustain=0.32, decay=0.18, arpeggio=MAJOR, lowpass=0.6),
        Voice("triangle", 1046, sustain=0.32, decay=0.18, arpeggio=MAJOR, volume=0.4),
    ), seed=61),
    Sound("card_pick", (
        Voice("square", 880, slide=1.0, duty=0.25, sustain=0.03, decay=0.08, lowpass=0.7),
        Voice("square", 1320, duty=0.25, sustain=0.03, decay=0.08, volume=0.4),
    ), seed=62),
    Sound("ui_move", (Voice("square", 660, duty=0.25, sustain=0.01, decay=0.03, lowpass=0.6),), seed=63),
    Sound("run_win", (
        Voice("square", 392, sustain=0.6, decay=0.4, arpeggio=FANFARE, lowpass=0.6),
        Voice("triangle", 196, sustain=0.6, decay=0.4, volume=0.6),
    ), seed=64),
)


def main() -> int:
    out_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.join("assets", "audio", "sfx")
    os.makedirs(out_dir, exist_ok=True)
    count = 0
    for sound in SOUNDS:
        for variant in range(sound.variants):
            write_wav(os.path.join(out_dir, f"{sound.name}_{variant}.wav"), render(sound, variant))
            count += 1
    print(f"wrote {count} files to {out_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
