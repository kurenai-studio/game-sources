## Base for one-shot traps. Wire a plate or lever signal to `trigger` in the scene; when it fires, the trap
## stuns every monster standing in its zone (`size` around the origin, the ground line, centred). It stays
## spent until the checkpoint restores it. Subclasses draw the effect and decide when `_stun_zone` runs.
class_name Trap
extends Node2D

signal sprung

@export var size := Vector2(260.0, 300.0)
@export var stun_time := 3.0
## Seconds after it springs until it can be triggered again; 0 = only a checkpoint resets it.
@export var rearm_after := 0.0

var armed := true

var _saved_armed := true
var _generation := 0  # a checkpoint reset cancels a rearm timer that is still running


func _ready() -> void:
	add_to_group(&"resettable")


## `on` lets a plate or lever signal connect directly: releasing the plate or switching the lever off does nothing.
func trigger(on := true) -> void:
	if not on or not armed:
		return
	armed = false
	sprung.emit()
	_fire()
	if rearm_after > 0.0:
		var generation := _generation
		get_tree().create_timer(rearm_after).timeout.connect(func() -> void:
			if generation == _generation:
				armed = true
				_rearm())


func save_checkpoint() -> void:
	_saved_armed = armed


func reset_to_checkpoint() -> void:
	_generation += 1
	armed = _saved_armed
	_restore()


func _fire() -> void:
	pass


func _restore() -> void:
	pass


func _rearm() -> void:
	_restore()


func _stun_zone() -> void:
	# the monster's origin sits exactly on the ground line, and Rect2.has_point excludes the bottom edge
	var zone := Rect2(-size.x * 0.5, -size.y, size.x, size.y + 40.0)
	for monster: Monster in get_tree().get_nodes_in_group(&"monster"):
		if monster.active and zone.has_point(to_local(monster.global_position)):
			monster.stun(stun_time)
