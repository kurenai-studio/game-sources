extends Area2D

var SPEED = 200.0
var rotation_offset = 0.0

var active = true

func _ready() -> void:
	rotation = rotation_offset
	
	
func _physics_process(delta: float) -> void:
	if not active:
		return
	global_position += Vector2.RIGHT.rotated(rotation_offset) * SPEED * delta
	
	
func _on_body_entered(body: Node2D) -> void:
	if not active:
		return
	
	_destroy_bullet()
	
	if body.has_method("player_2"):
		body._knockback(Vector2.RIGHT.rotated(rotation_offset) * SPEED)
	
func _on_area_entered(area: Area2D) -> void:
	if not active:
		return
	
	_destroy_bullet()
	if area.has_method("_iam_button"):
		area._iam_button()

func _destroy_bullet():
	active = false
	$AnimationPlayer.play("destroyed")
	$Particles.emitting = false
	$CollisionShape2D.set_deferred("disabled", true)
	$Destroy_bullet.start()
	$hit.play()

func _on_timer_timeout() -> void:
	queue_free()

func _on_destroy_bullet_timeout() -> void:
	queue_free()
