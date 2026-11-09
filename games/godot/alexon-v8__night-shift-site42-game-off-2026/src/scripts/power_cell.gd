extends RigidBody3D
class_name PowerCell

@export var cell_id: String = "cell_alpha"
var is_held: bool = false
var holder_node: Node3D = null

func grab(holder: Node3D):
	is_held = true
	holder_node = holder
	freeze = true

func release():
	is_held = false
	freeze = false
	holder_node = null

func update_held_position(target_pos: Vector3):
	if is_held:
		global_position = global_position.lerp(target_pos, 0.3)
