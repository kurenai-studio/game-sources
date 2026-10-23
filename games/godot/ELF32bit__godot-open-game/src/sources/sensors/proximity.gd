extends Node3D

const OBJECT_LIMITER: int = 64

@export var enabled := true
@export var max_distance: float = 10.0
@export var directional := false

var nearest_object: CollisionObject3D = null

@export_flags_3d_physics var collision_mask: int = 0:
	set(value):
		if is_instance_valid(area):
			area.collision_mask = value
		collision_mask = value

@onready var area: Area3D = $"Area3D"
@onready var collision_shape: CollisionShape3D = $"Area3D/CollisionShape3D"


func _ready() -> void:
	self.collision_mask = collision_mask

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	collision_shape.shape.radius = max_distance
	area.monitoring = enabled

	if not enabled:
		nearest_object = null
		return

	nearest_object = select_nearest_object(directional)

@warning_ignore("shadowed_variable")
func select_nearest_object(directional: bool = false) -> CollisionObject3D:
	var direction := +global_basis.z.normalized()
	var selected_object: CollisionObject3D = null
	var min_distance: float = INF

	var counter: int = 0
	for object in area.get_overlapping_bodies():
		if counter >= OBJECT_LIMITER: break
		counter += 1

		if not object is CollisionObject3D: continue
		var object_direction := object.global_position - global_position
		var object_distance := object_direction.length_squared()
		object_direction = object_direction.normalized()

		if directional:
			object_distance *= (3.0 +
				object_direction.dot(direction))

		if object_distance < min_distance:
			min_distance = object_distance
			selected_object = object

	return selected_object
