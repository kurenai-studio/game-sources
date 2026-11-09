extends StaticBody3D
class_name MaintenanceTerminal

signal terminal_interacted

@onready var screen_mesh: MeshInstance3D = get_node_or_null("ScreenMesh")
@onready var terminal_light: OmniLight3D = get_node_or_null("TerminalLight")

func interact():
	if FacilitySoundManager.instance:
		FacilitySoundManager.instance.play("terminal_beep", randf_range(0.95, 1.05), 0.0)
	terminal_interacted.emit()
