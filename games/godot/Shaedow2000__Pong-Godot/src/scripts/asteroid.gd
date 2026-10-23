extends CharacterBody2D

const SPEED = 10000.0
@export var direction: Vector2

@onready var game: Node = $"../"

func _ready() -> void:
	add_to_group("asteroid")
	launch()

func _physics_process(delta: float) -> void:
	if not game.start:
		return
	
	velocity = SPEED * direction * delta
	
	move_and_slide()

func launch() -> void:
	var angle = randf_range(-PI/4, PI/4)
	direction = Vector2.RIGHT.rotated(angle)
	if randf() < 0.5:
		direction *= -1
	
	velocity = SPEED * direction

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		direction.x *= -1
		
		if body.velocity.y < 0 and velocity.y > 0:
			direction.y *= -1
		
		if body.velocity.y > 0 and velocity.y < 0:
			direction.y *= -1
