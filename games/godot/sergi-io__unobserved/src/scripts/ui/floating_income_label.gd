extends Label

var _start_position: Vector2 = Vector2.ZERO
var _end_position: Vector2 = Vector2.ZERO
var _duration: float = 1.5
var _elapsed: float = 0.0
var _use_bounce_animation: bool = false


func configure(
	amount: int,
	start_position: Vector2,
	float_distance: float,
	duration: float,
	label_color: Color,
	font_size: int = 66,
	text_format: String = "+%d",
	use_bounce_animation: bool = false
) -> void:
	text = text_format % amount
	_start_position = start_position
	_end_position = start_position + Vector2(0.0, -float_distance)
	_duration = maxf(duration, 0.01)
	_elapsed = 0.0
	_use_bounce_animation = use_bounce_animation

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_scale := float(font_size) / 66.0
	custom_minimum_size = Vector2(72.0, 28.0) * font_scale
	add_theme_font_size_override("font_size", font_size)
	add_theme_color_override("font_color", label_color)
	add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	add_theme_constant_override("outline_size", maxi(1, int(round(float(font_size) / 33.0))))
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	pivot_offset = custom_minimum_size * 0.5
	scale = Vector2(0.2, 0.2) if _use_bounce_animation else Vector2.ONE
	position = start_position
	set_process(true)


func _process(delta: float) -> void:
	_elapsed += delta
	var progress := clampf(_elapsed / _duration, 0.0, 1.0)
	if _use_bounce_animation:
		_update_bounce_animation(progress)
	else:
		position = _start_position.lerp(_end_position, progress)

	_update_fade(progress)

	if progress >= 1.0:
		queue_free()


func _update_bounce_animation(progress: float) -> void:
	var movement_progress := 1.0 - pow(1.0 - progress, 2.0)
	position = _start_position.lerp(_end_position, movement_progress)

	var bounce_scale := 1.0
	if progress < 0.12:
		bounce_scale = lerpf(0.2, 1.35, _ease_out(progress / 0.12))
	elif progress < 0.24:
		bounce_scale = lerpf(1.35, 0.82, _ease_out((progress - 0.12) / 0.12))
	elif progress < 0.36:
		bounce_scale = lerpf(0.82, 1.08, _ease_out((progress - 0.24) / 0.12))
	elif progress < 0.48:
		bounce_scale = lerpf(1.08, 1.0, _ease_out((progress - 0.36) / 0.12))
	else:
		bounce_scale = 1.0

	scale = Vector2.ONE * bounce_scale


func _update_fade(progress: float) -> void:
	var faded := modulate
	if _use_bounce_animation:
		var fade_progress := clampf((progress - 0.45) / 0.55, 0.0, 1.0)
		faded.a = 1.0 - fade_progress
	else:
		faded.a = 1.0 - progress
	modulate = faded


func _ease_out(progress: float) -> float:
	var safe_progress := clampf(progress, 0.0, 1.0)
	return 1.0 - pow(1.0 - safe_progress, 3.0)
