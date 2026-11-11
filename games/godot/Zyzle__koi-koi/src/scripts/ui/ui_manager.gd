class_name UIManager
extends Node

const CARD_SCENE_PATH = "res://scenes/card_visual.tscn"
const SCORING_PANEL_SCENE_PATH = "res://scenes/scoring_panel.tscn"
const WIN_LOSE_PANEL_SCENE_PATH = "res://scenes/win_lose_panel.tscn"


@onready var game_world: Node2D = %GameWorld
@onready var player_hand_container: Hand = %PlayerHand
@onready var field_container: Field = %Field
@onready var opponent_hand_container: Hand = %OpponentHand
@onready var deck_slot: Deck = %DeckSlot
@onready var player_capture_area: CaptureArea = %PlayerCaptureArea
@onready var opponent_capture_area: CaptureArea = %OpponentCaptureArea

signal deal_finished();
signal player_chose_koi_koi()
signal player_chose_end_round()

var game_manager: GameManager
var game_state: GameState
var card_registry: Dictionary[Card, CardVisual]
var deal_registry: Array[Dictionary]
var selected_card: CardVisual
var scoring_panel: ScoringPanel
var wld_panel: WinLosePanel

func _create_card_visual(card: Card) -> CardVisual:
	var card_scene = preload(CARD_SCENE_PATH)
	var card_visual: CardVisual = card_scene.instantiate()
	card_visual.card_data = card
	
	# Pass GameState if CardVisual needs it
	if game_state:
		card_visual.set_game_state(game_state)
	
	return card_visual


## Retrieve a CardVisual from the registry
func _get_card_visual(card: Card) -> CardVisual:
	return card_registry.get(card, null)


func _highlight_matching_field_cards(card: Card) -> void:
	for child in field_container.get_cards():
		var card_visual = child
		if card == null:
			card_visual.remove_highlight()
		elif card_visual.card_data.month == card.month:
			card_visual.apply_highlight()
		else:
			card_visual.remove_highlight()


func _on_koi_koi_pressed() -> void:
	scoring_panel.queue_free()
	player_chose_koi_koi.emit()


func _on_end_pressed() -> void:
	scoring_panel.queue_free()
	player_chose_end_round.emit()


func _on_next_pressed() -> void:
	wld_panel.queue_free()
	game_state.advance_game_phase()


func set_game_state(state: GameState) -> void:
	game_state = state
	player_capture_area.setup_coins(game_state.rounds_to_play)
	opponent_capture_area.setup_coins(game_state.rounds_to_play)


func setup_deck_display(deck: Array[Card]) -> void:
	# Create all card visuals but keep them invisible initially
	# This prevents stacking issues in the deck container
	for card in deck:
		var card_visual = _create_card_visual(card)
		# Connect directly to GameManager (Controller) instead of UIManager
		card_visual.player_card_clicked.connect(game_manager.on_player_card_clicked)
		card_visual.field_card_clicked.connect(game_manager.on_field_card_clicked)
		card_registry[card] = card_visual
		
		# Stacking is preferred for Deck
		deck_slot.add_card(card_visual)
	

func card_dealt_to_player(card: Card) -> void:
	var card_visual = card_registry[card]
	deck_slot.remove_card(card_visual)
	card_visual.connect_events()
	deal_registry.append({card = card_visual, target = player_hand_container})


func card_dealt_to_field(card: Card) -> void:
	var card_visual = card_registry[card]
	deck_slot.remove_card(card_visual)
	card_visual.connect_events()
	deal_registry.append({card = card_visual, target = field_container})


func card_dealt_to_opponent(card: Card) -> void:
	var card_visual = card_registry[card]
	deck_slot.remove_card(card_visual)
	deal_registry.append({card = card_visual, target = opponent_hand_container})


func player_selected_card(card: Card) -> void:
	# Update visual selection state
	if selected_card:
		selected_card.set_selected(false)
	
	if card:
		# Find and select the new card
		var card_visual = _get_card_visual(card)
		if card_visual:
			card_visual.set_selected(true)
			selected_card = card_visual
			
			# Auto-play to field if in PLAY_CARD_TO_FIELD phase
			if game_state.current_turn_phase == GameState.TurnPhase.PLAY_CARD_TO_FIELD:
				# Automatically play the selected card to field since no capture is possible
				game_manager.play_card_to_field(card)
				card_visual.set_selected(false)
				selected_card = null
				return
	else:
		selected_card = null
		
	# Highlight matching field cards (only during capture phases)
	if game_state.current_turn_phase == GameState.TurnPhase.HAND_FIELD_CAPTURE:
		_highlight_matching_field_cards(card)
	else:
		# Clear all highlights if not in capture mode
		for child in field_container.get_cards():
			child.remove_highlight()


func process_deal_queue() -> void:
	for deal in deal_registry:
		var tween = await deal.target.add_card(deal.card, deal.target == player_hand_container)
		await tween.finished

	deal_registry.clear()
	deal_finished.emit()


func move_deck_to_field(card: Card) -> void:
	var card_visual = _get_card_visual(card)
	deck_slot.remove_card(card_visual)
	card_visual.connect_events()
	if field_container.all_slots_occupied():
		field_container.open_next_slot()
	var tween = field_container.add_card(card_visual, false)
	await tween.finished


## Handle when player plays a card from hand to field
func player_card_to_field(card: Card) -> void:
	var card_visual = _get_card_visual(card)
	if card_visual:
		card_visual.set_selected(false)
		card_visual.disconnect_events()
		player_hand_container.remove_card(card_visual)
		var tween = field_container.add_card(card_visual, false)
		await tween.finished
		card_visual.connect_events()
		field_container.clear_all_highlights()
	selected_card = null


## Handle when opponent plays a card from hand to field
func opponent_card_to_field(card: Card) -> void:
	var card_visual = _get_card_visual(card)
	if card_visual:
		card_visual.flip_card()
		opponent_hand_container.remove_card(card_visual)
		if field_container.all_slots_occupied():
			field_container.open_next_slot()
		var tween = field_container.add_card(card_visual, false)
		await tween.finished
		card_visual.connect_events()


func field_captured_by_player(player_card: Card, field_card: Card) -> void:
	var player_card_visual = _get_card_visual(player_card)
	var field_card_visual = _get_card_visual(field_card)

	player_card_visual.set_selected(false)
	player_card_visual.unembiggen(true)
	player_card_visual.disconnect_events()
	field_container.remove_card(field_card_visual)
	player_hand_container.remove_card(player_card_visual)
	selected_card = null
	
	if player_card_visual:
		var tween = player_capture_area.capture_card(player_card_visual)
		await tween.finished
	
	if field_card_visual:
		var tween = player_capture_area.capture_card(field_card_visual)
		await tween.finished


func field_captured_by_opponent(opponent_card: Card, field_card: Card) -> void:
	var opponent_card_visual = _get_card_visual(opponent_card)
	var field_card_visual = _get_card_visual(field_card)

	opponent_card_visual.flip_card()
	opponent_hand_container.remove_card(opponent_card_visual)
	field_container.remove_card(field_card_visual)
	selected_card = null

	if opponent_card_visual:
		var tween = opponent_capture_area.capture_card(opponent_card_visual)
		await tween.finished

	if field_card_visual:
		var tween = opponent_capture_area.capture_card(field_card_visual)
		await tween.finished


func field_captured_by_deck(deck_card: Card, field_card: Card, player: GameState.Turn) -> void:
	var deck_card_visual = _get_card_visual(deck_card)
	var field_card_visual = _get_card_visual(field_card)

	deck_card_visual.set_selected(false)
	deck_slot.remove_card(deck_card_visual)
	field_container.remove_card(field_card_visual)
	selected_card = null

	var capture_area = player_capture_area if player == GameState.Turn.PLAYER else opponent_capture_area

	if deck_card_visual:
		var tween = capture_area.capture_card(deck_card_visual)
		await tween.finished

	if field_card_visual:
		var tween = capture_area.capture_card(field_card_visual)
		await tween.finished


## Set UI state for capture mode (player can capture from field)
func set_capture_mode() -> void:
	pass
	# Could add visual indicators here


## Set UI state for playing cards to field (no capture possible)
func set_play_to_field_mode() -> void:
	# Could add visual indicators here
	field_container.highlight_available_slot()


## Set UI state for deck capture mode (deck card can capture)
func set_deck_capture_mode() -> void:
	# Could add visual indicators or highlight deck card
	var top_card = deck_slot.get_top_card()
	top_card.set_selected(true)
	_highlight_matching_field_cards(top_card.card_data)


## Flip the top deck card
func flip_deck_card() -> void:
	var top_card = deck_slot.get_top_card()
	if top_card:
		top_card.flip_card()


## Clean up UI state at end of turn
func end_turn_cleanup() -> void:
	if selected_card:
		selected_card.set_selected(false)
		selected_card = null
	
	# Remove all field card highlights
	for card_visual in field_container.get_cards():
		card_visual.remove_highlight()


func update_capture_numbers(for_turn: GameState.Turn, captured_cards: Array[Card]) -> void:
	match for_turn:
		GameState.Turn.PLAYER:
			player_capture_area.set_capture_labels(captured_cards)
		GameState.Turn.OPPONENT:
			opponent_capture_area.set_capture_labels(captured_cards)


func prompt_player_koi_koi() -> void:
	var scoring_panel_scene = preload(SCORING_PANEL_SCENE_PATH)
	scoring_panel = scoring_panel_scene.instantiate()
	scoring_panel.position = Vector2(625, 140)
	scoring_panel.connect("koi_koi_pressed", _on_koi_koi_pressed)
	scoring_panel.connect("end_pressed", _on_end_pressed)
	scoring_panel.set_game_state(game_state)
	game_world.add_child(scoring_panel)


func reset_ui_for_new_game() -> void:
	# Clear all containers
	player_hand_container.clear_all_cards()
	opponent_hand_container.clear_all_cards()
	field_container.clear_all_cards()
	player_capture_area.clear_all_cards()
	opponent_capture_area.clear_all_cards()
	deck_slot.clear_all_cards()
	
	# Clear card registry
	card_registry.clear()
	selected_card = null


func update_round_wins(wins: Array[int]) -> void:
	var wins_player: Array[int]
	wins_player.assign(wins.map(func(w: int): return 1 if w == 1 else 0))
	var wins_opponent: Array[int]
	wins_opponent.assign(wins.map(func(w: int): return 1 if w == 2 else 0))
	player_capture_area.set_coins(wins_player)
	opponent_capture_area.set_coins(wins_opponent)
	
	# Free existing panel if it exists
	if wld_panel and is_instance_valid(wld_panel):
		wld_panel.queue_free()
	
	var wld_panel_scene = preload(WIN_LOSE_PANEL_SCENE_PATH)
	wld_panel = wld_panel_scene.instantiate()
	wld_panel.position = Vector2(625, 140)
	wld_panel.set_game_state(game_state)
	wld_panel.next_pressed.connect(_on_next_pressed)
	game_world.add_child(wld_panel)
