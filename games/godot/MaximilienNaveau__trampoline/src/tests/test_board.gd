# Standalone checks for board.gd, runnable via:
#   godot4 --headless --path . --script tests/test_board.gd
# See tests/test_tiles.gd for why this isn't a test-framework addon.
#
# Board is deliberately unrestricted (see board.gd's header comment) — what
# a turn may do is tested with GameSession, in tests/test_game_session.gd.
extends SceneTree

var _failures := 0


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		print("FAIL: ", message)
		_failures += 1


func _initialize() -> void:
	_test_empty_board()
	_test_place_and_remove()
	_test_word_at()
	_test_rows_are_independent()
	_test_is_row_finished()
	_test_multiple_segments_per_row()
	_test_is_complete()

	if _failures == 0:
		print("\nAll checks passed.")
	else:
		print("\n", _failures, " check(s) failed.")
	quit(1 if _failures > 0 else 0)


func _test_empty_board() -> void:
	var board := Board.new()
	_check(board.leftmost_filled(0) == -1, "empty row has no leftmost filled cell")
	_check(board.rightmost_filled(0) == -1, "empty row has no rightmost filled cell")
	_check(board.word_at(0, 0) == "", "empty row spells the empty string")
	_check(board.is_empty(0, 4), "an untouched cell is empty")
	_check(board.segments_in_row(0) == [], "an empty row has no segments")


func _test_place_and_remove() -> void:
	var board := Board.new()
	_check(board.place(0, 4, Tile.new("C", "Z", true)), "placing into an empty cell succeeds")
	_check(not board.place(0, 4, Tile.new("A", "Z", true)), "placing into an occupied cell fails")

	# Board itself has no adjacency rule: placing anywhere else empty,
	# even leaving a gap, is allowed here.
	var far_away_ok := board.place(0, 7, Tile.new("A", "Z", true))
	_check(far_away_ok, "placing anywhere else empty succeeds (no adjacency rule here)")

	var removed := board.remove(0, 4)
	var removed_was_c := removed != null and removed.current_letter() == "C"
	_check(removed_was_c, "remove returns the tile that was there")
	_check(board.is_empty(0, 4), "cell is empty again after removal")
	_check(board.remove(0, 4) == null, "removing an already-empty cell returns null")

	# Board places no restriction on what can be removed either — a
	# real-letter tile comes right back out (what a turn must leave behind
	# is GameSession's business, see its `emptied_cells`).
	board.place(0, 4, Tile.new("H", "Z", true))
	var removed_letter := board.remove(0, 4)
	var real_letter_removable := removed_letter != null and removed_letter.current_letter() == "H"
	_check(real_letter_removable, "a real-letter tile can be removed from the raw board")


func _test_word_at() -> void:
	var board := Board.new()
	board.place(2, 2, Tile.new("C", "Z", true))
	board.place(2, 3, Tile.new("A", "Z", true))
	board.place(2, 4, Tile.new("T", "Z", true))
	_check(board.word_at(2, 2) == "CAT", "word reads correctly, anchored at its first column")
	_check(board.word_at(2, 3) == "CAT", "...or anchored anywhere inside it")

	# Flipping is the Tile's own job (see tile.gd), not the board's — call
	# it directly on the tile, not through Board.
	var shorten_tile := Tile.new("E", "", true)
	board.place(2, 5, shorten_tile)
	shorten_tile.flip()  # show the blank back face
	_check(board.word_at(2, 2) == "CAT", "a blank-showing tile truncates the word, not included")
	_check(board.rightmost_filled(2) == 5, "but the blank tile's cell still counts as occupied")
	_check(
		board.word_columns_at(2, 2) == [2, 3, 4],
		"word_columns_at lists exactly the word's own columns"
	)


func _test_rows_are_independent() -> void:
	var board := Board.new()
	board.place(4, 0, Tile.new("X", "Z", true))
	_check(board.word_at(5, 0) == "", "placing in one row leaves another row untouched")
	_check(board.leftmost_filled(5) == -1, "an untouched row still reports no filled cells")


func _test_is_row_finished() -> void:
	var board := Board.new()
	_check(not board.is_row_finished(0), "an empty row is not finished")

	board.place(0, 0, Tile.new("X", "Z", true))
	_check(not board.is_row_finished(0), "a single real letter, uncapped, is not finished")

	var shorten_tile := Tile.new("Y", "", true)
	board.place(0, 1, shorten_tile)
	_check(
		not board.is_row_finished(0),
		"...not finished either while the capping tile still shows a letter"
	)
	shorten_tile.flip()
	_check(board.is_row_finished(0), "...but IS finished once that tile shows blank")

	for col in range(Board.COLUMNS):
		board.place(1, col, Tile.new("Z", "Z", true))
	_check(
		board.is_row_finished(1), "a row with all 9 cells filled is finished, capping tile or not"
	)

	board.place(2, 8, Tile.new("Z", "Z", true))
	_check(
		not board.is_row_finished(2),
		"jammed against the edge without reaching 9 or a blank cap: not finished"
	)


func _test_multiple_segments_per_row() -> void:
	var board := Board.new()
	for i in range(3):
		board.place(3, i, Tile.new("CAT"[i], "Z", true))
	for i in range(3):
		board.place(3, 5 + i, Tile.new("DOG"[i], "Z", true))

	_check(
		board.segments_in_row(3) == [[0, 2], [5, 7]], "two separate words show up as two segments"
	)
	_check(board.word_at(3, 0) == "CAT", "the first word reads correctly")
	_check(board.word_at(3, 6) == "DOG", "...and the second, independently")
	_check(board.word_at(3, 3) == "", "the gap between them isn't part of either word")
	_check(
		not board.is_row_finished(3),
		"a row split across two separate words isn't finished, even if neither is growable further"
	)


func _test_is_complete() -> void:
	var board := Board.new()
	_check(not board.is_complete(), "a fresh board is not complete")

	for row in range(12):
		board.place(row, 0, Tile.new("X", "Z", true))
		var shorten_tile := Tile.new("Y", "", true)
		board.place(row, 1, shorten_tile)
		shorten_tile.flip()
	_check(not board.is_complete(), "not complete until every one of the 13 rows is finished")

	for col in range(Board.COLUMNS):
		board.place(12, col, Tile.new("Z", "Z", true))
	_check(board.is_complete(), "complete once the last row is finished too")
