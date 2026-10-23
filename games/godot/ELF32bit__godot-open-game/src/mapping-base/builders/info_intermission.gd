extends MapperUtilities

const BASE_CLASS_TARGETNAME := true

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node := Camera3D.new()
	node.current = false

	var root := Node3D.new()
	root.transform = node.transform
	add_global_child(node, root, map.settings)

	entity.node_groups.append("info_intermission")
	root.set_script(map.loader.load_script(
		"scripts/info_intermission"))

	root.set("_camera", root.get_path_to(node))

	return root


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@PointClass",
		"=", "info_intermission", ":",
		'"intermission camera"',
		"[",
			"\n\tmangle(string)", ":", '"camera angle (pitch yaw roll)"',
			"\n\ttargetname(target_source)", ":", '"entity name"',
		"\n]\n",
	]).replace(" \n", "\n"))
