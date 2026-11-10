"""Turn the University of Iowa guitar recordings into a playable instrument.

The Iowa Musical Instrument Samples (theremin.music.uiowa.edu, "may be
downloaded and used for any projects, without restrictions") record the
guitar as long chromatic runs: one .aif file per dynamic (pp, mf, ff),
string and range, e.g. `Guitar.mf.sulA.C3B3.aif` is C3 up to B3 played
on the A string, each note left to ring and followed by silence. This
cuts every run at its silences, checks each note's pitch, and writes one
.wav per note and an SFZ instrument:
- 3 velocity layers (pp, mf, ff),
- a note available on several strings picks one at random each time, as
  a guitarist would (round robin),
- each note is shifted by a few cents to be exactly in tune,
- notes ring on a little after their end (release) while MIDI controller
  20 is under 64; from 64 up they are damped: the hand stops the strings
  as soon as the note ends (the pompe's "chop").

Used by flake.nix's `samples` (or by hand), on the stereo 16-bit/44.1 kHz
recordings (Guitar.stereo.1644.1.zip):
    python3 slice_guitar.py IOWA_FOLDER OUT_FOLDER   # -> OUT/guitar.sfz
"""

import os
import re
import subprocess
import sys

import numpy as np
from scipy.io import wavfile

SAMPLE_RATE = 44100
_FRAME = 441  # 10 ms analysis frames
# Velocity range of each dynamic's layer.
_LAYERS = {"pp": (1, 54), "mf": (55, 94), "ff": (95, 127)}
_NAMES = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def _midi(name):
    """'Bb5' -> 82."""
    pc = _NAMES[name[0]] + {"b": -1, "#": 1}.get(name[1], 0) if len(name) == 3 else _NAMES[name[0]]
    return 12 * (int(name[-1]) + 1) + pc


def _load(path):
    """A recording as stereo float samples, shape (n, 2)."""
    raw = subprocess.run(["sox", path, "-t", "f32", "-c", "2", "-r", str(SAMPLE_RATE), "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.float32).astype(np.float64).reshape(-1, 2)


def _notes(audio):
    """[(start, end)] sample ranges of the sounds in a run, split at the
    silences (at least 0.15 s under -70 dB) between them."""
    frames = len(audio) // _FRAME
    db = 20 * np.log10(np.sqrt(np.mean(audio[: frames * _FRAME].reshape(frames, _FRAME) ** 2, axis=1)) + 1e-9)
    loud = db > -70
    notes, start, quiet = [], None, 0
    for i, on in enumerate(loud):
        if on:
            if start is None:
                start = i
            quiet = 0
        elif start is not None:
            quiet += 1
            if quiet >= 15:
                notes.append((start, i - quiet + 1))
                start = None
    if start is not None:
        notes.append((start, frames))
    # Drop crumbs (a stray click is not a note).
    return [(s * _FRAME, e * _FRAME) for s, e in notes if e - s >= 30]


def _pitch(chunk):
    """Fundamental frequency of a note (harmonic product spectrum)."""
    size = 1 << 17
    spectrum = np.abs(np.fft.rfft(chunk[: size] * np.hanning(min(len(chunk), size)), size))
    product = spectrum.copy()
    for k in (2, 3):
        product[: len(spectrum) // k] *= spectrum[::k][: len(spectrum) // k]
    freqs = np.fft.rfftfreq(size, 1 / SAMPLE_RATE)
    usable = freqs > 70
    return freqs[usable][np.argmax(product[usable])]


def _cents(freq, key):
    """How far `freq` is from `key`, in cents, ignoring octaves (the pitch
    detector may land an octave off)."""
    cents = 1200 * np.log2(freq / (440 * 2 ** ((key - 69) / 12)))
    return cents - 1200 * round(cents / 1200)


def _cut(audio, keys):
    """[(key, start, end, cents)]: the run's notes, matched to the keys it
    should play in order. Silences split the run into pieces; a piece with
    the pitch of the one before is the same note ringing on (glued back);
    a piece matching no expected key (a click, a squeak) is dropped."""
    pieces = []  # [start, end, pitch]
    for start, end in _notes(audio):
        pitch = _pitch(audio[start + 2205: start + 2205 + 32768])  # past the pluck's noise
        if pieces and abs(1200 * np.log2(pitch / pieces[-1][2])) < 60:
            pieces[-1][1] = end
        else:
            pieces.append([start, end, pitch])
    found, i = [], 0
    for start, end, pitch in pieces:
        if i < len(keys) and abs(_cents(pitch, keys[i])) < 60:
            found.append((keys[i], start, end, _cents(pitch, keys[i])))
            i += 1
        elif i + 1 < len(keys) and abs(_cents(pitch, keys[i + 1])) < 60:
            # One note of the run is missing: go on from the next.
            found.append((keys[i + 1], start, end, _cents(pitch, keys[i + 1])))
            i += 2
    return found


def main(source, out):
    os.makedirs(os.path.join(out, "samples"), exist_ok=True)
    regions = {}  # (dynamic, key) -> [(file, cents)]
    pattern = re.compile(r"Guitar\.(pp|mf|ff)\.sul_?([EADGB])\.([A-G]b?\d)([A-G]b?\d)?\.aif")
    missing = 0
    for name in sorted(os.listdir(source)):
        match = pattern.fullmatch(name)
        if not match:
            continue
        dynamic, string, low, high = match.groups()
        string = string.lower() if "sul_" in name else string  # sul_E: the high E string
        keys = list(range(_midi(low), _midi(high or low) + 1))
        audio = _load(os.path.join(source, name))
        found = _cut(audio.mean(axis=1), keys)
        if len(found) < len(keys):
            print(f"{name}: {len(keys) - len(found)} of {len(keys)} notes not found")
            missing += len(keys) - len(found)
        for key, start, end, cents in found:
            note = audio[max(0, start - 220): end].copy()  # from 5 ms before the onset
            fade = np.linspace(1, 0, min(len(note), 2205))  # 50 ms fade at the end
            note[-len(fade):] *= fade[:, None]
            file = f"samples/{dynamic}_{string}_{key}.wav"
            wavfile.write(os.path.join(out, file), SAMPLE_RATE, (np.clip(note, -1, 1) * 32767).astype(np.int16))
            regions.setdefault((dynamic, key), []).append((file, cents))
    lines = [
        "// Classical guitar, from the University of Iowa Musical Instrument Samples.",
        "// Made by tools/audio/slice_guitar.py.",
        "<global> amp_veltrack=35",
    ]
    all_keys = sorted({k for _, k in regions})
    # Each region twice: ringing (CC20 0..63), then damped (CC20 64..127).
    for locc, hicc, release in ((0, 63, 0.25), (64, 127, 0.04)):
        for dynamic, (lovel, hivel) in _LAYERS.items():
            lines.append(f"<group> locc20={locc} hicc20={hicc} ampeg_release={release}"
                         f" lovel={lovel} hivel={hivel}")
            have = sorted(k for d, k in regions if d == dynamic)
            for key in range(all_keys[0], all_keys[-1] + 1):
                # A key this layer lacks borrows its nearest sampled neighbour.
                source_key = min(have, key=lambda k: (abs(k - key), k))
                takes = regions[(dynamic, source_key)]
                for i, (file, cents) in enumerate(takes):
                    lorand, hirand = i / len(takes), (i + 1) / len(takes)
                    lines.append(f"<region> key={key} pitch_keycenter={source_key} tune={-round(cents)}"
                                 f" lorand={lorand:.3f} hirand={hirand:.3f} sample={file}")
    with open(os.path.join(out, "guitar.sfz"), "w") as sfz:
        sfz.write("\n".join(lines) + "\n")
    print(f"{len(regions)} notes kept, keys {all_keys[0]}..{all_keys[-1]}, {missing} missing")


if __name__ == "__main__":
    main(*sys.argv[1:])
