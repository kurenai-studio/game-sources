class_name GameSimulator
extends RefCounted

## Simulates game states for MCTS without affecting the real game
## Creates lightweight copies of game state for rollouts

class SimulatedState:
	var player_hand: Array[Card] = []
	var opponent_hand: Array[Card] = []
	var field_cards: Array[Card] = []
	var deck: Array[Card] = []
	var player_captured: Array[Card] = []
	var opponent_captured: Array[Card] = []
	var current_turn: GameState.Turn
	var current_turn_phase: GameState.TurnPhase
	var player_score: int = 0
	var opponent_score: int = 0

	func _to_string() -> String:
		return "SimulatedState(player_hand=%d, opponent_hand=%d, field_cards=%d, deck=%d, player_captured=%d, opponent_captured=%d, current_turn=%s, current_turn_phase=%s, player_score=%d, opponent_score=%d)" % [
			player_hand.size(),
			opponent_hand.size(),
			field_cards.size(),
			deck.size(),
			player_captured.size(),
			opponent_captured.size(),
			GameState.TURN_MAP[current_turn],
			GameState.TURN_PHASE_MAP[current_turn_phase],
			player_score,
			opponent_score
		]

		
	func duplicate_state() -> SimulatedState:
		var new_state = SimulatedState.new()
		new_state.player_hand = player_hand.duplicate()
		new_state.opponent_hand = opponent_hand.duplicate()
		new_state.field_cards = field_cards.duplicate()
		new_state.deck = deck.duplicate()
		new_state.player_captured = player_captured.duplicate()
		new_state.opponent_captured = opponent_captured.duplicate()
		new_state.current_turn = current_turn
		new_state.current_turn_phase = current_turn_phase
		new_state.player_score = player_score
		new_state.opponent_score = opponent_score
		return new_state


## Create a simulated state from the real game state
static func create_from_game_state(game_state: GameState) -> SimulatedState:
	var guessed_cards: Array[Card] = []
	for card in CardsDB.BASE_DECK:
		guessed_cards.append(Card.new(card.month, card.number, card.type, card.points))

	guessed_cards = guessed_cards.filter(func(c: Card) -> bool:
		# Remove known cards from guessed pool
		for known_card in game_state.field_cards:
			if c.equals(known_card):
				return false
		for known_card in game_state.player_captured:
			if c.equals(known_card):
				return false
		for known_card in game_state.opponent_captured:
			if c.equals(known_card):
				return false
		for known_card in game_state.opponent_hand:
			if c.equals(known_card):
				return false
		return true
	)

	guessed_cards.shuffle()

	var sim_state = SimulatedState.new()
	sim_state.opponent_hand = game_state.opponent_hand.duplicate()
	sim_state.player_captured = game_state.player_captured.duplicate()
	sim_state.field_cards = game_state.field_cards.duplicate()
	sim_state.opponent_captured = game_state.opponent_captured.duplicate()

	var top_deck_card = game_state.deck[game_state.deck.size() - 1] if game_state.deck.size() > 0 else null
	if top_deck_card != null:
		guessed_cards = guessed_cards.filter(func(c: Card) -> bool:
			return not c.equals(top_deck_card)
		)

		for i in range(game_state.deck.size() - 1):
			sim_state.deck.append(guessed_cards.pop_back())

		for i in range(game_state.player_hand.size()):
			sim_state.player_hand.append(guessed_cards.pop_back())

		sim_state.deck.append(top_deck_card)
	else:
		# I feel like this case shouldn't happen
		for i in range(game_state.deck.size()):
			sim_state.deck.append(guessed_cards.pop_back())

		for i in range(game_state.player_hand.size()):
			sim_state.player_hand.append(guessed_cards.pop_back())

	sim_state.current_turn = game_state.current_turn
	sim_state.current_turn_phase = game_state.current_turn_phase
	sim_state.player_score = game_state.player_score.total_score
	sim_state.opponent_score = game_state.opponent_score.total_score
	return sim_state


## Get all legal actions from current state
static func get_legal_actions(state: SimulatedState) -> Array[MCTSAction]:
	var actions: Array[MCTSAction] = []
	
	match state.current_turn_phase:
		GameState.TurnPhase.HAND_FIELD_CAPTURE:
			# Find all possible hand-field capture combinations
			var hand = state.opponent_hand if state.current_turn == GameState.Turn.OPPONENT else state.player_hand
			for hand_card in hand:
				for field_card in state.field_cards:
					if hand_card.month == field_card.month:
						actions.append(MCTSAction.new(MCTSAction.ActionType.HAND_CAPTURE, hand_card, field_card))
			
		GameState.TurnPhase.PLAY_CARD_TO_FIELD:
			# All hand cards can be played to field
			var hand = state.opponent_hand if state.current_turn == GameState.Turn.OPPONENT else state.player_hand
			for hand_card in hand:
				actions.append(MCTSAction.new(MCTSAction.ActionType.PLAY_TO_FIELD, hand_card))
		
		GameState.TurnPhase.DECK_FIELD_CAPTURE:
			# Deck card can capture from field
			if state.deck.size() > 0:
				var deck_card = state.deck[state.deck.size() - 1]
				for field_card in state.field_cards:
					if deck_card.month == field_card.month:
						actions.append(MCTSAction.new(MCTSAction.ActionType.DECK_CAPTURE, null, field_card))
		
		GameState.TurnPhase.SCORE:
			# Koi-koi decision
			actions.append(MCTSAction.new(MCTSAction.ActionType.KOI_KOI_YES))
			actions.append(MCTSAction.new(MCTSAction.ActionType.KOI_KOI_NO))
	
	return actions


## Apply an action to the simulated state
static func apply_action(state: SimulatedState, action: MCTSAction) -> void:
	var is_opponent = state.current_turn == GameState.Turn.OPPONENT
	
	match action.action_type:
		MCTSAction.ActionType.HAND_CAPTURE:
			# Remove cards and add to captured
			if is_opponent:
				state.opponent_hand.erase(action.hand_card)
				state.opponent_captured.append(action.hand_card)
				state.opponent_captured.append(action.field_card)
			else:
				state.player_hand.erase(action.hand_card)
				state.player_captured.append(action.hand_card)
				state.player_captured.append(action.field_card)
			state.field_cards.erase(action.field_card)
			state.current_turn_phase = GameState.TurnPhase.FLIP_DECK_CARD
			
		MCTSAction.ActionType.PLAY_TO_FIELD:
			# Move card from hand to field
			if is_opponent:
				state.opponent_hand.erase(action.hand_card)
			else:
				state.player_hand.erase(action.hand_card)
			state.field_cards.append(action.hand_card)
			state.current_turn_phase = GameState.TurnPhase.FLIP_DECK_CARD
			
		MCTSAction.ActionType.DECK_CAPTURE:
			# Deck card captures from field
			var deck_card = state.deck.pop_back()
			if is_opponent:
				state.opponent_captured.append(deck_card)
				state.opponent_captured.append(action.field_card)
			else:
				state.player_captured.append(deck_card)
				state.player_captured.append(action.field_card)
			state.field_cards.erase(action.field_card)
			state.current_turn_phase = GameState.TurnPhase.SCORE
			
		MCTSAction.ActionType.DECK_TO_FIELD:
			# Deck card goes to field
			var deck_card = state.deck.pop_back()
			state.field_cards.append(deck_card)
			state.current_turn_phase = GameState.TurnPhase.SCORE
			
		MCTSAction.ActionType.KOI_KOI_YES:
			# Continue playing
			state.current_turn_phase = GameState.TurnPhase.TURN_END
			
		MCTSAction.ActionType.KOI_KOI_NO:
			# End round - this would need proper scoring
			state.current_turn_phase = GameState.TurnPhase.TURN_END


## Evaluate the state for the AI (opponent perspective)
## Returns a score where higher is better for the AI
static func evaluate_state(state: SimulatedState) -> float:
	# Calculate score difference (AI score - Player score)
	var opponent_result = Scoring.calculate_score(state.opponent_captured)
	var player_result = Scoring.calculate_score(state.player_captured)
	
	var score_diff = opponent_result.total_score - player_result.total_score
	
	# Add heuristic values
	var opponent_value = _evaluate_hand_potential(state.opponent_hand, state.field_cards)
	var player_value = _evaluate_hand_potential(state.player_hand, state.field_cards)
	
	# Combine actual score with potential
	return float(score_diff) + (opponent_value - player_value) * 0.1


## Evaluate potential of cards in hand
static func _evaluate_hand_potential(hand: Array[Card], field: Array[Card]) -> float:
	var potential = 0.0
	
	# Count matching cards in field (potential captures)
	for hand_card in hand:
		for field_card in field:
			if hand_card.month == field_card.month:
				potential += hand_card.points * 0.5 # Potential capture value
	
	# Value high-point cards in hand
	for card in hand:
		if card.type == Card.CardType.BRIGHT:
			potential += 2.0
		elif card.type == Card.CardType.ANIMAL:
			potential += 1.0
		elif card.type == Card.CardType.RIBBON:
			potential += 0.5
	
	return potential


## Check if the game has ended
static func is_terminal_state(state: SimulatedState) -> bool:
	# Game ends if hands are empty or someone chose to end
	return state.player_hand.is_empty() and state.opponent_hand.is_empty()


## Check if current player can capture from field with their hand
static func can_capture_from_field(state: SimulatedState) -> bool:
	var hand = state.opponent_hand if state.current_turn == GameState.Turn.OPPONENT else state.player_hand
	for hand_card in hand:
		for field_card in state.field_cards:
			if hand_card.month == field_card.month:
				return true
	return false
