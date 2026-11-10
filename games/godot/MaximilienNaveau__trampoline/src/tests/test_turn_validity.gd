# Standalone checks for turn_validity.gd, runnable via:
#   godot4 --headless --path . --script tests/test_turn_validity.gd
extends SceneTree

var _failures := 0


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		print("FAIL: ", message)
		_failures += 1


func _initialize() -> void:
	_test_empty_this_turn_is_always_legal()
	_test_one_contiguous_word_is_legal()
	_test_extending_an_existing_word_is_legal()
	_test_two_disconnected_groups_in_one_row_is_flagged()
	_test_two_different_rows_is_flagged()
	_test_untouched_pre_existing_segment_is_ignored()

	if _failures == 0:
		print("\nAll checks passed.")
	else:
		print("\n", _failures, " check(s) failed.")
	quit(1 if _failures > 0 else 0)


func _test_empty_this_turn_is_always_legal() -> void:
	var board := Board.new()
	_check(
		TurnValidity.invalid_cells(board, []).is_empty(), "nothing placed yet is trivially legal"
	)


func _test_one_contiguous_word_is_legal() -> void:
	var board := Board.new()
	var tiles: Array[Tile] = []
	for i in range(3):
		var tile := Tile.new("CAT"[i], "Z", true)
		board.place(4, 2 + i, tile)
		tiles.append(tile)
	_check(
		TurnValidity.invalid_cells(board, tiles).is_empty(),
		"one contiguous word, all placed this turn, is legal"
	)


func _test_extending_an_existing_word_is_legal() -> void:
	var board := Board.new()
	# "AT" already on the board from an earlier turn — not in `placed_this_
	# turn`, so it shouldn't matter that it's there too.
	board.place(4, 3, Tile.new("A", "Z", true))
	board.place(4, 4, Tile.new("T", "Z", true))
	var new_tile := Tile.new("C", "Z", true)
	board.place(4, 2, new_tile)
	_check(
		TurnValidity.invalid_cells(board, [new_tile]).is_empty(),
		"extending an existing word with one new tile is legal"
	)


func _test_two_disconnected_groups_in_one_row_is_flagged() -> void:
	var board := Board.new()
	var first := Tile.new("A", "Z", true)
	var second := Tile.new("B", "Z", true)
	board.place(4, 0, first)
	board.place(4, 4, second)  # a gap of empty cells separates them

	var invalid := TurnValidity.invalid_cells(board, [first, second])
	_check(invalid.size() == 2, "both disconnected cells are reported")


func _test_two_different_rows_is_flagged() -> void:
	var board := Board.new()
	var first := Tile.new("A", "Z", true)
	var second := Tile.new("B", "Z", true)
	board.place(2, 4, first)
	board.place(5, 4, second)

	var invalid := TurnValidity.invalid_cells(board, [first, second])
	_check(invalid.size() == 2, "cells from both rows are reported")


# A row can hold two separate segments already (see board.gd — e.g. after
# tiles were moved there, see game_session.gd) — that's not
# THIS turn's doing, so it shouldn't get flagged just because a fresh tile
# extends one of them.
func _test_untouched_pre_existing_segment_is_ignored() -> void:
	var board := Board.new()
	board.place(4, 0, Tile.new("X", "Z", true))  # an untouched, pre-existing segment
	var new_tile := Tile.new("Y", "Z", true)
	board.place(4, 6, new_tile)  # this turn's own fresh word, far away in the same row
	_check(
		TurnValidity.invalid_cells(board, [new_tile]).is_empty(),
		"a pre-existing, untouched segment elsewhere in the row doesn't count against this turn"
	)
