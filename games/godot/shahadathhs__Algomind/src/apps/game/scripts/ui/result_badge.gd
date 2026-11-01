class_name ResultBadge
extends Control
## The square beside the result message: check for solved, X for failed.

var kind := "check"


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var face := Rect2(Vector2.ZERO, size)
	if UiLook.depth:
		face = TileDraw.tile(self, face, TileDraw.Tone.ACTIVE)
	else:
		UiKit.fill_chamfer(self, face, Palette.SIGNAL)
	UiKit.icon(self, kind, face.get_center(), size.x * 0.62, Palette.ON_SIGNAL)
