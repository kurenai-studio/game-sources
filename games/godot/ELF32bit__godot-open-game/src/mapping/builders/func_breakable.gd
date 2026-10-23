extends MapperUtilities

const MESH_PROPERTIES: Dictionary = {
	"gi_mode": MeshInstance3D.GI_MODE_DYNAMIC,
	"__recursive": true,
}

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node: Node3D = null
	node = create_brush_entity(entity, "Node3D", "RigidBody3D")
	if not node: return null
	return node


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@SolidClass",
		"=", "func_breakable", ":",
		'"group of physically simulated brushes"',
		"[]\n",
	]).replace(" \n", "\n"))
