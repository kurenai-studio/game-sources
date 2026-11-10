class_name PanArrow
extends Control
## A small pixel arrow at the edge of the strip. Pressing it asks the view to pan that way.
## It is only shown while there is more world in its direction.

signal pressed

const OUTLINE: Color = Color("2b2d42")
const FILL: Color = Color("f3e9d2")
const FILL_HOVER: Color = Color("ffffff")
const HALF_HEIGHT: int = 5
const SIZE: Vector2 = Vector2(14.0, 30.0)

## -1 points left, 1 points right.
var direction: int = 1

var _hover: bool = false


func _init(p_direction: int = 1) -> void:
	direction = p_direction
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()


func _draw() -> void:
	var center: Vector2 = SIZE / 2.0
	for offset: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		_draw_triangle(center + offset, OUTLINE)
	_draw_triangle(center, FILL_HOVER if _hover else FILL)


## A chunky pixel triangle: one 1 px row at a time, widest in the middle.
func _draw_triangle(center: Vector2, color: Color) -> void:
	var depth: int = HALF_HEIGHT + 1
	for row: int in range(-HALF_HEIGHT, HALF_HEIGHT + 1):
		var width: int = depth - absi(row)
		var left: float = center.x - float(depth) / 2.0 if direction > 0 \
				else center.x + float(depth) / 2.0 - float(width)
		draw_rect(Rect2(floorf(left), floorf(center.y) + float(row), float(width), 1.0), color)


func _set_hover(value: bool) -> void:
	_hover = value
	queue_redraw()
