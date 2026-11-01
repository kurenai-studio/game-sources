class_name BoardFloorLayer
extends Control
## The part of the 2.5D board that changes only when the run's state changes: the plate with its
## shadow, the floor tiles with the trail, the goal pad, the breadcrumbs, and the wall shadows. It
## sits behind the board view (which draws the walls and the automaton), so a moving automaton does
## not redraw hundreds of tiles every frame.

const FOOT_INSET := 0.035
const SHADOW_OFFSET := Vector2(0.2, 0.14)

var board: BoardView25D


func _init(owner_board: BoardView25D) -> void:
	board = owner_board
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _draw() -> void:
	if board.level.is_empty():
		return
	var view := board.projection()
	var level_board: Dictionary = board.level["board"]
	var cols := int(level_board["width"])
	var rows := int(level_board["height"])
	_draw_plate(view, cols, rows)
	var walls := {}
	for wall: Array in level_board["walls"]:
		walls[Vector2i(int(wall[0]), int(wall[1]))] = true
	var goal: Variant = null
	if board.level["goal"].has("position"):
		var cell: Array = board.level["goal"]["position"]
		goal = Vector2i(int(cell[0]), int(cell[1]))
	for y in rows:
		for x in cols:
			var point := Vector2i(x, y)
			if not walls.has(point):
				_draw_cell(view, point, goal != null and point == goal)
	_draw_routes(view)
	for point: Vector2i in walls:
		var shadow := PackedVector2Array()
		for corner in footprint(point.x, point.y, FOOT_INSET):
			shadow.append(view.project(corner.x, corner.y, BoardProjection.Z_FLOOR))
		DepthKit.soft_shadow(
			self, shadow, SHADOW_OFFSET * view.cell_scale, 0.1 * view.cell_scale, 0.4, 6
		)


## The route of every guard, as a thin line with a dot on each cell, lying on the floor.
func _draw_routes(view: BoardProjection) -> void:
	for patrol: Dictionary in board.level.get("patrols", []):
		var points := PackedVector2Array()
		for unit in GuardDraw.route(patrol):
			points.append(view.project(unit.x, unit.y, BoardProjection.Z_FLOOR))
		draw_polyline(points, DepthPalette.WALL_HATCH, 2.0)
		for point in points:
			draw_circle(point, 3.0 * view.cell_scale / 40.0 + 1.5, DepthPalette.WALL_HATCH)


## The square footprint of a cell in board units.
static func footprint(x: float, y: float, inset: float, side: float = 1.0) -> PackedVector2Array:
	return PackedVector2Array(
		[
			Vector2(x + inset, y + inset),
			Vector2(x + side - inset, y + inset),
			Vector2(x + side - inset, y + side - inset),
			Vector2(x + inset, y + side - inset),
		]
	)


func _draw_plate(view: BoardProjection, cols: int, rows: int) -> void:
	var margin := BoardProjection.PLATE_MARGIN
	var corners := PackedVector2Array(
		[
			Vector2(-margin, -margin),
			Vector2(cols + margin, -margin),
			Vector2(cols + margin, rows + margin),
			Vector2(-margin, rows + margin),
		]
	)
	var cast := PackedVector2Array()
	for corner in corners:
		cast.append(view.project(corner.x + 0.1, corner.y + 0.35, BoardProjection.Z_PLATE))
	DepthKit.soft_shadow(self, cast, Vector2.ZERO, 0.22 * view.cell_scale, 0.4, 8)
	DepthKit.prism(
		self,
		view,
		corners,
		BoardProjection.Z_PLATE,
		0.0,
		{
			"top": DepthPalette.PLATE,
			"front": DepthPalette.PLATE_FRONT,
			"side": DepthPalette.PLATE_SIDE,
			"edge": DepthPalette.PLATE_EDGE
		}
	)


func _draw_cell(view: BoardProjection, point: Vector2i, is_goal: bool) -> void:
	var passed := board.trail.has(point)
	var top := DepthPalette.FLOOR
	var front := DepthPalette.FLOOR_FRONT
	var side := DepthPalette.FLOOR_SIDE
	var edge := DepthPalette.FLOOR_EDGE
	var height := BoardProjection.Z_FLOOR
	if is_goal:
		top = DepthPalette.SIGNAL
		front = DepthPalette.SIGNAL_FRONT
		side = DepthPalette.SIGNAL_SIDE
		edge = DepthPalette.SIGNAL_EDGE
		height = board.goal_height()
	elif passed:
		top = DepthPalette.TRAIL
		front = DepthPalette.TRAIL_FRONT
		side = DepthPalette.TRAIL_SIDE
		edge = DepthPalette.TRAIL_EDGE
	var colors := {"top": top, "front": front, "side": side, "edge": edge}
	DepthKit.prism(self, view, footprint(point.x, point.y, FOOT_INSET), 0.0, height, colors)
	var center := Vector2(point.x + 0.5, point.y + 0.5)
	if is_goal:
		_draw_goal(view, center, height)
	elif passed:
		_draw_passed(view, center, height, str(board.crumbs.get(point, "")))


## The target: a ring and a dot on the raised pad.
func _draw_goal(view: BoardProjection, center: Vector2, height: float) -> void:
	var ring := PackedVector2Array()
	var dot := PackedVector2Array()
	for i in 41:
		var angle := TAU * float(i) / 40.0
		var direction := Vector2(cos(angle), sin(angle))
		ring.append(
			view.project(center.x + direction.x * 0.27, center.y + direction.y * 0.27, height)
		)
		if i < 40:
			dot.append(
				view.project(center.x + direction.x * 0.1, center.y + direction.y * 0.1, height)
			)
	draw_polyline(ring, DepthPalette.ON_SIGNAL, maxf(2.0, 0.07 * view.cell_scale))
	draw_colored_polygon(dot, DepthPalette.ON_SIGNAL)


## A cell the automaton passed: a small square marker, or the breadcrumb arrow that leads back.
func _draw_passed(view: BoardProjection, center: Vector2, height: float, crumb: String) -> void:
	if crumb != "":
		var delta: Array = ContractLimits.DIRECTION_DELTAS[crumb]
		var direction := Vector2(float(delta[0]), float(delta[1]))
		var side := Vector2(-direction.y, direction.x) * 0.17
		var arrow := PackedVector2Array()
		for point: Vector2 in [
			center + direction * 0.34,
			center - direction * 0.2 + side,
			center - direction * 0.2 - side
		]:
			arrow.append(view.project(point.x, point.y, height))
		draw_colored_polygon(arrow, DepthPalette.INK)
		return
	var marker := PackedVector2Array()
	for point: Vector2 in footprint(center.x - 0.1, center.y - 0.1, 0.0, 0.2):
		marker.append(view.project(point.x, point.y, height))
	draw_colored_polygon(marker, DepthPalette.SIGNAL)
	var closed := marker.duplicate()
	closed.append(marker[0])
	draw_polyline(closed, DepthPalette.INK, 1.2)
