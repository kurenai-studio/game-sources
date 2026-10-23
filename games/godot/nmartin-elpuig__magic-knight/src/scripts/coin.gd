extends Area2D


@onready var game_manager: Node = %gameManager


func _on_body_entered(body: Node2D) -> void:
	game_manager.incrementa_un_punto()
	queue_free()
