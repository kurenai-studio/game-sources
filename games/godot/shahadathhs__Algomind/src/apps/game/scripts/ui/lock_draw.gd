class_name LockDraw
extends RefCounted
## Keys and doors, drawn the same way on the flat and the depth board. The caller gives `place`,
## a Callable that maps a point in board units (a cell is 1 by 1) to the canvas. A key is a ring
## with a shaft and a tooth; a shut door is a block with a keyhole, and an open one is only an
## outline. When a level has several locks, a key and its door carry the same number of pips (1 to
## 3), so the pairing is never only a color. A key is gone once its cell has been entered, which is
## when its door opens.

const DOOR_INSET := 0.1
const RING_STEPS := 20


## The lock indexes whose key cell is in `trail` (the cells entered so far, the start included).
static func held(level: Dictionary, trail: Array[Vector2i]) -> Dictionary:
	var out := {}
	var locks: Array = level.get("locks", [])
	for i in locks.size():
		var key: Array = locks[i]["key"]
		if trail.has(Vector2i(int(key[0]), int(key[1]))):
			out[i] = true
	return out


static func cell_of(lock: Dictionary, part: String) -> Vector2i:
	return Vector2i(int(lock[part][0]), int(lock[part][1]))


## The footprint of a shut door in board units, for the prism of the depth board.
static func door_footprint(cell: Vector2i) -> PackedVector2Array:
	return BoardFloorLayer.footprint(cell.x, cell.y, DOOR_INSET)


## A circle of the given radius as points.
static func ring(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in RING_STEPS:
		points.append(center + Vector2.from_angle(TAU * float(i) / float(RING_STEPS)) * radius)
	return points


static func box(a: Vector2, b: Vector2) -> PackedVector2Array:
	return PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)])


## Fills a shape given in cell units (0 to 1) of `cell`.
static func fill(
	canvas: CanvasItem, place: Callable, cell: Vector2i, shape: PackedVector2Array, color: Color
) -> void:
	var points := PackedVector2Array()
	for point in shape:
		points.append(place.call(Vector2(cell) + point))
	canvas.draw_colored_polygon(points, color)


## The pips that tell lock `index` (0 based) apart, under the shape in `cell`.
static func pips(
	canvas: CanvasItem, place: Callable, cell: Vector2i, index: int, color: Color
) -> void:
	for n in index + 1:
		var at := Vector2(0.5 + (float(n) - float(index) / 2.0) * 0.16, 0.86)
		fill(canvas, place, cell, box(at - Vector2(0.05, 0.05), at + Vector2(0.05, 0.05)), color)


## Draws every key still on the board. `hole` is the color the ring shows through.
static func draw_keys(
	canvas: CanvasItem, level: Dictionary, trail: Array[Vector2i], place: Callable, hole: Color
) -> void:
	var taken := held(level, trail)
	var locks: Array = level.get("locks", [])
	for i in locks.size():
		if taken.has(i):
			continue
		var cell := cell_of(locks[i], "key")
		fill(canvas, place, cell, ring(Vector2(0.34, 0.46), 0.17), Palette.INK)
		fill(canvas, place, cell, ring(Vector2(0.34, 0.46), 0.075), hole)
		fill(canvas, place, cell, box(Vector2(0.48, 0.42), Vector2(0.82, 0.5)), Palette.INK)
		fill(canvas, place, cell, box(Vector2(0.72, 0.5), Vector2(0.8, 0.64)), Palette.INK)
		if locks.size() > 1:
			pips(canvas, place, cell, i, Palette.INK)


## Draws a door: an outline when open; when shut, the keyhole, on a flat block (`flat_block`) or on
## the top of the raised block the depth board has already drawn.
static func draw_door(
	canvas: CanvasItem, level: Dictionary, index: int, open: bool, place: Callable, flat_block: bool
) -> void:
	var locks: Array = level["locks"]
	var cell := cell_of(locks[index], "door")
	var inner := box(Vector2(DOOR_INSET, DOOR_INSET), Vector2(1.0 - DOOR_INSET, 1.0 - DOOR_INSET))
	if open:
		var outline := PackedVector2Array()
		for point in inner:
			outline.append(place.call(Vector2(cell) + point))
		outline.append(outline[0])
		canvas.draw_polyline(outline, Palette.INK, 2.0)
	else:
		if flat_block:
			fill(canvas, place, cell, inner, Palette.INK)
		fill(canvas, place, cell, ring(Vector2(0.5, 0.4), 0.1), Palette.ON_INK)
		var slot := PackedVector2Array(
			[Vector2(0.45, 0.46), Vector2(0.55, 0.46), Vector2(0.58, 0.68), Vector2(0.42, 0.68)]
		)
		fill(canvas, place, cell, slot, Palette.ON_INK)
	if locks.size() > 1:
		pips(canvas, place, cell, index, Palette.INK if open else Palette.ON_INK)
