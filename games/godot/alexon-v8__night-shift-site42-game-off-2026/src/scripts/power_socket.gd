extends StaticBody3D
class_name PowerSocket

signal power_restored

@export var is_powered: bool = false
@onready var socket_light: OmniLight3D = get_node_or_null("SocketLight")
@onready var cell_mesh_slot: Node3D = get_node_or_null("CellMeshSlot")

func _ready():
	_update_visuals()

func insert_cell() -> bool:
	if is_powered:
		return false
	is_powered = true
	if cell_mesh_slot:
		cell_mesh_slot.visible = true
	_update_visuals()
	if FacilitySoundManager.instance:
		FacilitySoundManager.instance.play("power_cell_insert", 1.0, 2.0)
	power_restored.emit()
	return true

func _update_visuals():
	if socket_light:
		socket_light.light_color = Color(0.1, 1.0, 0.4) if is_powered else Color(1.0, 0.2, 0.1)
		socket_light.light_energy = 2.5 if is_powered else 0.8
