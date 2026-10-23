class_name GalaxyCameraController
extends RefCounted

var drag_sensitivity: float = 1.0
var click_drag_threshold: float = 8.0
var keyboard_pan_speed: float = 2400.0
var min_zoom: float = 0.25
var max_zoom: float = 2.5
var default_zoom: float = 1.0
var zoom_step: float = 0.01
var trackpad_zoom_step: float = 0.02
var shake_decay: float = 2.7
var shake_max_offset: float = 120.0
var shake_max_rotation: float = 0.055
var shake_max_trauma: float = 2.0
var shake_falloff_distance: float = 3000.0

var _viewport_owner: Node
var _camera: Camera2D
var _starfield: Node2D
var _ship: Node2D
var _world_radius_provider: Callable
var _game_over_provider: Callable
var _move_ship_callback: Callable
var _is_dragging: bool = false
var _has_dragged: bool = false
var _drag_start_screen_position: Vector2 = Vector2.ZERO
var _is_ship_selected: bool = false
var _shake_trauma: float = 0.0
var _camera_base_rotation: float = 0.0
var _shake_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func configure(
		viewport_owner: Node,
		camera: Camera2D,
		starfield: Node2D,
		ship: Node2D,
		world_radius_provider: Callable,
		game_over_provider: Callable,
		move_ship_callback: Callable
) -> void:
	_viewport_owner = viewport_owner
	_camera = camera
	_starfield = starfield
	_ship = ship
	_world_radius_provider = world_radius_provider
	_game_over_provider = game_over_provider
	_move_ship_callback = move_ship_callback


func setup() -> void:
	if _camera == null:
		return

	_camera.make_current()
	_camera_base_rotation = _camera.rotation
	_camera.offset = Vector2.ZERO
	var safe_min_zoom := minf(min_zoom, max_zoom)
	var safe_max_zoom := maxf(min_zoom, max_zoom)
	var initial_zoom := clampf(default_zoom, safe_min_zoom, safe_max_zoom)
	_camera.zoom = Vector2(initial_zoom, initial_zoom)
	_camera.position = clamp_camera_position(_camera.position, _camera.zoom)
	_camera.force_update_scroll()
	_shake_rng.randomize()


func set_ship(ship: Node2D) -> void:
	_ship = ship
	if _ship == null:
		_is_ship_selected = false


func process(delta: float) -> void:
	if _camera == null:
		return

	_update_camera_shake(delta)
	if _is_game_over():
		return

	var keyboard_pan_direction := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	if keyboard_pan_direction != Vector2.ZERO:
		set_ship_selected(false)
		_pan_camera_with_keyboard(keyboard_pan_direction, delta)
	elif _is_ship_selected:
		follow_ship()

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not _is_pointer_over_gui_control():
		_move_ship_to_cursor()


func handle_unhandled_input(event: InputEvent) -> bool:
	if _camera == null:
		return false

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		center_on_ship()
		return true

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_finish_left_pointer_input(event.position)
		return true

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_move_ship_to_screen_position(event.position)
		return true

	if _handle_zoom_input(event):
		return true

	if event is InputEventMouseMotion and _is_dragging:
		_update_pointer_drag(event.position, event.relative)
		return true

	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_finish_left_pointer_input(event.position)
		return true

	if event is InputEventScreenDrag:
		_update_pointer_drag(event.position, event.relative)
		return true

	return false


func center_on_ship() -> void:
	if _ship == null or not is_instance_valid(_ship):
		return

	center_on_world_position(_ship.global_position)


func center_on_world_position(world_position: Vector2) -> void:
	set_ship_selected(false)
	set_camera_position(world_position, _camera.zoom)


func follow_ship() -> void:
	if _camera == null or _ship == null or not is_instance_valid(_ship):
		return

	var clamped_ship_position := clamp_camera_position(_ship.global_position, _camera.zoom)
	if _camera.position.is_equal_approx(clamped_ship_position):
		return

	set_camera_position(clamped_ship_position, _camera.zoom)


func set_ship_selected(is_selected: bool) -> void:
	if _is_game_over():
		is_selected = false

	if _is_ship_selected == is_selected:
		return

	_is_ship_selected = is_selected
	if _ship != null and is_instance_valid(_ship) and _ship.has_method("set_selected"):
		_ship.call("set_selected", is_selected)


func sync_starfield() -> void:
	if _camera != null and _starfield != null and _starfield.has_method("sync_to_camera"):
		_starfield.call("sync_to_camera", _camera.get_screen_center_position(), _camera.zoom)


func shake(intensity: float) -> void:
	if _camera == null:
		return

	_shake_trauma = maxf(_shake_trauma, clampf(intensity, 0.0, shake_max_trauma))
	_update_camera_shake(0.0)


func shake_from_world_position(intensity: float, source_world_position: Vector2) -> void:
	var effective_intensity := intensity * _get_visible_shake_ratio(source_world_position)
	if effective_intensity <= 0.001:
		return

	shake(effective_intensity)


func world_to_screen_position(world_position: Vector2) -> Vector2:
	if _camera == null or _viewport_owner == null:
		return world_position

	var safe_zoom: Vector2 = _get_safe_zoom(_camera.zoom)
	return (world_position - _camera.position) * safe_zoom + _viewport_owner.get_viewport_rect().size * 0.5


func screen_to_world(screen_position: Vector2, zoom_value: Vector2) -> Vector2:
	if _camera == null or _viewport_owner == null:
		return screen_position

	var viewport_size: Vector2 = _viewport_owner.get_viewport_rect().size
	var mouse_offset: Vector2 = screen_position - viewport_size * 0.5
	return _camera.position + mouse_offset / _get_safe_zoom(zoom_value)


func set_camera_position(desired_position: Vector2, zoom_value: Vector2) -> void:
	if _camera == null:
		return

	_camera.position = clamp_camera_position(desired_position, zoom_value)
	_camera.force_update_scroll()
	sync_starfield()


func clamp_camera_position(desired_position: Vector2, zoom_value: Vector2) -> Vector2:
	if _viewport_owner == null:
		return desired_position

	var world_radius: float = _get_world_radius()
	var viewport_size: Vector2 = _viewport_owner.get_viewport_rect().size
	var half_view_size: Vector2 = viewport_size * 0.5 / _get_safe_zoom(zoom_value)
	var clamped_position := desired_position

	var min_x: float = -world_radius + half_view_size.x
	var max_x: float = world_radius - half_view_size.x
	if min_x <= max_x:
		clamped_position.x = clampf(clamped_position.x, min_x, max_x)
	else:
		clamped_position.x = 0.0

	var min_y: float = -world_radius + half_view_size.y
	var max_y: float = world_radius - half_view_size.y
	if min_y <= max_y:
		clamped_position.y = clampf(clamped_position.y, min_y, max_y)
	else:
		clamped_position.y = 0.0

	return clamped_position


func _handle_zoom_input(event: InputEvent) -> bool:
	if event.is_action_pressed("zoom_in"):
		_apply_zoom(1.0 + zoom_step)
		return true

	if event.is_action_pressed("zoom_out"):
		_apply_zoom(1.0 / (1.0 + zoom_step))
		return true

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_apply_zoom(1.0 + zoom_step)
			return true
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_apply_zoom(1.0 / (1.0 + zoom_step))
			return true

	if event is InputEventMagnifyGesture:
		var magnify_event := event as InputEventMagnifyGesture
		if not is_equal_approx(magnify_event.factor, 1.0):
			_apply_zoom(magnify_event.factor)
		return true

	if event is InputEventPanGesture:
		var pan_event := event as InputEventPanGesture
		if absf(pan_event.delta.y) < 0.001:
			return false

		var trackpad_zoom_amount := clampf(absf(pan_event.delta.y) * trackpad_zoom_step, 0.001, 0.08)
		if pan_event.delta.y < 0.0:
			_apply_zoom(1.0 + trackpad_zoom_amount)
		else:
			_apply_zoom(1.0 / (1.0 + trackpad_zoom_amount))
		return true

	return false


func _begin_drag(screen_position: Vector2) -> void:
	_is_dragging = true
	_has_dragged = false
	_drag_start_screen_position = screen_position


func _finish_left_pointer_input(screen_position: Vector2) -> void:
	if not _is_dragging:
		return

	_is_dragging = false
	if not _has_dragged:
		_handle_left_click(screen_position)


func _update_pointer_drag(screen_position: Vector2, screen_delta: Vector2) -> void:
	if not _has_dragged:
		_has_dragged = screen_position.distance_to(_drag_start_screen_position) >= click_drag_threshold

	if _has_dragged:
		_pan_camera(screen_delta)


func _pan_camera(screen_delta: Vector2) -> void:
	set_ship_selected(false)
	set_camera_position(_camera.position - screen_delta * drag_sensitivity / _get_safe_zoom(_camera.zoom), _camera.zoom)


func _pan_camera_with_keyboard(direction: Vector2, delta: float) -> void:
	set_camera_position(_camera.position + direction * keyboard_pan_speed * delta / _get_safe_zoom(_camera.zoom), _camera.zoom)


func _apply_zoom(zoom_multiplier: float) -> void:
	var safe_min_zoom := minf(min_zoom, max_zoom)
	var safe_max_zoom := maxf(min_zoom, max_zoom)
	var next_zoom := clampf(_camera.zoom.x * zoom_multiplier, safe_min_zoom, safe_max_zoom)
	var mouse_world_before := _get_mouse_world_position(_camera.zoom)
	_camera.zoom = Vector2(next_zoom, next_zoom)
	set_camera_position(_camera.position + mouse_world_before - _get_mouse_world_position(_camera.zoom), _camera.zoom)


func _get_mouse_world_position(zoom_value: Vector2) -> Vector2:
	if _viewport_owner == null:
		return Vector2.ZERO

	return screen_to_world(_viewport_owner.get_viewport().get_mouse_position(), zoom_value)


func _is_pointer_over_gui_control() -> bool:
	if _viewport_owner == null:
		return false

	var viewport := _viewport_owner.get_viewport()
	if viewport == null:
		return false

	var hovered_control := viewport.gui_get_hovered_control()
	while hovered_control != null:
		if hovered_control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			return true
		hovered_control = hovered_control.get_parent_control()

	return false


func _handle_left_click(screen_position: Vector2) -> void:
	if _is_game_over():
		return

	var world_position := screen_to_world(screen_position, _camera.zoom)
	if _is_ship_at_world_position(world_position):
		set_ship_selected(true)
		follow_ship()


func _move_ship_to_screen_position(screen_position: Vector2) -> void:
	if _is_game_over():
		return

	_move_ship_to_world_position(screen_to_world(screen_position, _camera.zoom), true)


func _move_ship_to_cursor() -> void:
	if _is_game_over():
		return

	_move_ship_to_world_position(_get_mouse_world_position(_camera.zoom), false)


func _move_ship_to_world_position(world_position: Vector2, show_feedback: bool = true) -> void:
	if _move_ship_callback.is_valid():
		_move_ship_callback.call(world_position, show_feedback)
	elif _ship != null and is_instance_valid(_ship) and _ship.has_method("move_to"):
		_ship.call("move_to", world_position)


func _is_ship_at_world_position(world_position: Vector2) -> bool:
	if _ship != null and is_instance_valid(_ship) and _ship.has_method("contains_world_position"):
		return bool(_ship.call("contains_world_position", world_position))

	return false


func _get_safe_zoom(zoom_value: Vector2) -> Vector2:
	return Vector2(maxf(zoom_value.x, 0.001), maxf(zoom_value.y, 0.001))


func _get_world_radius() -> float:
	if _world_radius_provider.is_valid():
		return maxf(float(_world_radius_provider.call()), 1.0)

	return 1.0


func _is_game_over() -> bool:
	return bool(_game_over_provider.call()) if _game_over_provider.is_valid() else false


func _get_visible_shake_ratio(source_world_position: Vector2) -> float:
	if _camera == null or _viewport_owner == null:
		return 1.0

	var half_view_size: Vector2 = _viewport_owner.get_viewport_rect().size * 0.5 / _get_safe_zoom(_camera.zoom)
	var source_delta := source_world_position - _camera.position
	var outside_view_distance := Vector2(
		maxf(absf(source_delta.x) - half_view_size.x, 0.0),
		maxf(absf(source_delta.y) - half_view_size.y, 0.0)
	).length()
	if outside_view_distance <= 0.0:
		return 1.0

	return 1.0 - clampf(outside_view_distance / maxf(shake_falloff_distance, 1.0), 0.0, 1.0)


func _update_camera_shake(delta: float) -> void:
	if _camera == null:
		return

	if _shake_trauma <= 0.0:
		_camera.offset = Vector2.ZERO
		_camera.rotation = _camera_base_rotation
		return

	var shake_amount := _shake_trauma * _shake_trauma
	_camera.offset = Vector2(
		_shake_rng.randf_range(-1.0, 1.0),
		_shake_rng.randf_range(-1.0, 1.0)
	) * shake_max_offset * shake_amount
	_camera.rotation = _camera_base_rotation + _shake_rng.randf_range(-1.0, 1.0) * shake_max_rotation * shake_amount
	_shake_trauma = maxf(_shake_trauma - shake_decay * delta, 0.0)
