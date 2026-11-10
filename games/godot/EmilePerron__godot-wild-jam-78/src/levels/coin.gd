extends Node2D
class_name Coin


func collect() -> void:
	Money.gain(1)
	self.queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		collect()
