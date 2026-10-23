extends MapperUtilities

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	if entity.metadata.has("_closed_path"): return null
	if entity.metadata.has("_open_path"): return null

	# finding path_corner targets from a random path position
	var targets := map.get_first_entity_target_recursively(
		entity, "target", "targetname", "path_corner")

	# marking and sorting closed paths
	if targets.size() > 0 and targets[-1] == entity:
		var start_targetname: Array = [entity,
			entity.get_string_property("targetname", "")]
		for path_entity in targets:
			var targetname = path_entity.get_string_property("targetname", "")
			if targetname.naturalcasecmp_to(start_targetname[1]) < 0:
				start_targetname = [path_entity, targetname]
		for path_entity in targets:
			path_entity.metadata["_closed_path"] = start_targetname[0]

	# also resolving open paths
	elif targets.size() > 0:
		for path_entity in targets:
			path_entity.metadata["_open_path"] = false
		entity.metadata["_open_path"] = true

	return null


static func post_build(map: MapperMap) -> Dictionary:
	var paths: Dictionary = {}
	for entity in map.classnames.get("path_corner", []):
		if entity == entity.metadata.get("_closed_path", null):
			var targets := map.get_first_entity_target_recursively(
				entity, "target", "targetname", "path_corner")
			targets.insert(0, entity)
			targets.pop_back()

			# creating closed path from targets
			var path := build_path(map, targets, true)
			var path_length = path.curve.get_meta("_MAPPER_LENGTH")
			for index in range(targets.size()):
				paths.get_or_add(targets[index], []).append({
					"path_length": path_length[index],
					"path_is_closed": true,
					"path_node": path })
			path.curve.remove_meta("_MAPPER_LENGTH")

		elif entity.metadata.get("_open_path", false):
			var targets := map.get_first_entity_target_recursively(
				entity, "target", "targetname", "path_corner")
			targets.insert(0, entity)

			# creating open path from targets
			var path := build_path(map, targets, false)
			var path_length = path.curve.get_meta("_MAPPER_LENGTH")
			for index in range(targets.size()):
				paths.get_or_add(targets[index], []).append({
					"path_length": path_length[index],
					"path_is_closed": false,
					"path_node": path })
			path.curve.remove_meta("_MAPPER_LENGTH")

	return paths


static func build_path(map: MapperMap, path_entities: Array[MapperEntity], is_closed: bool) -> Path3D:
	var path := Path3D.new()
	path.curve = Curve3D.new()
	var curve_length: Array = []
	for index in range(path_entities.size()):
		var path_entity: MapperEntity = path_entities[index]
		if path_entity.get_origin_property(null) == null: continue
		var tilt := deg_to_rad(path_entity.get_float_property("tilt", 0.0))
		var point: Vector3 = path_entity.get_origin_property()

		# adding curve point to the path (supporting tilt)
		path.curve.add_point(point, Vector3.ZERO, Vector3.ZERO)
		path.curve.set_point_tilt(path.curve.point_count - 1, tilt)
		curve_length.append(path.curve.get_baked_length())

	if is_closed:
		path.curve.closed = is_closed
		curve_length.append(path.curve.get_baked_length())
	path.curve.set_meta("_MAPPER_LENGTH", curve_length)

	var class_root := map.node.find_child("path_corner", false, false)
	class_root.add_child(path, map.settings.readable_node_names)
	return path


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@PointClass",
		"size(16 16 16)",
		"color(0 255 255)",
		"=", "path_corner", ":",
		'"waypoint for platforms and monsters"',
		"[",
			"\n\ttarget(target_destination)", ":", '"next target"',
			"\n\ttargetname(target_source)", ":", '"entity name"',
			"\n\ttilt(float)", ":", '"path tilt (degrees)"', ":", '"0.0"',
			"\n\twait(float)", ":", '"wait time"', ":", '"0.0"',
		"\n]\n",
	]).replace(" \n", "\n"))
