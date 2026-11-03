class_name SfxSynth
extends RefCounted
## Procedural audio: every sound effect and the music loop are synthesized at startup.

const MIX_RATE := 22050


static func _sample(wave: String, phase: float, rng: RandomNumberGenerator) -> float:
	match wave:
		"sine": return sin(phase * TAU)
		"square": return 1.0 if phase < 0.5 else -1.0
		"saw": return phase * 2.0 - 1.0
		"tri": return 4.0 * absf(phase - 0.5) - 1.0
		_: return rng.randf_range(-1.0, 1.0)


## Renders one note into 16-bit PCM bytes.
static func render(wave: String, f0: float, f1: float, duration: float, volume: float = 0.5,
		attack: float = 0.004, noise_mix: float = 0.0, cutoff: float = 1.0) -> PackedByteArray:
	var n := maxi(1, int(duration * MIX_RATE))
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(f0 * 31.0 + duration * 1000.0)
	var phase := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / MIX_RATE
		var k := float(i) / n
		var f := lerpf(f0, f1, k)
		phase = fmod(phase + f / MIX_RATE, 1.0)
		var s := _sample(wave, phase, rng)
		if noise_mix > 0.0:
			s = lerpf(s, rng.randf_range(-1.0, 1.0), noise_mix)
		lp += (s - lp) * cutoff
		var env := minf(1.0, t / attack) * (1.0 - k) * (1.0 - k)
		data.encode_s16(i * 2, int(clampf(lp * env * volume, -1.0, 1.0) * 32767.0))
	return data


static func to_stream(data: PackedByteArray, loop: bool = false) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = MIX_RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = data.size() / 2
	return w


static func tone(wave: String, f0: float, f1: float, duration: float, volume: float = 0.5,
		attack: float = 0.004, noise_mix: float = 0.0, cutoff: float = 1.0) -> AudioStreamWAV:
	return to_stream(render(wave, f0, f1, duration, volume, attack, noise_mix, cutoff))


static func arpeggio(freqs: Array, note_len: float, wave: String = "square", volume: float = 0.3) -> AudioStreamWAV:
	var data := PackedByteArray()
	for f in freqs:
		data.append_array(render(wave, f, f, note_len, volume))
	return to_stream(data)


static func build_library() -> Dictionary:
	return {
		&"shoot": tone("square", 920.0, 520.0, 0.06, 0.18, 0.002, 0.0, 0.5),
		&"enemy_shoot": tone("saw", 520.0, 300.0, 0.09, 0.18, 0.002, 0.0, 0.4),
		&"hit": tone("noise", 0.0, 0.0, 0.05, 0.35, 0.001, 0.0, 0.5),
		&"crit": tone("square", 1500.0, 900.0, 0.08, 0.25),
		&"kill": tone("tri", 400.0, 140.0, 0.14, 0.4, 0.002, 0.25),
		&"explode": tone("noise", 0.0, 0.0, 0.55, 0.7, 0.002, 0.0, 0.08),
		&"pickup": tone("sine", 900.0, 1500.0, 0.07, 0.3),
		&"coin": arpeggio([1318.5, 1975.5], 0.05, "square", 0.18),
		&"heal": arpeggio([523.3, 659.3, 784.0], 0.06, "sine", 0.35),
		&"hurt": tone("saw", 320.0, 80.0, 0.22, 0.45, 0.002, 0.35, 0.4),
		&"dash": tone("noise", 0.0, 0.0, 0.14, 0.25, 0.01, 0.0, 0.2),
		&"ability": tone("saw", 180.0, 900.0, 0.28, 0.35, 0.01, 0.1, 0.35),
		&"level_up": arpeggio([523.3, 659.3, 784.0, 1046.5], 0.07, "square", 0.25),
		&"wave": arpeggio([392.0, 523.3, 784.0], 0.09, "tri", 0.4),
		&"boss": tone("saw", 90.0, 45.0, 1.3, 0.55, 0.08, 0.2, 0.15),
		&"achievement": arpeggio([784.0, 987.8, 1174.7, 1568.0], 0.08, "tri", 0.4),
		&"ui_hover": tone("sine", 1500.0, 1700.0, 0.03, 0.15),
		&"ui_click": tone("square", 760.0, 520.0, 0.05, 0.2, 0.002, 0.0, 0.5),
		&"ui_back": tone("square", 520.0, 360.0, 0.06, 0.2, 0.002, 0.0, 0.5),
		&"error": tone("square", 180.0, 160.0, 0.14, 0.25),
	}


## A 16-step synthwave loop: saw bass + triangle arpeggio + noise hats.
static func build_music(bars: int = 4, bpm: float = 112.0) -> AudioStreamWAV:
	var step_len := 60.0 / bpm / 4.0
	var steps := bars * 16
	var per_step := int(step_len * MIX_RATE)
	var n := steps * per_step
	var mix := PackedFloat32Array()
	mix.resize(n)
	var roots := [55.0, 43.65, 65.41, 49.0]  # A1, F1, C2, G1
	var arp := [1.0, 1.5, 2.0, 2.5198, 2.0, 1.5]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for s in steps:
		var root: float = roots[(s / 16) % roots.size()]
		var start := s * per_step
		var bass_f := root * (2.0 if s % 4 == 2 else 1.0)
		var arp_f: float = root * 4.0 * arp[s % arp.size()]
		var phase_b := 0.0
		var phase_a := 0.0
		var lp := 0.0
		for i in per_step:
			var k := float(i) / per_step
			phase_b = fmod(phase_b + bass_f / MIX_RATE, 1.0)
			phase_a = fmod(phase_a + arp_f / MIX_RATE, 1.0)
			lp += ((phase_b * 2.0 - 1.0) - lp) * 0.12
			var v := lp * 0.32 * (1.0 - k * 0.6)
			v += (4.0 * absf(phase_a - 0.5) - 1.0) * 0.12 * (1.0 - k)
			if s % 2 == 1 and k < 0.25:
				v += rng.randf_range(-1.0, 1.0) * 0.05 * (1.0 - k * 4.0)
			if s % 4 == 0 and k < 0.5:
				v += sin(TAU * (60.0 - 30.0 * k) * (float(i) / MIX_RATE)) * 0.35 * (1.0 - k * 2.0)
			mix[start + i] = v
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(clampf(mix[i], -1.0, 1.0) * 32767.0))
	return to_stream(data, true)
