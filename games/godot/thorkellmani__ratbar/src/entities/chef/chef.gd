extends CharacterBody2D

const SPEED = 300
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	var movement_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if movement_vector:
		velocity = movement_vector * SPEED
	else:
		velocity = Vector2.ZERO

	move_and_slide()
