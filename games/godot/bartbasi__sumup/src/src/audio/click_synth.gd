class_name ClickSynth extends RefCounted
## Builds the click sound in code (docs/BRIEF.md section 4, docs/ARCHITECTURE.md
## section 9). There are no audio files.
##
## The click is a short, high, bell-like tap: three harmonic partials on an E6
## fundamental. The upper partials fade first, so the start is bright and the
## tail settles into a clean tone. The pitch lifts by about a semitone during
## the attack, which makes it sound like an upward, positive tap.
## A raised cosine attack keeps the start soft, an exponential decay keeps it
## short, and a raised cosine fade brings the last sample to exactly zero.

## Total length of the click, seconds.
const LENGTH_SEC: float = 0.065
## Rise from silence to full level, seconds.
const ATTACK_SEC: float = 0.003
## Fade at the very end that lands on zero, seconds.
const FADE_SEC: float = 0.010
## Fundamental after the lift, Hz (E6).
const PITCH_HZ: float = 1318.5
## Pitch at the first sample as a ratio of PITCH_HZ, about a semitone below.
const LIFT_FROM: float = 0.944
## How long the pitch takes to lift, seconds.
const LIFT_SEC: float = 0.012
## Harmonic number, relative level and decay time constant of each partial.
const HARMONICS: PackedFloat32Array = [1.0, 2.0, 3.0]
const LEVELS: PackedFloat32Array = [1.0, 0.35, 0.12]
const DECAYS_SEC: PackedFloat32Array = [0.012, 0.007, 0.004]
## Highest sample level, dBFS. AudioService lets at most two clicks sound at
## once, and two clicks that start on the same sample add up to about -2 dBFS,
## still below the -1 dBFS ceiling.
const PEAK_DBFS: float = -8.0

const DEFAULT_MIX_RATE: int = 44100
const MIN_MIX_RATE: int = 8000
const MAX_MIX_RATE: int = 192000
const FULL_SCALE: float = 32767.0


## The click as a 16 bit mono one shot at mix_rate samples per second.
static func build(mix_rate: int = DEFAULT_MIX_RATE) -> AudioStreamWAV:
	var rate: int = mix_rate
	if rate < MIN_MIX_RATE or rate > MAX_MIX_RATE:
		push_error("ClickSynth.build: mix rate %d is outside %d to %d, using %d" % [mix_rate, MIN_MIX_RATE, MAX_MIX_RATE, DEFAULT_MIX_RATE])
		rate = DEFAULT_MIX_RATE
	var wave: PackedFloat64Array = _render(rate)
	var loudest: float = 0.0
	for value: float in wave:
		loudest = maxf(loudest, absf(value))
	var gain: float = db_to_linear(PEAK_DBFS) * FULL_SCALE / loudest
	var data: PackedByteArray = PackedByteArray()
	data.resize(wave.size() * 2)
	for n: int in wave.size():
		data.encode_s16(n * 2, roundi(wave[n] * gain))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = data
	return stream


## The click before scaling, one value per sample.
static func _render(rate: int) -> PackedFloat64Array:
	var count: int = roundi(LENGTH_SEC * rate)
	var fade_start: int = count - roundi(FADE_SEC * rate)
	var fade_span: float = float(count - 1 - fade_start)
	var wave: PackedFloat64Array = PackedFloat64Array()
	wave.resize(count)
	var phase: float = 0.0
	for n: int in count:
		var t: float = float(n) / rate
		var level: float = 1.0
		if t < ATTACK_SEC:
			level = sin(0.5 * PI * t / ATTACK_SEC) ** 2
		if n > fade_start:
			level *= cos(0.5 * PI * float(n - fade_start) / fade_span) ** 2
		var since_attack: float = maxf(0.0, t - ATTACK_SEC)
		var value: float = 0.0
		for k: int in HARMONICS.size():
			value += LEVELS[k] * exp(-since_attack / DECAYS_SEC[k]) * sin(HARMONICS[k] * phase)
		wave[n] = level * value
		var lift: float = minf(t / LIFT_SEC, 1.0)
		var ratio: float = LIFT_FROM + (1.0 - LIFT_FROM) * (1.0 - (1.0 - lift) * (1.0 - lift))
		phase += TAU * PITCH_HZ * ratio / rate
	return wave
