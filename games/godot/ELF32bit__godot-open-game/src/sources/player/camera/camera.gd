extends Camera3D

enum SelectMode { FIRST_PERSON, THIRD_PERSON }
@export var select_mode := SelectMode.THIRD_PERSON

@export var select_enabled := true
@export var select_distance: float = -1.0

var selected_object: CollisionObject3D = null

@export_flags_3d_physics var select_mask: int = 0
@export_flags_3d_physics var collision_mask: int = 0:
	set(value):
		if is_instance_valid(raycast):
			raycast.collision_mask = value
		collision_mask = value

@onready var viewport: Viewport = get_viewport()
@onready var raycast: RayCast3D = $"RayCast3D"


func _ready() -> void:
	self.collision_mask = collision_mask

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	if not select_enabled:
		selected_object = null
		return

	if viewport.get_camera_3d() != self:
		selected_object = null
		return

	if select_mode == SelectMode.THIRD_PERSON:
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
			selected_object = null
			return

	match select_mode:
		SelectMode.FIRST_PERSON:
			selected_object = select_object(select_distance)
		SelectMode.THIRD_PERSON:
			selected_object = select_object_with_mouse(select_distance)


func select_object(at_distance: float = -1.0) -> CollisionObject3D:
	if at_distance < 0.0:
		if select_distance < 0.0: at_distance = far
		else: at_distance = select_distance

	var direction := -global_basis.z.normalized()
	var target_position := global_position + direction * at_distance
	raycast.target_position = raycast.to_local(target_position)
	raycast.force_raycast_update()

	raycast.target_position = Vector3.ZERO
	if raycast.is_colliding():
		var object := raycast.get_collider()
		if not object is CollisionObject3D: return object
		elif object.collision_layer & select_mask: return object
	return null


func select_object_with_mouse(at_distance: float = -1.0) -> CollisionObject3D:
	var mouse_position := viewport.get_mouse_position()
	if at_distance < 0.0:
		if select_distance < 0.0: at_distance = far
		else: at_distance = select_distance

	var direction := project_ray_normal(mouse_position)
	var target_position := global_position + direction * at_distance
	raycast.target_position = raycast.to_local(target_position)
	raycast.force_raycast_update()

	raycast.target_position = Vector3.ZERO
	if raycast.is_colliding():
		var object := raycast.get_collider()
		if not object is CollisionObject3D: return object
		elif object.collision_layer & select_mask: return object
	return null
