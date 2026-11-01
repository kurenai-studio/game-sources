extends CharacterBody2D

@export var speed: float = 100.0
signal died

func _ready():
	$AnimatedSprite2D.animation = "walk"
	$AnimatedSprite2D.play()

func _process(delta):
	velocity = Vector2(-speed, 0)
	move_and_slide()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	die()

func die():
	queue_free()
	died.emit()
