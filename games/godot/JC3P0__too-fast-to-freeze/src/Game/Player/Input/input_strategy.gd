class_name InputStrategy
extends Node

## Base class for all player input strategies (Strategy pattern).
## Concrete strategies implement process_input and handle_input_event.
## Swap strategies via the InputMode export on player.gd.

func process_input(_player: CharacterBody3D, _delta: float) -> void:
	pass

func handle_input_event(_player: CharacterBody3D, _event: InputEvent) -> void:
	pass

func get_strategy_name() -> String:
	return ""
