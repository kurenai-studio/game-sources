class_name DepthBlocks
extends RefCounted
## The raised blocks of the depth board that are not walls: a shut door and a shut gate. Both are a
## low ink prism with the same drawing as on the flat board laid on top.

const HEIGHT := 0.34


static func _colors() -> Dictionary:
	return {
		"top": DepthPalette.INK,
		"front": DepthPalette.INK_FRONT,
		"side": DepthPalette.INK_SIDE,
		"edge": DepthPalette.INK_EDGE
	}


## A shut door: the keyhole on top. `index` is the lock.
static func door(canvas: CanvasItem, view: BoardProjection, level: Dictionary, index: int) -> void:
	var cell := LockDraw.cell_of(level["locks"][index], "door")
	var top := BoardProjection.Z_FLOOR + HEIGHT
	DepthKit.prism(
		canvas, view, LockDraw.door_footprint(cell), BoardProjection.Z_FLOOR, top, _colors()
	)
	var place := func(unit: Vector2) -> Vector2: return view.project(unit.x, unit.y, top + 0.003)
	LockDraw.draw_door(canvas, level, index, false, place, false)


## A shut gate: the bars on top. `index` is the pair.
static func gate(canvas: CanvasItem, view: BoardProjection, level: Dictionary, index: int) -> void:
	var cell := LockDraw.cell_of(level["switches"][index], "gate")
	var top := BoardProjection.Z_FLOOR + HEIGHT
	DepthKit.prism(
		canvas, view, LockDraw.door_footprint(cell), BoardProjection.Z_FLOOR, top, _colors()
	)
	var place := func(unit: Vector2) -> Vector2: return view.project(unit.x, unit.y, top + 0.003)
	var colors := {"block": DepthPalette.INK, "bar": DepthPalette.ON_INK}
	SwitchDraw.draw_gate(canvas, level, index, false, place, false, colors)
