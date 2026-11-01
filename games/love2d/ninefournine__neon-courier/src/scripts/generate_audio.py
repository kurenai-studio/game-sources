#!/usr/bin/env python3
"""Original NEON COURIER score/SFX. Standard library synthesis + local ffmpeg.

No samples, models, external services, or third-party music are used. Events are
composed on a 16-bar grid. Decays wrap around the score so the loop is continuous.
Run from the repo root: python3 scripts/generate_audio.py
"""
from array import array
from pathlib import Path
import json
import math
import random
import shutil
import subprocess
import tempfile
import wave

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio"
RATE = 22050
BPM = 100
BEAT = 60 / BPM
TAU = math.tau
RNG = random.Random(19990929)
STATS = {}


def freq(midi):
    return 440 * 2 ** ((midi - 69) / 12)


def envelope(t, duration, attack=0.008, release=0.09):
    return min(1.0, t / attack) * min(1.0, max(0, duration - t) / release)


def add(buf, at, duration, fn, amp=1, wrap=False):
    start = round(at * RATE)
    for i in range(round(duration * RATE)):
        idx = start + i
        if wrap:
            idx %= len(buf)
        elif idx < 0 or idx >= len(buf):
            continue
        buf[idx] += amp * fn(i / RATE, duration)


def tone(note, kind="keys"):
    f = freq(note)
    if kind == "pad":
        return lambda t, d: envelope(t, d, .38, .62) * (
            math.sin(TAU * f * t) + .17 * math.sin(TAU * f * 2 * t)
            + .09 * math.sin(TAU * f * 3 * t))
    if kind == "bass":
        return lambda t, d: envelope(t, d, .009, .10) * math.exp(-t * 1.7) * (
            math.sin(TAU * f * t) + .24 * math.sin(TAU * f * 2 * t))
    return lambda t, d: envelope(t, d, .006, .17) * math.exp(-t * 2.8) * (
        math.sin(TAU * f * t) + .30 * math.sin(TAU * f * 2 * t)
        + .08 * math.sin(TAU * f * 3 * t))


def kick(t, d):
    # Integral of falling pitch avoids a discontinuous phase reset.
    phase = TAU * (48 * t + 86 * .025 * (1 - math.exp(-t / .025)))
    return envelope(t, d, .002, .07) * math.sin(phase) * math.exp(-t * 15)


def snare(t, d):
    return envelope(t, d, .001, .015) * math.exp(-t * 28) * (
        .55 * RNG.uniform(-1, 1) + .45 * math.sin(TAU * 181 * t))


def hat(t, d):
    return envelope(t, d, .001, .01) * math.exp(-t * 90) * (
        RNG.uniform(-1, 1) + .25 * math.sin(TAU * 7013 * t))


def measure(name, buf, looping=False):
    peak = max(abs(x) for x in buf)
    rms = math.sqrt(sum(x * x for x in buf) / len(buf))
    record = {
        "sample_rate": RATE, "samples": len(buf), "duration_seconds": len(buf) / RATE,
        "peak_linear": round(peak, 5), "rms_linear": round(rms, 5),
        "peak_dbfs": round(20 * math.log10(max(peak, 1e-9)), 2),
        "clipped_samples": sum(abs(x) >= 1 for x in buf),
    }
    if looping:
        record["boundary_step_linear"] = round(abs(buf[-1] - buf[0]), 6)
        record["mean_adjacent_step_linear"] = round(
            sum(abs(buf[i] - buf[i-1]) for i in range(1, len(buf))) / (len(buf)-1), 6)
    STATS[name] = record


def write_wav(path, buf):
    samples = array("h", (round(max(-.9999, min(.9999, x)) * 32767) for x in buf))
    import sys
    if sys.byteorder != "little":
        samples.byteswap()
    with wave.open(str(path), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(samples.tobytes())


def save(name, buf, peak=.72, looping=False, ogg=False):
    actual = max(abs(x) for x in buf)
    if actual:
        factor = peak / actual
        for i in range(len(buf)):
            buf[i] *= factor
    measure(name, buf, looping)
    synthesized = STATS[name]
    if ogg:
        with tempfile.TemporaryDirectory(prefix="neon-audio-") as temp:
            wav = Path(temp) / "input.wav"
            write_wav(wav, buf)
            subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
                "-i", str(wav), "-c:a", "libvorbis", "-q:a", "4", "-map_metadata", "-1",
                str(OUT / (name + ".ogg"))], check=True)
        # Verify the actual decoder output, not just the pre-encode waveform.
        decoded = subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error",
            "-i", str(OUT / (name + ".ogg")), "-f", "f32le", "-ac", "1", "-ar", str(RATE),
            "pipe:1"], check=True, stdout=subprocess.PIPE).stdout
        decoded_buf = array("f")
        decoded_buf.frombytes(decoded)
        import sys
        if sys.byteorder != "little":
            decoded_buf.byteswap()
        measure(name, decoded_buf, looping)
        STATS[name]["synthesized_peak_linear"] = synthesized["peak_linear"]
        STATS[name]["verification"] = "ffmpeg decoded Ogg Vorbis"
    else:
        write_wav(OUT / (name + ".wav"), buf)


def music():
    length = round(16 * 4 * BEAT * RATE)
    base = array("f", [0]) * length
    chase = array("f", [0]) * length
    # Em9 / Cmaj7 / Am9 / Bm7. Two bars per harmony, twice, with a
    # D# pickup before each return to E. Deliberately composed melody.
    chords = [(40, [52, 55, 59, 62, 66]), (36, [48, 52, 55, 59]),
              (33, [45, 48, 52, 55, 59]), (35, [47, 50, 54, 57])]
    motifs = [
        [(0, 76, .7), (1.5, 79, .45), (2.5, 71, .65)],
        [(.5, 74, .7), (2, 71, .8), (3.5, 67, .4)],
        [(0, 72, .9), (1.5, 76, .5), (2.5, 79, .7)],
        [(.5, 71, .7), (2, 67, 1.0)],
        [(0, 69, .8), (1.5, 72, .5), (2.5, 76, .7)],
        [(.5, 79, .65), (2, 76, .65), (3, 72, .55)],
        [(0, 71, .8), (1.5, 74, .5), (2.5, 78, .55)],
        [(.5, 74, .6), (2, 71, .6), (3.5, 75, .45)],
    ]
    for bar in range(16):
        at = bar * 4 * BEAT
        root, chord = chords[(bar // 2) % 4]
        if bar % 2 == 0:
            for n in chord:
                add(base, at - .18, 8 * BEAT + .5, tone(n, "pad"), .045, True)
        for beat, n, sustain in [(0, root, .9), (1.5, root + 12, .55),
                                 (2.75, root, .75), (3.5, root + 7, .42)]:
            add(base, at + beat * BEAT, sustain * BEAT + .08,
                tone(n, "bass"), .17, True)
        for beat in [0, 2] + ([3.5] if bar % 4 == 3 else []):
            add(base, at + beat * BEAT, .28, kick, .26, True)
        for beat in [1, 3]:
            add(base, at + beat * BEAT, .19, snare, .10, True)
        for eighth in range(8):
            swing = .022 if eighth % 2 else 0
            add(base, at + eighth * .5 * BEAT + swing, .065, hat,
                .030 if eighth % 2 else .044, True)
        for beat, n, sustain in motifs[bar % 8]:
            add(base, at + beat * BEAT, sustain * BEAT + .3, tone(n), .086, True)
            # Tempo-locked tape echo: finite authored repeats, no feedback.
            for delay, gain in [(.75, .23), (1.5, .10)]:
                add(base, at + (beat + delay) * BEAT, sustain * BEAT + .3,
                    tone(n), .086 * gain, True)
        # Chase layer has the identical grid/length; eight-note minor arpeggio
        # and deeper, tight pulse. Music remains recognizable under pursuit.
        for eighth in range(8):
            note = chord[(eighth + bar % 2) % len(chord)] + 12
            add(chase, at + eighth * .5 * BEAT, .23, tone(note), .095, True)
        for beat in [0, 1.5, 2, 3.25]:
            add(chase, at + beat * BEAT, .21, kick, .12, True)
        for beat in [1, 3]:
            add(chase, at + beat * BEAT, .12, snare, .055, True)
    save("night_shift", base, .67, True, True)
    save("chase_layer", chase, .51, True, True)


def circular_noise(seconds, smooth):
    buf = array("f", [0]) * round(seconds * RATE)
    raw = array("f", (RNG.uniform(-1, 1) for _ in range(len(buf))))
    value = 0
    for i in range(len(buf)):
        value += (raw[i] - value) * smooth
    # A second pass starts at the steady periodic filter state. Rotate to a
    # naturally quiet adjacent sample rather than inserting a fade/silent dip.
    for i in range(len(buf)):
        value += (raw[i] - value) * smooth
        buf[i] = value
    seam = min(range(1, len(buf)), key=lambda i: abs(buf[i] - buf[i-1]))
    return buf[seam:] + buf[:seam]


def effects():
    save("rain", circular_noise(4.0, .028), .21, True, True)
    # The 50Hz engine fundamental has an integer number of cycles in 1s.
    engine = array("f", (math.sin(TAU * 50 * i / RATE) + .34 * math.sin(TAU * 100 * i / RATE)
        + .09 * math.sin(TAU * 150 * i / RATE) for i in range(RATE)))
    save("engine", engine, .25, True)
    save("skid", circular_noise(1.5, .40), .24, True, True)
    sounds = {
        "boost": (.55, lambda t, d: envelope(t, d, .02, .18) * (
            .27 * RNG.uniform(-1, 1) + .44 * math.sin(TAU * (110*t + 320*t*t))) * math.exp(-t*2)),
        "impact": (.24, lambda t, d: envelope(t, d, .002, .06) * math.exp(-t*17) * (
            .65*RNG.uniform(-1, 1) + .45*math.sin(TAU*68*t))),
        "emp": (.72, lambda t, d: envelope(t, d, .01, .22) * math.exp(-t*5) * (
            math.sin(TAU*(950*t - 520*t*t)) + .2*RNG.uniform(-1, 1))),
        "explosion": (.95, lambda t, d: envelope(t, d, .002, .3) * math.exp(-t*5) * (
            .8*RNG.uniform(-1, 1) + .5*math.sin(TAU*(60*t + 10*(1-math.exp(-t*4)))))),
        "ui": (.09, lambda t, d: envelope(t, d, .004, .06) * math.sin(TAU*660*t) * math.exp(-t*12)),
        "back": (.12, lambda t, d: envelope(t, d, .004, .08) * math.sin(TAU*(480*t - 500*t*t))),
    }
    for name, (duration, fn) in sounds.items():
        buf = array("f", [0]) * round(duration * RATE)
        add(buf, 0, duration, fn)
        save(name, buf, .66 if name in ("explosion", "impact") else .48)
    for name, notes, duration in [
        ("pickup", [64, 71, 76], .43), ("delivery", [64, 67, 71, 76], .85),
        ("upgrade", [60, 64, 67, 71, 76], 1.0), ("failed", [59, 55, 52], .65),
    ]:
        buf = array("f", [0]) * round(duration * RATE)
        for i, note in enumerate(notes):
            at = i * (.10 if name != "delivery" else .13)
            add(buf, at, duration - at, tone(note), .3)
        save(name, buf, .52)


def main():
    if not shutil.which("ffmpeg"):
        raise SystemExit("Local ffmpeg with libvorbis is required; no installation is performed.")
    OUT.mkdir(parents=True, exist_ok=True)
    music()
    effects()
    stats = {"authoring": "Original deterministic synthesis", "seed": 19990929,
             "tempo_bpm": BPM, "bars": 16, "meter": "4/4", "tracks": STATS}
    (OUT / "technical_checks.json").write_text(json.dumps(stats, indent=2) + "\n")
    assert all(s["clipped_samples"] == 0 for s in STATS.values())
    print(f"Generated {len(STATS)} original audio assets in {OUT}")
    print(f"Music: 16 bars, {BPM} BPM, {STATS['night_shift']['duration_seconds']:.1f}s")
    for name in ("night_shift", "chase_layer", "rain", "engine", "skid"):
        print(name, STATS[name])


if __name__ == "__main__":
    main()
