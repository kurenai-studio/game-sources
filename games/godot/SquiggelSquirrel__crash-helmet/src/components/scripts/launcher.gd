extends Area2D

@export var right := false



func _on_body_entered(body: Node2D) -> void:
	if ! body is CharacterBody2D:
		return
	if (body.velocity.x > 0) != right:
		return
	if abs(body.get_real_velocity().x) < 10:
		return
	body.velocity = body.get_real_velocity() * 1.5
