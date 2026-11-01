extends SkinBackdrop
## Gumdrop backdrop (DESIGN_SYSTEM.md 4.7): flat bg over the whole control.

var _color: Color = Color.BLACK


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(skin: SkinData) -> void:
	_color = skin.color(&"bg")
	queue_redraw()


## The flat backdrop has no decoration to keep clear.
func set_clear_rects(_rects: Array[Rect2]) -> void:
	pass


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), _color)
