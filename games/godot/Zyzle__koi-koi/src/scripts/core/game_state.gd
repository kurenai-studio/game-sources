class_name GameState
extends Resource

enum Phase {
	NONE,
	START,
	DEAL,
	PLAY,
	ROUND_END
}

const PHASE_MAP = {
	Phase.NONE: "None",
	Phase.START: "Start",
	Phase.DEAL: "Deal",
	Phase.PLAY: "Play",
	Phase.ROUND_END: "Round End"
}

enum Turn {
	NONE,
	PLAYER,
	OPPONENT
}

const TURN_MAP = {
	Turn.NONE: "None",
	Turn.PLAYER: "Player",
	Turn.OPPONENT: "Opponent"
}

enum TurnPhase {
	NONE, # 0
	HAND_FIELD_CAPTURE, # 1
	PLAY_CARD_TO_FIELD, # 2
	FLIP_DECK_CARD, # 3
	DECK_FIELD_CAPTURE, # 4
	SCORE, # 5
	TURN_END # 6
}

const TURN_PHASE_MAP = {
	TurnPhase.NONE: "None",
	TurnPhase.HAND_FIELD_CAPTURE: "Hand Field Capture",
	TurnPhase.PLAY_CARD_TO_FIELD: "Play Card to Field",
	TurnPhase.FLIP_DECK_CARD: "Flip Deck Card",
	TurnPhase.DECK_FIELD_CAPTURE: "Deck Field Capture",
	TurnPhase.SCORE: "Score",
	TurnPhase.TURN_END: "Turn End"
}

# Private variables for properties with setters
var _current_phase: Phase
var _current_turn: Turn
var _current_turn_phase: TurnPhase
var _players_chosen_card: Card

# Properties with automatic signal emission
var current_phase: Phase:
	get: return _current_phase
	set(value):
		if _current_phase != value:
			_current_phase = value
			phase_changed.emit(value)

var current_turn: Turn:
	get: return _current_turn
	set(value):
		if _current_turn != value:
			_current_turn = value
			turn_changed.emit(value)

var current_turn_phase: TurnPhase:
	get: return _current_turn_phase
	set(value):
		if _current_turn_phase != value:
			_current_turn_phase = value
			turn_phase_changed.emit(value)

var players_chosen_card: Card:
	get: return _players_chosen_card
	set(value):
		_players_chosen_card = value
		player_selected_card.emit(value)

# Regular properties
var round_number: int = 0
var player_hand: Array[Card]
var opponent_hand: Array[Card]
var field_cards: Array[Card]
var deck: Array[Card]
var player_captured: Array[Card]
var opponent_captured: Array[Card]
var player_score: Scoring.ScoreResult = Scoring.ScoreResult.new()
var opponent_score: Scoring.ScoreResult = Scoring.ScoreResult.new()
var rounds_to_play: int
## Tracks wins for each round, 0 for no win, 1 for player win, 2 for opponent win
var round_wins: Array[int]
var player_running_score: int = 0
var opponent_running_score: int = 0

# Game Flow Signals
signal phase_changed(new_phase: Phase)
signal turn_changed(new_turn: Turn)
signal turn_phase_changed(new_turn_phase: TurnPhase)
signal player_selected_card(card: Card)
signal show_player_koi_koi()
signal reset_game()
signal update_wins(wins: Array[int])

# Model Events (generic)
signal card_moved(card: Card, from_to_location: String, move_also: Card)
signal deck_initialized(deck: Array[Card])
signal capture_numbers_updated(for_turn: Turn, cards: Array[Card])


func _arrays_have_same_content(arr1: Array, arr2: Array) -> bool:
	if arr1.size() != arr2.size():
		return false
	
	var temp_arr2 = arr2.duplicate()
	for item in arr1:
		if temp_arr2.has(item):
			temp_arr2.erase(item)
		else:
			return false
	
	return true


func _reset_game_for_new_round() -> void:
	# Clear hands, field, captured cards, scores
	player_hand.clear()
	opponent_hand.clear()
	field_cards.clear()
	player_captured.clear()
	opponent_captured.clear()
	player_score = Scoring.ScoreResult.new()
	opponent_score = Scoring.ScoreResult.new()
	round_number += 1
	reset_game.emit()


func _check_instant_wins() -> void:
	# check if 4 cards from the same month have been dealt to either player
	var player_win = Scoring.check_instant_hand_win(player_hand)
	var opponent_win = Scoring.check_instant_hand_win(opponent_hand)

	if player_win != null:
		player_score = player_win
		end_round(1)
	
	if opponent_win != null:
		opponent_score = opponent_win
		end_round(2)


func set_rounds(rounds: int) -> void:
	rounds_to_play = rounds
	round_wins = []
	for i in range(rounds):
		round_wins.append(0)


## Add a set of `Card` instances to the deck and shuffle
## emit deck_setup signal
func add_cards_to_deck(cards: Array[Card]) -> void:
	deck = cards
	deck.shuffle()
	deck_initialized.emit(deck)
	

func deal_card_to_player() -> void:
	if deck.size() == 0:
		return
	var card = deck.pop_back()
	card.make_player_card()
	player_hand.append(card)
	card_moved.emit(card, "deck_player_hand", null)


func deal_card_to_opponent() -> void:
	if deck.size() == 0:
		return
	var card = deck.pop_back()
	opponent_hand.append(card)
	card_moved.emit(card, "deck_opponent_hand", null)


func deal_card_to_field() -> void:
	if deck.size() == 0:
		return
	var card = deck.pop_back()
	card.make_field_card()
	field_cards.append(card)
	card_moved.emit(card, "deck_field", null)


func is_player_turn() -> bool:
	return _current_phase == Phase.PLAY and _current_turn == Turn.PLAYER


## When capturing cards, card1 is the players chosen card, either form their hand
## or the top of the deck, card 2 is the field card being captured
func player_captured_cards(card1: Card, card2: Card) -> void:
	if field_cards.has(card2):
		# card came from the field
		field_cards.erase(card2)
	else:
		# card came from the deck
		if not deck.has(card2):
			push_error("ERROR: deck does not have card2 to capture:", card2)
		deck.erase(card2)

	player_captured.append(card2)

	if player_hand.has(card1):
		# card came from player's hand
		player_hand.erase(card1)
		player_captured.append(card1)
		card_moved.emit(card1, "player_field_captured", card2)
	else:
		# card came from the deck
		deck.erase(card1)
		player_captured.append(card1)
		card_moved.emit(card1, "deck_field_captured", card2)

	capture_numbers_updated.emit(Turn.PLAYER, player_captured)


func player_card_to_field(card: Card) -> void:
	if player_hand.has(card):
		player_hand.erase(card)
		field_cards.append(card)
		card.make_field_card()
		card_moved.emit(card, "player_hand_field", null)


## When opponent captures cards, card1 is the opponent's chosen card
func opponent_captured_cards(card1: Card, card2: Card) -> void:
	if field_cards.has(card2):
		field_cards.erase(card2)
	else:
		if not deck.has(card2):
			push_error("ERROR: deck does not have card2 to capture:", card2)
		deck.erase(card2)
	
	opponent_captured.append(card2)
	
	if opponent_hand.has(card1):
		# card came from opponent's hand
		opponent_hand.erase(card1)
		opponent_captured.append(card1)
		card_moved.emit(card1, "opponent_field_captured", card2)
	else:
		# card came from the deck
		deck.erase(card1)
		opponent_captured.append(card1)
		card_moved.emit(card1, "deck_field_captured", card2)
	
	capture_numbers_updated.emit(Turn.OPPONENT, opponent_captured)


func opponent_card_to_field(card: Card) -> void:
	if opponent_hand.has(card):
		opponent_hand.erase(card)
		field_cards.append(card)
		card.make_field_card()
		card_moved.emit(card, "opponent_hand_field", null)


func start_deck_move() -> void:
	var card = deck[deck.size() - 1]
	# check if card is playable in field, if not add it
	if not field_cards.any(func(field_card: Card): return field_card.month == card.month):
		deal_card_to_field()
	else:
		deck.erase(card)
		players_chosen_card = card


## Start a new turn for the current player
func start_turn() -> void:
	if not is_player_turn():
		return
	
	# Check if player has any cards that can capture from field
	if can_player_capture_from_field():
		current_turn_phase = TurnPhase.HAND_FIELD_CAPTURE
	else:
		current_turn_phase = TurnPhase.PLAY_CARD_TO_FIELD

func start_opponent_turn() -> void:
	if current_turn != Turn.OPPONENT:
		return

	if can_opponent_capture_from_field():
		current_turn_phase = TurnPhase.HAND_FIELD_CAPTURE
	else:
		current_turn_phase = TurnPhase.PLAY_CARD_TO_FIELD


## Check if the current player has any cards that can capture from the field
func can_player_capture_from_field() -> bool:
	for hand_card in player_hand:
		for field_card in field_cards:
			if hand_card.month == field_card.month:
				return true
	return false


func can_opponent_capture_from_field() -> bool:
	for hand_card in opponent_hand:
		for field_card in field_cards:
			if hand_card.month == field_card.month:
				return true
	return false


## Check if a specific card can capture from the field
func can_card_capture_from_field(card: Card) -> bool:
	for field_card in field_cards:
		if card.month == field_card.month:
			return true
	return false


func advance_game_phase() -> void:
	match current_phase:
		Phase.NONE:
			current_phase = Phase.START
			# advance_game_phase()

		Phase.START:
			_reset_game_for_new_round()
			current_phase = Phase.DEAL

		Phase.DEAL:
			_check_instant_wins()
			current_turn_phase = TurnPhase.HAND_FIELD_CAPTURE
			current_phase = Phase.PLAY

		Phase.PLAY:
			# Check for end of round conditions here later
			current_phase = Phase.ROUND_END

		Phase.ROUND_END:
			current_phase = Phase.START
			current_turn = Turn.NONE
			current_turn_phase = TurnPhase.NONE


## Advance to the next phase of the turn
func advance_turn_phase() -> void:
	match current_turn_phase:
		TurnPhase.HAND_FIELD_CAPTURE:
			# Player made a capture, now flip deck card
			current_turn_phase = TurnPhase.FLIP_DECK_CARD
			
		TurnPhase.PLAY_CARD_TO_FIELD:
			# Player played card to field, now flip deck card
			current_turn_phase = TurnPhase.FLIP_DECK_CARD
			
		TurnPhase.FLIP_DECK_CARD:
			# Check if deck card can capture
			var deck_card = deck[deck.size() - 1]
			if can_card_capture_from_field(deck_card):
				current_turn_phase = TurnPhase.DECK_FIELD_CAPTURE
			else:
				# Deck card goes to field, turn ends
				deal_card_to_field()
				current_turn_phase = TurnPhase.SCORE
				
		TurnPhase.DECK_FIELD_CAPTURE:
			# Deck capture completed, turn ends
			current_turn_phase = TurnPhase.SCORE

		TurnPhase.SCORE:
			# Scoring completed, turn ends
			current_turn_phase = TurnPhase.TURN_END
			
		TurnPhase.TURN_END:
			# Switch to opponent turn
			if current_turn == Turn.PLAYER:
				current_turn = Turn.OPPONENT
			else:
				current_turn = Turn.PLAYER
				start_turn()


func can_player_koi_koi(result: Scoring.ScoreResult) -> bool:
	var old_score = player_score
	player_score = result
	var can_koi_koi = false
	if result.total_score != old_score.total_score or not _arrays_have_same_content(result.yaku_achieved, old_score.yaku_achieved):
		show_player_koi_koi.emit()
		can_koi_koi = true

	return can_koi_koi


func can_opponent_koi_koi(result: Scoring.ScoreResult) -> bool:
	var old_score = opponent_score
	opponent_score = result
	var can_koi_koi = false
	if result.total_score != old_score.total_score or not _arrays_have_same_content(result.yaku_achieved, old_score.yaku_achieved):
		can_koi_koi = true

	return can_koi_koi


## End the current round, setting winner as 1 for player, 2 for opponent
func end_round(winner: int) -> void:
	round_wins[round_number - 1] = winner

	if winner == 1:
		player_running_score += player_score.total_score
	elif winner == 2:
		opponent_running_score += opponent_score.total_score

	update_wins.emit(round_wins)
	# advance_game_phase()
