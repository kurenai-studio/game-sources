# The 13x9 board: 117 cells, one 9-letter word per row (see doc/RULES.md).
#
# Pure grid mechanics only — place/remove a tile in a cell, and read back
# what's there. On purpose, this enforces no rules: free play places and
# removes tiles anywhere, and what a turn may do is GameSession's business
# (see game_session.gd), so this file has no knowledge of which mode is
# using it, or of players/turns/scoring/drawing.
#
# A row can hold more than one separate word at once — tiles move freely
# during a turn (see game_session.gd), so two unrelated words can share a
# row, as long as they don't overlap. Every function below that deals
# with "the word" is anchored at a specific column rather than assuming a
# row has exactly one — see `segments_in_row`.
class_name Board
extends RefCounted

# 13 rows, 9 columns — the game's board is always exactly this size (no
# per-instance configuration needed, so these are constants rather than
# constructor parameters).
const ROWS := 13
const COLUMNS := 9

# The grid itself: one Array per row, each holding either `null` (empty
# cell) or a `Tile` (occupied cell). `Array[Tile]` still accepts `null` in
# GDScript — a typed array only constrains what class non-null elements
# must be, the same way a `Tile*` in C++ can be `nullptr`.
var _cells: Array = []


func _init() -> void:
	for row in range(ROWS):
		var empty_row: Array[Tile] = []
		empty_row.resize(COLUMNS)  # `resize` fills the new slots with `null`.
		_cells.append(empty_row)


# Whether a cell has no tile in it yet.
func is_empty(row: int, col: int) -> bool:
	return _cells[row][col] == null


# The tile currently in a cell, or `null` if it's empty.
func tile_at(row: int, col: int) -> Tile:
	return _cells[row][col]


# Index of the leftmost filled cell in a row, or -1 if the whole row is
# empty.
func leftmost_filled(row: int) -> int:
	for col in range(COLUMNS):
		if not is_empty(row, col):
			return col
	return -1


# Index of the rightmost filled cell in a row, or -1 if the whole row is
# empty.
func rightmost_filled(row: int) -> int:
	for col in range(COLUMNS - 1, -1, -1):
		if not is_empty(row, col):
			return col
	return -1


# Every maximal run of consecutively-filled cells in a row, as
# `[start_col, end_col]` inclusive pairs, left to right. A row nobody has
# touched has none; a normal row being grown one contiguous word at a time
# has exactly one; a row holding two unrelated, non-touching words (only
# possible after moving tiles there — see game_session.gd) has two.
func segments_in_row(row: int) -> Array:
	var segments := []
	var col := 0
	while col < COLUMNS:
		if is_empty(row, col):
			col += 1
			continue
		var start := col
		while col < COLUMNS and not is_empty(row, col):
			col += 1
		segments.append([start, col - 1])
	return segments


# Places `tile` at `(row, col)`. The only universal constraint — true in
# every mode — is that a cell can't hold two tiles at once. Returns false
# and does nothing if the cell is already occupied.
func place(row: int, col: int, tile: Tile) -> bool:
	if not is_empty(row, col):
		return false
	_cells[row][col] = tile
	return true


# Removes and returns whatever tile is at `(row, col)`, leaving it empty.
# Unconditional: any tile may be picked up during a turn (what a turn
# must leave behind is GameSession's business, see `emptied_cells`).
# Returns `null` if the cell is empty.
func remove(row: int, col: int) -> Tile:
	var tile: Tile = _cells[row][col]
	_cells[row][col] = null
	return tile


# The column indices making up the word that CONTAINS `col` in `row` —
# i.e. the segment starting at or before `col`, read from its own start,
# stopping at the first blank-showing tile (the "shorten" mechanic — see
# doc/RULES.md) or the first empty cell, whichever comes first, WITHOUT
# including a blank tile's column, since a blank marks "the word ends
# here" even though the row might still have empty cells left to grow
# into later. Empty if `col` itself is empty.
func word_columns_at(row: int, col: int) -> Array[int]:
	var columns: Array[int] = []
	if is_empty(row, col):
		return columns
	var start := col
	while start > 0 and not is_empty(row, start - 1):
		start -= 1
	for c in range(start, COLUMNS):
		var tile: Tile = _cells[row][c]
		if tile == null or tile.is_blank():
			break
		columns.append(c)
	return columns


# The word spelled out by whichever segment contains `col` in `row` — see
# `word_columns_at` above for exactly which cells that covers. Returns ""
# if `col` itself is empty.
func word_at(row: int, col: int) -> String:
	var word := ""
	for c in word_columns_at(row, col):
		word += _cells[row][c].current_letter()
	return word


# Whether a row needs no further growth: it holds exactly one word (not
# zero, not two separate ones), and that word has either reached the full
# 9 letters or was deliberately cut short by a blank-showing tile (the
# "shorten" mechanic) — in both cases nothing more is expected to be
# added. A word merely jammed against the board's edge without reaching 9
# letters and without a blank cap does NOT count — it could still grow
# further as a prefix. Used for the whole-board completion bonus (see
# scoring.gd) — the game's goal is one settled word per row, so a row
# still split across two separate words isn't there yet even if each
# piece looks "capped" on its own.
func is_row_finished(row: int) -> bool:
	var segments := segments_in_row(row)
	if segments.size() != 1:
		return false
	var columns := word_columns_at(row, segments[0][0])
	if columns.size() == COLUMNS:
		return true
	var col_after_word: int = columns[-1] + 1
	if col_after_word >= COLUMNS:
		return false
	var tile: Tile = _cells[row][col_after_word]
	return tile != null and tile.is_blank()


# Whether every row on the board is finished (see `is_row_finished`) —
# the "we filled the whole board" way a game can end (see doc/RULES.md).
# The other way — every player running out of tiles before that happens —
# has nothing to do with the board, so it isn't checked here; see
# turn_manager.gd's header comment for that half of the story.
func is_complete() -> bool:
	for row in range(ROWS):
		if not is_row_finished(row):
			return false
	return true
