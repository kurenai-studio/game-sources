# Moving several board tiles together, as one block: the ones the player
# selected with the dotted box (see board_view.gd), dragged by any one of
# them. Every tile shifts by the same number of rows and columns, so the
# block keeps its shape. Any player may move any tile during their turn;
# what the turn must leave behind is checked when it ends (see
# game_session.gd's `emptied_cells`).
#
# Cells are `Vector2i(col, row)`: Godot's 2D integer vector (like a C++
# struct of two ints), x for the column and y for the row, as on screen.
#
# Every function here is `static`: this class holds no state, it only acts
# on a `Board` passed in (like a C++ class of static methods).
class_name BlockMove
extends RefCounted


# Whether the tiles in `cells` can all move by `offset` (columns, rows):
# every one must land on the board, on a cell that's empty or that one of
# the block's own tiles is leaving (the block may slide over itself).
static func can_move(board: Board, cells: Array[Vector2i], offset: Vector2i) -> bool:
	if cells.is_empty():
		return false
	for cell in cells:
		if board.tile_at(cell.y, cell.x) == null:
			return false
		var dest := cell + offset
		if dest.x < 0 or dest.x >= Board.COLUMNS or dest.y < 0 or dest.y >= Board.ROWS:
			return false
		if not cells.has(dest) and not board.is_empty(dest.y, dest.x):
			return false
	return true


# Moves the tiles in `cells` by `offset`. Returns false and does nothing if
# `can_move` refuses.
static func move(board: Board, cells: Array[Vector2i], offset: Vector2i) -> bool:
	if not can_move(board, cells, offset):
		return false
	# Every tile is lifted first, then all are put down: a block sliding
	# over itself lands on cells some of its own tiles are still leaving.
	var tiles: Array[Tile] = []
	for cell in cells:
		tiles.append(board.remove(cell.y, cell.x))
	for i in range(cells.size()):
		var dest := cells[i] + offset
		board.place(dest.y, dest.x, tiles[i])
	return true
