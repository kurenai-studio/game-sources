extends CharacterBody2D

@export var forward_speed: float = 300.0
@export var backward_speed_multiplier: float = 0.33
@export var strafe_speed_multiplier: float = 0.44

# Distance thresholds for scaling speed based on mouse distance
@export var min_mouse_distance: float = 50.0
@export var max_mouse_distance: float = 400.0
@export var min_speed_multiplier: float = 0.5
@export var max_speed_multiplier: float = 1.5

func _ready() -> void:
	apply_size_upgrade()

func _physics_process(_delta: float) -> void:
	apply_size_upgrade()
	look_at(get_global_mouse_position())
	
	# Calculate a speed modifier based on how far the mouse is from the player
	var mouse_dist = global_position.distance_to(get_global_mouse_position())
	var mouse_dist_factor = remap(
		clamp(mouse_dist, min_mouse_distance, max_mouse_distance),
		min_mouse_distance, max_mouse_distance,
		min_speed_multiplier, max_speed_multiplier
	)
	
	var forward_backward := Input.get_axis("move_forward", "move_backward")
	var left_right := Input.get_axis("move_left", "move_right")
	var global_speed_mult = GameManager.get_player_speed_multiplier()
	
	# Apply the mouse distance factor into the velocity calculation
	var effective_speed = forward_speed * global_speed_mult * mouse_dist_factor
	
	var final_velocity = Vector2.ZERO
	if forward_backward < 0:
		final_velocity += transform.x * -forward_backward * effective_speed
	elif forward_backward > 0:
		final_velocity += transform.x * -forward_backward * (effective_speed * backward_speed_multiplier)
		
	final_velocity += transform.y * left_right * (effective_speed * strafe_speed_multiplier)
	
	velocity = final_velocity
	move_and_slide()

func apply_size_upgrade() -> void:
	scale = Vector2.ONE * GameManager.get_player_size_multiplier()

func die() -> void:
	GameManager.end_game()
