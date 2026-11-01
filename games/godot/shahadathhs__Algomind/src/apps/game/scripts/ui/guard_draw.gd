class_name GuardDraw
extends RefCounted
## Where the guards of a level stand while a run is shown, and how one is drawn. A guard is a
## diamond with a ring and a dot, so it never reads as the square automaton or as a wall; its
## route is a thin line with a dot on every cell. The position follows the step count, so an
## animation only tweens `time` (the number of steps shown, fractional while a step slides).

const DIAMOND := 0.34


## The cell [x, y] (fractional between two steps) of every guard at `time` steps.
static func positions(level: Dictionary, time: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var whole := floori(time)
	var part := time - float(whole)
	for patrol: Dictionary in level.get("patrols", []):
		var a := Patrol.cell(patrol, whole)
		var cell := Vector2(int(a[0]), int(a[1]))
		if part > 0.0:
			var b := Patrol.cell(patrol, whole + 1)
			cell = cell.lerp(Vector2(int(b[0]), int(b[1])), part)
		out.append(cell)
	return out


## The route of a patrol as cell centers, in board units; a loop returns to its first cell.
static func route(patrol: Dictionary) -> PackedVector2Array:
	var points := PackedVector2Array()
	for cell: Array in patrol["cells"]:
		points.append(Vector2(int(cell[0]) + 0.5, int(cell[1]) + 0.5))
	if patrol["pattern"] == "loop":
		points.append(points[0])
	return points


## A diamond of the given radius around `center`.
static func diamond(center: Vector2, radius: float) -> PackedVector2Array:
	return PackedVector2Array(
		[
			center + Vector2(0.0, -radius),
			center + Vector2(radius, 0.0),
			center + Vector2(0.0, radius),
			center + Vector2(-radius, 0.0),
		]
	)


## True when a guard (a position from `positions`) stands on the cell.
static func on_cell(guard: Vector2, cell: Variant) -> bool:
	return cell != null and roundi(guard.x) == cell.x and roundi(guard.y) == cell.y


## The flat look: routes under, then the guard. `rect_of` maps board units (a cell is 1) to pixels.
static func draw_flat(
	canvas: CanvasItem, level: Dictionary, time: float, caught: Variant, rect_of: Callable
) -> void:
	for patrol: Dictionary in level.get("patrols", []):
		var points := route(patrol)
		for i in points.size():
			var at: Vector2 = rect_of.call(points[i])
			canvas.draw_circle(at, 3.0, Palette.WALL_HATCH)
			if i > 0:
				canvas.draw_line(rect_of.call(points[i - 1]), at, Palette.WALL_HATCH, 2.0)
	for guard in positions(level, time):
		var center: Vector2 = rect_of.call(guard + Vector2(0.5, 0.5))
		var radius: float = (rect_of.call(Vector2(DIAMOND, 0.0)) - rect_of.call(Vector2.ZERO)).x
		var face := Palette.SIGNAL if on_cell(guard, caught) else Palette.INK
		var ink := Palette.ON_SIGNAL if on_cell(guard, caught) else Palette.ON_INK
		canvas.draw_colored_polygon(diamond(center, radius), face)
		canvas.draw_arc(center, radius * 0.5, 0.0, TAU, 24, ink, 2.0)
		canvas.draw_circle(center, radius * 0.22, ink)
