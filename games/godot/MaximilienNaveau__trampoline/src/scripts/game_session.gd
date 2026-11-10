# Ties every other piece together into an actual playable turn loop:
# Board + TileBag + TurnManager + Scoring + FrenchDictionary +
# BlockMove + WordChallenge. The equivalent of the Unity
# project's GameControllerMultiplayer, but for the current design (see
# doc/RULES.md and this project's other scripts for the individual rules).
class_name GameSession
extends RefCounted

# How long a game lasts (see doc/RULES.md's "End of the game"): one hour
# of actual play. Once it's up, the current round is finished — every
# player gets the same number of turns — and the game ends.
const TIME_LIMIT_SECONDS := 3600.0

var board: Board
var pool: TilePool
var bag: TileBag
var turns: TurnManager
var scoring: Scoring
var dictionary: FrenchDictionary

# Seconds of actual play so far — only counted while someone is really
# playing (the caller decides, see main.gd's `_process`), and saved with
# the game (see save_game.gd).
var play_time := 0.0
# Whether the game ended because the hour ran out (see `end_turn`) —
# saved with the game too.
var ended_by_time := false
# How the board and the current player's hand stood when the current
# turn began (see turn_start.gd): the turn earns the board's change in
# worth (see `turn_points`), must fill again the cells that held a letter
# (see `emptied_cells`), and can be started over (see `reset_turn`). Taken
# again whenever a turn begins, and by save_game.gd once a game is loaded
# (a game is only ever saved between turns).
var turn_start: TurnStart
# What each player entered as their name, in player order — may be
# shorter than the number of players, or hold empty names (main.gd shows
# "Joueur N" for those). Saved with the game.
var player_names: Array[String] = []

# Tiles the current player has put down from their hand since their turn
# began. What `invalid_cells()` below checks against: a turn's new letters
# go on one row, in one connected group (see doc/RULES.md) — a property of
# ALL of this turn's tiles together, not any single placement. Tiles
# already on the board and only moved don't count. Reset every
# `_start_turn()`.
var _placed_this_turn: Array[Tile] = []

# Tiles in the current player's hand they've chosen to give back to the
# bag when their turn ends, to draw others instead (see
# `set_marked_for_discard`), in the order they were marked.
# Reset every `_start_turn()`.
var _marked_for_discard: Array[Tile] = []


# `dictionary` can be injected (e.g. a test reusing one already-loaded
# instance across several sessions rather than reading the ~421,000-word
# list again) — defaults to loading a fresh one.
func _init(number_of_players: int, a_dictionary: FrenchDictionary = null) -> void:
	board = Board.new()
	# Kept as its own field (not just handed to TileBag and forgotten) so
	# save_game.gd has one canonical, indexable list of all 117 tiles to
	# save/restore flip-state against, regardless of which of them are
	# currently on the board, in a hand, or still undrawn.
	pool = TilePool.new()
	bag = TileBag.new(pool)
	turns = TurnManager.new(number_of_players)
	scoring = Scoring.new()
	dictionary = a_dictionary if a_dictionary != null else FrenchDictionary.new()

	# Everyone is dealt a full hand up front, like a real board game — not
	# just whoever happens to go first. Their first turn's refill then
	# draws nothing, the hand being full already (see `_start_turn`).
	for player_id in range(number_of_players):
		turns.refill_hand(bag, player_id)
	_note_turn_start()


# Whether the game has ended, either way (see turn_manager.gd's header
# comment): every player exhausted, or the board itself fully settled.
func is_game_over() -> bool:
	return turns.is_game_complete() or board.is_complete() or ended_by_time


# Counts `seconds` more of actual play towards the hour (see
# TIME_LIMIT_SECONDS). Does nothing once the game is over.
func add_play_time(seconds: float) -> void:
	if not is_game_over():
		play_time += seconds


# Seconds of play left before the last round starts (0 once it has).
func remaining_time() -> float:
	return maxf(TIME_LIMIT_SECONDS - play_time, 0.0)


# Whether the hour is up and the current round is the last one.
func is_last_round() -> bool:
	return play_time >= TIME_LIMIT_SECONDS and not is_game_over()


# Whoever won once the game is over (empty while it's still in progress),
# in player order: the highest score; on equal scores, whoever has the
# fewest tiles left in hand; if that's equal too, they all win (see
# doc/RULES.md's "End of the game"). Doesn't reuse TurnManager.winner_id()
# — that one only looks at TurnManager's OWN "everyone exhausted" flag,
# which stays false if the game ended another way.
func winner_ids() -> Array[int]:
	var winners: Array[int] = []
	if not is_game_over():
		return winners
	for player_id in range(turns.number_of_players):
		var order := 1 if winners.is_empty() else _compare_players(player_id, winners[0])
		if order > 0:
			winners.clear()
		if order >= 0:
			winners.append(player_id)
	return winners


# Whether `a` finished ahead of `b` (1), behind (-1), or level (0): by
# score, then by fewest tiles left in hand.
func _compare_players(a: int, b: int) -> int:
	var score_a := turns.player_score(a)
	var score_b := turns.player_score(b)
	if score_a != score_b:
		return 1 if score_a > score_b else -1
	var tiles_a := bag.hand(a).size()
	var tiles_b := bag.hand(b).size()
	if tiles_a != tiles_b:
		return 1 if tiles_a < tiles_b else -1
	return 0


# Places one of the current player's own hand tiles at (row, col). On an
# occupied cell, the two swap: the tile there goes into the player's hand
# (the 2015 rules let a player swap letters between their hand and the
# board). Returns false and does nothing if `tile` isn't in the current
# player's hand. Deliberately doesn't check where it lands —
# `can_end_turn()` below is what catches an illegal result, so the UI can
# show the player what's wrong (see `invalid_cells()`) rather than just
# silently refusing to let a tile land somewhere.
func place_tile(row: int, col: int, tile: Tile) -> bool:
	var player_id := turns.current_player_id()
	if not bag.hand(player_id).has(tile):
		return false
	var displaced := board.remove(row, col)
	if displaced != null:
		_take_into_hand(displaced)
	board.place(row, col, tile)
	bag.consume(player_id, tile)
	_placed_this_turn.append(tile)
	# A tile on the board is no longer in hand to give back.
	_marked_for_discard.erase(tile)
	return true


# Marks `tile`, in the current player's hand, to be given back to the bag
# when their turn ends (`marked` true), or changes their mind (false).
# Their next turn then refills their hand with other tiles (see
# `_start_turn`). Returns false and does nothing if the tile isn't in the
# current player's hand.
func set_marked_for_discard(tile: Tile, marked: bool) -> bool:
	if not bag.hand(turns.current_player_id()).has(tile):
		return false
	_marked_for_discard.erase(tile)
	if marked:
		_marked_for_discard.append(tile)
	return true


# Every tile currently marked to be given back, in the order marked — a
# copy, so the caller can't change the marks behind this class's back.
func marked_for_discard() -> Array[Tile]:
	return _marked_for_discard.duplicate()


# Picks the tile at (row, col) up into the CURRENT player's hand — any
# tile, whoever put it there: during a turn, every tile on the board may
# move (see doc/RULES.md); the turn just can't end with a cell emptied
# that held a letter when it began (see `emptied_cells`). Returns null and
# does nothing if the cell is empty.
func remove_tile(row: int, col: int) -> Tile:
	var tile := board.remove(row, col)
	if tile != null:
		_take_into_hand(tile)
	return tile


# Moves the tile at (from_row, from_col) to (to_row, to_col) — any tile,
# like `remove_tile`. On an occupied cell, the tile there goes into the
# current player's hand (a swap, as in `place_tile`). Returns false and
# does nothing if there's no tile to move, or it's dropped where it is.
func move_tile(from_row: int, from_col: int, to_row: int, to_col: int) -> bool:
	if (
		board.is_empty(from_row, from_col)
		or Vector2i(from_col, from_row) == Vector2i(to_col, to_row)
	):
		return false
	var displaced := board.remove(to_row, to_col)
	if displaced != null:
		_take_into_hand(displaced)
	board.place(to_row, to_col, board.remove(from_row, from_col))
	return true


# Moves the tiles in `cells` (`Vector2i(col, row)`) together by `offset`
# columns and rows — see block_move.gd. Returns false and does nothing if
# the block would land off the board or on other tiles.
func move_tiles(cells: Array[Vector2i], offset: Vector2i) -> bool:
	return BlockMove.move(board, cells, offset)


# `tile`, just taken off the board, goes into the current player's hand.
func _take_into_hand(tile: Tile) -> void:
	bag.give_to_hand(turns.current_player_id(), tile)
	# Back in hand, it no longer counts as put down this turn.
	_placed_this_turn.erase(tile)


# Puts the board and the current player's hand back as they were when
# the turn began (see `turn_start`): every tile in its cell or the
# hand, showing the same face, nothing marked to give back.
func reset_turn() -> void:
	turn_start.restore(board, bag.hand(turns.current_player_id()))
	_placed_this_turn.clear()
	_marked_for_discard.clear()


# Flips the tile at (row, col) in place, revealing its other face — see
# doc/RULES.md's "trampoline" mechanic: any tile on the board may be
# flipped. Scoring doesn't need telling about this separately: `Scoring`
# always reads a tile's CURRENT face live (see scoring.gd), so a flipped
# tile's new letter/color is simply picked up the next time the board's
# worth is read. Returns false and does nothing if the cell is empty.
func flip_tile(row: int, col: int) -> bool:
	var tile := board.tile_at(row, col)
	if tile == null:
		return false
	tile.flip()
	return true


# Whether the current player may end their turn right now: blocked while
# any word on the board is invalid (see word_challenge.gd), this turn's
# new letters don't form one legal single-row, single-word turn (see
# turn_validity.gd), or a cell that held a letter when the turn began is
# empty (see `emptied_cells`).
func can_end_turn() -> bool:
	return (
		WordChallenge.can_end_turn(board, dictionary)
		and invalid_cells().is_empty()
		and emptied_cells().is_empty()
	)


# The cells (`Vector2i(col, row)`) that held a letter when the turn began
# and are empty now: the 2015 rules' "aucune case occupée avant une
# intervention ne doit être vidée de son contenu" — tiles may move, but
# the board never loses a letter.
func emptied_cells() -> Array[Vector2i]:
	var emptied: Array[Vector2i] = []
	for cell in turn_start.cells_to_keep_filled:
		if board.is_empty(cell.y, cell.x):
			emptied.append(cell)
	return emptied


# The word(s) currently blocking `can_end_turn()` above, as a list of
# `{row, col, word}` dictionaries (see word_challenge.gd's
# `find_invalid_words`) — lets the UI explain WHY `end_turn()` just
# refused, rather than only reporting that it did.
func invalid_words() -> Array:
	return WordChallenge.find_invalid_words(board, dictionary)


# The cell(s) currently blocking `can_end_turn()` for the OTHER reason (see
# turn_validity.gd) — this turn's own placements spread across more than
# one row, or split into more than one disconnected group of letters.
# Empty if this turn, so far, is legal on this front (independent of
# whether a word elsewhere on the board also happens to be invalid).
func invalid_cells() -> Array:
	return TurnValidity.invalid_cells(board, _placed_this_turn)


# What the current player's score would change by, from the words alone,
# if their turn ended right now: how much their turn changed the board's
# worth (see scoring.gd) — negative if, say, they flipped a letter to
# green or broke a word. Bonuses come separately, see `turn_bonuses`.
# Changes nothing.
func turn_points() -> int:
	return Scoring.board_value(board, dictionary) - turn_start.value


# The bonuses the current player would win if their turn ended right now
# (see scoring.gd: +10 a line, +30/+50 a full word, +30 the board), one
# entry each, rows top to bottom then the board's. Changes nothing.
func turn_bonuses() -> Array[int]:
	var bonuses: Array[int] = []
	for row in range(Board.ROWS):
		var bonus := scoring.line_bonus(board, dictionary, row)
		if bonus > 0:
			bonuses.append(bonus)
	if scoring.board_bonus(board) > 0:
		bonuses.append(scoring.board_bonus(board))
	return bonuses


# Ends the current player's turn: adds what it earned (see `turn_points`)
# and any bonuses just won to their score, marks the player finished if
# they're out of tiles for good, and starts the next turn if the game
# isn't over.
# Returns false and does nothing if `can_end_turn()` refuses.
func end_turn() -> bool:
	if not can_end_turn():
		return false

	var player_id := turns.current_player_id()
	var points := turn_points()
	for row in range(Board.ROWS):
		points += scoring.claim_line_bonus(board, dictionary, row)
	points += scoring.claim_board_bonus(board)
	turns.set_player_score(player_id, turns.player_score(player_id) + points)

	# The tiles this player chose to give back go into the bag now; their
	# hand is refilled at the start of their next turn, so the next player
	# never sees the new tiles.
	for tile in _marked_for_discard:
		bag.return_tile(player_id, tile)
	_marked_for_discard.clear()

	if bag.hand(player_id).is_empty() and bag.remaining_count() == 0:
		turns.set_player_finished(player_id, true)  # advances the turn on its own
	else:
		turns.end_turn()

	# Once the hour is up, the game ends when the round does: when play
	# wraps back around (the next player comes before, or is, this one).
	if play_time >= TIME_LIMIT_SECONDS and turns.current_player_id() <= player_id:
		ended_by_time = true

	if not is_game_over():
		_start_turn()
	return true


func _start_turn() -> void:
	turns.refill_hand(bag, turns.current_player_id())
	_note_turn_start()


# Notes down how the board and hand stand as a turn begins (see
# `turn_start`), and, for the bonuses, how full each row is (see
# scoring.gd's `begin_turn`).
func _note_turn_start() -> void:
	turn_start = TurnStart.new(board, bag.hand(turns.current_player_id()), dictionary)
	scoring.begin_turn(board)
	_placed_this_turn.clear()
	_marked_for_discard.clear()
