extends Node

signal game_over
signal round_started

var score: int = 0

# Upgrade Levels
var speed_level: int = 1
var size_level: int = 1
var time_level: int = 1

# Upgrade Costs (Starting higher)
var speed_cost: int = 25
var size_cost: int = 30
var time_cost: int = 40

# Round Configuration & State
var round_duration: float = 15.0
var time_left: float = 0.0
var round_active: bool = false

func _process(delta: float) -> void:
	if not round_active:
		return
		
	time_left = max(0.0, time_left - delta)
	
	if time_left <= 0.0:
		end_game()

func start_new_round() -> void:
	# Clear out any leftover collectibles from previous rounds instantly
	get_tree().call_group("collectibles", "queue_free")
	
	time_left = round_duration + get_bonus_time()
	round_active = true
	get_tree().paused = false
	round_started.emit()

func end_game() -> void:
	if not round_active:
		return
	round_active = false
	get_tree().paused = true
	game_over.emit()

# Diminishing returns formula: Smaller increase per level, but uncapped
func get_player_speed_multiplier() -> float:
	# Each level now adds a smaller 5% increase instead of 15%
	return 1.0 + (speed_level - 1) * 0.05

func get_player_size_multiplier() -> float:
	return 1.0 + (size_level - 1) * 0.1

func get_bonus_time() -> float:
	return float((time_level - 1) * 2.5)

func can_afford(cost: int) -> bool:
	return score >= cost

func spend_score(cost: int) -> void:
	score -= cost
