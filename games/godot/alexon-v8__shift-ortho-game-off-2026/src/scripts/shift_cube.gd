extends RigidBody3D
class_name ShiftCube

signal scale_changed(new_scale: float, new_weight: float)

@export var base_scale: float = 1.0
@export var base_mass: float = 10.0
@export var min_scale: float = 0.3
@export var max_scale: float = 4.5
@export var initial_hold_distance: float = 2.5

var current_scale: float = 1.0
var is_held: bool = false
var holder_node: Node3D = null
var camera_ref: Camera3D = null

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready():
	apply_scale_factor(base_scale)
	contact_monitor = true
	max_contacts_reported = 4

func apply_scale_factor(new_scale: float) -> void:
	current_scale = clamp(new_scale, min_scale, max_scale)
	if mesh_instance:
		mesh_instance.scale = Vector3.ONE * current_scale
	if collision_shape:
		collision_shape.scale = Vector3.ONE * current_scale
	mass = base_mass * pow(current_scale, 3.0)
	scale_changed.emit(current_scale, mass)

func grab(holder: Node3D, cam: Camera3D) -> void:
	is_held = true
	holder_node = holder
	camera_ref = cam
	freeze = true
	if SoundManager.instance:
		SoundManager.instance.play("grab", 1.0, 0.0)

func release(drop_impulse: Vector3 = Vector3.ZERO) -> void:
	if not is_held:
		return
	is_held = false
	freeze = false
	linear_velocity = drop_impulse
	holder_node = null
	camera_ref = null
	if SoundManager.instance:
		SoundManager.instance.play("drop", 1.0, 0.0)

func update_held_position(target_global_pos: Vector3, in_ortho: bool, raycast_distance: float) -> void:
	if not is_held:
		return
		
	if in_ortho and raycast_distance > 0.5:
		# In Orthographic mode, screen size is constant.
		# When projected to a surface at raycast_distance, scale changes proportionally
		var target_scale = clamp(base_scale * (raycast_distance / initial_hold_distance), min_scale, max_scale)
		apply_scale_factor(lerp(current_scale, target_scale, 0.2))
		global_position = global_position.lerp(target_global_pos, 0.25)
	else:
		global_position = global_position.lerp(target_global_pos, 0.3)
