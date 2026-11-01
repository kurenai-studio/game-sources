class_name SkinBoardView extends Control
## The board as one skin draws it: board, tiles, chain line, merge preview,
## highlights and effects (docs/ARCHITECTURE.md section 6). It holds no rules:
## the board controller tells it everything.
##
## Each skin subclasses this and implements every method. The methods here
## only report a subclass that forgot one. Create a view through
## SkinCatalog.make_board_view(skin), then call setup().
##
## Cells are Vector2i(column, row). Boards are PackedInt64Array cells, index
## row * columns + column, each the tile's exponent k (the tile is 2^k,
## ARCHITECTURE.md 17), 0 for an empty cell. Every value below is an exponent. Vector2i(-1, -1) means "no
## cell".
##
## Effects start at once and return their length in seconds: the time until
## every tile they touch is at rest on its cell. Decorative tails (Gumdrop's
## candy burst after a clear, Nova's glow bloom after a merge) keep running
## after that and never block input. After the last effect of a move the
## controller calls set_board(cells_after), which ends every effect that
## changes a tile.

const NO_CELL: Vector2i = Vector2i(-1, -1)


func _init() -> void:
	# The view draws only. The board controller around it handles input.
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(_skin: SkinData, _columns: int, _rows: int) -> void:
	_missing("setup")


## Static look, complete in the first frame.
func set_board(_cells: PackedInt64Array) -> void:
	_missing("set_board")


## The chain in drag order. drag_point is the finger in local pixels, or
## Vector2(-1, -1) for none. An empty chain clears it.
func set_chain(_chain: Array[Vector2i], _drag_point: Vector2) -> void:
	_missing("set_chain")


## The merge preview, as an exponent. 0 hides it. A skin that shows the preview in the
## HUD draws nothing.
func set_preview(_value: int) -> void:
	_missing("set_preview")


## The joinable highlight (D-40).
func set_joinable(_cells: Array[Vector2i]) -> void:
	_missing("set_joinable")


## The booster in targeting mode. &"" ends targeting.
func set_targeting(_booster_id: StringName) -> void:
	_missing("set_targeting")


## Press feedback on the tile under the finger in targeting (D-43).
## Vector2i(-1, -1) for none.
func set_pressed_cell(_cell: Vector2i) -> void:
	_missing("set_pressed_cell")


## Swap's first tile. Vector2i(-1, -1) for none.
func set_swap_selected(_cell: Vector2i) -> void:
	_missing("set_swap_selected")


## Local rect of a tile.
func cell_rect(_cell: Vector2i) -> Rect2:
	_missing("cell_rect")
	return Rect2()


## Local top left corner of cell (0, 0)'s pitch box.
func grid_origin() -> Vector2:
	_missing("grid_origin")
	return Vector2.ZERO


## Distance between neighboring cell centers.
func cell_pitch() -> Vector2:
	_missing("cell_pitch")
	return Vector2.ZERO


## Height the board needs at this width.
func preferred_height(_width: float) -> float:
	_missing("preferred_height")
	return 0.0


func play_spawn(_cells: Array[Vector2i], _values: PackedInt64Array) -> float:
	_missing("play_spawn")
	return 0.0


func play_merge(_chain: Array[Vector2i], _result_cell: Vector2i, _result_value: int) -> float:
	_missing("play_merge")
	return 0.0


## D-38 small tiles, and the Hammer.
func play_clear(_cells: Array[Vector2i]) -> float:
	_missing("play_clear")
	return 0.0


func play_fall(_from_cells: Array[Vector2i], _to_cells: Array[Vector2i]) -> float:
	_missing("play_fall")
	return 0.0


## Double.
func play_value_change(_cell: Vector2i, _value: int) -> float:
	_missing("play_value_change")
	return 0.0


func play_swap(_a: Vector2i, _b: Vector2i) -> float:
	_missing("play_swap")
	return 0.0


## Shuffle and Undo.
func play_rearrange(_cells_after: PackedInt64Array) -> float:
	_missing("play_rearrange")
	return 0.0


func _missing(method_name: String) -> void:
	var script_path: String = ""
	var own_script: Script = get_script() as Script
	if own_script != null:
		script_path = own_script.resource_path
	push_error("%s does not implement SkinBoardView.%s()" % [script_path, method_name])
