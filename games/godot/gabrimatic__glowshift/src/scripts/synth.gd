class_name Synth
extends RefCounted
## Builds every sound in the game from math at startup. No audio files.

const SFX_RATE := 22050
const MUSIC_RATE := 16000
const BPM := 112.0

# One chord per bar: A minor, F, C, G. Bass roots, then arpeggio tones.
const BASS := [110.0, 87.31, 130.81, 98.0]
const CHORDS := [
	[440.0, 523.25, 659.25],
	[349.23, 440.0, 523.25],
	[392.0, 523.25, 659.25],
	[392.0, 493.88, 587.33],
]
const ARP_PATTERN := [0, 1, 2, 1, 0, 2, 1, 2]


static func effects() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	return {
		"pickup": _sweep(rng, 0.11, 880.0, 1760.0, 0.0, false, 1.5),
		"dash": _sweep(rng, 0.16, 420.0, 120.0, 0.85, false, 2.0),
		"kill": _sweep(rng, 0.24, 240.0, 50.0, 0.55, true, 1.8),
		"death": _sweep(rng, 0.95, 130.0, 28.0, 0.5, false, 1.2),
		"power": _sweep(rng, 0.3, 500.0, 1500.0, 0.0, true, 1.0),
		"level": _sweep(rng, 0.5, 660.0, 990.0, 0.0, false, 1.0),
		"shield": _sweep(rng, 0.22, 300.0, 900.0, 0.3, false, 1.5),
		"dart": _sweep(rng, 0.12, 1400.0, 700.0, 0.2, true, 2.0),
		"graze": _sweep(rng, 0.07, 2200.0, 2600.0, 0.1, false, 2.5),
	}


## Builds the four-bar synthwave loop (kick, offbeat hats, plucked bass, arpeggio,
## pad) a slice at a time, so it never stalls a frame. Web builds have no threads.
class MusicBuilder:
	var rng := RandomNumberGenerator.new()
	var buf := PackedByteArray()
	var n := 0
	var i := 0
	var beat := 60.0 / BPM
	var bar_len := beat * 4.0
	var sixteenth := beat / 4.0
	var eighth := beat / 2.0

	func _init() -> void:
		rng.seed = 11
		n = int(bar_len * BASS.size() * MUSIC_RATE)
		buf.resize(n * 2)

	func done() -> bool:
		return i >= n

	## Synthesizes samples until `budget_usec` microseconds have passed.
	func step(budget_usec: int) -> void:
		var stop_at := Time.get_ticks_usec() + budget_usec
		while i < n:
			for _k in 256:
				if i >= n:
					break
				buf.encode_s16(i * 2, int(_sample(float(i) / MUSIC_RATE) * 30000.0))
				i += 1
			if Time.get_ticks_usec() >= stop_at:
				return

	func stream() -> AudioStreamWAV:
		var s := AudioStreamWAV.new()
		s.format = AudioStreamWAV.FORMAT_16_BITS
		s.mix_rate = MUSIC_RATE
		s.data = buf
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = n
		return s

	func _sample(t: float) -> float:
		var bar := int(t / bar_len) % BASS.size()
		var chord: Array = CHORDS[bar]
		var root: float = BASS[bar]

		var kt := fmod(t, beat)
		var kick := sin(TAU * (50.0 * kt + 100.0 * (1.0 - exp(-kt * 30.0)) / 30.0)) * exp(-kt * 12.0) * 0.55

		var ht := fmod(t + eighth, beat)
		var hat := rng.randf_range(-1.0, 1.0) * maxf(0.0, 1.0 - ht / 0.035) * 0.07

		var bt := fmod(t, eighth)
		var bass := 2.0 / PI * asin(sin(TAU * root * t)) * exp(-bt * 5.0) * 0.32

		var step_i := int(t / sixteenth) % ARP_PATTERN.size()
		var at := fmod(t, sixteenth)
		var arp_f: float = chord[ARP_PATTERN[step_i]]
		var arp := signf(sin(TAU * arp_f * t)) * exp(-at * 22.0) * 0.07

		var pad := 0.0
		for f: float in chord:
			pad += sin(TAU * f * 0.5 * t) + 0.5 * sin(TAU * f * 0.502 * t)
		pad *= 0.022 * minf(1.0, fmod(t, bar_len) * 2.0)

		var v := kick + hat + bass + arp + pad
		return v / (1.0 + absf(v))  # soft clip


static func _sweep(rng: RandomNumberGenerator, dur: float, f0: float, f1: float, noise: float, square: bool, decay: float) -> AudioStreamWAV:
	var n := int(dur * SFX_RATE)
	var buf := PackedByteArray()
	buf.resize(n * 2)
	var phase := 0.0
	for i in n:
		var p := float(i) / n
		phase += TAU * lerpf(f0, f1, p) / SFX_RATE
		var v := sin(phase)
		if square:
			v = signf(v) * 0.5
		v = v * (1.0 - noise) + rng.randf_range(-1.0, 1.0) * noise
		var env := pow(1.0 - p, decay) * minf(1.0, i / 80.0)
		buf.encode_s16(i * 2, int(clampf(v * env, -1.0, 1.0) * 30000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = SFX_RATE
	s.data = buf
	return s
