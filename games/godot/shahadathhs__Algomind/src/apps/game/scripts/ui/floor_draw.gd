class_name FloorDraw
extends RefCounted
## Ice and belts (`ice`, `belts`), drawn the same way on the flat and the depth board; `place`
## maps a point in board units to the canvas, as in LockDraw. Ice is a floor cell with a thin inset
## outline and two glints; a belt is a pair of chevrons pointing the way it carries. Neither is only
## a color.


## Draws every ice cell with `soft` (the quiet line color) and every belt with `ink`.
static func draw(
	canvas: CanvasItem, level: Dictionary, place: Callable, soft: Color, ink: Color
) -> void:
	for cell: Array in level.get("ice", []):
		_ice(canvas, place, Vector2i(int(cell[0]), int(cell[1])), soft)
	for belt: Dictionary in level.get("belts", []):
		var at := Vector2i(int(belt["cell"][0]), int(belt["cell"][1]))
		_belt(canvas, place, at, String(belt["direction"]), ink)


static func _line(
	canvas: CanvasItem, place: Callable, cell: Vector2i, points: Array, color: Color, width: float
) -> void:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(place.call(Vector2(cell) + point))
	canvas.draw_polyline(out, color, width)


static func _ice(canvas: CanvasItem, place: Callable, cell: Vector2i, color: Color) -> void:
	var lo := 0.1
	var hi := 0.9
	var frame := [
		Vector2(lo, lo), Vector2(hi, lo), Vector2(hi, hi), Vector2(lo, hi), Vector2(lo, lo)
	]
	_line(canvas, place, cell, frame, color, 1.5)
	_line(canvas, place, cell, [Vector2(0.28, 0.5), Vector2(0.5, 0.28)], color, 2.0)
	_line(canvas, place, cell, [Vector2(0.44, 0.74), Vector2(0.74, 0.44)], color, 2.0)


static func _belt(
	canvas: CanvasItem, place: Callable, cell: Vector2i, direction: String, color: Color
) -> void:
	var delta: Array = ContractLimits.DIRECTION_DELTAS[direction]
	var along := Vector2(float(delta[0]), float(delta[1]))
	var across := Vector2(-along.y, along.x)
	var center := Vector2(0.5, 0.5)
	for offset in [-0.14, 0.14]:
		var back := center + along * (float(offset) - 0.1)
		var chevron := [
			back + across * 0.22,
			center + along * (float(offset) + 0.1),
			back - across * 0.22,
		]
		_line(canvas, place, cell, chevron, color, 3.0)
