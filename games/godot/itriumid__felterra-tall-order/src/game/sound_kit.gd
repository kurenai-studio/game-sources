class_name SoundKit
extends RefCounted
## Every sound effect in the game, synthesized when the game starts: no recordings, nothing to
## license. Like the palette for the art, a few shared building blocks (a tone that sweeps,
## filtered noise, a pulse wave, the stepped noise of old sound chips) make every sound, so they
## all sound like one game. Each comes in a few variants, so a repeat never sounds the same.

const RATE := 22050
const VARIANTS := 3

## Every sound there is, by name. The director plays them by these names.
const NAMES: Array[String] = [
	"shot_handgun", "shot_submachine_gun", "swing", "hit_small", "squeak", "hit_big", "bark", "hit_dog", "yelp", "saw_rev", "saw_cut",
	"pounce", "riposte", "shot_drone", "meriam", "blast", "crack", "mine_drop",
	"track_clank", "hydraulic", "jaws", "clang", "hiss", "machine_break",
	"lock_click", "cage_open", "meow", "pickup",
	"shot_rifle", "shot_heavy", "shot_twang", "shot_puff", "shot_thunk", "shot_nail", "shot_flare",
	"pop", "net", "ignite", "radio", "drum", "snare", "buzz",
	"boss_horn", "whistle", "truck_horn", "stall", "throw", "lever", "structure_down", "goal_done", "freed", "rotor",
	"footstep_giant", "stomp", "fall", "dodge", "hurt", "bite",
	"level_up", "card", "reroll", "banish", "menu_move", "menu_choose", "menu_back",
]

static var _cache := {}


## A variant of a sound, made the first time it's asked for.
static func stream(sound_name: String, variant: int) -> AudioStreamWAV:
	var key := "%s|%d" % [sound_name, variant]
	if not _cache.has(key):
		var random := RandomNumberGenerator.new()
		random.seed = hash(key)
		_cache[key] = _to_stream(_render(sound_name, random))
	return _cache[key]


## Every variant of every sound, made at once and kept nowhere: the director makes them on a worker
## thread as the game starts, then keeps them with take(), so no sound is made in the middle of a
## fight. Each comes out as it would have on its first play: its noise is seeded from its name.
static func make_all() -> Dictionary:
	var made := {}
	for sound_name in NAMES:
		for variant in VARIANTS:
			var key := "%s|%d" % [sound_name, variant]
			var random := RandomNumberGenerator.new()
			random.seed = hash(key)
			made[key] = _to_stream(_render(sound_name, random))
	return made


## Keeps sounds made elsewhere, unless one was made meanwhile, on its first play.
static func take(made: Dictionary) -> void:
	for key: String in made:
		if not _cache.has(key):
			_cache[key] = made[key]


static func _render(sound_name: String, random: RandomNumberGenerator) -> PackedFloat32Array:
	var wobble := random.randf_range(0.94, 1.06)
	match sound_name:
		"shot_handgun":
			# A crack of noise over a thump, crushed a little like an old sound chip.
			return _mix([_noise(0.16, 0.035, 3400.0 * wobble, random, 2), _sweep(0.16, 170.0 * wobble, 55.0, 0.05)], [0.8, 0.9])
		"shot_submachine_gun":
			return _mix([_noise(0.09, 0.02, 4200.0 * wobble, random, 2), _sweep(0.09, 220.0 * wobble, 80.0, 0.025)], [0.75, 0.6])
		"swing":
			return _whoosh(0.16, 900.0 * wobble, 2600.0 * wobble, random, 0.5)
		"hit_small":
			return _mix([_sweep(0.11, 260.0 * wobble, 95.0, 0.035), _noise(0.05, 0.008, 1800.0, random, 1)], [0.9, 0.5])
		"squeak":
			return _chirp(0.13, [1700.0 * wobble, 2600.0 * wobble, 1300.0 * wobble], 0.25)
		"bark":
			# Two sharp barks, falling in pitch.
			return _mix([_chirp(0.09, [720.0 * wobble, 430.0 * wobble], 0.4), _noise(0.09, 0.03, 1800.0, random, 2)], [0.8, 0.4]) + _mix([_chirp(0.11, [680.0 * wobble, 380.0 * wobble], 0.4), _noise(0.1, 0.03, 1600.0, random, 2)], [0.9, 0.4])
		"hit_dog":
			return _mix([_sweep(0.16, 190.0 * wobble, 70.0, 0.06), _noise(0.08, 0.015, 1200.0, random, 1)], [1.0, 0.5])
		"yelp":
			return _chirp(0.18, [900.0 * wobble, 1300.0 * wobble, 600.0 * wobble], 0.35)
		"saw_rev":
			# A two-stroke engine opening up: a buzz climbing in pitch.
			return _mix([_chirp(0.6, [70.0 * wobble, 140.0 * wobble, 190.0 * wobble], 0.5), _noise(0.6, 0.5, 900.0, random, 3)], [0.5, 0.35])
		"saw_cut":
			return _mix([_chirp(0.4, [200.0 * wobble, 185.0 * wobble, 150.0 * wobble], 0.45), _noise(0.4, 0.3, 3200.0, random, 2)], [0.55, 0.6])
		"hit_big":
			return _mix([_sweep(0.22, 120.0 * wobble, 42.0, 0.08), _noise(0.12, 0.03, 600.0, random, 1)], [1.0, 0.5])
		"footstep_giant":
			return _mix([_sweep(0.3, 75.0 * wobble, 34.0, 0.11), _noise(0.2, 0.05, 380.0, random, 1)], [1.0, 0.45])
		"stomp":
			return _mix([_sweep(0.9, 62.0 * wobble, 26.0, 0.3), _noise(0.9, 0.35, 320.0, random, 1), _noise(0.3, 0.06, 2400.0, random, 3)], [1.0, 0.7, 0.3])
		"fall":
			return _mix([_sweep(1.3, 55.0 * wobble, 22.0, 0.45), _noise(1.3, 0.55, 280.0, random, 1), _crackle(1.0, random)], [1.0, 0.75, 0.35])
		"dodge":
			return _whoosh(0.22, 500.0 * wobble, 1400.0 * wobble, random, 0.35)
		"shot_drone":
			# A small gun on a light frame: a thinner, higher crack.
			return _mix([_noise(0.1, 0.02, 5200.0 * wobble, random, 2), _sweep(0.08, 320.0 * wobble, 120.0, 0.03)], [0.7, 0.5])
		"meriam":
			# The bamboo cannon: a deep, hollow boom, the tube ringing under it.
			return _mix([_sweep(0.8, 95.0 * wobble, 34.0, 0.26), _noise(0.6, 0.2, 520.0, random, 1), _chirp(0.25, [180.0 * wobble, 150.0 * wobble], 0.5)], [1.0, 0.7, 0.25])
		"blast":
			return _mix([_sweep(0.8, 72.0 * wobble, 26.0, 0.28), _noise(0.8, 0.28, 900.0, random, 1), _crackle(0.6, random)], [1.0, 0.8, 0.4])
		"crack":
			# Bamboo splitting: a dry snap and splinters.
			return _mix([_noise(0.22, 0.03, 3600.0, random, 2), _crackle(0.3, random)], [0.8, 0.5])
		"mine_drop":
			return _chirp(0.07, [1500.0 * wobble, 1350.0 * wobble], 0.3)
		"track_clank":
			# A track link rolling over the sprocket: a dull knock with a rattle.
			return _mix([_sweep(0.12, 140.0 * wobble, 70.0, 0.04), _noise(0.08, 0.02, 2200.0, random, 3)], [0.7, 0.4])
		"hydraulic":
			# The boom swinging out: a hydraulic whine climbing, over the engine laboring.
			return _mix([_chirp(0.9, [220.0 * wobble, 330.0 * wobble, 360.0 * wobble], 0.5), _noise(0.9, 0.6, 400.0, random, 4)], [0.25, 0.4])
		"jaws":
			# The head coming down: a heavy chop, and the saw disc screaming through.
			return _mix([_sweep(0.5, 90.0 * wobble, 30.0, 0.16), _noise(0.5, 0.2, 700.0, random, 1), _chirp(0.4, [900.0 * wobble, 760.0 * wobble], 0.4)], [1.0, 0.6, 0.25])
		"clang":
			# A round off its steel: a short metallic ring.
			return _mix([_chirp(0.14, [1240.0 * wobble, 1180.0 * wobble], 0.3), _noise(0.04, 0.008, 5000.0, random, 1)], [0.3, 0.5])
		"hiss":
			# The open joint hit: hydraulic fluid spraying out.
			return _mix([_noise(0.35, 0.15, 6000.0, random, 1), _chirp(0.12, [1000.0 * wobble, 950.0 * wobble], 0.3)], [0.5, 0.2])
		"machine_break":
			# The engine dying under a crunch of steel.
			return _mix([_sweep(1.4, 80.0 * wobble, 24.0, 0.5), _noise(1.2, 0.45, 600.0, random, 2), _crackle(1.2, random), _chirp(1.0, [110.0, 70.0, 40.0], 0.5)], [1.0, 0.6, 0.4, 0.3])
		"shot_rifle":
			# Longer than the handgun's crack, with a tail.
			return _mix([_noise(0.24, 0.05, 4200.0 * wobble, random, 2), _sweep(0.2, 150.0 * wobble, 45.0, 0.07)], [0.9, 0.9])
		"shot_heavy":
			return _mix([_noise(0.4, 0.1, 2400.0 * wobble, random, 2), _sweep(0.4, 110.0 * wobble, 34.0, 0.14)], [1.0, 1.0])
		"shot_twang":
			# A string let go: a plucked tone falling, and a whip of air.
			return _mix([_chirp(0.16, [420.0 * wobble, 260.0 * wobble], 0.4), _whoosh(0.1, 1200.0, 3000.0, random, 0.3)], [0.4, 0.5])
		"shot_puff":
			return _noise(0.08, 0.02, 1800.0 * wobble, random, 1)
		"shot_thunk":
			return _mix([_sweep(0.16, 200.0 * wobble, 80.0, 0.05), _noise(0.08, 0.02, 1500.0, random, 2)], [0.8, 0.3])
		"shot_nail":
			return _mix([_noise(0.05, 0.01, 5500.0, random, 1), _sweep(0.05, 600.0 * wobble, 300.0, 0.02)], [0.6, 0.4])
		"shot_flare":
			return _mix([_whoosh(0.5, 600.0, 2600.0, random, 0.5), _sweep(0.1, 300.0 * wobble, 120.0, 0.04)], [0.6, 0.6])
		"pop":
			return _mix([_noise(0.07, 0.015, 4800.0 * wobble, random, 1), _sweep(0.06, 400.0 * wobble, 150.0, 0.02)], [0.8, 0.4])
		"net":
			return _mix([_whoosh(0.2, 300.0, 900.0, random, 0.4), _sweep(0.1, 120.0, 60.0, 0.04)], [0.5, 0.5])
		"ignite":
			# Oil catching: a soft whoomph that keeps burning.
			return _mix([_sweep(0.5, 90.0 * wobble, 40.0, 0.2), _noise(0.6, 0.3, 1200.0, random, 1)], [0.6, 0.6])
		"radio":
			# A little tune out of a tinny speaker.
			return _arpeggio(["D5", "F#5", "A5", "F#5", "B5", "A5"], 0.09, 0.2)
		"boss_horn":
			# Something big coming: a low horn, swelling.
			return _mix([_chirp(1.2, [98.0 * wobble, 110.0 * wobble, 104.0 * wobble], 0.5), _noise(1.2, 0.6, 300.0, random, 4)], [0.5, 0.3])
		"whistle":
			return _chirp(0.4, [2400.0 * wobble, 2600.0 * wobble, 2200.0 * wobble], 0.5)
		"truck_horn":
			return _mix([_chirp(0.6, [330.0, 330.0], 0.5), _chirp(0.6, [415.0, 415.0], 0.5)], [0.35, 0.35])
		"stall":
			# An engine coughing out.
			return _mix([_noise(0.6, 0.25, 500.0, random, 6), _sweep(0.6, 90.0, 40.0, 0.2)], [0.5, 0.6])
		"throw":
			return _whoosh(0.6, 200.0, 900.0, random, 0.6)
		"drum":
			# The kentongan struck: a hollow bamboo knock, ringing a moment.
			return _mix([_sweep(0.18, 520.0 * wobble, 380.0, 0.06), _noise(0.04, 0.01, 2400.0, random, 2)], [0.8, 0.3])
		"snare":
			# A rattan loop pulled tight: a creak and a snap.
			return _mix([_sweep(0.12, 700.0 * wobble, 1100.0, 0.03), _noise(0.06, 0.015, 3000.0, random, 2)], [0.5, 0.6])
		"buzz":
			# A sting: bees, a short angry drone.
			return _mix([_sweep(0.14, 220.0 * wobble, 240.0, 0.05), _noise(0.14, 0.05, 900.0, random, 3)], [0.4, 0.3])
		"lever":
			# A catch giving, and the stack starting to roll.
			return _mix([_sweep(0.2, 260.0, 120.0, 0.06), _noise(1.0, 0.5, 400.0, random, 3)], [0.6, 0.6])
		"structure_down":
			return _mix([_sweep(0.6, 120.0 * wobble, 40.0, 0.2), _crackle(0.6, random), _noise(0.4, 0.12, 1400.0, random, 2)], [0.8, 0.5, 0.5])
		"goal_done":
			return _arpeggio(["A5", "D6", "F#6"], 0.09, 0.4)
		"freed":
			# The forest's own again: the bronze rising.
			return _arpeggio(["D5", "F#5", "A5", "D6", "F#6", "A6"], 0.12, 0.5)
		"rotor":
			return _mix([_sweep(0.08, 110.0, 70.0, 0.03), _noise(0.06, 0.02, 900.0, random, 3)], [0.6, 0.4])
		"lock_click":
			return _noise(0.03, 0.006, 6500.0, random, 1)
		"cage_open":
			# The padlock giving and the door swinging: a clunk and a creak.
			return _mix([_sweep(0.12, 300.0 * wobble, 140.0, 0.04), _chirp(0.3, [520.0 * wobble, 610.0 * wobble, 470.0 * wobble], 0.15)], [0.7, 0.25])
		"meow":
			# A freed cat's call, rising then falling.
			return _chirp(0.34, [620.0 * wobble, 980.0 * wobble, 860.0 * wobble, 560.0 * wobble], 0.3)
		"pickup":
			return _arpeggio(["E6", "B6"], 0.035, 0.25)
		"pounce":
			# Paws coming down hard: a soft thump with a scuff of grit.
			return _mix([_sweep(0.14, 170.0 * wobble, 60.0, 0.05), _noise(0.1, 0.03, 1500.0, random, 2)], [0.9, 0.4])
		"riposte":
			# Steel on steel: a bright ring over a short scrape.
			return _mix([_chirp(0.3, [1760.0 * wobble, 1700.0 * wobble], 0.25), _noise(0.06, 0.015, 6000.0, random, 1)], [0.35, 0.6])
		"hurt":
			# Something like a cat's yowl: a pulse falling in pitch.
			return _chirp(0.26, [880.0 * wobble, 1050.0 * wobble, 420.0 * wobble], 0.35)
		"bite":
			return _noise(0.05, 0.01, 5000.0, random, 1)
		"level_up":
			return _arpeggio(["D5", "F#5", "A5", "D6"], 0.075, 0.5)
		"card":
			return _arpeggio(["A5", "D6"], 0.05, 0.25)
		"reroll":
			return _mix([_noise(0.2, 0.06, 2600.0, random, 4), _arpeggio(["E5", "A5"], 0.06, 0.25)], [0.5, 0.6])
		"banish":
			return _arpeggio(["A5", "E5", "A4"], 0.07, 0.25)
		"menu_move":
			return _arpeggio(["E6"], 0.03, 0.125)
		"menu_choose":
			return _arpeggio(["A5", "E6"], 0.04, 0.25)
		"menu_back":
			return _arpeggio(["E6", "A5"], 0.04, 0.25)
	return PackedFloat32Array()


## A tone gliding from one pitch to another as it fades: thumps, thuds and booms.
static func _sweep(seconds: float, from: float, to: float, decay: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(seconds * RATE))
	var phase := 0.0
	for index in samples.size():
		var time := float(index) / RATE
		phase += TAU * (to + (from - to) * exp(-time / (decay * 0.6))) / RATE
		samples[index] = sin(phase) * exp(-time / decay) * minf(time / 0.002, 1.0)
	return samples


## Noise through a one-pole low-pass filter, fading. Steps above 1 hold each value that many
## samples, the coarse grain of an old sound chip.
static func _noise(seconds: float, decay: float, cutoff: float, random: RandomNumberGenerator, steps: int) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(seconds * RATE))
	var smoothing := exp(-TAU * cutoff / RATE)
	var level := 0.0
	var held := 0.0
	for index in samples.size():
		if index % steps == 0:
			held = random.randf_range(-1.0, 1.0)
		level = (1.0 - smoothing) * held + smoothing * level
		var time := float(index) / RATE
		samples[index] = level * exp(-time / decay) * minf(time / 0.001, 1.0) * 2.0
	return samples


## Air moving: noise whose brightness rises and falls, loudest in the middle.
static func _whoosh(seconds: float, low: float, high: float, random: RandomNumberGenerator, gain: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(seconds * RATE))
	var level := 0.0
	for index in samples.size():
		var along := float(index) / samples.size()
		var cutoff := low + (high - low) * sin(along * PI)
		var smoothing := exp(-TAU * cutoff / RATE)
		level = (1.0 - smoothing) * random.randf_range(-1.0, 1.0) + smoothing * level
		samples[index] = level * sin(along * PI) * gain * 3.0
	return samples


## A pulse wave through a run of pitches, for squeaks and yowls.
static func _chirp(seconds: float, pitches: Array[float], width: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(seconds * RATE))
	var phase := 0.0
	for index in samples.size():
		var along := float(index) / samples.size() * (pitches.size() - 1)
		var part := mini(int(along), pitches.size() - 2)
		var pitch := lerpf(pitches[part], pitches[part + 1], along - part)
		phase = fmod(phase + pitch / RATE, 1.0)
		var time := float(index) / RATE
		samples[index] = (1.0 if phase < width else -1.0) * 0.5 * minf(time / 0.004, 1.0) * (1.0 - float(index) / samples.size())
	return samples


## Debris settling: sparse clicks thinning out.
static func _crackle(seconds: float, random: RandomNumberGenerator) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(seconds * RATE))
	for index in samples.size():
		var along := float(index) / samples.size()
		if random.randf() < 0.004 * (1.0 - along):
			for click in mini(40, samples.size() - index):
				samples[index + click] += random.randf_range(-1.0, 1.0) * exp(-click / 8.0)
	return samples


## Square-wave notes one after another, the chiptune voice of the interface.
static func _arpeggio(notes: Array[String], note_seconds: float, width: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	var per_note := int(note_seconds * RATE)
	samples.resize(per_note * notes.size() + per_note)
	for at in notes.size():
		var pitch := _pitch(notes[at])
		var phase := 0.0
		for index in per_note * 2:
			var target := at * per_note + index
			if target >= samples.size():
				break
			phase = fmod(phase + pitch / RATE, 1.0)
			samples[target] += (0.4 if phase < width else -0.4) * exp(-float(index) / (per_note * 0.6))
	return samples


static func _pitch(note_name: String) -> float:
	var steps := {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
	var octave := int(note_name.right(1))
	var semitones: int = steps[note_name.left(1)] + (1 if note_name.contains("#") else 0) + (octave - 4) * 12
	return 440.0 * pow(2.0, semitones / 12.0)


static func _mix(parts: Array[PackedFloat32Array], gains: Array[float]) -> PackedFloat32Array:
	var length := 0
	for part in parts:
		length = maxi(length, part.size())
	var samples := PackedFloat32Array()
	samples.resize(length)
	for at in parts.size():
		for index in parts[at].size():
			samples[index] += parts[at][index] * gains[at]
	return samples


## Into a stream Godot can play: softly limited so nothing clips, then 16-bit.
static func _to_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for index in samples.size():
		data.encode_s16(index * 2, int(tanh(samples[index]) * 30000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav


## The loudest any sample of a sound reaches, 0 to 1. For the tests.
static func peak(sound_name: String) -> float:
	var wav := stream(sound_name, 0)
	var loudest := 0
	for index in range(0, wav.data.size(), 2):
		loudest = maxi(loudest, absi(wav.data.decode_s16(index)))
	return loudest / 32767.0
