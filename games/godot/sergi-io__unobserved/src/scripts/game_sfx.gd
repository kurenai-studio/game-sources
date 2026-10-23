extends RefCounted
class_name GameSfx

const CUE_LASER: StringName = &"laser"
const CUE_LEVEL_UP: StringName = &"level_up"
const CUE_MISSILE_LAUNCH: StringName = &"missile_launch"
const CUE_PICKUP: StringName = &"pickup"
const CUE_SHIELD: StringName = &"shield"
const CUE_PROPULSION: StringName = &"propulsion"
const CUE_SCANNER: StringName = &"scanner"
const CUE_BEACON_COLONY: StringName = &"beacon_colony"
const CUE_MISSILE_EXPLOSION: StringName = &"missile_explosion"
const CUE_MEDIUM_EXPLOSION: StringName = &"medium_explosion"
const CUE_NUKE_EXPLOSION: StringName = &"nuke_explosion"
const CUE_DASH: StringName = &"dash"
const CUE_VORTEX: StringName = &"vortex"

const LASER_STREAM: AudioStream = preload("res://sfx/laser.ogg")
const LEVEL_UP_STREAM: AudioStream = preload("res://sfx/level_up.ogg")
const MISSILE_LAUNCH_STREAM: AudioStream = preload("res://sfx/misile_launch.mp3")
const PICKUP_STREAM: AudioStream = preload("res://sfx/pickup.ogg")
const SHIELD_STREAM: AudioStream = preload("res://sfx/shield.ogg")
const PROPULSION_STREAM: AudioStream = preload("res://sfx/propulsion.mp3")
const SCANNER_STREAM: AudioStream = preload("res://sfx/scanner.ogg")
const BEACON_COLONY_STREAM: AudioStream = preload("res://sfx/beacon_colony.ogg")
const MISSILE_EXPLOSION_STREAM: AudioStream = preload("res://sfx/misile_explosion.ogg")
const MEDIUM_EXPLOSION_STREAM: AudioStream = preload("res://sfx/medium_explossion.ogg")
const NUKE_EXPLOSION_STREAM: AudioStream = preload("res://sfx/nuke_explosion.ogg")
const DASH_STREAM: AudioStream = preload("res://sfx/dash.ogg")
const VORTEX_STREAM: AudioStream = preload("res://sfx/vortex.ogg")

const DEFAULT_BUS: StringName = &"Master"
const SFX_BUS: StringName = &"SFX"


static func play(context: Node, cue: StringName, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if context == null or not is_instance_valid(context):
		return

	request_web_audio_unlock()
	var host := _get_playback_host(context)
	if host == null:
		return

	match cue:
		CUE_LASER:
			_play_laser_layers(host, volume_db, pitch_scale)
		CUE_MISSILE_EXPLOSION:
			_play_missile_explosion_layers(host, volume_db, pitch_scale)
		CUE_MEDIUM_EXPLOSION:
			_play_medium_explosion_layers(host, volume_db, pitch_scale)
		CUE_NUKE_EXPLOSION:
			_play_nuke_explosion_layers(host, volume_db, pitch_scale)
		_:
			var stream := _get_stream(cue)
			if stream == null:
				return
			_play_stream_layer(host, stream, volume_db, pitch_scale)


static func get_stream(cue: StringName) -> AudioStream:
	return _get_stream(cue)


static func get_bus_name() -> StringName:
	return _resolve_bus_name()


static func request_web_audio_unlock() -> void:
	if not OS.has_feature("web"):
		return

	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return

	var audio_settings := tree.root.get_node_or_null("AudioSettings")
	if audio_settings != null and audio_settings.has_method("request_web_audio_unlock"):
		audio_settings.call("request_web_audio_unlock")


static func _get_stream(cue: StringName) -> AudioStream:
	match cue:
		CUE_LASER:
			return LASER_STREAM
		CUE_LEVEL_UP:
			return LEVEL_UP_STREAM
		CUE_MISSILE_LAUNCH:
			return MISSILE_LAUNCH_STREAM
		CUE_PICKUP:
			return PICKUP_STREAM
		CUE_SHIELD:
			return SHIELD_STREAM
		CUE_SCANNER:
			return SCANNER_STREAM
		CUE_BEACON_COLONY:
			return BEACON_COLONY_STREAM
		CUE_MISSILE_EXPLOSION:
			return MISSILE_EXPLOSION_STREAM
		CUE_MEDIUM_EXPLOSION:
			return MEDIUM_EXPLOSION_STREAM
		CUE_NUKE_EXPLOSION:
			return NUKE_EXPLOSION_STREAM
		CUE_DASH:
			return DASH_STREAM
		CUE_VORTEX:
			return VORTEX_STREAM
		CUE_PROPULSION:
			return PROPULSION_STREAM
		_:
			return null


static func _get_playback_host(context: Node) -> Node:
	var tree := context.get_tree()
	if tree == null:
		return null
	if tree.current_scene != null and is_instance_valid(tree.current_scene):
		return tree.current_scene

	return tree.root


static func _resolve_bus_name() -> StringName:
	if AudioServer.get_bus_index(String(SFX_BUS)) >= 0:
		return SFX_BUS

	return DEFAULT_BUS


static func _play_laser_layers(host: Node, volume_db: float, pitch_scale: float) -> void:
	_play_stream_layer(host, LASER_STREAM, volume_db - 1.0, pitch_scale * randf_range(0.99, 1.03))
	_play_stream_layer(host, LASER_STREAM, volume_db - 7.5, pitch_scale * randf_range(1.2, 1.28), 0.012)
	_play_stream_layer(host, LASER_STREAM, volume_db - 13.0, pitch_scale * randf_range(0.8, 0.88), 0.026)


static func _play_missile_explosion_layers(host: Node, volume_db: float, pitch_scale: float) -> void:
	_play_stream_layer(host, MISSILE_EXPLOSION_STREAM, volume_db + 0.25, pitch_scale * randf_range(0.97, 1.02))
	_play_stream_layer(host, MISSILE_EXPLOSION_STREAM, volume_db - 6.0, pitch_scale * randf_range(0.76, 0.84), 0.022)
	_play_stream_layer(host, MISSILE_EXPLOSION_STREAM, volume_db - 11.0, pitch_scale * randf_range(1.1, 1.2), 0.008)


static func _play_medium_explosion_layers(host: Node, volume_db: float, pitch_scale: float) -> void:
	_play_stream_layer(host, MEDIUM_EXPLOSION_STREAM, volume_db + 0.5, pitch_scale * randf_range(0.94, 0.99))
	_play_stream_layer(host, MEDIUM_EXPLOSION_STREAM, volume_db - 5.0, pitch_scale * randf_range(0.64, 0.74), 0.03)
	_play_stream_layer(host, MEDIUM_EXPLOSION_STREAM, volume_db - 9.5, pitch_scale * randf_range(1.04, 1.14), 0.012)


static func _play_nuke_explosion_layers(host: Node, volume_db: float, pitch_scale: float) -> void:
	_play_stream_layer(host, NUKE_EXPLOSION_STREAM, volume_db + 1.2, pitch_scale * randf_range(0.92, 0.97))
	_play_stream_layer(host, NUKE_EXPLOSION_STREAM, volume_db - 3.8, pitch_scale * randf_range(0.58, 0.66), 0.036)
	_play_stream_layer(host, NUKE_EXPLOSION_STREAM, volume_db - 8.4, pitch_scale * randf_range(1.02, 1.1), 0.014)


static func _play_stream_layer(
	host: Node,
	stream: AudioStream,
	volume_db: float,
	pitch_scale: float,
	delay: float = 0.0
) -> void:
	if host == null or not is_instance_valid(host) or stream == null:
		return

	request_web_audio_unlock()
	var player := AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.bus = _resolve_bus_name()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = maxf(pitch_scale, 0.01)
	player.finished.connect(player.queue_free)
	host.add_child(player)
	if delay <= 0.0:
		player.play()
		return

	var tree := host.get_tree()
	if tree == null:
		player.play()
		return

	var timer := tree.create_timer(delay)
	timer.timeout.connect(
		func() -> void:
			if player != null and is_instance_valid(player):
				player.play()
	)
