extends Area2D


func _on_body_entered(body: Node2D) -> void:
	$Flag.show()
	if body is Player:
		body.emit_win()
		%Ding.play()
