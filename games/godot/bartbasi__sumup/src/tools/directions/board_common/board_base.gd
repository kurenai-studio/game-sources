extends Control
## Shared board machinery for the three Phase 1 directions: board state, the
## grid geometry, the chain path, the target pulse and the effect players.
## Each direction's board_view.gd extends this, draws everything in _draw()
## through its tile painter, and overrides the frame functions that shape its
## effects. No drawing and no look lives here.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")
const TileFx: GDScript = preload("res://tools/directions/board_common/tile_fx.gd")
const MotionMath: GDScript = preload("res://tools/directions/board_common/motion_math.gd")

const NO_CELL: Vector2i = Vector2i(-1, -1)
const CELL_COUNT: int = MockState.COLUMNS * MockState.ROWS

var tokens: DirectionTokens = null

# Board state. Cells are stored flat: index = row * COLUMNS + column.
var _cells: PackedInt32Array = PackedInt32Array()
var _fx: Array[TileFx] = []
## Position of each cell in the chain, or -1.
var _chain_index: PackedInt32Array = PackedInt32Array()
## How far each chained cell has joined the chain, 0 to 1.
var _chain_amount: PackedFloat32Array = PackedFloat32Array()
var _chain: Array[Vector2i] = []
## Distance along the chain from its first cell, in cell units, per chain cell.
var _chain_distance: PackedFloat32Array = PackedFloat32Array()
var _drag: Vector2 = Vector2.ZERO
var _drag_active: bool = false
## While a merge travels, the line starts this far along the chain.
var _trail: float = 0.0
var _line_hidden: bool = false
var _preview: int = 0
var _target: Vector2i = NO_CELL
var _targeting: bool = false
var _pulse_time: float = 0.0
var _tweens: Array[Tween] = []

# Geometry. _reference holds the pitch, tile side and border at the composed
# width; everything else is that scaled to fit the current rect.
var _reference: Vector3 = Vector3.ONE
var _reference_size: Vector2 = Vector2.ONE
var _scale: float = 1.0
var _pitch: float = 1.0
var _side: float = 1.0
var _board_rect: Rect2 = Rect2()
var _grid_origin: Vector2 = Vector2.ZERO

## Chain line points in px, filled by _build_line(); only the first
## _line_count are valid.
var _line_points: PackedVector2Array = PackedVector2Array()
var _line_count: int = 0


func setup(tile_tokens: DirectionTokens) -> void:
	tokens = tile_tokens
	_reference = _reference_metrics()
	var border: float = _reference.z * 2.0
	_reference_size = Vector2(MockState.COLUMNS * _reference.x + border, MockState.ROWS * _reference.x + border)
	_cells.resize(CELL_COUNT)
	_cells.fill(0)
	_chain_index.resize(CELL_COUNT)
	_chain_index.fill(-1)
	_chain_amount.resize(CELL_COUNT)
	_chain_amount.fill(0.0)
	_fx.clear()
	for _i: int in CELL_COUNT:
		_fx.append(TileFx.new())
	_setup_painters()
	_relayout()
	set_process(false)


## MockState.ROWS rows of MockState.COLUMNS values, top row first. 0 is an empty cell.
func set_board(values: Array[PackedInt32Array]) -> void:
	_kill_effects()
	_cells.fill(0)
	for row: int in mini(values.size(), MockState.ROWS):
		var line: PackedInt32Array = values[row]
		for column: int in mini(line.size(), MockState.COLUMNS):
			_cells[row * MockState.COLUMNS + column] = line[column]
	for fx: TileFx in _fx:
		fx.reset()
	queue_redraw()


## Cells as Vector2i(column, row) in drag order. drag_point is in cell units,
## Vector2(0, 0) at the top left of the grid. An empty array clears the chain.
func set_chain(cells: Array[Vector2i], drag_point: Vector2) -> void:
	_assign_chain(cells)
	for i: int in _chain.size():
		_chain_amount[_index(_chain[i])] = 1.0
	_drag = drag_point
	_drag_active = not _chain.is_empty()
	queue_redraw()


## The live result while dragging. 0 hides it.
func set_preview(value: int) -> void:
	_preview = value
	queue_redraw()


## The tile under the finger in targeting mode. Vector2i(-1, -1) clears it.
func set_target(cell: Vector2i) -> void:
	_target = cell if _is_cell(cell) else NO_CELL
	queue_redraw()


## Targeting mode on or off. Starts or stops the target pulse.
func set_targeting(active: bool) -> void:
	_targeting = active
	_pulse_time = 0.0
	set_process(active and tokens.duration("target_pulse") > 0.0)
	queue_redraw()


## Local rect of a cell's tile, for overlays.
func cell_rect(cell: Vector2i) -> Rect2:
	var center: Vector2 = cell_center(cell)
	return Rect2(center - Vector2(_side, _side) * 0.5, Vector2(_side, _side))


## Height this board needs when it is given this width, tray included.
func preferred_height(width: float) -> float:
	if tokens == null:
		push_error("preferred_height() needs setup() first")
		return 0.0
	return _reference_size.y * width / _reference_size.x


## Center of a cell in local px.
func cell_center(cell: Vector2i) -> Vector2:
	return _grid_origin + (Vector2(cell) + Vector2(0.5, 0.5)) * _pitch


## A point in cell units as local px.
func cell_point(point: Vector2) -> Vector2:
	return _grid_origin + point * _pitch


## Tile side in px at the current size.
func tile_side() -> float:
	return _side


# Effect frames. Each direction overrides these. They set fx to the look at a
# linear progress from 0 to 1 through the effect, so the review sheet can
# freeze any moment and the players below can run them live.

## A new tile appearing.
func spawn_frame(fx: TileFx, progress: float) -> void:
	fx.reset()
	fx.scale = Vector2.ONE * progress


## The merge result arriving on the last chain cell.
func pop_frame(fx: TileFx, progress: float) -> void:
	fx.reset()
	fx.scale = Vector2.ONE * progress


## A tile falling drop px into its cell.
func fall_frame(fx: TileFx, progress: float, drop: float) -> void:
	fx.reset()
	fx.offset.y = -drop * (1.0 - progress)


# Effect players. Each returns its length in seconds.

## Spawns values into cells, each with the spawn effect and the stagger.
func play_spawn(cells: Array[Vector2i], values: PackedInt32Array) -> float:
	var length: float = tokens.duration("spawn")
	var stagger: float = MotionMath.extra(tokens, "spawn", "stagger")
	var tween: Tween = _new_tween()
	tween.set_parallel(true)
	for i: int in cells.size():
		var index: int = _index(cells[i])
		_cells[index] = values[i]
		spawn_frame(_fx[index], 0.0)
		tween.tween_method(_spawn_step.bind(index), 0.0, 1.0, length).set_delay(stagger * i)
	queue_redraw()
	return length + stagger * maxi(0, cells.size() - 1)


## Grows the chain to cells, the new cells joining with chain_add while the
## drag point moves to drag_point.
func play_chain_to(cells: Array[Vector2i], drag_point: Vector2) -> float:
	var joined: PackedInt32Array = PackedInt32Array()
	for cell: Vector2i in cells:
		if _chain_index[_index(cell)] < 0:
			joined.append(_index(cell))
	var from_drag: Vector2 = _drag if _drag_active else drag_point
	_assign_chain(cells)
	for i: int in _chain.size():
		var index: int = _index(_chain[i])
		_chain_amount[index] = 0.0 if joined.has(index) else 1.0
	_drag_active = not _chain.is_empty()
	var length: float = tokens.duration("chain_add")
	var tween: Tween = _new_tween()
	tween.tween_method(_chain_step.bind(joined, from_drag, drag_point), 0.0, 1.0, length)
	return length


## Commits the chain: the chain tiles travel into the last one, the other
## chain cells clear, and the last cell pops to result.
func play_merge(result: int) -> float:
	if _chain.size() < 2:
		return 0.0
	var cells: Array[Vector2i] = _chain.duplicate()
	var last: int = _index(cells.back())
	var starts: PackedFloat32Array = _chain_distance.duplicate()
	var centers: PackedVector2Array = PackedVector2Array()
	for cell: Vector2i in cells:
		centers.append(Vector2(cell) + Vector2(0.5, 0.5))
	for cell: Vector2i in cells:
		_fx[_index(cell)].layer = TileFx.LAYER_MOVING
	_fx[last].layer = TileFx.LAYER_TOP
	_drag_active = false
	_preview = 0
	_line_hidden = _line_cuts_on_merge()
	var travel: float = tokens.duration("merge_travel")
	var pop: float = tokens.duration("merge_pop")
	var tween: Tween = _new_tween()
	tween.tween_method(_travel_step.bind(cells, centers, starts), 0.0, 1.0, travel)
	tween.tween_callback(_finish_travel.bind(cells, result))
	tween.tween_method(_pop_step.bind(last), 0.0, 1.0, pop)
	tween.tween_callback(_fx[last].reset)
	queue_redraw()
	return travel + pop


## Moves the tile in each from cell down into the matching to cell. From
## cells that no tile moves into become empty.
func play_fall(from_cells: Array[Vector2i], to_cells: Array[Vector2i]) -> float:
	var moved: PackedInt32Array = PackedInt32Array()
	var drops: PackedFloat32Array = PackedFloat32Array()
	var carried: PackedInt32Array = PackedInt32Array()
	for cell: Vector2i in from_cells:
		carried.append(_cells[_index(cell)])
	for cell: Vector2i in from_cells:
		_cells[_index(cell)] = 0
	for i: int in to_cells.size():
		var index: int = _index(to_cells[i])
		_cells[index] = carried[i]
		moved.append(index)
		drops.append(float(to_cells[i].y - from_cells[i].y) * _pitch)
		fall_frame(_fx[index], 0.0, drops[i])
		_fx[index].layer = TileFx.LAYER_MOVING
	var length: float = tokens.duration("fall")
	var tween: Tween = _new_tween()
	tween.tween_method(_fall_step.bind(moved, drops), 0.0, 1.0, length)
	tween.tween_callback(_reset_fx.bind(moved))
	queue_redraw()
	return length


## Value in a cell, 0 when empty.
func value_at(cell: Vector2i) -> int:
	return _cells[_index(cell)]


# Hooks for the directions.

## Pitch, tile side and border at the composed width. See the painters'
## reference_metrics().
func _reference_metrics() -> Vector3:
	return Vector3(1.0, 1.0, 0.0)


func _setup_painters() -> void:
	pass


## Called after the geometry changes, to resize painters.
func _on_layout() -> void:
	pass


## Whether travelling chain tiles follow the chain path (true) or slide
## straight into the last tile (false).
func _travel_follows_path() -> bool:
	return true


## Whether the chain line runs on from the last chain cell to the finger.
func _line_has_tail() -> bool:
	return true


## Whether the chain line disappears the moment a merge starts (true) or
## pulls in behind the travelling tiles (false).
func _line_cuts_on_merge() -> bool:
	return false


# Helpers for drawing.

func _index(cell: Vector2i) -> int:
	return cell.y * MockState.COLUMNS + cell.x


func _cell_of(index: int) -> Vector2i:
	return Vector2i(index % MockState.COLUMNS, index / MockState.COLUMNS)


func _is_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < MockState.COLUMNS and cell.y < MockState.ROWS


## Center of a cell by flat index, in local px.
func _center_of(index: int) -> Vector2:
	return cell_center(_cell_of(index))


## Fills _line_points with the chain line in px, from the trail start through
## the chain centers to the drag point (when the direction draws a tail).
## Sets _line_count.
func _build_line() -> void:
	_line_count = 0
	if _chain.is_empty() or _line_hidden:
		return
	var needed: int = _chain.size() + 2
	if _line_points.size() < needed:
		_line_points.resize(needed)
	if _trail > 0.0:
		_line_points[0] = cell_point(_path_point(_trail))
		_line_count = 1
	for i: int in _chain.size():
		if _chain_distance[i] > _trail or (_trail <= 0.0):
			_line_points[_line_count] = cell_center(_chain[i])
			_line_count += 1
	if _drag_active and _line_has_tail():
		_line_points[_line_count] = cell_point(_drag)
		_line_count += 1


## Index into _chain of the cell each line point belongs to, for colored
## lines. The trail start belongs to the first chain cell it has not passed.
func _line_owner(point_index: int) -> int:
	var skipped: int = 0
	if _trail > 0.0:
		for i: int in _chain.size():
			if _chain_distance[i] <= _trail:
				skipped += 1
		if point_index == 0:
			return mini(skipped, _chain.size() - 1)
		return mini(skipped + point_index - 1, _chain.size() - 1)
	return mini(point_index, _chain.size() - 1)


## A point along the chain path, in cell units, distance cell units from the
## first chain cell. Before the start it carries on backwards along the
## first segment, so back easing can pull tiles back a little.
func _path_point(distance: float) -> Vector2:
	var first: Vector2 = Vector2(_chain[0]) + Vector2(0.5, 0.5)
	if _chain.size() == 1:
		return first
	if distance <= 0.0:
		var second: Vector2 = Vector2(_chain[1]) + Vector2(0.5, 0.5)
		return first + (second - first).normalized() * distance
	for i: int in range(1, _chain.size()):
		if distance <= _chain_distance[i]:
			var from: Vector2 = Vector2(_chain[i - 1]) + Vector2(0.5, 0.5)
			var to: Vector2 = Vector2(_chain[i]) + Vector2(0.5, 0.5)
			var span: float = _chain_distance[i] - _chain_distance[i - 1]
			return from.lerp(to, (distance - _chain_distance[i - 1]) / maxf(span, 0.0001))
	return Vector2(_chain.back()) + Vector2(0.5, 0.5)


# Internals.

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_READY:
		_relayout()


func _process(delta: float) -> void:
	# Godot turns processing on when the node becomes ready, so switch it
	# back off here when there is no pulse to run.
	if not _targeting or tokens == null or tokens.duration("target_pulse") <= 0.0:
		set_process(false)
		return
	_pulse_time += delta
	queue_redraw()


func _relayout() -> void:
	if tokens == null:
		return
	var fit: float = minf(size.x / _reference_size.x, size.y / _reference_size.y)
	if fit <= 0.0:
		return
	_scale = fit
	_pitch = _reference.x * fit
	_side = _reference.y * fit
	var board_size: Vector2 = _reference_size * fit
	_board_rect = Rect2((size - board_size) * 0.5, board_size)
	_grid_origin = _board_rect.position + Vector2(_reference.z, _reference.z) * fit
	_on_layout()
	queue_redraw()


func _assign_chain(cells: Array[Vector2i]) -> void:
	for cell: Vector2i in _chain:
		_chain_index[_index(cell)] = -1
		_chain_amount[_index(cell)] = 0.0
	_chain = cells.duplicate()
	_chain_distance.resize(_chain.size())
	var total: float = 0.0
	for i: int in _chain.size():
		if i > 0:
			total += Vector2(_chain[i]).distance_to(Vector2(_chain[i - 1]))
		_chain_distance[i] = total
		_chain_index[_index(_chain[i])] = i
	_trail = 0.0
	_line_hidden = false


func _new_tween() -> Tween:
	for i: int in range(_tweens.size() - 1, -1, -1):
		if not _tweens[i].is_valid():
			_tweens.remove_at(i)
	var tween: Tween = create_tween()
	_tweens.append(tween)
	return tween


func _kill_effects() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()


func _spawn_step(progress: float, index: int) -> void:
	spawn_frame(_fx[index], progress)
	queue_redraw()


func _chain_step(progress: float, joined: PackedInt32Array, from_drag: Vector2, to_drag: Vector2) -> void:
	var amount: float = MotionMath.eased(tokens, "chain_add", progress)
	for index: int in joined:
		if _chain_index[index] >= 0:
			_chain_amount[index] = amount
	_drag = from_drag.lerp(to_drag, amount)
	queue_redraw()


func _travel_step(progress: float, cells: Array[Vector2i], centers: PackedVector2Array, starts: PackedFloat32Array) -> void:
	var amount: float = MotionMath.eased(tokens, "merge_travel", progress)
	var last: int = cells.size() - 1
	var end: float = starts[last]
	for i: int in last:
		var point: Vector2 = Vector2.ZERO
		if _travel_follows_path():
			point = _path_point(lerpf(starts[i], end, amount))
		else:
			point = centers[i].lerp(centers[last], amount)
		_fx[_index(cells[i])].offset = (point - centers[i]) * _pitch
	_trail = clampf(end * amount, 0.0, end)
	queue_redraw()


func _finish_travel(cells: Array[Vector2i], result: int) -> void:
	var last: int = _index(cells.back())
	for cell: Vector2i in cells:
		var index: int = _index(cell)
		_fx[index].reset()
		if index != last:
			_cells[index] = 0
	_cells[last] = result
	var no_chain: Array[Vector2i] = []
	_assign_chain(no_chain)
	_drag_active = false
	pop_frame(_fx[last], 0.0)
	_fx[last].layer = TileFx.LAYER_TOP
	queue_redraw()


func _pop_step(progress: float, index: int) -> void:
	pop_frame(_fx[index], progress)
	_fx[index].layer = TileFx.LAYER_TOP
	queue_redraw()


func _fall_step(progress: float, moved: PackedInt32Array, drops: PackedFloat32Array) -> void:
	for i: int in moved.size():
		fall_frame(_fx[moved[i]], progress, drops[i])
		_fx[moved[i]].layer = TileFx.LAYER_MOVING
	queue_redraw()


func _reset_fx(moved: PackedInt32Array) -> void:
	for index: int in moved:
		_fx[index].reset()
	queue_redraw()
