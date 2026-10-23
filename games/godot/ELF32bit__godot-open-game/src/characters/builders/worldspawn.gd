extends MapperUtilities

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	return preload("func_group.gd").build_animated_geometry(map, entity)


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@SolidClass",
		"=", "worldspawn", ":",
		'"static world entity"',
		"[]\n",
	]).replace(" \n", "\n"))
