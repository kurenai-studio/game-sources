class_name Candy
extends Area2D


func _on_body_entered(body: Node2D) -> void:
	set_process_mode.call_deferred(Node.PROCESS_MODE_DISABLED)
	get_node("AnimatedSprite2D").visible = false
	$Collect.play()


func _on_collect_finished() -> void:
	queue_free()
