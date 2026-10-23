extends Node

signal web_audio_unlocked

const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"
const DEFAULT_MUSIC_VOLUME: float = 0.75
const DEFAULT_SFX_VOLUME: float = 1.0
const MIN_AUDIBLE_VOLUME: float = 0.001
const MUTED_VOLUME_DB: float = -80.0

var _music_volume: float = DEFAULT_MUSIC_VOLUME
var _sfx_volume: float = DEFAULT_SFX_VOLUME
var _web_audio_unlocked: bool = false
var _pending_web_music_players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	ensure_audio_buses()
	set_music_volume(DEFAULT_MUSIC_VOLUME)
	set_sfx_volume(DEFAULT_SFX_VOLUME)
	if not _is_web_export():
		_mark_web_audio_unlocked()


func _input(event: InputEvent) -> void:
	if _web_audio_unlocked or not _is_web_export():
		return
	if not _is_audio_activation_event(event):
		return

	request_web_audio_unlock()
	_mark_web_audio_unlocked()


func ensure_audio_buses() -> void:
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)


func get_music_volume() -> float:
	return _music_volume


func set_music_volume(volume: float) -> void:
	_music_volume = clampf(volume, 0.0, 1.0)
	_set_bus_volume_linear(MUSIC_BUS, _music_volume)


func get_sfx_volume() -> float:
	return _sfx_volume


func set_sfx_volume(volume: float) -> void:
	_sfx_volume = clampf(volume, 0.0, 1.0)
	_set_bus_volume_linear(SFX_BUS, _sfx_volume)


func is_web_audio_unlocked() -> bool:
	return _web_audio_unlocked


func request_web_audio_unlock() -> void:
	if not _is_web_export():
		_mark_web_audio_unlocked()
		return

	if not Engine.has_singleton("JavaScriptBridge"):
		return

	JavaScriptBridge.eval(
		"""
		if (typeof GodotAudio !== "undefined" && GodotAudio.ctx && GodotAudio.ctx.state !== "running") {
			GodotAudio.ctx.resume();
		}
		"""
	)


func play_music_when_ready(player: AudioStreamPlayer) -> void:
	if player == null or not is_instance_valid(player):
		return

	player.stream_paused = false
	if not _is_web_export() or _web_audio_unlocked:
		if not player.playing:
			player.play()
		return

	if player.playing:
		player.stop()
	if not _pending_web_music_players.has(player):
		_pending_web_music_players.append(player)


func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(String(bus_name)) >= 0:
		return

	AudioServer.add_bus(AudioServer.bus_count)
	var bus_index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, String(bus_name))
	AudioServer.set_bus_send(bus_index, "Master")


func _set_bus_volume_linear(bus_name: StringName, volume: float) -> void:
	ensure_audio_buses()
	var bus_index := AudioServer.get_bus_index(String(bus_name))
	if bus_index < 0:
		return

	if volume <= MIN_AUDIBLE_VOLUME:
		AudioServer.set_bus_volume_db(bus_index, MUTED_VOLUME_DB)
		AudioServer.set_bus_mute(bus_index, true)
		return

	AudioServer.set_bus_mute(bus_index, false)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume))


func _mark_web_audio_unlocked() -> void:
	if _web_audio_unlocked:
		return

	_web_audio_unlocked = true
	for player in _pending_web_music_players:
		if player != null and is_instance_valid(player):
			player.play()
	_pending_web_music_players.clear()
	web_audio_unlocked.emit()


func _is_web_export() -> bool:
	return OS.has_feature("web")


func _is_audio_activation_event(event: InputEvent) -> bool:
	var key_event := event as InputEventKey
	if key_event != null:
		return key_event.pressed and not key_event.echo

	var mouse_button_event := event as InputEventMouseButton
	if mouse_button_event != null:
		return mouse_button_event.pressed

	var screen_touch_event := event as InputEventScreenTouch
	if screen_touch_event != null:
		return screen_touch_event.pressed

	return false
