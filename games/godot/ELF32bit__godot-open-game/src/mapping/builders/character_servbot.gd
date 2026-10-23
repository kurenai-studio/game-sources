extends MapperUtilities

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	if not entity.node_properties.has("position"):
		entity.node_properties["position"] = entity.center
	entity.node_properties["scale"] = (Vector3.ONE *
		entity.get_float_property("scale", 1.0))

	var height: float = 32.0 / map.settings.unit_size
	entity.node_properties["position"] += (Vector3.UP *
		entity.node_properties["scale"] * height * 0.5)

	return load("res://characters/scenes/servbot.tscn").instantiate()


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@PointClass",
		"size(-8 -8 0, 8 8 32)",
		'model("models/servbot.obj")',
		"=", "character_servbot", ":",
		'"dummy character"',
		"[",
		"\n]\n",
	]).replace(" \n", "\n"))
