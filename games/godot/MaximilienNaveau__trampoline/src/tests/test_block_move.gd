# Standalone checks for block_move.gd, runnable via:
#   godot4 --headless --path . --script tests/test_block_move.gd
extends SceneTree

var _failures := 0


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		print("FAIL: ", message)
		_failures += 1


func _initialize() -> void:
	_test_slide_within_a_row()
	_test_move_two_rows_keeping_their_shape()
	_test_refused_moves()

	if _failures == 0:
		print("\nAll checks passed.")
	else:
		print("\n", _failures, " check(s) failed.")
	quit(1 if _failures > 0 else 0)


# Places `word` from `col` of `row`, one plain-yellow tile per letter, and
# returns its cells.
func _place_word(board: Board, row: int, col: int, word: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i in range(word.length()):
		board.place(row, col + i, Tile.new(word[i], "Z", true))
		cells.append(Vector2i(col + i, row))
	return cells


func _test_slide_within_a_row() -> void:
	var board := Board.new()
	var cells := _place_word(board, 0, 2, "CAT")
	_check(BlockMove.move(board, cells, Vector2i(-2, 0)), "sliding left over itself succeeds")
	_check(board.word_at(0, 0) == "CAT", "the word reads the same at its new place")
	_check(board.is_empty(0, 3) and board.is_empty(0, 4), "the cells it left are empty")


func _test_move_two_rows_keeping_their_shape() -> void:
	var board := Board.new()
	var cells := _place_word(board, 1, 0, "LE")
	cells.append_array(_place_word(board, 2, 1, "UN"))
	_check(BlockMove.move(board, cells, Vector2i(3, 5)), "two rows move together")
	_check(board.word_at(6, 3) == "LE", "the first row lands 5 rows down, 3 across")
	_check(board.word_at(7, 4) == "UN", "...and the second keeps its place under it")
	_check(board.segments_in_row(1).is_empty(), "the old rows are empty")


func _test_refused_moves() -> void:
	var board := Board.new()
	var cells := _place_word(board, 4, 6, "CAT")
	_place_word(board, 5, 0, "DOG")
	_check(not BlockMove.can_move(board, cells, Vector2i(1, 0)), "off the board's edge")
	_check(not BlockMove.can_move(board, cells, Vector2i(-6, 1)), "onto another word's tiles")
	_check(BlockMove.can_move(board, cells, Vector2i(-6, 2)), "onto free cells is fine")
	var empty: Array[Vector2i] = [Vector2i(0, 0)]
	_check(not BlockMove.can_move(board, empty, Vector2i(1, 0)), "a selection with no tile")
