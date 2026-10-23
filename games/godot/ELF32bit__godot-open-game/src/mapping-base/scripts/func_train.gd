extends Node3D

signal generic(parameters: Dictionary)
signal generic_free() # for killtargets

@export_node_path("AnimationPlayer") var _animation_player: NodePath
@onready var animation_player: AnimationPlayer = get_node(_animation_player)


func _on_animation_finished(animation_name: StringName) -> void:
	match animation_name:
		"move":
			generic_free.emit()
			generic.emit({})

@warning_ignore("unused_parameter")
func _on_generic_signal(parameters: Dictionary) -> void:
	animation_player.play("move")
