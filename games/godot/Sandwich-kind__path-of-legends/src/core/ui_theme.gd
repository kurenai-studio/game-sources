class_name UiTheme
# Общий стиль интерфейса: рисованные кнопки-пластины с окантовкой и заклёпками.

static func build() -> Theme:
	var th := Theme.new()
	# рисованные пластины с бронзовой окантовкой (см. UiArt)
	for state in ["normal", "hover", "pressed", "disabled"]:
		th.set_stylebox(state, "Button", UiArt.button_box(state))
	# рамка выбранной кнопки (видна, когда меню листают геймпадом)
	var fo := StyleBoxFlat.new()
	fo.draw_center = false
	fo.border_color = Color(1.0, 0.85, 0.3)
	fo.set_border_width_all(4)
	fo.set_corner_radius_all(8)
	fo.expand_margin_left = 4
	fo.expand_margin_right = 4
	fo.expand_margin_top = 4
	fo.expand_margin_bottom = 4
	for cls in ["Button", "CheckButton", "HSlider", "LineEdit"]:
		th.set_stylebox("focus", cls, fo)
	th.set_color("font_color", "Button", Color(1.0, 0.95, 0.85))
	th.set_color("font_hover_color", "Button", Color(1.0, 0.9, 0.6))
	th.set_color("font_pressed_color", "Button", Color(1.0, 0.85, 0.5))
	th.set_constant("outline_size", "Button", 4)
	th.set_color("font_outline_color", "Button", Color(0, 0, 0, 0.6))
	th.set_constant("outline_size", "Label", 4)
	th.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.55))
	return th

static func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.set_corner_radius_all(14)
	st.border_color = border
	st.set_border_width_all(3)
	st.shadow_color = Color(0, 0, 0, 0.35)
	st.shadow_size = 6
	st.shadow_offset = Vector2(0, 4)
	st.content_margin_left = 12
	st.content_margin_right = 12
	return st
