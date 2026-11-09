"""The adaptive soundtrack: one short loop, composed in code, in several intensity levels.

The loop is Am - F - C - G, one chord per bar, built as separate layers
("stems"): pad, bass, drums, arpeggio and lead. Each intensity level mixes
some of them, and every level is cut into one-bar pieces, so the player can
switch level exactly on a bar line and the music always stays in time.
"""

import math

from app import config
from app.audio.synth import Samples, Synth

# Layer volumes for each level. 0 = menus (calm); 1-4 follow the danger of the run.
LEVELS: tuple[dict[str, float], ...] = (
    {"pad": 1.0, "bass": 0.5},
    {"pad": 0.9, "bass": 0.9, "hats": 0.7},
    {"pad": 0.8, "bass": 1.0, "hats": 1.0, "kick": 1.0, "snare": 0.8},
    {"pad": 0.7, "bass": 1.0, "hats": 1.0, "kick": 1.0, "snare": 1.0, "arp": 1.0},
    {"pad": 0.6, "bass": 1.1, "hats": 1.0, "hats16": 1.0, "kick": 1.15, "snare": 1.1, "arp": 1.0, "lead": 1.0},
)
CHORDS = ((220.00, 261.63, 329.63), (174.61, 220.00, 261.63),       # Am, F
          (261.63, 329.63, 392.00), (196.00, 246.94, 293.66))       # C, G


def compose_stems(s: Synth) -> tuple[dict[str, Samples], int]:
    """Every layer as a buffer of exactly the loop's length. Returns (stems, loop length in samples)."""
    rate = s.rate
    beat = 60 / config.MUSIC_BPM
    bar = beat * 4
    beats = 4 * config.MUSIC_BARS
    total = int(bar * config.MUSIC_BARS * rate)

    def place(parts: list[tuple[Samples, float]]) -> Samples:
        out = [0.0] * total
        if parts:
            mixed = s.mix(*parts)
            out[:min(total, len(mixed))] = mixed[:total]
        return out

    stems: dict[str, Samples] = {}
    # Pad: slightly detuned sine chords that swell and fade over each bar.
    pad = [0.0] * total
    bar_n = int(bar * rate)
    for c, notes in enumerate(CHORDS):
        freqs = [f * detune for f in notes for detune in (1.0, 1.004)]
        for i in range(min(bar_n, total - c * bar_n)):
            t = i / rate
            swell = math.sin(math.pi * i / bar_n) ** 0.6
            pad[c * bar_n + i] = sum(math.sin(math.tau * f * t) for f in freqs) * swell * 0.022
    stems["pad"] = pad
    # Bass: an 8th-note pulse on the root, jumping an octave on the last 8th of each half bar.
    stems["bass"] = place([(s.tone(notes[0] / 2 * (2 if k % 4 == 3 else 1), beat * 0.45, wave="square",
                                   decay=9, volume=0.09), c * bar + k * beat / 2)
                           for c, notes in enumerate(CHORDS) for k in range(8)])
    # Drums.
    kick = s.tone(120, 0.25, freq_end=45, decay=14, volume=0.55)
    snare = s.mix((s.noise(0.16, decay=22, volume=0.22, smooth=0.7), 0),
                  (s.tone(210, 0.1, wave="triangle", decay=30, volume=0.15), 0))
    hat = s.noise(0.035, decay=90, volume=0.12)
    stems["kick"] = place([(kick, b * beat) for b in range(beats)])
    stems["snare"] = place([(snare, (b + 1) * beat) for b in range(0, beats, 2)])
    stems["hats"] = place([(hat, b * beat + beat / 2) for b in range(beats)])
    stems["hats16"] = place([(hat, b * beat + q * beat / 4) for b in range(beats) for q in (1, 3)])
    # Arpeggio: fast 16th notes running through each chord.
    stems["arp"] = place([(s.tone((n[0] * 2, n[1] * 2, n[2] * 2, n[1] * 4)[k % 4], beat / 4 * 0.9,
                                  wave="triangle", decay=14, volume=0.045), c * bar + k * beat / 4)
                          for c, n in enumerate(CHORDS) for k in range(16)])
    # Lead: tense saw notes with vibrato (top level only).
    stems["lead"] = place([(s.tone(f, bar / 2 * 0.95, wave="saw", attack=0.03, decay=1.5, volume=0.05,
                                   vibrato_rate=6, vibrato_depth=0.012), c * bar + h * bar / 2)
                           for c, n in enumerate(CHORDS) for h, f in enumerate((n[2] * 2, n[1] * 2))])
    return stems, total


def build_levels(s: Synth) -> list[list[Samples]]:
    """For each level, the mixed loop cut into one-bar pieces: ``levels[level][bar]``."""
    stems, total = compose_stems(s)
    bar_n = total // config.MUSIC_BARS
    levels = []
    for weights in LEVELS:
        mixed = [0.0] * total
        for name, weight in weights.items():
            stem = stems[name]
            for i in range(total):
                mixed[i] += stem[i] * weight
        levels.append([mixed[b * bar_n:(b + 1) * bar_n] for b in range(config.MUSIC_BARS)])
    return levels


def compose_pcm(rate: int, channels: int) -> list[list[bytes]]:
    """Every level as raw audio bytes, ``[level][bar]``. Runs in a separate process (see AudioPlayer):
    plain bytes travel between processes, pygame Sounds don't."""
    synth = Synth(rate)
    return [[synth.to_pcm(bar, channels) for bar in level] for level in build_levels(synth)]


def intensity_for(danger: float) -> int:
    """The music level for a danger of 0..1: 1, plus one per threshold passed."""
    return 1 + sum(1 for t in config.MUSIC_LEVEL_THRESHOLDS if danger >= t)
