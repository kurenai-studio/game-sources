"""Turns the lofi tracks in tools/music_source/ into the game's music, and
measures the beat of every track the athletes bounce to.

Each track is evened out to the loudness of the game's sounds (-18 LUFS),
given the same gentle top end as the sound effects, faded in and out, and
saved as Ogg Vorbis in assets/audio/music/. data/music.json gets each track in
its set, with its credit.

For the events set, the beat is measured from the audio itself:
  * an onset envelope (how much new sound arrives, moment to moment), from a
    short-time spectrum's rise, and a second one from the low end alone (the
    kick drum);
  * the tempo, from the envelope's autocorrelation (lofi lives between 70 and
    110 bpm), refined by trying tempos a hundredth of a bpm apart and keeping
    the one whose beat grid lands on the most onset;
  * the grid's phase, the same way, to a couple of milliseconds;
  * which beat is the downbeat: the one the kick drum hits hardest;
  * the drift check: the grid is fitted again in each 8-bar stretch, and if
    the track's tempo turns out a hair off, the slope of those fits fixes it;
  * where the beat is clear (the drums are in): the first bar from which the
    onsets fall on the grid far more than between it. Events start there.
A track whose beat isn't clear enough is moved to the stadium set instead.

Run:  python tools/fetch_music.py, then python tools/make_music.py [name ...]
Needs numpy, scipy and ffmpeg.
"""

import json
import subprocess
import sys
from pathlib import Path

import numpy as np
from scipy import signal

sys.path.insert(0, str(Path(__file__).resolve().parent))
from fetch_music import OUT as SOURCE, TRACKS   # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
DEST = ROOT / "assets" / "audio" / "music"
MUSIC_JSON = ROOT / "data" / "music.json"
LUFS = -18.0
SR = 22050
HOP = 128
SHAPE = "acompressor=threshold=0.1:ratio=2.0:attack=8:release=250:knee=6,highshelf=f=6000:g=-3,lowpass=f=15000"


def run(args):
    return subprocess.run(args, capture_output=True, text=True, encoding="utf-8", errors="ignore")


def decode(path):
    """The track as mono floats at SR."""
    p = subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", str(path), "-ac", "1", "-ar", str(SR),
                        "-f", "f32le", "-"], capture_output=True)
    return np.frombuffer(p.stdout, dtype=np.float32).astype(np.float64)


def onsets(x):
    """Onset envelopes (all, and the low end), one value per HOP samples."""
    f, t, Z = signal.stft(x, SR, nperseg=1024, noverlap=1024 - HOP, boundary=None, padded=False)
    mag = np.log1p(np.abs(Z) * 100.0)
    flux = np.maximum(0.0, np.diff(mag, axis=1))
    full = flux.sum(axis=0)
    low = flux[f < 160].sum(axis=0)
    for e in (full, low):
        e -= np.convolve(e, np.ones(64) / 64, mode="same")   # take away the slow swell
        np.maximum(e, 0, out=e)
    fps = SR / HOP
    return full / (full.max() or 1), low / (low.max() or 1), fps


def sample(env, times, fps):
    i = times * fps
    i0 = np.clip(np.floor(i).astype(int), 0, len(env) - 2)
    fr = i - i0
    return env[i0] * (1 - fr) + env[i0 + 1] * fr


def grid_score(env, fps, bpm, phase, t0=0.0, t1=None):
    t1 = t1 if t1 is not None else len(env) / fps
    beat = 60.0 / bpm
    times = np.arange(phase + np.ceil((t0 - phase) / beat) * beat, t1, beat)
    if len(times) < 4:
        return 0.0
    return float(sample(env, times, fps).mean())


def best_phase(env, fps, bpm, t0=0.0, t1=None, steps=200):
    beat = 60.0 / bpm
    phases = np.linspace(0, beat, steps, endpoint=False)
    scores = [grid_score(env, fps, bpm, p, t0, t1) for p in phases]
    k = int(np.argmax(scores))
    return float(phases[k]), float(scores[k])


def tempo(env, fps):
    ac = np.correlate(env, env, mode="full")[len(env) - 1:]
    best, score = 90.0, -1.0
    for bpm in np.arange(70.0, 125.0, 0.25):
        lag = 60.0 / bpm * fps
        # the beat, and its double and half, should all ring
        s = 0.0
        for mult, w in ((1, 1.0), (2, 0.5), (4, 0.25)):
            L = lag * mult
            i = int(L)
            if i + 1 < len(ac):
                s += w * (ac[i] * (1 - (L - i)) + ac[i + 1] * (L - i))
        # lofi sits round 85-95: a gentle preference
        s *= np.exp(-((bpm - 90.0) / 30.0) ** 2)
        if s > score:
            best, score = bpm, s
    # refine on the grid itself
    cands = np.arange(best - 0.5, best + 0.5, 0.01)
    scores = [best_phase(env, fps, b, steps=60)[1] for b in cands]
    return float(cands[int(np.argmax(scores))])


def analyse(path):
    x = decode(path)
    env, low, fps = onsets(x)
    dur = len(x) / SR
    bpm = tempo(env, fps)
    phase, _ = best_phase(env, fps, bpm, steps=400)
    beat = 60.0 / bpm
    # drift: fit the phase again in 8-bar stretches; their slope corrects the tempo
    stretch = beat * 32
    xs, ys = [], []
    t = 0.0
    while t + stretch <= dur:
        p, s = best_phase(env, fps, bpm, t, t + stretch, steps=200)
        # unwrap against the global phase
        d = (p - phase + beat / 2) % beat - beat / 2
        if s > 0.05:
            xs.append(t + stretch / 2)
            ys.append(d)
        t += stretch
    if len(xs) >= 3:
        slope = np.polyfit(xs, ys, 1)[0]
        bpm = bpm * (1.0 - slope)
        beat = 60.0 / bpm
        phase, _ = best_phase(env, fps, bpm, steps=600)
    # the downbeat: the beat of four the kick hits hardest
    n_beats = int((dur - phase) / beat)
    times = phase + np.arange(n_beats) * beat
    kicks = sample(low, times, fps)
    which = int(np.argmax([kicks[k::4].mean() for k in range(4)]))
    offset = phase + which * beat
    # how clear the beat is, bar by bar: on the grid against between it
    on = sample(env, times, fps)
    off = sample(env, times + beat / 2.0, fps) * 0.5 + sample(env, times + beat / 4.0, fps) * 0.5
    bar = beat * 4
    n_bars = int((dur - offset) / bar)
    clarity = []
    for b in range(n_bars):
        t0 = offset + b * bar
        sel = (times >= t0 - 1e-6) & (times < t0 + bar - 1e-6)
        if sel.sum() < 4:
            clarity.append(0.0)
            continue
        clarity.append(float(on[sel].mean() / (off[sel].mean() + 1e-3)))
    clarity = np.array(clarity)
    start_bar = 0
    for b in range(max(0, len(clarity) - 4)):
        if clarity[b:b + 4].min() > 1.3:
            start_bar = b
            break
    whole = float(np.median(clarity)) if len(clarity) else 0.0
    # check the fit over the whole track: the late bars should be as on-grid as the early ones
    return {"bpm": round(bpm, 3), "offset": round(offset, 4), "start": round(offset + start_bar * bar, 3),
            "clarity": round(whole, 2), "duration": round(dur, 2)}


def measure(path, pre=""):
    chain = (pre + "," if pre else "") + f"loudnorm=I={LUFS}:TP=-1.5:LRA=11:print_format=json"
    out = run(["ffmpeg", "-hide_banner", "-i", str(path), "-af", chain, "-f", "null", "-"]).stderr
    return json.loads(out[out.rindex("{"):out.rindex("}") + 1])


def convert(name, set_):
    src = SOURCE / f"{name}.mp3"
    dst = DEST / set_ / f"{name}.ogg"
    dst.parent.mkdir(parents=True, exist_ok=True)
    m = measure(src, SHAPE)
    dur = float(run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(src)]).stdout)
    # events tracks keep their very start (the beat map counts from it): no fade in
    fade_in = "" if set_ == "events" else "afade=t=in:d=0.6,"
    filt = (f"{SHAPE},"
            f"loudnorm=I={LUFS}:TP=-1.5:LRA=11:measured_I={m['input_i']}:measured_TP={m['input_tp']}:"
            f"measured_LRA={m['input_lra']}:measured_thresh={m['input_thresh']}:offset={m['target_offset']}:linear=true,"
            f"{fade_in}afade=t=out:st={max(0.0, dur - 2.5):.2f}:d=2.5")
    r = run(["ffmpeg", "-hide_banner", "-y", "-i", str(src), "-af", filt, "-ar", "44100", "-ac", "2",
             "-c:a", "libvorbis", "-q:a", "3", str(dst)])
    if r.returncode != 0:
        raise RuntimeError(r.stderr[-400:])
    return dst


def main(only):
    data = json.loads(MUSIC_JSON.read_text(encoding="utf-8")) if MUSIC_JSON.exists() else {}
    sets = {k: [] for k in ["title", "stadium", "events", "ceremony"]}
    # keep any hand-made entries (the stand-in loops) that aren't from Pixabay
    for k, items in data.get("sets", {}).items():
        for it in items:
            if isinstance(it, dict) and it.get("made"):
                sets.setdefault(k, []).append(it)
    credits = [c for c in data.get("credits", []) if c.get("made")]
    for set_, name, title, artist, page, _file in TRACKS:
        src = SOURCE / f"{name}.mp3"
        if not src.exists():
            print(f"missing {name} (run fetch_music.py)")
            continue
        dst = DEST / set_ / f"{name}.ogg"
        if not only or name in only or not dst.exists():
            convert(name, set_)
        entry = {"path": "res://" + dst.relative_to(ROOT).as_posix(), "title": title, "artist": artist}
        target = set_
        if set_ == "events":
            beat = analyse(dst)
            entry.update(beat)
            print(f"{name:20s} {beat['bpm']:7.2f} bpm  first downbeat {beat['offset']:.3f}s  "
                  f"start {beat['start']:.2f}s  clarity {beat['clarity']:.2f}")
            if beat["clarity"] < 1.25:
                target = "stadium"
                print(f"   (beat not clear enough to bounce to: menus instead)")
            elif not 72.0 <= beat["bpm"] <= 102.0:
                target = "ceremony"
                print(f"   (too fast or slow for a comfortable bounce: the ceremony instead)")
        sets[target].append(entry)
        credits.append({"title": title, "artist": artist, "page": page, "licence": "Pixabay Content License"})
    data["sets"] = sets
    data["credits"] = credits
    data.setdefault("gap", [2.0, 6.0])
    MUSIC_JSON.write_text(json.dumps(data, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print("wrote", MUSIC_JSON)


if __name__ == "__main__":
    main(sys.argv[1:])
