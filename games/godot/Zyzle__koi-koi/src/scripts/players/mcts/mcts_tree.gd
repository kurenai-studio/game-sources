class_name MCTSTree
extends RefCounted

## Monte Carlo Tree Search implementation for Koi-Koi AI

var root: MCTSNode
var max_iterations: int = 1000 # Adjustable for difficulty
var max_time_ms: float = 1000.0 # Time budget in milliseconds


func _init(game_state: GameState, iterations: int = 1000, time_budget_ms: float = 1000.0) -> void:
	var sim_state = GameSimulator.create_from_game_state(game_state)
	root = MCTSNode.new(sim_state)
	max_iterations = iterations
	max_time_ms = time_budget_ms


## Run MCTS search and return best action
func search() -> MCTSAction:
	var start_time = Time.get_ticks_msec()
	var iterations = 0
	
	# Run MCTS iterations until time/iteration budget exhausted
	while iterations < max_iterations and (Time.get_ticks_msec() - start_time) < max_time_ms:
		# 1. Selection - traverse tree using UCB1 until we find a non-fully-expanded node
		var node = _select(root)
		
		# 2. Expansion - if not terminal and not fully expanded, expand it
		var simulation_node = node
		if not node.is_terminal() and not node.is_fully_expanded():
			var expanded_child = node.expand()
			if expanded_child != null:
				simulation_node = expanded_child
		
		# 3. Simulation - play out randomly from the node (could be expanded child or selected node)
		var result = _simulate(simulation_node)
		
		# 4. Backpropagation - update statistics
		_backpropagate(simulation_node, result)
		
		iterations += 1
	
	# Return action leading to most visited child
	var best_child = root.get_most_visited_child()
	if best_child:
		return best_child.action
	
	# Fallback to random legal action
	var legal_actions = GameSimulator.get_legal_actions(root.state)
	if not legal_actions.is_empty():
		return legal_actions[0]
	
	return null


## Selection phase - traverse tree selecting best children until we find a non-fully-expanded or terminal node
func _select(node: MCTSNode) -> MCTSNode:
	# Keep going down the tree as long as node has children to explore
	while not node.is_terminal() and node.is_fully_expanded() and not node.children.is_empty():
		node = node.select_child()
	return node


## Simulation phase - random playout from node
func _simulate(node: MCTSNode) -> float:
	var sim_state = node.state.duplicate_state()
	var depth = 0
	var max_depth = 50 # Prevent infinite loops
	
	
	# Play randomly until terminal state
	while not GameSimulator.is_terminal_state(sim_state) and depth < max_depth:
		# Handle automatic deck flip before getting actions
		if sim_state.current_turn_phase == GameState.TurnPhase.FLIP_DECK_CARD:
			_handle_deck_flip(sim_state)
			continue # Skip to next iteration after handling deck flip
		
		# Handle turn end phase - switch turns
		if sim_state.current_turn_phase == GameState.TurnPhase.TURN_END:
			if sim_state.current_turn == GameState.Turn.PLAYER:
				sim_state.current_turn = GameState.Turn.OPPONENT
			else:
				sim_state.current_turn = GameState.Turn.PLAYER
			
			# Start new turn - check for captures
			if GameSimulator.can_capture_from_field(sim_state):
				sim_state.current_turn_phase = GameState.TurnPhase.HAND_FIELD_CAPTURE
			else:
				sim_state.current_turn_phase = GameState.TurnPhase.PLAY_CARD_TO_FIELD
			continue
		
		var actions = GameSimulator.get_legal_actions(sim_state)
		
		if actions.is_empty():
			break
		
		# Choose random action (could be improved with heuristics)
		var action = actions[randi() % actions.size()]
		GameSimulator.apply_action(sim_state, action)
		
		depth += 1
	
	# Evaluate final state (from AI/opponent perspective)
	return GameSimulator.evaluate_state(sim_state)


## Handle automatic deck flip during simulation
func _handle_deck_flip(state: GameSimulator.SimulatedState) -> void:
	if state.deck.is_empty():
		state.current_turn_phase = GameState.TurnPhase.TURN_END
		return
	
	var deck_card = state.deck[state.deck.size() - 1]
	var can_capture = false
	
	for field_card in state.field_cards:
		if deck_card.month == field_card.month:
			can_capture = true
			break
	
	if can_capture:
		state.current_turn_phase = GameState.TurnPhase.DECK_FIELD_CAPTURE
	else:
		# Auto-move to field
		GameSimulator.apply_action(state, MCTSAction.new(MCTSAction.ActionType.DECK_TO_FIELD))


## Backpropagation phase - update nodes with result
func _backpropagate(node: MCTSNode, result: float) -> void:
	while node != null:
		# Update from AI perspective
		# If it's player's turn in this node, invert the result
		var score = result if node.state.current_turn == GameState.Turn.OPPONENT else -result
		node.update(score)
		node = node.parent


## Adjust difficulty by changing search parameters
func set_difficulty(difficulty: AIPlayer.Difficulty) -> void:
	match difficulty:
		AIPlayer.Difficulty.EASY:
			max_iterations = 100
			max_time_ms = 100.0
		AIPlayer.Difficulty.MEDIUM:
			max_iterations = 500
			max_time_ms = 500.0
		AIPlayer.Difficulty.HARD:
			max_iterations = 2000
			max_time_ms = 2000.0
