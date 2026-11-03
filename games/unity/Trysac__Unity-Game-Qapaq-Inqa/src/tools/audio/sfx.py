"""Sound effect recipes. Each function returns a rendered Track."""

from synth import Track, flute, note_freq, saw, sine, square, triangle


def pulse(duty):
    return lambda p: square(p, duty)


def jump():
    """A light hop: a quick upward chirp."""
    t = Track(0.16)
    t.add_tone(0, 0.09, 330, pulse(0.25), 0.18, freq_end=620, release=0.03)
    return t


def land():
    """Sandals on stone: a soft dull thud."""
    t = Track(0.1)
    t.add_noise(0, 0.05, 0.3, smoothing=0.85, decay_power=2.0, seed=11)
    t.add_tone(0, 0.04, 140, triangle, 0.25, freq_end=80, release=0.02)
    return t


def shoot():
    """The bow: a taut string twang and the swish of the arrow."""
    t = Track(0.22)
    t.add_tone(0, 0.1, 220, saw, 0.16, freq_end=180, decay=0.08, sustain=0.2, release=0.05, vibrato=0.02)
    t.add_noise(0.02, 0.12, 0.12, smoothing=0.3, decay_power=1.2, seed=12)
    return t


def arrow_hit():
    """An arrow strikes stone or a stone warrior."""
    t = Track(0.12)
    t.add_noise(0, 0.05, 0.35, smoothing=0.5, decay_power=2.2, seed=13)
    t.add_tone(0, 0.04, 900, triangle, 0.15, freq_end=400, release=0.02)
    return t


def coin():
    """A small gold disc: two bright notes."""
    t = Track(0.25)
    t.add_tone(0, 0.05, note_freq("E6"), pulse(0.5), 0.14, release=0.02)
    t.add_tone(0.05, 0.12, note_freq("A6"), pulse(0.5), 0.14, release=0.06)
    return t


def idol():
    """A golden idol: a rising pentatonic shimmer."""
    t = Track(0.7)
    for i, n in enumerate(["A5", "C6", "D6", "E6", "G6", "A6"]):
        t.add_tone(i * 0.06, 0.18, note_freq(n), triangle, 0.2, release=0.15)
        t.add_tone(i * 0.06, 0.18, note_freq(n) * 2, sine, 0.06, release=0.15)
    return t


def shell():
    """A mullu shell: a hollow, sea-like chord."""
    t = Track(0.8)
    for i, n in enumerate(["D5", "A5", "E6"]):
        t.add_tone(i * 0.05, 0.4, note_freq(n), flute, 0.2, attack=0.03, release=0.3, vibrato=0.01)
    t.add_noise(0, 0.5, 0.05, smoothing=0.95, decay_power=0.8, seed=14)
    return t


def heart():
    """A warm two-note rise."""
    t = Track(0.4)
    t.add_tone(0, 0.1, note_freq("C5"), triangle, 0.25, release=0.05)
    t.add_tone(0.1, 0.2, note_freq("G5"), triangle, 0.25, release=0.1)
    return t


def checkpoint():
    """A carved stone wakes up: a low hum and a bright bell."""
    t = Track(0.9)
    t.add_tone(0, 0.5, note_freq("A3"), triangle, 0.2, attack=0.05, release=0.3)
    t.add_tone(0.08, 0.15, note_freq("E6"), sine, 0.2, decay=0.1, sustain=0.3, release=0.5)
    t.add_tone(0.16, 0.15, note_freq("A6"), sine, 0.15, decay=0.1, sustain=0.3, release=0.5)
    return t


def gate_open():
    """The Sun Gate unseals: grinding stone under a chord of light."""
    t = Track(1.6)
    t.add_noise(0, 1.0, 0.25, smoothing=0.92, decay_power=0.6, seed=15)
    t.add_tone(0, 0.9, 55, saw, 0.12, freq_end=48, release=0.3)
    for i, n in enumerate(["A4", "E5", "A5", "C#6"]):
        t.add_tone(0.4 + i * 0.08, 0.6, note_freq(n), flute, 0.13, attack=0.05, release=0.4)
    return t


def hurt():
    """The player is struck: a falling buzz."""
    t = Track(0.3)
    t.add_tone(0, 0.18, 420, pulse(0.3), 0.2, freq_end=140, release=0.05)
    t.add_noise(0, 0.08, 0.2, smoothing=0.4, decay_power=2.0, seed=16)
    return t


def die():
    """A life is lost: a slow descending phrase."""
    t = Track(1.2)
    for i, n in enumerate(["E5", "D5", "C5", "A4"]):
        t.add_tone(i * 0.18, 0.2, note_freq(n), flute, 0.25, release=0.1, vibrato=0.01)
    t.add_tone(0.72, 0.3, note_freq("A3"), triangle, 0.25, release=0.2)
    return t


def stomp():
    """Boots on a stone warrior's head."""
    t = Track(0.2)
    t.add_tone(0, 0.08, 260, pulse(0.5), 0.2, freq_end=520, release=0.03)
    t.add_noise(0, 0.05, 0.25, smoothing=0.6, decay_power=2.0, seed=17)
    return t


def enemy_die():
    """A stone warrior crumbles to rubble."""
    t = Track(0.5)
    t.add_noise(0, 0.35, 0.4, smoothing=0.75, decay_power=1.4, seed=18)
    t.add_tone(0, 0.2, 160, triangle, 0.3, freq_end=60, release=0.1)
    return t


def boss_roar():
    """The Stone Puma wakes: a rough growl that swells and falls."""
    t = Track(1.2)
    t.add_tone(0, 0.8, 90, saw, 0.3, freq_end=60, attack=0.15, release=0.3, vibrato=0.06)
    t.add_tone(0, 0.8, 135, saw, 0.15, freq_end=95, attack=0.15, release=0.3, vibrato=0.08)
    t.add_noise(0, 0.9, 0.25, smoothing=0.8, decay_power=0.8, seed=19)
    return t


def boss_slam():
    """It lands from a leap: a heavy impact."""
    t = Track(0.6)
    t.add_tone(0, 0.3, 70, sine, 0.6, freq_end=35, release=0.2)
    t.add_noise(0, 0.3, 0.4, smoothing=0.85, decay_power=1.2, seed=20)
    return t


def boss_throw():
    """A rock torn up and hurled."""
    t = Track(0.3)
    t.add_noise(0, 0.2, 0.25, smoothing=0.5, decay_power=1.0, seed=21)
    t.add_tone(0, 0.15, 200, triangle, 0.15, freq_end=400, release=0.05)
    return t


def boss_defeat():
    """The guardian falls: a long rumble, then silence."""
    t = Track(2.0)
    t.add_noise(0, 1.6, 0.45, smoothing=0.9, decay_power=0.7, seed=22)
    t.add_tone(0, 1.2, 80, saw, 0.2, freq_end=30, release=0.4)
    return t


def clear():
    """A trial passed: a short fanfare in A minor pentatonic resolving to A major."""
    t = Track(1.6)
    for i, n in enumerate(["A4", "C5", "E5", "A5"]):
        t.add_tone(i * 0.12, 0.14, note_freq(n), flute, 0.25, release=0.05)
    t.add_tone(0.5, 0.7, note_freq("C#6"), flute, 0.22, release=0.3, vibrato=0.01)
    t.add_tone(0.5, 0.7, note_freq("A5"), flute, 0.2, release=0.3, vibrato=0.01)
    t.add_tone(0.5, 0.7, note_freq("E5"), triangle, 0.15, release=0.3)
    return t


def game_over():
    """All lives lost: a low, slow fall."""
    t = Track(1.8)
    for i, n in enumerate(["A4", "G4", "E4", "D4", "A3"]):
        t.add_tone(i * 0.25, 0.3, note_freq(n), flute, 0.25, release=0.15, vibrato=0.012)
    return t


def click():
    """Menu move."""
    t = Track(0.06)
    t.add_tone(0, 0.025, 1400, pulse(0.5), 0.1, release=0.01)
    return t


def confirm():
    """Menu choice."""
    t = Track(0.16)
    t.add_tone(0, 0.04, note_freq("E6"), triangle, 0.18, release=0.02)
    t.add_tone(0.05, 0.07, note_freq("A6"), triangle, 0.18, release=0.04)
    return t


EFFECTS = {
    "jump.ogg": jump, "land.ogg": land, "shoot.ogg": shoot, "arrow_hit.ogg": arrow_hit,
    "coin.ogg": coin, "idol.ogg": idol, "shell.ogg": shell, "heart.ogg": heart,
    "checkpoint.ogg": checkpoint, "gate_open.ogg": gate_open, "hurt.ogg": hurt, "die.ogg": die,
    "stomp.ogg": stomp, "enemy_die.ogg": enemy_die, "boss_roar.ogg": boss_roar,
    "boss_slam.ogg": boss_slam, "boss_throw.ogg": boss_throw, "boss_defeat.ogg": boss_defeat,
    "clear.ogg": clear, "game_over.ogg": game_over, "click.ogg": click, "confirm.ogg": confirm,
}
