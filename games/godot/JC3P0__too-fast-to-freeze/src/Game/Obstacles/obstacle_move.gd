extends CharacterBody3D

var player: CharacterBody3D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(_delta: float) -> void:
	velocity.z = player.player_direction.z * player.player_current_speed
	velocity.x = player.player_direction.x * player.player_current_speed
	move_and_slide()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body != self:
		if body.is_in_group("Obstacle"):
			body.queue_free()
