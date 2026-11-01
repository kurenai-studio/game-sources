class_name State extends Node

@warning_ignore("unused_signal")
signal finished(next_state: String, data: Dictionary)

@warning_ignore("unused_parameter")
func input(event: InputEvent) -> void:
	pass

@warning_ignore("unused_parameter")
func update(delta: float) -> void:
	pass
	
@warning_ignore("unused_parameter")
func physics_update(delta: float) -> void:
	pass

@warning_ignore("unused_parameter")
func enter(previous_state: String, data := {}) -> void:
	pass
	
func exit() -> void:
	pass
