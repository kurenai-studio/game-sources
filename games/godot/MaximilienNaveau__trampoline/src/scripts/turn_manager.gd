# Per-player state (score, finished status) and turn advancement for
# turn-based play (1-4 players — see doc/RULES.md). Ported from the Unity
# project's PlayerManager.cs + TurnManager.cs, merged into one class since
# here they're not two separate scene components, just plain state one
# object can hold.
#
# Deliberately left out: PlayerManager.cs's per-player display colors —
# that's rendering, not game state, and belongs in a future view layer
# instead (see the project's "separate logic from graphics" rule).
#
# "Finished" means something different here than in the Unity source.
# There, each player owned their own rows and finished by personally
# completing 13 words. This board is fully collaborative instead — any
# player can extend any row, so there's no per-player completion goal to
# track. Here, "finished" means EXHAUSTED: this player has no tiles left
# in hand and the bag is empty, so there's nothing left to refill their
# hand with (see `refill_hand`) and they should be skipped in the turn
# rotation. This class doesn't detect that itself — the caller (see
# game_session.gd's `end_turn`) decides when to call `set_player_finished`
# based on hand + bag state.
#
# Consequently, `is_game_complete()` only covers ONE of the two ways this
# game actually ends: everyone being simultaneously exhausted (a forced
# stalemate, board possibly still incomplete). The other way — the board
# itself becoming fully settled (see `Board.is_complete`) — has nothing to
# do with players and isn't tracked here at all. A real game-over check
# needs to OR both conditions together.
class_name TurnManager
extends RefCounted

var number_of_players: int

var _current_player_id := 0
var _scores: Array[int] = []
var _finished: Array[bool] = []
var _game_complete := false


func _init(players: int) -> void:
	assert(players >= 1 and players <= 4, "Trampoline supports 1-4 players")
	number_of_players = players
	for i in range(players):
		_scores.append(0)
		_finished.append(false)


func current_player_id() -> int:
	return _current_player_id


func player_score(player_id: int) -> int:
	return _scores[player_id]


func set_player_score(player_id: int, score: int) -> void:
	_scores[player_id] = score


func add_to_player_score(player_id: int, points: int) -> void:
	_scores[player_id] += points


func all_player_scores() -> Array[int]:
	return _scores.duplicate()


func is_player_finished(player_id: int) -> bool:
	return _finished[player_id]


# Marks a player as finished (or not). If this is the CURRENT player
# finishing, their turn ends immediately, same as calling `end_turn()`.
func set_player_finished(player_id: int, finished: bool) -> void:
	_finished[player_id] = finished
	if finished and player_id == _current_player_id:
		end_turn()


func is_game_complete() -> bool:
	return _game_complete


# The player with the highest score, or -1 if the game isn't complete yet.
func winner_id() -> int:
	if not _game_complete:
		return -1
	var best := 0
	for player_id in range(1, number_of_players):
		if _scores[player_id] > _scores[best]:
			best = player_id
	return best


# Ends the current player's turn and hands play to the next player who
# hasn't finished yet, wrapping around as needed. If every player turns
# out to be finished once the search wraps all the way back to whoever
# was playing, the game is complete instead (if only ONE player remains
# unfinished, this correctly hands the turn right back to them — they
# just keep playing until they finish too).
func end_turn() -> void:
	var start := _current_player_id
	var next := start
	while true:
		next = (next + 1) % number_of_players
		if next == start:
			_current_player_id = next
			if _all_finished():
				_game_complete = true
			return
		if not _finished[next]:
			_current_player_id = next
			return


func _all_finished() -> bool:
	for finished in _finished:
		if not finished:
			return false
	return true


# Tops `player_id`'s hand back up to the most they may hold (see
# draw_plan.gd) from `bag`, as far as the bag allows. Returns the tiles
# drawn — none if the hand is already full (a player can hold more than
# that after picking a tile back up off the board, see game_session.gd's
# `remove_tile`; they then simply draw nothing).
func refill_hand(bag: TileBag, player_id: int) -> Array[Tile]:
	var missing := DrawPlan.hand_size(number_of_players) - bag.hand(player_id).size()
	return bag.draw(player_id, maxi(missing, 0))


# Exports every bit of this class's state — see save_game.gd. Plain data
# only (no Tile references, unlike TileBag/Scoring), so this round-trips
# through JSON without any tile-identity bookkeeping to worry about.
func export_state() -> Dictionary:
	return {
		"current_player_id": _current_player_id,
		"scores": _scores,
		"finished": _finished,
		"game_complete": _game_complete,
	}


# Overwrites this class's entire state from `data` (see `export_state`).
# JSON round-trips every number as a float, so each one is explicitly
# cast back to `int` here — GDScript's typed `Array[int]` fields would
# otherwise refuse a float element.
func restore_state(data: Dictionary) -> void:
	_current_player_id = int(data["current_player_id"])
	_scores.clear()
	for score in data["scores"]:
		_scores.append(int(score))
	_finished.clear()
	for finished in data["finished"]:
		_finished.append(finished)
	_game_complete = data["game_complete"]
