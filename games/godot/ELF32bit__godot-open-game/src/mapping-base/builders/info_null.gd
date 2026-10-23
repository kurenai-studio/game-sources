extends MapperUtilities

const BASE_CLASS_TARGETNAME := true

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	return null


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@PointClass",
		"color(200 150 150)",
		"=", "info_null", ":",
		'"spotlight target"',
		"[",
			"\n\ttargetname(target_source)", ":", '"entity name"',
		"\n]\n",
	]).replace(" \n", "\n"))
