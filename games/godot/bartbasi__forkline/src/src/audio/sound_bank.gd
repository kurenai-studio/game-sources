# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name SoundBank
extends RefCounted
## Every sound and both music tracks, synthesized in code. The recipes are
## static and repeatable. An instance builds them all once on worker threads
## (start), then hands out the finished streams (stream). No audio files.

## Effect ids. Event sounds are named like the event kinds of the sim (contract 3.1).
const EFFECTS: Array[StringName] = [
	&"wave_started", &"spawned", &"fired", &"popped", &"defeated", &"healed",
	&"leaked", &"gate_broken", &"wave_cleared", &"build_started", &"built",
	&"upgraded", &"sold", &"gate_placed", &"gate_removed", &"won", &"lost",
	&"tap", &"refuse", &"star",
	# Released creatures, a gate being broken, Ironshell speeding up, interest gold.
	&"released", &"break_started", &"sped_up", &"interest",
	# Shot sounds by tower and tier 3 path. The Sling Post's plain shot is &"fired".
	# The Lullaby Bell and the Bakery never fire (architecture 3.1), so they have none.
	&"shot_quickshot", &"shot_stone_sling",
	&"shot_pumpkin_catapult", &"shot_prize_pumpkin", &"shot_jam_pot",
	&"shot_longbow_loft", &"shot_giant_bow", &"shot_triple_bow",
	&"shot_firework_tower", &"shot_star_bloom", &"shot_skyrocket",
	# The expansion's attacking towers. The Scarecrow never fires, so it has none.
	&"shot_bramble_cottage", &"shot_wild_bramble", &"shot_holly_crown",
	&"shot_snow_fort", &"shot_big_snowball", &"shot_flurry",
	&"shot_moth_lantern", &"shot_beacon_lantern", &"shot_lantern_garland",
	# Expansion creature events: a nap, a wake, a dig, a surfacing, a blink, a yawn.
	&"napped", &"woke", &"burrowed", &"surfaced", &"blinked", &"yawned",
]
const TRACKS: Array[StringName] = [&"menu", &"battle"]

# The menu tune: a short waltz lullaby in F major (the theme slice's loop).
# Each note: [beat, midi note, length in beats].
const MENU_MELODY: Array = [
	[0.0, 72, 1.0], [1.0, 69, 1.0], [2.0, 72, 1.0],
	[3.0, 77, 2.0], [5.0, 74, 1.0],
	[6.0, 74, 1.0], [7.0, 72, 1.0], [8.0, 70, 1.0],
	[9.0, 67, 2.0], [11.0, 72, 1.0],
	[12.0, 69, 1.0], [13.0, 72, 1.0], [14.0, 77, 1.0],
	[15.0, 76, 1.0], [16.0, 74, 0.5], [16.5, 72, 0.5], [17.0, 69, 1.0],
	[18.0, 67, 1.0], [19.0, 70, 1.0], [20.0, 76, 1.0],
	[21.0, 77, 2.0], [23.0, 69, 1.0],
]
# One chord per bar: bass note, then the chord tones for the soft plucks.
const MENU_CHORDS: Array = [
	[41, [57, 60, 65]], [38, [57, 62, 65]], [46, [58, 62, 65]], [48, [55, 60, 64]],
	[41, [57, 60, 65]], [45, [57, 60, 64]], [43, [55, 58, 62]], [41, [57, 60, 65]],
]
# The battle tune: a gentle 4/4 stroll in C major. Same instruments, a little
# more lift, and nothing sharp, so it stays easy to hear for a long wave.
const BATTLE_MELODY: Array = [
	[0.0, 76, 1.0], [1.0, 79, 0.5], [1.5, 76, 0.5], [2.0, 72, 2.0],
	[4.0, 72, 1.0], [5.0, 69, 1.0], [6.0, 72, 2.0],
	[8.0, 77, 1.0], [9.0, 74, 1.0], [10.0, 72, 1.0], [11.0, 69, 1.0],
	[12.0, 71, 1.5], [13.5, 74, 0.5], [14.0, 67, 2.0],
	[16.0, 76, 1.0], [17.0, 79, 0.5], [17.5, 81, 0.5], [18.0, 79, 2.0],
	[20.0, 76, 1.0], [21.0, 71, 1.0], [22.0, 76, 1.0], [23.0, 79, 1.0],
	[24.0, 77, 1.5], [25.5, 76, 0.5], [26.0, 74, 1.0], [27.0, 72, 1.0],
	[28.0, 74, 1.0], [29.0, 71, 1.0], [30.0, 72, 2.0],
]
const BATTLE_CHORDS: Array = [
	[48, [60, 64, 67]], [45, [57, 60, 64]], [41, [57, 60, 65]], [43, [55, 59, 62]],
	[48, [60, 64, 67]], [40, [55, 59, 64]], [41, [57, 60, 65]], [43, [55, 59, 62]],
]

var _mutex: Mutex = Mutex.new()
var _streams: Dictionary[StringName, AudioStreamWAV] = {}
var _tasks: PackedInt64Array = PackedInt64Array()
var _waited: bool = false


## Starts building every sound on worker threads: the effects on one, each
## music track on its own. Returns at once. Calling it twice does nothing.
func start() -> void:
	if not _tasks.is_empty():
		return
	_tasks.append(WorkerThreadPool.add_task(_build_effects, false, "Forkline effects"))
	for track: StringName in TRACKS:
		_tasks.append(WorkerThreadPool.add_task(_build_track.bind(track), false, "Forkline music"))


## Blocks until every sound is built. Safe to call more than once. Call it
## before the bank is dropped, so no task is left unwaited.
func wait() -> void:
	if _waited:
		return
	_waited = true
	for task: int in _tasks:
		WorkerThreadPool.wait_for_task_completion(task)


## True once every effect and track is built.
func is_complete() -> bool:
	_mutex.lock()
	var done: bool = _streams.size() == EFFECTS.size() + TRACKS.size()
	_mutex.unlock()
	return done


## The finished stream for a sound or track id, or null while it is still
## being built (or when the id is unknown).
func stream(id: StringName) -> AudioStreamWAV:
	_mutex.lock()
	var found: AudioStreamWAV = _streams.get(id)
	_mutex.unlock()
	return found


func _build_effects() -> void:
	for id: StringName in EFFECTS:
		_store(id, render_effect(id))


func _build_track(track: StringName) -> void:
	_store(track, render_music(track))


func _store(id: StringName, wav: AudioStreamWAV) -> void:
	_mutex.lock()
	_streams[id] = wav
	_mutex.unlock()


## Builds one effect. Null for an unknown id.
static func render_effect(id: StringName) -> AudioStreamWAV:
	match id:
		&"wave_started": return _wave_started()
		&"spawned": return _spawned()
		&"fired": return _fired()
		&"popped": return _popped()
		&"defeated": return _defeated()
		&"healed": return _healed()
		&"leaked": return _leaked()
		&"gate_broken": return _gate_broken()
		&"wave_cleared": return _wave_cleared()
		&"build_started": return _build_started()
		&"built": return _built()
		&"upgraded": return _upgraded()
		&"sold": return _sold()
		&"gate_placed": return _gate_placed()
		&"gate_removed": return _gate_removed()
		&"won": return _won()
		&"lost": return _lost()
		&"tap": return _tap()
		&"refuse": return _refuse()
		&"star": return _star()
		&"released": return _released()
		&"break_started": return _break_started()
		&"sped_up": return _sped_up()
		&"interest": return _interest()
		&"shot_quickshot": return _shot_quickshot()
		&"shot_stone_sling": return _shot_stone_sling()
		&"shot_pumpkin_catapult": return _lob(260.0, 110.0, 0.22, 16.0, 0.8, 7)
		&"shot_prize_pumpkin": return _lob(200.0, 80.0, 0.3, 11.0, 0.85, 8)
		&"shot_jam_pot": return _shot_jam_pot()
		&"shot_longbow_loft": return _twang(1, 520.0, 380.0, 0.12, 22.0, 0.45)
		&"shot_giant_bow": return _twang(1, 300.0, 210.0, 0.18, 16.0, 0.6)
		&"shot_triple_bow": return _twang(3, 560.0, 420.0, 0.06, 40.0, 0.35)
		&"shot_firework_tower": return _firework(&"shot_firework_tower")
		&"shot_star_bloom": return _firework(&"shot_star_bloom")
		&"shot_skyrocket": return _firework(&"shot_skyrocket")
		&"shot_bramble_cottage", &"shot_wild_bramble", &"shot_holly_crown":
			return _bramble(id)
		&"shot_snow_fort", &"shot_big_snowball", &"shot_flurry":
			return _snowball(id)
		&"shot_moth_lantern", &"shot_beacon_lantern", &"shot_lantern_garland":
			return _lantern(id)
		&"napped": return _napped()
		&"woke": return _woke()
		&"burrowed": return _burrowed()
		&"surfaced": return _surfaced()
		&"blinked": return _blinked()
		&"yawned": return _yawned()
	return null


## Builds one looping music track. Null for an unknown track. Slow in
## GDScript (a second or more), so call it off the main thread.
static func render_music(track: StringName) -> AudioStreamWAV:
	match track:
		&"menu":
			return _compose(96.0, 3, MENU_MELODY, MENU_CHORDS, [1.0, 2.0], [[0.0, 0, 1.0]], 0.26)
		&"battle":
			return _compose(104.0, 4, BATTLE_MELODY, BATTLE_CHORDS, [1.0, 3.0], [[0.0, 0, 1.0], [2.0, 7, 0.6]], 0.24)
	return null


# Music.

static func _compose(bpm: float, beats_per_bar: int, melody: Array, chords: Array, pluck_beats: Array, bass_beats: Array, melody_amp: float) -> AudioStreamWAV:
	var rate: int = AudioSynth.MUSIC_RATE
	var beat: float = 60.0 / bpm
	var buf: PackedFloat32Array = AudioSynth.buffer(float(chords.size() * beats_per_bar) * beat, rate)
	var total: int = buf.size()
	for n: Array in melody:
		AudioSynth.music_box(buf, rate, float(n[0]) * beat, AudioSynth.hz(int(n[1])), melody_amp, true)
	for bar: int in chords.size():
		var chord: Array = chords[bar]
		var start: float = float(bar * beats_per_bar) * beat
		var root: int = chord[0]
		for b: Array in bass_beats:
			AudioSynth.bass(buf, rate, start + float(b[0]) * beat, AudioSynth.hz(root + int(b[1])), 0.30 * float(b[2]), true)
		for pluck_beat: float in pluck_beats:
			for tone: int in chord[1]:
				AudioSynth.pluck(buf, rate, start + pluck_beat * beat, AudioSynth.hz(tone), 0.07, true)
	# A soft echo, wrapped around the loop so the seam stays clean.
	var delay: int = int(beat * 0.5 * float(rate))
	for _pass: int in 2:
		for i: int in total:
			var j: int = i - delay
			if j < 0:
				j += total
			buf[i] += buf[j] * 0.22
	return AudioSynth.to_stream(buf, rate, true)


# Effects. Each is a short mono stream. The mixer sets how loud each plays.

static func _tap() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.05, r)
	AudioSynth.sweep(buf, r, 0.0, 0.05, 1800.0, 1800.0, 0.35, 90.0)
	return AudioSynth.to_stream(buf, r, false)


## Two soft low knocks, a gentle no.
static func _refuse() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.26, r)
	AudioSynth.noise(buf, r, 0.0, 0.02, 0.2, 0.3, 29)
	AudioSynth.sweep(buf, r, 0.0, 0.08, 230.0, 170.0, 0.5, 35.0)
	AudioSynth.noise(buf, r, 0.1, 0.02, 0.18, 0.3, 31)
	AudioSynth.sweep(buf, r, 0.1, 0.1, 200.0, 140.0, 0.45, 30.0)
	return AudioSynth.to_stream(buf, r, false)


## A star earned: four sparkling bell notes going up.
static func _star() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(1.1, r)
	AudioSynth.bell(buf, r, 0.0, 1047.0, 0.2, 5.0)
	AudioSynth.bell(buf, r, 0.07, 1319.0, 0.2, 5.0)
	AudioSynth.bell(buf, r, 0.14, 1568.0, 0.2, 5.0)
	AudioSynth.bell(buf, r, 0.21, 2093.0, 0.16, 5.0)
	return AudioSynth.to_stream(buf, r, false)


## A new wave: two music box notes, a rising fifth.
static func _wave_started() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(1.2, r)
	AudioSynth.music_box(buf, r, 0.0, AudioSynth.hz(72), 0.3, false)
	AudioSynth.music_box(buf, r, 0.22, AudioSynth.hz(79), 0.3, false)
	return AudioSynth.to_stream(buf, r, false)


## A creature arrives: a very quiet low blip. It fires a lot, so it stays faint.
static func _spawned() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.08, r)
	AudioSynth.sweep(buf, r, 0.0, 0.08, 300.0, 430.0, 0.4, 28.0)
	return AudioSynth.to_stream(buf, r, false)


## Tower shot: a short soft pip with a falling pitch.
static func _fired() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.09, r)
	AudioSynth.sweep(buf, r, 0.0, 0.09, 1250.0, 650.0, 0.5, 40.0)
	return AudioSynth.to_stream(buf, r, false)


## A bubble pops: a quick rising blip with a breath of noise.
static func _popped() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.08, r)
	AudioSynth.noise(buf, r, 0.0, 0.015, 0.25, 0.3, 19)
	AudioSynth.sweep(buf, r, 0.0, 0.06, 500.0, 1500.0, 0.4, 55.0)
	return AudioSynth.to_stream(buf, r, false)


## Creature puff: a soft breath of noise and two rising chimes.
static func _defeated() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.5, r)
	AudioSynth.noise(buf, r, 0.0, 0.22, 0.45, 0.12, 11)
	AudioSynth.bell(buf, r, 0.03, 1568.0, 0.16, 11.0)
	AudioSynth.bell(buf, r, 0.09, 2093.0, 0.13, 10.0)
	return AudioSynth.to_stream(buf, r, false)


## A Mender heals: three quick shimmering notes going up.
static func _healed() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.6, r)
	AudioSynth.bell(buf, r, 0.0, 1319.0, 0.14, 12.0)
	AudioSynth.bell(buf, r, 0.06, 1568.0, 0.14, 12.0)
	AudioSynth.bell(buf, r, 0.12, 1976.0, 0.14, 12.0)
	return AudioSynth.to_stream(buf, r, false)


## A creature reached the village: two soft falling notes.
static func _leaked() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.6, r)
	AudioSynth.bell(buf, r, 0.0, 523.0, 0.25, 7.0)
	AudioSynth.bell(buf, r, 0.16, 392.0, 0.25, 6.0)
	return AudioSynth.to_stream(buf, r, false)


## A gate breaks: a dull wooden crack and two small splinters. Soft, not sharp.
static func _gate_broken() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.4, r)
	AudioSynth.noise(buf, r, 0.0, 0.07, 0.6, 0.35, 21)
	AudioSynth.sweep(buf, r, 0.0, 0.2, 170.0, 70.0, 0.6, 14.0)
	AudioSynth.noise(buf, r, 0.07, 0.05, 0.3, 0.3, 23)
	AudioSynth.noise(buf, r, 0.13, 0.04, 0.2, 0.3, 25)
	return AudioSynth.to_stream(buf, r, false)


## A wave is cleared: a bright little arpeggio.
static func _wave_cleared() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(1.1, r)
	AudioSynth.bell(buf, r, 0.0, 523.0, 0.2, 6.0)
	AudioSynth.bell(buf, r, 0.09, 659.0, 0.2, 6.0)
	AudioSynth.bell(buf, r, 0.18, 784.0, 0.2, 6.0)
	AudioSynth.bell(buf, r, 0.27, 1047.0, 0.2, 6.0)
	return AudioSynth.to_stream(buf, r, false)


## Build time begins: one quiet chime. It often follows a cleared wave, so it stays small.
static func _build_started() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.5, r)
	AudioSynth.bell(buf, r, 0.0, 659.0, 0.14, 10.0)
	return AudioSynth.to_stream(buf, r, false)


## Tower built: a knock and two bell notes going up.
static func _built() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.5, r)
	AudioSynth.noise(buf, r, 0.0, 0.05, 0.5, 0.45, 9)
	AudioSynth.bell(buf, r, 0.04, 784.0, 0.22, 9.0)
	AudioSynth.bell(buf, r, 0.12, 1175.0, 0.2, 9.0)
	return AudioSynth.to_stream(buf, r, false)


## Tower upgraded: a knock and three bell notes going up.
static func _upgraded() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.7, r)
	AudioSynth.noise(buf, r, 0.0, 0.05, 0.45, 0.45, 13)
	AudioSynth.bell(buf, r, 0.04, 784.0, 0.2, 8.0)
	AudioSynth.bell(buf, r, 0.11, 1175.0, 0.2, 8.0)
	AudioSynth.bell(buf, r, 0.18, 1568.0, 0.18, 8.0)
	return AudioSynth.to_stream(buf, r, false)


## Tower sold: a small tick and two coin notes going down.
static func _sold() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.45, r)
	AudioSynth.noise(buf, r, 0.0, 0.03, 0.3, 0.5, 17)
	AudioSynth.bell(buf, r, 0.0, 1175.0, 0.2, 12.0)
	AudioSynth.bell(buf, r, 0.07, 880.0, 0.2, 12.0)
	return AudioSynth.to_stream(buf, r, false)


## Gate placed: a wooden knock and a warm bell.
static func _gate_placed() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.6, r)
	AudioSynth.noise(buf, r, 0.0, 0.05, 0.6, 0.5, 3)
	AudioSynth.sweep(buf, r, 0.0, 0.12, 200.0, 120.0, 0.6, 30.0)
	AudioSynth.bell(buf, r, 0.05, 880.0, 0.3, 6.0)
	return AudioSynth.to_stream(buf, r, false)


## Gate lifted: a lighter knock and a lower bell.
static func _gate_removed() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.5, r)
	AudioSynth.noise(buf, r, 0.0, 0.04, 0.4, 0.5, 5)
	AudioSynth.bell(buf, r, 0.03, 660.0, 0.25, 8.0)
	return AudioSynth.to_stream(buf, r, false)


## The level is won: a bright music box run up, then a warm held chord.
static func _won() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(2.6, r)
	AudioSynth.music_box(buf, r, 0.0, AudioSynth.hz(72), 0.26, false)
	AudioSynth.music_box(buf, r, 0.2, AudioSynth.hz(77), 0.26, false)
	AudioSynth.music_box(buf, r, 0.4, AudioSynth.hz(81), 0.26, false)
	AudioSynth.music_box(buf, r, 0.6, AudioSynth.hz(84), 0.3, false)
	for midi: int in [65, 69, 72]:
		AudioSynth.music_box(buf, r, 0.6, AudioSynth.hz(midi), 0.12, false)
	return AudioSynth.to_stream(buf, r, false)


## The level is lost: four slow falling music box notes. Sad, never harsh.
static func _lost() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(2.6, r)
	AudioSynth.music_box(buf, r, 0.0, AudioSynth.hz(69), 0.26, false)
	AudioSynth.music_box(buf, r, 0.4, AudioSynth.hz(65), 0.26, false)
	AudioSynth.music_box(buf, r, 0.8, AudioSynth.hz(62), 0.26, false)
	AudioSynth.music_box(buf, r, 1.25, AudioSynth.hz(57), 0.28, false)
	return AudioSynth.to_stream(buf, r, false)


## Creatures released: two tiny soft bubbles, the second a little higher. It
## stays quiet because a split can release a whole batch.
static func _released() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.22, r)
	AudioSynth.noise(buf, r, 0.0, 0.03, 0.15, 0.2, 51)
	AudioSynth.sweep(buf, r, 0.0, 0.08, 340.0, 520.0, 0.45, 30.0)
	AudioSynth.sweep(buf, r, 0.07, 0.09, 420.0, 640.0, 0.4, 30.0)
	return AudioSynth.to_stream(buf, r, false)


## A creature starts to break a gate: two soft wooden knocks under a small bell.
## Gentle, but different from every other sound, so the player looks up.
static func _break_started() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.5, r)
	AudioSynth.noise(buf, r, 0.0, 0.04, 0.45, 0.3, 53)
	AudioSynth.sweep(buf, r, 0.0, 0.1, 190.0, 120.0, 0.6, 28.0)
	AudioSynth.noise(buf, r, 0.12, 0.04, 0.4, 0.3, 55)
	AudioSynth.sweep(buf, r, 0.12, 0.1, 180.0, 115.0, 0.55, 28.0)
	AudioSynth.bell(buf, r, 0.0, 698.0, 0.14, 8.0)
	AudioSynth.bell(buf, r, 0.24, 698.0, 0.12, 8.0)
	return AudioSynth.to_stream(buf, r, false)


## A creature speeds up: a soft rising whoosh that ends in a small bell.
static func _sped_up() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.45, r)
	AudioSynth.noise(buf, r, 0.0, 0.2, 0.12, 0.15, 57)
	AudioSynth.sweep(buf, r, 0.0, 0.22, 330.0, 820.0, 0.4, 7.0)
	AudioSynth.bell(buf, r, 0.2, 1047.0, 0.16, 9.0)
	return AudioSynth.to_stream(buf, r, false)


## Interest gold: a tiny coin tick and two quick high notes. Soft and short.
static func _interest() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.35, r)
	AudioSynth.noise(buf, r, 0.0, 0.015, 0.2, 0.5, 59)
	AudioSynth.bell(buf, r, 0.0, 1760.0, 0.16, 14.0)
	AudioSynth.bell(buf, r, 0.06, 2349.0, 0.14, 14.0)
	return AudioSynth.to_stream(buf, r, false)


# Shot sounds. Short and soft; the mixer keeps them in the background.

## Quickshot: two quick pips.
static func _shot_quickshot() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.13, r)
	AudioSynth.sweep(buf, r, 0.0, 0.05, 1500.0, 900.0, 0.4, 55.0)
	AudioSynth.sweep(buf, r, 0.06, 0.05, 1500.0, 900.0, 0.35, 55.0)
	return AudioSynth.to_stream(buf, r, false)


## Stone Sling: a lower, heavier pip with a little grit.
static func _shot_stone_sling() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.11, r)
	AudioSynth.noise(buf, r, 0.0, 0.012, 0.2, 0.3, 41)
	AudioSynth.sweep(buf, r, 0.0, 0.1, 700.0, 330.0, 0.55, 32.0)
	return AudioSynth.to_stream(buf, r, false)


## A catapult lob: a low round thump with a puff of noise. The slice's lob.
static func _lob(f0: float, f1: float, length: float, decay: float, amp: float, seed_value: int) -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(length, r)
	AudioSynth.sweep(buf, r, 0.0, length, f0, f1, amp, decay)
	AudioSynth.noise(buf, r, 0.0, 0.06, 0.15, 0.3, seed_value)
	return AudioSynth.to_stream(buf, r, false)


## Jam Pot: a lob with a glossy little bell on top.
static func _shot_jam_pot() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.3, r)
	AudioSynth.sweep(buf, r, 0.0, 0.2, 280.0, 130.0, 0.7, 16.0)
	AudioSynth.noise(buf, r, 0.0, 0.05, 0.12, 0.3, 9)
	AudioSynth.bell(buf, r, 0.05, 1175.0, 0.12, 14.0)
	return AudioSynth.to_stream(buf, r, false)


## Longbow Loft: a soft string twang. `count` twangs, `step` seconds apart.
static func _twang(count: int, f0: float, f1: float, step: float, decay: float, amp: float) -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.1 + step * float(count), r)
	for i: int in count:
		var at: float = step * float(i)
		AudioSynth.sweep(buf, r, at, 0.1, f0, f1, amp, decay)
		AudioSynth.sweep(buf, r, at, 0.08, f0 * 2.0, f1 * 2.0, amp * 0.3, decay * 1.4)
	return AudioSynth.to_stream(buf, r, false)


## Firework Tower: a soft whoosh up and a bell pop. Bloom adds sparkles,
## Skyrocket goes higher and quicker.
static func _firework(id: StringName) -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.4, r)
	if id == &"shot_skyrocket":
		AudioSynth.noise(buf, r, 0.0, 0.1, 0.12, 0.15, 43)
		AudioSynth.sweep(buf, r, 0.0, 0.1, 700.0, 2000.0, 0.18, 10.0)
		AudioSynth.noise(buf, r, 0.1, 0.03, 0.2, 0.3, 45)
		AudioSynth.bell(buf, r, 0.1, 2093.0, 0.14, 14.0)
		return AudioSynth.to_stream(buf, r, false)
	AudioSynth.noise(buf, r, 0.0, 0.12, 0.12, 0.15, 43)
	AudioSynth.sweep(buf, r, 0.0, 0.12, 500.0, 1400.0, 0.2, 12.0)
	AudioSynth.bell(buf, r, 0.12, 1568.0, 0.15, 14.0)
	if id == &"shot_star_bloom":
		AudioSynth.bell(buf, r, 0.16, 1976.0, 0.1, 14.0)
		AudioSynth.bell(buf, r, 0.2, 2349.0, 0.08, 14.0)
	return AudioSynth.to_stream(buf, r, false)


# The expansion (architecture 14.11). Same gentle voice as the rest.

## Bramble Cottage pulse: a dry leafy rustle and a soft thorn knock. One sound for
## the whole ring. Wild Bramble rustles wider and lower, Holly Crown adds a bright
## holly tick on top.
static func _bramble(id: StringName) -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	if id == &"shot_wild_bramble":
		var wide: PackedFloat32Array = AudioSynth.buffer(0.3, r)
		AudioSynth.noise(wide, r, 0.0, 0.18, 0.55, 0.28, 61)
		AudioSynth.noise(wide, r, 0.06, 0.14, 0.45, 0.32, 62)
		AudioSynth.noise(wide, r, 0.12, 0.12, 0.35, 0.36, 63)
		AudioSynth.sweep(wide, r, 0.0, 0.12, 430.0, 300.0, 0.35, 22.0)
		return AudioSynth.to_stream(wide, r, false)
	var buf: PackedFloat32Array = AudioSynth.buffer(0.22, r)
	AudioSynth.noise(buf, r, 0.0, 0.12, 0.5, 0.35, 61)
	AudioSynth.noise(buf, r, 0.05, 0.09, 0.4, 0.45, 62)
	AudioSynth.sweep(buf, r, 0.0, 0.08, 540.0, 390.0, 0.35, 30.0)
	if id == &"shot_holly_crown":
		AudioSynth.bell(buf, r, 0.03, 1568.0, 0.1, 16.0)
	return AudioSynth.to_stream(buf, r, false)


## Snow Fort line: a soft low whoomph and a breath of snow rolling away. Big
## Snowball is deeper and longer, Flurry is two light puffs.
static func _snowball(id: StringName) -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	if id == &"shot_flurry":
		var flurry: PackedFloat32Array = AudioSynth.buffer(0.26, r)
		AudioSynth.noise(flurry, r, 0.0, 0.1, 0.35, 0.2, 67)
		AudioSynth.sweep(flurry, r, 0.0, 0.1, 300.0, 190.0, 0.4, 24.0)
		AudioSynth.noise(flurry, r, 0.11, 0.1, 0.3, 0.2, 68)
		AudioSynth.sweep(flurry, r, 0.11, 0.1, 340.0, 210.0, 0.35, 24.0)
		return AudioSynth.to_stream(flurry, r, false)
	if id == &"shot_big_snowball":
		var big: PackedFloat32Array = AudioSynth.buffer(0.5, r)
		AudioSynth.noise(big, r, 0.0, 0.4, 0.5, 0.1, 65)
		AudioSynth.sweep(big, r, 0.0, 0.4, 130.0, 60.0, 0.75, 6.0)
		AudioSynth.sweep(big, r, 0.0, 0.3, 260.0, 120.0, 0.2, 9.0)
		return AudioSynth.to_stream(big, r, false)
	var plain: PackedFloat32Array = AudioSynth.buffer(0.36, r)
	AudioSynth.noise(plain, r, 0.0, 0.28, 0.45, 0.12, 63)
	AudioSynth.sweep(plain, r, 0.0, 0.3, 180.0, 90.0, 0.6, 9.0)
	return AudioSynth.to_stream(plain, r, false)


## Moth Lantern lure: a warm glow note with a second one a hair off, so the pair
## flutters like wings. Beacon Lantern is lower and rings longer, Lantern Garland
## lights three notes in a row, one for each flyer.
static func _lantern(id: StringName) -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	if id == &"shot_lantern_garland":
		var garland: PackedFloat32Array = AudioSynth.buffer(0.45, r)
		AudioSynth.bell(garland, r, 0.0, 988.0, 0.15, 11.0)
		AudioSynth.bell(garland, r, 0.06, 1175.0, 0.15, 11.0)
		AudioSynth.bell(garland, r, 0.12, 1480.0, 0.14, 11.0)
		return AudioSynth.to_stream(garland, r, false)
	if id == &"shot_beacon_lantern":
		var beacon: PackedFloat32Array = AudioSynth.buffer(0.6, r)
		AudioSynth.partial(beacon, r, 0.0, 0.6, 784.0, 0.14, 6.0, 300.0, false)
		AudioSynth.partial(beacon, r, 0.0, 0.6, 791.0, 0.14, 6.0, 300.0, false)
		AudioSynth.bell(beacon, r, 0.08, 1175.0, 0.12, 7.0)
		return AudioSynth.to_stream(beacon, r, false)
	var buf: PackedFloat32Array = AudioSynth.buffer(0.36, r)
	AudioSynth.partial(buf, r, 0.0, 0.36, 988.0, 0.13, 10.0, 300.0, false)
	AudioSynth.partial(buf, r, 0.0, 0.36, 997.0, 0.13, 10.0, 300.0, false)
	AudioSynth.sweep(buf, r, 0.0, 0.1, 700.0, 1000.0, 0.1, 22.0)
	AudioSynth.bell(buf, r, 0.06, 1319.0, 0.1, 11.0)
	return AudioSynth.to_stream(buf, r, false)


## A sleeper naps instead of popping: a soft sigh sliding down and one drowsy
## music box note. Gentle, so the player reads "asleep" and not "defeated".
static func _napped() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.7, r)
	AudioSynth.noise(buf, r, 0.0, 0.25, 0.2, 0.1, 71)
	AudioSynth.sweep(buf, r, 0.0, 0.3, 620.0, 380.0, 0.35, 7.0)
	AudioSynth.music_box(buf, r, 0.2, AudioSynth.hz(79), 0.14, false)
	return AudioSynth.to_stream(buf, r, false)


## The sleeper wakes: a small rising blip and two warm music box notes going up.
static func _woke() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.7, r)
	AudioSynth.sweep(buf, r, 0.0, 0.14, 420.0, 760.0, 0.3, 14.0)
	AudioSynth.music_box(buf, r, 0.08, AudioSynth.hz(72), 0.16, false)
	AudioSynth.music_box(buf, r, 0.18, AudioSynth.hz(76), 0.16, false)
	return AudioSynth.to_stream(buf, r, false)


## A digger goes under: a dull scoop of earth and a low falling thump.
static func _burrowed() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.3, r)
	AudioSynth.noise(buf, r, 0.0, 0.14, 0.5, 0.15, 73)
	AudioSynth.noise(buf, r, 0.09, 0.1, 0.35, 0.15, 74)
	AudioSynth.sweep(buf, r, 0.0, 0.16, 220.0, 80.0, 0.55, 18.0)
	return AudioSynth.to_stream(buf, r, false)


## A digger comes up: a short crumble and a low thump rising.
static func _surfaced() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.26, r)
	AudioSynth.noise(buf, r, 0.0, 0.1, 0.45, 0.2, 75)
	AudioSynth.sweep(buf, r, 0.0, 0.14, 90.0, 250.0, 0.5, 16.0)
	AudioSynth.noise(buf, r, 0.1, 0.06, 0.25, 0.2, 76)
	return AudioSynth.to_stream(buf, r, false)


## A blink: a faint high sparkle, two tiny notes and a quick glide. It is the
## quietest sound in the game, because blinkers repeat all wave long.
static func _blinked() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.2, r)
	AudioSynth.sweep(buf, r, 0.0, 0.05, 1400.0, 2400.0, 0.2, 20.0)
	AudioSynth.bell(buf, r, 0.0, 2093.0, 0.16, 22.0)
	AudioSynth.bell(buf, r, 0.04, 2794.0, 0.12, 22.0)
	return AudioSynth.to_stream(buf, r, false)


## A yawn: a slow sigh that falls, with a breath of air. Soft and sleepy, so
## the player reads "the towers are drowsy" and not "something broke".
static func _yawned() -> AudioStreamWAV:
	var r: int = AudioSynth.EFFECT_RATE
	var buf: PackedFloat32Array = AudioSynth.buffer(0.8, r)
	AudioSynth.noise(buf, r, 0.0, 0.5, 0.2, 0.1, 77)
	AudioSynth.sweep(buf, r, 0.0, 0.6, 330.0, 200.0, 0.4, 3.5)
	AudioSynth.sweep(buf, r, 0.0, 0.5, 660.0, 400.0, 0.1, 5.0)
	return AudioSynth.to_stream(buf, r, false)
