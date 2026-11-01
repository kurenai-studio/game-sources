class_name BoardView25D
extends BoardView
## The depth look's board: the same state and properties as BoardView (so the play screen and its
## animator drive it unchanged), drawn as an extruded board on a plate. The floor, trail, goal, and
## wall shadows are drawn by BoardFloorLayer behind this node and only when the state changes;
## this node draws what moves or hides things: the walls and the automaton, painted far to near.

const WALL_INSET := 0.035
const AUTOMATON_INSET := 0.17
const AUTOMATON_SIDE := 0.66
const AUTOMATON_CHAMFER := 0.14
## How high the automaton lifts between two cells, in cells, and how far the goal pad rises when
## the automaton stands on it.
const LIFT := 0.14
const GOAL_RISE := 0.12
## How high a shut door stands above the floor, in cells.
const GOAL_RISE_SECONDS := 0.2
## A quarter turn of the wedge takes this long.
const PIVOT_SECONDS := 0.1

var _view: BoardProjection
var _floor: BoardFloorLayer
## The direction the wedge is drawn in (radians), turning toward the facing; and the goal pad's
## rise, 0 to 1.
var _wedge_angle := 0.0
var _rise := 0.0


func _init() -> void:
	_floor = BoardFloorLayer.new(self)
	add_child(_floor)
	resized.connect(_on_resized)


func _ready() -> void:
	# Frames run only while something moves (see _on_moved); Godot would otherwise run them always.
	set_process(false)


## How high the automaton is lifted at a point of its move between two cells: 0 on a cell, the
## most halfway between. Pure, so it can be tested.
static func lift_at(position: Vector2) -> float:
	var along := maxf(position.x - floorf(position.x), position.y - floorf(position.y))
	return LIFT * sin(PI * along)


## The facing as an angle on the board (east is 0, south is a quarter turn).
static func angle_of(direction: String) -> float:
	var delta: Array = ContractLimits.DIRECTION_DELTAS[direction]
	return Vector2(float(delta[0]), float(delta[1])).angle()


## The height of the goal pad now, with the rise it has reached.
func goal_height() -> float:
	return BoardProjection.Z_GOAL + GOAL_RISE * _rise


func _on_goal() -> bool:
	if level.is_empty() or not level["goal"].has("position"):
		return false
	var goal: Array = level["goal"]["position"]
	return roundi(automaton.x) == int(goal[0]) and roundi(automaton.y) == int(goal[1])


func _on_moved() -> void:
	# Frames are needed only while something is turning, rising, or moving.
	set_process(true)


func set_level(level_data: Dictionary) -> void:
	super.set_level(level_data)
	# A new level starts settled: no pivot, no rise.
	_wedge_angle = angle_of(facing)
	_rise = 1.0 if _on_goal() else 0.0


func _process(delta: float) -> void:
	var target := angle_of(facing)
	if not is_equal_approx(_wedge_angle, target):
		_wedge_angle = (
			rotate_toward(_wedge_angle, target, delta * (PI / 2.0) / PIVOT_SECONDS)
			if UiLook.animate
			else target
		)
	var wanted := 1.0 if _on_goal() else 0.0
	if _rise != wanted:
		_rise = (
			move_toward(_rise, wanted, delta / GOAL_RISE_SECONDS) if UiLook.animate else wanted
		)
		_floor.queue_redraw()
	queue_redraw()
	if is_equal_approx(_wedge_angle, target) and _rise == wanted:
		set_process(false)


## The projection for the current level and size, rebuilt only when either changes.
func projection() -> BoardProjection:
	var board: Dictionary = level["board"]
	var cols := int(board["width"])
	var rows := int(board["height"])
	if _view == null or _view.cols != cols or _view.rows != rows or _view.box() != size:
		_view = BoardProjection.new(cols, rows, size)
	return _view


func show_state(
	position: Array,
	direction: String,
	passed: Array[Vector2i],
	blocked: Variant,
	marks: Dictionary = {},
	walked: Array[Vector2i] = []
) -> void:
	super.show_state(position, direction, passed, blocked, marks, walked)
	_floor.queue_redraw()


func _on_resized() -> void:
	_floor.queue_redraw()
	queue_redraw()


func _draw() -> void:
	if level.is_empty():
		return
	var view := projection()
	var at := automaton + nudge
	_draw_automaton_shadow(view, at)
	var items: Array[Dictionary] = []
	_add_floor_pieces(view, items)
	for wall: Array in level["board"]["walls"]:
		var point := Vector2i(int(wall[0]), int(wall[1]))
		items.append({"depth": view.depth(point.x + 0.5, point.y + 0.5), "wall": point})
	items.append({"depth": view.depth(at.x + 0.5, at.y + 0.5), "wall": null})
	for guard in GuardDraw.positions(level, guard_time):
		items.append(
			{"depth": view.depth(guard.x + 0.5, guard.y + 0.5) + 0.01, "wall": null, "guard": guard}
		)
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["depth"] < b["depth"])
	for item in items:
		if item.has("door"):
			DepthBlocks.door(self, view, level, int(item["door"]))
		elif item.has("gate"):
			DepthBlocks.gate(self, view, level, int(item["gate"]))
		elif item.has("guard"):
			_draw_guard_block(view, item["guard"])
		elif item["wall"] == null:
			_draw_automaton_block(view, at)
		else:
			_draw_wall_block(view, item["wall"], hit_wall != null and hit_wall == item["wall"])


## Draws what lies on the floor (keys, open doors, crates and docks, switches, open gates) and adds
## the shut doors and gates, which stand up, to `items` for the depth sort.
func _add_floor_pieces(view: BoardProjection, items: Array[Dictionary]) -> void:
	var flat := func(unit: Vector2) -> Vector2:
		return view.project(unit.x, unit.y, BoardProjection.Z_FLOOR)
	if level.has("ice") or level.has("belts"):
		FloorDraw.draw(self, level, flat, DepthPalette.WALL_HATCH, DepthPalette.INK)
	if level.has("teleports"):
		TeleportDraw.draw(self, level, flat, DepthPalette.INK)
	if level.has("locks"):
		var open_doors := _draw_floor_locks(view)
		var locks: Array = level["locks"]
		for i in locks.size():
			if not open_doors.has(i):
				var door := LockDraw.cell_of(locks[i], "door")
				items.append(
					{"depth": view.depth(door.x + 0.5, door.y + 0.5), "wall": null, "door": i}
				)
	if level.has("deliveries"):
		ItemDraw.draw_floor(self, level, route, flat, DepthPalette.FLOOR, DepthPalette.INK)
	if level.has("switches"):
		SwitchDraw.draw_switches(self, level, route, flat, DepthPalette.INK)
		var open: Dictionary = SwitchDraw.state(level, route)["open"]
		var colors := {"block": DepthPalette.INK, "bar": DepthPalette.ON_INK}
		var pairs: Array = level["switches"]
		for i in pairs.size():
			if open.has(i):
				SwitchDraw.draw_gate(self, level, i, true, flat, false, colors)
			else:
				var gate := LockDraw.cell_of(pairs[i], "gate")
				items.append(
					{"depth": view.depth(gate.x + 0.5, gate.y + 0.5), "wall": null, "gate": i}
				)


func _draw_wall_block(view: BoardProjection, point: Vector2i, hit: bool) -> void:
	var colors := {
		"top": DepthPalette.WALL,
		"front": DepthPalette.WALL_FRONT,
		"side": DepthPalette.WALL_SIDE,
		"edge": DepthPalette.WALL_EDGE
	}
	var z := BoardProjection.Z_WALL
	DepthKit.prism(
		self, view, BoardFloorLayer.footprint(point.x, point.y, WALL_INSET), 0.0, z, colors
	)
	# Hatch lines run corner to corner of the top face; each is clipped to the cell by its ends.
	var color := DepthPalette.SIGNAL if hit else DepthPalette.WALL_HATCH
	var width := (0.17 if hit else 0.1) * view.cell_scale
	var c := 0.1
	while c < 1.95:
		var start := maxf(0.0, c - 1.0)
		var finish := minf(c, 1.0)
		var a := view.project(point.x + start, point.y + c - start, z)
		var b := view.project(point.x + finish, point.y + c - finish, z)
		draw_line(a, b, color, width)
		c += 0.34 if hit else 0.28


## Keys and open doors lie on the floor; the lock indexes of the open doors are returned.
func _draw_floor_locks(view: BoardProjection) -> Dictionary:
	var place := func(unit: Vector2) -> Vector2:
		return view.project(unit.x, unit.y, BoardProjection.Z_FLOOR)
	var taken := LockDraw.held(level, route)
	LockDraw.draw_keys(self, level, route, place, DepthPalette.FLOOR)
	for i in taken:
		LockDraw.draw_door(self, level, i, true, place, false)
	return taken


func _draw_guard_block(view: BoardProjection, guard: Vector2) -> void:
	var caught := GuardDraw.on_cell(guard, hit_wall)
	var center := guard + Vector2(0.5, 0.5)
	var colors := {
		"top": DepthPalette.SIGNAL if caught else DepthPalette.INK,
		"front": DepthPalette.INK_FRONT,
		"side": DepthPalette.INK_SIDE,
		"edge": DepthPalette.INK_EDGE
	}
	var shadow := PackedVector2Array()
	for corner in GuardDraw.diamond(center + BoardFloorLayer.SHADOW_OFFSET, GuardDraw.DIAMOND):
		shadow.append(view.project(corner.x, corner.y, BoardProjection.Z_FLOOR))
	DepthKit.soft_shadow(self, shadow, Vector2.ZERO, 0.12 * view.cell_scale, 0.42, 6)
	var top := DepthKit.prism(
		self,
		view,
		GuardDraw.diamond(center, GuardDraw.DIAMOND),
		BoardProjection.Z_FLOOR,
		BoardProjection.Z_FLOOR + BoardProjection.Z_AUTOMATON,
		colors
	)
	var face := DepthPalette.ON_SIGNAL if caught else DepthPalette.ON_INK
	var middle := Vector2.ZERO
	for point in top:
		middle += point / float(top.size())
	draw_circle(middle, GuardDraw.DIAMOND * view.cell_scale * 0.42, face)
	draw_circle(
		middle,
		GuardDraw.DIAMOND * view.cell_scale * 0.2,
		DepthPalette.SIGNAL if not caught else DepthPalette.ON_INK
	)


func _draw_automaton_shadow(view: BoardProjection, at: Vector2) -> void:
	var shadow := PackedVector2Array()
	for corner in BoardFloorLayer.footprint(
		at.x + AUTOMATON_INSET, at.y + AUTOMATON_INSET, 0.0, AUTOMATON_SIDE
	):
		var moved := corner + BoardFloorLayer.SHADOW_OFFSET
		shadow.append(view.project(moved.x, moved.y, BoardProjection.Z_FLOOR))
	DepthKit.soft_shadow(self, shadow, Vector2.ZERO, 0.12 * view.cell_scale, 0.42, 6)


func _draw_automaton_block(view: BoardProjection, at: Vector2) -> void:
	# It stands on the pad (which may be rising) and lifts a little between two cells.
	var base := (goal_height() if _on_goal() else BoardProjection.Z_FLOOR) + lift_at(automaton)
	var low := AUTOMATON_INSET
	var high := AUTOMATON_INSET + AUTOMATON_SIDE
	var body := PackedVector2Array(
		[
			Vector2(at.x + low, at.y + low),
			Vector2(at.x + high - AUTOMATON_CHAMFER, at.y + low),
			Vector2(at.x + high, at.y + low + AUTOMATON_CHAMFER),
			Vector2(at.x + high, at.y + high),
			Vector2(at.x + low, at.y + high),
		]
	)
	var top := base + BoardProjection.Z_AUTOMATON
	var colors := {
		"top": DepthPalette.INK,
		"front": DepthPalette.INK_FRONT,
		"side": DepthPalette.INK_SIDE,
		"edge": DepthPalette.INK_EDGE
	}
	DepthKit.prism(self, view, body, base, top, colors)
	var direction := Vector2.from_angle(_wedge_angle)
	var side := Vector2(-direction.y, direction.x)
	var center := Vector2(at.x + 0.5, at.y + 0.5)
	var wedge := PackedVector2Array()
	for point: Vector2 in [
		center + direction * 0.27,
		center - direction * 0.1 + side * 0.2,
		center - direction * 0.1 - side * 0.2
	]:
		wedge.append(view.project(point.x, point.y, top + 0.003))
	draw_colored_polygon(wedge, DepthPalette.SIGNAL)
	if level.has("deliveries"):
		var carried := func(unit: Vector2) -> Vector2:
			return view.project(unit.x, unit.y, top + 0.003)
		var crate := {"edge": DepthPalette.ON_INK, "fill": DepthPalette.SIGNAL}
		ItemDraw.draw_carried(self, level, route, carried, at, crate)
