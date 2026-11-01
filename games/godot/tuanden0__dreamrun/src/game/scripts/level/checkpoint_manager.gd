## Respawn flow. When the player dies it plays the death, fades to black, resets every node in group
## "resettable" to its state at the last checkpoint (they implement save_checkpoint /
## reset_to_checkpoint) and puts the player back at that checkpoint, all within respawn_delay (< 1 s).
class_name CheckpointManager
extends Node

signal respawned

@export var player_path: NodePath
## Seconds from death to being back in control.
@export var respawn_delay := 0.55
@export var fade_in := 0.3
@export var fade_out := 0.25

var _player: PlayerController
var _spawn := Vector2.ZERO
var _veil: ColorRect


func _ready() -> void:
	_player = get_node(player_path) as PlayerController
	_spawn = _player.global_position
	var layer := CanvasLayer.new()
	layer.layer = 20
	_veil = ColorRect.new()
	_veil.color = Color(0.0, 0.0, 0.0, 0.0)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_veil)
	add_child(layer)
	_player.died.connect(_on_died)
	_collect.call_deferred()  # wait until every other node is ready


func _collect() -> void:
	for checkpoint in get_tree().get_nodes_in_group(&"checkpoint"):
		checkpoint.activated.connect(_on_checkpoint)
	get_tree().call_group(&"resettable", &"save_checkpoint")


func _on_checkpoint(checkpoint: Checkpoint) -> void:
	_spawn = checkpoint.spawn_position()
	get_tree().call_group(&"resettable", &"save_checkpoint")


func _on_died() -> void:
	var tween := create_tween()
	tween.tween_interval(maxf(respawn_delay - fade_in, 0.0))
	tween.tween_property(_veil, "color:a", 1.0, fade_in)
	tween.tween_callback(_respawn)
	tween.tween_property(_veil, "color:a", 0.0, fade_out)


func _respawn() -> void:
	get_tree().call_group(&"resettable", &"reset_to_checkpoint")
	_player.respawn(_spawn)
	respawned.emit()
