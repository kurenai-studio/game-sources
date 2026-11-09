extends Camera3D
class_name OrthoCamera

signal mode_changed(is_ortho: bool)
signal angle_snapped(new_yaw_degrees: float)

@export var perspective_fov: float = 75.0
@export var ortho_size: float = 14.0
@export var transition_speed: float = 8.0

var is_ortho: bool = false
var target_ortho: bool = false

func _ready():
	projection = PROJECTION_PERSPECTIVE
	fov = perspective_fov
	near = 0.05
	far = 200.0

func toggle_projection() -> void:
	set_ortho_mode(not is_ortho)

func set_ortho_mode(ortho: bool) -> void:
	if is_ortho == ortho:
		return
	is_ortho = ortho
	if is_ortho:
		projection = PROJECTION_ORTHOGONAL
		size = ortho_size
		if SoundManager.instance:
			SoundManager.instance.play("shift_ortho", 1.0, 0.0)
	else:
		projection = PROJECTION_PERSPECTIVE
		fov = perspective_fov
		if SoundManager.instance:
			SoundManager.instance.play("shift_persp", 1.0, 0.0)
	mode_changed.emit(is_ortho)

func snap_to_cardinal(target_body: Node3D = null) -> void:
	var body: Node3D = target_body
	if not body:
		if owner and owner is Node3D:
			body = owner
		elif get_parent() and get_parent().get_parent() is Node3D:
			body = get_parent().get_parent()
		elif get_parent() is Node3D:
			body = get_parent()

	if body:
		var current_yaw = body.rotation.y
		var step = PI / 4.0 # 45 degrees
		var snapped_yaw = round(current_yaw / step) * step
		body.rotation.y = snapped_yaw
		angle_snapped.emit(rad_to_deg(snapped_yaw))
		if SoundManager.instance:
			SoundManager.instance.play("grab", 1.4, -4.0)
