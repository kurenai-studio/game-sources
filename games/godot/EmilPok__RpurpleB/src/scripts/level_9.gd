extends Node2D

@onready var main = get_parent()

func _ready() -> void:
	main.sus_button = $Button5.Sprite
