"""Scoundrel's placeholder music, the two end-of-run cues and the torch's crackle.

Composed without being heard - Claude cannot listen - so each piece says in its
docstring what it is meant to be, and listening round 3 judges it. The music is
the part most likely to be replaced (docs/audio.md, Sourcing); this is the
placeholder that lets the whole game be wired and timed first.

D minor, 64 BPM, 16-bar loops of exactly 60 s. Two bars a chord:
i - VI - iv - V, i - VI - VII - V, with the harmonic minor's A major for the
pull home.

Loops are seamless by construction, never by trimming:
- anything that rings past the loop's end (a pluck, the reverb) is folded back
  onto its start, where it will be heard when the loop comes round;
- anything sustained (the drone, the breathing) completes a whole number of
  cycles in a loop, so it meets itself exactly;
- filters on a finished loop work on it as a circle (synth.circular_filter).

The stream names mirror com.tomer.scoundrel.audio.StreamFile; AudioAssetsTest holds
the folder to that enum and check.py holds it to this list.
"""

import zlib

import numpy as np

import synth as s

TEMPO = 64
BEAT = 60 / TEMPO          # 0.9375 s
BAR = 4 * BEAT             # 3.75 s
BARS = 16
LOOP_SECONDS = BARS * BAR  # 60 s
TAIL_SECONDS = 8.0         # what rings past a loop's end, to be folded back onto its start


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def looped_hz(freq, seconds):
    """The nearest frequency that completes a whole number of cycles in `seconds`."""
    return round(freq * seconds) / seconds


def fold(x, length):
    """A loop of `length` samples from a longer render: whatever rang past the end
    is added back onto the start, where the loop will be when it comes round."""
    out = x[:length].copy()
    rest = x[length:]
    while len(rest):
        chunk = rest[:length]
        out[:len(chunk)] += chunk
        rest = rest[length:]
    return out


# --- the material ------------------------------------------------------------

D2, A2, D3 = 38, 45, 50
# Two bars each: Dm, Bb, Gm, A, Dm, Bb, C, A. The pulse sounds each chord's root.
CHORD_ROOTS = (38, 46, 43, 45, 38, 46, 48, 45)

# The theme: (bar, beat, midi, velocity). Two eight-bar phrases, the second answering
# the first. Sparse - two notes a bar at most - so it broods rather than tells.
MELODY = (
    (0, 0, 74, 0.9), (0, 2, 69, 0.7),                    # D5, A4           | Dm
    (1, 0, 65, 0.8), (1, 2.5, 64, 0.6),                  # F4, E4
    (2, 0, 62, 0.8), (2, 1, 65, 0.6), (2, 2, 70, 0.8),   # D4, F4, Bb4      | Bb
    (3, 0, 69, 0.7),                                     # A4
    (4, 0, 67, 0.8), (4, 1.5, 70, 0.6), (4, 3, 74, 0.8), # G4, Bb4, D5      | Gm
    (5, 0.5, 72, 0.7), (5, 2, 70, 0.6),                  # C5, Bb4
    (6, 0, 69, 0.8), (6, 2, 73, 0.9),                    # A4, C#5          | A
    (7, 0, 76, 0.7),                                     # E5, left hanging
    (8, 0, 74, 0.9), (8, 2, 69, 0.7),                    # D5, A4           | Dm
    (9, 0, 65, 0.8), (9, 1.5, 67, 0.6), (9, 3, 69, 0.7), # F4, G4, A4
    (10, 0, 70, 0.8), (10, 1.5, 69, 0.6), (10, 3, 65, 0.6),  # Bb4, A4, F4  | Bb
    (11, 0.5, 62, 0.7),                                  # D4
    (12, 0, 64, 0.8), (12, 1, 67, 0.6), (12, 2, 72, 0.8),    # E4, G4, C5   | C
    (13, 0.5, 70, 0.7), (13, 2.5, 69, 0.6),              # Bb4, A4
    (14, 0, 73, 0.9), (14, 2, 64, 0.6),                  # C#5, E4          | A
    (15, 0, 69, 0.7),                                    # A4 - and round to D5
)


def pluck_note(rng, midi, velocity, seconds=3.5):
    """One plucked note: a soft-attacked string that rings down to -40 dB inside its
    `seconds` and is faded over its last fifth, placed a little left or right by pitch
    so the line has some width.

    The ring is set per note, not per register: a string loses a little every period,
    so a fixed damping left low notes still loud when the note was cut off - a click
    mid-phrase, and a death cue whose last low D was still ringing at the end of the
    file (check.py caught it as a tail that was not silent)."""
    n = s.samples(seconds)
    freq = hz(midi)
    damping = 10 ** (-2 / (freq * seconds * 0.8))       # -40 dB at 80% of the note
    tone = s.pluck(n, freq, rng, damping=damping, brightness=0.35, excitation_cutoff=2500)
    envelope = np.clip(s.times(n) / 0.004, 0, 1)
    release = s.samples(seconds * 0.2)
    envelope[-release:] *= 0.5 * (1 + np.cos(np.linspace(0, np.pi, release)))
    return s.pan(tone * velocity * envelope, max(-0.35, min(0.35, (midi - 69) / 20)))


def notes(rng, n, events, start_beat_filter=None, velocity_scale=1.0):
    """The theme laid into a stereo buffer of n samples."""
    out = np.zeros((n, 2))
    for bar, beat, midi, velocity in events:
        if start_beat_filter and beat not in start_beat_filter:
            continue
        at = s.samples(bar * BAR + beat * BEAT)
        note = pluck_note(rng, midi, velocity * velocity_scale)
        end = min(n, at + len(note))
        out[at:end] += note[:end - at]
    return out


def drone(n, seconds, breath_depth=0.2):
    """Low D and A, held: two slightly detuned voices a note, one each side, darkened
    to a warm hum, breathing slowly (four breaths a loop). Every frequency completes a
    whole number of cycles in the loop, so it meets itself at the seam."""
    out = np.zeros((n, 2))
    t = s.times(n)
    for midi, level in ((D2, 1.0), (A2, 0.6), (D3, 0.25)):
        for side, detune, phase in ((0, -0.1, 0.0), (1, 0.1, 1.3)):
            freq = looped_hz(hz(midi) + detune, seconds)
            harmonics = [1 / k / np.sqrt(1 + (freq * k / 500) ** 4) for k in range(1, 21)]
            voice = s.harmonic_tone(n, freq, harmonics, phase)
            breath = 1 + breath_depth * np.sin(2 * np.pi * t * 4 / seconds + phase + midi)
            out[:, side] += level * voice * breath
    return out * 0.25


def heartbeat(rng, n):
    """The run's pulse: a soft double thump each bar on the chord's root, like a slow
    heart - a low sine with a knock at twice and three times it, so small speakers carry
    it (the thud's lesson from round 1)."""
    out = np.zeros(n)
    for bar in range(BARS):
        root = hz(CHORD_ROOTS[bar // 2])
        for offset, strength in ((0.0, 1.0), (0.3, 0.6)):
            m = s.samples(0.9)
            body = s.sweep_sine(m, root * 1.6, root, 0.03) * s.attack_decay(m, 0.004, 0.5)
            knock = s.modal(m, [(root * 2, 0.35, 0.25), (root * 3, 0.15, 0.15)], attack=0.004)
            at = s.samples(bar * BAR + offset)
            end = min(n, at + m)
            out[at:end] += strength * (body + knock)[:end - at]
    return s.pan(out * 0.6, 0.0)


# --- the pieces ---------------------------------------------------------------

def run_track(rng):
    """Under a run: slow and brooding. The drone, the theme plucked sparsely over it,
    and the heartbeat underneath. Loops every 60 s."""
    loop, long = s.samples(LOOP_SECONDS), s.samples(LOOP_SECONDS + TAIL_SECONDS)
    events = notes(rng, long, MELODY) + heartbeat(rng, long)
    events = events + 0.35 * s.reverb(events, seconds=2.6)
    return fold(events, loop) + drone(loop, LOOP_SECONDS)


def menu_track(rng):
    """The menus: the same theme, stripped back - the drone, and only the melody's
    notes on the strong beats, softer. No heartbeat. Loops every 60 s."""
    loop, long = s.samples(LOOP_SECONDS), s.samples(LOOP_SECONDS + TAIL_SECONDS)
    events = notes(rng, long, MELODY, start_beat_filter={0, 2}, velocity_scale=0.8)
    events = events + 0.4 * s.reverb(events, seconds=2.8)
    return fold(events, loop) + drone(loop, LOOP_SECONDS, breath_depth=0.15)


def win_cue(rng):
    """A run won: the theme's first two notes (A to D), and then the minor theme
    resolving onto D major - a rising arpeggio over a warm D-major chord, the
    Picardy third. Brief; not a fanfare."""
    n = s.samples(5.5)
    out = np.zeros((n, 2))
    for at, midi, velocity in ((0.0, 69, 0.9), (0.45, 74, 1.0)):
        note = pluck_note(rng, midi, velocity, seconds=3.0)
        out[s.samples(at):s.samples(at) + len(note)] += note[:n - s.samples(at)]
    for i, midi in enumerate((62, 66, 69, 74, 78)):          # D4 F#4 A4 D5 F#5
        at = s.samples(0.95 + i * 0.09)
        note = pluck_note(rng, midi, 0.8 - 0.05 * i, seconds=4.0)
        end = min(n, at + len(note))
        out[at:end] += note[:end - at]
    pad = np.zeros(n)
    for midi in (50, 54, 57):                               # D3 F#3 A3
        pad += s.harmonic_tone(n, hz(midi), [1, 0.3, 0.1])
    swell = np.clip((s.times(n) - 0.95) / 0.4, 0, 1) * np.exp(-np.maximum(s.times(n) - 1.35, 0) * s.LN_1000 / 4.0)
    out += s.pan(0.12 * pad * swell, 0.0)
    return out + 0.35 * s.reverb(out, seconds=2.6)


def death_cue(rng):
    """A run lost: a low toll, then a line sinking to the bottom of the range while
    the drone slides down a semitone and goes out. 7.5 s, so the last low D and the
    reverb behind it have gone quiet before the file ends."""
    n = s.samples(7.5)
    out = np.zeros((n, 2))
    toll = s.pan(0.6 * s.sweep_sine(n, hz(D2) * 1.5, hz(D2), 0.05) * s.attack_decay(n, 0.004, 2.5), 0.0)
    out += toll
    for at, midi, velocity in ((0.0, 50, 1.0), (0.6, 57, 0.8), (1.2, 53, 0.75),
                               (1.9, 50, 0.65), (2.6, 49, 0.55), (3.3, 38, 0.6)):
        note = pluck_note(rng, midi, velocity, seconds=3.0)
        start = s.samples(at)
        end = min(n, start + len(note))
        out[start:end] += note[:end - start]
    t = s.times(n)
    sinking = np.zeros(n)
    for midi, level in ((D2, 1.0), (A2, 0.5)):
        freq = hz(midi) * 2 ** (-np.clip(t / 4.0, 0, 1) / 12)   # down a semitone over 4 s
        phase = 2 * np.pi * np.cumsum(freq) / s.SR
        sinking += level * (np.sin(phase) + 0.3 * np.sin(2 * phase) + 0.1 * np.sin(3 * phase))
    fade = np.clip(t / 0.3, 0, 1) * np.clip(1 - (t - 0.5) / 4.0, 0, 1)
    out += s.pan(0.15 * sinking * fade, 0.0)
    return out + 0.4 * s.reverb(out, seconds=3.0)


TORCH_SECONDS = 20.0
CRACKLES_PER_SECOND = 5.0
"""Bursts a second while the flame burns at its resting brightness; more in a flare."""
POPS_PER_SECOND = 0.35
FLAME_LEVEL = 0.017
"""The flame's murmur against the crackle: the crackle carries about 86% of the torch's
loudness as heard, 8 dB over the murmur (round 3)."""


def flicker(t):
    """The flame's slow breathing, about 0.7 to 1.3: three sines that each complete whole
    cycles in the loop, so the torch meets itself at the seam."""
    return 1 + 0.3 * (np.sin(2 * np.pi * t * 3 / TORCH_SECONDS)
                      + 0.6 * np.sin(2 * np.pi * t * 7 / TORCH_SECONDS + 1.1)
                      + 0.4 * np.sin(2 * np.pi * t * 11 / TORCH_SECONDS + 2.3)) / 2


def snap(rng):
    """One snap of burning wood: a tick of bright noise, gone in one to four
    milliseconds, its colour a little different every time."""
    m = s.samples(0.008)
    tick = s.bandpass(s.noise(m, rng), rng.uniform(1800, 5500), q=rng.uniform(0.7, 1.5))
    return tick * s.attack_decay(m, 0.0001, rng.uniform(0.001, 0.004))


def crackle(rng):
    """A crackle the way wood makes one: a burst of one to eight snaps a few
    milliseconds apart (three on average), each its own level, fading through the burst.
    The levels vary widely but are capped: uncapped, one burst in a hundred stood 7 dB
    over the rest and set the torch's loudest moment."""
    count = min(8, int(rng.geometric(0.35)))
    starts = np.concatenate([[0.0], np.cumsum(np.maximum(rng.exponential(0.007, count - 1), 0.0015))])
    n = s.samples(starts[-1] + 0.01)
    out = np.zeros(n)
    for i, at in enumerate(starts):
        out += s.place(n, snap(rng) * np.clip(rng.lognormal(0, 0.5), 0.5, 1.8) * 0.85 ** i, s.samples(at))
    return out * np.clip(rng.lognormal(0, 0.6), 0.35, 2.2)


def pop(rng):
    """Now and then a knot of sap bursting: a crack with a little weight under it, and
    a spray of snaps after it."""
    m = s.samples(0.2)
    thump = s.sweep_sine(m, 180, 80, 0.02) * s.attack_decay(m, 0.001, 0.08)
    crack = s.bandpass(s.noise(m, rng), 3000, q=0.8) * s.attack_decay(m, 0.0003, 0.01)
    return 0.6 * thump + crack + s.place(m, crackle(rng), s.samples(0.02))


def torch_loop(rng):
    """The torch, on every screen: a wood fire's crackle - bursts of sharp little snaps,
    thicker when the flame flares, now and then a pop with a little weight - over the
    low, soft murmur of the flame. Mono; loops every 20 s.

    Round 3: "too much white noise and not enough crackle". The first render's bed was
    noise from 150 Hz to 2.5 kHz on one-pole slopes, so it reached well past 5 kHz, and it
    carried 96% of the torch's loudness: only 1% of 10 ms windows had a crackle standing
    above it. Now the flame is a murmur under 350 Hz, well under the crackle, and the
    crackle comes in bursts, as burning wood gives it, rather than as single ticks."""
    loop, long = s.samples(TORCH_SECONDS), s.samples(TORCH_SECONDS + 0.5)
    breath = flicker(s.times(loop))
    murmur = s.circular_filter(rng.standard_normal(loop),
                               lambda f: s.highpass_response(60, 2)(f) * s.lowpass_response(350, 2)(f))
    flame = FLAME_LEVEL * murmur / np.std(murmur) * breath

    # Crackles come in flurries as the flame breathes: a Poisson stream thinned by the
    # flicker to the fourth power, so a flare (about 13 a second) is ten times as busy as a
    # lull, and the loop averages about 5.5.
    events = np.zeros(long)
    busiest = 1.3 ** 4
    at = rng.exponential(1 / (CRACKLES_PER_SECOND * busiest))
    while at < TORCH_SECONDS:
        if rng.uniform() < flicker(at) ** 4 / busiest:
            events += s.place(long, crackle(rng), s.samples(at))
        at += rng.exponential(1 / (CRACKLES_PER_SECOND * busiest))
    at = rng.exponential(1 / POPS_PER_SECOND)
    while at < TORCH_SECONDS:
        events += s.place(long, pop(rng), s.samples(at))
        at += rng.exponential(1 / POPS_PER_SECOND)
    return flame + fold(events, loop)


# --- the catalogue -----------------------------------------------------------

STREAMS = {
    # name (under assets/audio/): (build, integrated loudness target in dB as heard, loops, channels)
    "music/menu": (menu_track, -28.0, True, 2),
    "music/run": (run_track, -26.0, True, 2),
    "music/win": (win_cue, -24.0, False, 2),
    "music/death": (death_cue, -25.0, False, 2),
    "ambience/torch": (torch_loop, -41.0, True, 1),
}
"""Loudness targets sit below the sound effects', whose loudest moments are about -12 to
-25 dB; the torch well under everything.

Round 3: "the sound effects should be up a notch, I barely hear them with the music".
The effects could not come up - the loudest blade already peaks at -1.04 dBFS, against
the -1 dBFS ceiling - so the music came down a notch (6 dB, one MUSIC step) instead, all four
pieces together so the menu, run and cues keep the balance they were heard at. The
torch is set by its loudest moment, not its average: a crackle is mostly silence, so
-41 integrated puts its loudest pop at about -27 over 50 ms, as loud as the old hissing
torch ever got and just under the quietest effect (the flip, -25)."""

PRE_ENCODE_CEILING_DB = -2.0
"""Vorbis overshoots: -2 dBFS going in keeps the decoded peak under the -1 ceiling."""


def crush(x, looped):
    """The lo-fi stage for music, milder than the effects': hold to 22.05 kHz (every
    other sample, so a loop's even length keeps it periodic), 12 bits, and a warm
    low-pass - circular for a loop."""
    n = x.shape[0]
    held = x[(np.arange(n) // 2) * 2]
    crushed = np.round(held * 2048) / 2048
    response = s.lowpass_response(9000, order=2)
    return s.circular_filter(crushed, response) if looped else s.fft_filter(crushed, response)


def finish(x, target_db, looped):
    """A raw piece to a shippable one: DC out, levelled to its target as heard, through
    the lo-fi stage at that level, levelled again, soft-limited under the pre-encode
    ceiling (memorylessly, so a loop stays a loop), and a one-shot's tail faded out."""
    x = x - x.mean(axis=0)
    x = x * 10 ** ((target_db - s.loudness_integrated_db(x, looped)) / 20)
    x = crush(x, looped)
    ceiling = 10 ** (PRE_ENCODE_CEILING_DB / 20)
    for _ in range(8):
        x = x * 10 ** ((target_db - s.loudness_integrated_db(x, looped)) / 20)
        if np.max(np.abs(x)) <= ceiling:
            break
        knee = ceiling * 0.7
        over = np.abs(x) > knee
        x[over] = np.sign(x[over]) * (knee + (ceiling - knee) * np.tanh((np.abs(x[over]) - knee) / (ceiling - knee)))
    if not looped:
        fade = s.samples(0.05)
        x[-fade:] *= (0.5 * (1 + np.cos(np.linspace(0, np.pi, fade))))[:, None]
    peak = np.max(np.abs(x))
    if peak > ceiling:
        x = x * (ceiling / peak)
    return x


def render(name):
    """The finished float signal for one stream: (samples,) for mono, (samples, 2) for
    stereo. Seeded by its name, so it never changes unless its recipe does."""
    build, target_db, looped, channels = STREAMS[name]
    rng = np.random.default_rng(zlib.crc32(name.encode("utf-8")))
    x = build(rng)
    x = finish(x if x.ndim == 2 else x[:, None], target_db, looped)
    return x[:, 0] if channels == 1 else x
