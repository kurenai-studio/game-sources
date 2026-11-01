class_name CoachBar
extends Control
## The first-run coach: a dark bar with a numbered yellow chip and one instruction.

var step_number := 1
var text := ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _draw() -> void:
	var rect := TileDraw.tile(self, Rect2(Vector2.ZERO, size), TileDraw.Tone.SOLID)
	var chip := TileDraw.tile(
		self, Rect2(8.0, (rect.size.y - 24.0) / 2.0, 24.0, 24.0), TileDraw.Tone.ACTIVE
	)
	UiKit.text(self, str(step_number), chip, 16, Palette.ON_SIGNAL, 0)
	var area := Rect2(44.0, 0.0, size.x - 56.0, rect.size.y)
	UiKit.text(self, text, area, 15, Palette.ON_INK, 1, HORIZONTAL_ALIGNMENT_LEFT)
