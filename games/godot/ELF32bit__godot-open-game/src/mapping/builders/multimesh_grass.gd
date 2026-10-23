extends MapperUtilities

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	return null


static func build_distribution(map: MapperMap, entity: MapperEntity, parent: Node) -> void:
	var multimesh: MultiMesh = load("res://multimeshes/grass.tres")
	var transform_array := entity.generate_surface_distribution(
		["prototype/*", "color/*"], 1.0, 0.0, 60.0, false, false,
			map.settings.options.get("grass_seed", 0))

	var spread_radius: float = 0.25
	var min_scale := Vector3(0.5, 0.5, 0.5)
	var max_scale := Vector3(0.75, 1.0, 0.75)
	var snap_degrees := Vector3(-1.0, 0.0, -1.0)

	if not is_zero_approx(spread_radius):
		spread_transform_array(transform_array, spread_radius)
	scale_transform_array(transform_array, min_scale, max_scale)
	rotate_transform_array(transform_array, snap_degrees)

	var painted_transform_array: PackedVector3Array = []
	for map_entity in map.classnames.get("multimesh_grass", []):
		var position = map_entity.get_origin_property(null)
		if position == null: continue

		var local_position := Vector3(position) - entity.center
		var radius = map_entity.get_unit_property("radius", 300.0)
		var hardness = map_entity.get_float_property("hardness", 1.0)
		painted_transform_array.append_array(erase_transform_array(
			transform_array, local_position, radius, hardness))

	var mesh_instance := create_merged_multimesh_instance(
		entity, parent, multimesh, painted_transform_array)
	mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_STATIC
	mesh_instance.gi_lightmap_texel_scale = 0.25


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@PointClass",
		"=", "multimesh_grass", ":",
		'"grass brush"',
		"[",
			"\n\tradius(integer)", ":", '"radius (units)"', ":", "300",
			"\n\thardness(float)", ":", '"hardness"', ":", '"1.0"',
		"\n]\n",
	]).replace(" \n", "\n"))
