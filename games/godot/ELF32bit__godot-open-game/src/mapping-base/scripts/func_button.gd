extends Node3D
const DT := preload("trigger_relay.gd")

signal generic(parameters: Dictionary)
signal generic_free() # for killtargets

@export_node_path("AnimationPlayer") var _animation_player: NodePath
@onready var animation_player: AnimationPlayer = get_node(_animation_player)

@export_node_path("Timer") var _wait_timer: NodePath
@onready var wait_timer: Timer = get_node_or_null(_wait_timer)

@export var delay_time: float = 0.0


func _on_animation_finished(animation_name: StringName) -> void:
	match animation_name:
		"press":
			if is_instance_valid(wait_timer):
				wait_timer.start()
			DT._start_delay_timer_from(self, delay_time)
			animation_player.play("pressed")
		"release":
			animation_player.play("released")


func _on_delay_timer_timeout() -> void:
	generic_free.emit()
	generic.emit({})


func _on_wait_timer_timeout() -> void:
	animation_player.play("release")

@warning_ignore("unused_parameter")
func _on_player_interacted(player: Node) -> void:
	match animation_player.assigned_animation:
		"release":
			var progress := (1.0 -
				animation_player.current_animation_position /
				animation_player.current_animation_length)
			animation_player.play("press")
			animation_player.seek(progress *
				animation_player.current_animation_length, true)
		"released": animation_player.play("press")
