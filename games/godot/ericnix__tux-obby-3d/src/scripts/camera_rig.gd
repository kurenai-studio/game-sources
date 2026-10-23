extends Node3D
class_name CameraRig
## Camera em terceira pessoa, orbital, com colisão contra o cenário.

@export var sensitivity := 0.0022
@export var distance := 6.0
@export var min_distance := 2.2
@export var max_distance := 9.0
@export var min_pitch := -1.15
@export var max_pitch := 0.5

var yaw := 0.0
var pitch := -0.22
var enabled := true

var _camera: Camera3D
var _current_distance := 6.0


func _ready() -> void:
	_camera = Camera3D.new()
	_camera.fov = 74.0
	_camera.near = 0.05
	_camera.far = 420.0
	_camera.current = true
	add_child(_camera)

	# Luz suave presa à câmera: mantém o Tux legível mesmo em contraluz.
	var fill := OmniLight3D.new()
	fill.light_color = Color("ffe6c4")
	fill.light_energy = 11.0
	fill.omni_range = 12.0
	fill.omni_attenuation = 1.7
	fill.light_cull_mask = 2
	fill.shadow_enabled = false
	_camera.add_child(fill)

	_current_distance = distance
	snap()


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * sensitivity
		pitch = clampf(pitch - event.relative.y * sensitivity, min_pitch, max_pitch)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clampf(distance - 0.4, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clampf(distance + 0.4, min_distance, max_distance)


func _process(delta: float) -> void:
	if _camera == null:
		return
	var look_target := global_position + Vector3(0.0, 0.35, 0.0)
	var orbit := Basis.from_euler(Vector3(pitch, yaw, 0.0))
	var back := orbit * Vector3(0.0, 0.0, 1.0)
	var wanted := distance

	# Evita que a câmera atravesse paredes e plataformas.
	var query := PhysicsRayQueryParameters3D.create(
		look_target,
		look_target + back * (distance + 0.3),
		1
	)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		wanted = clampf(look_target.distance_to(hit.position) - 0.3, 0.8, distance)

	_current_distance = lerpf(_current_distance, wanted, minf(1.0, delta * 14.0))
	_camera.global_position = look_target + back * _current_distance
	_camera.look_at(look_target, Vector3.UP)


func snap() -> void:
	_current_distance = distance
	if _camera != null:
		_process(1.0)


func reset_view(new_yaw: float = 0.0) -> void:
	yaw = new_yaw
	pitch = -0.22
	snap()


func set_enabled(value: bool) -> void:
	enabled = value


func activate() -> void:
	if _camera != null:
		_camera.current = true
