class_name MobStateMoving extends MobState

@warning_ignore("unused_parameter")
func enter(previous_state: String, data := {}) -> void:
	mob.update_animation("walk")

@warning_ignore("unused_parameter")
func update(delta: float) -> void:
	if mob.direction == Vector2.ZERO:
		finished.emit(IDLE)
		return
		
	mob.velocity = mob.direction * mob.speed
	
	if mob.set_animation_direction():
		mob.update_animation("walk")
