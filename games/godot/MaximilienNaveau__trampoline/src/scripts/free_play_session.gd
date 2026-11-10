# The solo "free play" sandbox from doc/RULES.md's single-player modes:
# all 117 tiles available at once, no turns, no draw restrictions — place,
# move, remove, swap or flip any tile anywhere, any time. Standard scoring
# still applies (a word of n letters is worth 1 + 2 + … + n, minus 5 per
# green letter — see scoring.gd), as one running total.
#
# Deliberately NOT a GameSession subclass: GameSession carries turns/bag/
# draw-scheduling that free play has no use for at all, so inheriting
# would either buy nothing (an empty base) or force free-play-skip
# branches into GameSession itself. main.gd instead calls whichever
# session is active (GameSession or this) by the same method names.
class_name FreePlaySession
extends RefCounted

var board: Board
var pool: TilePool
var dictionary: FrenchDictionary


# `dictionary` can be injected the same way GameSession's constructor
# allows (e.g. a test reusing one already-loaded instance rather than
# reading the ~421,000-word list again) — defaults to loading a fresh one.
func _init(a_dictionary: FrenchDictionary = null) -> void:
	board = Board.new()
	pool = TilePool.new()
	dictionary = a_dictionary if a_dictionary != null else FrenchDictionary.new()


# Every tile NOT currently sitting somewhere on the board — there's no
# hand/bag bookkeeping to maintain at all in free play, so "what's
# available" is simply recomputed from the board's current state each
# time this is called, rather than tracked incrementally.
func available_tiles() -> Array[Tile]:
	# A Dictionary used purely as a hash set (its values never read, only
	# `.has()` checked below) — the standard GDScript way to test "is this
	# tile somewhere on the board?" in O(1) per tile instead of scanning
	# the whole board again for each of the 117.
	var on_board := {}
	for row in range(Board.ROWS):
		for col in range(Board.COLUMNS):
			var tile := board.tile_at(row, col)
			if tile != null:
				on_board[tile] = true

	var available: Array[Tile] = []
	for tile in pool.tiles:
		if not on_board.has(tile):
			available.append(tile)
	return available


# Places `tile` at (row, col) — anywhere, free play has no rules about
# where (board.gd's own header comment: free play calls straight into
# Board). On an occupied cell, the tile there goes back among the
# available ones (a swap, as in a game, see GameSession.place_tile).
func place_tile(row: int, col: int, tile: Tile) -> void:
	board.remove(row, col)
	board.place(row, col, tile)


# Picks the tile at (row, col) back up, giving it back to `available_tiles()`
# (nothing else to update — see that function's own comment). Returns
# null if the cell is empty.
func remove_tile(row: int, col: int) -> Tile:
	return board.remove(row, col)


# Moves the tile at (from_row, from_col) to (to_row, to_col). On an
# occupied cell, the tile there goes back among the available ones (a
# swap, see `place_tile`). Does nothing if the source is empty or is the
# destination itself.
func move_tile(from_row: int, from_col: int, to_row: int, to_col: int) -> void:
	if (
		board.is_empty(from_row, from_col)
		or Vector2i(from_col, from_row) == Vector2i(to_col, to_row)
	):
		return
	place_tile(to_row, to_col, board.remove(from_row, from_col))


# Moves the tiles in `cells` (`Vector2i(col, row)`) together by `offset`,
# as in a game (see block_move.gd).
func move_tiles(cells: Array[Vector2i], offset: Vector2i) -> void:
	BlockMove.move(board, cells, offset)


# Flips the tile at (row, col) in place, revealing its other face — same
# as GameSession.flip_tile, and for the same reason scoring needs no
# separate bookkeeping here either: Scoring always reads a tile's CURRENT
# face live (see scoring.gd). Returns false and does nothing if the cell
# is empty.
func flip_tile(row: int, col: int) -> bool:
	var tile := board.tile_at(row, col)
	if tile == null:
		return false
	tile.flip()
	return true


# The current total score: what the board is worth (see
# Scoring.board_value). There's no separate "commit" step in free play —
# the score is just always whatever it currently is.
func current_score() -> int:
	return Scoring.board_value(board, dictionary)
