extends Node

@export var player: Node2D
@export var collectible_scenes: Array[PackedScene] = []
@export var spawn_interval: float = 0.6  # Made significantly more frequent (was 1.5)
@export var spawn_margin: float = 0.0    # Set to 0.0 so they spawn right on the visible edge line

var timer: float = 0.0

func _process(delta: float) -> void:
	if get_tree().paused or not player:
		return
		
	timer += delta
	if timer >= spawn_interval:
		timer = 0.0
		spawn_item()

func spawn_item() -> void:
	if collectible_scenes.is_empty():
		return
		
	var random_scene = collectible_scenes[randi() % collectible_scenes.size()]
	if not random_scene:
		return
		
	var viewport := get_viewport()
	var cam := viewport.get_camera_2d()
	var screen_size := viewport.get_visible_rect().size
	var cam_pos = cam.global_position if cam else player.global_position
	
	# Using true half-widths/heights minus any inset margin so they sit on the border
	var half_width = (screen_size.x / 2.0) - spawn_margin
	var half_height = (screen_size.y / 2.0) - spawn_margin
	
	var spawn_pos := Vector2.ZERO
	var side = randi() % 4
	
	match side:
		0: # Top edge inside view
			spawn_pos = cam_pos + Vector2(randf_range(-half_width, half_width), -half_height)
		1: # Bottom edge inside view
			spawn_pos = cam_pos + Vector2(randf_range(-half_width, half_width), half_height)
		2: # Left edge inside view
			spawn_pos = cam_pos + Vector2(-half_width, randf_range(-half_height, half_height))
		3: # Right edge inside view
			spawn_pos = cam_pos + Vector2(half_width, randf_range(-half_height, half_height))
			
	var instance = random_scene.instantiate() as Node2D
	if not instance:
		return
		
	instance.global_position = spawn_pos
	get_tree().current_scene.add_child(instance)
