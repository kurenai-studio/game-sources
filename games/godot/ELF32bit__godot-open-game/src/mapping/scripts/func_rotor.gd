extends Node3D

@export_node_path("AnimationPlayer") var _animation_player: NodePath
@onready var animation_player: AnimationPlayer = get_node(_animation_player)

var move_progress: float = 0.0

@warning_ignore("unused_parameter")
func _on_generic_signal(parameters: Dictionary) -> void:
	match animation_player.assigned_animation:
		"move":
			move_progress = (
				animation_player.current_animation_position /
				animation_player.current_animation_length)
			animation_player.play("stop")
		"stop", "":
			animation_player.play("move")
			animation_player.seek(move_progress *
				animation_player.current_animation_length, true)
