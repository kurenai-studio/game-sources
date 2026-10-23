extends MapperUtilities

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node: StaticBody3D = null
	node = create_merged_brush_entity(entity, "StaticBody3D")
	if not node: return null

	# creating ambient audio player under the node
	var ambient_ost_player := AudioStreamPlayer.new()
	ambient_ost_player.stream = (
		map.loader.load_sound("sounds/worldspawn-ambient"))
	node.add_child(ambient_ost_player, true)
	ambient_ost_player.autoplay = true

	return node


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@SolidClass",
		"=", "worldspawn", ":",
		'"static world entity"',
		"[]\n",
	]).replace(" \n", "\n"))
