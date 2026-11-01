class_name UiRows
extends RefCounted
## Rows the list screens share (Settings, Profile, Leaderboard, Daily): captions, gaps, notes,
## ON/OFF rows, and a segmented choice. Colors come from Palette only.

const ROW_HEIGHT := 52.0


static func caption(value: String) -> Label:
	return UiKit.label(value, 14, Palette.MUTE, 2)


static func gap(height: float) -> Control:
	var node := Control.new()
	node.custom_minimum_size = Vector2(0, height)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## A wrapping line of text. A wrapping label needs a width, so it asks for `width`.
static func note(value: String, size: int, color: Color, width: float) -> Label:
	var node := UiKit.label(value, size, color, 1)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.custom_minimum_size = Vector2(width, 0)
	return node


## A row with a label on the left and an ON/OFF tile on the right. ON is yellow with a check.
static func toggle_row(caption_text: String, on: bool, handler: Callable) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	var label := UiKit.label(caption_text, 20, Palette.INK, 1)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	var kind := TileButton.Kind.PRIMARY if on else TileButton.Kind.SECONDARY
	var button := TileButton.make(kind, "ON" if on else "OFF", "check" if on else "", 18)
	button.accessibility_name = "%s, %s" % [caption_text.capitalize(), "on" if on else "off"]
	button.custom_minimum_size = Vector2(92.0, ROW_HEIGHT)
	button.pressed.connect(handler)
	row.add_child(button)
	return row


## A caption and a segmented choice: the selected segment is solid and checked. `labels` are
## shown, `names` are handed to `handler`.
static func segment_row(
	caption_text: String,
	names: Array[String],
	current: String,
	handler: Callable,
	labels: Array[String] = []
) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	if not caption_text.is_empty():
		box.add_child(UiKit.label(caption_text, 20, Palette.INK, 1))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	for i in names.size():
		var option := names[i]
		var shown := labels[i] if i < labels.size() else option.to_upper()
		var selected := option == current
		var kind := TileButton.Kind.SOLID if selected else TileButton.Kind.SECONDARY
		var button := TileButton.make(kind, shown, "check" if selected else "", 16)
		button.accessibility_name = (
			"%s %s%s"
			% [caption_text.capitalize(), shown.to_lower(), ", selected" if selected else ""]
		)
		button.custom_minimum_size = Vector2(0, ROW_HEIGHT)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(handler.bind(option))
		row.add_child(button)
	box.add_child(row)
	return box
