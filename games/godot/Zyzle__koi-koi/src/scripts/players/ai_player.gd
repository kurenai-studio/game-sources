class_name AIPlayer
extends Player

enum Difficulty {
	EASY,
	MEDIUM,
	HARD
}

var difficulty: Difficulty = Difficulty.MEDIUM
var thinking_time: float = 0.5 # Delay before making move (for realism)


## Make a move using MCTS algorithm
func make_move(game_state: GameState) -> MCTSAction:
	# Create MCTS tree with difficulty-based parameters
	var mcts = MCTSTree.new(game_state)
	mcts.set_difficulty(difficulty)
	
	# Search for best action
	var best_action = mcts.search()
	
	return best_action


## Set AI difficulty level
func set_difficulty(new_difficulty: Difficulty) -> void:
	difficulty = new_difficulty
	
	# Adjust thinking time based on difficulty
	match difficulty:
		Difficulty.EASY:
			thinking_time = 0.3
		Difficulty.MEDIUM:
			thinking_time = 0.5
		Difficulty.HARD:
			thinking_time = 0.8


## Get a description of current difficulty
func get_difficulty_name() -> String:
	match difficulty:
		Difficulty.EASY:
			return "Easy"
		Difficulty.MEDIUM:
			return "Medium"
		Difficulty.HARD:
			return "Hard"
	return "Unknown"