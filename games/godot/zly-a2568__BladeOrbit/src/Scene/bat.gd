extends Enemy
class_name Bat

var SPEED: float=60.0
var CHASE_MIN_DISTANCE_SQ: float
var DAMAGED_SPEED_FACTOR: float

var player: CharacterBody2D


func _ready() -> void:
	super()
	_apply_config()
	player = get_tree().get_first_node_in_group("player")


func _apply_config() -> void:
	var c: Dictionary = Config.data["bat"]
	CHASE_MIN_DISTANCE_SQ = c["chase_min_distance_sq"]
	DAMAGED_SPEED_FACTOR = c["damaged_speed_factor"]


func _act(_delta: float) -> void:
	super(_delta)
	if player == null:
		return
	var to_player := player.global_position - global_position
	if to_player.length_squared() > CHASE_MIN_DISTANCE_SQ:
		var direction := to_player.normalized()
		velocity = direction * SPEED * (DAMAGED_SPEED_FACTOR if damaged else 1.0)
	else :
		velocity=Vector2.ZERO


func _can_move() -> bool:
	return true
