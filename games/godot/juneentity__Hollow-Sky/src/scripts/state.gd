class_name State
extends Node

@export
var animation_name : String
@export_range(0,1000)
var move_speed : float = 300
@export 
var epsilon: float = 2

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

var parent: Player 

func enter() -> void:
	#parent.animations.play(animation_name)
	pass

func exit() -> void:
	pass 

func process_input(event: InputEvent) -> State:
	return null
	
func process_frame(delta: float) -> State:
	return null

func process_physics(delta: float) -> State:
	return null
