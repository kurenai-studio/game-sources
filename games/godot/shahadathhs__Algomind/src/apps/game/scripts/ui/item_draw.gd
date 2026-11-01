class_name ItemDraw
extends RefCounted
## Items and docks (`deliveries`), drawn the same way on the flat and the depth board; `place`
## maps a point in board units to the canvas, as in LockDraw. An item is a crate: a solid square
## with a strap. A dock is four corner brackets; once its item is on it, the crate sits inside
## them. The crate being carried is drawn small on the automaton. With several deliveries an item
## and its dock carry the same number of pips, so the pairing is never only a color.


## What a trail of entered cells has done to the items: the index being carried (-1 for none) and
## the delivered ones. The same rules as RunItems, replayed from the cells.
static func state(level: Dictionary, trail: Array[Vector2i]) -> Dictionary:
	var tables := RunItems.tables(level)
	var run := {"carrying": -1, "delivered": {}, "items": tables["items"], "docks": tables["docks"]}
	for cell in trail:
		RunItems.settle(run, cell)
	return run


static func _cell(delivery: Dictionary, part: String) -> Vector2i:
	return Vector2i(int(delivery[part][0]), int(delivery[part][1]))


## A crate in the unit square of `cell`, `size` wide and centered at `center`. `colors` has the
## `edge` and the `fill` of the crate.
static func crate(
	canvas: CanvasItem,
	place: Callable,
	cell: Vector2i,
	center: Vector2,
	size: float,
	colors: Dictionary
) -> void:
	var half := Vector2(size, size) / 2.0
	LockDraw.fill(canvas, place, cell, LockDraw.box(center - half, center + half), colors["edge"])
	var inner := half * 0.78
	LockDraw.fill(canvas, place, cell, LockDraw.box(center - inner, center + inner), colors["fill"])
	var strap := Vector2(inner.x, size * 0.07)
	LockDraw.fill(canvas, place, cell, LockDraw.box(center - strap, center + strap), colors["edge"])


## Draws the docks (with their crate once delivered) and the items still lying on the board.
## `hole` is the floor color; `ink` the color of the brackets and crates.
static func draw_floor(
	canvas: CanvasItem,
	level: Dictionary,
	trail: Array[Vector2i],
	place: Callable,
	hole: Color,
	ink: Color
) -> void:
	var now := state(level, trail)
	var delivered: Dictionary = now["delivered"]
	var deliveries: Array = level["deliveries"]
	var colors := {"edge": ink, "fill": hole}
	for i in deliveries.size():
		var dock := _cell(deliveries[i], "dock")
		_brackets(canvas, place, dock, ink)
		if delivered.has(i):
			crate(canvas, place, dock, Vector2(0.5, 0.46), 0.42, colors)
		if deliveries.size() > 1:
			LockDraw.pips(canvas, place, dock, i, ink)
		if now["carrying"] == i or delivered.has(i):
			continue
		var item := _cell(deliveries[i], "item")
		crate(canvas, place, item, Vector2(0.5, 0.44), 0.5, colors)
		if deliveries.size() > 1:
			LockDraw.pips(canvas, place, item, i, ink)


## The crate being carried, small on the corner of the automaton's cell at `at` (board units, may
## lie between two cells).
static func draw_carried(
	canvas: CanvasItem,
	level: Dictionary,
	trail: Array[Vector2i],
	place: Callable,
	at: Vector2,
	colors: Dictionary
) -> void:
	if int(state(level, trail)["carrying"]) < 0:
		return
	var cell := Vector2i(floori(at.x), floori(at.y))
	crate(canvas, place, cell, at - Vector2(cell) + Vector2(0.27, 0.27), 0.38, colors)


## Four L-shaped corners marking the dock.
static func _brackets(canvas: CanvasItem, place: Callable, cell: Vector2i, ink: Color) -> void:
	var low := 0.14
	var high := 0.86
	var arm := 0.2
	var thick := 0.06
	for flip_x in [false, true]:
		for flip_y in [false, true]:
			var sx := -1.0 if flip_x else 1.0
			var sy := -1.0 if flip_y else 1.0
			var corner := Vector2(high if flip_x else low, high if flip_y else low)
			var across := LockDraw.box(corner, corner + Vector2(sx * arm, sy * thick))
			var down := LockDraw.box(corner, corner + Vector2(sx * thick, sy * arm))
			LockDraw.fill(canvas, place, cell, across, ink)
			LockDraw.fill(canvas, place, cell, down, ink)
