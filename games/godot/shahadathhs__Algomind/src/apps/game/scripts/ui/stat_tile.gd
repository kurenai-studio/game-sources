class_name StatTile
extends Control
## One result figure: a large value over a small caption, in an outlined tile.

var value := ""
var caption := ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if UiLook.depth:
		rect = TileDraw.tile(self, rect, TileDraw.Tone.PLAIN)
	else:
		UiKit.fill_chamfer(self, rect, Palette.GROUND)
		UiKit.outline_chamfer(self, rect, Palette.INK)
	var top := Rect2(0.0, rect.size.y * 0.1, size.x, rect.size.y * 0.55)
	UiKit.text(self, value, top, int(rect.size.y * 0.5), Palette.INK, 0)
	var bottom := Rect2(0.0, rect.size.y * 0.62, size.x, rect.size.y * 0.3)
	UiKit.text(self, caption, bottom, 13, Palette.MUTE, 2)
