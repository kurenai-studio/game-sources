extends Node3D

signal opening(parameters: Dictionary)
signal opening_free() # for killtargets

signal closing(parameters: Dictionary)

@export_node_path("Area3D") var _area: NodePath
@onready var area: Area3D = get_node(_area)

@export_node_path("AnimationPlayer") var _animation_player: NodePath
@onready var animation_player: AnimationPlayer = get_node(_animation_player)

@export_node_path("Timer") var _wait_timer: NodePath
@onready var wait_timer: Timer = get_node_or_null(_wait_timer)

@export var is_toggled := false


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


func _on_body_entered(body: Node3D) -> void:
	if is_instance_valid(body):
		pass
	match animation_player.assigned_animation:
		"opened":
			if is_toggled:
				animation_player.play("close")
				closing.emit({})
		"closed":
			animation_player.play("open")
			opening_free.emit()
			opening.emit({})
		"close":
			var progress := (1.0 -
				animation_player.current_animation_position /
				animation_player.current_animation_length)
			animation_player.play("open")
			animation_player.seek(progress *
				animation_player.current_animation_length, true)
			opening_free.emit()
			opening.emit({})


func _on_animation_finished(animation_name: StringName) -> void:
	match animation_name:
		"open":
			if is_instance_valid(wait_timer):
				set_physics_process(true)
			elif not is_toggled:
				area.monitoring = false
			animation_player.play("opened")
		"close": animation_player.play("closed")


func _on_wait_timer_timeout() -> void:
	set_physics_process(false)
	animation_player.play("close")
	closing.emit({})

@warning_ignore("unused_parameter")
func _on_generic_signal(parameters: Dictionary) -> void:
	_on_body_entered(null)
