"""Signal building blocks for Scoundrel's synthesized audio.

numpy only: the filters are written out by hand rather than taken from scipy, so
the toolchain stays two pinned packages (see requirements.txt). Every function
is deterministic - randomness comes in through an explicit numpy Generator - so
a recipe with a fixed seed renders the same bytes every time.

Signals are float64 arrays at SR, nominally within -1..1.
"""

import math

import numpy as np

SR = 44100
"""The output sample rate: the rate every file ships at, and LibGDX plays."""

LN_1000 = math.log(1000.0)
"""A decay of this many time constants is -60 dB."""


def samples(seconds):
    return int(round(seconds * SR))


def times(n):
    return np.arange(n) / SR


def noise(n, rng):
    """White noise, unit variance."""
    return rng.standard_normal(n)


# --- envelopes --------------------------------------------------------------

def decay(n, t60):
    """Exponential decay from 1, reaching -60 dB after t60 seconds."""
    return np.exp(-times(n) * LN_1000 / t60)


def attack_decay(n, attack, t60):
    """A linear rise over `attack` seconds, then exponential decay to -60 dB at t60 after it."""
    t = times(n)
    rise = np.clip(t / attack, 0.0, 1.0) if attack > 0 else np.ones(n)
    fall = np.exp(-np.maximum(t - attack, 0.0) * LN_1000 / t60)
    return rise * fall


def place(n, signal, at):
    """`signal` laid into a silent buffer of n samples, starting at sample `at`; clipped to fit."""
    out = np.zeros(n)
    end = min(n, at + len(signal))
    if at < n:
        out[at:end] = signal[:end - at]
    return out


# --- oscillators ------------------------------------------------------------

def sweep_sine(n, f_start, f_end, tau):
    """A sine whose pitch falls (or rises) from f_start toward f_end with time constant tau.
    The pitch drop is what makes a low sine read as a thump rather than a tone."""
    t = times(n)
    freq = f_end + (f_start - f_end) * np.exp(-t / tau)
    phase = 2 * np.pi * np.cumsum(freq) / SR
    return np.sin(phase)


def modal(n, partials, attack=0.0005):
    """Struck-object synthesis: a sum of decaying sines, one per mode.
    `partials` is a list of (frequency Hz, amplitude, t60 seconds). Inharmonic
    ratios are what make it metal or glass rather than a note."""
    t = times(n)
    out = np.zeros(n)
    for freq, amp, t60 in partials:
        if freq >= SR / 2:
            continue
        out += amp * np.sin(2 * np.pi * freq * t) * np.exp(-t * LN_1000 / t60)
    if attack > 0:
        out *= np.clip(t / attack, 0.0, 1.0)
    return out


def bubble(n, f0, rise, t60):
    """One Minnaert bubble: a sine that rises in pitch as it dies (van den Doel's model).
    `rise` is the fractional pitch increase per second. A run of these is a glug."""
    t = times(n)
    freq = f0 * (1.0 + rise * t)
    phase = 2 * np.pi * np.cumsum(freq) / SR
    return np.sin(phase) * np.exp(-t * LN_1000 / t60) * np.clip(t / 0.001, 0.0, 1.0)


def karplus_strong(n, freq, rng, damping=0.996, brightness=0.5):
    """A plucked string: a burst of noise circulating in a delay line one period
    long, averaged a little each pass. `brightness` blends the averaging filter."""
    period = max(2, int(round(SR / freq)))
    line = rng.uniform(-1.0, 1.0, period)
    out = np.empty(n)
    idx = 0
    prev = 0.0
    for i in range(n):
        current = line[idx]
        out[i] = current
        averaged = brightness * current + (1.0 - brightness) * 0.5 * (current + prev)
        prev = current
        line[idx] = damping * averaged
        idx += 1
        if idx == period:
            idx = 0
    return out


def pluck(n, freq, rng, damping=0.996, brightness=0.5, excitation_cutoff=None):
    """A plucked string (Karplus-Strong), computed a whole period at a time.

    Each sample is an average of the two a period before it, so a block of one
    period depends only on blocks already written - which lets numpy do each
    block at once instead of Python doing each sample. Same maths as
    karplus_strong(); pitch is quantised to a whole-sample period (a few cents
    at most across this game's range, well inside what lo-fi forgives).
    `excitation_cutoff`, if given, softens the pluck: a darker, gentler attack.
    """
    period = max(2, int(round(SR / freq)))
    burst = rng.uniform(-1.0, 1.0, period)
    if excitation_cutoff:
        burst = one_pole_lowpass(np.tile(burst, 3), excitation_cutoff)[-period:]
    # Centred: the averaging keeps a burst's mean forever, and a string that
    # starts off-centre plays on a DC bias that swamps its note.
    burst -= burst.mean()
    burst /= max(1e-9, np.max(np.abs(burst)))
    c0 = damping * (brightness + (1.0 - brightness) * 0.5)
    c1 = damping * (1.0 - brightness) * 0.5
    blocks = n // period + 2
    y = np.zeros(blocks * period + 1)  # y[0] is the zero before the first sample
    y[1:period + 1] = burst
    for k in range(1, blocks):
        start = 1 + k * period
        prev = y[start - period:start]
        prev_shift = y[start - period - 1:start - 1]
        y[start:start + period] = c0 * prev + c1 * prev_shift
    return y[1:n + 1]


def harmonic_tone(n, freq, harmonics, phase=0.0):
    """An additive tone: `harmonics` is a list of amplitudes for partials 1, 2, 3...
    Band-limited by construction, and exactly periodic if freq * seconds is whole."""
    t = times(n)
    out = np.zeros(n)
    for k, amp in enumerate(harmonics, start=1):
        if amp and freq * k < SR / 2:
            out += amp * np.sin(2 * np.pi * freq * k * t + phase * k)
    return out


def circular_filter(x, response):
    """Filters a loop as a circle, through its spectrum: `response(freqs)` gives the gain
    at each frequency. Zero-phase, and no start-up transient - the end of the loop
    feeds its start, exactly as it will when it plays round."""
    spectrum = np.fft.rfft(x, axis=0)
    freqs = np.fft.rfftfreq(x.shape[0], 1 / SR)
    gain = response(freqs)
    if x.ndim == 2:
        gain = gain[:, None]
    return np.fft.irfft(spectrum * gain, n=x.shape[0], axis=0)


def lowpass_response(cutoff, order=2):
    return lambda f: 1.0 / np.sqrt(1.0 + (f / cutoff) ** (2 * order))


def highpass_response(cutoff, order=2):
    return lambda f: 1.0 / np.sqrt(1.0 + (cutoff / np.maximum(f, 1e-9)) ** (2 * order))


def _comb(x, delay, feedback):
    """y[n] = x[n] + g*y[n-D], a delay's worth at a time."""
    y = x.copy()
    for start in range(delay, len(y), delay):
        end = min(len(y), start + delay)
        y[start:end] += feedback * y[start - delay:end - delay]
    return y


def _allpass(x, delay, gain):
    """y[n] = -g*x[n] + x[n-D] + g*y[n-D], a delay's worth at a time."""
    y = -gain * x
    y[:delay] = -gain * x[:delay]
    for start in range(delay, len(y), delay):
        end = min(len(y), start + delay)
        y[start:end] += x[start - delay:end - delay] + gain * y[start - delay:end - delay]
    return y


# Freeverb's tunings, scaled from 44.1 kHz: mutually prime-ish so the echoes do not ring.
_COMBS = (1116, 1188, 1277, 1356)
_ALLPASSES = (556, 441)
_STEREO_SPREAD = 23


def reverb(x, seconds=2.4, damping_hz=4500):
    """A Schroeder reverb: parallel combs into series all-passes, each channel on
    slightly different delays so the space is wide. `seconds` is the decay to
    -60 dB - a dungeon's, long and dark. Returns the wet signal only."""
    mono = x if x.ndim == 1 else x.mean(axis=1)
    out = []
    for channel in range(1 if x.ndim == 1 else 2):
        spread = channel * _STEREO_SPREAD
        wet = np.zeros(len(mono))
        for d in _COMBS:
            delay = d + spread
            wet += _comb(mono, delay, 10 ** (-3 * delay / (seconds * SR)))
        wet /= len(_COMBS)
        for d in _ALLPASSES:
            wet = _allpass(wet, d + spread, 0.5)
        out.append(fft_filter(wet, lowpass_response(damping_hz, order=1)))
    return out[0] if x.ndim == 1 else np.column_stack(out)


def fft_filter(x, response, pad_seconds=1.0):
    """Linear (not circular) filtering through the spectrum: padded so nothing
    wraps round. For long signals where a per-sample loop would be slow."""
    pad = samples(pad_seconds)
    padded = np.concatenate([x, np.zeros((pad,) + x.shape[1:])])
    return circular_filter(padded, response)[:x.shape[0]]


def pan(mono, position):
    """Mono to stereo, equal power: position -1 is hard left, 0 centre, 1 hard right."""
    angle = (position + 1) * np.pi / 4
    return np.column_stack([mono * math.cos(angle), mono * math.sin(angle)])


def _magnitude(b, a, freqs):
    """|H| of a biquad at each frequency, from its coefficients."""
    z1 = np.exp(-1j * 2 * np.pi * freqs / SR)
    z2 = z1 * z1
    return np.abs((b[0] + b[1] * z1 + b[2] * z2) / (a[0] + a[1] * z1 + a[2] * z2))


def k_response(freqs):
    """The K-weighting's gain at each frequency: the same two filters as k_weight(),
    evaluated from their equations instead of run sample by sample."""
    a_gain = 10 ** (3.99984385397 / 40)
    cos_w, alpha = _coefficients(1681.974450955533, 0.7071752369554193)
    root = 2 * math.sqrt(a_gain) * alpha
    shelf = _magnitude(
        (a_gain * ((a_gain + 1) + (a_gain - 1) * cos_w + root),
         -2 * a_gain * ((a_gain - 1) + (a_gain + 1) * cos_w),
         a_gain * ((a_gain + 1) + (a_gain - 1) * cos_w - root)),
        ((a_gain + 1) - (a_gain - 1) * cos_w + root,
         2 * ((a_gain - 1) - (a_gain + 1) * cos_w),
         (a_gain + 1) - (a_gain - 1) * cos_w - root), freqs)
    cos_w, alpha = _coefficients(38.13547087613982, 0.5003270373253953)
    high = _magnitude(((1 + cos_w) / 2, -(1 + cos_w), (1 + cos_w) / 2),
                      (1 + alpha, -2 * cos_w, 1 - alpha), freqs)
    return shelf * high


def loudness_integrated_db(x, looped=False):
    """How loud a stream is overall, as heard: BS.1770's K-weighted mean square,
    summed over channels, in dB. Computed on the spectrum (a mean square is the
    same there), so a minute of stereo takes a moment. A loop is weighted as the
    circle it is; anything else is padded, so its end does not feed its start."""
    signal = x if looped else np.concatenate([x, np.zeros((samples(1.0),) + x.shape[1:])])
    spectrum = np.fft.rfft(signal, axis=0)
    gain = k_response(np.fft.rfftfreq(signal.shape[0], 1 / SR))
    weighted = np.fft.irfft(spectrum * (gain[:, None] if signal.ndim == 2 else gain),
                            n=signal.shape[0], axis=0)
    energy = float(np.sum(np.square(weighted))) / x.shape[0]
    return 10 * math.log10(energy) if energy > 0 else -math.inf


# --- filters (RBJ audio-EQ cookbook biquads, direct form I) -----------------

def _biquad(x, b0, b1, b2, a0, a1, a2):
    b0, b1, b2, a1, a2 = b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0
    y = np.empty(len(x))
    x1 = x2 = y1 = y2 = 0.0
    for i, xi in enumerate(x):
        yi = b0 * xi + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1 = x1, xi
        y2, y1 = y1, yi
        y[i] = yi
    return y


def _coefficients(freq, q):
    w0 = 2 * np.pi * min(freq, SR * 0.49) / SR
    return math.cos(w0), math.sin(w0) / (2 * q)


def lowpass(x, freq, q=0.707):
    cos_w, alpha = _coefficients(freq, q)
    return _biquad(x, (1 - cos_w) / 2, 1 - cos_w, (1 - cos_w) / 2, 1 + alpha, -2 * cos_w, 1 - alpha)


def highpass(x, freq, q=0.707):
    cos_w, alpha = _coefficients(freq, q)
    return _biquad(x, (1 + cos_w) / 2, -(1 + cos_w), (1 + cos_w) / 2, 1 + alpha, -2 * cos_w, 1 - alpha)


def bandpass(x, freq, q=1.0):
    """Constant 0 dB peak gain."""
    cos_w, alpha = _coefficients(freq, q)
    return _biquad(x, alpha, 0.0, -alpha, 1 + alpha, -2 * cos_w, 1 - alpha)


def swept_bandpass(x, freqs, q=1.0):
    """A band-pass whose centre follows `freqs`, one value per sample (a Chamberlin
    state-variable filter, which tolerates its coefficients moving every sample).
    For whooshes: noise through a band that slides."""
    damp = 1.0 / q
    low = band = 0.0
    y = np.empty(len(x))
    for i, xi in enumerate(x):
        f = 2.0 * math.sin(math.pi * min(freqs[i], SR / 6) / SR)
        low += f * band
        high = xi - low - damp * band
        band += f * high
        y[i] = band
    return y


def one_pole_lowpass(x, freq):
    """A gentle 6 dB/octave smoother, for control signals as much as audio."""
    a = 1.0 - math.exp(-2 * np.pi * freq / SR)
    y = np.empty(len(x))
    state = 0.0
    for i, xi in enumerate(x):
        state += a * (xi - state)
        y[i] = state
    return y


# --- colour -----------------------------------------------------------------

def saturate(x, drive):
    """Soft clipping: more drive, more grit. Normalised so full scale stays full scale."""
    if drive <= 0:
        return x
    return np.tanh(drive * x) / math.tanh(drive)


def lofi(x, hold_rate=18000, bits=10, cutoff=8500):
    """The "crunchy lo-fi" stage every sound goes through.

    Sample-and-hold down to `hold_rate` (the aliasing is the crunch), quantise
    to `bits` (a grain in the quiet tails), then a low-pass at `cutoff` so the
    result is warm rather than fizzy. Starting values, tuned by ear.
    """
    n = len(x)
    step = SR / hold_rate
    held = x[np.minimum((np.floor(np.arange(n) / step) * step).astype(int), n - 1)]
    levels = 2 ** (bits - 1)
    crushed = np.round(held * levels) / levels
    return lowpass(crushed, cutoff)


# --- finishing --------------------------------------------------------------

def rms_db(x):
    value = math.sqrt(float(np.mean(np.square(x)))) if len(x) else 0.0
    return 20 * math.log10(value) if value > 0 else -math.inf


def high_shelf(x, freq, gain_db, q):
    """RBJ high shelf."""
    a = 10 ** (gain_db / 40)
    cos_w, alpha = _coefficients(freq, q)
    root = 2 * math.sqrt(a) * alpha
    return _biquad(x,
                   a * ((a + 1) + (a - 1) * cos_w + root),
                   -2 * a * ((a - 1) + (a + 1) * cos_w),
                   a * ((a + 1) + (a - 1) * cos_w - root),
                   (a + 1) - (a - 1) * cos_w + root,
                   2 * ((a - 1) - (a + 1) * cos_w),
                   (a + 1) - (a - 1) * cos_w - root)


def k_weight(x):
    """ITU-R BS.1770's K-weighting: how much of a signal's energy the ear counts as
    loudness. A shelf lifts everything above ~1.7 kHz by 4 dB and a high-pass takes
    out the deep bass, the range a small speaker cannot play and an ear barely
    weighs. Parameters as pyloudnorm derives them for any sample rate.

    Plain RMS scored a sub-bass thud as loud as a mid-range hit of the same energy;
    in round 1 that thud was all but inaudible."""
    x = high_shelf(x, 1681.974450955533, 3.99984385397, 0.7071752369554193)
    return highpass(x, 38.13547087613982, 0.5003270373253953)


def loudness_db(x, window=0.05, hop=0.005):
    """How loud a sound is heard: the loudest 50 ms of its K-weighted signal, in dB.
    Short effects are judged by their peak moment, not their average, so a long
    quiet tail doesn't make a sound measure quieter than it is heard."""
    k = k_weight(x)
    w, h = samples(window), samples(hop)
    if len(k) <= w:
        return rms_db(k)
    best = 0.0
    for start in range(0, len(k) - w + 1, h):
        best = max(best, float(np.mean(np.square(k[start:start + w]))))
    return 10 * math.log10(best) if best > 0 else -math.inf


def peak_db(x):
    peak = float(np.max(np.abs(x))) if len(x) else 0.0
    return 20 * math.log10(peak) if peak > 0 else -math.inf


def fade_tail(x, seconds=0.01):
    """A raised-cosine fade over the last `seconds`, so every file ends in silence."""
    n = min(len(x), samples(seconds))
    if n > 0:
        x = x.copy()
        x[-n:] *= 0.5 * (1 + np.cos(np.linspace(0, np.pi, n)))
    return x


def finish(x, target_db, ceiling_db=-1.0, lofi_args=None):
    """Everything between a raw recipe and a shippable file.

    Brings the sound to its target loudness, puts it through the lo-fi stage at
    that level (so the bit depth means what it says), corrects the level again,
    removes DC, keeps the peak under the ceiling with a soft limiter, and fades
    the tail to silence.
    """
    x = x - np.mean(x)
    x = x * 10 ** ((target_db - loudness_db(x)) / 20)
    x = lofi(x, **(lofi_args or {}))
    x = highpass(x, 25.0)
    ceiling = 10 ** (ceiling_db / 20)
    for _ in range(6):
        x = x * 10 ** ((target_db - loudness_db(x)) / 20)
        if np.max(np.abs(x)) <= ceiling:
            break
        # Soft-limit only what exceeds the ceiling's knee, then re-level.
        knee = ceiling * 0.7
        over = np.abs(x) > knee
        x[over] = np.sign(x[over]) * (knee + (ceiling - knee) * np.tanh((np.abs(x[over]) - knee) / (ceiling - knee)))
    x = fade_tail(x)
    peak = np.max(np.abs(x))
    if peak > ceiling:
        x = x * (ceiling / peak)
    return x


def to_pcm16(x):
    """Float to little-endian 16-bit PCM bytes, no dither (so renders are byte-identical)."""
    return np.clip(np.round(x * 32767.0), -32768, 32767).astype("<i2").tobytes()
