extends RefCounted


static func show(
	label: Label, previous_tween: Tween, text: String, font_size: int, color: Color, hold: float
) -> Tween:
	if previous_tween != null and previous_tween.is_valid():
		previous_tween.kill()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2.ONE * 0.4
	label.modulate.a = 1.0

	var tween := label.create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(hold)
	tween.tween_property(label, "modulate:a", 0.0, 0.4)
	return tween
