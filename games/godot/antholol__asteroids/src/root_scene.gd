extends Node2D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ESC"):
		get_tree().change_scene_to_file("res://main_menu.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
