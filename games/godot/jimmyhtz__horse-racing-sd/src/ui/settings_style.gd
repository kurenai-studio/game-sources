extends RefCounted
## Neutral, compact Settings styling, independent from the game cabinet.
static func box(fill: Color, border: Color, padding: int = 7) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(padding)
	return style

static func make(font_size: int = 16) -> Theme:
	var result := Theme.new()
	result.default_font_size = font_size
	var ink := Color("253044")
	for control in ["Label","Button","CheckButton","OptionButton","LineEdit","ItemList","PopupMenu","TabContainer"]:
		result.set_color("font_color",control,ink)
		result.set_color("font_hover_color",control,ink)
		result.set_color("font_pressed_color",control,ink)
		result.set_color("font_focus_color",control,ink)
		result.set_color("font_selected_color",control,ink)
		result.set_color("font_disabled_color",control,Color("727b89"))
	for control in ["Button","OptionButton"]:
		result.set_stylebox("normal",control,box(Color("ffffff"),Color("c4cbd5")))
		result.set_stylebox("hover",control,box(Color("e8f1fc"),Color("6b91c8")))
		result.set_stylebox("pressed",control,box(Color("d7e8fc"),Color("3773bc")))
		result.set_stylebox("disabled",control,box(Color("ebedf0"),Color("cbd0d8")))
		var focus := box(Color.TRANSPARENT,Color("3773bc"))
		focus.set_border_width_all(2)
		result.set_stylebox("focus",control,focus)
	result.set_stylebox("panel","AcceptDialog",box(Color("f6f7fa"),Color("c4cbd5"),14))
	result.set_stylebox("panel","TabContainer",box(Color("ffffff"),Color("dde1e8"),12))
	result.set_stylebox("panel","PopupMenu",box(Color("ffffff"),Color("c4cbd5")))
	result.set_stylebox("hover","PopupMenu",box(Color("e4effc"),Color("b2cbed")))
	result.set_color("font_separator_color","PopupMenu",ink)
	result.set_color("font_accelerator_color","PopupMenu",ink)
	result.set_color("font_hovered_color","ItemList",ink)
	result.set_color("font_hovered_selected_color","ItemList",ink)
	for state in ["hovered","hovered_selected","hovered_selected_focus"]:
		result.set_stylebox(state,"ItemList",box(Color("e4effc"),Color("b2cbed"),5))
	result.set_stylebox("panel","TooltipPanel",box(Color("fffbea"),Color("c4cbd5")))
	result.set_color("font_color","TooltipLabel",ink)
	result.set_stylebox("panel","ItemList",box(Color("f6f7fa"),Color("e1e5eb"),5))
	result.set_stylebox("selected","ItemList",box(Color("dceafd"),Color("b2cbed"),5))
	result.set_stylebox("selected_focus","ItemList",box(Color("dceafd"),Color("7da6dc"),5))
	result.set_stylebox("normal","LineEdit",box(Color("ffffff"),Color("c4cbd5")))
	result.set_stylebox("focus","LineEdit",box(Color.TRANSPARENT,Color("3773bc")))
	result.set_color("font_placeholder_color","LineEdit",Color("737e90"))
	result.set_color("caret_color","LineEdit",ink)
	result.set_stylebox("slider","HSlider",box(Color("dce2eb"),Color("dce2eb"),2))
	result.set_stylebox("grabber_area","HSlider",box(Color("3574bf"),Color("3574bf"),2))
	result.set_stylebox("grabber_area_highlight","HSlider",box(Color("245fa6"),Color("245fa6"),2))
	for state in ["grabber","grabber_highlight","grabber_disabled"]:
		var image := Image.new()
		var color := "#929aa6" if state == "grabber_disabled" else "#3574bf"
		image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"><circle cx="8" cy="8" r="6" fill="%s" stroke="white" stroke-width="2"/></svg>' % color)
		result.set_icon(state,"HSlider",ImageTexture.create_from_image(image))
	return result
