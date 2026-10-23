extends Node

var player: Node
var rng := RandomNumberGenerator.new()

var player_swim_area_type: int = -1:
	set(value):
		player_swim_area_type = value
		GUI.update_screen_effects()

var player_hovered_object: CollisionObject3D:
	set(value):
		player_hovered_object = value
		GUI.update_mouse_cursor_image_on_hover()

var player_selected_object: CollisionObject3D
var player_interactable_object: CollisionObject3D


func _ready() -> void:
	rng.seed = 0
