# Standalone checks for word_challenge.gd, runnable via:
#   godot4 --headless --path . --script tests/test_word_challenge.gd
extends SceneTree

var _failures := 0
var _dictionary: FrenchDictionary


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		print("FAIL: ", message)
		_failures += 1


func _initialize() -> void:
	_dictionary = FrenchDictionary.new()

	_test_empty_board_is_clean()
	_test_valid_word_allows_ending_turn()
	_test_invalid_word_blocks_ending_turn()
	_test_only_the_bad_segment_is_reported()
	_test_blank_capped_valid_word_is_fine()

	if _failures == 0:
		print("\nAll checks passed.")
	else:
		print("\n", _failures, " check(s) failed.")
	quit(1 if _failures > 0 else 0)


func _place_word(board: Board, row: int, col: int, word: String) -> void:
	for i in range(word.length()):
		board.place(row, col + i, Tile.new(word[i], "Z", true))


func _test_empty_board_is_clean() -> void:
	var board := Board.new()
	_check(
		WordChallenge.find_invalid_words(board, _dictionary) == [],
		"an empty board has no bad words"
	)
	_check(WordChallenge.can_end_turn(board, _dictionary), "...so ending a turn is always allowed")


func _test_valid_word_allows_ending_turn() -> void:
	var board := Board.new()
	_place_word(board, 0, 0, "maison")
	_check(
		WordChallenge.can_end_turn(board, _dictionary), "a real word doesn't block ending the turn"
	)


func _test_invalid_word_blocks_ending_turn() -> void:
	var board := Board.new()
	_place_word(board, 1, 2, "QSXWZY")
	_check(
		not WordChallenge.can_end_turn(board, _dictionary),
		"gibberish on the board blocks ending the turn"
	)

	var invalid := WordChallenge.find_invalid_words(board, _dictionary)
	_check(invalid.size() == 1, "exactly one bad word is reported")
	_check(invalid[0]["row"] == 1, "...at the right row")
	_check(invalid[0]["col"] == 2, "...at the right column")
	_check(invalid[0]["word"] == "QSXWZY", "...with the word itself included")


func _test_only_the_bad_segment_is_reported() -> void:
	var board := Board.new()
	_place_word(board, 2, 0, "maison")  # valid
	_place_word(board, 2, 7, "ZZ")  # invalid, unrelated segment in the same row

	var invalid := WordChallenge.find_invalid_words(board, _dictionary)
	_check(invalid.size() == 1, "only the bad segment is flagged, not the good one alongside it")
	_check(invalid[0]["word"] == "ZZ", "...specifically the gibberish one")


func _test_blank_capped_valid_word_is_fine() -> void:
	var board := Board.new()
	_place_word(board, 3, 0, "maison")
	var shorten_tile := Tile.new("E", "", true)
	board.place(3, 6, shorten_tile)
	shorten_tile.flip()
	_check(
		WordChallenge.can_end_turn(board, _dictionary),
		"a valid word capped by a blank tile doesn't block ending the turn"
	)
