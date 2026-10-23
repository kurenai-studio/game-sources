extends CharacterBody3D

const UP_PLANE := Plane(Vector3.UP)
const VELOCITY_EPSILON: float = 0.01
func _clear_velocity_jitter() -> void:
	velocity.x *= float(absf(velocity.x) >= VELOCITY_EPSILON)
	velocity.y *= float(absf(velocity.y) >= VELOCITY_EPSILON)
	velocity.z *= float(absf(velocity.z) >= VELOCITY_EPSILON)

enum MovementMode { GROUNDED, SWIMMING, FLYING }
@export var movement_mode: MovementMode = MovementMode.GROUNDED:
	set(value):
		match value:
			MovementMode.GROUNDED:
				floor_block_on_wall = true
				floor_snap_length = _floor_snap_length
				_enable_swim_blocking_areas(not swim_enabled)

			MovementMode.SWIMMING:
				floor_block_on_wall = false
				floor_snap_length = 0.0
				_enable_swim_blocking_areas(false)

			MovementMode.FLYING:
				if movement_mode != MovementMode.GROUNDED: return
				if is_swimming_shallow: return
				floor_block_on_wall = false
				floor_snap_length = 0.0
				_enable_swim_blocking_areas(true)
		movement_mode = value

@export var walk_speed: float = 10.0
@export var swim_speed: float = 6.0
@export var fly_speed: float = 16.0

@export var swim_enabled := true:
	set(value):
		if movement_mode == MovementMode.GROUNDED:
			_enable_swim_blocking_areas(not value)
		swim_enabled = value

@export var turn_speed: float = 3.0
@export var acceleration: float = 8.0
@export var deceleration: float = 10.0

@export var walk2_enabled: bool = true
@export var walk2_speed: float = 16.0

@export var swim2_enabled: bool = true
@export var swim2_speed: float = 10.0

@export var fly2_enabled: bool = false
@export var fly2_speed: float = 20.0

@export var jump_enabled: bool = true
@export var jump_height: float = 2.0
@export var jump_control: float = 0.3
@export var jump_count_max: int = 1

@export var gravity: float = 30.0
@export var gravity_submerge: float = 0.35
@export var gravity_swim: float = 0.0
@export var gravity_fly: float = 0.0

@export var orbit_length_step: float = 0.15
@export var orbit_length_min: float = 0.0
@export var orbit_length_max: float = 10.0
@export var orbit_limit_min := deg_to_rad(-89.0)
@export var orbit_limit_max := deg_to_rad(89.0)
@export var orbit_altitude_recovery: float = 6.0
@export var orbit_altitude_min := deg_to_rad(15.0)
@export var orbit_altitude_max := deg_to_rad(30.0)
@export var orbit_altitude_swim := deg_to_rad(45.0)

@export_flags_3d_physics var swim_blocking_layers: int = 0
func _enable_swim_blocking_areas(value: bool) -> void:
	if value: collision_mask |= swim_blocking_layers
	else: collision_mask &= ~swim_blocking_layers

var input: Node = null
var direction := Vector3.ZERO
var velocity_target := Vector3.ZERO
var velocity_before_collision := Vector3.ZERO
var jump_count := jump_count_max
var orbit_altitude: float = 0.0

var swim_area_type: int = -1
var swim_areas: Dictionary = {}
var is_swimming_shallow := false
var is_swimming_deep := false
var is_swimming := false

@onready var rid: RID = get_rid()
@onready var camera: Camera3D = $"Camera3D"
@onready var spring_arm: SpringArm3D = $"SpringArm3D"
@onready var _floor_snap_length := float(floor_snap_length)
@onready var _camera_remote: RemoteTransform3D = (
	$"SpringArm3D/RemoteTransform3D")


func _ready() -> void:
	InputManager.mode = InputManager.Mode.Player
	input = InputManager.get_current()
	_validate_input()

	spring_arm.clear_excluded_objects()
	spring_arm.add_excluded_object(rid)
	set_process(false)


func _validate_input() -> void:
	assert("move_vector" in input)
	assert("get_camera_scroll_number" in input)
	assert("get_free_look" in input)
	assert("is_camera_focus_pressed" in input)
	assert("is_camera_orbit_pressed" in input)
	assert("is_jump_pressed" in input)
	assert("is_jump_just_pressed" in input)


func _process(delta: float) -> void:
	_update_spring_arm_rotation(input.move_vector, delta)


func _physics_process(delta: float) -> void:
	_update_spring_arm_length(input.get_camera_scroll_number())
	_apply_free_look(spring_arm, input.get_free_look(), delta)
	orbit_altitude = float(spring_arm.rotation.x)

	_apply_move_rotation(input.move_vector,
		input.is_camera_focus_pressed, delta)

	set_process(false)
	if input.is_camera_focus_pressed:
		rotation.y = spring_arm.rotation.y
	elif not input.is_camera_orbit_pressed:
		set_process(true)

	var was_swimming := bool(is_swimming)
	_update_swim_areas()
	_reset_on_water_floor(was_swimming)
	_update_movement_mode()

	_update_direction(input.move_vector,
		input.is_camera_focus_pressed)
	_update_velocity_target(false)

	_apply_gravity(delta)
	_reset_on_floor()

	_apply_jump(input.is_jump_pressed,
		input.is_jump_just_pressed)

	_update_velocity(delta)
	velocity_before_collision = velocity
	move_and_slide()

@warning_ignore("shadowed_variable")
func _update_spring_arm_length(scroll_number: int) -> void:
	spring_arm.spring_length -= scroll_number * orbit_length_step
	spring_arm.spring_length = clampf(spring_arm.spring_length,
		orbit_length_min, orbit_length_max)


func _update_spring_arm_rotation(move_vector: Vector2, delta: float) -> void:
	var target := -global_basis.z.rotated(global_basis.x.normalized(),
		-clampf(-orbit_altitude, orbit_altitude_min, orbit_altitude_max))
	var target_quaternion := Basis.looking_at(target, Vector3.UP)

	var weight := clampf(orbit_altitude_recovery * delta, 0.0, 1.0)
	if absf(move_vector.x) > 0.0: weight = sqrt(weight)
	elif move_vector.y == 0: weight = 0.0

	spring_arm.quaternion = spring_arm.quaternion.slerp(
		target_quaternion, weight)
	spring_arm.rotation.z = 0.0


func _apply_free_look(node: Node3D, free_look: Vector2, delta: float) -> void:
	node.rotation.x += free_look.y * delta
	node.rotation.x = clampf(node.rotation.x,
		orbit_limit_min, orbit_limit_max)
	node.rotate_y(free_look.x * delta)


func _apply_move_rotation(move_vector: Vector2, is_focused: bool, delta: float) -> void:
	if is_focused or absf(move_vector.x) == 0.0: return
	rotate_y(turn_speed * signf(-move_vector.x) * delta)

# OBJECT: has_point(point: Vector3)
func _update_swim_areas() -> void:
	swim_area_type = -1
	is_swimming_shallow = false
	is_swimming_deep = false
	is_swimming = false

	for area in swim_areas:
		if not is_instance_valid(area): continue
		if not area.has_method("has_point"): continue
		swim_area_type = swim_areas[area]
		is_swimming_shallow = true

		if area.has_point(global_position):
			swim_area_type = swim_areas[area]
			is_swimming = true
		else: continue

		if area.has_point(spring_arm.global_position):
			is_swimming_deep = true
		break
	if swim_areas.size() > 0:
		if not is_swimming_shallow:
			swim_areas.clear()


func _update_movement_mode() -> void:
	if is_swimming:
		if movement_mode != MovementMode.SWIMMING:
			movement_mode = MovementMode.SWIMMING
	elif movement_mode == MovementMode.SWIMMING:
		if is_swimming_shallow:
			if is_on_floor() or not swim_enabled:
				movement_mode = MovementMode.GROUNDED
		else: movement_mode = MovementMode.GROUNDED


func _update_direction(move_vector: Vector2, is_focused: bool) -> void:
	direction = Vector3.ZERO
	match movement_mode:
		MovementMode.GROUNDED:
			if is_focused:
				direction += spring_arm.global_basis.x * move_vector.x
				direction -= spring_arm.global_basis.z * move_vector.y
				direction = UP_PLANE.project(direction)
			elif absf(move_vector.y) > 0.0:
				direction -= global_basis.z * move_vector.y

		MovementMode.SWIMMING:
			if is_swimming_deep:
				if is_focused:
					direction += spring_arm.global_basis.x * move_vector.x
					direction -= spring_arm.global_basis.z * move_vector.y
				elif absf(move_vector.y) > 0.0:
					direction -= global_basis.z * move_vector.y

			elif not is_swimming_deep:
				if is_focused and -orbit_altitude > orbit_altitude_swim:
					direction += spring_arm.global_basis.x * move_vector.x
					direction -= spring_arm.global_basis.z * move_vector.y
				elif is_focused:
					direction += global_basis.x * move_vector.x
					direction -= global_basis.z * move_vector.y
				elif absf(move_vector.y) > 0.0:
					direction -= global_basis.z * move_vector.y

			if is_on_floor():
				direction = direction.normalized()
				if get_floor_normal().dot(direction) < 0.0:
					direction = global_basis.x * move_vector.x
					direction -= global_basis.z * move_vector.y
			elif is_on_ceiling():
				pass

		MovementMode.FLYING:
			if is_focused:
				direction += spring_arm.global_basis.x * move_vector.x
				direction -= spring_arm.global_basis.z * move_vector.y
			elif absf(move_vector.y) > 0.0:
				direction -= global_basis.z * move_vector.y

	direction = direction.normalized()
	return


func _update_velocity_target(is_alternative: bool) -> void:
	velocity_target = Vector3.ZERO
	var speed: float = 0.0
	match movement_mode:
		MovementMode.GROUNDED:
			speed = walk2_speed if is_alternative else walk_speed
			velocity_target.x = direction.x * speed
			velocity_target.z = direction.z * speed
		MovementMode.SWIMMING:
			speed = swim2_speed if is_alternative else swim_speed
			velocity_target = direction * speed
		MovementMode.FLYING:
			speed = fly2_speed if is_alternative else fly_speed
			velocity_target = direction * speed


func _apply_gravity(delta: float) -> void:
	if is_on_floor(): return
	match movement_mode:
		MovementMode.GROUNDED:
			velocity.y -= gravity * delta
			velocity_target.y = velocity.y
		MovementMode.SWIMMING:
			if is_swimming:
				velocity_target.y -= gravity_swim
			elif not is_swimming:
				velocity.y -= gravity_submerge * delta
				velocity_target.y = velocity.y
		MovementMode.FLYING:
			velocity_target.y -= gravity_fly


func _reset_on_floor() -> void:
	if not is_on_floor(): return
	match movement_mode:
		MovementMode.GROUNDED:
			jump_count = jump_count_max
			velocity_target.y = maxf(velocity_target.y, 0.0)
			velocity.y = maxf(velocity.y, 0.0)
		MovementMode.SWIMMING: pass
		MovementMode.FLYING: pass


func _reset_on_water_floor(was_swimming: bool) -> void:
	if not was_swimming and is_swimming:
		jump_count = jump_count_max
		velocity_target.y = 0.0
		velocity.y = 0.0
	elif was_swimming and not is_swimming:
		velocity_target = Vector3.ZERO
		velocity = Vector3.ZERO


func _apply_jump(is_jumping: bool, now: bool) -> void:
	if not is_jumping: return
	match movement_mode:
		MovementMode.GROUNDED:
			if now: jump(false, jump_height)
		MovementMode.SWIMMING:
			if is_swimming:
				velocity_target.y = swim_speed
			elif not is_swimming:
				if is_on_wall_only():
					jump(false, jump_height)
					jump_count = 0
		MovementMode.FLYING:
			velocity_target.y = fly_speed


func _update_velocity(delta: float) -> void:
	var weight := deceleration
	if direction.dot(velocity) > 0.0:
		weight = acceleration

	match movement_mode:
		MovementMode.GROUNDED:
			if not is_on_floor():
				weight *= jump_control
		MovementMode.SWIMMING: pass
		MovementMode.FLYING: pass

	weight = clampf(weight * delta, 0.0, 1.0)
	velocity = velocity.lerp(velocity_target, weight)
	if direction.dot(velocity) == 0.0:
		match movement_mode:
			MovementMode.SWIMMING:
				if is_swimming:
					_clear_velocity_jitter()
				elif not is_swimming: pass
			_: _clear_velocity_jitter()


func can_sprint() -> bool:
	if input.move_vector.y <= 0.0: return false
	match movement_mode:
		MovementMode.GROUNDED:
			return walk2_enabled and is_on_floor()
		MovementMode.SWIMMING: return swim2_enabled
		MovementMode.FLYING: return fly2_enabled
	return false


func can_jump() -> bool:
	if not jump_enabled: return false
	match movement_mode:
		MovementMode.GROUNDED:
			return is_on_floor() or jump_count > 0
		MovementMode.SWIMMING:
			return is_on_wall_only() and not is_swimming
		MovementMode.FLYING: return false
	return false


func jump(forced: bool = false, height: float = jump_height) -> void:
	if not can_jump() and not forced: return
	velocity.y = sqrt(2.0 * gravity * height)
	velocity_target.y = velocity.y
	if not forced:
		jump_count = clampi(jump_count - 1,
			0, jump_count_max)


func push(push_velocity: Vector3) -> void:
	velocity_target = push_velocity
	velocity = push_velocity
	jump_count = 0

@warning_ignore("unused_parameter")
func teleport(to: Transform3D, push_speed: float = 0.0) -> void:
	spring_arm.rotation.y = rotation.y
	if push_speed != 0.0:
		var push_direction := -global_basis.z.normalized()
		push(push_direction * push_speed)


func is_camera_detached() -> bool:
	return camera.top_level


func detach_camera() -> Camera3D:
	_camera_remote.update_position = false
	_camera_remote.update_rotation = false
	camera.top_level = true
	return camera


func attach_camera() -> Camera3D:
	_camera_remote.update_position = true
	_camera_remote.update_rotation = true
	camera.top_level = false
	return camera
