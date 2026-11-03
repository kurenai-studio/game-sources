"""Original Andean-flavoured music for the game, built on minor pentatonic scales.

Melodies are 'NOTE:SIXTEENTHS' tokens ('R' is a rest), played by a quena-like flute.
Each bar also names a chord, which a charango-like voice strums on the 'x' steps of the
song's strum pattern, and a bass plays on the 'R' (root) and 'F' (fifth) steps of its bass
pattern. Drums are one character per sixteenth: B bombo (deep drum), b soft bombo,
k wooden rim click, s shaker, '.' rest.
"""

from synth import Track, flute, note_freq, saw, sine, square, triangle

CHORDS = {
    "Am": ("A", [0, 3, 7]), "C": ("C", [0, 4, 7]), "G": ("G", [0, 4, 7]),
    "Dm": ("D", [0, 3, 7]), "Em": ("E", [0, 3, 7]), "F": ("F", [0, 4, 7]),
    "E": ("E", [0, 4, 7]), "Bb": ("Bb", [0, 4, 7]),
}


def parse(melody):
    notes = []
    for token in melody.split():
        name, length = token.split(":")
        notes.append((None if name == "R" else name, int(length)))
    return notes


def bombo(track, at, volume, seed):
    track.add_tone(at, 0.18, 85, sine, volume, freq_end=48, release=0.08)
    track.add_noise(at, 0.04, volume * 0.25, smoothing=0.7, decay_power=2.0, seed=seed)


def click(track, at, seed):
    track.add_tone(at, 0.015, 1900, triangle, 0.08, release=0.01)
    track.add_noise(at, 0.02, 0.05, smoothing=0.2, decay_power=2.0, seed=seed)


def shaker(track, at, seed):
    track.add_noise(at, 0.05, 0.035, smoothing=0.0, decay_power=1.4, seed=seed)


def strum(track, at, root, intervals, volume, spread=0.012):
    """A charango strum: the chord's notes plucked a hair apart, bright and quickly fading."""
    base = note_freq(root + "4")
    for i, interval in enumerate(intervals + [12]):
        freq = base * 2 ** (interval / 12)
        track.add_tone(at + i * spread, 0.11, freq, lambda p: 0.6 * saw(p) + 0.4 * square(p, 0.3),
                       volume, attack=0.002, decay=0.09, sustain=0.15, release=0.06)


def render(song):
    sixteenth = song["sixteenth"]
    steps = song["steps"]
    bars = [bar for section in song["form"] for bar in song["sections"][section]]
    total = len(bars) * steps * sixteenth
    track = Track(total + 0.6)

    for bar_index, (melody, chord) in enumerate(bars):
        bar_start = bar_index * steps * sixteenth
        notes = parse(melody)
        assert sum(length for _, length in notes) == steps, f"bar {bar_index} is not {steps} steps: {melody}"
        cursor = 0
        for name, length in notes:
            if name:
                track.add_tone(bar_start + cursor * sixteenth, length * sixteenth * 0.92, note_freq(name),
                               flute, song["lead_volume"], attack=0.03, decay=0.08, sustain=0.75,
                               release=0.07, vibrato=0.006 if length >= 4 else 0.0)
                # Breath at the start of each note.
                track.add_noise(bar_start + cursor * sixteenth, 0.05, song["lead_volume"] * 0.12,
                                smoothing=0.85, decay_power=1.5, seed=bar_index * 97 + cursor)
            cursor += length
        root, intervals = CHORDS[chord]
        for step, kind in enumerate(song["strum"]):
            if kind == "x":
                strum(track, bar_start + step * sixteenth, root, intervals, song["strum_volume"])
        bass_root = note_freq(root + "2")
        for step, kind in enumerate(song["bass"]):
            if kind in "RF":
                freq = bass_root if kind == "R" else bass_root * 2 ** (7 / 12)
                track.add_tone(bar_start + step * sixteenth, sixteenth * 1.8, freq, triangle, 0.32,
                               release=0.04)
        for step, kind in enumerate(song["drums"]):
            at = bar_start + step * sixteenth
            seed = bar_index * 31 + step
            if kind == "B":
                bombo(track, at, 0.55, seed)
            elif kind == "b":
                bombo(track, at, 0.3, seed)
            elif kind == "k":
                click(track, at, seed)
            elif kind == "s":
                shaker(track, at, seed)

    track.normalize(0.8)
    track.fade(fade_out=0.02)
    return track


# A minor pentatonic (A C D E G). The huayno rhythm: a long note, then two short ones.

TITLE_A = [
    ("E5:6 D5:2 C5:4 A4:4", "Am"), ("G4:8 A4:4 C5:4", "C"),
    ("D5:6 E5:2 D5:4 C5:4", "G"), ("A4:12 R:4", "Am"),
    ("C5:6 D5:2 E5:4 G5:4", "C"), ("A5:8 G5:4 E5:4", "Am"),
    ("D5:6 C5:2 D5:4 E5:4", "G"), ("A4:12 R:4", "Am"),
]

VALLEY_A = [
    ("A4:2 C5:1 D5:1 E5:2 E5:2 G5:2 E5:2 D5:4", "Am"),
    ("C5:2 D5:1 C5:1 A4:2 G4:2 A4:8", "C"),
    ("E5:2 G5:1 A5:1 G5:2 E5:2 D5:2 C5:2 D5:4", "G"),
    ("E5:2 D5:1 C5:1 D5:2 C5:2 A4:8", "Am"),
]
VALLEY_B = [
    ("A5:4 G5:2 E5:2 G5:4 A5:4", "Am"),
    ("C6:2 A5:2 G5:2 E5:2 D5:8", "G"),
    ("E5:2 G5:2 A5:2 G5:2 E5:2 D5:2 C5:2 D5:2", "C"),
    ("E5:2 D5:1 C5:1 A4:2 G4:2 A4:8", "Am"),
]

MOUNTAIN_A = [
    ("E5:3 D5:1 E5:2 G5:2 A5:4 G5:4", "Am"),
    ("E5:3 D5:1 C5:2 D5:2 E5:8", "C"),
    ("G5:3 E5:1 D5:2 C5:2 D5:4 E5:4", "G"),
    ("C5:3 A4:1 G4:2 A4:2 A4:8", "Am"),
]

# D minor pentatonic (D F G A C) for the caves: slower and darker.
CAVE_A = [
    ("D5:8 C5:4 A4:4", "Dm"), ("F4:8 G4:4 A4:4", "F"),
    ("C5:6 A4:2 G4:4 F4:4", "C"), ("D4:12 R:4", "Dm"),
    ("A4:6 C5:2 D5:4 F5:4", "Dm"), ("G5:8 F5:4 D5:4", "Bb"),
    ("C5:6 D5:2 C5:4 A4:4", "C"), ("D5:12 R:4", "Dm"),
]

# E minor pentatonic (E G A B D) for the guardian: fast and driving.
BOSS_A = [
    ("E5:2 E5:1 E5:1 G5:2 E5:2 B5:4 A5:4", "Em"),
    ("G5:2 A5:1 G5:1 E5:2 D5:2 E5:8", "Em"),
    ("D5:2 D5:1 D5:1 G5:2 D5:2 A5:4 G5:4", "G"),
    ("B5:2 A5:1 G5:1 A5:2 G5:2 E5:8", "Em"),
]
BOSS_B = [
    ("B5:4 D6:4 B5:2 A5:2 G5:4", "Em"),
    ("A5:4 G5:4 E5:4 D5:4", "G"),
    ("E5:2 G5:2 A5:2 B5:2 D6:2 B5:2 A5:2 G5:2", "C"),
    ("E5:12 R:4", "Em"),
]

SONGS = {
    "title_theme.ogg": {
        "sixteenth": 0.15, "steps": 16, "form": "AA", "lead_volume": 0.32, "strum_volume": 0.05,
        "sections": {"A": TITLE_A},
        "strum": "x.......x.......", "bass": "R.......F.......", "drums": "B.......b.......",
    },
    "valley_theme.ogg": {
        "sixteenth": 0.105, "steps": 16, "form": "AABA", "lead_volume": 0.3, "strum_volume": 0.06,
        "sections": {"A": VALLEY_A, "B": VALLEY_B},
        "strum": "x.xxx.xxx.xxx.xx", "bass": "R...F...R...F...", "drums": "B.k.b.kkB.k.b.ks",
    },
    "mountain_theme.ogg": {
        "sixteenth": 0.11, "steps": 16, "form": "AA", "lead_volume": 0.3, "strum_volume": 0.06,
        "sections": {"A": MOUNTAIN_A},
        "strum": "x..xx..xx..xx..x", "bass": "R..F..R.R..F..R.", "drums": "B..kb..kB..kb.ss",
    },
    "cave_theme.ogg": {
        "sixteenth": 0.16, "steps": 16, "form": "AA", "lead_volume": 0.28, "strum_volume": 0.04,
        "sections": {"A": CAVE_A},
        "strum": "x.......x.......", "bass": "R.......R...F...", "drums": "B.....k.b.....k.",
    },
    "boss_theme.ogg": {
        "sixteenth": 0.085, "steps": 16, "form": "AABA", "lead_volume": 0.3, "strum_volume": 0.07,
        "sections": {"A": BOSS_A, "B": BOSS_B},
        "strum": "x.xxx.xxx.xxx.xx", "bass": "R.R.F.R.R.R.F.R.", "drums": "B.kBb.kkB.kBb.kk",
    },
}
