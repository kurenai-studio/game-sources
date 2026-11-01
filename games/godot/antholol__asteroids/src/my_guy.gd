extends CharacterBody2D
var speed:float = 3
var moveTarget:float = 0
var move:float = 0
var turnTarget:float = 0

func _process(_delta: float) -> void:
	var turn:float = Input.get_axis("A","D")
	rotation_degrees += turn * 6
	#rotation_degrees = lerp(rotation_degrees,turnTarget,0.1)
	
	move = Input.get_axis("S", "W")
	#move = lerp(move, moveTarget, 0.001)
	var direction:Vector2 = Vector2.from_angle(rotation).normalized()
	velocity += direction * move * speed 
	move_and_slide()
	
	print(position)
