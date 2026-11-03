class_name DamageNumber
extends Label
## Pooled floating combat text.

signal finished(node: DamageNumber)

var _tween: Tween


func _init() -> void:
	theme_type_variation = "HudLabel"
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	size = Vector2(120, 32)
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50


func show_number(at: Vector2, text_value: String, color: Color, big: bool = false) -> void:
	text = text_value
	position = at - size / 2.0 + Vector2(randf_range(-10, 10), 0)
	add_theme_color_override("font_color", color)
	add_theme_font_size_override("font_size", 30 if big else 20)
	modulate.a = 1.0
	scale = Vector2.ONE * (0.4 if big else 0.6)
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", Vector2.ONE * (1.25 if big else 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position:y", position.y - 46.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.45)
	_tween.chain().tween_callback(func() -> void: finished.emit(self))
