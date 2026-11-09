extends StaticBody3D
class_name OverrideConsole

signal console_activated

@export var is_activated: bool = false
@onready var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D")

func interact():
	if is_activated:
		return
	is_activated = true
	if FacilitySoundManager.instance:
		FacilitySoundManager.instance.play("terminal_beep", 1.2, 2.0)
	if mesh_instance:
		var mat = mesh_instance.get_active_material(0)
		if mat and mat is StandardMaterial3D:
			mat = mat.duplicate()
			mat.albedo_color = Color(0.1, 0.9, 0.3)
			mat.emission = Color(0.1, 1.0, 0.4)
			mat.emission_energy_multiplier = 2.0
			mesh_instance.set_surface_override_material(0, mat)
	console_activated.emit()
