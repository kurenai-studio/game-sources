extends AnimatableBody3D
class_name VaultDoor

@export var open_offset: Vector3 = Vector3(0, 3.5, 0)
@export var open_duration: float = 1.0

var closed_position: Vector3
var is_open: bool = false
var current_tween: Tween = null

func _ready():
	closed_position = position

func set_door_state(open: bool) -> void:
	if is_open == open:
		return
	is_open = open
	
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		
	current_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var target_pos = closed_position + open_offset if is_open else closed_position
	current_tween.tween_property(self, "position", target_pos, open_duration)
	
	if SoundManager.instance:
		SoundManager.instance.play("door_open", 1.0 if is_open else 0.8, -3.0)

func _on_pressure_plate_activated(is_active: bool) -> void:
	set_door_state(is_active)
