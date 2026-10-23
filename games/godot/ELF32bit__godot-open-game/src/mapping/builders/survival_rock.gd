extends MapperUtilities

const BASE_CLASS_TARGET := true
const BASE_CLASS_KILLTARGET := true
const BASE_CLASS_TARGETNAME := true

const MESH_PROPERTIES: Dictionary = {
	"cast_shadow": MeshInstance3D.SHADOW_CASTING_SETTING_OFF,
	"visibility_range_end": 25.0,
	"__recursive": true
}

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node: Node3D = null
	node = preload("mining_coal.gd").build(map, entity)
	if not node: return null

	for child in node.find_children("*", "AnimatableBody3D", false, false):
		preload("mining_coal.gd")._change_script(child,
			map.loader.load_script("scripts/survival_rock"))

	return node


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@SolidClass",
		"=", "survival_rock", ":",
		'"collectable rock"',
		"[",
			"\n\tcursor(integer)", ":", '"mouse cursor override"', ":", "1",
			"\n\ttarget(target_destination)", ":", '"target to activate"',
			"\n\tkilltarget(target_destination)", ":", '"target to destroy"',
			"\n\ttargetname(target_source)", ":", '"entity name"',
			"\n\twait(float)", ":", '"wait time"', ":", '"-1.0"',
		"\n]\n",
	]).replace(" \n", "\n"))
