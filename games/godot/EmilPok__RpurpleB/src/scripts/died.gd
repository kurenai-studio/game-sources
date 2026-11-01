extends Area2D

@onready var main = get_tree().current_scene

func _on_body_entered(_body: Node2D) -> void:
	main._died()
