extends SpinBox
const Display = preload("res://ui/led_display.gd")
var readout: Control
var bet_outline: ReferenceRect
func _ready() -> void:
	custom_minimum_size = Vector2(78,42)
	var field := get_line_edit()
	field.add_theme_color_override("font_color",Color.TRANSPARENT)
	field.add_theme_color_override("font_selected_color",Color("ff2452"))
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("170e13")
	panel.set_content_margin_all(4)
	field.add_theme_stylebox_override("normal",panel)
	field.add_theme_stylebox_override("read_only",panel)
	readout = Display.new()
	readout.digits = 2
	readout.value = int(value)
	readout.ink = Color("ff6688") if value > 0 else Color("ff2452")
	field.add_child(readout)
	readout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bet_outline = ReferenceRect.new()
	bet_outline.name = "PlacedBetOutline"
	bet_outline.editor_only = false
	bet_outline.border_color = Color("fff52e")
	bet_outline.border_width = 3.0
	bet_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	field.add_child(bet_outline)
	bet_outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bet_outline.visible = value > 0
	value_changed.connect(func(number):
		bet_outline.visible = number > 0
		readout.value = int(number)
		readout.ink = Color("ff6688") if number > 0 else Color("ff2452")
		if field.has_focus(): field.add_theme_color_override("font_color",readout.ink)
		readout.queue_redraw())
	field.focus_entered.connect(func():
		field.add_theme_color_override("font_color",readout.ink)
		readout.hide())
	field.focus_exited.connect(func():
		field.add_theme_color_override("font_color",Color.TRANSPARENT)
		readout.show())
