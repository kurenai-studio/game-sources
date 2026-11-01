extends CharacterBody2D

const SPEED = 9000.0

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_up_b", "move_down_b")
	
	velocity.y = SPEED * direction * delta
	velocity.x = 0
	
	move_and_slide()
