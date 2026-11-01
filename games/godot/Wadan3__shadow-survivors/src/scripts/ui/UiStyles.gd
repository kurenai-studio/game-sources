extends RefCounted

static func panel(color: Color = Color(0.025, 0.045, 0.09, 0.94), border: Color = Color(0.12, 0.72, 0.92, 0.45), radius: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	return style

static func style_button(button: Button, accent: Color = Color("32dfff")) -> void:
	button.custom_minimum_size = Vector2(260, 50)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color("dffbff"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", panel(Color(0.035, 0.075, 0.13, 0.96), Color(accent, 0.35), 8))
	button.add_theme_stylebox_override("hover", panel(Color(0.05, 0.15, 0.22, 0.98), accent, 8))
	button.add_theme_stylebox_override("pressed", panel(Color(0.02, 0.25, 0.32, 1.0), accent, 8))
	button.add_theme_stylebox_override("focus", panel(Color(0.04, 0.12, 0.19, 1.0), Color.WHITE, 8))

static func title(label: Label, size: int = 52, color: Color = Color("7df6ff")) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.75, 1.0, 0.42))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)

static func label(text: String, size: int = 16, color: Color = Color("c5d8ea")) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result
