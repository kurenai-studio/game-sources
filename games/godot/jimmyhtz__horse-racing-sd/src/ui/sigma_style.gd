extends RefCounted
const GOLD := Color("efbc42")
const INK := Color("27221c")
const SILVER := Color("c8c4b8")
const BURGUNDY := Color("3a111b")

static func plate(color: Color = SILVER, edge: Color = Color("62594b"), radius: int = 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = edge
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0.05,0.025,0.01,0.6)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0,3)
	return style

static func theme(font_size: int = 18) -> Theme:
	var result := Theme.new()
	result.default_font_size = font_size
	for type in ["Label","Button","CheckBox","CheckButton","OptionButton","LineEdit","ItemList","TabContainer","PopupMenu"]:
		result.set_color("font_color",type,INK)
		result.set_color("font_hover_color",type,INK)
		result.set_color("font_pressed_color",type,INK)
		result.set_color("font_focus_color",type,INK)
		result.set_color("font_disabled_color",type,Color("746c5c"))
	for type in ["Button","OptionButton"]:
		result.set_stylebox("normal",type,plate(GOLD,Color("7e531a"),6))
		result.set_stylebox("hover",type,plate(Color("ffda72"),Color("93601a"),6))
		var pressed := plate(Color("bb8728"),Color("5b3b1c"),6)
		pressed.shadow_size = 0
		pressed.content_margin_top = 15
		pressed.content_margin_bottom = 9
		result.set_stylebox("pressed",type,pressed)
		result.set_stylebox("disabled",type,plate(Color("a39a84"),Color("6f6759"),6))
	result.set_stylebox("panel","PanelContainer",plate())
	result.set_stylebox("panel","AcceptDialog",plate())
	result.set_stylebox("panel","PopupMenu",plate())
	result.set_stylebox("panel","TabContainer",plate(Color("d6d1c2")))
	result.set_stylebox("panel","ItemList",plate(Color("bdb7a8")))
	result.set_color("font_selected_color","ItemList",INK)
	result.set_stylebox("selected","ItemList",plate(GOLD))
	result.set_stylebox("selected_focus","ItemList",plate(GOLD))
	result.set_stylebox("normal","LineEdit",plate(Color("f2eddf"),Color("827a6b")))
	result.set_stylebox("read_only","LineEdit",plate(Color("c1bbac"),Color("827a6b")))
	result.set_color("caret_color","LineEdit",INK)
	result.set_color("font_placeholder_color","LineEdit",Color("776f60"))
	return result

static func step_button(button: Button, upper: bool) -> void:
	button.custom_minimum_size = Vector2(24,23)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size",11)
	for state in ["normal","hover","pressed","disabled"]:
		var style := plate(Color("edbd35") if state != "pressed" else Color("b1811c"),Color("30271c"),3)
		style.corner_radius_top_left = 16 if upper else 3
		style.corner_radius_top_right = 16 if upper else 3
		style.corner_radius_bottom_left = 3 if upper else 16
		style.corner_radius_bottom_right = 3 if upper else 16
		style.set_border_width_all(2)
		style.set_content_margin_all(4)
		style.shadow_size = 0 if state == "pressed" else 2
		if state == "disabled":
			style.bg_color = Color("a79a74")
		button.add_theme_stylebox_override(state,style)

static func bet_button(button: Button) -> void:
	button.custom_minimum_size = Vector2(54,54)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size",12)
	for state in ["normal","hover","pressed","disabled"]:
		var style := plate(Color("efbd31") if state != "pressed" else Color("d5a01b"),Color("24211b"),27)
		style.set_border_width_all(5)
		style.set_content_margin_all(4)
		style.shadow_size = 1 if state == "pressed" else 4
		if state == "disabled": style.bg_color = Color("a99a67")
		if state == "hover": style.bg_color = Color("ffdb62")
		button.add_theme_stylebox_override(state,style)

static func indicator(button: Button, lit: bool) -> void:
	button.toggle_mode = true
	button.button_pressed = lit
	button.add_theme_color_override("font_pressed_color",Color("15371c"))
	button.add_theme_color_override("font_hover_pressed_color",Color("15371c"))
	button.add_theme_color_override("font_color",Color("e4ddc9"))
	button.add_theme_color_override("font_hover_color",Color("e4ddc9"))
	button.add_theme_color_override("font_focus_color",Color("15371c") if lit else Color("e4ddc9"))
	button.add_theme_color_override("font_disabled_color",Color("15371c") if lit else Color("c1bcae"))
	for state in ["normal","hover","pressed","hover_pressed","disabled"]:
		var bright: bool = state in ["pressed","hover_pressed"] or (state == "disabled" and lit)
		var style := plate(Color("caff81") if bright else Color("514f43"),Color("293022"),5)
		style.set_content_margin_all(5)
		style.shadow_size = 2
		if bright:
			style.shadow_color = Color(0.55,1.0,0.2,0.35)
			style.shadow_size = 4
		if state in ["hover","hover_pressed"]:
			style.border_color=Color("fff155")
			style.set_border_width_all(3)
		button.add_theme_stylebox_override(state,style)
