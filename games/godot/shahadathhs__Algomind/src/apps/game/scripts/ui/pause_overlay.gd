class_name PauseOverlay
extends Control
## The pause menu over the dimmed game: Resume (the one primary), then four outlined actions.

signal resume
signal restart
signal how_to_play
signal open_settings
signal back_to_levels

var level_caption := ""
var back_label := "BACK TO LEVELS"

var _caption: Label
var _title: Label
var _buttons: Array[TileButton] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_caption = UiKit.label(level_caption, 14, Palette.MUTE, 3)
	add_child(_caption)
	_title = UiKit.label("PAUSED", 40, Palette.INK, 1)
	add_child(_title)
	_add_button(TileButton.Kind.PRIMARY, "RESUME", 26, resume)
	_add_button(TileButton.Kind.SECONDARY, "RESTART LEVEL", 18, restart)
	_add_button(TileButton.Kind.SECONDARY, "HOW TO PLAY", 18, how_to_play)
	_add_button(TileButton.Kind.SECONDARY, "SETTINGS", 18, open_settings)
	_add_button(TileButton.Kind.SECONDARY, back_label, 18, back_to_levels)
	resized.connect(_place)
	_place()


func _add_button(kind: TileButton.Kind, text: String, font_px: int, action: Signal) -> void:
	var button := TileButton.make(kind, text, "", font_px)
	button.pressed.connect(func() -> void: action.emit())
	add_child(button)
	_buttons.append(button)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.GROUND)


func _place() -> void:
	if _buttons.is_empty():
		return
	var m := 20.0 if size.x >= 380.0 else 16.0
	var width := size.x - 2.0 * m
	var gap := 10.0
	var heights: Array[float] = [64.0, 52.0, 52.0, 52.0, 52.0]
	var total := 0.0
	for h in heights:
		total += h + gap
	var bottom := size.y - m
	var y := bottom - total + gap
	for i in _buttons.size():
		_buttons[i].position = Vector2(m, y)
		_buttons[i].size = Vector2(width, heights[i])
		y += heights[i] + gap
	var title_y := _buttons[0].position.y - 70.0
	_caption.position = Vector2(m, title_y - 24.0)
	_caption.size = Vector2(width, 18.0)
	_title.position = Vector2(m, title_y)
	_title.size = Vector2(width, 52.0)
	queue_redraw()
