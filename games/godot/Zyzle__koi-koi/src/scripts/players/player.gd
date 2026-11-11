class_name Player
extends RefCounted

var captured_cards: Array[Card]
var hand: Array[Card]
var score: int

func make_move(game_state: GameState) -> MCTSAction:
	assert(false, "make_move must be implemented by subclasses")
	return null
