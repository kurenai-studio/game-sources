@tool
extends SpotLight3D

enum ShapeMode { CAPSULE }
@export var shape_mode: ShapeMode = ShapeMode.CAPSULE

@export var capsule_height: float = 1.0
@export var capsule_radius: float = 0.35
@export var capsule_centered: bool = true
@export var uniform_scale: float = 1.0
@export var jump_height: float = 2.0


func update_shape() -> void:
	match shape_mode:
		ShapeMode.CAPSULE:
			if not capsule_centered:
				position.y = capsule_height
			else: position.y = capsule_height * 0.5
			rotation_degrees = Vector3(-90.0, 0.0, 0.0)
			spot_range = jump_height * uniform_scale + capsule_height * 0.5
			spot_angle = rad_to_deg(atan(capsule_radius /
				(capsule_height - capsule_radius)))


func _ready() -> void:
	if not Engine.is_editor_hint():
		assert(light_negative == true)
		set_physics_process(false)
	update_shape()

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	update_shape()
