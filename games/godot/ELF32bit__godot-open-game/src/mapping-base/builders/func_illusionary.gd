extends MapperUtilities

const MESH_PROPERTIES: Dictionary = {
	"cast_shadow": MeshInstance3D.SHADOW_CASTING_SETTING_OFF,
	"gi_mode": MeshInstance3D.GI_MODE_STATIC,
}

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node: Node3D = null
	node = create_merged_brush_entity(entity,
		"Node3D", true, false, false)
	if not node: return null
	return node


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@SolidClass",
		"=", "func_illusionary", ":",
		'"static nonsolid model"',
		"[]\n",
	]).replace(" \n", "\n"))
