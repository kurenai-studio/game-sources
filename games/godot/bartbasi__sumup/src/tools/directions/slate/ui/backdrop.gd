extends Control
## Slate backdrop: flat near black bg, filling the control's rect.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")

var _color: Color = Color.BLACK


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(tokens: DirectionTokens) -> void:
	_color = tokens.color("bg")
	queue_redraw()


## Areas to keep clear of backdrop decoration, in global coordinates. The
## flat backdrop has none, so this does nothing.
func set_clear_rects(_rects: Array[Rect2]) -> void:
	pass


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), _color)
