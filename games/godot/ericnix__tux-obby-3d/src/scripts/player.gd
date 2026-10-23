extends CharacterBody3D
class_name TuxPlayer
## Controlador do Tux: plataforma 3D com pulo duplo, coyote time e buffer de pulo.

signal died
signal landed(impact_speed)

@export_group("Movimento")
@export var walk_speed := 7.2
@export var sprint_speed := 10.6
@export var ground_acceleration := 60.0
@export var air_acceleration := 28.0
@export var ground_friction := 58.0
@export var jump_height := 1.95
@export var double_jump_height := 1.35
@export var gravity := 27.0
@export var max_fall_speed := 34.0
@export var coyote_time := 0.13
@export var jump_buffer_time := 0.15

var dead := false
var frozen := true
var invulnerable := 0.0
var jumps_left := 1

var _gravity := 27.0
var _jump_velocity := 10.0
var _double_jump_velocity := 8.5
var _coyote := 0.0
var _jump_buffer := 0.0
var _ignore_jump := 0.0
var _model_yaw := 0.0

@onready var model: TuxModel = $TuxModel
@onready var camera_rig: CameraRig = $CameraRig


func _ready() -> void:
	_gravity = gravity
	_jump_velocity = sqrt(2.0 * _gravity * jump_height)
	_double_jump_velocity = sqrt(2.0 * _gravity * double_jump_height)
	camera_rig.snap()


func _physics_process(delta: float) -> void:
	invulnerable = maxf(0.0, invulnerable - delta)
	_ignore_jump = maxf(0.0, _ignore_jump - delta)

	if frozen or dead:
		if not is_on_floor():
			velocity = Vector3.ZERO
		return

	var was_on_floor := is_on_floor()

	if not was_on_floor:
		velocity.y -= _gravity * delta
		velocity.y = maxf(velocity.y, -max_fall_speed)
		_coyote = maxf(0.0, _coyote - delta)
	else:
		_coyote = coyote_time

	_move_horizontal(delta)
	_handle_jump(delta)

	var fall_speed := velocity.y
	move_and_slide()

	var on_floor := is_on_floor()
	if not was_on_floor and on_floor:
		jumps_left = 1
		_coyote = coyote_time
		if fall_speed < -5.0:
			var impact := clampf(-fall_speed / 30.0, 0.12, 0.65)
			model.squash(impact)
			Sfx.play("land", -9.0, randf_range(0.92, 1.08))
			landed.emit(fall_speed)

	if on_floor and absf(velocity.x) + absf(velocity.z) > 0.2:
		_model_yaw = _face_movement(_model_yaw, delta)

	model.update_animation(velocity, on_floor, delta)


func _move_horizontal(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Basis(Vector3.UP, camera_rig.yaw) * Vector3(input.x, 0.0, input.y)
	if direction.length_squared() > 0.001:
		direction = direction.normalized()

	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var accel := ground_acceleration if is_on_floor() else air_acceleration

	if direction.length_squared() > 0.001:
		horizontal = horizontal.move_toward(direction * speed, accel * delta)
		_model_yaw = _face_movement(_model_yaw, delta)
	else:
		if is_on_floor():
			horizontal = horizontal.move_toward(Vector3.ZERO, ground_friction * delta)
		else:
			horizontal = horizontal.move_toward(Vector3.ZERO, 2.5 * delta)

	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _face_movement(current_yaw: float, delta: float) -> float:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Basis(Vector3.UP, camera_rig.yaw) * Vector3(input.x, 0.0, input.y)
	var target := current_yaw
	if direction.length_squared() > 0.01:
		target = atan2(-direction.x, -direction.z)
	_model_yaw = lerp_angle(current_yaw, target, minf(1.0, delta * 14.0))
	model.rotation.y = _model_yaw
	return _model_yaw


func _handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and _ignore_jump <= 0.0:
		_jump_buffer = jump_buffer_time
	else:
		_jump_buffer = maxf(0.0, _jump_buffer - delta)

	if _jump_buffer > 0.0:
		if _coyote > 0.0:
			velocity.y = _jump_velocity
			_coyote = 0.0
			_jump_buffer = 0.0
			jumps_left = 1
			model.stretch(0.4)
			Sfx.play("jump", -7.0, randf_range(0.96, 1.06))
		elif jumps_left > 0:
			velocity.y = _double_jump_velocity
			jumps_left -= 1
			_jump_buffer = 0.0
			model.stretch(0.5)
			model.double_jump_spin()
			Sfx.play("double_jump", -7.0, randf_range(0.97, 1.05))

	if Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y *= 0.55


func bounce(power: float) -> void:
	if dead:
		return
	velocity.y = power
	jumps_left = 1
	_coyote = 0.0
	_jump_buffer = 0.0
	model.stretch(0.7)
	Sfx.play("bounce", -6.0, randf_range(0.95, 1.05))


func kill() -> void:
	if dead or frozen or invulnerable > 0.0:
		return
	dead = true
	frozen = true
	velocity = Vector3.ZERO
	model.play_death()
	Sfx.play("death", -5.0)
	died.emit()


func respawn(pos: Vector3, face_yaw: float = 0.0) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	dead = false
	frozen = true
	invulnerable = 1.4
	jumps_left = 1
	_coyote = 0.0
	_jump_buffer = 0.0
	_ignore_jump = 0.25
	_model_yaw = face_yaw
	model.rotation.y = face_yaw
	model.reset_visuals()
	camera_rig.reset_view(face_yaw)
	camera_rig.snap()


func set_frozen(value: bool) -> void:
	frozen = value
	if value:
		velocity = Vector3.ZERO


func unfreeze() -> void:
	frozen = false
	_ignore_jump = 0.2


func set_camera_enabled(value: bool) -> void:
	camera_rig.set_enabled(value)


func get_camera_yaw() -> float:
	return camera_rig.yaw
