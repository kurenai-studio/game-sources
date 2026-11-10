# Whether the tiles a player has placed THIS TURN (see
# GameSession._placed_this_turn) collectively form a legal turn, per
# doc/RULES.md: confined to one row, and extending/starting a SINGLE word
# rather than scattering separate letters around. A placement is never
# refused outright anymore — a player can freely place/move/take back tiles
# all turn, and only finds out something's wrong when trying to end_turn(),
# the same way an invalid dictionary word already works (see
# word_challenge.gd). `static`, same reasoning as WordChallenge:
# this class holds no state of its own, only `board`/`placed_this_turn`
# passed in by whoever's asking (GameSession).
class_name TurnValidity
extends RefCounted


# Every `{row, col}` this turn placed a tile in that's part of a problem:
# either it sits in a row other than where the rest of this turn's tiles
# are, or it's part of a group of letters disconnected from the rest of
# them within that one row. Empty if the turn (so far) is entirely legal —
# including if nothing's been placed yet.
static func invalid_cells(board: Board, placed_this_turn: Array[Tile]) -> Array:
	if placed_this_turn.is_empty():
		return []

	# One full pass over the whole board, collecting — per row — every cell
	# that holds one of THIS turn's own tiles. Cheap even called often (117
	# cells at most), and avoids needing a Tile to know its own board
	# position at all, which nothing else in this codebase needs either.
	var rows_touched: Dictionary = {}  # row (int) -> Array of {row, col}
	for row in range(Board.ROWS):
		for col in range(Board.COLUMNS):
			var tile := board.tile_at(row, col)
			if tile != null and placed_this_turn.has(tile):
				if not rows_touched.has(row):
					rows_touched[row] = []
				rows_touched[row].append({"row": row, "col": col})

	if rows_touched.size() > 1:
		# Spread across more than one row: every one of this turn's own
		# cells is the problem, not just some of them — there's no single
		# "the right row" to single out as the mistake.
		var all_cells := []
		for row in rows_touched:
			all_cells.append_array(rows_touched[row])
		return all_cells

	# Exactly one row touched: still only legal if every one of this turn's
	# own cells in it belongs to the SAME segment (see board.gd's
	# `segments_in_row`) — two separate segments means two separate new
	# words got started in one turn, which isn't allowed even though each
	# individually might read fine extending from an empty cell.
	var row: int = rows_touched.keys()[0]
	var cells: Array = rows_touched[row]
	var segments := board.segments_in_row(row)
	var touched_segment_starts := {}
	for cell in cells:
		for segment in segments:
			if cell["col"] >= segment[0] and cell["col"] <= segment[1]:
				touched_segment_starts[segment[0]] = true
				break
	if touched_segment_starts.size() <= 1:
		return []
	return cells
