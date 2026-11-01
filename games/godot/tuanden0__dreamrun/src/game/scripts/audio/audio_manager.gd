## All the sound of a level: ambient layers that follow the AudioZone the player is in, footsteps driven by how far
## the player walked (not by the animation), a thud on landing, and the monsters' rumble that swells as one gets
## close. No dialogue, no music. It only listens to the player's signals and reads the monsters' `active` flag, so it
## knows nothing about the art. Files are in assets/audio (see tools/gen_audio.sh).
class_name AudioManager
extends Node

signal zone_changed(zone_name: StringName)
## A step was played: kind is &"walk", &"run" or &"push" (also pulling).
signal footstep(kind: StringName)
signal landing_heard(volume_db: float)

const DIR := "res://assets/audio/"
const LAYER_FILES := {&"wind": "wind.ogg", &"drone": "drone.ogg", &"drips": "drips.ogg"}
const SILENT_DB := -80.0

@export var layer_fade := 2.5
## Distance walked per step at walking pace, at running pace, and while pushing or pulling a crate (px).
@export var stride_walk := 56.0
@export var stride_run := 96.0
@export var stride_grab := 40.0
@export var step_db_walk := -16.0
@export var step_db_run := -9.0
@export var step_db_grab := -22.0
## A monster further than this is not heard (px); the rumble is loudest when it is on top of the player.
@export var monster_hear_distance := 900.0
@export var rumble_db := -4.0

## 0..1: how close the nearest awake monster is.
var proximity := 0.0
var current_zone: StringName = &""

var _layers := {}
var _layer_tweens := {}
var _steps: Array[AudioStream] = []
var _land: AudioStream
var _step_players: Array[AudioStreamPlayer] = []
var _next_step_player := 0
var _last_step := -1
var _rumble: AudioStreamPlayer
var _monsters: Array[Monster] = []
var _player: PlayerController
var _state: StringName = &"idle"
var _walked := 0.0
var _rng := RandomNumberGenerator.new()


## A looping player for `file` under `parent`, silent until its volume is raised. Used here and by the cutscene.
static func add_loop(parent: Node, file: String, volume_db: float = SILENT_DB) -> AudioStreamPlayer:
	var stream := load(DIR + file) as AudioStreamOggVorbis
	stream.loop = true
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	parent.add_child(player)
	player.play()
	return player


func _ready() -> void:
	_rng.randomize()
	for layer: StringName in LAYER_FILES:
		_layers[layer] = add_loop(self, LAYER_FILES[layer])
	_rumble = add_loop(self, "rumble.ogg")
	for i in 4:
		_steps.append(load(DIR + "step_%d.ogg" % (i + 1)))
	_land = load(DIR + "land.ogg")
	for i in 3:  # steps overlap their own tails
		var player := AudioStreamPlayer.new()
		add_child(player)
		_step_players.append(player)
	_attach.call_deferred()  # every other node is ready by then


func _attach() -> void:
	_player = get_tree().get_first_node_in_group(&"player") as PlayerController
	if _player != null:
		_player.moved.connect(_on_moved)
		_player.landed.connect(_on_landed)
		_player.state_changed.connect(func(s: StringName) -> void: _state = s)
	for zone: AudioZone in get_tree().get_nodes_in_group(&"audio_zone"):
		zone.entered.connect(_on_zone_entered)
	for monster: Monster in get_tree().get_nodes_in_group(&"monster"):
		_monsters.append(monster)


func _physics_process(delta: float) -> void:
	var nearest := INF
	if _player != null:
		for monster in _monsters:
			if monster.active and not monster.is_stunned():
				nearest = minf(nearest, absf(monster.global_position.x - _player.global_position.x))
	var target := clampf(1.0 - nearest / monster_hear_distance, 0.0, 1.0)
	proximity = move_toward(proximity, target, delta * 1.5)  # swells and fades instead of jumping
	_rumble.volume_db = SILENT_DB if proximity < 0.01 else lerpf(-34.0, rumble_db, proximity * proximity)


## The ambient mix of a zone, in dB per layer; layers it does not list fade out.
func mix_of(zone: AudioZone) -> Dictionary:
	var mix := {}
	for layer: StringName in _layers:
		mix[layer] = float(zone.layers.get(layer, zone.layers.get(String(layer), SILENT_DB)))
	return mix


func layer_target_db(layer: StringName) -> float:
	return _layer_tweens[layer].target if _layer_tweens.has(layer) else SILENT_DB


func _on_zone_entered(zone: AudioZone) -> void:
	if zone.name == current_zone:
		return
	current_zone = zone.name
	var mix := mix_of(zone)
	for layer: StringName in _layers:
		var player: AudioStreamPlayer = _layers[layer]
		if _layer_tweens.has(layer):
			_layer_tweens[layer].tween.kill()
		var tween := create_tween()
		tween.tween_property(player, "volume_db", mix[layer], layer_fade).set_trans(Tween.TRANS_SINE)
		_layer_tweens[layer] = {"tween": tween, "target": mix[layer]}
	zone_changed.emit(zone.name)


func _on_moved(velocity: Vector2, run_ratio: float, _facing: int, on_floor: bool) -> void:
	if not on_floor or absf(velocity.x) < 8.0 or not (_state == &"walk" or _state == &"run" or _state == &"push" or _state == &"pull"):
		return
	var grabbing := _state == &"push" or _state == &"pull"
	var stride := stride_grab if grabbing else lerpf(stride_walk, stride_run, clampf(run_ratio, 0.0, 1.0))
	_walked += absf(velocity.x) * get_physics_process_delta_time()
	if _walked < stride:
		return
	_walked -= stride
	var kind := &"push" if grabbing else (&"run" if run_ratio > 0.6 else &"walk")
	var db := step_db_grab if grabbing else lerpf(step_db_walk, step_db_run, clampf(run_ratio, 0.0, 1.0))
	_play_step(db)
	footstep.emit(kind)


func _play_step(db: float) -> void:
	var pick := _rng.randi() % _steps.size()
	if pick == _last_step:
		pick = (pick + 1) % _steps.size()
	_last_step = pick
	var player := _step_players[_next_step_player]
	_next_step_player = (_next_step_player + 1) % _step_players.size()
	player.stream = _steps[pick]
	player.volume_db = db
	player.pitch_scale = _rng.randf_range(0.92, 1.08)
	player.play()


func _on_landed(impact_speed: float) -> void:
	if impact_speed < 150.0:
		return
	var db := lerpf(-22.0, -4.0, clampf(impact_speed / 900.0, 0.0, 1.0))
	var player := _step_players[_next_step_player]
	_next_step_player = (_next_step_player + 1) % _step_players.size()
	player.stream = _land
	player.volume_db = db
	player.pitch_scale = _rng.randf_range(0.94, 1.04)
	player.play()
	landing_heard.emit(db)
