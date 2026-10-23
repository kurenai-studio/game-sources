@tool
extends SpotLight3D

enum ShapeMode { CAPSULE }
@export var shape_mode: ShapeMode = ShapeMode.CAPSULE

@export var capsule_height: float = 1.0
@export var capsule_radius: float = 0.35
@export var capsule_centered: bool = true
@export var uniform_scale: float = 1.0
@export var jump_height: float = 2.0

@onready var _cutout: SpotLight3D = $CUTOUT
@export var selection_color := Color.DEEP_PINK
@export var selection_cutout: float = 0.85

# WARNING: spot_attenuation <= 0.0 is not cross-platform
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

			_cutout.spot_range = spot_range
			_cutout.spot_angle = spot_angle
			_cutout.spot_angle *= selection_cutout


func update_selection_color() -> void:
	_cutout.light_color = selection_color
	light_color = selection_color


func _ready() -> void:
	if not Engine.is_editor_hint():
		assert(light_energy == _cutout.light_energy)
		assert(_cutout.light_negative == true)
		assert(light_negative == false)
		set_physics_process(false)
	update_selection_color()
	update_shape()

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	update_selection_color()
	update_shape()
