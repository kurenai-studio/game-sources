extends RefCounted

const SAMPLE_RATE := 44100
const AMPLITUDE := 0.30
const ATTACK := 0.006
const RELEASE := 0.05

## Each note is [frequency_hz, duration_seconds, decay_rate].
const COIN := [[987.77, 0.085, 0.0], [1318.51, 0.55, 3.4]]
const FANFARE := [
	[523.25, 0.085, 0.0],
	[659.25, 0.085, 0.0],
	[783.99, 0.085, 0.0],
	[1046.50, 0.085, 0.0],
	[1318.51, 0.085, 0.0],
	[1567.98, 0.70, 2.6],
]


const BLIP_DURATION := 0.07
const BLIP_ATTACK := 0.004
const BLIP_RELEASE := 0.035
const BLIP_AMPLITUDE := 0.22


static func coin() -> AudioStreamWAV:
	return build(COIN)


static func fanfare() -> AudioStreamWAV:
	return build(FANFARE)


static func blip(frequency: float = 880.0) -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * BLIP_DURATION)
	var data := PackedByteArray()
	data.resize(count * 2)
	var step := TAU * frequency / SAMPLE_RATE
	var phase := 0.0
	for i in count:
		var t := float(i) / SAMPLE_RATE
		phase = fmod(phase + step, TAU)
		var gain := 1.0
		if t < BLIP_ATTACK:
			gain = t / BLIP_ATTACK
		var remaining := BLIP_DURATION - t
		if remaining < BLIP_RELEASE:
			gain *= maxf(remaining, 0.0) / BLIP_RELEASE
		var level := sin(phase) * BLIP_AMPLITUDE * gain
		data.encode_s16(i * 2, int(clampf(level, -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream


static func build(notes: Array) -> AudioStreamWAV:
	var total := 0
	for note in notes:
		total += int(SAMPLE_RATE * float(note[1]))

	var data := PackedByteArray()
	data.resize(total * 2)

	var cursor := 0
	var phase := 0.0
	for note in notes:
		var frequency: float = note[0]
		var duration: float = note[1]
		var decay: float = note[2]
		var count := int(SAMPLE_RATE * duration)
		var step := TAU * frequency / SAMPLE_RATE
		for i in count:
			var t := float(i) / SAMPLE_RATE
			phase = fmod(phase + step, TAU)
			var wave := 1.0 if phase < PI * 0.6 else -1.0
			var level := wave * AMPLITUDE * _envelope(t, duration) * exp(-t * decay)
			data.encode_s16(cursor * 2, int(clampf(level, -1.0, 1.0) * 32767.0))
			cursor += 1

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream


static func _envelope(t: float, duration: float) -> float:
	var gain := 1.0
	if t < ATTACK:
		gain = t / ATTACK
	var remaining := duration - t
	if remaining < RELEASE:
		gain *= maxf(remaining, 0.0) / RELEASE
	return gain
