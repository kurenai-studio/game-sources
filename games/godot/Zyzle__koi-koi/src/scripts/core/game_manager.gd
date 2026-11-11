class_name GameManager
extends Node

var game_state: GameState
var ai_player: AIPlayer
var ui_manager: UIManager
# var nework_manager: NetworkManager

func _ready() -> void:
	game_state = GameState.new()
	game_state.set_rounds(Global.game_rounds)
	ai_player = AIPlayer.new()
	ai_player.set_difficulty(Global.ai_difficulty)
	ui_manager = get_node("../UIManager")
	ui_manager.game_manager = self
	
	# Defer initialization to ensure all nodes are ready
	call_deferred("_initialize_game")


func _initialize_game() -> void:
	# Pass GameState to UIManager
	ui_manager.set_game_state(game_state)
	_connect_signals()
	# _setup_new_game()
	game_state.advance_game_phase()


func _connect_signals() -> void:
	# Game flow signals
	game_state.phase_changed.connect(_on_phase_changed)
	game_state.turn_changed.connect(_on_turn_changed)
	game_state.turn_phase_changed.connect(_on_turn_phase_changed)
	ui_manager.deal_finished.connect(_on_deal_finished)
	ui_manager.player_chose_koi_koi.connect(_on_player_chose_koi_koi)
	ui_manager.player_chose_end_round.connect(_on_player_chose_end_round)
	
	
	# Model events - Controller translates to UI actions
	game_state.deck_initialized.connect(_on_deck_initialized)
	game_state.card_moved.connect(_on_card_moved)
	game_state.player_selected_card.connect(_on_player_selected_card)
	game_state.capture_numbers_updated.connect(ui_manager.update_capture_numbers)
	game_state.show_player_koi_koi.connect(ui_manager.prompt_player_koi_koi)
	game_state.reset_game.connect(ui_manager.reset_ui_for_new_game)
	game_state.reset_game.connect(_setup_new_game)
	game_state.update_wins.connect(ui_manager.update_round_wins)


## Create a new array of all the cards in the cards db,
## then pass these to game_state via add_cards_to_deck()
## moves the current_phase to DEAL
func _setup_new_game() -> void:
	var cards: Array[Card] = []
	for card in CardsDB.BASE_DECK:
		var card_instance = Card.new(card["month"], card["number"], card["type"], card["points"])
		cards.append(card_instance)
	game_state.add_cards_to_deck(cards)
	

# Game flow signal handlers
func _on_phase_changed(new_phase: GameState.Phase) -> void:
	match new_phase:
		GameState.Phase.START:
			# Setup for new round
			_setup_new_game()
			# Advance to DEAL phase
			game_state.advance_game_phase()

		GameState.Phase.DEAL:
			for i in range(8):
				game_state.deal_card_to_player()
				game_state.deal_card_to_opponent()
				game_state.deal_card_to_field()
			ui_manager.process_deal_queue()
			# Note: advance_game_phase is called by _on_deal_finished signal

		GameState.Phase.PLAY:
			game_state.current_turn = GameState.Turn.PLAYER
		
		GameState.Phase.ROUND_END:
			game_state.advance_game_phase()


func _on_turn_changed(new_turn: GameState.Turn) -> void:
	if new_turn == GameState.Turn.PLAYER:
		# Start the player's turn sequence
		game_state.start_turn()
	elif new_turn == GameState.Turn.OPPONENT:
		# AI makes its move after a thinking delay
		await get_tree().create_timer(ai_player.thinking_time).timeout
		game_state.start_opponent_turn()
		# game_state.current_turn_phase = GameState.TurnPhase.HAND_FIELD_CAPTURE if game_state.can_opponent_capture_from_field() else GameState.TurnPhase.PLAY_CARD_TO_FIELD
		# _make_ai_move()


func _on_turn_phase_changed(new_turn_phase: GameState.TurnPhase) -> void:
	if game_state.current_turn == GameState.Turn.OPPONENT:
		# AI turn phases are handled in _make_ai_move
		_on_turn_phase_changed_for_opponent(new_turn_phase)
	elif game_state.current_turn == GameState.Turn.PLAYER:
		# Handle player turn phases
		_on_turn_phase_changed_for_player(new_turn_phase)


func _on_turn_phase_changed_for_player(new_turn_phase: GameState.TurnPhase) -> void:
	match new_turn_phase:
		GameState.TurnPhase.HAND_FIELD_CAPTURE:
			ui_manager.set_capture_mode()
			
		GameState.TurnPhase.PLAY_CARD_TO_FIELD:
			ui_manager.set_play_to_field_mode()
			
		GameState.TurnPhase.FLIP_DECK_CARD:
			ui_manager.flip_deck_card()
			# Automatically advance after animation
			await get_tree().create_timer(1.0).timeout
			game_state.advance_turn_phase()
			
		GameState.TurnPhase.DECK_FIELD_CAPTURE:
			ui_manager.set_deck_capture_mode()

		GameState.TurnPhase.SCORE:
			var turn_scores = Scoring.calculate_score(game_state.player_captured)
			var can_koi_koi = game_state.can_player_koi_koi(turn_scores)
			if not can_koi_koi:
				game_state.advance_turn_phase()

		GameState.TurnPhase.TURN_END:
			ui_manager.end_turn_cleanup()
			game_state.advance_turn_phase()


func _on_turn_phase_changed_for_opponent(new_turn_phase: GameState.TurnPhase) -> void:
	match new_turn_phase:
		GameState.TurnPhase.HAND_FIELD_CAPTURE:
			_make_ai_move()
			
		GameState.TurnPhase.PLAY_CARD_TO_FIELD:
			_make_ai_move()
			
		GameState.TurnPhase.FLIP_DECK_CARD:
			ui_manager.flip_deck_card()
			# Automatically advance after animation
			await get_tree().create_timer(1.0).timeout
			game_state.advance_turn_phase()
			
		GameState.TurnPhase.DECK_FIELD_CAPTURE:
			_make_ai_move()

		GameState.TurnPhase.SCORE:
			var turn_scores = Scoring.calculate_score(game_state.opponent_captured)
			var can_koi_koi = game_state.can_opponent_koi_koi(turn_scores)
			if not can_koi_koi:
				game_state.advance_turn_phase()
			else:
				_make_ai_move()
			
		GameState.TurnPhase.TURN_END:
			ui_manager.end_turn_cleanup()
			game_state.advance_turn_phase()


func _on_deal_finished() -> void:
	game_state.advance_game_phase()


# Model event handlers - Controller translates to specific UI actions
func _on_deck_initialized(deck: Array[Card]) -> void:
	ui_manager.setup_deck_display(deck)


## Handle card moved events from GameState and pass to UI manager
## card is the Card instance that moved
## from_to_location is a string in the format "from_to", e.g. "deck_player_hand"
## move_also is used when a card is moved to the field and needs to animate
func _on_card_moved(card: Card, from_to_location: String, move_also: Card) -> void:
	match from_to_location:
		"deck_player_hand":
			ui_manager.card_dealt_to_player(card)
		"deck_opponent_hand":
			ui_manager.card_dealt_to_opponent(card)
		"deck_field":
			if game_state.current_phase == GameState.Phase.DEAL:
				ui_manager.card_dealt_to_field(card)
			else:
				ui_manager.move_deck_to_field(card)
		"player_field_captured":
			ui_manager.field_captured_by_player(card, move_also)
		"player_hand_field":
			ui_manager.player_card_to_field(card)
		"opponent_hand_field":
			ui_manager.opponent_card_to_field(card)
		"deck_field_captured":
			ui_manager.field_captured_by_deck(card, move_also, game_state.current_turn)
		"opponent_field_captured":
			ui_manager.field_captured_by_opponent(card, move_also)


func _on_player_selected_card(card: Card) -> void:
	ui_manager.player_selected_card(card)


func _on_player_chose_koi_koi() -> void:
	# advance turn phase to keep playing
	game_state.advance_turn_phase()


func _on_player_chose_end_round() -> void:
	game_state.end_round(1)


## AI opponent makes a move using MCTS
func _make_ai_move() -> void:
	var action = ai_player.make_move(game_state)
	if action:
		_execute_ai_action(action)
	else:
		game_state.advance_turn_phase()
		

## Execute the AI's chosen action
func _execute_ai_action(action: MCTSAction) -> void:
	match action.action_type:
		MCTSAction.ActionType.HAND_CAPTURE:
			# AI captures with hand card
			game_state.opponent_captured_cards(action.hand_card, action.field_card)
			game_state.advance_turn_phase()
			
		MCTSAction.ActionType.PLAY_TO_FIELD:
			# AI plays card to field
			game_state.opponent_card_to_field(action.hand_card)
			game_state.advance_turn_phase()
			
		MCTSAction.ActionType.DECK_CAPTURE:
			# AI captures with deck card
			var deck_card = game_state.deck[game_state.deck.size() - 1]
			game_state.opponent_captured_cards(deck_card, action.field_card)
			game_state.advance_turn_phase()
			
		MCTSAction.ActionType.KOI_KOI_YES:
			# AI continues playing
			game_state.advance_turn_phase()
			
		MCTSAction.ActionType.KOI_KOI_NO:
			# AI ends round
			game_state.end_round(2) # 2 = opponent wins


# Controller methods - handle user input and decide what to do
func on_player_card_clicked(clicked_card_visual: CardVisual) -> void:
	# Only allow card selection during appropriate turn phases
	if not (game_state.current_turn_phase == GameState.TurnPhase.HAND_FIELD_CAPTURE or
			game_state.current_turn_phase == GameState.TurnPhase.PLAY_CARD_TO_FIELD):
		return
	
	# Game logic decides what happens
	if ui_manager.selected_card == clicked_card_visual:
		# Deselect
		game_state.players_chosen_card = null
	else:
		# Select new card
		game_state.players_chosen_card = clicked_card_visual.card_data


func on_field_card_clicked(clicked_card_visual: CardVisual) -> void:
	# Handle different scenarios based on turn phase
	match game_state.current_turn_phase:
		GameState.TurnPhase.HAND_FIELD_CAPTURE:
			# Player is capturing with a hand card
			if game_state.players_chosen_card != null:
				var player_card = game_state.players_chosen_card
				var field_card = clicked_card_visual.card_data
				
				if player_card.month == field_card.month:
					game_state.players_chosen_card = null
					game_state.player_captured_cards(player_card, field_card)
					# Advance to deck flip phase
					game_state.advance_turn_phase()
			
		GameState.TurnPhase.PLAY_CARD_TO_FIELD:
			# This shouldn't happen - player should play to field, not capture
			push_warning("WARNING: Cannot capture during PLAY_CARD_TO_FIELD phase")

		GameState.TurnPhase.DECK_FIELD_CAPTURE:
			# Player is capturing with the deck card
			var deck_card = game_state.deck[game_state.deck.size() - 1]
			var field_card = clicked_card_visual.card_data
			
			if deck_card.month == field_card.month:
				game_state.player_captured_cards(deck_card, field_card)
				# End turn
				game_state.advance_turn_phase()


## Handle when player plays a card to the field (no capture possible)
func play_card_to_field(card: Card) -> void:
	if game_state.current_turn_phase != GameState.TurnPhase.PLAY_CARD_TO_FIELD:
		return
	
	if not game_state.player_hand.has(card):
		return
		
	# Move card from hand to field
	game_state.player_card_to_field(card)

	# Clear selection and advance to deck flip
	game_state.players_chosen_card = null
	game_state.advance_turn_phase()
