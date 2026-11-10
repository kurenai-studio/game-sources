"""Turn a lead sheet (melody + chord symbols) into a small acoustic band "a la
Brassens", played by sampled instruments and mixed like a little room.

- The band, as Brassens's (no drums: the guitar and the double bass make
  the rhythm): a classical guitar (accompaniment: the "pompe", a waltz
  "pom-tchi-tchi", or fingerpicking), a pizzicato double bass, and on the
  tune a piano, a button accordion, a flute or a clarinet. Each comes from
  a free sample library (see README.md), found under $TRAMPOLINE_SAMPLES.
- The playing: notes are written as a score, then performed as people
  would, not as a sequencer:
  - the tempo breathes: it drifts slowly and eases off at phrase ends;
  - each player has their own feel: the bass pushes a hair ahead of the
    beat, the tune sits back, and each one's timing wanders slowly
    rather than jittering note by note;
  - velocities follow the beat, the line's rise and fall, and the 8-bar
    phrase (growing, then settling);
  - the accompaniment never plays the same bar twice in a row exactly:
    upstrokes, approach notes and fingerpicking patterns vary, and the
    band breathes at the end of each phrase;
  - winds play legato, breathe at the rests and swell on long notes (MIDI
    CC11); the clarinet and the flute slide up into notes after a leap,
    the clarinet's long notes get vibrato (pitch bends);
  - guitar chords are strummed string by string, faster when loud, and the
    pompe's chops are damped by the hand; the piano pedals each chord.
- The sound: each instrument ("stem") is written to its own MIDI file and
  rendered by sfizz, then the stems are panned, filtered, sent to a shared
  reverb (a real small concert hall's recorded impulse response) and mixed.

Run from `nix develop .#audio` (needs $TRAMPOLINE_SAMPLES, sfizz_render,
sox, ffmpeg).
"""

import os
import random
import subprocess
import tempfile
from dataclasses import dataclass

import mido
import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, oaconvolve, resample_poly, sosfilt

SAMPLE_RATE = 44100
TICKS_PER_BEAT = 960

# The stems, numbered: a Note's `channel` says which one plays it.
GUITAR, RHYTHM, BASS, CLARINET, ACCORDION, PIANO, FLUTE = range(7)


@dataclass(frozen=True)
class Stem:
    sfz: str  # the instrument, relative to $TRAMPOLINE_SAMPLES
    keys: range  # the instrument's range, for level calibration
    pan: float  # -1 (left) .. 1 (right)
    gain_db: float
    reverb: float  # how much goes to the reverb, 0..1
    highpass: float  # Hz: removes rumble below the instrument
    lowpass: float = 20000.0  # Hz: softens a close microphone's highs
    width: float = 1.0  # stereo width: 0 folds a stereo recording to mono


# The classical guitar cut from the Iowa recordings (see slice_guitar.py):
# 3 dynamics, a note's strings taken in turn. Recorded in a dead room, so
# it gets a little more reverb than the others.
_GUITAR_SFZ = "guitar/guitar.sfz"
STEMS = {
    GUITAR: Stem(_GUITAR_SFZ, range(40, 84), 0.12, 2.0, 0.40, 70, 7500),
    RHYTHM: Stem(_GUITAR_SFZ, range(40, 84), -0.38, 7.0, 0.30, 100, 6500),
    # Karoryfer's Meatbass, pizzicato.
    BASS: Stem("bass/Programs/pizz_basic.sfz", range(28, 56), 0.0, 0.0, 0.12, 32),
    CLARINET: Stem("vsco/ClarinetSus.sfz", range(50, 92), 0.30, -3.0, 0.36, 130),
    ACCORDION: Stem("accordion/PRESET Button Accordion HN tuned.sfz", range(55, 92), 0.22, -11.0, 0.32, 160),
    # Salamander Grand Piano (a Yamaha C5, 16 velocity layers).
    PIANO: Stem("piano/SalamanderGrandPiano-V3+20200602.sfz", range(36, 97), 0.18, 2.0, 0.30, 50, width=0.7),
    FLUTE: Stem("vsco/FluteSusVib.sfz", range(60, 97), 0.25, 6.0, 0.38, 200),
}
# Winds hold their notes and get CC11 swells; plucked and struck ones don't.
_WINDS = (CLARINET, ACCORDION, FLUTE)
# Where each player sits against the beat, in ms: the bass pushes, the
# guitar is the beat, the tune (every other stem) lays back.
_FEEL_MS = {BASS: -7.0, RHYTHM: 0.0}
_LEAD_FEEL_MS = 14.0
# Every tune's balance, the same everywhere: how loud each part is while it
# plays (dB, before the master brings the whole mix to its loudness). The
# bass measures loudest but sounds no louder than the guitar: its energy is
# mostly in its low fundamentals, which the ear hears less.
_BALANCE_DB = {"comp": -36.0, "bass": -31.0, "lead": -42.5, "counter": -45.0}
_PHRASE_BARS = 8

_PITCH_CLASSES = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}

# Chord qualities -> intervals above the root, in semitones.
_QUALITIES = {
    "": (0, 4, 7),
    "m": (0, 3, 7),
    "7": (0, 4, 7, 10),
    "m7": (0, 3, 7, 10),
    "maj7": (0, 4, 7, 11),
    "6": (0, 4, 7, 9),
    "m6": (0, 3, 7, 9),
    "dim7": (0, 3, 6, 9),
    "m7b5": (0, 3, 6, 10),
    "9": (0, 4, 7, 10, 14),
    "sus4": (0, 5, 7),
}


def _pitch_class(name):
    """'C' -> 0, 'F#' -> 6, 'Bb' -> 10."""
    pc = _PITCH_CLASSES[name[0]]
    for accidental in name[1:]:
        pc += {"#": 1, "b": -1}[accidental]
    return pc % 12


def note_number(name):
    """'C5' -> 72 (MIDI), sharps '#' and flats 'b' allowed: 'F#4', 'Bb4'."""
    return 12 * (int(name[-1]) + 1) + _PITCH_CLASSES[name[0]] + sum(
        {"#": 1, "b": -1}[a] for a in name[1:-1]
    )


def parse_chord(symbol):
    """'A7' -> (9, (0, 4, 7, 10), 9); 'G/B' -> (7, (0, 4, 7), 11): root,
    intervals, and the bass note's pitch class (the root unless slashed)."""
    symbol, _, bass = symbol.partition("/")
    root_len = 2 if len(symbol) > 1 and symbol[1] in "#b" else 1
    root = _pitch_class(symbol[:root_len])
    return root, _QUALITIES[symbol[root_len:]], _pitch_class(bass) if bass else root


def parse_bars(text):
    """Split a '|'-separated string into one list of tokens per bar."""
    return [bar.split() for bar in text.split("|")]


def parse_melody(text):
    """'C5:1 r:.5 D5:.5 | E5:2 D5:2' -> per-bar lists of (midi or None, beats)."""
    bars = []
    for tokens in parse_bars(text):
        notes = []
        for token in tokens:
            name, beats = token.split(":")
            notes.append((None if name == "r" else note_number(name), float(beats)))
        bars.append(notes)
    return bars


@dataclass
class Pass:
    """One time through the tune: its melody, who plays what, and how."""

    melody: str
    lead: int = GUITAR  # the stem playing the melody
    comp: str = "pompe"  # "pompe", "waltz", "picking", "none"
    bass: str = "two"  # "two", "walk", "waltz", "none"
    lead_velocity: int = 84
    counter: str = ""  # an optional second voice, same format as the melody
    counter_lead: int = CLARINET
    counter_velocity: int = 62
    comp_velocity: int = 0  # added to the accompaniment's velocities


@dataclass
class Tune:
    name: str
    tempo: float  # beats per minute
    meter: int  # beats per bar: 4 or 3
    chords: str  # one '|'-separated bar per melody bar, chords split the bar evenly
    passes: list
    transpose: int = 0
    swing: float = 0.6  # where the off-beat eighth lands (0.5 = straight)
    seed: int = 1


@dataclass
class Note:
    beat: float
    length: float
    pitch: int
    velocity: int
    channel: int  # the stem: GUITAR, RHYTHM, BASS, PIANO...
    delay_ms: float = 0.0  # added after swing: strum roll, the player's feel
    swell: bool = False  # winds: crescendo-decrescendo over the note
    damped: bool = False  # guitar: the hand stops the strings at once on release
    scoop: bool = False  # clarinet, flute: slides up into the note
    vibrato: bool = False  # clarinet: a vibrato that grows on a long note
    pedal: bool = False  # piano: not a note, the sustain pedal held over it


def _swing(beat, ratio):
    """Push off-beat eighths late: maps [0, .5] -> [0, ratio], [.5, 1] -> [ratio, 1]."""
    whole = int(beat // 1)
    frac = beat - whole
    if frac <= 0.5:
        return whole + frac / 0.5 * ratio
    return whole + ratio + (frac - 0.5) / 0.5 * (1 - ratio)


def _frange(start, stop, step):
    beat = start
    while beat < stop - 1e-6:
        yield beat
        beat += step


# --- The score: chords, accompaniment, bass, melody ---------------------------


def _voicing(root, intervals, low=52, high=67):
    """Guitar chord shape: each chord tone in its octave nearest the middle
    of the neck (ninths fold down to seconds, as a guitarist would)."""
    centre = (low + high) / 2
    pitches = set()
    for interval in intervals:
        pc = (root + interval) % 12
        pitches.add(min((p for p in range(low, high + 1) if p % 12 == pc), key=lambda p: abs(p - centre)))
    return sorted(pitches)


def _low(pc, low=31):
    """A pitch class in the double bass's sweet spot, G1..F#2."""
    return low + (pc - low) % 12


def _chord_segments(tune):
    """[(start_beat, length, root_pc, intervals, bass_pc)] for one pass."""
    segments = []
    for bar_index, symbols in enumerate(parse_bars(tune.chords)):
        length = tune.meter / len(symbols)
        for i, symbol in enumerate(symbols):
            root, intervals, bass = parse_chord(symbol)
            t = tune.transpose
            segments.append((bar_index * tune.meter + i * length, length, (root + t) % 12, intervals, (bass + t) % 12))
    return segments


def _strum(beat, chord, length, velocity, rng, up=False, damped=False):
    """One strum, string by string (low to high, or high to low going up).
    A harder strum is a faster one: from about 16 ms between strings when
    soft to 7 ms when loud. `damped`: the hand stops it short (a chop)."""
    order = list(reversed(chord)) if up else chord
    spread = np.clip(16 - (velocity - 40) / 4, 7, 16)
    return [
        Note(beat, length * rng.uniform(0.85, 1.15), p, velocity - 3 * i + rng.randint(-4, 4), RHYTHM,
             i * spread * rng.uniform(0.75, 1.25), damped=damped)
        for i, p in enumerate(order)
    ]


def _phrase_end(beat, meter, total):
    """Is `beat` in the last bar of an 8-bar phrase (where the band
    breathes)? Not the tune's very last bar: there the band plays on into
    the first bar, where the loop starts again."""
    bar = int(beat // meter)
    return bar % _PHRASE_BARS == _PHRASE_BARS - 1 and bar != total // meter - 1


def _comp(segments, meter, total, style, boost, rng):
    """The rhythm guitar. Its pattern is the style's, but varied as a
    guitarist would: upstrokes come and go, chops are more or less short,
    and the last bar of a phrase is a breath (a chord left ringing)."""
    notes = []
    for start, length, root, intervals, bass in segments:
        chord = _voicing(root, intervals)
        thumb = [_low(bass, 40), _low((root + 7) % 12, 40)]  # E2..D#3: the guitar's bass strings
        for beat in _frange(start, start + length, 1):
            in_bar = round(beat % meter)
            breath = _phrase_end(beat, meter, total)
            if style == "pompe":
                if breath:
                    # A ringing strum on 1, a light chop on 4, nothing between.
                    if in_bar == 0:
                        notes += _strum(beat, chord, 2.6, 58 + boost, rng)
                    elif in_bar == 3:
                        notes += _strum(beat, chord[-3:], 0.2, 50 + boost, rng, damped=True)
                    continue
                # Soft ringing strum on 1 and 3, short accented "chop" on 2 and 4.
                accent = in_bar % 2 == 1
                notes += _strum(beat, chord if not accent else chord[-4:],
                                rng.uniform(0.14, 0.26) if accent else 0.55, (64 if accent else 46) + boost, rng,
                                damped=accent)
                # Swung upstrokes on the off-beats now and then: the bounce.
                if rng.random() < (0.45 if in_bar == 3 else 0.12):
                    notes += _strum(beat + 0.5, chord[-3:], 0.15, 34 + boost + rng.randint(-4, 4), rng, up=True,
                                    damped=True)
            elif style == "waltz":
                # Bass alone on 1 (the double bass), chords on 2 and 3; at
                # times a lighter "tchi-tchi" pair of eighths on 3.
                if breath and in_bar:
                    if in_bar == 1:
                        notes += _strum(beat, chord, 1.8, 50 + boost, rng)
                elif in_bar == 1:
                    notes += _strum(beat, chord, rng.uniform(0.25, 0.4), 56 + boost, rng, damped=True)
                elif in_bar == 2:
                    notes += _strum(beat, chord[-3:], 0.3, 46 + boost, rng, damped=True)
                    if rng.random() < 0.2:
                        notes += _strum(beat + 0.5, chord[-3:], 0.2, 38 + boost, rng, up=True, damped=True)
            elif style == "picking":
                # Thumb on every beat, alternating bass strings; a finger on
                # most "ands", picking among the top voices; a pinch (thumb
                # + top voice together) at the start of the chord.
                t = thumb[0] if in_bar % 2 == 0 else thumb[1]
                notes.append(Note(beat, 1.9, t, 58 + boost + rng.randint(-4, 4), RHYTHM, rng.uniform(0, 6)))
                if beat == start or (in_bar == 2 and rng.random() < 0.3):
                    notes.append(Note(beat, 1.6, chord[-1], 52 + boost + rng.randint(-4, 4), RHYTHM, rng.uniform(4, 10)))
                if breath and in_bar >= 2:
                    continue  # the end of a phrase: let it ring
                if rng.random() < 0.88:
                    finger = rng.choice(chord[-3:] if in_bar % 2 else chord[-2:])
                    notes.append(Note(beat + 0.5, 1.4, finger, 46 + boost + rng.randint(-5, 5), RHYTHM, rng.uniform(0, 8)))
    return notes


def _bass(segments, meter, total, style, rng):
    """The double bass: the style's pattern, with approach notes into the
    next chord now and then, and a long note at the end of each phrase."""
    notes = []
    for index, (start, length, root, intervals, bass) in enumerate(segments):
        nxt = _low(segments[(index + 1) % len(segments)][4])
        low = _low(bass)
        fifth = _low((root + 7) % 12)
        fifth = fifth if fifth != low else low + 7
        third = _low((root + intervals[1]) % 12)
        # A step into the next chord's bass note: from a semitone below or above.
        approach = nxt + (1 if rng.random() < 0.5 else -1)
        vel = lambda v: v + rng.randint(-6, 6)  # noqa: E731
        if _phrase_end(start, meter, total) and start % meter == 0:
            notes.append(Note(start, meter - 0.8, low, vel(88), BASS))
            continue
        if style == "waltz":
            # Beat 1; a long chord alternates root and fifth bar by bar;
            # sometimes a pickup on 3 into the next bar.
            for beat in _frange(start, start + length, meter):
                pitch = fifth if (beat // meter) % 2 and beat != start else low
                last = beat + meter >= start + length
                if last and nxt != pitch and rng.random() < 0.25:
                    notes.append(Note(beat, 1.3, pitch, vel(90), BASS))
                    notes.append(Note(beat + 2, 0.8, approach, vel(72), BASS))
                else:
                    notes.append(Note(beat, rng.uniform(1.1, 1.5), pitch, vel(90), BASS))
        elif style == "two":
            beats = list(_frange(start, start + length, 2))
            for k, beat in enumerate(beats):
                pitch, v = (low, 90) if k % 2 == 0 else (fifth, 80)
                if k == len(beats) - 1 and nxt != low and rng.random() < 0.3:
                    # Half note shortened to a quarter, then the approach.
                    notes.append(Note(beat, 0.9, pitch, vel(v), BASS))
                    notes.append(Note(beat + 1, 0.9, approach, vel(74), BASS))
                else:
                    notes.append(Note(beat, rng.uniform(1.4, 1.8), pitch, vel(v), BASS))
        elif style == "walk":
            # The root, chord tones in some order, then a step into the next bass note.
            beats = list(_frange(start, start + length, 1))
            middle = [third, fifth] + ([low + 12] if low + 12 <= 55 else [])
            rng.shuffle(middle)
            line = ([low] + middle + middle)[: len(beats) - 1] + [approach] if len(beats) > 1 else [low]
            for k, (beat, pitch) in enumerate(zip(beats, line)):
                notes.append(Note(beat, rng.uniform(0.85, 0.97), pitch, vel(88 if k == 0 else 78), BASS))
    return notes


def _chord_at(segments, beat):
    """The (root, intervals) of the chord sounding at `beat`."""
    for start, length, root, intervals, _ in segments:
        if start <= beat < start + length:
            return root, intervals
    return segments[-1][2], segments[-1][3]


def _harmony(pitch, root, intervals):
    """The chord tone a pianist would add under a melody note: the highest
    one at least a minor third below it."""
    tones = [p for p in range(pitch - 9, pitch - 2) if (p - root) % 12 in {i % 12 for i in intervals}]
    return tones[-1] if tones else None


def _perform_line(text, offset, tune, channel, velocity, rng, segments=()):
    """A melody as played: legato or let ring, breathing at the rests,
    velocity shaped by the beat and by the line's rise and fall. The
    clarinet and the flute often slide up into a note after a leap, and the
    clarinet sings its long notes with vibrato. On the piano (`segments`:
    the chords), notes of a beat or longer get a chord tone below, and the
    sustain pedal changes with each chord."""
    bars = parse_melody(text)
    flat = []  # (beat, pitch or None, beats)
    for bar_index, bar in enumerate(bars):
        total = sum(beats for _, beats in bar)
        assert abs(total - tune.meter) < 1e-6, f"{tune.name}: bar {bar_index + 1} has {total} beats"
        beat = offset + bar_index * tune.meter
        for pitch, beats in bar:
            flat.append((beat, pitch, beats))
            beat += beats
    pitches = [p for _, p, _ in flat if p is not None]
    centre = sum(pitches) / max(1, len(pitches))
    notes = []
    for i, (beat, pitch, beats) in enumerate(flat):
        if pitch is None:
            continue
        nxt = flat[(i + 1) % len(flat)]
        in_bar = (beat - offset) % tune.meter
        # Strong beats lean in, off-beats lighten, high notes sing out.
        accent = 6 if in_bar == 0 else 3 if in_bar == int(in_bar) else -4
        v = velocity + accent + 0.7 * (pitch - centre) + rng.randint(-4, 4)
        if channel in _WINDS:
            # Legato into the next note; a breath before a rest or a repeat.
            breath = nxt[1] is None or nxt[1] == pitch
            length = beats * 0.82 if breath else beats + 0.04
        elif channel == PIANO:
            # Held to the next note (legato), a little less before a rest.
            length = beats * (0.9 if nxt[1] is None else 1.02)
        else:
            # A plucked note rings on under the next one.
            length = beats + 0.6
        delay = rng.uniform(0, 6)
        previous = next((p for _, p, _ in reversed(flat[:i]) if p is not None), pitch)
        sings = channel in (CLARINET, FLUTE)
        notes.append(Note(beat, length, pitch + tune.transpose, round(v), channel, delay,
                          swell=channel in _WINDS and beats >= 1.5,
                          scoop=sings and abs(pitch - previous) >= 5 and rng.random() < 0.6,
                          vibrato=channel == CLARINET and beats >= 1.5))
        if channel == PIANO and segments and beats >= 1:
            below = _harmony(pitch + tune.transpose, *_chord_at(segments, beat))
            if below is not None:
                notes.append(Note(beat, length, below, round(v) - 14, channel, delay + 3))
    if channel == PIANO:
        notes += [Note(start, length, 0, 0, PIANO, pedal=True) for start, length, *_ in segments
                  if offset <= start < offset + len(bars) * tune.meter]
    return notes


def arrange(tune):
    """All the notes of every pass of the tune, and its length in beats."""
    rng = random.Random(tune.seed)
    segments = _chord_segments(tune)
    pass_beats = len(parse_bars(tune.chords)) * tune.meter
    total = pass_beats * len(tune.passes)
    notes = []
    for number, a_pass in enumerate(tune.passes):
        offset = number * pass_beats
        assert len(parse_bars(a_pass.melody)) == len(parse_bars(tune.chords)), f"{tune.name}: bar count"
        shifted = [(s + offset, *rest) for s, *rest in segments]
        notes += _perform_line(a_pass.melody, offset, tune, a_pass.lead, a_pass.lead_velocity, rng, shifted)
        if a_pass.counter:
            notes += _perform_line(a_pass.counter, offset, tune, a_pass.counter_lead, a_pass.counter_velocity, rng)
        notes += _comp(shifted, tune.meter, total, a_pass.comp, a_pass.comp_velocity, rng)
        notes += _bass(shifted, tune.meter, total, a_pass.bass, rng)
    _humanise(notes, tune.meter, rng)
    return notes, total


def _humanise(notes, meter, rng):
    """What makes a band sound like people, done to every note in place:
    - each player sits at their own place against the beat (_FEEL_MS), and
      their timing wanders slowly around it (two slow waves with random
      phases, about +-6 ms): a human's timing errors follow each other,
      unlike independent random jitter, which sounds like a machine;
    - the dynamics swell over each 8-bar phrase and settle at its end,
      the accompaniment less than the tune. Each phrase starts and ends
      at the same level, so the loop's end meets its start."""
    phrase = _PHRASE_BARS * meter
    phases = {channel: (rng.uniform(0, 2 * np.pi), rng.uniform(0, 2 * np.pi))
              for channel in sorted({n.channel for n in notes})}
    for note in notes:
        p = phases[note.channel]
        wander = (4 * np.sin(2 * np.pi * note.beat / (7 * meter) + p[0])
                  + 2.5 * np.sin(2 * np.pi * note.beat / (3 * meter) + p[1]))
        note.delay_ms += _FEEL_MS.get(note.channel, _LEAD_FEEL_MS) + wander + rng.gauss(0, 2.5)
        arc = 8 * np.sin(np.pi * (note.beat % phrase) / phrase) - 3
        if note.channel in (RHYTHM, BASS):
            arc *= 0.5
        note.velocity = int(np.clip(round(note.velocity + arc), 1, 127))


# --- The performance: MIDI files, one per stem --------------------------------


def _clock(tune, beats):
    """When each whole beat of the tune falls, in seconds (beats + 1 values).
    A band is not a metronome: its tempo drifts slowly (three slow waves,
    about +-1.5 % together), and it eases off into the last bar of each
    8-bar phrase, then picks up again. The waves fit a whole number of
    times in the tune and the last bar doesn't ease off, so the loop ends
    at the tempo it starts with."""
    rng = np.random.default_rng(tune.seed)
    beat = np.arange(beats)
    stretch = sum(0.006 * np.sin(2 * np.pi * waves * beat / beats + rng.uniform(0, 2 * np.pi))
                  for waves in (2, 3, 5))
    phrase = _PHRASE_BARS * tune.meter
    into_last_bar = (beat % phrase - (phrase - tune.meter)) / tune.meter  # 0..1 over the last bar
    eases = (into_last_bar >= 0) & (beat < beats - tune.meter)
    stretch = stretch + np.where(eases, 0.035 * (into_last_bar + 1 / tune.meter), 0)
    return np.concatenate([[0.0], np.cumsum(60 / tune.tempo * (1 + stretch))])


def _steady(tempo, beats):
    """A metronome's clock (for the sound effects and calibration)."""
    return np.arange(int(np.ceil(beats)) + 1) * 60 / tempo


def _seconds(times, beat):
    """When `beat` falls on the clock `times`; past its end the clock starts
    over (the loop's next time round)."""
    loop = len(times) - 1
    rounds, rest = divmod(beat, loop)
    return rounds * times[-1] + np.interp(rest, np.arange(loop + 1), times)


def _write_midi(notes, times, swing, path, repeats, end_seconds, levels):
    """Write one stem's notes, played `repeats` times in a row on the clock
    `times`. The file's tempo is 60 bpm, so its beats are seconds."""
    events = []  # (tick, order, message): note-offs and controllers before note-ons
    for repeat in range(repeats):
        base = repeat * (len(times) - 1)
        for note in notes:
            shift = note.delay_ms / 1000
            on = max(0, round((_seconds(times, base + _swing(note.beat, swing)) + shift) * TICKS_PER_BEAT))
            off = max(on + 1, round((_seconds(times, base + _swing(note.beat + note.length, swing)) + shift)
                                    * TICKS_PER_BEAT))
            if note.pedal:
                # Legato pedalling: the pedal comes up as the chord changes
                # and goes down again just after the new notes sound, so
                # they ring on without blurring into the previous chord.
                events.append((on + TICKS_PER_BEAT * 6 // 100, 1, mido.Message("control_change", control=64, value=127)))
                events.append((off, 0, mido.Message("control_change", control=64, value=0)))
                continue
            # Even out the samples' loudness: this key's correction, in velocity.
            velocity = note.velocity * 10 ** (levels.get(note.pitch, 0.0) / 40)
            velocity = max(1, min(127, round(velocity)))
            if note.channel in (GUITAR, RHYTHM):
                # Ringing or damped: MIDI controller 20 (see slice_guitar.py).
                events.append((on, 1, mido.Message("control_change", control=20, value=127 if note.damped else 0)))
            events.append((on, 2, mido.Message("note_on", note=note.pitch, velocity=velocity)))
            events.append((off, 0, mido.Message("note_off", note=note.pitch, velocity=0)))
            events += _bends(note, on, off)
            if note.channel in _WINDS:
                # Expression: start a bit under, bloom, ease off (a swell),
                # or simply sit at a steady level.
                curve = (88, 120, 100) if note.swell else (108, 108, 108)
                for k, value in enumerate(curve):
                    events.append((on + (off - on) * k // 3, 1, mido.Message("control_change", control=11, value=value)))
    track = mido.MidiTrack()
    track.append(mido.MetaMessage("set_tempo", tempo=mido.bpm2tempo(60), time=0))
    now = 0
    for tick, _, message in sorted(events, key=lambda e: (e[0], e[1])):
        track.append(message.copy(time=tick - now))
        now = tick
    # Every stem ends at the same tick, so the renders line up.
    track.append(mido.MetaMessage("end_of_track", time=max(0, round(end_seconds * TICKS_PER_BEAT) - now)))
    midi = mido.MidiFile(ticks_per_beat=TICKS_PER_BEAT)
    midi.tracks.append(track)
    midi.save(path)


def _bend(cents):
    """A pitch bend message, the instruments bending +-200 cents (the SFZ default)."""
    return mido.Message("pitchwheel", pitch=int(np.clip(round(cents / 200 * 8191), -8192, 8191)))


def _bends(note, on, off):
    """A note's pitch bends, as (tick, order, message) events: a scoop
    (from 45 cents flat, up to pitch in 90 ms), a vibrato (5.5 Hz, starting
    a third of the way in and growing to +-20 cents), or else nothing
    but a reset to true pitch."""
    if not (note.scoop or note.vibrato):
        return [(on, 1, _bend(0))] if note.channel in (CLARINET, FLUTE) else []
    step = TICKS_PER_BEAT // 50  # 20 ms
    events = []
    if note.scoop:
        events += [(on + k * step // 2, 1, _bend(-45 * (1 - k / 9))) for k in range(10)]
    else:
        events.append((on, 1, _bend(0)))
    if note.vibrato:
        start = on + (off - on) // 3
        for tick in range(start, off - step, step // 2):  # done before the next note's own bends
            seconds = (tick - start) / TICKS_PER_BEAT
            depth = 20 * min(1.0, seconds / 0.6)
            events.append((tick, 1, _bend(depth * np.sin(2 * np.pi * 5.5 * seconds))))
    return events


def _sfz(stem):
    return os.path.join(os.environ["TRAMPOLINE_SAMPLES"], STEMS[stem].sfz)


def _sfizz(sfz, midi, wav):
    subprocess.run(["sfizz_render", "--sfz", sfz, "--midi", midi, "--wav", wav,
                    "-s", str(SAMPLE_RATE), "--use-eot"],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def _read(wav):
    """A wav file as float stereo samples, shape (n, 2)."""
    _, data = wavfile.read(wav)
    data = data.astype(np.float64) / (32768.0 if data.dtype == np.int16 else 1.0)
    return data if data.ndim == 2 else np.column_stack([data, data])


_LEVELS = {}  # sfz file -> {key: dB correction}, measured once per run


def _key_levels(stem, sfz, folder):
    """Sampled notes come out at uneven loudness (one key a few dB above its
    neighbours). Play every key once, measure it, and return per key the
    correction (in dB) that brings it to the instrument's median."""
    spec = STEMS[stem]
    if spec.sfz not in _LEVELS:
        notes = [Note(i, 0.9, key, 90, stem) for i, key in enumerate(spec.keys)]
        midi, wav = os.path.join(folder, "levels.mid"), os.path.join(folder, "levels.wav")
        _write_midi(notes, _steady(60, len(notes)), 0.5, midi, 1, len(notes) + 1, {})
        _sfizz(sfz, midi, wav)
        mono = _read(wav).mean(axis=1)
        db = {}
        for i, key in enumerate(spec.keys):
            chunk = mono[i * SAMPLE_RATE: i * SAMPLE_RATE + SAMPLE_RATE // 2]
            db[key] = 10 * np.log10(np.mean(chunk ** 2) + 1e-12)
        median = float(np.median(list(db.values())))
        _LEVELS[spec.sfz] = {k: float(np.clip(median - v, -9, 9)) for k, v in db.items()}
    return _LEVELS[spec.sfz]


# --- The sound: the room and the mix ------------------------------------------


_ROOM = []  # the room's impulse response, loaded once


def _room():
    """The Brahmssaal of the Detmold University of Music, a small chamber
    music hall (about 120 seats, 1.25 s of reverberation), recorded by a
    dummy head in the middle of the hall: its stereo impulse response
    (see README.md). The direct sound (its first 2.5 ms) is cut: the dry
    mix is the direct sound; the room adds its reflections."""
    if not _ROOM:
        rate, ir = wavfile.read(os.path.join(os.environ["TRAMPOLINE_SAMPLES"], "room", "brahmssaal.wav"))
        ir = resample_poly(ir.astype(np.float64), SAMPLE_RATE, rate, axis=0)
        energy = (ir ** 2).sum(axis=1)
        ir = ir[np.argmax(energy > energy.max() * 1e-2):]
        ramp = int(0.0025 * SAMPLE_RATE)
        ir[:ramp] = 0
        ir[ramp: 2 * ramp] *= np.linspace(0, 1, ramp)[:, None]
        _ROOM.append(ir / np.sqrt((ir ** 2).sum(axis=0)).max())
    return _ROOM[0]


def _playing_db(audio):
    """How loud a stem is while it plays: the RMS of its 100 ms blocks
    louder than 30 dB under its loudest (its rests don't count)."""
    mono = audio.mean(axis=1)
    block = SAMPLE_RATE // 10
    energy = (mono[: len(mono) // block * block].reshape(-1, block) ** 2).mean(axis=1)
    playing = energy[energy > energy.max() * 1e-3]
    return 10 * np.log10(playing.mean() + 1e-20)


def _mix(stems, balance=None):
    """Filter, balance and place the stems, send them to the room; stereo
    out. `balance` (stem -> dB while playing, see _playing_db) sets each
    stem's level; without it, the stems' own gain_db."""
    length = max(len(s) for s in stems.values())
    dry = np.zeros((length, 2))
    send = np.zeros(length)
    for stem, audio in stems.items():
        spec = STEMS[stem]
        audio = np.pad(audio, ((0, length - len(audio)), (0, 0)))
        audio = sosfilt(butter(2, spec.highpass, "highpass", fs=SAMPLE_RATE, output="sos"), audio, axis=0)
        if spec.lowpass < SAMPLE_RATE / 2:
            audio = sosfilt(butter(1, spec.lowpass, "lowpass", fs=SAMPLE_RATE, output="sos"), audio, axis=0)
        gain_db = balance[stem] - _playing_db(audio) if balance else spec.gain_db
        audio *= 10 ** (gain_db / 20)
        # Narrow the recording's own stereo image (mid/side), then place it
        # (a constant-power balance: left and right at 1 when centred).
        mid, side = audio.mean(axis=1), (audio[:, 0] - audio[:, 1]) / 2 * spec.width
        angle = (spec.pan + 1) * np.pi / 4
        dry += np.column_stack([(mid + side) * np.cos(angle), (mid - side) * np.sin(angle)]) * np.sqrt(2)
        send += mid * spec.reverb
    send = sosfilt(butter(2, 180, "highpass", fs=SAMPLE_RATE, output="sos"), send)
    ir = _room()
    wet = np.column_stack([oaconvolve(send, ir[:, side])[:length] for side in range(2)])
    return dry + wet


def _master(audio, rms_db=-18.0):
    """Bring the mix to a common loudness, then round off the rare peaks
    above -4.5 dBFS so they stay under -1.5 dBFS (a soft limiter: the margin
    keeps the Vorbis encoding from clipping)."""
    audio = audio * 10 ** (rms_db / 20) / (np.sqrt(np.mean(audio ** 2)) + 1e-12)
    knee, ceiling = 10 ** (-4.5 / 20), 10 ** (-1.5 / 20)
    over = np.abs(audio) > knee
    audio[over] = np.sign(audio[over]) * (knee + (ceiling - knee) * np.tanh((np.abs(audio[over]) - knee) / (ceiling - knee)))
    return audio


def _render(notes, times, swing, folder, repeats, end_seconds, balance=None):
    """Every stem through sfizz, then mixed: stereo float samples."""
    stems = {}
    for stem in sorted({n.channel for n in notes}):
        sfz = _sfz(stem)
        midi, wav = os.path.join(folder, f"{stem}.mid"), os.path.join(folder, f"{stem}.wav")
        _write_midi([n for n in notes if n.channel == stem], times, swing, midi,
                    repeats, end_seconds, _key_levels(stem, sfz, folder))
        _sfizz(sfz, midi, wav)
        stems[stem] = _read(wav)
    return _mix(stems, balance)


def _save(path, audio):
    wavfile.write(path, SAMPLE_RATE, (np.clip(audio, -1, 1) * 32767).astype(np.int16))


def _balance(tune):
    """Each stem's level in the tune (see _BALANCE_DB): its main part, the
    tune before a counter-melody."""
    balance = {RHYTHM: _BALANCE_DB["comp"], BASS: _BALANCE_DB["bass"]}
    for a_pass in tune.passes:
        if a_pass.counter:
            balance.setdefault(a_pass.counter_lead, _BALANCE_DB["counter"])
    for a_pass in tune.passes:
        balance[a_pass.lead] = _BALANCE_DB["lead"]
    return balance


def build_loop(tune, ogg_path):
    """Render the tune three times in a row and keep the middle one: it starts
    with the ringing notes and reverb of its predecessor, so it loops
    without a seam. The samples' small random variations (round robins,
    random pitch) make the third time not quite the second, so the loop's
    first 80 ms fade in from the third: what really follows its last sample."""
    notes, beats = arrange(tune)
    times = _clock(tune, beats)
    with tempfile.TemporaryDirectory() as tmp:
        audio = _render(notes, times, tune.swing, tmp, 3, 3 * times[-1], _balance(tune))
        size = round(times[-1] * SAMPLE_RATE)
        loop = audio[size: 2 * size].copy()
        fade = np.linspace(0, 1, int(0.08 * SAMPLE_RATE))[:, None]
        loop[: len(fade)] = fade * loop[: len(fade)] + (1 - fade) * audio[2 * size: 2 * size + len(fade)]
        loop = _master(loop)
        wav = os.path.join(tmp, "loop.wav")
        _save(wav, loop)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "4", ogg_path], check=True)
    return times[-1]


def build_stinger(notes, tempo, wav_path, tail_beats=3.0, swing=0.5):
    """A one-shot musical sound effect (no loop), mono wav for Godot."""
    beats = max(n.beat + n.length for n in notes)
    with tempfile.TemporaryDirectory() as tmp:
        mix, trimmed = os.path.join(tmp, "mix.wav"), os.path.join(tmp, "trim.wav")
        audio = _render(notes, _steady(tempo, beats), swing, tmp, 1, (beats + tail_beats) * 60 / tempo)
        _save(mix, _master(audio, rms_db=-16.0))
        # Mono, drop the silent tail (below -50 dB); then normalise and fade
        # the last 0.3 s (a second pass: fade needs the trimmed length).
        subprocess.run(["sox", mix, "-c", "1", trimmed, "reverse", "silence", "1", "0.02", "-50d", "reverse"], check=True)
        subprocess.run(["sox", trimmed, wav_path, "gain", "-n", "-1", "fade", "0", "-0", "0.3"], check=True)
