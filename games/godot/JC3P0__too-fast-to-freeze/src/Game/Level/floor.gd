extends StaticBody3D

## Compensates for non-square floor mesh — X scroll appears faster if floor is wider than long.
## Set to floor_length / floor_width. If floor is square, leave at 1.0.
@export var x_scroll_scale: float = 1.0

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
var player: Node = null

func _physics_process(delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("Player")
	if not player:
		return
	var offset: float = player.player_current_speed * delta * 0.09
	var mat: Material = mesh_instance_3d.get_active_material(0)
	mat.uv1_offset.z -= offset * player.player_direction.z
	mat.uv1_offset.x -= offset * player.player_direction.x * x_scroll_scale
