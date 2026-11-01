extends SkinBoardView
## Shared machinery of the three skins' board views: board state, geometry,
## the chain line path, the highlights, the effect players and the drawing
## pipeline. Each skin's board view extends this, names its tile painter,
## draws its tiles and layers and shapes its effects in the frame functions.
## No look lives here.
##
## Every tile has its own canvas items: a tile item, and an under item for
## what must sit below the chain line (Nova's glow, Slate's fill and frames).
## Effects only move, scale, turn and fade those items through their
## transform and modulate; a tile is drawn again only when its own look
## changes (value, chained, joinable, press, selection, flash, glow). So a
## falling or spawning board costs a few transform updates a frame, not a
## redraw.
##
## Draw order, lowest first:
##   back    this Control: tray, empty cells (and Nova's clear sparks)
##   under   the tiles' under items
##   line    the chain line
##   tiles   the tiles' items, resting tiles first, moving tiles over them
##   top     the preview, the selection marks, the candy bursts
## The back, line and top layers redraw only when what they show changed.
##
## Effects run on the view's own clock, advanced in _process. Each frame
## every TileFx is reset and each running effect adds its part, so effects on
## the same tile combine. Review scenes and tests freeze the clock with
## effects_paused and step it with advance_effects().

const TileFx: GDScript = preload("res://src/skins/common/tile_fx.gd")
const BoardEffect: GDScript = preload("res://src/skins/common/board_effect.gd")
const CellFade: GDScript = preload("res://src/skins/common/cell_fade.gd")
const MotionMath: GDScript = preload("res://src/skins/common/motion_math.gd")
const TilePainter: GDScript = preload("res://src/skins/common/tile_painter.gd")

const LAYER_BACK: int = 0
const LAYER_LINE: int = 1
const LAYER_TOP: int = 2
const NO_DRAG: Vector2 = Vector2(-1.0, -1.0)
const HALF_CELL: Vector2 = Vector2(0.5, 0.5)

## Draw order of tile items: new tiles still growing in (under everything,
## so a new tile appears from behind a tile falling away, DESIGN_SYSTEM.md
## 3.6), resting tiles, tiles leaving (cleared or gone in a Shuffle or Undo),
## moving tiles, chain tiles travelling into a merge, the tile they travel
## into, the tile a merge lands on, Swap's selected tile.
const RANK_SPAWN: int = 0
const RANK_REST: int = 1
const RANK_LEAVING: int = 2
const RANK_MOVING: int = 3
const RANK_TRAVEL: int = 4
const RANK_HOLD: int = 5
const RANK_TOP: int = 6
const RANK_SELECTED: int = 7
const RANK_STEP: int = 4096
## An item's look key: label index, chained, joinable, press, selection,
## flash, glow, moving, layout epoch.
const KEY_SIZE: int = 9

## Freezes the effect clock. Review scenes and tests set it and step the
## clock with advance_effects().
var effects_paused: bool = false

var skin: SkinData = null
var columns: int = 0
var rows: int = 0
var cell_count: int = 0

## The board tile painter, made by the skin in _make_painter().
var _painter: TilePainter = null
var _cells: PackedInt64Array = PackedInt64Array()
## Label index of each cell's value, -1 for an empty cell.
var _labels: PackedInt32Array = PackedInt32Array()
var _fx: Array[TileFx] = []
var _effects: Array[BoardEffect] = []
var _clock: float = 0.0

var _chain: Array[Vector2i] = []
var _chain_fade: CellFade = null
var _join_fade: CellFade = null
var _press_fade: CellFade = null
var _select_fade: CellFade = null
## Scratch flags, one per cell.
var _mark: PackedByteArray = PackedByteArray()
var _drag: Vector2 = NO_DRAG
var _preview: int = 0
var _targeting: StringName = &""
var _pressed: Vector2i = NO_CELL
var _selected: Vector2i = NO_CELL
var _selected_since: float = 0.0
var _pulse_period: float = 0.0

# The chain line: its cells, their values, and each cell's distance along the
# path from the first cell, in cell units. It is the live chain, or the chain
# being merged while it travels.
var _line_cells: Array[Vector2i] = []
var _line_values: PackedInt64Array = PackedInt64Array()
var _line_distance: PackedFloat32Array = PackedFloat32Array()
## Line points in px and the line cell each belongs to, filled by
## _build_line_points(); only the first _line_count are valid.
var _line_points: PackedVector2Array = PackedVector2Array()
var _line_owner: PackedInt32Array = PackedInt32Array()
var _line_count: int = 0
## While a merge travels, the line starts this far along the path.
var _trail: float = 0.0
var _travel_start: float = 0.0
## Length of the merge travel the line follows; below 0 when none runs.
var _travel_length: float = -1.0

# Geometry.
var _side: float = 0.0
var _gap: float = 0.0
var _pad: float = 0.0
var _pitch: float = 0.0
var _unit: float = 1.0
var _origin: Vector2 = Vector2.ZERO
var _board_rect: Rect2 = Rect2()
var _has_layout: bool = false
## Each cell's center in local px.
var _centers: PackedVector2Array = PackedVector2Array()
## The size the geometry was worked out for. Geometry is worked out again
## whenever the size differs, so it is right even before a resize
## notification arrives.
var _layout_size: Vector2 = -Vector2.ONE

# Layers and tile items.
var _under_layer: Control = null
var _line_layer: Control = null
var _tiles_layer: Control = null
var _top_layer: Control = null
## Items per tile: the first cell_count are the cells, the rest a pool for
## ghost tiles.
var _tile_items: Array[RID] = []
var _under_items: Array[RID] = []
var _item_keys: PackedFloat32Array = PackedFloat32Array()
var _item_xforms: Array[Transform2D] = []
var _item_alpha: PackedFloat32Array = PackedFloat32Array()
var _item_order: PackedInt32Array = PackedInt32Array()
var _item_shown: PackedByteArray = PackedByteArray()
## 1 when an item was last brought up to date as a plain resting tile, so
## the next sync can skip it while nothing about it changes.
var _item_rest: PackedByteArray = PackedByteArray()
## Bumped when the layout changes, so every tile is drawn again.
var _epoch: float = 0.0
## Which cells show as empty on the back layer, as last drawn.
var _empty_mask: PackedByteArray = PackedByteArray()


func setup(p_skin: SkinData, p_columns: int, p_rows: int) -> void:
	if p_skin == null or p_columns < 1 or p_rows < 1:
		push_error("setup() needs a skin and at least one column and row")
		return
	skin = p_skin
	columns = p_columns
	rows = p_rows
	cell_count = columns * rows
	_cells.resize(cell_count)
	_cells.fill(0)
	_labels.resize(cell_count)
	_labels.fill(-1)
	_centers.resize(cell_count)
	_fx.clear()
	for _i: int in cell_count:
		_fx.append(TileFx.new())
	_effects.clear()
	_chain.clear()
	_chain_fade = CellFade.new()
	_chain_fade.setup(skin, cell_count, &"chain_add", &"chain_remove")
	_join_fade = CellFade.new()
	_join_fade.setup(skin, cell_count, &"joinable_in", &"joinable_in")
	_press_fade = CellFade.new()
	_press_fade.setup(skin, cell_count, &"press", &"press")
	_select_fade = CellFade.new()
	_select_fade.setup(skin, cell_count, &"press", &"press")
	_mark.resize(cell_count)
	_empty_mask.resize(cell_count)
	_empty_mask.fill(0)
	_line_points.resize(cell_count + 2)
	_line_owner.resize(cell_count + 2)
	_line_cells.clear()
	_line_values.clear()
	_line_distance.clear()
	_travel_length = -1.0
	_drag = NO_DRAG
	_preview = 0
	_targeting = &""
	_pressed = NO_CELL
	_selected = NO_CELL
	_pulse_period = skin.duration(&"target_pulse")
	_painter = _make_painter()
	_painter.setup(skin)
	_make_layers()
	_ensure_items(cell_count)
	_epoch += 1.0
	_setup_look()
	_layout_size = -Vector2.ONE
	_refresh_all()


func set_board(cells: PackedInt64Array) -> void:
	if not _check_setup("set_board"):
		return
	if cells.size() != cell_count:
		push_error("set_board() got %d cells, the board has %d" % [cells.size(), cell_count])
		return
	_cells = cells.duplicate()
	_relabel()
	_end_effects()
	_update_effects()
	_wake()
	_refresh_all()


func set_chain(chain: Array[Vector2i], drag_point: Vector2) -> void:
	if not _check_setup("set_chain"):
		return
	_drag = drag_point
	if _same_chain(chain):
		if _line_has_tail():
			_line_layer.queue_redraw()
		return
	_chain.clear()
	_mark.fill(0)
	for cell: Vector2i in chain:
		var index: int = _index_of(cell)
		if index >= 0 and _mark[index] == 0:
			_mark[index] = 1
			_chain.append(cell)
	for index: int in cell_count:
		var chained: bool = _mark[index] != 0
		_chain_fade.set_on(index, chained)
		if chained:
			# Tiles in the chain are never joinable (D-40).
			_join_fade.clear_cell_now(index)
	if _travel_length < 0.0:
		_set_line_from_chain()
	_wake()
	_refresh_all()


func set_preview(value: int) -> void:
	if not _check_setup("set_preview"):
		return
	var shown: int = value if value > 0 else 0
	if shown == _preview:
		return
	_preview = shown
	_top_layer.queue_redraw()


func set_joinable(cells: Array[Vector2i]) -> void:
	if not _check_setup("set_joinable"):
		return
	_mark.fill(0)
	for cell: Vector2i in cells:
		var index: int = _index_of(cell)
		if index >= 0:
			_mark[index] = 1
	for index: int in cell_count:
		_join_fade.set_on(index, _mark[index] != 0 and not _chain_fade.is_on(index))
	_wake()
	_refresh_items()


func set_targeting(booster_id: StringName) -> void:
	if not _check_setup("set_targeting"):
		return
	_targeting = booster_id
	if booster_id == &"":
		set_pressed_cell(NO_CELL)
		set_swap_selected(NO_CELL)


func set_pressed_cell(cell: Vector2i) -> void:
	if not _check_setup("set_pressed_cell"):
		return
	var target: Vector2i = cell if _index_of(cell) >= 0 else NO_CELL
	if target == _pressed:
		return
	if _pressed != NO_CELL:
		_press_fade.set_on(_index_of(_pressed), false)
	_pressed = target
	if target != NO_CELL:
		_press_fade.set_on(_index_of(target), true)
	_wake()
	_refresh_items()
	_top_layer.queue_redraw()


func set_swap_selected(cell: Vector2i) -> void:
	if not _check_setup("set_swap_selected"):
		return
	var target: Vector2i = cell if _index_of(cell) >= 0 else NO_CELL
	if target == _selected:
		return
	if _selected != NO_CELL:
		_select_fade.set_on(_index_of(_selected), false)
	_selected = target
	_selected_since = _clock
	if target != NO_CELL:
		_select_fade.set_on(_index_of(target), true)
	_wake()
	_refresh_items()
	_top_layer.queue_redraw()


func cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(cell_center(cell) - Vector2(_side, _side) * 0.5, Vector2(_side, _side))


func grid_origin() -> Vector2:
	_ensure_layout()
	return _origin


func cell_pitch() -> Vector2:
	_ensure_layout()
	return Vector2(_pitch, _pitch)


func preferred_height(width: float) -> float:
	if not _check_setup("preferred_height"):
		return 0.0
	var metrics: Vector3 = _painter.board_metrics(width, columns)
	if metrics.x <= 0.0:
		return 0.0
	return _extent(rows, metrics)


## Center of a cell in local px.
func cell_center(cell: Vector2i) -> Vector2:
	_ensure_layout()
	return _origin + (Vector2(cell) + HALF_CELL) * _pitch


## Tile side in px (Nova: the orb diameter).
func tile_side() -> float:
	_ensure_layout()
	return _side


## The board's own rect inside the view (Gumdrop: the tray).
func board_rect() -> Rect2:
	_ensure_layout()
	return _board_rect


func play_spawn(cells: Array[Vector2i], values: PackedInt64Array) -> float:
	if not _check_setup("play_spawn"):
		return 0.0
	if cells.size() != values.size():
		push_error("play_spawn() got %d cells and %d values" % [cells.size(), values.size()])
		return 0.0
	if cells.is_empty():
		return 0.0
	var length: float = skin.duration(&"spawn")
	var stagger: float = MotionMath.extra(skin, &"spawn", "stagger")
	for i: int in cells.size():
		var index: int = _index_of(cells[i])
		if index < 0:
			continue
		_put_cell(index, values[i])
		_drop_cell_effects(index)
		_add_cell_effect(BoardEffect.SPAWN, index, _clock + stagger * float(i), length, values[i])
	_started()
	return length + stagger * float(cells.size() - 1)


func play_merge(chain: Array[Vector2i], result_cell: Vector2i, result_value: int) -> float:
	if not _check_setup("play_merge"):
		return 0.0
	var travel: float = skin.duration(&"merge_travel")
	var pop: float = skin.duration(&"merge_pop")
	var result_index: int = _index_of(result_cell)
	var merging: Array[Vector2i] = []
	for cell: Vector2i in chain:
		if _index_of(cell) >= 0:
			merging.append(cell)
	# The line follows the merging chain into the result cell while it travels.
	_line_cells = merging.duplicate()
	if result_index >= 0 and (merging.is_empty() or merging.back() != result_cell):
		_line_cells.append(result_cell)
	_fill_line_values()
	var path_end: float = _line_distance[_line_distance.size() - 1] if not _line_distance.is_empty() else 0.0
	var target: Vector2 = Vector2(result_cell) + HALF_CELL
	# The chain tiles carry their chained look as ghosts, so the live chain,
	# the highlight and the preview go at once.
	_chain.clear()
	_chain_fade.clear_now()
	_join_fade.clear_now()
	_preview = 0
	_drag = NO_DRAG
	for i: int in merging.size():
		var index: int = _index_of(merging[i])
		var value: int = _cells[index]
		if value <= 0:
			continue
		var ghost: BoardEffect = _add_ghost(BoardEffect.TRAVEL, merging[i], value, travel)
		# A skin whose line cuts at the merge drops the chained marks with it.
		ghost.chain = 0.0 if _line_cuts_on_merge() else 1.0
		if index == result_index:
			ghost.kind = BoardEffect.HOLD
		else:
			ghost.offset = target
			ghost.path_from = _line_distance[i]
			ghost.path_to = path_end
			_put_cell(index, 0)
		_drop_cell_effects(index)
	if result_index >= 0:
		_put_cell(result_index, result_value)
		_add_cell_effect(BoardEffect.HIDE, result_index, _clock, travel, result_value)
		var pop_kind: int = BoardEffect.BLOOM if _pop_is_decor() else BoardEffect.POP
		_add_cell_effect(pop_kind, result_index, _clock + travel, pop, result_value)
	if _line_cuts_on_merge() or travel <= 0.0:
		_end_travel()
	else:
		_travel_start = _clock
		_travel_length = travel
		_trail = 0.0
	_started()
	return travel if _pop_is_decor() else travel + pop


func play_clear(cells: Array[Vector2i]) -> float:
	if not _check_setup("play_clear"):
		return 0.0
	var length: float = skin.duration(&"clear")
	var cleared: int = 0
	for cell: Vector2i in cells:
		var index: int = _index_of(cell)
		if index < 0 or _cells[index] <= 0:
			continue
		var ghost: BoardEffect = _add_ghost(BoardEffect.CLEAR, cell, _cells[index], length)
		_put_cell(index, 0)
		_drop_cell_effects(index)
		_clear_cell_looks(index)
		_on_clear_ghost(ghost)
		cleared += 1
	if cleared == 0:
		return 0.0
	_started()
	return length


func play_fall(from_cells: Array[Vector2i], to_cells: Array[Vector2i]) -> float:
	if not _check_setup("play_fall"):
		return 0.0
	if from_cells.size() != to_cells.size():
		push_error("play_fall() got %d from cells and %d to cells" % [from_cells.size(), to_cells.size()])
		return 0.0
	var moves: PackedInt32Array = PackedInt32Array()
	moves.resize(cell_count)
	moves.fill(-1)
	var carried: PackedInt64Array = PackedInt64Array()
	carried.resize(from_cells.size())
	for i: int in from_cells.size():
		var from: int = _index_of(from_cells[i])
		var to: int = _index_of(to_cells[i])
		if from < 0 or to < 0:
			continue
		carried[i] = _cells[from]
		moves[from] = to
	for i: int in from_cells.size():
		var from: int = _index_of(from_cells[i])
		if from >= 0 and moves[from] >= 0:
			_put_cell(from, 0)
	# Effects still running on a moving tile move with it.
	for effect: BoardEffect in _effects:
		if effect.on_cell() and moves[effect.index] >= 0:
			effect.index = moves[effect.index]
	var length: float = skin.duration(&"fall")
	var moved: int = 0
	for i: int in from_cells.size():
		var from: int = _index_of(from_cells[i])
		var to: int = _index_of(to_cells[i])
		if from < 0 or to < 0:
			continue
		_put_cell(to, carried[i])
		var effect: BoardEffect = _add_cell_effect(BoardEffect.FALL, to, _clock, length, carried[i])
		effect.offset = Vector2(from_cells[i] - to_cells[i])
		moved += 1
	if moved == 0:
		return 0.0
	_started()
	return length


func play_value_change(cell: Vector2i, value: int) -> float:
	if not _check_setup("play_value_change"):
		return 0.0
	var index: int = _index_of(cell)
	if index < 0:
		return 0.0
	var pop: float = skin.duration(&"merge_pop")
	_put_cell(index, value)
	_drop_cell_effects(index)
	var pop_kind: int = BoardEffect.BLOOM if _pop_is_decor() else BoardEffect.POP
	_add_cell_effect(pop_kind, index, _clock, pop, value)
	_started()
	return 0.0 if _pop_is_decor() else pop


func play_swap(a: Vector2i, b: Vector2i) -> float:
	if not _check_setup("play_swap"):
		return 0.0
	var first: int = _index_of(a)
	var second: int = _index_of(b)
	if first < 0 or second < 0 or first == second:
		return 0.0
	var length: float = skin.duration(_slide_motion())
	var value: int = _cells[first]
	_put_cell(first, _cells[second])
	_put_cell(second, value)
	_drop_cell_effects(first)
	_drop_cell_effects(second)
	_add_cell_effect(BoardEffect.SLIDE, first, _clock, length, _cells[first]).offset = Vector2(b - a)
	_add_cell_effect(BoardEffect.SLIDE, second, _clock, length, _cells[second]).offset = Vector2(a - b)
	_started()
	return length


## Shuffle and Undo. Tiles that keep their value stay. Every other new tile
## slides in from the nearest old tile of the same value that is free; a new
## value with no old tile to come from spawns in, and an old tile nothing
## takes leaves the way a cleared tile does, without its burst.
func play_rearrange(cells_after: PackedInt64Array) -> float:
	if not _check_setup("play_rearrange"):
		return 0.0
	if cells_after.size() != cell_count:
		push_error("play_rearrange() got %d cells, the board has %d" % [cells_after.size(), cell_count])
		return 0.0
	var old: PackedInt64Array = _cells
	_cells = cells_after.duplicate()
	_relabel()
	var taken: PackedByteArray = PackedByteArray()
	taken.resize(cell_count)
	for index: int in cell_count:
		taken[index] = 1 if old[index] == cells_after[index] else 0
	var longest: float = 0.0
	for index: int in cell_count:
		var value: int = cells_after[index]
		if value <= 0 or old[index] == value:
			continue
		_drop_cell_effects(index)
		var cell: Vector2i = _cell_of(index)
		var source: int = -1
		var best: float = INF
		for other: int in cell_count:
			if taken[other] == 0 and old[other] == value:
				var distance: float = Vector2(_cell_of(other)).distance_squared_to(Vector2(cell))
				if distance < best:
					best = distance
					source = other
		if source >= 0:
			taken[source] = 1
			var length: float = skin.duration(_slide_motion())
			_add_cell_effect(BoardEffect.SLIDE, index, _clock, length, value).offset = Vector2(_cell_of(source) - cell)
			longest = maxf(longest, length)
		else:
			var length: float = skin.duration(&"spawn")
			_add_cell_effect(BoardEffect.SPAWN, index, _clock, length, value)
			longest = maxf(longest, length)
	for index: int in cell_count:
		if taken[index] == 0 and old[index] > 0:
			var length: float = skin.duration(&"clear")
			_add_ghost(BoardEffect.DEPART, _cell_of(index), old[index], length)
			longest = maxf(longest, length)
	_started()
	return longest


## Steps the effect clock by seconds, as a frame would. Review scenes and
## tests use it with effects_paused to show a moment of an effect.
func advance_effects(seconds: float) -> void:
	if skin == null:
		return
	_tick(seconds)


## True while an effect that moves or changes a tile still runs. Decorative
## tails do not count.
func has_running_effects() -> bool:
	for effect: BoardEffect in _effects:
		if not effect.is_decor():
			return true
	return _travel_length >= 0.0


## The value shown in a cell, 0 for an empty cell.
func value_at(cell: Vector2i) -> int:
	var index: int = _index_of(cell)
	return _cells[index] if index >= 0 else 0


# Hooks for the skins.

func _make_painter() -> TilePainter:
	push_error("board view does not implement _make_painter()")
	return TilePainter.new()


## Builds whatever the skin draws with: style boxes, extra painters.
func _setup_look() -> void:
	pass


## Called after the geometry changes, to size painters and boxes.
func _on_layout() -> void:
	pass


## Draws the back, line or top layer into item.
func _draw_layer(_layer: int, _item: CanvasItem) -> void:
	pass


## Draws one tile in tile space: its tile item, and its under item for what
## must sit under the chain line. moving is true for a tile that is not
## resting on its cell (falling, sliding, a ghost), which draws whole.
func _draw_item(_tile: RID, _under: RID, _value: int, _chain_amount: float, _join: float, _press: float, _select: float, _flash: bool, _glow: float, _moving: bool) -> void:
	pass


## Extra scale of a tile item for its chained look (Gumdrop's press_scale).
func _item_scale(_chain_amount: float) -> float:
	return 1.0


## Extra turn of a cell's tile item, in radians (Gumdrop's selected wobble).
func _item_turn(_index: int) -> float:
	return 0.0


## Whether a cell shows as empty on the back layer: no tile, or its tile is
## away from its cell or not yet grown in.
func _shows_empty(index: int) -> bool:
	var fx: TileFx = _fx[index]
	return _cells[index] <= 0 or fx.hidden or fx.offset != Vector2.ZERO or (fx.scale.x < 1.0 and fx.scale.y < 1.0)


## Whether the back layer animates right now (Nova's clear sparks).
func _back_animates() -> bool:
	return false


## Whether the top layer animates right now (bursts, a turning orbit).
func _top_animates() -> bool:
	return false


## Whether the chain line runs on from the last chain tile to the finger.
func _line_has_tail() -> bool:
	return true


## The rect the end of the tail to the finger is kept inside, in local px:
## the board view's rect. A skin with a tray keeps it on the tray.
func _tail_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, size)


## Whether travelling chain tiles follow the chain path (true) or slide
## straight into the result (false).
func _travel_follows_path() -> bool:
	return true


## Whether the chain line disappears the moment a merge starts (true) or
## pulls in behind the travelling tiles (false).
func _line_cuts_on_merge() -> bool:
	return false


## Whether merge_pop is a decorative tail that does not block input.
func _pop_is_decor() -> bool:
	return false


## The motion a tile moving to another cell uses in Swap, Shuffle and Undo.
func _slide_motion() -> StringName:
	return &"fall"


## Called for each tile play_clear() starts clearing.
func _on_clear_ghost(_ghost: BoardEffect) -> void:
	pass


# Frame functions. Each adds its part to fx at a linear progress from 0 to 1
# through the effect.

func _spawn_frame(fx: TileFx, progress: float) -> void:
	fx.scale *= MotionMath.eased(skin, &"spawn", progress)


func _pop_frame(_fx_value: TileFx, _progress: float) -> void:
	pass


func _fall_frame(fx: TileFx, progress: float, offset: Vector2) -> void:
	fx.offset += offset * (1.0 - MotionMath.eased(skin, &"fall", progress))
	fx.raise_layer(TileFx.LAYER_MOVING)


func _slide_frame(fx: TileFx, progress: float, offset: Vector2) -> void:
	var amount: float = minf(MotionMath.eased(skin, _slide_motion(), progress), 1.0)
	fx.offset += offset * (1.0 - amount)
	fx.raise_layer(TileFx.LAYER_MOVING)


func _clear_frame(fx: TileFx, progress: float) -> void:
	fx.scale *= 1.0 - MotionMath.eased(skin, &"clear", progress)


func _depart_frame(fx: TileFx, progress: float) -> void:
	_clear_frame(fx, progress)


# Helpers for drawing.

## Local px of a point in cell units.
func _point_of(cell_point: Vector2) -> Vector2:
	return _origin + cell_point * _pitch


func _center_of(index: int) -> Vector2:
	_ensure_layout()
	return _centers[index]


func _rect_of(index: int) -> Rect2:
	return cell_rect(_cell_of(index))


## Center of a ghost or decor effect's tile in local px.
func _ghost_center(effect: BoardEffect) -> Vector2:
	return _point_of(effect.origin)


## Progress of an effect on the clock, clamped to 0 to 1.
func _progress(effect: BoardEffect) -> float:
	return clampf(effect.progress_at(_clock), 0.0, 1.0)


func _has_started(effect: BoardEffect) -> bool:
	return effect.progress_at(_clock) >= 0.0


## Seconds since Swap's tile was selected, for the target_pulse loop.
func _pulse_time() -> float:
	return _clock - _selected_since


## Fills _line_points with the chain line in px: from the trail point while
## a merge travels, through the chain centers, to the finger when the skin
## draws a tail. Returns the point count.
func _build_line_points() -> int:
	_line_count = 0
	var count: int = _line_cells.size()
	if count == 0:
		return 0
	if _travel_length >= 0.0:
		var first: int = count
		for i: int in count:
			if _line_distance[i] > _trail:
				first = i
				break
		_line_points[0] = _point_of(_path_point(_trail))
		_line_owner[0] = mini(first, count - 1)
		_line_count = 1
		for i: int in range(first, count):
			_line_points[_line_count] = cell_center(_line_cells[i])
			_line_owner[_line_count] = i
			_line_count += 1
		return _line_count
	for i: int in count:
		_line_points[_line_count] = cell_center(_line_cells[i])
		_line_owner[_line_count] = i
		_line_count += 1
	if _line_has_tail() and _drag != NO_DRAG:
		# The chain stays when the finger leaves the board (AT-19); only the
		# drawn tail stops at the board's edge.
		var bounds: Rect2 = _tail_bounds()
		_line_points[_line_count] = _drag.clamp(bounds.position, bounds.position + bounds.size.max(Vector2.ZERO))
		_line_owner[_line_count] = count - 1
		_line_count += 1
	return _line_count


## Where the merge preview sits: the gap crossing at the top left corner of
## the last chain tile, or the top right corner when that tile is in column 0.
func _preview_center() -> Vector2:
	var last: Vector2i = _chain.back()
	var corner: Vector2 = Vector2(last)
	if last.x == 0:
		corner.x += 1.0
	return _point_of(corner)


func _show_preview() -> bool:
	return _preview > 0 and not _chain.is_empty()


# Internals.

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if skin != null:
			_ensure_layout()
			_refresh_all()
	elif what == NOTIFICATION_ENTER_TREE:
		set_process(not effects_paused and _is_busy())
	elif what == NOTIFICATION_READY:
		# Godot turns processing on for a script with _process when it becomes
		# ready; keep it on only while something animates.
		set_process(not effects_paused and _is_busy())
	elif what == NOTIFICATION_PREDELETE:
		for item: RID in _tile_items:
			RenderingServer.free_rid(item)
		for item: RID in _under_items:
			RenderingServer.free_rid(item)
		_tile_items.clear()
		_under_items.clear()


func _process(delta: float) -> void:
	if effects_paused or skin == null:
		set_process(false)
		return
	if not _tick(delta):
		set_process(false)


func _draw() -> void:
	if _ensure_layout():
		_draw_layer(LAYER_BACK, self)


func _on_layer_draw(layer: int, item: CanvasItem) -> void:
	if _ensure_layout():
		_draw_layer(layer, item)


func _make_layers() -> void:
	if _under_layer != null:
		return
	_under_layer = _make_layer()
	_line_layer = _make_layer()
	_tiles_layer = _make_layer()
	_top_layer = _make_layer()
	_line_layer.draw.connect(_on_layer_draw.bind(LAYER_LINE, _line_layer))
	_top_layer.draw.connect(_on_layer_draw.bind(LAYER_TOP, _top_layer))


func _make_layer() -> Control:
	var control: Control = Control.new()
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(control)
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return control


## Makes tile items until there are count of each.
func _ensure_items(count: int) -> void:
	var have: int = _tile_items.size()
	if have >= count:
		return
	var tiles_parent: RID = _tiles_layer.get_canvas_item()
	var under_parent: RID = _under_layer.get_canvas_item()
	_item_keys.resize(count * KEY_SIZE)
	_item_alpha.resize(count)
	_item_order.resize(count)
	_item_shown.resize(count)
	_item_rest.resize(count)
	for item: int in range(have, count):
		var tile: RID = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(tile, tiles_parent)
		RenderingServer.canvas_item_set_visible(tile, false)
		var under: RID = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(under, under_parent)
		RenderingServer.canvas_item_set_visible(under, false)
		_tile_items.append(tile)
		_under_items.append(under)
		_item_xforms.append(Transform2D.IDENTITY)
		_item_alpha[item] = 1.0
		_item_order[item] = -1
		_item_shown[item] = 0
		_item_rest[item] = 0
		_item_keys[item * KEY_SIZE] = -1.0


## Works out the geometry when the size changed since last time. Returns
## whether there is a layout to draw.
func _ensure_layout() -> bool:
	if skin == null:
		return false
	if size != _layout_size:
		_compute_layout()
	return _has_layout


func _compute_layout() -> void:
	_layout_size = size
	_has_layout = false
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var metrics: Vector3 = _painter.board_metrics(size.x, columns)
	if metrics.x <= 0.0:
		return
	var needed: float = _extent(rows, metrics)
	if needed > size.y:
		# Too tall for the rect: the whole board shrinks evenly (DESIGN_SYSTEM.md 2.3).
		metrics *= size.y / needed
	_side = metrics.x
	_gap = metrics.y
	_pad = metrics.z
	_pitch = _side + _gap
	var board_size: Vector2 = Vector2(_extent(columns, metrics), _extent(rows, metrics))
	_board_rect = Rect2((size - board_size) * 0.5, board_size)
	_origin = _board_rect.position + Vector2.ONE * (_pad - _gap * 0.5)
	_unit = _side / _painter.reference_side()
	for index: int in cell_count:
		_centers[index] = _origin + (Vector2(_cell_of(index)) + HALF_CELL) * _pitch
	_has_layout = true
	_epoch += 1.0
	_painter.set_side(_side, _unit)
	_on_layout()


## Length of a board of count tiles along one side.
static func _extent(count: int, metrics: Vector3) -> float:
	return float(count) * metrics.x + float(count - 1) * metrics.y + 2.0 * metrics.z


## Brings the tile items up to date and redraws every layer.
func _refresh_all() -> void:
	_sync_items()
	queue_redraw()
	_line_layer.queue_redraw()
	_top_layer.queue_redraw()


## Brings the tile items up to date and redraws the layers that show
## highlights.
func _refresh_items() -> void:
	_sync_items()
	_line_layer.queue_redraw()
	_top_layer.queue_redraw()


## Updates every tile item: shown or hidden, its look (drawn again only when
## it changed), its transform, its alpha and its draw order. Also redraws
## the back layer when the set of empty cells changed.
func _sync_items() -> void:
	if not _ensure_layout():
		return
	var selected: int = _index_of(_selected)
	var back_changed: bool = false
	for index: int in cell_count:
		var fx: TileFx = _fx[index]
		var label: int = _labels[index]
		var chain: float = _chain_fade.value[index]
		var join: float = _join_fade.value[index]
		var press: float = _press_fade.value[index]
		var select: float = _select_fade.value[index]
		var plain: bool = chain == 0.0 and join == 0.0 and press == 0.0 and select == 0.0 and index != selected and fx.is_rest()
		if plain and _item_rest[index] != 0 and _item_keys[index * KEY_SIZE] == float(label) and _item_keys[index * KEY_SIZE + 8] == _epoch:
			# A resting tile that was drawn as one and has not changed since.
			continue
		var rank: int = RANK_REST
		if fx.layer == TileFx.LAYER_MOVING:
			rank = RANK_MOVING
		elif fx.layer == TileFx.LAYER_TOP:
			rank = RANK_TOP
		elif fx.spawning:
			rank = RANK_SPAWN
		if index == selected:
			rank = RANK_SELECTED
		_sync_item(index, _cells[index], _centers[index], fx, chain, join, press, select, _item_turn(index), rank, fx.layer != TileFx.LAYER_REST)
		_item_rest[index] = 1 if plain else 0
		var empty: int = 1 if _shows_empty(index) else 0
		if empty != _empty_mask[index]:
			_empty_mask[index] = empty
			back_changed = true
	var item: int = cell_count
	for effect: BoardEffect in _effects:
		if not effect.is_ghost() or not _has_started(effect):
			continue
		_ensure_items(item + 1)
		var rank: int = RANK_LEAVING
		if effect.kind == BoardEffect.TRAVEL:
			rank = RANK_TRAVEL
		elif effect.kind == BoardEffect.HOLD:
			rank = RANK_HOLD
		_sync_item(item, effect.value, _ghost_center(effect), effect.fx, effect.chain, 0.0, 0.0, 0.0, 0.0, rank, true)
		item += 1
	for unused: int in range(item, _tile_items.size()):
		_show_item(unused, false)
	if back_changed:
		queue_redraw()


func _sync_item(item: int, value: int, center: Vector2, fx: TileFx, chain: float, join: float, press: float, select: float, turn: float, rank: int, moving: bool) -> void:
	var label: int = TilePainter.index_of(value)
	var shown: bool = label >= 0 and not fx.hidden and not fx.is_collapsed()
	_show_item(item, shown)
	var key: int = item * KEY_SIZE
	if not shown:
		# Forget the look, so the tile is drawn again when it shows.
		_item_keys[key] = -2.0 if label >= 0 else float(label)
		_item_keys[key + 8] = _epoch
		return
	var flash: float = 1.0 if fx.flash else 0.0
	var moved: float = 1.0 if moving else 0.0
	if _item_keys[key] != float(label) or _item_keys[key + 1] != chain or _item_keys[key + 2] != join \
			or _item_keys[key + 3] != press or _item_keys[key + 4] != select or _item_keys[key + 5] != flash \
			or _item_keys[key + 6] != fx.glow or _item_keys[key + 7] != moved or _item_keys[key + 8] != _epoch:
		_item_keys[key] = float(label)
		_item_keys[key + 1] = chain
		_item_keys[key + 2] = join
		_item_keys[key + 3] = press
		_item_keys[key + 4] = select
		_item_keys[key + 5] = flash
		_item_keys[key + 6] = fx.glow
		_item_keys[key + 7] = moved
		_item_keys[key + 8] = _epoch
		RenderingServer.canvas_item_clear(_tile_items[item])
		RenderingServer.canvas_item_clear(_under_items[item])
		_draw_item(_tile_items[item], _under_items[item], value, chain, join, press, select, fx.flash, fx.glow, moving)
	var spin: float = fx.rotation + turn
	var tile_scale: Vector2 = fx.scale * _item_scale(chain)
	var pivot: Vector2 = fx.pivot * _side
	var basis: Transform2D = Transform2D(spin, tile_scale, 0.0, Vector2.ZERO)
	var xform: Transform2D = Transform2D(spin, tile_scale, 0.0, center + fx.offset + pivot - basis.basis_xform(pivot))
	if xform != _item_xforms[item]:
		_item_xforms[item] = xform
		RenderingServer.canvas_item_set_transform(_tile_items[item], xform)
		RenderingServer.canvas_item_set_transform(_under_items[item], xform)
	if fx.alpha != _item_alpha[item]:
		_item_alpha[item] = fx.alpha
		var tint: Color = Color(1.0, 1.0, 1.0, fx.alpha)
		RenderingServer.canvas_item_set_modulate(_tile_items[item], tint)
		RenderingServer.canvas_item_set_modulate(_under_items[item], tint)
	var order: int = rank * RANK_STEP + item
	if order != _item_order[item]:
		_item_order[item] = order
		RenderingServer.canvas_item_set_draw_index(_tile_items[item], order)
		RenderingServer.canvas_item_set_draw_index(_under_items[item], order)


func _show_item(item: int, shown: bool) -> void:
	var flag: int = 1 if shown else 0
	if _item_shown[item] == flag:
		return
	_item_shown[item] = flag
	RenderingServer.canvas_item_set_visible(_tile_items[item], shown)
	RenderingServer.canvas_item_set_visible(_under_items[item], shown)


## Sets a cell's value and its label index.
func _put_cell(index: int, value: int) -> void:
	_cells[index] = value
	_labels[index] = TilePainter.index_of(value)


## Works out every cell's label index after _cells was replaced.
func _relabel() -> void:
	for index: int in cell_count:
		_labels[index] = TilePainter.index_of(_cells[index])


func _check_setup(method_name: String) -> bool:
	if skin == null:
		push_error("%s() needs setup() first" % method_name)
		return false
	return true


func _index_of(cell: Vector2i) -> int:
	if cell.x < 0 or cell.y < 0 or cell.x >= columns or cell.y >= rows:
		return -1
	return cell.y * columns + cell.x


@warning_ignore("integer_division")
func _cell_of(index: int) -> Vector2i:
	return Vector2i(index % columns, index / columns)


func _same_chain(chain: Array[Vector2i]) -> bool:
	if chain.size() != _chain.size():
		return false
	for i: int in chain.size():
		if chain[i] != _chain[i]:
			return false
	return true


func _set_line_from_chain() -> void:
	_line_cells = _chain.duplicate()
	_fill_line_values()


func _fill_line_values() -> void:
	var count: int = _line_cells.size()
	_line_values.resize(count)
	_line_distance.resize(count)
	var total: float = 0.0
	for i: int in count:
		_line_values[i] = _cells[_index_of(_line_cells[i])]
		if i > 0:
			total += Vector2(_line_cells[i]).distance_to(Vector2(_line_cells[i - 1]))
		_line_distance[i] = total


## A point on the line path, distance cell units from its first cell, in
## cell units. Before the start it runs on backwards along the first segment,
## so a back ease can pull tiles back a little.
func _path_point(distance: float) -> Vector2:
	var count: int = _line_cells.size()
	if count == 0:
		return Vector2.ZERO
	var first: Vector2 = Vector2(_line_cells[0]) + HALF_CELL
	if count == 1:
		return first
	if distance <= 0.0:
		var second: Vector2 = Vector2(_line_cells[1]) + HALF_CELL
		return first + (second - first).normalized() * distance
	for i: int in range(1, count):
		if distance <= _line_distance[i]:
			var from: Vector2 = Vector2(_line_cells[i - 1]) + HALF_CELL
			var to: Vector2 = Vector2(_line_cells[i]) + HALF_CELL
			var span: float = _line_distance[i] - _line_distance[i - 1]
			return from.lerp(to, (distance - _line_distance[i - 1]) / maxf(span, 0.0001))
	return Vector2(_line_cells[count - 1]) + HALF_CELL


func _add_cell_effect(kind: int, index: int, start: float, length: float, value: int) -> BoardEffect:
	var effect: BoardEffect = BoardEffect.new()
	effect.kind = kind
	effect.index = index
	effect.start = start
	effect.length = length
	effect.value = value
	effect.origin = Vector2(_cell_of(index)) + HALF_CELL
	_effects.append(effect)
	return effect


func _add_ghost(kind: int, cell: Vector2i, value: int, length: float) -> BoardEffect:
	var effect: BoardEffect = BoardEffect.new()
	effect.kind = kind
	effect.start = _clock
	effect.length = length
	effect.value = value
	effect.origin = Vector2(cell) + HALF_CELL
	effect.fx = TileFx.new()
	_effects.append(effect)
	return effect


## Adds a decor effect at a cell center. Decor effects outlive set_board().
func _add_decor(kind: int, origin: Vector2, value: int, start: float, length: float) -> BoardEffect:
	var effect: BoardEffect = BoardEffect.new()
	effect.kind = kind
	effect.start = start
	effect.length = length
	effect.value = value
	effect.origin = origin
	_effects.append(effect)
	return effect


## Ends the effects running on a cell's tile, because a new one replaces it.
func _drop_cell_effects(index: int) -> void:
	for i: int in range(_effects.size() - 1, -1, -1):
		var effect: BoardEffect = _effects[i]
		if effect.on_cell() and effect.index == index:
			_effects.remove_at(i)


func _clear_cell_looks(index: int) -> void:
	_chain_fade.clear_cell_now(index)
	_join_fade.clear_cell_now(index)


## set_board(): ends every effect that changes a tile. Decor tails keep
## running, except a bloom on a cell that now shows another value.
func _end_effects() -> void:
	for i: int in range(_effects.size() - 1, -1, -1):
		var effect: BoardEffect = _effects[i]
		var keep: bool = effect.kind == BoardEffect.BURST
		if effect.kind == BoardEffect.BLOOM:
			keep = _cells[effect.index] == effect.value
		if not keep:
			_effects.remove_at(i)
	_end_travel()
	for fx: TileFx in _fx:
		fx.reset()


func _end_travel() -> void:
	_travel_length = -1.0
	_trail = 0.0
	_set_line_from_chain()


## Applies frame 0 of new effects at once, so the first frame already shows
## them, and starts the clock.
func _started() -> void:
	_update_effects()
	_wake()
	_refresh_all()


func _wake() -> void:
	if not effects_paused and is_inside_tree():
		set_process(true)


func _is_busy() -> bool:
	if _chain_fade == null:
		return false
	var fading: bool = _chain_fade.is_moving() or _join_fade.is_moving() or _press_fade.is_moving() or _select_fade.is_moving()
	return fading or not _effects.is_empty() or _travel_length >= 0.0 or _pulse_running()


func _pulse_running() -> bool:
	return _selected != NO_CELL and _pulse_period > 0.0


## Advances the clock. Returns true while anything still animates.
func _tick(delta: float) -> bool:
	_clock += delta
	var chain_moving: bool = _chain_fade.step(delta)
	var join_moving: bool = _join_fade.step(delta)
	var press_moving: bool = _press_fade.step(delta)
	var select_moving: bool = _select_fade.step(delta)
	var travelling: bool = _travel_length >= 0.0
	var running: bool = _update_effects()
	var pulse: bool = _pulse_running()
	_sync_items()
	if chain_moving or travelling:
		_line_layer.queue_redraw()
	if press_moving or select_moving or _top_animates():
		_top_layer.queue_redraw()
	if _back_animates():
		queue_redraw()
	return chain_moving or join_moving or press_moving or select_moving or running or pulse


## Resets every TileFx and applies each running effect. Removes finished
## effects. Returns true when any effect was running.
func _update_effects() -> bool:
	_ensure_layout()
	var running: bool = not _effects.is_empty() or _travel_length >= 0.0
	for fx: TileFx in _fx:
		fx.reset()
	var i: int = 0
	while i < _effects.size():
		var effect: BoardEffect = _effects[i]
		var progress: float = effect.progress_at(_clock)
		if progress >= 1.0:
			_effects.remove_at(i)
			continue
		if effect.is_ghost():
			effect.fx.reset()
		if effect.kind == BoardEffect.SPAWN:
			_fx[effect.index].spawning = true
		if progress < 0.0:
			if effect.kind == BoardEffect.SPAWN:
				_fx[effect.index].hidden = true
		else:
			_apply(effect, progress)
		i += 1
	if _travel_length >= 0.0:
		var travel: float = (_clock - _travel_start) / _travel_length
		if travel >= 1.0:
			_end_travel()
		else:
			var path_end: float = _line_distance[_line_distance.size() - 1] if not _line_distance.is_empty() else 0.0
			_trail = clampf(path_end * MotionMath.eased(skin, &"merge_travel", travel), 0.0, path_end)
	return running


func _apply(effect: BoardEffect, progress: float) -> void:
	match effect.kind:
		BoardEffect.SPAWN:
			_spawn_frame(_fx[effect.index], progress)
		BoardEffect.POP, BoardEffect.BLOOM:
			_pop_frame(_fx[effect.index], progress)
		BoardEffect.FALL:
			_fall_frame(_fx[effect.index], progress, effect.offset * _pitch)
		BoardEffect.SLIDE:
			_slide_frame(_fx[effect.index], progress, effect.offset * _pitch)
		BoardEffect.HIDE:
			_fx[effect.index].hidden = true
		BoardEffect.TRAVEL:
			_travel_frame(effect, progress)
		BoardEffect.HOLD:
			effect.fx.raise_layer(TileFx.LAYER_TOP)
		BoardEffect.CLEAR:
			_clear_frame(effect.fx, progress)
		BoardEffect.DEPART:
			_depart_frame(effect.fx, progress)


func _travel_frame(effect: BoardEffect, progress: float) -> void:
	var amount: float = MotionMath.eased(skin, &"merge_travel", progress)
	var point: Vector2 = Vector2.ZERO
	if _travel_follows_path() and _travel_length >= 0.0:
		point = _path_point(lerpf(effect.path_from, effect.path_to, amount))
	else:
		point = effect.origin.lerp(effect.offset, amount)
	effect.fx.offset = (point - effect.origin) * _pitch
	effect.fx.raise_layer(TileFx.LAYER_MOVING)
