extends "mining_coal.gd"

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node: Node3D = null
	node = preload("mining_coal.gd").build(map, entity)
	if not node: return null

	for child in node.find_children("*", "AnimatableBody3D", false, false):
		_change_script(child, map.loader.load_script(
			"scripts/mining_iron"))

	return node


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@SolidClass",
		"=", "mining_iron", ":",
		'"iron mining node"',
		"[",
			"\n\tcursor(integer)", ":", '"mouse cursor override"', ":", "1",
			"\n\ttarget(target_destination)", ":", '"target to activate"',
			"\n\tkilltarget(target_destination)", ":", '"target to destroy"',
			"\n\ttargetname(target_source)", ":", '"entity name"',
			"\n\twait(float)", ":", '"wait time"', ":", '"-1.0"',
		"\n]\n",
	]).replace(" \n", "\n"))
