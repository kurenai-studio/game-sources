extends Camera3D

@export var edge_margin:int = 100
@export var pan_speed: float = 25.0
@export var edge_boundary: int = 25

var pan_velocity: Vector3 = Vector3(0,0,0)
var viewport_size: Vector2 = Vector2(0,0)

func _ready() -> void:
	viewport_size = get_viewport().size
	
	
func _physics_process(delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	
	pan_velocity = Vector3(0,0,0)		
	
	if mouse_pos.x < edge_margin or Input.is_action_pressed("Move Map Left"):
		pan_velocity.x = - 1.0
	if mouse_pos.x > viewport_size.x - edge_margin or Input.is_action_pressed("Move Map Right"):
		pan_velocity.x = 1.0
	if mouse_pos.y < edge_margin or Input.is_action_pressed("Move Map Up"):
		pan_velocity.z = -1.0
	if mouse_pos.y > viewport_size.y - edge_margin or Input.is_action_pressed("Move Map Down"):
		pan_velocity.z = 1.0
	
	if pan_velocity.length_squared() > 0:
		var move_direction = pan_velocity.normalized()
		var movement = Vector3(move_direction.x,0,move_direction.z) * pan_speed * delta
		global_translate(movement)
