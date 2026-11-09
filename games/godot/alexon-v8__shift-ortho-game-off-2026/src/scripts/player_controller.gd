extends CharacterBody3D
class_name PlayerController

signal shift_toggled(is_ortho: bool)
signal cube_grabbed(cube: ShiftCube)
signal cube_released()
signal chamber_reset_requested()

@export var move_speed: float = 6.0
@export var jump_velocity: float = 5.0
@export var mouse_sensitivity: float = 0.0025
@export var gravity: float = 14.0
@export var hold_distance: float = 2.5

@onready var camera_mount: Node3D = $CameraMount
@onready var camera: OrthoCamera = $CameraMount/OrthoCamera
@onready var interact_raycast: RayCast3D = $CameraMount/OrthoCamera/InteractRayCast

var held_cube: ShiftCube = null
var spawn_point: Vector3 = Vector3.ZERO
var footstep_timer: float = 0.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spawn_point = global_position if is_inside_tree() else position
	if camera:
		camera.mode_changed.connect(_on_camera_mode_changed)

func _input(event: InputEvent):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Rotate body horizontally
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Rotate camera mount vertically
		camera_mount.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_mount.rotation.x = clamp(camera_mount.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))

	if event.is_action_pressed("shift_mode"):
		camera.toggle_projection()
		
	if event.is_action_pressed("snap_angle"):
		camera.snap_to_cardinal(self)

	if event.is_action_pressed("interact"):
		_handle_interaction()

	if event.is_action_pressed("reset_chamber"):
		chamber_reset_requested.emit()

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Movement
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	input_dir = input_dir.normalized()

	var move_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if move_direction != Vector3.ZERO:
		velocity.x = move_direction.x * move_speed
		velocity.z = move_direction.z * move_speed
		if is_on_floor():
			footstep_timer += delta
			if footstep_timer > 0.4:
				footstep_timer = 0.0
				if SoundManager.instance:
					SoundManager.instance.play("footstep", randf_range(0.9, 1.1), -8.0)
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()

	# Void fall check
	if global_position.y < -15.0:
		respawn()

	# Update held cube physics and forced perspective scaling
	_process_held_cube()

	# Notify ortho bridges in scene of camera rotation and ortho status
	_update_ortho_bridges()

func _handle_interaction():
	if held_cube:
		# Release held cube
		interact_raycast.remove_exception(held_cube)
		held_cube.release(velocity * 0.5)
		held_cube = null
		cube_released.emit()
	else:
		# Try grab cube
		if interact_raycast.is_colliding():
			var collider = interact_raycast.get_collider()
			if collider is ShiftCube:
				held_cube = collider
				interact_raycast.add_exception(held_cube)
				held_cube.grab(self, camera)
				cube_grabbed.emit(held_cube)

func _process_held_cube():
	if not held_cube:
		return
		
	var cam_pos = camera.global_position
	var cam_forward = -camera.global_transform.basis.z
	var ray_dist = hold_distance
	
	if interact_raycast.is_colliding():
		var hit_point = interact_raycast.get_collision_point()
		var dist_to_hit = (hit_point - cam_pos).length()
		# If aiming at a wall/surface, place right in front of it
		ray_dist = max(0.8, dist_to_hit - (held_cube.current_scale * 0.6))
	
	var target_pos = cam_pos + cam_forward * ray_dist
	held_cube.update_held_position(target_pos, camera.is_ortho, ray_dist)

func _update_ortho_bridges():
	var bridges = get_tree().get_nodes_in_group("ortho_bridges")
	var yaw_deg = rad_to_deg(rotation.y)
	for bridge in bridges:
		if bridge.has_method("update_state"):
			bridge.update_state(camera.is_ortho, yaw_deg)

func _on_camera_mode_changed(is_ortho: bool):
	shift_toggled.emit(is_ortho)

func respawn():
	global_position = spawn_point
	velocity = Vector3.ZERO
	if held_cube:
		interact_raycast.remove_exception(held_cube)
		held_cube.release()
		held_cube = null
		cube_released.emit()
