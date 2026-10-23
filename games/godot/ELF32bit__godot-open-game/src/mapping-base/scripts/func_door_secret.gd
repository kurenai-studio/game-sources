extends Node3D

signal generic(parameters: Dictionary)
signal generic_free() # for killtargets

@export_node_path("AnimationPlayer") var _animation_player: NodePath
@onready var animation_player: AnimationPlayer = get_node(_animation_player)

@export_node_path("Timer") var _wait_timer: NodePath
@onready var wait_timer: Timer = get_node_or_null(_wait_timer)

@export var opens_once: bool = false


func _on_animation_finished(animation_name: StringName) -> void:
	match animation_name:
		"open":
			animation_player.play("opened")
			if is_instance_valid(wait_timer):
				wait_timer.start()
		"close":
			animation_player.play("closed")


func _on_wait_timer_timeout() -> void:
	if opens_once: return
	animation_player.play("close")


func _on_generic_signal(parameters: Dictionary) -> void:
	match animation_player.assigned_animation:
		"closed":
			animation_player.play("open")
			generic_free.emit()
			generic.emit(parameters)
		"close":
			var progress := (1.0 -
				animation_player.current_animation_position /
				animation_player.current_animation_length)
			animation_player.play("open")
			animation_player.seek(progress *
				animation_player.current_animation_length, true)
			generic_free.emit()
			generic.emit(parameters)
