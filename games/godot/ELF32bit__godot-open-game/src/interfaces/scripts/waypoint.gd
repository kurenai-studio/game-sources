extends Node3D

const SCREEN_MARGIN: int = 8

@export var text: String = "Waypoint"
@export var sticky: bool = true

@export_group("Visibility", "visibility_")
@export var visibility_range_begin: float = 0.0:
	set(value): visibility_range_begin = clampf(value, 0.0, INF)

@export var visibility_range_begin_margin: float = 0.0:
	set(value): visibility_range_begin_margin = clampf(value, 0.0, INF)

@export var visibility_range_end: float = 0.0:
	set(value): visibility_range_end = clampf(value, 0.0, INF)

@export var visibility_range_end_margin: float = 0.0:
	set(value): visibility_range_end_margin = clampf(value, 0.0, INF)

func _visibility_range_fade(distance: float) -> float:
	if visibility_range_end != 0.0:
		if distance >= visibility_range_end: return 0.0
	if distance < visibility_range_begin: return 0.0
	var opacity: float = 1.0

	if visibility_range_begin_margin != 0.0:
		if distance < visibility_range_begin + visibility_range_begin_margin:
			opacity = ((distance - visibility_range_begin)
				/ visibility_range_begin_margin)

	if visibility_range_end != 0.0 and visibility_range_end_margin != 0.0:
		if distance > visibility_range_end - visibility_range_end_margin:
			opacity = minf(opacity, (visibility_range_end - distance)
				/ visibility_range_end_margin)

	return clampf(opacity, 0.0, 1.0)

@onready var control: Control = $"Control"
@onready var label: Label = $"Control/Label"

@onready var viewport: Viewport = get_viewport()


func _ready() -> void:
	if not visibility_changed.is_connected(_on_visibility_changed):
		visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	control.visible = true
	control.rotation = 0.0
	label.visible = true
	label.text = text

	var camera := viewport.get_camera_3d()
	if not is_instance_valid(camera):
		return

	var distance := camera.global_position.distance_to(global_position)
	control.modulate.a = _visibility_range_fade(distance)
	if control.modulate.a == 0.0:
		control.visible = false
		return

	var viewport_size := Vector2i(0, 0)
	if viewport is SubViewport:
		if viewport.size_2d_override > Vector2i(0, 0):
			viewport_size = viewport.size_2d_override
		else: viewport_size = viewport.size
	elif viewport is Window:
		if viewport.content_scale_size > Vector2i(0, 0):
			viewport_size = viewport.content_scale_size
		else: viewport_size = viewport.size

	var unprojected_position := camera.unproject_position(global_position)
	var is_behind := bool(camera.global_basis.z.dot(
		global_position - camera.global_position) > 0.0)

	if not sticky:
		control.position = unprojected_position
		control.visible = not is_behind
		return

	if is_behind:
		if unprojected_position.x < int(viewport_size.x / 2.0):
			unprojected_position.x = viewport_size.x - SCREEN_MARGIN
		else: unprojected_position.x = SCREEN_MARGIN

	if (is_behind or
	unprojected_position.x < SCREEN_MARGIN or
	unprojected_position.x > viewport_size.x - SCREEN_MARGIN):
		var x := camera.global_transform.looking_at(global_position, Vector3.UP)
		var difference := angle_difference(x.basis.get_euler().x,
			camera.global_basis.get_euler().x)

		unprojected_position.y = (viewport_size.y *
			(0.5 + (difference / deg_to_rad(camera.fov))))

	control.position = Vector2(
		clampf(unprojected_position.x,
			SCREEN_MARGIN, viewport_size.x - SCREEN_MARGIN),
		clampf(unprojected_position.y,
			SCREEN_MARGIN, viewport_size.y - SCREEN_MARGIN))

	var overflow: int = 0
	if control.position.x <= SCREEN_MARGIN:
		overflow = int(-TAU / 8.0)
		control.rotation = TAU / 4.0
		label.visible = false
	elif control.position.x >= viewport_size.x - SCREEN_MARGIN:
		overflow = int(TAU / 8.0)
		control.rotation = TAU * 3.0 / 4.0
		label.visible = false

	if control.position.y <= SCREEN_MARGIN:
		control.rotation = TAU / 2.0 + overflow
		label.visible = false
	elif control.position.y >= viewport_size.y - SCREEN_MARGIN:
		control.rotation = -overflow
		label.visible = false


func _on_visibility_changed() -> void:
	control.visible = visible
	set_process(visible)
