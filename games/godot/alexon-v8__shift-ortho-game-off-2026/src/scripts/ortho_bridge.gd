extends StaticBody3D
class_name OrthoBridge

@export var active_in_ortho_only: bool = true
@export var required_yaw_deg: float = -1.0 # -1 means any angle in ortho
@export var angle_tolerance_deg: float = 22.5

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var is_solid: bool = false

func _ready():
	update_state(false, 0.0)

func update_state(is_ortho: bool, camera_yaw_deg: float) -> void:
	var should_be_solid = false
	if active_in_ortho_only:
		if is_ortho:
			if required_yaw_deg < 0.0:
				should_be_solid = true
			else:
				var diff = abs(wrapf(camera_yaw_deg - required_yaw_deg, -180.0, 180.0))
				if diff <= angle_tolerance_deg:
					should_be_solid = true
		else:
			should_be_solid = false
	else:
		should_be_solid = true

	set_solid(should_be_solid)

func set_solid(solid: bool) -> void:
	if is_solid == solid:
		return
	is_solid = solid
	if collision_shape:
		collision_shape.disabled = not is_solid
	if mesh_instance:
		if is_solid:
			mesh_instance.transparency = 0.0
			var mat = mesh_instance.get_active_material(0)
			if mat and mat is StandardMaterial3D:
				mat.albedo_color = Color(0.1, 0.9, 1.0, 0.85)
				mat.emission_enabled = true
				mat.emission = Color(0.0, 0.7, 1.0)
				mat.emission_energy_multiplier = 2.0
		else:
			mesh_instance.transparency = 0.85
			var mat = mesh_instance.get_active_material(0)
			if mat and mat is StandardMaterial3D:
				mat.albedo_color = Color(0.2, 0.5, 0.7, 0.15)
				mat.emission_enabled = false
