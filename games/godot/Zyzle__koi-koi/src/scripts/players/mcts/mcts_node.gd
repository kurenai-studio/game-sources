class_name MCTSNode
extends RefCounted

## Represents a node in the MCTS search tree

var state: GameSimulator.SimulatedState
var action: MCTSAction # Action that led to this node
var parent: MCTSNode
var children: Array[MCTSNode] = []
var untried_actions: Array[MCTSAction] = []

# MCTS statistics
var visits: int = 0
var wins: float = 0.0 # From AI perspective

const EXPLORATION_CONSTANT = sqrt(2.0) # UCB1 constant


func _init(sim_state: GameSimulator.SimulatedState, parent_node: MCTSNode = null, parent_action: MCTSAction = null) -> void:
	state = sim_state
	parent = parent_node
	action = parent_action
	untried_actions = GameSimulator.get_legal_actions(state)


## Select best child using UCB1 formula
func select_child() -> MCTSNode:
	var best_child: MCTSNode = null
	var best_value = - INF
	
	for child in children:
		# UCB1 = exploitation + exploration
		var exploitation = child.wins / float(child.visits)
		var exploration = EXPLORATION_CONSTANT * sqrt(log(visits) / float(child.visits))
		var ucb_value = exploitation + exploration
		
		if ucb_value > best_value:
			best_value = ucb_value
			best_child = child
	
	return best_child


## Expand node by trying an untried action
func expand() -> MCTSNode:
	if untried_actions.is_empty():
		return null
	
	# Try a random untried action
	var action_to_try = untried_actions.pop_back()
	
	# Create new state by applying action
	var new_state = state.duplicate_state()
	GameSimulator.apply_action(new_state, action_to_try)
	
	# Create child node
	var child = MCTSNode.new(new_state, self, action_to_try)
	children.append(child)
	
	return child


## Check if node is fully expanded
func is_fully_expanded() -> bool:
	return untried_actions.is_empty()


## Check if node is terminal (game over)
func is_terminal() -> bool:
	return GameSimulator.is_terminal_state(state)


## Update node statistics after a playout
func update(result: float) -> void:
	visits += 1
	wins += result


## Get best child based on visit count (for final decision)
func get_most_visited_child() -> MCTSNode:
	var best_child: MCTSNode = null
	var most_visits = 0
	
	for child in children:
		if child.visits > most_visits:
			most_visits = child.visits
			best_child = child
	
	return best_child
