# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name AudioSynth
extends RefCounted
## Small synthesis helpers shared by every sound: decaying sine partials,
## pitch sweeps, soft noise, and the step that turns samples into a stream.
## Pure functions of their inputs. No randomness except seeded noise, so the
## same call always gives the same samples. Safe to run on a worker thread.

## Effects are short, so they get a clean rate.
const EFFECT_RATE: int = 22050
## The music is long. The lower rate keeps it quick to build and warm to hear.
const MUSIC_RATE: int = 16000
## A decay stops being worth computing once it falls to exp(-6.2), about 0.2 percent.
const SILENCE: float = 6.2
## Peak a stream may reach, as a fraction of full scale. Louder is scaled down.
const CEILING: float = 0.9


## An empty (silent) buffer of this many seconds.
static func buffer(seconds: float, rate: int) -> PackedFloat32Array:
	var buf: PackedFloat32Array = PackedFloat32Array()
	buf.resize(int(seconds * float(rate)))
	return buf


## Frequency in Hz of a MIDI note number.
static func hz(midi: int) -> float:
	return 440.0 * pow(2.0, float(midi - 69) / 12.0)


## Adds one sine partial with a fast attack and an exponential decay.
## attack_rate is how fast the level climbs to full (1 / seconds). When wrap
## is true the partial wraps around the buffer's end, for seamless loops.
## It stops once the decay is inaudible or after max_seconds, with a 4 ms taper.
static func partial(buf: PackedFloat32Array, rate: int, start: float, max_seconds: float, freq: float, amp: float, decay: float, attack_rate: float, wrap: bool) -> void:
	var total: int = buf.size()
	var s0: int = int(start * float(rate))
	var span: float = max_seconds
	if decay > 0.0:
		span = minf(span, SILENCE / decay)
	var n: int = int(span * float(rate))
	if not wrap:
		n = mini(n, total - s0)
	if n <= 0 or total == 0:
		return
	# A rotating phasor gives the sine with no sin() call per sample.
	var w: float = TAU * freq / float(rate)
	var cw: float = cos(w)
	var sw: float = sin(w)
	var c: float = 1.0
	var s: float = 0.0
	var k: float = exp(-decay / float(rate))
	var env: float = amp
	var ramp: float = 0.0
	var ramp_step: float = attack_rate / float(rate)
	var taper: int = mini(n, int(0.004 * float(rate)))
	var taper_from: int = n - taper
	var inv_taper: float = 1.0 / float(maxi(taper, 1))
	var idx: int = s0 % total
	for i: int in n:
		var g: float = s * env * ramp
		if i >= taper_from:
			g *= float(n - i) * inv_taper
		buf[idx] += g
		idx += 1
		if idx == total:
			idx = 0
		env *= k
		if ramp < 1.0:
			ramp = minf(1.0, ramp + ramp_step)
		var next_s: float = s * cw + c * sw
		c = c * cw - s * sw
		s = next_s


## A small bell: the note plus an inharmonic overtone that dies twice as fast.
static func bell(buf: PackedFloat32Array, rate: int, start: float, freq: float, amp: float, decay: float) -> void:
	var left: float = float(buf.size()) / float(rate) - start
	partial(buf, rate, start, left, freq, amp, decay, 400.0, false)
	partial(buf, rate, start, left, freq * 2.76, amp * 0.4, decay * 2.0, 400.0, false)


## The lullaby voice: a music box note with a soft second and third partial.
static func music_box(buf: PackedFloat32Array, rate: int, start: float, freq: float, amp: float, wrap: bool) -> void:
	var left: float = 1.4
	if not wrap:
		left = minf(left, float(buf.size()) / float(rate) - start)
	partial(buf, rate, start, left, freq, amp, 3.2, 300.0, wrap)
	partial(buf, rate, start, left, freq * 2.0, amp * 0.3, 9.2, 300.0, wrap)
	partial(buf, rate, start, left, freq * 3.01, amp * 0.12, 13.2, 300.0, wrap)


## A soft plucked chord tone.
static func pluck(buf: PackedFloat32Array, rate: int, start: float, freq: float, amp: float, wrap: bool) -> void:
	partial(buf, rate, start, 0.5, freq, amp, 6.0, 200.0, wrap)
	partial(buf, rate, start, 0.5, freq * 2.0, amp * 0.25, 6.0, 200.0, wrap)


## A round bass note. The upper partials keep it audible on a phone speaker.
static func bass(buf: PackedFloat32Array, rate: int, start: float, freq: float, amp: float, wrap: bool) -> void:
	partial(buf, rate, start, 2.3, freq, amp, 2.0, 120.0, wrap)
	partial(buf, rate, start, 2.3, freq * 2.0, amp * 0.6, 2.0, 120.0, wrap)
	partial(buf, rate, start, 2.3, freq * 3.0, amp * 0.25, 2.0, 120.0, wrap)


## A sine that glides from f0 to f1 over duration seconds, with an exponential decay.
static func sweep(buf: PackedFloat32Array, rate: int, start: float, duration: float, f0: float, f1: float, amp: float, decay: float) -> void:
	var s0: int = int(start * float(rate))
	var n: int = mini(int(duration * float(rate)), buf.size() - s0)
	if n <= 0:
		return
	var phase: float = 0.0
	var env: float = amp
	var k: float = exp(-decay / float(rate))
	for i: int in n:
		buf[s0 + i] += sin(phase) * env
		phase += TAU * lerpf(f0, f1, float(i) / float(n)) / float(rate)
		env *= k


## A soft burst of noise that fades out. Higher smooth values keep more highs;
## low values are a duller breath. The seed makes it repeat exactly.
static func noise(buf: PackedFloat32Array, rate: int, start: float, length: float, amp: float, smooth: float, seed_value: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var s0: int = int(start * float(rate))
	var n: int = mini(int(length * float(rate)), buf.size() - s0)
	var last: float = 0.0
	for i: int in n:
		var t: float = float(i) / float(n)
		last = lerpf(last, rng.randf_range(-1.0, 1.0), smooth)
		buf[s0 + i] += last * amp * (1.0 - t) * minf(1.0, float(i) / 40.0)


## Largest absolute sample value.
static func peak_of(samples: PackedFloat32Array) -> float:
	var peak: float = 0.0
	for v: float in samples:
		peak = maxf(peak, absf(v))
	return peak


## Turns samples into a mono 16 bit stream. A peak above CEILING is scaled down
## so nothing clips. One shots get a 3 ms fade at the end so they never click.
## A loop covers the whole buffer. Godot's mixer plays the loop_end frame too
## before it wraps, so a loop gets one extra frame, a copy of frame 0, and
## never reads past the end of its data.
static func to_stream(samples: PackedFloat32Array, rate: int, loop: bool) -> AudioStreamWAV:
	var n: int = samples.size()
	var peak: float = peak_of(samples)
	var gain: float = CEILING / peak if peak > CEILING else 1.0
	var fade: int = 0 if loop else mini(n, int(0.003 * float(rate)))
	var frames: int = n + 1 if loop and n > 0 else n
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(frames * 2)
	for i: int in frames:
		var v: float = samples[i % n] * gain
		if fade > 0 and i >= n - fade:
			v *= float(n - i) / float(fade)
		bytes.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = n
	return wav
