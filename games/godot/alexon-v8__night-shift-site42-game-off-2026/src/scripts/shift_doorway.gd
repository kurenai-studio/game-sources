extends Area3D
class_name ShiftDoorway

signal doorway_anchored(id: String, anchored: bool)
signal doorway_shifted(id: String, is_altered: bool)

@export var doorway_id: String = "door_01"
@export var doorway_name: String = "COOLANT ACCESS 01"
@export var is_anchored: bool = false
@export var default_destination_path: NodePath
@export var shifted_destination_path: NodePath

var is_shifted: bool = false
var default_destination: Node3D = null
var shifted_destination: Node3D = null

@onready var anchor_glow: MeshInstance3D = get_node_or_null("AnchorGlow")

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if has_node(default_destination_path):
		default_destination = get_node(default_destination_path)
	if has_node(shifted_destination_path):
		shifted_destination = get_node(shifted_destination_path)
		
	update_anchor_visuals()
	_apply_room_states()

func set_anchored(anchored: bool) -> void:
	is_anchored = anchored
	update_anchor_visuals()
	doorway_anchored.emit(doorway_id, is_anchored)

func trigger_shift(force: bool = false) -> bool:
	if is_anchored and not force:
		# Quantum locked by Polaroid photograph!
		return false
		
	is_shifted = not is_shifted
	_apply_room_states()
	
	if FacilitySoundManager.instance:
		FacilitySoundManager.instance.play("room_shift_distant", randf_range(0.9, 1.1), 0.0)
		
	doorway_shifted.emit(doorway_id, is_shifted)
	return true

func _apply_room_states():
	if default_destination:
		default_destination.visible = not is_shifted
		_toggle_collisions(default_destination, not is_shifted)
	if shifted_destination:
		shifted_destination.visible = is_shifted
		_toggle_collisions(shifted_destination, is_shifted)

func _toggle_collisions(node: Node, enabled: bool):
	if node is CollisionShape3D:
		node.disabled = not enabled
	for child in node.get_children():
		_toggle_collisions(child, enabled)

func update_anchor_visuals():
	if anchor_glow:
		anchor_glow.visible = is_anchored
		var mat = anchor_glow.get_active_material(0)
		if mat and mat is StandardMaterial3D:
			mat.emission_enabled = true
			mat.emission = Color(0.1, 1.0, 0.4) if is_anchored else Color(0.2, 0.2, 0.2)

func _on_body_entered(body: Node3D):
	# When player passes through, potentially trigger shift behind them after exiting
	pass

func _on_body_exited(body: Node3D):
	if body is CharacterBody3D and not is_anchored:
		# Random chance or deterministic shift when player leaves room
		trigger_shift()
