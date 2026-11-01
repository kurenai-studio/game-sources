"""Measures Scoundrel's rendered sound effects; exits non-zero if any fails.

    python audio-source/check.py

Claude cannot hear, so this is how a render is judged before anyone listens:
- the folder holds exactly the files the recipes make (everything in assets/ ships);
- each is 16-bit mono PCM at 44.1 kHz;
- the peak is at or under -1 dBFS;
- the attack starts within 5 ms, so the sound lands on the beat it is played on;
- the tail ends in silence, and there is no DC offset;
- it is no longer than its recipe allows (flips must stay short: they land 83 ms apart);
- its loudness (the loudest 50 ms) is on its recipe's target;
- the committed bytes are exactly what the recipes render now;
- and the versions of a sound are not near-copies of one another (waveform
  correlation under 0.9) - two versions that are the same sound defeat the
  point of having them.

It also prints, without failing, how bright each weight is (spectral centroid):
heavier should read darker, but that is a proxy, and tuning by ear may overrule it.

And the streams - the music, the cues, the torch loop - measured as decoded,
because Vorbis moves the peak: format and channels; peak at or under -1 dBFS;
integrated loudness on target; a loop's seam no worse than the rest of it (the
sample step across the wrap, and the high-frequency energy of a window straddling
it, where a click would show); a cue's start inside 5 ms and a silent tail; and
the decoded audio equal to a fresh render's (an OGG's bytes differ run to run,
its audio does not).

Whether any of it sounds right is the listening rounds' call, not this script's.
"""

import itertools
import math
import sys
import wave

import numpy as np
import soundfile

import music
import recipes
import render
import synth

PEAK_CEILING_DB = -1.0
LEAD_LIMIT_MS = 5.0
LEAD_THRESHOLD_DB = -40.0
TAIL_LIMIT_DB = -60.0
DC_LIMIT = 0.002
LOUDNESS_TOLERANCE_DB = 0.5
VERSION_CORRELATION_LIMIT = 0.9


def correlation(a, b):
    n = min(len(a), len(b))
    return float(np.corrcoef(a[:n], b[:n])[0, 1])


def centroid_hz(x):
    """Spectral centroid: a rough number for how bright a sound is."""
    spectrum = np.abs(np.fft.rfft(x * np.hanning(len(x))))
    freqs = np.fft.rfftfreq(len(x), 1 / synth.SR)
    return float(np.sum(freqs * spectrum) / np.sum(spectrum))


def compare_versions_and_weights(jobs, skip):
    """(failures, report lines): near-copy versions fail; brightness by weight is reported."""
    signals = {}
    for job in jobs:
        path = render.SFX_DIR / f"{job.name}.wav"
        if path.exists():
            signals[job.name] = read_wav(path)[0]
    failures, report = [], []
    by_stem, by_sound = {}, {}
    for job in jobs:
        if job.name in signals:
            by_stem.setdefault(job.name.rsplit("_", 1)[0], []).append(job)
            by_sound.setdefault(job.recipe.sound, []).append(job)
    for stem, members in by_stem.items():
        for a, b in itertools.combinations(members, 2):
            if a.name in skip or b.name in skip:
                continue
            r = correlation(signals[a.name], signals[b.name])
            if r >= VERSION_CORRELATION_LIMIT:
                failures.append(f"{a.name} and {b.name} correlate {r:+.2f}: near-copies, not versions")
    for sound, members in by_sound.items():
        if not members[0].recipe.weights:
            continue
        levels = []
        for weight in members[0].recipe.weights:
            hz = [centroid_hz(signals[j.name]) for j in members if recipes.WEIGHTS[j.weight] == weight]
            levels.append((weight, sum(hz) / len(hz)))
        darker = all(levels[i][1] > levels[i + 1][1] for i in range(len(levels) - 1))
        report.append(f"  {sound:<6} " + "  >  ".join(f"{w} {hz:5.0f} Hz" for w, hz in levels)
                      + ("" if darker else "   (not darker as it gets heavier)"))
    return failures, report


def read_wav(path):
    """(float signal, channels, sample width, rate) for a PCM WAV."""
    with wave.open(str(path), "rb") as f:
        channels, width, rate, frames = f.getnchannels(), f.getsampwidth(), f.getframerate(), f.getnframes()
        data = f.readframes(frames)
    signal = np.frombuffer(data, dtype="<i2").astype(np.float64) / 32768.0 if width == 2 else np.zeros(0)
    return signal, channels, width, rate


def lead_ms(x):
    over = np.nonzero(np.abs(x) >= 10 ** (LEAD_THRESHOLD_DB / 20))[0]
    return math.inf if len(over) == 0 else over[0] / synth.SR * 1000


def measure(job, path, replaced):
    """(row of measurements, list of failures) for one file."""
    x, channels, width, rate = read_wav(path)
    fails = []
    if (channels, width, rate) != (1, 2, synth.SR):
        fails.append(f"format {channels}ch/{8 * width}bit/{rate}Hz, want 1ch/16bit/{synth.SR}Hz")
    seconds = len(x) / synth.SR
    peak, loud, lead = synth.peak_db(x), synth.loudness_db(x), lead_ms(x)
    tail = synth.rms_db(x[-synth.samples(0.01):])
    dc = float(np.mean(x)) if len(x) else 0.0
    if peak > PEAK_CEILING_DB + 1e-3:
        fails.append(f"peak {peak:.2f} dBFS over {PEAK_CEILING_DB}")
    if lead > LEAD_LIMIT_MS:
        fails.append(f"attack starts at {lead:.1f} ms, over {LEAD_LIMIT_MS}")
    if tail > TAIL_LIMIT_DB:
        fails.append(f"tail {tail:.1f} dBFS, not silent")
    if abs(dc) > DC_LIMIT:
        fails.append(f"DC offset {dc:.4f}")
    if seconds > job.recipe.max_seconds:
        fails.append(f"{seconds:.3f} s, over its {job.recipe.max_seconds} s")
    if not replaced and abs(loud - job.target_db) > LOUDNESS_TOLERANCE_DB:
        fails.append(f"loudness {loud:.2f} dBFS, target {job.target_db}")
    row = f"{job.name:<16} {seconds:6.3f}s  peak {peak:6.2f}  loud {loud:6.2f} (target {job.target_db:5.1f})" \
          f"  lead {lead:4.1f}ms  tail {tail:7.1f}  dc {dc:+.4f}"
    return row, fails


def seam_step_ok(x):
    """(ok, worst ratio): the step across the wrap against the loop's 99.9th-percentile step."""
    worst = 0.0
    for c in range(x.shape[1]):
        steps = np.abs(np.diff(np.concatenate([x[:, c], x[:1, c]])))
        worst = max(worst, steps[-1] / max(1e-12, np.percentile(steps, 99.9)))
    return worst <= 1.0, worst


def seam_hf(x):
    """High-frequency energy in a 10 ms window straddling a loop's seam, and in every other
    10 ms window round the loop. A click is broadband, so it shows up here."""
    x = x if x.ndim == 2 else x[:, None]
    energy = np.sum(np.square(synth.circular_filter(x, synth.highpass_response(6000, 2))), axis=1)
    w = synth.samples(0.01)
    running = np.cumsum(np.concatenate([energy, energy[:w]]))
    windows = running[w:] - running[:-w]
    seam = float(np.sum(energy[-(w // 2):]) + np.sum(energy[:w - w // 2]))
    return seam, windows


SEAM_ENCODING_LIMIT = 1.5


def seam_click_ok(decoded, source):
    """(ok, ratio): did encoding put a click at the seam? The source loop is seamless by
    construction (music.py), so the seam's high-frequency energy is compared with the
    source's at the same spot - a note plucked on the downbeat is broadband too, and
    measuring against the rest of the loop called it a click (the menu, in Task 6). For
    a replaced stream there is no source, so its seam is held to the loop's own
    99th-percentile window instead."""
    seam, windows = seam_hf(decoded)
    if source is None:
        typical = float(np.percentile(windows, 99))
        return seam <= typical, seam / max(1e-12, typical)
    reference, _ = seam_hf(source)
    ratio = seam / max(1e-12, reference)
    return ratio <= SEAM_ENCODING_LIMIT, ratio


def check_streams(skip):
    """(rows, failures) for the streamed files."""
    rows, failures = [], []
    fresh = render.render_streams()
    for name, (_, target_db, looped, channels) in music.STREAMS.items():
        path = render.stream_path(name)
        if not path.exists():
            failures.append(f"{name}: missing")
            continue
        info = soundfile.info(str(path))
        decoded = render.decode(path.read_bytes())
        x = decoded if decoded.ndim == 2 else decoded[:, None]
        fails = []
        if (info.samplerate, info.channels) != (synth.SR, channels):
            fails.append(f"format {info.channels}ch/{info.samplerate}Hz, want {channels}ch/{synth.SR}Hz")
        peak = synth.peak_db(x)
        loud = synth.loudness_integrated_db(x, looped)
        if peak > PEAK_CEILING_DB + 1e-3:
            fails.append(f"decoded peak {peak:.2f} dBFS over {PEAK_CEILING_DB}")
        if name not in skip and abs(loud - target_db) > LOUDNESS_TOLERANCE_DB:
            fails.append(f"loudness {loud:.2f}, target {target_db}")
        if looped:
            step_ok, step = seam_step_ok(x)
            click_ok, click = seam_click_ok(x, None if name in skip else fresh[name])
            if not step_ok:
                fails.append(f"seam step {step:.2f}x the loop's 99.9th-percentile step")
            if not click_ok:
                fails.append(f"seam high-frequency energy {click:.2f}x the source's: encoding added a click")
            shape = f"seam step {step:.2f}x, seam hf {click:.2f}x the source's"
        else:
            lead = lead_ms(np.max(np.abs(x), axis=1))
            tail = synth.rms_db(x[-synth.samples(0.01):])
            if lead > LEAD_LIMIT_MS:
                fails.append(f"starts at {lead:.1f} ms, over {LEAD_LIMIT_MS}")
            if tail > TAIL_LIMIT_DB:
                fails.append(f"tail {tail:.1f} dBFS, not silent")
            shape = f"lead {lead:.1f}ms, tail {tail:.1f}"
        if name not in skip and not np.array_equal(decoded, render.decode(render.ogg_bytes(fresh[name]))):
            fails.append("decodes differently from a fresh render: re-run render.py")
        rows.append(("FAIL " if fails else "ok   ")
                    + f"{name:<15} {len(x) / synth.SR:6.2f}s {info.channels}ch  peak {peak:6.2f}"
                    + f"  loud {loud:6.2f} (target {target_db:5.1f})  {shape}")
        failures.extend(f"{name}: {f}" for f in fails)
    failures.extend(f"{p}: no stream makes it, and everything in assets/ ships" for p in render.stream_strays())
    return rows, failures


def main():
    skip = render.replaced()
    jobs = recipes.jobs()
    expected = {job.name for job in jobs}
    failures = []

    present = {p.stem for p in render.SFX_DIR.glob("*.wav")} if render.SFX_DIR.exists() else set()
    others = sorted(p.name for p in render.SFX_DIR.iterdir() if p.suffix != ".wav") if render.SFX_DIR.exists() else []
    for name in sorted(expected - present):
        failures.append(f"{name}: missing")
    for name in sorted(present - expected) + others:
        failures.append(f"{name}: no recipe makes it, and everything in assets/ ships")

    fresh = render.render_sfx()
    print(f"{len(jobs)} sound effects ({len(skip & expected)} replaced)\n")
    for job in jobs:
        path = render.SFX_DIR / f"{job.name}.wav"
        if not path.exists():
            continue
        row, fails = measure(job, path, job.name in skip)
        if job.name not in skip and fresh[job.name] != path.read_bytes():
            fails.append("differs from a fresh render: re-run render.py, or the recipe is not deterministic")
        print(("FAIL " if fails else "ok   ") + row)
        failures.extend(f"{job.name}: {f}" for f in fails)

    version_failures, brightness = compare_versions_and_weights(jobs, skip)
    failures.extend(version_failures)
    print("\nbrightness by weight (spectral centroid; heavier should read darker):")
    print("\n".join(brightness))

    stream_rows, stream_failures = check_streams(skip)
    print(f"\n{len(music.STREAMS)} streams (decoded):")
    print("\n".join(stream_rows))
    failures.extend(stream_failures)

    if failures:
        print(f"\n{len(failures)} failure(s):")
        for f in failures:
            print("  " + f)
        return 1
    print("\nall checks pass")
    return 0


if __name__ == "__main__":
    sys.exit(main())
