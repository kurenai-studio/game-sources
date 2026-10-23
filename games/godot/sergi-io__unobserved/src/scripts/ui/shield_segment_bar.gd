class_name ShieldSegmentBar
extends Control

signal became_empty

@export_range(1, 999, 1) var hit_points_per_level: int = 10
@export_range(0.0, 8.0, 0.1) var chunk_gap: float = 2.0
@export_range(0.0, 6.0, 0.1) var control_padding: float = 1.0
@export var control_background_color: Color = Color(0.015, 0.06, 0.10, 0.88)
@export var control_border_color: Color = Color(0.20, 0.55, 0.76, 0.42)
@export var background_color: Color = Color(0.03, 0.12, 0.20, 1.0)
@export var fill_color: Color = Color(0.12, 0.66, 1.0, 1.0)
@export var depleted_color: Color = Color(0.06, 0.18, 0.28, 0.78)
@export var border_color: Color = Color(0.46, 0.86, 1.0, 0.48)
@export_range(0.0, 4.0, 0.1) var corner_radius: float = 3.0
@export_range(0.0, 8.0, 0.1) var control_corner_radius: float = 5.0

var _displayed_hit_points: float = 0.0
var _displayed_levels: int = 0
var _target_levels: int = 0
var _value_tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(140.0, 12.0)


func set_shield(current_shield_hp: int, max_shield_hp: int, shield_level: int, animate: bool = true) -> void:
	var safe_levels := maxi(shield_level, 0)
	var safe_max_hp := maxi(max_shield_hp, 0)
	var safe_current_hp := clampi(current_shield_hp, 0, safe_max_hp)
	_target_levels = safe_levels

	if _value_tween != null and _value_tween.is_running():
		_value_tween.kill()
	_value_tween = null

	if safe_levels <= 0 and safe_current_hp <= 0:
		if animate and _displayed_levels > 0 and _displayed_hit_points > 0.0:
			_animate_to(0.0, _displayed_levels, 0)
		else:
			_displayed_levels = 0
			_displayed_hit_points = 0.0
			queue_redraw()
			became_empty.emit()
		return

	if _displayed_levels <= 0:
		_displayed_levels = safe_levels
	elif safe_levels > _displayed_levels:
		_displayed_levels = safe_levels

	var visible_levels := _displayed_levels
	if safe_levels < _displayed_levels and safe_current_hp < _displayed_hit_points:
		visible_levels = _displayed_levels
	else:
		visible_levels = safe_levels

	if animate:
		_animate_to(float(safe_current_hp), visible_levels, safe_levels)
	else:
		_displayed_levels = safe_levels
		_displayed_hit_points = float(safe_current_hp)
		queue_redraw()


func _animate_to(target_hit_points: float, visible_levels: int, final_levels: int) -> void:
	_displayed_levels = maxi(visible_levels, final_levels)
	_value_tween = create_tween()
	_value_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_value_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	_value_tween.set_trans(Tween.TRANS_QUAD)
	_value_tween.set_ease(Tween.EASE_OUT)
	_value_tween.tween_method(_set_displayed_hit_points, _displayed_hit_points, target_hit_points, 0.22)
	if final_levels < _displayed_levels:
		_value_tween.tween_callback(_finish_level_drop.bind(final_levels, target_hit_points))
	elif final_levels <= 0 and target_hit_points <= 0.0:
		_value_tween.tween_callback(func() -> void: became_empty.emit())


func _set_displayed_hit_points(value: float) -> void:
	_displayed_hit_points = maxf(value, 0.0)
	queue_redraw()


func _finish_level_drop(final_levels: int, target_hit_points: float) -> void:
	_displayed_levels = maxi(final_levels, 0)
	_displayed_hit_points = maxf(target_hit_points, 0.0)
	queue_redraw()
	if _displayed_levels <= 0:
		became_empty.emit()


func _draw() -> void:
	if _displayed_levels <= 0:
		return

	var control_rect := Rect2(Vector2.ZERO, size)
	_draw_rounded_box(control_rect, control_background_color, control_corner_radius, control_border_color, 1)

	var content_rect := control_rect.grow(-control_padding)
	if content_rect.size.x <= 0.0 or content_rect.size.y <= 0.0:
		return

	var total_gap := chunk_gap * float(maxi(_displayed_levels - 1, 0))
	var chunk_width := maxf((content_rect.size.x - total_gap) / float(_displayed_levels), 1.0)
	var chunk_height := maxf(content_rect.size.y, 1.0)
	var remaining_hp := _displayed_hit_points
	for index in range(_displayed_levels):
		var x := content_rect.position.x + float(index) * (chunk_width + chunk_gap)
		var rect := Rect2(Vector2(x, content_rect.position.y), Vector2(chunk_width, chunk_height))
		_draw_rounded_box(rect, background_color, corner_radius)

		var chunk_fill := clampf(remaining_hp / float(maxi(hit_points_per_level, 1)), 0.0, 1.0)
		if chunk_fill > 0.0:
			var fill_rect := Rect2(rect.position, Vector2(rect.size.x * chunk_fill, rect.size.y))
			_draw_rounded_box(fill_rect, fill_color, corner_radius)
		else:
			_draw_rounded_box(rect, depleted_color, corner_radius)

		_draw_rounded_box(rect, Color.TRANSPARENT, corner_radius, border_color, 1)
		remaining_hp -= float(hit_points_per_level)


func _draw_rounded_box(
	rect: Rect2,
	background: Color,
	radius: float,
	outline: Color = Color.TRANSPARENT,
	outline_width: int = 0
) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return

	var safe_radius := int(round(minf(radius, minf(rect.size.x, rect.size.y) * 0.5)))
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = outline
	style.set_border_width_all(outline_width)
	style.set_corner_radius_all(safe_radius)
	style.draw(get_canvas_item(), rect)
