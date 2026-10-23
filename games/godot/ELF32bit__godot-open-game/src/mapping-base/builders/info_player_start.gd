extends MapperUtilities

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	entity.node_groups.append("info_player_start")
	return Marker3D.new()


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@PointClass",
		"size(-16 -16 -24, 16 16 32)",
		"color(0 255 0)",
		"=", "info_player_start", ":",
		'"player starting position"',
		"[]\n",
	]).replace(" \n", "\n"))
