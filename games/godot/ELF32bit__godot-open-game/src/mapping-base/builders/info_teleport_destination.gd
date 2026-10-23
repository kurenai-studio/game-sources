extends MapperUtilities

const BASE_CLASS_TARGETNAME := true

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	return Marker3D.new()


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@PointClass",
		"size(-32 -32 0, 32 32 64)",
		"=", "info_teleport_destination", ":",
		'"teleporter destination"',
		"[",
			"\n\tangle(float)", ":", '"angle of teleportation"',
			"\n\ttargetname(target_source)", ":", '"entity name"',
		"\n]\n",
	]).replace(" \n", "\n"))
