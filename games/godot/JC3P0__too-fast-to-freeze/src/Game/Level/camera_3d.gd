extends Camera3D

@export var player: Node3D
@export var follow_offset = Vector3(0, 3.7, 4.5)
@export var follow_speed = 8.0
@export var lateral_camera_offset = 1.8

func _ready():
	player = get_node_or_null("../Player")
	if player == null:
		print("Player node not found in the current scene")

func _physics_process(delta: float) -> void:
	if player:
		var current_position = global_transform.origin
		var player_position = player.global_transform.origin
		
		var lateral_offset = 0
		if player.turn_direction == 0:
			lateral_offset = 0
		elif player.turn_direction < 0:
			lateral_offset = -lateral_camera_offset
		elif player.turn_direction > 0:
			lateral_offset = lateral_camera_offset
		
		var target_position = Vector3(
			player_position.x + follow_offset.x + lateral_offset,
			current_position.y,
			player_position.z + follow_offset.z
		)
		
		global_transform.origin = global_transform.origin.lerp(target_position, follow_speed * delta)
