class_name MobStateIdle extends MobState

@warning_ignore("unused_parameter")
func enter(previous_state: String, data := {}) -> void:
	mob.update_animation("idle")
	
@warning_ignore("unused_parameter")
func update(delta: float) -> void:
	if mob.direction != Vector2.ZERO:
		finished.emit(MOVING)
		return
		
	mob.velocity = Vector2.ZERO
