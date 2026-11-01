extends CharacterBody2D

@onready var paddle: CharacterBody2D = $"../paddle"

@export var speed: float = 500

signal ball_lost()
signal scored()
func _physics_process(delta: float) -> void:
	move_and_slide()
	
	# --- Bounce Logic ---
	for i in get_slide_collision_count():
		var collider = get_slide_collision(i)
		var collision = collider.get_collider()
		if collider.get_normal().y != 0:
			velocity.y = -velocity.y
		if collider.get_normal().x != 0:
			velocity.x = -velocity.x
		
		if collision == paddle:
			velocity.x = clamp((global_position.x - paddle.global_position.x) * 20, -200, 200)
		
		if collision.has_method("destroy"):
			scored.emit()
			collision.destroy()
		break

# Functions are used in game.gd
func start_round():
	if velocity == Vector2.ZERO:
		velocity = Vector2(randf_range(-200, 200), speed)

func restart():
	global_position = Vector2.ZERO
	velocity = Vector2.ZERO

func _on_gate_body_entered(body: Node2D) -> void:
	ball_lost.emit()
