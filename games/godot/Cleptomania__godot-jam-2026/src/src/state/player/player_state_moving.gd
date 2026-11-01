class_name PlayerStateMoving extends PlayerState

@warning_ignore("unused_parameter")
func enter(previous_state: String, data := {}) -> void:
	player.update_animation("walk")

@warning_ignore("unused_parameter")
func update(delta: float) -> void:
	if player.direction == Vector2.ZERO:
		finished.emit(IDLE)
		return
		
	player.velocity = player.direction * player.speed
	
	if player.set_animation_direction():
		player.update_animation("walk")
