extends SkinBoardView
## A SkinBoardView for the board tests. It draws nothing, records every call
## and returns the effect lengths a test sets in durations (0 by default, so
## a move finishes inside the call that resolved it).
## Not a test file: the runner only loads files named test_*.gd.
##
## Fixed geometry: cell (0, 0)'s pitch box starts at ORIGIN and cells are
## PITCH apart, whatever the view's size. Each tile is a TILE square centered
## in its pitch box, so tiles have 20 px gaps between them. The D-07 join
## radius (0.42 of the pitch, 42 px) reaches just past a tile's sides
## (40 px) but not its corners (about 57 px).

const ORIGIN: Vector2 = Vector2(20.0, 30.0)
const PITCH: Vector2 = Vector2(100.0, 100.0)
const TILE: Vector2 = Vector2(80.0, 80.0)

## Effect lengths in seconds by method name, for example &"play_merge".
var durations: Dictionary[StringName, float] = {}

var setup_skin: SkinData = null
var setup_columns: int = 0
var setup_rows: int = 0

## Effects and set_board, in call order, by method name.
var effects: PackedStringArray = PackedStringArray()
## Arguments of each call, in call order per method.
var boards: Array[PackedInt64Array] = []
var merges: Array = []          # [chain, result_cell, result_value]
var clears: Array = []          # cells
var falls: Array = []           # [from_cells, to_cells]
var spawns: Array = []          # [cells, values]
var value_changes: Array = []   # [cell, value]
var swaps: Array = []           # [a, b]
var rearranges: Array = []      # cells_after

## The last state each setter was given, and how often it was called.
var chain: Array[Vector2i] = []
var drag_point: Vector2 = Vector2(-1.0, -1.0)
var chain_calls: int = 0
var preview: int = 0
var previews: Array[int] = []
var joinable: Array[Vector2i] = []
var joinable_calls: int = 0
var targeting: Array[StringName] = []
var pressed: Array[Vector2i] = []
var swap_selected: Array[Vector2i] = []


func setup(skin: SkinData, columns: int, rows: int) -> void:
	setup_skin = skin
	setup_columns = columns
	setup_rows = rows


func set_board(cells: PackedInt64Array) -> void:
	effects.append("set_board")
	boards.append(cells.duplicate())


func set_chain(new_chain: Array[Vector2i], new_drag_point: Vector2) -> void:
	chain = new_chain.duplicate()
	drag_point = new_drag_point
	chain_calls += 1


func set_preview(value: int) -> void:
	preview = value
	previews.append(value)


func set_joinable(cells: Array[Vector2i]) -> void:
	joinable = cells.duplicate()
	joinable_calls += 1


func set_targeting(booster_id: StringName) -> void:
	targeting.append(booster_id)


func set_pressed_cell(cell: Vector2i) -> void:
	pressed.append(cell)


func set_swap_selected(cell: Vector2i) -> void:
	swap_selected.append(cell)


func cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(ORIGIN + (Vector2(cell) + Vector2(0.5, 0.5)) * PITCH - TILE * 0.5, TILE)


func grid_origin() -> Vector2:
	return ORIGIN


func cell_pitch() -> Vector2:
	return PITCH


func preferred_height(width: float) -> float:
	return width * 1.6


func play_spawn(cells: Array[Vector2i], values: PackedInt64Array) -> float:
	spawns.append([cells.duplicate(), values.duplicate()])
	return _effect(&"play_spawn")


func play_merge(merge_chain: Array[Vector2i], result_cell: Vector2i, result_value: int) -> float:
	merges.append([merge_chain.duplicate(), result_cell, result_value])
	return _effect(&"play_merge")


func play_clear(cells: Array[Vector2i]) -> float:
	clears.append(cells.duplicate())
	return _effect(&"play_clear")


func play_fall(from_cells: Array[Vector2i], to_cells: Array[Vector2i]) -> float:
	falls.append([from_cells.duplicate(), to_cells.duplicate()])
	return _effect(&"play_fall")


func play_value_change(cell: Vector2i, value: int) -> float:
	value_changes.append([cell, value])
	return _effect(&"play_value_change")


func play_swap(a: Vector2i, b: Vector2i) -> float:
	swaps.append([a, b])
	return _effect(&"play_swap")


func play_rearrange(cells_after: PackedInt64Array) -> float:
	rearranges.append(cells_after.duplicate())
	return _effect(&"play_rearrange")


## Forgets every recorded call.
func clear_log() -> void:
	effects.clear()
	boards.clear()
	merges.clear()
	clears.clear()
	falls.clear()
	spawns.clear()
	value_changes.clear()
	swaps.clear()
	rearranges.clear()
	chain_calls = 0
	previews.clear()
	joinable_calls = 0
	targeting.clear()
	pressed.clear()
	swap_selected.clear()


func _effect(method_name: StringName) -> float:
	effects.append(String(method_name))
	return durations.get(method_name, 0.0)
