extends Area3D

@export var push_speed: float = 31.25
@export var push_once := false


func _ready() -> void:
	set_physics_process(false)

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	if not monitoring:
		set_physics_process(false)
		return

	var overlapping_bodies := get_overlapping_bodies()
	if not overlapping_bodies.size():
		set_physics_process(false)
		if push_once: set_deferred("monitoring", false)
		return

	var forward := -global_basis.z.normalized()
	var push_velocity := Vector3(forward * push_speed)

	# OBJECT: push(velocity: Vector3)
	for overlapping_body in overlapping_bodies:
		if overlapping_body.has_method("push"):
			overlapping_body.push(push_velocity)
		elif overlapping_body is RigidBody3D:
			overlapping_body.set_axis_velocity(push_velocity)

@warning_ignore("unused_parameter")
func _on_body_entered(body: Node3D) -> void:
	set_physics_process(true)
