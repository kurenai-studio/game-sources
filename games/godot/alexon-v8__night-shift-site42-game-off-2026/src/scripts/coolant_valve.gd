extends StaticBody3D
class_name CoolantValve

signal valve_stabilized

@export var turns_required: int = 4
var current_turns: int = 0
var is_complete: bool = false

@onready var wheel_mesh: Node3D = get_node_or_null("ValveWheel")
@onready var status_light: OmniLight3D = get_node_or_null("StatusLight")

func interact():
	if is_complete:
		return
		
	current_turns += 1
	if wheel_mesh:
		wheel_mesh.rotate_z(deg_to_rad(60.0))
		
	if FacilitySoundManager.instance:
		FacilitySoundManager.instance.play("valve_turn", randf_range(0.9, 1.1), 0.0)
		
	if current_turns >= turns_required:
		is_complete = true
		if status_light:
			status_light.light_color = Color(0.2, 1.0, 0.4)
		valve_stabilized.emit()
