# Standalone checks for turn_manager.gd, runnable via:
#   godot4 --headless --path . --script tests/test_turn_manager.gd
extends SceneTree

var _failures := 0


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		print("FAIL: ", message)
		_failures += 1


func _initialize() -> void:
	_test_initial_state()
	_test_scores()
	_test_turn_advancement()
	_test_skips_finished_players()
	_test_lone_player_cycles_back_to_themselves()
	_test_game_completion_and_winner()
	_test_solo_play()
	_test_refill_hand()

	if _failures == 0:
		print("\nAll checks passed.")
	else:
		print("\n", _failures, " check(s) failed.")
	quit(1 if _failures > 0 else 0)


func _test_initial_state() -> void:
	var turns := TurnManager.new(3)
	_check(turns.current_player_id() == 0, "play starts with player 0")
	_check(turns.player_score(0) == 0, "scores start at 0")
	_check(not turns.is_player_finished(0), "nobody starts finished")
	_check(not turns.is_game_complete(), "the game isn't complete at the start")
	_check(turns.winner_id() == -1, "no winner before the game is complete")


func _test_scores() -> void:
	var turns := TurnManager.new(2)
	turns.set_player_score(0, 21)
	turns.add_to_player_score(0, 4)
	_check(turns.player_score(0) == 25, "set then add composes correctly")
	_check(turns.all_player_scores() == [25, 0], "all_player_scores reflects both players")


func _test_turn_advancement() -> void:
	var turns := TurnManager.new(3)
	turns.end_turn()
	_check(turns.current_player_id() == 1, "turn advances to player 1")
	turns.end_turn()
	_check(turns.current_player_id() == 2, "then to player 2")
	turns.end_turn()
	_check(turns.current_player_id() == 0, "then wraps back around to player 0")


func _test_skips_finished_players() -> void:
	var turns := TurnManager.new(3)
	turns.set_player_finished(1, true)
	_check(
		turns.current_player_id() == 0,
		"marking a non-current player finished doesn't end anyone's turn"
	)
	turns.end_turn()
	_check(turns.current_player_id() == 2, "ending player 0's turn skips the finished player 1")


func _test_lone_player_cycles_back_to_themselves() -> void:
	var turns := TurnManager.new(3)
	# Finishing player 0 (the current player) auto-advances to player 1.
	turns.set_player_finished(0, true)
	_check(turns.current_player_id() == 1, "sanity: finishing player 0 hands the turn to player 1")
	# Finishing player 2 (NOT the current player) doesn't move anyone.
	turns.set_player_finished(2, true)
	_check(
		turns.current_player_id() == 1,
		"sanity: finishing a non-current player doesn't end anyone's turn"
	)

	# Player 1 is now the only one left; ending their turn should hand
	# play right back to them, not complete the game.
	turns.end_turn()
	_check(turns.current_player_id() == 1, "the lone unfinished player keeps getting the turn")
	_check(
		not turns.is_game_complete(), "...and the game isn't complete while they're still playing"
	)


func _test_game_completion_and_winner() -> void:
	var turns := TurnManager.new(2)
	turns.set_player_score(0, 10)
	turns.set_player_score(1, 99)
	turns.set_player_finished(0, true)
	_check(not turns.is_game_complete(), "one player finishing isn't enough to complete the game")
	turns.set_player_finished(1, true)
	_check(turns.is_game_complete(), "the game completes once every player has finished")
	_check(turns.winner_id() == 1, "the higher scorer wins")


func _test_solo_play() -> void:
	var turns := TurnManager.new(1)
	turns.end_turn()
	_check(
		turns.current_player_id() == 0, "solo play always hands the turn back to the only player"
	)
	_check(not turns.is_game_complete(), "not complete until that player finishes")
	turns.set_player_finished(0, true)
	_check(turns.is_game_complete(), "finishing the only player completes the game")
	_check(turns.winner_id() == 0, "the only player is the winner")


func _test_refill_hand() -> void:
	var pool := TilePool.new()
	var bag := TileBag.new(pool)
	var turns := TurnManager.new(2)
	_check(turns.refill_hand(bag, 0).size() == 13, "an empty 2-player hand fills up to 13")
	_check(turns.refill_hand(bag, 0).is_empty(), "a full hand draws nothing")

	# Play 4 tiles away: the next refill only replaces those 4.
	for i in range(4):
		bag.consume(0, bag.hand(0)[0])
	_check(turns.refill_hand(bag, 0).size() == 4, "a refill only tops the hand back up to 13")
	_check(bag.hand(0).size() == 13, "...leaving exactly 13 in hand")

	# A hand over the limit (a tile picked back up off the board) draws
	# nothing, and isn't cut down either.
	bag.give_to_hand(0, Tile.new("A", "B", true))
	_check(turns.refill_hand(bag, 0).is_empty(), "a hand over the limit draws nothing")
	_check(bag.hand(0).size() == 14, "...and keeps its extra tile")

	# The bag running low limits the refill.
	var small_bag := TileBag.new(pool)
	small_bag.restore_state([Tile.new("A", "B", true), Tile.new("C", "D", true)] as Array[Tile], {})
	_check(turns.refill_hand(small_bag, 1).size() == 2, "a refill takes what's left in the bag")
