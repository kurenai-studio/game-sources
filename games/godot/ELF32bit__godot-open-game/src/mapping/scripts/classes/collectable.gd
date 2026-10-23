extends Node3D

signal generic(parameters: Dictionary)
signal generic_free() # for killtargets

@export_node_path("Area3D") var _area: NodePath
@onready var area: Area3D = get_node_or_null(_area)

@export_node_path("AnimatableBody3D") var _animatable_body: NodePath
@onready var animatable_body: AnimatableBody3D = get_node(_animatable_body)

@export_node_path("AnimationPlayer") var _animation_player: NodePath
@onready var animation_player: AnimationPlayer = get_node(_animation_player)

@export_node_path("Timer") var _wait_timer: NodePath
@onready var wait_timer: Timer = get_node_or_null(_wait_timer)


func _ready() -> void:
	set_physics_process(false)

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	if not area.monitoring: set_physics_process(false)
	elif area.get_overlapping_bodies().size() == 0:
		area.set_deferred("monitoring", false)
		animation_player.play("enable")
		set_physics_process(false)


func _on_animation_finished(animation_name: StringName) -> void:
	match animation_name:
		"enable":
			animation_player.play("enabled")
		"disable":
			animation_player.play("disabled")
			if is_instance_valid(wait_timer):
				wait_timer.start()
			generic_free.emit()
			generic.emit({})


func _on_wait_timer_timeout() -> void:
	if not is_instance_valid(area): return
	area.set_deferred("monitoring", true)
	set_physics_process(true)

# OBJECT: interact_with_collectable(node: Node3D)
func _on_player_interacted(player: Node) -> void:
	if not is_instance_valid(player): return
	if not player.has_method("interact_with_collectable"): return
	match animation_player.assigned_animation:
		"enabled": player.interact_with_collectable(self)

# TODO: more complex transaction with parameters instead of success
func _on_player_finished_interacting(player: Node, success: bool) -> void:
	if not success: return
	if not is_instance_valid(player): return
	match animation_player.assigned_animation:
		"enabled": animation_player.play("disable")

@warning_ignore("unused_parameter")
func _on_generic_signal(parameters: Dictionary) -> void:
	match animation_player.assigned_animation:
		"disabled": animation_player.play("enable")
