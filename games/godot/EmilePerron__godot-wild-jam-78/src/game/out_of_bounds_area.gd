extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		GameManager.instance.player_died.emit("You fell out of the world!")
