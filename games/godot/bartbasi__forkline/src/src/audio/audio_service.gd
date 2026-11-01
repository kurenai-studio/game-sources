# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name AudioService
extends Node
## Plays Forkline's sounds and music. The App creates one and passes it down.
## Battle events become sounds (play_events), screens ask for UI sounds
## (play_ui), and set_music picks the menu or battle tune.
##
## Every stream is built once, on worker threads, when the service is created
## (SoundBank). A sound asked for before it is built is skipped, and a
## music track asked for early starts as soon as it is ready. Playing a
## sound is then a handful of array reads and one play() call.
##
## Mixing: 12 voices in all, at most 3 of the same sound at once, and a short
## gap between two starts of the same sound, so a big wave at 3x stays soft.
## A limiter on the Sfx bus is the last guard against clipping.
##
## Foreground only (phones): nothing plays while the app is not in front.
## Android logs "AudioHardening background playback" when audio starts a
## moment before the activity shows or runs on after it leaves, and a future
## Android may mute that. So on a phone the service starts out silent and goes
## to the front on NOTIFICATION_APPLICATION_RESUMED or FOCUS_IN. If neither
## arrives, the second drawn frame counts as in front, because a frame is only
## drawn once the activity has a surface. APPLICATION_PAUSED and FOCUS_OUT stop
## every voice and the music at once. The notifications reach this node by
## themselves, so the App forwards nothing. On Windows and in tests the
## service is always in front, as before.
##
## Two switches. set_enabled is the sound switch (the HUD button and the Settings
## Sound effects row): off silences sounds and music. set_music_on is the music
## switch (the Settings Music row): off silences only the music, with a short
## fade. Music plays only when both are on and the app is in front. Sound
## effects follow set_enabled alone. Music back on starts the wanted tune again
## from its beginning with the usual fade in.

const SFX_BUS: StringName = &"Sfx"
const MUSIC_BUS: StringName = &"Music"
## Total sound voices (architecture section 9).
const VOICES: int = 12
## Most voices of one sound at the same time (architecture section 9).
const MAX_SAME: int = 3
const MUSIC_DB: float = -12.0
const FADE_IN_SECONDS: float = 0.8
const FADE_OUT_SECONDS: float = 0.35
## Time the audio thread needs to drop stopped playbacks when the service leaves the tree.
const PLAYBACK_DROP_MS: int = 200
## Frames drawn before a phone service counts as in front when no RESUMED or
## FOCUS_IN notification has arrived.
const FRONT_FRAMES: int = 2

## Event kind (architecture 3.1, 14.6) to sound id. Every kind has a sound.
## break_started and sped_up warn the player, so they are heard. released and
## interest are soft and quiet. The expansion kinds: napped and woke show that
## a sleeper did not pop and is back, yawned that towers are dozing (silent when
## no tower dozes), burrowed and surfaced are low earthy sounds, and blinked is a
## faint sparkle. The three that repeat all game (burrowed, surfaced, blinked)
## are frequent sounds, so they give way to every other sound. no_lives_lost
## has no entry on purpose: the won sound already says it.
const EVENT_SOUNDS: Dictionary[StringName, StringName] = {
	&"wave_started": &"wave_started",
	&"spawned": &"spawned",
	&"fired": &"fired",
	&"popped": &"popped",
	&"defeated": &"defeated",
	&"healed": &"healed",
	&"leaked": &"leaked",
	&"gate_broken": &"gate_broken",
	&"wave_cleared": &"wave_cleared",
	&"build_started": &"build_started",
	&"built": &"built",
	&"upgraded": &"upgraded",
	&"sold": &"sold",
	&"gate_placed": &"gate_placed",
	&"gate_removed": &"gate_removed",
	&"won": &"won",
	&"lost": &"lost",
	&"released": &"released",
	&"break_started": &"break_started",
	&"sped_up": &"sped_up",
	&"interest": &"interest",
	&"napped": &"napped",
	&"woke": &"woke",
	&"burrowed": &"burrowed",
	&"surfaced": &"surfaced",
	&"blinked": &"blinked",
	&"yawned": &"yawned",
}
## UI sound names (architecture 3.8). Each is also a sound id.
const UI_SOUNDS: Array[StringName] = [&"tap", &"refuse", &"star"]

## How loud each sound plays, in dB.
const GAIN_DB: Dictionary[StringName, float] = {
	&"wave_started": -6.0, &"spawned": -16.0, &"fired": -14.0, &"popped": -13.0,
	&"defeated": -11.0, &"healed": -14.0, &"leaked": -6.0, &"gate_broken": -6.0,
	&"wave_cleared": -6.0, &"build_started": -9.0, &"built": -7.0, &"upgraded": -7.0,
	&"sold": -8.0, &"gate_placed": -7.0, &"gate_removed": -8.0, &"won": -4.0,
	&"lost": -5.0, &"tap": -8.0, &"refuse": -8.0, &"star": -6.0,
	&"released": -16.0, &"break_started": -9.0, &"sped_up": -10.0, &"interest": -14.0,
	&"shot_quickshot": -14.0, &"shot_stone_sling": -13.0,
	&"shot_pumpkin_catapult": -12.0, &"shot_prize_pumpkin": -11.0, &"shot_jam_pot": -12.0,
	&"shot_longbow_loft": -13.0, &"shot_giant_bow": -12.0, &"shot_triple_bow": -14.0,
	&"shot_firework_tower": -14.0, &"shot_star_bloom": -14.0, &"shot_skyrocket": -14.0,
	&"shot_bramble_cottage": -15.0, &"shot_wild_bramble": -15.0, &"shot_holly_crown": -15.0,
	&"shot_snow_fort": -13.0, &"shot_big_snowball": -12.0, &"shot_flurry": -14.0,
	&"shot_moth_lantern": -13.0, &"shot_beacon_lantern": -12.0, &"shot_lantern_garland": -13.0,
	&"napped": -12.0, &"woke": -12.0, &"burrowed": -17.0, &"surfaced": -17.0,
	&"blinked": -20.0, &"yawned": -12.0,
}
## The least time between two starts of the same sound, in ms. Events in the
## same frame therefore make one sound, not a stack.
const GAP_MS: Dictionary[StringName, int] = {
	&"wave_started": 200, &"spawned": 90, &"fired": 55, &"popped": 60,
	&"defeated": 45, &"healed": 150, &"leaked": 120, &"gate_broken": 150,
	&"wave_cleared": 300, &"build_started": 300, &"built": 80, &"upgraded": 80,
	&"sold": 80, &"gate_placed": 80, &"gate_removed": 80, &"won": 500,
	&"lost": 500, &"tap": 60, &"refuse": 120, &"star": 80,
	&"released": 140, &"break_started": 400, &"sped_up": 300, &"interest": 300,
	&"shot_quickshot": 55, &"shot_stone_sling": 55,
	&"shot_pumpkin_catapult": 70, &"shot_prize_pumpkin": 70, &"shot_jam_pot": 70,
	&"shot_longbow_loft": 60, &"shot_giant_bow": 60, &"shot_triple_bow": 60,
	&"shot_firework_tower": 70, &"shot_star_bloom": 70, &"shot_skyrocket": 70,
	# A pulse is one sound for all its hits, and many cottages pulse in a big wave,
	# so the cottage gap is the longest of the shots.
	&"shot_bramble_cottage": 110, &"shot_wild_bramble": 110, &"shot_holly_crown": 110,
	&"shot_snow_fort": 70, &"shot_big_snowball": 70, &"shot_flurry": 70,
	&"shot_moth_lantern": 70, &"shot_beacon_lantern": 70, &"shot_lantern_garland": 70,
	&"napped": 150, &"woke": 150, &"burrowed": 200, &"surfaced": 200,
	&"blinked": 250, &"yawned": 300,
}
## Shot sounds by tower id: the tower's plain shot, then its tier 3 path 0 and
## path 1 (the order of architecture 2.2). The Lullaby Bell and the Bakery never
## fire (architecture 3.1), so they have no row, and neither has the Scarecrow
## (RULES 5.13). Unknown towers use &"fired". A pulse or a line is one fired
## event, so it plays one sound however many creatures it hits.
const SHOT_SOUNDS: Dictionary[StringName, Array] = {
	&"sling_post": [&"fired", &"shot_quickshot", &"shot_stone_sling"],
	&"pumpkin_catapult": [&"shot_pumpkin_catapult", &"shot_prize_pumpkin", &"shot_jam_pot"],
	&"longbow_loft": [&"shot_longbow_loft", &"shot_giant_bow", &"shot_triple_bow"],
	&"firework_tower": [&"shot_firework_tower", &"shot_star_bloom", &"shot_skyrocket"],
	&"bramble_cottage": [&"shot_bramble_cottage", &"shot_wild_bramble", &"shot_holly_crown"],
	&"snow_fort": [&"shot_snow_fort", &"shot_big_snowball", &"shot_flurry"],
	&"moth_lantern": [&"shot_moth_lantern", &"shot_beacon_lantern", &"shot_lantern_garland"],
}
## Every shot sound.
const SHOT_IDS: Dictionary[StringName, bool] = {
	&"fired": true,
	&"shot_quickshot": true, &"shot_stone_sling": true,
	&"shot_pumpkin_catapult": true, &"shot_prize_pumpkin": true, &"shot_jam_pot": true,
	&"shot_longbow_loft": true, &"shot_giant_bow": true, &"shot_triple_bow": true,
	&"shot_firework_tower": true, &"shot_star_bloom": true, &"shot_skyrocket": true,
	&"shot_bramble_cottage": true, &"shot_wild_bramble": true, &"shot_holly_crown": true,
	&"shot_snow_fort": true, &"shot_big_snowball": true, &"shot_flurry": true,
	&"shot_moth_lantern": true, &"shot_beacon_lantern": true, &"shot_lantern_garland": true,
}
## Most shot sounds of any kind at once, so a big wave never turns into a rattle.
const MAX_SHOTS: int = 4
## Frequent sounds: every shot, plus these. When all voices are busy they give
## way to every other sound. A big split releases many creatures, so released is one.
## Diggers and blinkers repeat all wave long, so those three are too.
const OTHER_COMMON: Array[StringName] = [
	&"spawned", &"popped", &"defeated", &"healed", &"released",
	&"burrowed", &"surfaced", &"blinked",
]

## Shots take one of five pitches by tower cell, and puffs and blinks one of three by
## creature id, so a big wave sounds like a music box, not a machine.
const SHOT_PITCHES: PackedFloat32Array = [0.84, 0.94, 1.05, 1.25, 1.4]
const PUFF_PITCHES: PackedFloat32Array = [0.9, 1.0, 1.12]

var _bank: SoundBank = null
var _enabled: bool = true
var _music_on: bool = true
var _voices: Array[AudioStreamPlayer] = []
var _voice_sound: Array[StringName] = []
var _voice_end: PackedInt64Array = PackedInt64Array()
var _last_start: Dictionary[StringName, int] = {}
var _cache: Dictionary[StringName, AudioStreamWAV] = {}
var _music: AudioStreamPlayer = null
var _music_wanted: StringName = &""
var _music_playing: StringName = &""
var _tween: Tween = null
## True when the app is in front, or when the service does not track that.
var _front: bool = true
## True when this service tracks the app coming to the front and leaving.
var _gated: bool = false
## True once a PAUSED or FOCUS_OUT notification has arrived.
var _left: bool = false
var _frames: int = 0


## With `gated` (the default on a phone) the service stays silent until the app
## is in front. Tests pass it to try that on a desktop.
func _init(gated: bool = OS.has_feature("mobile")) -> void:
	# Everything is set up here, not in _ready, so the service works before it
	# joins the tree (the App may pick music first) and under a test runner.
	_gated = gated
	_front = not gated
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(SFX_BUS, true)
	_ensure_bus(MUSIC_BUS, false)
	for i: int in VOICES:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_voices.append(player)
		_voice_sound.append(&"")
		_voice_end.append(0)
	_music = AudioStreamPlayer.new()
	_music.bus = MUSIC_BUS
	_music.volume_db = MUSIC_DB
	add_child(_music)
	_bank = SoundBank.new()
	_bank.start()


func _ready() -> void:
	# A phone service runs frames until it is in front (the frame fallback).
	set_process(not _front and not _left)
	# tree_exiting fires before the players below leave the tree.
	tree_exiting.connect(_release_playback)
	# Music picked before the node joined the tree starts now.
	_music_playing = &""
	if _can_music() and _music_wanted != &"":
		_apply_music()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _bank != null:
		# Waits for any build still running, so no worker task outlives the service.
		_bank.wait()
	elif not _gated:
		return
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_left = false
		_set_front(true)
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_left = true
		_set_front(false)


func _process(_delta: float) -> void:
	# Runs while the app is not yet in front (the frame fallback), and while a
	# music track is waiting for its stream to finish building.
	if not _front:
		if _left:
			set_process(false)
			return
		_frames += 1
		if _frames >= FRONT_FRAMES:
			_set_front(true)
		return
	if _music_wanted == &"" or not _enabled or not _music_on or _music_playing == _music_wanted:
		set_process(false)
		return
	_start_music()


## True when sound may play: on, and the app in front.
func _can_play() -> bool:
	return _enabled and _front


## True when music may play: sound on, music on, and the app in front.
func _can_music() -> bool:
	return _enabled and _music_on and _front


## True when the app is in front, or the service does not track that.
func is_in_front() -> bool:
	return _front


## Moves the service to the front or back. Going back stops every voice and the
## music at once. Coming forward brings the wanted music back.
func _set_front(front: bool) -> void:
	if front == _front:
		return
	_front = front
	if not front:
		_stop_all()
		set_process(false)
		return
	_frames = 0
	set_process(false)
	if _can_music() and _music_wanted != &"":
		_apply_music()


## Stops every voice and the music, with no fade.
func _stop_all() -> void:
	_kill_tween()
	for i: int in _voices.size():
		_voices[i].stop()
		_voice_end[i] = 0
	_music.stop()
	_music_playing = &""


## Stops every player and lets go of its stream, so no playback outlives the
## service. The audio thread drops a stopped playback on its next mix, so when
## something was playing this waits a moment for that mix. Otherwise a playing
## player at exit leaks its stream and playback.
func _release_playback() -> void:
	# A quit during the first seconds must not tear the engine down under the
	# worker threads that are still building sounds.
	if _bank != null:
		_bank.wait()
	_kill_tween()
	var was_playing: bool = false
	for player: AudioStreamPlayer in _voices:
		was_playing = was_playing or player.stream != null
		player.stop()
		player.stream = null
	if _music != null:
		was_playing = was_playing or _music.stream != null
		_music.stop()
		_music.stream = null
	_music_playing = &""
	if was_playing:
		OS.delay_msec(PLAYBACK_DROP_MS)


## Turns every sound and the music on or off (the Settings toggle). Off stops
## everything at once and ignores new sounds. On brings the wanted music back.
func set_enabled(on: bool) -> void:
	if on == _enabled:
		return
	_enabled = on
	if not on:
		_stop_all()
	elif _can_music() and _music_wanted != &"":
		_apply_music()


## Turns the music on or off, leaving sound effects alone (the music switch).
## Off fades the music out in a third of a second. On starts the wanted tune
## again with a fade in. Nothing starts while sound is off or the app is away.
func set_music_on(on: bool) -> void:
	if on == _music_on:
		return
	_music_on = on
	if not on:
		_kill_tween()
		# A track change may be mid fade out (nothing marked as playing, the
		# player still sounding), so the player itself is checked too.
		if _music_playing != &"" or _music.playing:
			_music_playing = &""
			_fade_out_then(Callable())
	elif _can_music() and _music_wanted != &"":
		_apply_music()


## Turns battle events (architecture 3.1) into sounds. Unknown events are ignored.
func play_events(events: Array[Dictionary]) -> void:
	if not _can_play() or _voices.is_empty():
		return
	for event: Dictionary in events:
		var sound: StringName = sound_for(event)
		if sound == &"":
			continue
		_play(sound, _pitch_for(sound, event))


## Plays a UI sound: &"tap", &"refuse" or &"star". Anything else is ignored.
func play_ui(sound: StringName) -> void:
	if not _can_play() or _voices.is_empty() or not UI_SOUNDS.has(sound):
		return
	_play(sound, 1.0)


## Starts the &"menu" or &"battle" tune, or silence for &"". An unknown name
## counts as silence. The tune loops until another is picked.
func set_music(track: StringName) -> void:
	var wanted: StringName = track if SoundBank.TRACKS.has(track) else &""
	if wanted == _music_wanted:
		return
	_music_wanted = wanted
	if _can_music():
		_apply_music()


## The track asked for last, whether or not sound is on. &"" for silence.
func current_music() -> StringName:
	return _music_wanted


## True when the music is playing right now.
func is_music_playing() -> bool:
	return _can_music() and _music_playing != &"" and (not _music.is_inside_tree() or _music.playing)


func is_enabled() -> bool:
	return _enabled


## True when the music switch is on. Music still needs sound on to be heard.
func is_music_on() -> bool:
	return _music_on


## Voices in use right now. With a sound id, only that sound's voices.
func voice_count(sound: StringName = &"") -> int:
	var now: int = Time.get_ticks_msec()
	var count: int = 0
	for i: int in _voices.size():
		if _voice_end[i] > now and (sound == &"" or _voice_sound[i] == sound):
			count += 1
	return count


## True once every sound and track is built.
func is_ready() -> bool:
	return _bank != null and _bank.is_complete()


## Blocks until every sound is built. For tests and tools; the game never needs it.
func wait_until_ready() -> void:
	if _bank == null:
		return
	_bank.wait()
	if _can_music() and _music_wanted != &"" and _music_playing != _music_wanted:
		_start_music()


## The sound an event makes, or &"" for an unknown or malformed event. A
## `fired` event picks its shot by `tower` and `spec` (architecture 3.1). A
## `yawned` event with no tower in `cells` is silent, because nothing dozes.
static func sound_for(event: Dictionary) -> StringName:
	var kind: Variant = event.get("kind", &"")
	if typeof(kind) != TYPE_STRING_NAME and typeof(kind) != TYPE_STRING:
		return &""
	var sound: StringName = EVENT_SOUNDS.get(StringName(kind), &"")
	if sound == &"yawned":
		var cells: Variant = event.get("cells")
		return sound if cells is Array and not (cells as Array).is_empty() else &""
	if sound != &"fired":
		return sound
	var tower: Variant = event.get("tower")
	if typeof(tower) != TYPE_STRING_NAME and typeof(tower) != TYPE_STRING:
		return sound
	var row: Array = SHOT_SOUNDS.get(StringName(tower), [])
	if row.is_empty():
		return sound
	var spec: Variant = event.get("spec", -1)
	var index: int = 0
	if typeof(spec) == TYPE_INT and int(spec) >= 0 and int(spec) <= 1:
		index = int(spec) + 1
	return row[index]


func _pitch_for(sound: StringName, event: Dictionary) -> float:
	if SHOT_IDS.has(sound):
		var cell: Variant = event.get("cell")
		if cell is Vector2i:
			var c: Vector2i = cell
			return SHOT_PITCHES[absi(c.x * 3 + c.y * 5) % SHOT_PITCHES.size()]
	elif sound == &"defeated" or sound == &"blinked":
		var id: Variant = event.get("id")
		if typeof(id) == TYPE_INT:
			return PUFF_PITCHES[absi(int(id)) % PUFF_PITCHES.size()]
	return 1.0


func _stream(id: StringName) -> AudioStreamWAV:
	var found: AudioStreamWAV = _cache.get(id)
	if found == null and _bank != null:
		found = _bank.stream(id)
		if found != null:
			_cache[id] = found
	return found


## Starts one sound if the caps allow it.
func _play(sound: StringName, pitch: float) -> void:
	var stream: AudioStreamWAV = _stream(sound)
	if stream == null:
		return
	var now: int = Time.get_ticks_msec()
	if now - int(_last_start.get(sound, -1000000)) < int(GAP_MS.get(sound, 60)):
		return
	var shot: bool = SHOT_IDS.has(sound)
	var common: bool = shot or OTHER_COMMON.has(sound)
	var shots: int = 0
	var free: int = -1
	var same: int = 0
	var oldest_same: int = -1
	var oldest_common: int = -1
	var oldest: int = -1
	for i: int in _voices.size():
		if _voice_end[i] <= now:
			if free < 0:
				free = i
			continue
		if oldest < 0 or _voice_end[i] < _voice_end[oldest]:
			oldest = i
		if _voice_sound[i] == sound:
			same += 1
			if oldest_same < 0 or _voice_end[i] < _voice_end[oldest_same]:
				oldest_same = i
		var other: StringName = _voice_sound[i]
		if SHOT_IDS.has(other):
			shots += 1
		if SHOT_IDS.has(other) or OTHER_COMMON.has(other):
			if oldest_common < 0 or _voice_end[i] < _voice_end[oldest_common]:
				oldest_common = i
	if shot and shots >= MAX_SHOTS:
		return
	var slot: int = free
	if same >= MAX_SAME:
		if common:
			return
		slot = oldest_same
	elif free < 0:
		if common:
			return
		slot = oldest_common if oldest_common >= 0 else oldest
	var player: AudioStreamPlayer = _voices[slot]
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = float(GAIN_DB.get(sound, -8.0))
	if player.is_inside_tree():
		player.play()
	_voice_sound[slot] = sound
	_voice_end[slot] = now + int(stream.get_length() / pitch * 1000.0) + 20
	_last_start[sound] = now


# Music.

func _apply_music() -> void:
	_kill_tween()
	if _music_wanted == &"":
		if _music_playing != &"" or _music.playing:
			_music_playing = &""
			_fade_out_then(Callable())
		return
	if _music_playing == _music_wanted:
		return
	if _music_playing != &"":
		_music_playing = &""
		_fade_out_then(_start_music)
	else:
		_start_music()


func _start_music() -> void:
	if not _can_music() or _music_wanted == &"":
		return
	var stream: AudioStreamWAV = _stream(_music_wanted)
	if stream == null:
		set_process(true)
		return
	set_process(false)
	_kill_tween()
	_music_playing = _music_wanted
	if not is_inside_tree():
		return
	if _music.playing and _music.stream == stream:
		# A fade out was cut short by music coming back on. Climb from the
		# current level, so there is no jump and no restart.
		_tween = create_tween()
		_tween.tween_property(_music, "volume_db", MUSIC_DB, FADE_IN_SECONDS)
		return
	_music.stream = stream
	_music.volume_db = -40.0
	_music.play()
	_tween = create_tween()
	_tween.tween_property(_music, "volume_db", MUSIC_DB, FADE_IN_SECONDS)


func _fade_out_then(next: Callable) -> void:
	if not is_inside_tree():
		_music.stop()
		if next.is_valid():
			next.call()
		return
	_tween = create_tween()
	_tween.tween_property(_music, "volume_db", -40.0, FADE_OUT_SECONDS)
	_tween.tween_callback(_music.stop)
	if next.is_valid():
		_tween.tween_callback(next)


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


## Adds a bus under Master if it is missing. The Sfx bus gets a limiter.
func _ensure_bus(bus_name: StringName, limiter: bool) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, &"Master")
	if limiter:
		var effect: AudioEffectLimiter = AudioEffectLimiter.new()
		effect.ceiling_db = -1.0
		effect.threshold_db = -6.0
		AudioServer.add_bus_effect(index, effect)
