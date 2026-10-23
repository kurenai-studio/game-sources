class_name MusicKit
extends RefCounted
## The placeholder soundtrack, synthesized like the sound effects: chiptune and bitpop in D major,
## gamelan bronze answering the lead, and a rock layer for when a giant walks in. Every layer is
## the same loop of bars, so they all stay in step and the director can fade any in or out. A note
## that rings past the end of the loop wraps round to its start, so the loop has no seam.
##
## It stands in until real music is composed; the layers it makes are the ones real music fills.
##
## The village has its own, from the same instruments: slower, no drums, the bronze up front, the
## lead's melody played half as often and softly, as something remembered. The story's opening
## has its own too, slower still: a lone suling, the bamboo flute, over a soft pad and a gong.

const RATE := 22050
const TEMPO := 154.0
const BARS := 8
const LAYERS: Array[String] = ["drums", "bass", "chords", "lead", "gamelan", "rock"]
const VILLAGE_TEMPO := 92.0
const VILLAGE_LAYERS: Array[String] = ["village_bronze", "village_chords", "village_melody"]
## I, vi, IV, V: settled, homely.
const VILLAGE_CHORDS := [["D3", "F#3", "A3"], ["B2", "D3", "F#3"], ["G2", "B2", "D3"], ["A2", "C#3", "E3"]]
## The bronze's figure through each bar: degrees of pelog, two to a beat.
const VILLAGE_FIGURE := [0, 2, 4, 2, 3, 2, 0, 1]
## An area freed: warm, the run's melody whole, unhurried, on the suling, over angklung and bronze.
const FREED_TEMPO := 96.0
const FREED_LAYERS: Array[String] = ["freed_chords", "freed_melody"]
const INTRO_TEMPO := 72.0
const INTRO_LAYERS: Array[String] = ["intro_pad", "intro_suling"]
## The suling's tune, a note to a beat ("" rests), over D, then B minor, G, and A.
const INTRO_TUNE := [
	"A4", "", "B4", "D5", "", "", "B4", "", "A4", "", "F#4", "", "", "", "", "",
	"E4", "", "F#4", "A4", "", "B4", "A4", "", "F#4", "", "E4", "", "D4", "", "", "",
]

## I, V, vi, IV in D major: bright and heroic.
const CHORDS := [["D3", "F#3", "A3"], ["A2", "C#3", "E3"], ["B2", "D3", "F#3"], ["G2", "B2", "D3"]]
const LEAD := [
	"F#5", "", "A5", "B5", "A5", "", "F#5", "E5", "D5", "", "E5", "F#5", "E5", "", "C#5", "",
	"B4", "", "D5", "E5", "F#5", "", "A5", "", "G5", "F#5", "E5", "D5", "E5", "", "", "",
]
## Pelog, as cents above its first tone, for the bronze that answers the lead.
const PELOG := [0, 120, 270, 540, 670, 785, 950]
const ANSWER := [0, 2, 3, 2, 4, 3, 2, 0]

static var _random := RandomNumberGenerator.new()


static func beat(tempo := TEMPO) -> float:
	return 60.0 / tempo


static func loop_samples(tempo := TEMPO) -> int:
	return int(BARS * 4 * beat(tempo) * RATE)


## Every layer, as a looping stream. Slow enough to make that it belongs on a worker thread.
static func make_all() -> Dictionary:
	_random.seed = 39
	var layers := {}
	for layer in LAYERS:
		layers[layer] = make(layer)
	return layers


## The village's layers, as looping streams, all in step with each other.
static func make_village() -> Dictionary:
	_random.seed = 40
	var layers := {}
	var b := beat(VILLAGE_TEMPO)
	for layer in VILLAGE_LAYERS:
		var mix := PackedFloat32Array()
		mix.resize(loop_samples(VILLAGE_TEMPO))
		var notes := {}
		for bar in BARS:
			var chord: Array = VILLAGE_CHORDS[bar % 4]
			match layer:
				"village_bronze":
					# The figure on the low bronze, and the gong-like root under every second bar.
					for step in VILLAGE_FIGURE.size():
						var degree: int = VILLAGE_FIGURE[(step + bar) % VILLAGE_FIGURE.size()] + 7
						var pitch := 440.0 * pow(2.0, (PELOG[degree % 7] + 1200 * (degree / 7)) / 1200.0) / 2.0
						_place(mix, _cached(notes, "bronze%d" % degree, func() -> PackedFloat32Array: return _bronze(pitch)), (bar * 4) * b + step * b / 2.0, 0.22 if step % 2 == 0 else 0.14)
					if bar % 2 == 0:
						var root := _pitch(chord[0]) / 2.0
						_place(mix, _cached(notes, "gong%.1f" % root, func() -> PackedFloat32Array: return _bronze(root)), bar * 4 * b, 0.4)
				"village_chords":
					for name: String in chord:
						var pitch := _pitch(name) * 2.0
						_place(mix, _cached(notes, "angklung" + name, func() -> PackedFloat32Array: return _angklung(pitch, b * 3.8)), bar * 4 * b, 0.12)
					var low := _pitch(chord[0]) / 2.0
					_place(mix, _cached(notes, "low%.1f" % low, func() -> PackedFloat32Array: return _bass(low, b * 1.6)), bar * 4 * b, 0.22)
					_place(mix, _cached(notes, "low%.1f" % low, func() -> PackedFloat32Array: return _bass(low, b * 1.6)), (bar * 4 + 2) * b, 0.16)
				"village_melody":
					# The run's melody, every other note, held long: the same tune, at rest.
					if bar % 2 == 0:
						for step in range(0, 16, 2):
							var name: String = LEAD[(bar / 2 % 2) * 16 + step]
							if name.is_empty():
								continue
							var pitch := _pitch(name)
							_place(mix, _cached(notes, "soft%s" % name, func() -> PackedFloat32Array: return _chip_lead(pitch, b * 0.9)), (bar * 4) * b + step * b / 2.0, 0.08)
		layers[layer] = _to_loop(mix)
	return layers


## The opening's layers: the pad's chords breathing in and out under a gong, and the suling.
static func make_intro() -> Dictionary:
	_random.seed = 41
	var layers := {}
	var b := beat(INTRO_TEMPO)
	for layer in INTRO_LAYERS:
		var mix := PackedFloat32Array()
		mix.resize(loop_samples(INTRO_TEMPO))
		var notes := {}
		for bar in BARS:
			var chord: Array = VILLAGE_CHORDS[(bar / 2) % 4]
			match layer:
				"intro_pad":
					if bar % 2 == 0:
						for name: String in chord:
							var pitch := _pitch(name)
							_place(mix, _cached(notes, "pad" + name, func() -> PackedFloat32Array: return _pad(pitch, b * 8.0)), bar * 4 * b, 0.1)
						var root := _pitch(chord[0]) / 2.0
						_place(mix, _cached(notes, "gong%.1f" % root, func() -> PackedFloat32Array: return _bronze(root)), bar * 4 * b, 0.3)
				"intro_suling":
					if bar % 4 == 0:
						for step in 16:
							var name: String = INTRO_TUNE[(bar / 4 % 2) * 16 + step]
							if name.is_empty():
								continue
							# Held to the next note, as a flute breathes from one to the next.
							var length := 1
							while step + length < 16 and (INTRO_TUNE[(bar / 4 % 2) * 16 + step + length] as String).is_empty():
								length += 1
							var pitch := _pitch(name)
							_place(mix, _cached(notes, "suling%s%d" % [name, length], func() -> PackedFloat32Array: return _suling(pitch, b * length * 0.95)), (bar * 4 + step) * b, 0.16)
		layers[layer] = _to_loop(mix)
	return layers


## The freeing's layers: angklung chords with the bronze answering, and the melody on the suling.
static func make_freed() -> Dictionary:
	_random.seed = 42
	var layers := {}
	var b := beat(FREED_TEMPO)
	for layer in FREED_LAYERS:
		var mix := PackedFloat32Array()
		mix.resize(loop_samples(FREED_TEMPO))
		var notes := {}
		for bar in BARS:
			var chord: Array = CHORDS[bar % 4]
			match layer:
				"freed_chords":
					for name: String in chord:
						var pitch := _pitch(name) * 2.0
						_place(mix, _cached(notes, "angklung" + name, func() -> PackedFloat32Array: return _angklung(pitch, b * 3.8)), bar * 4 * b, 0.13)
					if bar % 2 == 1:
						for step in ANSWER.size():
							var degree: int = ANSWER[step] + 7
							var pitch := 440.0 * pow(2.0, (PELOG[degree % 7] + 1200 * (degree / 7)) / 1200.0)
							_place(mix, _cached(notes, "bronze%d" % degree, func() -> PackedFloat32Array: return _bronze(pitch)), (bar * 4) * b + step * b / 2.0, 0.18)
				"freed_melody":
					for step in 16:
						var name: String = LEAD[(bar % 2) * 16 + step]
						if name.is_empty() or step % 2 == 1:
							continue
						var pitch := _pitch(name)
						_place(mix, _cached(notes, "suling%s" % name, func() -> PackedFloat32Array: return _suling(pitch, b * 0.9)), (bar * 4) * b + step * b / 4.0 * 2.0, 0.14)
		layers[layer] = _to_loop(mix)
	return layers


static func make(layer: String) -> AudioStreamWAV:
	var mix := PackedFloat32Array()
	mix.resize(loop_samples())
	var b := beat()
	var notes := {}
	for bar in BARS:
		var chord: Array = CHORDS[bar % 4]
		for count in 4:
			var at := (bar * 4 + count) * b
			match layer:
				"drums":
					_place(mix, _cached(notes, "kick", func() -> PackedFloat32Array: return _kick()), at, 0.9)
					if count % 2 == 1:
						_place(mix, _cached(notes, "snare", func() -> PackedFloat32Array: return _noise_snare()), at, 0.6)
					for sixteenth in 4:
						_place(mix, _cached(notes, "hat", func() -> PackedFloat32Array: return _hat()), at + sixteenth * b / 4.0, 0.25 if sixteenth % 2 else 0.4)
					if count % 2 == 1:
						_place(mix, _cached(notes, "kentongan", func() -> PackedFloat32Array: return _kentongan()), at + b * 0.75, 0.3)
					if bar % 4 == 3 and count == 3:
						for sixteenth in 4:
							var hit := "dang" if sixteenth % 2 == 0 else "tak"
							_place(mix, _cached(notes, hit, func() -> PackedFloat32Array: return _kendang(hit == "dang")), at + sixteenth * b / 4.0, 0.5)
				"bass":
					# Syncopated, jumping octaves.
					for step: Array in [[0, 1.0], [2, 2.0], [3, 1.0]]:
						var pitch: float = _pitch(chord[0]) * step[1] / 2.0
						_place(mix, _cached(notes, "bass%.1f" % pitch, func() -> PackedFloat32Array: return _bass(pitch, b / 4.0 * 0.9)), at + step[0] * b / 4.0, 0.4)
				"chords":
					for name: String in chord:
						var pitch := _pitch(name) * 2.0
						if bar < 4:
							_place(mix, _cached(notes, "stab" + name, func() -> PackedFloat32Array: return _fm_stab(pitch, b * 0.3)), at + b / 2.0, 0.12)
						elif count == 0:
							_place(mix, _cached(notes, "angklung" + name, func() -> PackedFloat32Array: return _angklung(pitch, b * 3.8)), at, 0.14)
				"rock":
					if count in [0, 2]:
						_place(mix, _cached(notes, "kick", func() -> PackedFloat32Array: return _kick()), at + b / 2.0, 0.6)
					if count % 2 == 0:
						var root := _pitch(chord[0]) / 2.0
						_place(mix, _cached(notes, "power%.1f" % root, func() -> PackedFloat32Array: return _power_chord(root, b * 1.9)), at, 0.26)
		if layer == "lead":
			for step in 16:
				var name: String = LEAD[(bar % 2) * 16 + step]
				if name.is_empty():
					continue
				var length := b / 4.0 * (1.8 if step % 4 == 0 else 0.9)
				var pitch := _pitch(name)
				_place(mix, _cached(notes, "lead%s%.2f" % [name, length], func() -> PackedFloat32Array: return _chip_lead(pitch, length)), (bar * 4) * b + step * b / 4.0, 0.15)
		if layer == "gamelan" and bar % 2 == 1:
			# The bronze answers the lead in the bars it rests.
			for step in ANSWER.size():
				var degree: int = ANSWER[step] + 7
				var pitch := 440.0 * pow(2.0, (PELOG[degree % 7] + 1200 * (degree / 7)) / 1200.0)
				_place(mix, _cached(notes, "bronze%d" % degree, func() -> PackedFloat32Array: return _bronze(pitch)), (bar * 4) * b + step * b / 2.0, 0.28)
	return _to_loop(mix)


static func _cached(notes: Dictionary, key: String, make_note: Callable) -> PackedFloat32Array:
	if not notes.has(key):
		notes[key] = make_note.call()
	return notes[key]


## Adds a note into the loop, wrapping what runs past the end round to the start.
static func _place(mix: PackedFloat32Array, note: PackedFloat32Array, seconds: float, gain: float) -> void:
	var start := int(seconds * RATE)
	var length := mix.size()
	for index in note.size():
		mix[(start + index) % length] += note[index] * gain


static func _envelope(index: int, attack: float, decay: float) -> float:
	var time := float(index) / RATE
	return minf(time / attack, 1.0) * exp(-time / decay)


static func _samples(seconds: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(seconds * RATE))
	return samples


static func _kick() -> PackedFloat32Array:
	var samples := _samples(0.28)
	var phase := 0.0
	for index in samples.size():
		var time := float(index) / RATE
		phase += TAU * (50.0 + 115.0 * exp(-time / 0.03)) / RATE
		samples[index] = sin(phase) * _envelope(index, 0.001, 0.12)
	return samples


## The noise of an old sound chip: held in steps.
static func _noise_snare() -> PackedFloat32Array:
	var samples := _samples(0.18)
	var held := 0.0
	for index in samples.size():
		if index % 6 == 0:
			held = _random.randf_range(-1.0, 1.0)
		samples[index] = held * 0.7 * _envelope(index, 0.001, 0.06)
	return samples


static func _hat() -> PackedFloat32Array:
	var samples := _samples(0.03)
	var last := 0.0
	for index in samples.size():
		var noise := _random.randf_range(-1.0, 1.0)
		samples[index] = (noise - last) * 0.35 * _envelope(index, 0.0005, 0.012)
		last = noise
	return samples


## The bamboo slit drum: a hollow knock.
static func _kentongan() -> PackedFloat32Array:
	var samples := _samples(0.12)
	for index in samples.size():
		var time := float(index) / RATE
		samples[index] = (sin(TAU * 1150.0 * time) + 0.5 * sin(TAU * 2830.0 * time)) * _envelope(index, 0.0005, 0.025)
	return samples


static func _kendang(low: bool) -> PackedFloat32Array:
	var samples := _samples(0.25 if low else 0.1)
	var phase := 0.0
	for index in samples.size():
		var time := float(index) / RATE
		if low:
			phase += TAU * (95.0 + 60.0 * exp(-time / 0.02)) / RATE
			samples[index] = sin(phase) * _envelope(index, 0.001, 0.09)
		else:
			samples[index] = (0.5 * sin(TAU * 420.0 * time) + 0.4 * _random.randf_range(-1.0, 1.0)) * _envelope(index, 0.0005, 0.025)
	return samples


static func _bass(pitch: float, seconds: float) -> PackedFloat32Array:
	var samples := _samples(seconds)
	var level := 0.0
	var smoothing := exp(-TAU * 900.0 / RATE)
	for index in samples.size():
		var square := 1.0 if fmod(index * pitch / RATE, 1.0) < 0.5 else -1.0
		level = (1.0 - smoothing) * square + smoothing * level
		samples[index] = level * _envelope(index, 0.002, 0.07)
	return samples


## A staccato FM chord tone: a sine bent by another, bright, then gone.
static func _fm_stab(pitch: float, seconds: float) -> PackedFloat32Array:
	var samples := _samples(seconds)
	for index in samples.size():
		var time := float(index) / RATE
		var shape := _envelope(index, 0.001, 0.06)
		samples[index] = sin(TAU * pitch * time + 2.5 * shape * sin(TAU * pitch * 2.0 * time)) * shape
	return samples


## Bamboo tubes shaken in their frame: a hollow tone that rattles.
static func _angklung(pitch: float, seconds: float) -> PackedFloat32Array:
	var samples := _samples(seconds)
	for index in samples.size():
		var time := float(index) / RATE
		var rattle := 0.55 + 0.45 * signf(sin(TAU * 13.0 * time))
		samples[index] = (sin(TAU * pitch * time) + 0.3 * sin(TAU * pitch * 2.0 * time)) * rattle * _envelope(index, 0.01, seconds * 0.8)
	return samples


## The chiptune lead: a pulse wave with a fast vibrato that grows in.
static func _chip_lead(pitch: float, seconds: float) -> PackedFloat32Array:
	var samples := _samples(seconds)
	var phase := 0.0
	for index in samples.size():
		var time := float(index) / RATE
		phase = fmod(phase + pitch * (1.0 + 0.012 * sin(TAU * 7.0 * time) * minf(time / 0.08, 1.0)) / RATE, 1.0)
		samples[index] = (1.0 if phase < 0.25 else -1.0) * _envelope(index, 0.002, 0.14)
	return samples


## A bronze bar: partials that ring out of tune with each other, as a saron or bonang does.
static func _bronze(pitch: float) -> PackedFloat32Array:
	var samples := _samples(0.6)
	for index in samples.size():
		var time := float(index) / RATE
		var value := 0.0
		for partial: Array in [[1.0, 1.0, 0.25], [2.76, 0.45, 0.12], [5.4, 0.25, 0.06]]:
			value += partial[1] * sin(TAU * pitch * partial[0] * time) * exp(-time / partial[2])
		samples[index] = value * minf(time / 0.002, 1.0)
	return samples


## A soft pad: a tone and its octave, swelling in slowly and fading slowly.
static func _pad(pitch: float, seconds: float) -> PackedFloat32Array:
	var samples := _samples(seconds)
	for index in samples.size():
		var time := float(index) / RATE
		var swell := minf(time / (seconds * 0.35), 1.0) * minf((seconds - time) / (seconds * 0.4), 1.0)
		samples[index] = (sin(TAU * pitch * time) + 0.35 * sin(TAU * pitch * 2.0 * time + 0.3)) * swell
	return samples


## The suling: a bamboo flute, near a pure tone, with breath in it and a vibrato that grows as the
## note is held.
static func _suling(pitch: float, seconds: float) -> PackedFloat32Array:
	var samples := _samples(seconds)
	var phase := 0.0
	var breath := 0.0
	for index in samples.size():
		var time := float(index) / RATE
		phase += TAU * pitch * (1.0 + 0.008 * sin(TAU * 5.0 * time) * minf(time / 0.4, 1.0)) / RATE
		breath = 0.9 * breath + 0.1 * _random.randf_range(-1.0, 1.0)
		var shape := minf(time / 0.08, 1.0) * minf((seconds - time) / 0.15, 1.0)
		samples[index] = (sin(phase) + 0.12 * sin(phase * 2.0) + breath * 0.25) * shape
	return samples


## A distorted guitar: root and fifth, driven hard.
static func _power_chord(root: float, seconds: float) -> PackedFloat32Array:
	var samples := _samples(seconds)
	var level := 0.0
	var smoothing := exp(-TAU * 2200.0 / RATE)
	for index in samples.size():
		var time := float(index) / RATE
		var saw := 0.0
		for harmonic: Array in [[1.0, 1.0], [1.5, 1.0], [2.0, 0.5]]:
			saw += harmonic[1] * (2.0 * fmod(time * root * harmonic[0], 1.0) - 1.0)
		level = (1.0 - smoothing) * saw + smoothing * level
		samples[index] = tanh(level * 3.0) * _envelope(index, 0.004, seconds * 0.9)
	return samples


static func _pitch(note_name: String) -> float:
	var steps := {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
	var octave := int(note_name.right(1))
	var semitones: int = steps[note_name.left(1)] + (1 if note_name.contains("#") else 0) + (octave - 4) * 12
	return 440.0 * pow(2.0, semitones / 12.0)


## Softly limited so nothing clips, as 16-bit, set to loop from end to start.
static func _to_loop(mix: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(mix.size() * 2)
	for index in mix.size():
		data.encode_s16(index * 2, int(tanh(mix[index]) * 30000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = mix.size()
	return wav
