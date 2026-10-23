extends Node3D

signal generic(parameters: Dictionary)
signal generic_free() # for killtargets

@export_node_path("Area3D") var _area: NodePath
@onready var area: Area3D = get_node(_area)

@export_node_path("AnimationPlayer") var _animation_player: NodePath
@onready var animation_player: AnimationPlayer = get_node(_animation_player)

@export_node_path("Timer") var _wait_timer: NodePath
@onready var wait_timer: Timer = get_node_or_null(_wait_timer)


func _ready() -> void:
	set_physics_process(false)

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	if (area.monitoring and
	area.get_overlapping_bodies().size() > 0):
		wait_timer.start()
	elif wait_timer.is_stopped():
		wait_timer.start()
	if not area.monitoring:
		set_physics_process(false)

@warning_ignore("unused_parameter")
func _on_body_entered(body: Node3D) -> void:
	match animation_player.assigned_animation:
		"retract":
			var progress := (1.0 -
				animation_player.current_animation_position /
				animation_player.current_animation_length)
			animation_player.play("extend")
			animation_player.seek(progress *
				animation_player.current_animation_length, true)
		"retracted":
			animation_player.play("extend")

@warning_ignore("unused_parameter")
func _on_animation_finished(animation_name: StringName) -> void:
	match animation_name:
		"extend":
			if is_instance_valid(wait_timer):
				set_physics_process(true)
			else: area.monitoring = false
			animation_player.play("extended")
		"retract": animation_player.play("retracted")
		"extended":
			generic_free.emit()
			generic.emit({})


func _on_wait_timer_timeout() -> void:
	set_physics_process(false)
	animation_player.play("retract")

@warning_ignore("unused_parameter")
func _on_generic_signal(parameters: Dictionary) -> void:
	if area.monitoring: return
	match animation_player.assigned_animation:
		"extended":
			animation_player.play("retract")
			area.monitoring = true
