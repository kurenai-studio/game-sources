class_name HintOverlay
extends Control
## A hint over the game: a dark panel with "HINT n OF m" and the text, then Close and Next hint.
## Hints are optional level data; a level without any shows a plain line instead.

signal closed
signal next_hint

var hints: Array[String] = []
var index := 0

var _next: TileButton
var _close: TileButton


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_close = TileButton.make(TileButton.Kind.SECONDARY, "CLOSE", "", 18)
	_close.pressed.connect(func() -> void: closed.emit())
	add_child(_close)
	_next = TileButton.make(TileButton.Kind.PRIMARY, "NEXT HINT", "", 22)
	_next.pressed.connect(_on_next)
	add_child(_next)
	_refresh_buttons()
	resized.connect(_place)
	_place()


func _on_next() -> void:
	if index < hints.size() - 1:
		index += 1
		next_hint.emit()
		_refresh_buttons()
		queue_redraw()


func _refresh_buttons() -> void:
	_next.set_disabled(index >= hints.size() - 1)


func _panel_rect() -> Rect2:
	var m := 20.0 if size.x >= 380.0 else 16.0
	var panel_h := 150.0
	var button_h := 56.0
	var bottom := size.y - m - button_h - 12.0
	return Rect2(m, bottom - panel_h, size.x - 2.0 * m, panel_h)


func _place() -> void:
	if _next == null:
		return
	var m := 20.0 if size.x >= 380.0 else 16.0
	var width := size.x - 2.0 * m
	var h := 56.0
	var y := size.y - m - h
	var close_w := floorf(width * 0.32)
	_close.position = Vector2(m, y)
	_close.size = Vector2(close_w, h)
	_next.position = Vector2(m + close_w + 10.0, y)
	_next.size = Vector2(width - close_w - 10.0, h)
	queue_redraw()


func _draw() -> void:
	var dim := Palette.GROUND
	dim.a = 0.72
	draw_rect(Rect2(Vector2.ZERO, size), dim)
	var panel := TileDraw.tile(self, _panel_rect(), TileDraw.Tone.SOLID)
	var pad := 18.0
	var caption := "NO HINTS" if hints.is_empty() else "HINT %d OF %d" % [index + 1, hints.size()]
	var chip := TileDraw.tile(
		self,
		Rect2(
			panel.position.x + pad,
			panel.position.y + pad,
			UiKit.text_width(caption, 13, 2) + 20.0,
			26.0
		),
		TileDraw.Tone.ACTIVE
	)
	UiKit.text(self, caption, chip, 13, Palette.ON_SIGNAL, 2)
	var text := (
		"THERE ARE NO HINTS FOR THIS LEVEL." if hints.is_empty() else hints[index].to_upper()
	)
	var area := Rect2(
		panel.position.x + pad,
		chip.end.y + 10.0,
		panel.size.x - 2.0 * pad,
		panel.size.y - 2.0 * pad - 36.0
	)
	var f := UiKit.font(0)
	draw_multiline_string(
		f,
		Vector2(area.position.x, area.position.y + f.get_ascent(26)),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		area.size.x,
		26,
		3,
		Palette.ON_INK
	)
