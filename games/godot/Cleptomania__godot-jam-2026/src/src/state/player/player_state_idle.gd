class_name PlayerStateIdle extends PlayerState

@warning_ignore("unused_parameter")
func enter(previous_state: String, data := {}) -> void:
	player.update_animation("idle")
	
@warning_ignore("unused_parameter")
func update(delta: float) -> void:
	if player.direction != Vector2.ZERO:
		finished.emit(MOVING)
		return
		
	player.velocity = Vector2.ZERO
