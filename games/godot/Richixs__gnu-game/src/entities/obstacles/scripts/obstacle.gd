extends Area2D

func _ready() -> void:
	if $AnimatedSprite2D:
		$AnimatedSprite2D.play("default")

func _physics_process(delta: float) -> void:
	position.x -= Global.current_speed * delta
	
	if position.x < -15:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		AudioManager.play_die()
		Global.game_active = false
		Global.game_over_triggered.emit()
		get_tree().paused = true
