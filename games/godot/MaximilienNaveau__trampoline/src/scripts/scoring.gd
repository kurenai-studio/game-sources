# The points the board is worth, and the completion bonuses (see
# doc/RULES.md). Only dictionary-valid words score anything at all.
#
# A word of n letters is worth 1 + 2 + … + n — what laying its letters one
# after the other would earn (the 2015 rules: "la case 1 vaut 1 point …
# la ligne totale vaut 45") — minus 5 points per green letter. Nobody owns
# a letter: each turn, the player earns what their turn changed the
# board's worth by (see game_session.gd's `turn_points`), whatever they did
# to get there — placing, moving, swapping or flipping tiles.
#
# Bonuses are a lump sum paid to whoever completes the row (see
# `claim_line_bonus`/`claim_board_bonus`): this class doesn't need to know
# which player is claiming one, only the caller does.
class_name Scoring
extends RefCounted

const LINE_COMPLETION_BONUS := 10
const SINGLE_COLOR_WORD_BONUS := 50
const MIXED_COLOR_WORD_BONUS := 30
const BOARD_COMPLETION_BONUS := 30
const GREEN_LETTER_PENALTY := 5

# One "already paid?" flag per row for the line bonus, and a single flag
# for the whole-board bonus.
var _line_bonus_claimed: Array[bool] = []
var _board_bonus_claimed := false

# Snapshot of how many cells were filled in each row, taken by
# `begin_turn`, so `claim_line_bonus` can tell apart the two different
# ways a row can reach 9 letters (confirmed by Maximilien — these are NOT
# the same bonus):
#   - Completing a word that already had letters on the board before the
#     current turn began: worth +10, regardless of color.
#   - Writing an entire 9-letter word within a single turn, starting from
#     a completely empty row — the equivalent of a Scrabble "bingo" —
#     earns more instead: +50 if entirely yellow, +30 if mixed color.
# Defaults to all zeros, so code that never calls `begin_turn` (tests,
# tools) treats every row as if it started the (single, implicit) turn
# empty — i.e. eligible for the bigger bonus.
var _filled_count_at_turn_start: Array[int] = []


func _init() -> void:
	for row in range(Board.ROWS):
		_line_bonus_claimed.append(false)
		_filled_count_at_turn_start.append(0)


# Snapshots how many cells are currently filled in every row. Call this
# once, at the start of each player's turn, before they place or remove
# anything, so `claim_line_bonus` can later tell a from-scratch "scrabble"
# apart from completing a word that already existed.
func begin_turn(board: Board) -> void:
	for row in range(Board.ROWS):
		var filled := 0
		for col in range(Board.COLUMNS):
			if not board.is_empty(row, col):
				filled += 1
		_filled_count_at_turn_start[row] = filled


# What the whole board is worth right now: every valid word's letters
# (see the top of this file), green ones costing 5 each. Only a word
# starting in the first column counts (see doc/RULES.md). `static`: it only
# reads the board, nothing of this class's own (like a C++ static method).
static func board_value(board: Board, dictionary: FrenchDictionary) -> int:
	var total := 0
	for row in range(Board.ROWS):
		for segment in board.segments_in_row(row):
			var col: int = segment[0]
			if col > 0 or not dictionary.is_word_valid(board.word_at(row, col)):
				continue
			var columns := board.word_columns_at(row, col)
			var length := columns.size()
			# 1 + 2 + … + n. Both sides are whole numbers, so `/` divides
			# exactly here (n(n+1) is always even): Godot is told not to warn.
			@warning_ignore("integer_division")
			total += length * (length + 1) / 2
			total -= GREEN_LETTER_PENALTY * _green_letter_count(board, row, columns)
	return total


# The line-completion bonus `row` would earn right now: only once per
# row, ever, and only once it holds exactly one word (not zero, not two —
# see board.gd) that's a dictionary-valid 9 letters. Returns the bonus
# amount, or 0 if it isn't earned yet (or was already claimed). See
# `_filled_count_at_turn_start` above for which of the two distinct
# bonuses this is. Only looks: `claim_line_bonus` actually pays it out.
func line_bonus(board: Board, dictionary: FrenchDictionary, row: int) -> int:
	if _line_bonus_claimed[row]:
		return 0

	var segments := board.segments_in_row(row)
	if segments.size() != 1:
		return 0

	var col: int = segments[0][0]
	var columns := board.word_columns_at(row, col)
	var is_finished_valid_word := (
		columns.size() == Board.COLUMNS and dictionary.is_word_valid(board.word_at(row, col))
	)
	if not is_finished_valid_word:
		return 0

	if _filled_count_at_turn_start[row] > 0:
		return LINE_COMPLETION_BONUS
	if _green_letter_count(board, row, columns) == 0:
		return SINGLE_COLOR_WORD_BONUS
	return MIXED_COLOR_WORD_BONUS


# Pays out `line_bonus` and marks it claimed, so `row` never pays again:
# a lump sum for whoever completes the row; the caller (not this class)
# knows who that is.
func claim_line_bonus(board: Board, dictionary: FrenchDictionary, row: int) -> int:
	var bonus := line_bonus(board, dictionary, row)
	if bonus > 0:
		_line_bonus_claimed[row] = true
	return bonus


# The whole-board completion bonus the board would earn right now: only
# once, ever, and only once every row is finished (see `Board.is_complete`
# — a row counts even if it was deliberately shortened, not just at 9
# letters). Returns the bonus amount, or 0 if not earned yet (or already
# claimed). Only looks: `claim_board_bonus` pays it out.
func board_bonus(board: Board) -> int:
	if _board_bonus_claimed or not board.is_complete():
		return 0
	return BOARD_COMPLETION_BONUS


# Pays out `board_bonus` and marks it claimed.
func claim_board_bonus(board: Board) -> int:
	var bonus := board_bonus(board)
	if bonus > 0:
		_board_bonus_claimed = true
	return bonus


# Exports every bit of this class's state — see save_game.gd.
func export_state() -> Dictionary:
	return {
		"line_bonus_claimed": _line_bonus_claimed,
		"board_bonus_claimed": _board_bonus_claimed,
		"filled_count_at_turn_start": _filled_count_at_turn_start,
	}


# Overwrites this class's entire state from `data` (see `export_state`).
# See turn_manager.gd's restore_state for why numbers need an explicit
# `int(...)` cast after a JSON round-trip.
func restore_state(data: Dictionary) -> void:
	_line_bonus_claimed.clear()
	for claimed in data["line_bonus_claimed"]:
		_line_bonus_claimed.append(claimed)
	_board_bonus_claimed = data["board_bonus_claimed"]
	_filled_count_at_turn_start.clear()
	for filled in data["filled_count_at_turn_start"]:
		_filled_count_at_turn_start.append(int(filled))


# How many tiles on the whole board show a green face — letters and
# blanks alike (a blank is a tile's green side, see tile_pool.gd). None
# on a finished board (see `is_perfect`) is the best a game can end on.
static func green_face_count(board: Board) -> int:
	var count := 0
	for row in range(Board.ROWS):
		for col in range(Board.COLUMNS):
			var tile := board.tile_at(row, col)
			if tile != null and tile.current_is_green():
				count += 1
	return count


# Whether `board` is the best a game can end on: finished (see
# Board.is_complete) without a single green face — so 13 all-yellow words
# of 9 letters, the highest score there is.
static func is_perfect(board: Board) -> bool:
	return board.is_complete() and green_face_count(board) == 0


# How many letters in `columns` of `row` are green.
static func _green_letter_count(board: Board, row: int, columns: Array) -> int:
	var count := 0
	for col in columns:
		if board.tile_at(row, col).current_is_green():
			count += 1
	return count
