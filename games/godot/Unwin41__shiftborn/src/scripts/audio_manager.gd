class_name AudioManager
extends Node
## Autoload "Audio": plays the generated sound effects and the music.
## Game code calls the static helpers, e.g. [code]AudioManager.play(&"axe_hit")[/code].
## They do nothing when the autoload is missing (isolated unit tests).
##
## Each sound owns a small pool of players (its voice cap) and a minimum
## interval, so 50 hits in one frame make one crunchy hit instead of a
## wall of noise. Each play picks a different variant and a random pitch.
## M toggles mute.

const SFX_DIR := "res://assets/audio/sfx/"
const RUN_MUSIC := "res://assets/audio/music/run.ogg"
const TITLE_MUSIC := "res://assets/audio/music/title.ogg"
const BOSS_MUSIC := "res://assets/audio/music/boss.ogg"
const SFX_BUS := &"SFX"
const MUSIC_BUS := &"Music"
const MUTE_ACTION := &"mute"
const SILENT_DB := -60.0
## Real seconds to wait after freeing every player before quitting, so the
## audio thread has mixed at least once and dropped the old playbacks.
const SHUTDOWN_SECONDS := 0.15

## id -> variants, volume (dB), simultaneous voices, minimum ms between
## plays, random pitch range (1.0 = none, 1.1 = 1/1.1 .. 1.1).
const SOUNDS := {
	&"axe_swing": {variants = 3, volume_db = -9.0, voices = 2, interval_ms = 60, pitch = 1.08},
	&"axe_hit": {variants = 3, volume_db = -7.0, voices = 4, interval_ms = 35, pitch = 1.15},
	&"bolt_cast": {variants = 3, volume_db = -13.0, voices = 3, interval_ms = 40, pitch = 1.08},
	&"bolt_hit": {variants = 2, volume_db = -12.0, voices = 3, interval_ms = 35, pitch = 1.12},
	&"crit": {variants = 2, volume_db = -10.0, voices = 2, interval_ms = 70, pitch = 1.05},
	&"hit_resisted": {variants = 2, volume_db = -9.0, voices = 3, interval_ms = 45, pitch = 1.06},
	&"enemy_death": {variants = 3, volume_db = -9.0, voices = 4, interval_ms = 30, pitch = 1.15},
	&"player_hurt": {variants = 2, volume_db = -4.0, voices = 1, interval_ms = 150, pitch = 1.05},
	&"player_death": {variants = 1, volume_db = -2.0, voices = 1, interval_ms = 0, pitch = 1.0},
	&"shift_to_mage": {variants = 1, volume_db = -8.0, voices = 2, interval_ms = 0, pitch = 1.03},
	&"shift_to_warrior": {variants = 1, volume_db = -8.0, voices = 2, interval_ms = 0, pitch = 1.03},
	&"perfect_shift": {variants = 1, volume_db = -4.0, voices = 1, interval_ms = 0, pitch = 1.0},
	&"shift_burst": {variants = 1, volume_db = -4.0, voices = 2, interval_ms = 0, pitch = 1.05},
	&"boss_roar": {variants = 1, volume_db = -2.0, voices = 1, interval_ms = 500, pitch = 1.0},
	&"boss_swap": {variants = 1, volume_db = -4.0, voices = 1, interval_ms = 0, pitch = 1.0},
	&"boss_shot": {variants = 1, volume_db = -6.0, voices = 1, interval_ms = 0, pitch = 1.0},
	&"boss_dash": {variants = 1, volume_db = -5.0, voices = 1, interval_ms = 0, pitch = 1.0},
	&"level_up": {variants = 1, volume_db = -6.0, voices = 1, interval_ms = 0, pitch = 1.0},
	&"card_pick": {variants = 1, volume_db = -6.0, voices = 1, interval_ms = 0, pitch = 1.0},
	&"ui_move": {variants = 1, volume_db = -12.0, voices = 2, interval_ms = 40, pitch = 1.0},
	&"run_win": {variants = 1, volume_db = -4.0, voices = 1, interval_ms = 0, pitch = 1.0},
}

static var _instance: AudioManager

## Per sound id: its player pool, its variant streams, the next voice to
## use, the last variant played and when it last played.
var _voices: Dictionary[StringName, Array] = {}
var _streams: Dictionary[StringName, Array] = {}
var _next_voice: Dictionary[StringName, int] = {}
var _last_variant: Dictionary[StringName, int] = {}
var _last_played_ms: Dictionary[StringName, int] = {}
var _music: AudioStreamPlayer
var _music_tween: Tween
## False on the Dummy driver (headless runs). It never mixes, so started
## playbacks are never released and Godot reports them as leaks at exit.
var _can_output: bool = true
## Set by the first close request; later ones are ignored so the quit
## always waits for shutdown().
var _closing: bool = false


static func sfx_path(id: StringName, variant: int) -> String:
	return SFX_DIR + "%s_%d.wav" % [id, variant]


## True when a sound last played at [param last_ms] may play again at
## [param now_ms]. A negative [param last_ms] means it never played.
static func should_play(last_ms: int, now_ms: int, interval_ms: int) -> bool:
	return last_ms < 0 or now_ms - last_ms >= interval_ms


## A variant index in 0..count-1 that differs from [param last] when there
## is more than one. [param roll] is any non-negative random integer.
static func pick_variant(count: int, last: int, roll: int) -> int:
	if count <= 1:
		return 0
	if last < 0 or last >= count:
		return roll % count
	var pick := roll % (count - 1)
	return pick if pick < last else pick + 1


static func play(id: StringName) -> void:
	if _instance != null:
		_instance._play(id)


## Starts [param path] looping, fading in over [param fade] seconds. If
## that track is already playing (even fading out), it fades back in.
static func play_music(path: String, fade: float = 1.0) -> void:
	if _instance != null:
		_instance._play_music(path, fade)


static func stop_music(fade: float = 1.0) -> void:
	if _instance != null:
		_instance._stop_music(fade)


## Frees every player and waits [constant SHUTDOWN_SECONDS] of real time. Quitting while a player is
## still playing makes Godot report its playbacks as leaked, so the close
## request and test scripts await this right before quitting. Sounds are
## silent afterwards.
static func shutdown() -> void:
	var manager := _instance
	if manager == null:
		return
	_instance = null
	for child in manager.get_children():
		child.queue_free()
	# Process while paused and ignore time scale: real time, even in hitstop.
	await manager.get_tree().create_timer(SHUTDOWN_SECONDS, true, false, true).timeout


func _enter_tree() -> void:
	_instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Quit only after shutdown() so no playback is still alive at exit.
	get_tree().auto_accept_quit = false


func _exit_tree() -> void:
	if _instance == self:
		_instance = null


func _ready() -> void:
	_can_output = AudioServer.get_driver_name() != "Dummy"
	for id: StringName in SOUNDS:
		_add_sound(id, SOUNDS[id])
	_music = AudioStreamPlayer.new()
	_music.bus = MUSIC_BUS
	add_child(_music)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not _closing:
		_closing = true
		await shutdown()
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action(MUTE_ACTION) and event.is_action_pressed(MUTE_ACTION):
		var master := AudioServer.get_bus_index(&"Master")
		AudioServer.set_bus_mute(master, not AudioServer.is_bus_mute(master))
		get_viewport().set_input_as_handled()


func _play(id: StringName) -> void:
	if not _voices.has(id):
		push_warning("AudioManager: unknown sound %s" % id)
		return
	var config: Dictionary = SOUNDS[id]
	var now := Time.get_ticks_msec()
	if not should_play(_last_played_ms.get(id, -1), now, config.interval_ms):
		return
	_last_played_ms[id] = now
	var pool: Array = _voices[id]
	var voice: AudioStreamPlayer = pool[_next_voice[id]]
	_next_voice[id] = (_next_voice[id] + 1) % pool.size()
	var streams: Array = _streams[id]
	var variant := pick_variant(streams.size(), _last_variant.get(id, -1), randi())
	_last_variant[id] = variant
	voice.stream = streams[variant]
	voice.pitch_scale = randf_range(1.0 / config.pitch, config.pitch)
	if _can_output:
		voice.play()


func _play_music(path: String, fade: float) -> void:
	if _music.playing and _music.stream != null and _music.stream.resource_path == path:
		_fade_music_to(0.0, fade)
		return
	var stream := load(path) as AudioStreamOggVorbis
	if stream == null:
		push_warning("AudioManager: cannot load music %s" % path)
		return
	stream.loop = true
	_music.stream = stream
	_music.volume_db = SILENT_DB
	if _can_output:
		_music.play()
	_fade_music_to(0.0, fade)


func _stop_music(fade: float) -> void:
	if not _music.playing:
		return
	_fade_music_to(SILENT_DB, fade).tween_callback(_music.stop)


func _fade_music_to(volume_db: float, fade: float) -> Tween:
	if _music_tween != null:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music, ^"volume_db", volume_db, maxf(fade, 0.01))
	return _music_tween


func _add_sound(id: StringName, config: Dictionary) -> void:
	var streams: Array[AudioStream] = []
	for i in config.variants:
		streams.append(load(sfx_path(id, i)))
	var pool: Array[AudioStreamPlayer] = []
	for i in config.voices:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = config.volume_db
		voice.bus = SFX_BUS
		add_child(voice)
		pool.append(voice)
	_streams[id] = streams
	_voices[id] = pool
	_next_voice[id] = 0
