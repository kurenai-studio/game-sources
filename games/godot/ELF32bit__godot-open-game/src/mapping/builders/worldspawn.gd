extends MapperUtilities

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node: StaticBody3D = null
	node = create_merged_brush_entity(entity, "StaticBody3D")
	if not node: return null

	map.loader.load_script("builders/multimesh_grass"
		).build_distribution(map, entity, node)

	# creating ambient audio player under the node
	var ambient_ost_player := AudioStreamPlayer.new()
	ambient_ost_player.stream = (
		map.loader.load_sound("sounds/worldspawn-ambient"))
	node.add_child(ambient_ost_player, true)
	ambient_ost_player.autoplay = true

	# creating world environment (sky and fog)
	var world_environment := WorldEnvironment.new()
	world_environment.environment = (
		load("res://environments/heavens.tres"))
	node.add_child(world_environment, true)

	return node


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@SolidClass",
		"=", "worldspawn", ":",
		'"static world entity"',
		"[]\n",
	]).replace(" \n", "\n"))
