# One crossword-reconstruction puzzle (see doc/RULES.md's third
# single-player mode and crossword_puzzles.gd for the raw data): a
# hidden 13-word target grid, one 9-letter word per board row, plus its
# clues. Deliberately holds no Board/Tile of its own and never mutates
# anything — it only ever reads whichever Board a session (see
# free_play_session.gd, reused as-is for the actual tile placement
# mechanics) is showing, to answer "is this row solved yet?"
class_name CrosswordPuzzle
extends RefCounted

# Which entry of CrosswordPuzzles.PUZZLES this is.
var puzzle_index: int

var clues: Array[String] = []
var target_words: Array[String] = []


# `puzzle_index` picks which entry of CrosswordPuzzles.PUZZLES to load —
# defaults to the first (and, for now, only) puzzle.
func _init(a_puzzle_index: int = 0) -> void:
	puzzle_index = a_puzzle_index
	for pair in CrosswordPuzzles.PUZZLES[puzzle_index]:
		clues.append(pair[0])
		target_words.append(pair[1])


# Whether `board`'s row currently spells this puzzle's target word for
# it. Every one of the row's 9 cells must be filled — a still-in-progress
# or wrong row isn't solved. Built by walking the row directly rather
# than through Board.word_at/word_columns_at: those model a single
# contiguous GROWN segment (and can report a short, partial word), while
# a puzzle needs an exact, whole-row match or nothing at all.
func is_row_solved(board: Board, row: int) -> bool:
	var word := ""
	for col in range(Board.COLUMNS):
		if board.is_empty(row, col):
			return false
		word += board.tile_at(row, col).current_letter()
	return word == target_words[row]


# One solved flag per row, in board-row order — see ClueListView.refresh,
# which colors each clue according to this.
func solved_rows(board: Board) -> Array[bool]:
	var solved: Array[bool] = []
	for row in range(Board.ROWS):
		solved.append(is_row_solved(board, row))
	return solved


# Whether the WHOLE puzzle is solved — every row matches its target.
func is_solved(board: Board) -> bool:
	for row in range(Board.ROWS):
		if not is_row_solved(board, row):
			return false
	return true
