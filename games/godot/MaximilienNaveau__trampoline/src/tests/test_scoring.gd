# Standalone checks for scoring.gd, runnable via:
#   godot4 --headless --path . --script tests/test_scoring.gd
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

	_test_word_score()
	_test_line_bonus()
	_test_board_bonus()
	_test_board_value_adds_up_words()
	_test_green_faces_and_perfect_board()

	if _failures == 0:
		print("\nAll checks passed.")
	else:
		print("\n", _failures, " check(s) failed.")
	quit(1 if _failures > 0 else 0)


# Places `word` starting at column 0 of `row`, one plain-yellow tile per
# letter.
func _place_word(board: Board, row: int, word: String) -> void:
	for col in range(word.length()):
		board.place(row, col, Tile.new(word[col], "Z", true))


func _test_word_score() -> void:
	var board := Board.new()

	_place_word(board, 0, "QSXWZY")
	_check(Scoring.board_value(board, _dictionary) == 0, "gibberish is worth nothing")

	# "maison" (6 letters, confirmed valid) with its 4th letter ('s') on a
	# green face: (1+2+3+4+5+6) - 5*1 = 16.
	var word := "maison"
	for col in range(word.length()):
		var tile: Tile
		if col == 3:
			tile = Tile.new("Z", "s", true)
			tile.flip()  # show the green "s" face instead of the dummy front
		else:
			tile = Tile.new(word[col], "Z", true)
		board.place(1, col, tile)
	_check(
		board.word_at(1, 0) == "maison",
		"sanity: the word still reads correctly with a green letter"
	)
	_check(
		Scoring.board_value(board, _dictionary) == 16,
		"1 + 2 + … + 6, minus the green-letter penalty"
	)


func _test_line_bonus() -> void:
	var board := Board.new()
	var scoring := Scoring.new()

	# A whole 9-letter word written in one turn, starting from an empty
	# row — a Scrabble-style "bingo" — entirely yellow: +50.
	_place_word(board, 2, "etudiante")
	_check(
		scoring.claim_line_bonus(board, _dictionary, 2) == 50,
		"a from-scratch 9-letter all-yellow word: scrabble bonus +50"
	)
	_check(
		scoring.claim_line_bonus(board, _dictionary, 2) == 0,
		"the same row's bonus can't be claimed twice"
	)

	# Same again, but with one letter forced green: the mixed-color
	# scrabble bonus, +30.
	_place_word(board, 3, "etudiante")
	var green_letter := Tile.new("Z", "i", true)
	board.remove(3, 4)
	board.place(3, 4, green_letter)
	green_letter.flip()
	_check(
		scoring.claim_line_bonus(board, _dictionary, 3) == 30,
		"a from-scratch 9-letter mixed-color word: scrabble bonus +30"
	)

	# 9 letters, but not a real word: no bonus, ever.
	_place_word(board, 4, "ZZZZZZZZZ")
	_check(
		scoring.claim_line_bonus(board, _dictionary, 4) == 0,
		"9 letters of gibberish earns no bonus"
	)

	# A valid word, but shorter than 9 letters: no bonus yet.
	_place_word(board, 5, "maison")
	_check(
		scoring.claim_line_bonus(board, _dictionary, 5) == 0,
		"a valid but not-yet-9-letter word earns no bonus"
	)

	# Completing a word that already had letters on the board before this
	# turn began: +10 only, never the bigger scrabble bonus, regardless of
	# color. First 5 letters of "etudiante" go down, THEN begin_turn snapshots
	# the row as already non-empty, THEN the remaining 4 letters complete it.
	var word9 := "etudiante"
	for col in range(5):
		board.place(6, col, Tile.new(word9[col], "Z", true))
	scoring.begin_turn(board)
	for col in range(5, 9):
		board.place(6, col, Tile.new(word9[col], "Z", true))
	_check(board.word_at(6, 0) == word9, "sanity: the word completed correctly")
	_check(
		scoring.claim_line_bonus(board, _dictionary, 6) == 10,
		"completing a word that already existed before this turn: +10 only"
	)


func _test_board_bonus() -> void:
	var board := Board.new()
	var scoring := Scoring.new()

	# Rows 0-11: a single real letter capped by a blank tile right after
	# it — "finished" per Board.is_row_finished without needing 9 letters.
	for row in range(12):
		board.place(row, 0, Tile.new("X", "Z", true))
		var shorten_tile := Tile.new("Y", "", true)
		board.place(row, 1, shorten_tile)
		shorten_tile.flip()

	_check(
		scoring.claim_board_bonus(board) == 0,
		"bonus not earned until every one of the 13 rows is finished"
	)

	# Row 12: a full 9 letters (doesn't need to be a real word for the
	# board itself to count as physically complete).
	_place_word(board, 12, "ZZZZZZZZZ")

	_check(
		scoring.claim_board_bonus(board) == 30, "whole-board bonus once all 13 rows are finished"
	)
	_check(scoring.claim_board_bonus(board) == 0, "the whole-board bonus can't be claimed twice")


# The worked example of doc/RULES.md: a 6-letter word ("etudia", the
# passé simple of "étudier", already valid) is worth 1+…+6 = 21; completed
# to 9 letters ("etudiante") it's worth 1+…+9 = 45, so whoever completed
# it earned 24 — and +10, not a from-scratch bonus. Two words on a board
# add up.
func _test_board_value_adds_up_words() -> void:
	var board := Board.new()
	var scoring := Scoring.new()

	var word9 := "etudiante"
	for col in range(6):
		board.place(7, col, Tile.new(word9[col], "Z", true))
	_check(Scoring.board_value(board, _dictionary) == 21, '"etudia" alone: 1+2+…+6')

	scoring.begin_turn(board)  # the row already has 6 letters as the turn starts
	for col in range(6, 9):
		board.place(7, col, Tile.new(word9[col], "Z", true))
	_check(board.word_at(7, 0) == word9, "sanity: the word completed correctly")
	_check(Scoring.board_value(board, _dictionary) == 45, '"etudiante": 1+2+…+9, so +24')
	_check(
		scoring.claim_line_bonus(board, _dictionary, 7) == 10,
		"completing a word already started earns the +10 bonus, not a scrabble bonus"
	)
	_place_word(board, 8, "maison")
	_check(Scoring.board_value(board, _dictionary) == 45 + 21, "...and with MAISON beside: +21")


func _test_green_faces_and_perfect_board() -> void:
	var board := Board.new()
	for row in range(Board.ROWS):
		_place_word(board, row, "ETUDIANTE")
	_check(Scoring.green_face_count(board) == 0, "an all-yellow board has no green face")
	_check(Scoring.is_perfect(board), "...and, finished, it's perfect")
	board.tile_at(5, 3).flip()  # its back face: a green "Z"
	_check(Scoring.green_face_count(board) == 1, "one tile flipped to green is counted")
	_check(not Scoring.is_perfect(board), "...and the board is no longer perfect")
	board.tile_at(5, 3).flip()
	board.remove(12, 8)
	_check(not Scoring.is_perfect(board), "an unfinished board isn't perfect, even all yellow")
