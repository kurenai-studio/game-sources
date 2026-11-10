# Standalone checks for crossword_puzzle.gd, runnable via:
#   godot4 --headless --path . --script tests/test_crossword_puzzle.gd
extends SceneTree

var _failures := 0


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		print("FAIL: ", message)
		_failures += 1


func _initialize() -> void:
	_test_fresh_puzzle_has_no_solved_rows()
	_test_row_solved_when_target_word_placed()
	_test_row_not_solved_when_partially_filled()
	_test_row_not_solved_when_wrong_word()
	_test_is_solved_only_true_when_every_row_matches()
	_test_puzzle_index_selects_the_right_puzzle()

	if _failures == 0:
		print("\nAll checks passed.")
	else:
		print("\n", _failures, " check(s) failed.")
	quit(1 if _failures > 0 else 0)


# Places `word` (already 9 letters) across `row`, one tile per column.
func _place_word(board: Board, row: int, word: String) -> void:
	for col in range(word.length()):
		board.place(row, col, Tile.new(word[col], "Z", true))


func _test_fresh_puzzle_has_no_solved_rows() -> void:
	var puzzle := CrosswordPuzzle.new()
	var board := Board.new()
	_check(not puzzle.is_row_solved(board, 0), "an empty row isn't solved")
	_check(not puzzle.solved_rows(board).has(true), "no row is solved on a fresh board")
	_check(not puzzle.is_solved(board), "a fresh board isn't a solved puzzle")


func _test_row_solved_when_target_word_placed() -> void:
	var puzzle := CrosswordPuzzle.new()
	var board := Board.new()
	_place_word(board, 0, puzzle.target_words[0])
	_check(puzzle.is_row_solved(board, 0), "placing the exact target word solves that row")
	_check(not puzzle.is_row_solved(board, 1), "...without affecting an untouched row")


func _test_row_not_solved_when_partially_filled() -> void:
	var puzzle := CrosswordPuzzle.new()
	var board := Board.new()
	var word: String = puzzle.target_words[0]
	for col in range(word.length() - 1):  # leave the last cell empty
		board.place(0, col, Tile.new(word[col], "Z", true))
	_check(not puzzle.is_row_solved(board, 0), "a still-in-progress row isn't solved")


func _test_row_not_solved_when_wrong_word() -> void:
	var puzzle := CrosswordPuzzle.new()
	var board := Board.new()
	_place_word(board, 0, "ABCDEFGHI")
	_check(not puzzle.is_row_solved(board, 0), "a fully-filled but wrong word isn't solved")


func _test_is_solved_only_true_when_every_row_matches() -> void:
	var puzzle := CrosswordPuzzle.new()
	var board := Board.new()
	for row in range(Board.ROWS - 1):
		_place_word(board, row, puzzle.target_words[row])
	_check(not puzzle.is_solved(board), "not solved while even one row is still wrong/empty")

	_place_word(board, Board.ROWS - 1, puzzle.target_words[Board.ROWS - 1])
	_check(puzzle.is_solved(board), "solved once every row matches its target")


# Confirms CrosswordPuzzles.PUZZLES holds all 10 usable puzzles (see
# crossword_puzzles.gd), and that `puzzle_index` actually picks between
# them rather than always loading puzzle 1.
func _test_puzzle_index_selects_the_right_puzzle() -> void:
	_check(CrosswordPuzzles.PUZZLES.size() == 10, "all 10 usable puzzles are present")
	var puzzle_1 := CrosswordPuzzle.new(0)
	var puzzle_2 := CrosswordPuzzle.new(1)
	_check(
		puzzle_1.target_words[0] != puzzle_2.target_words[0],
		"different puzzle indices load genuinely different data"
	)
	_check(puzzle_2.target_words[0] == "STABILITE", "puzzle_index 1 loads puzzle 2's own data")
