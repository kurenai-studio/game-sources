extends MapperUtilities

@warning_ignore("unused_parameter")
static func build(map: MapperMap) -> void:
	var first_world_entity := map.get_first_world_entity()
	if first_world_entity and first_world_entity.brushes.size():
		var lightmap_gi := create_lightmap_gi(map, map.node)

	var paths: Dictionary = (
		map.loader.load_script("builders/path_corner").post_build(map))
	post_build_path_to_follow(map, "character_servbot", paths)

	build_base_class_targetname(map)
	map.loader.load_script("builders/func_door"
		).post_build(map)

	build_base_class_target(map)
	build_base_class_killtarget(map)
	build_base_class_parent(map)
	build_mesh_properties(map)
	build_mesh_gi_modes(map)

	build_safe_timers(map)
	build_animation_players(map)
	build_collision_layers(map)
	build_render_layers(map)
	build_sound_players(map)

	preload("func_connector.gd").post_build(map)
	build_forge_game_data(map)
	clear_empty_nodes(map)


static func _get_layers(map: MapperMap, with_alternative: bool = true) -> Dictionary:
	var directories: PackedStringArray = []
	directories.append(map.settings.game_directory)
	if with_alternative: directories.append_array(
		map.settings.alternative_game_directories)

	var layers: Dictionary = {
		"RENDER_2D": {},
		"RENDER_3D": {},
		"PHYSICS_2D": {},
		"PHYSICS_3D": {},
		"NAVIGATION_2D": {},
		"NAVIGATION_3D": {},
	}

	for directory_path in directories:
		var directory_layers: GDScript = load(
			directory_path.path_join("layers.gd"))
		if not directory_layers: continue

		if typeof(directory_layers.get("RENDER_2D")) == TYPE_DICTIONARY:
			layers["RENDER_2D"].merge(directory_layers.RENDER_2D, false)
		if typeof(directory_layers.get("RENDER_3D")) == TYPE_DICTIONARY:
			layers["RENDER_3D"].merge(directory_layers.RENDER_3D, false)
		if typeof(directory_layers.get("PHYSICS_2D")) == TYPE_DICTIONARY:
			layers["PHYSICS_2D"].merge(directory_layers.PHYSICS_2D, false)
		if typeof(directory_layers.get("PHYSICS_3D")) == TYPE_DICTIONARY:
			layers["PHYSICS_3D"].merge(directory_layers.PHYSICS_3D, false)
		if typeof(directory_layers.get("NAVIGATION_2D")) == TYPE_DICTIONARY:
			layers["NAVIGATION_2D"].merge(directory_layers.NAVIGATION_2D, false)
		if typeof(directory_layers.get("NAVIGATION_3D")) == TYPE_DICTIONARY:
			layers["NAVIGATION_3D"].merge(directory_layers.NAVIGATION_3D, false)

	return layers


static func _get_build_scripts(map: MapperMap, with_alternative: bool = true) -> Dictionary:
	var directories: PackedStringArray = []
	directories.append(map.settings.game_directory)
	if with_alternative: directories.append_array(
		map.settings.alternative_game_directories)

	var scripts: Dictionary = {}
	for directory_path in directories:
		var builders_path := directory_path.path_join(
			map.settings.game_builders_directory)
		var directory := DirAccess.open(builders_path)
		if not directory: continue

		for script_path in directory.get_files():
			if not script_path.ends_with(".gd"): continue
			if script_path.begins_with(map.settings.post_build_script_name):
				continue

			var path := builders_path.path_join(script_path)
			var script_name := script_path.trim_suffix(".gd")
			if script_name.ends_with("_"):
				script_name = script_name.trim_suffix("_")
				script_name += "*"

			if not scripts.has(script_name):
				scripts[script_name] = load(path)

	return scripts


static func build_base_class_target(map: MapperMap) -> void:
	var scripts := _get_build_scripts(map)
	for script_name in scripts:
		var script: GDScript = scripts[script_name]
		if typeof(script.get("BASE_CLASS_TARGET")) == TYPE_BOOL:
			if not script.BASE_CLASS_TARGET: continue
			_bind_target_base(map, script_name)


static func _bind_target_base(map: MapperMap, classname: String) -> void:
	for name in map.classnames:
		if not name.matchn(classname): continue
		for entity in map.classnames.get(name, []):
			entity.bind_signal_property("target",
				"targetname", "generic", "_on_generic_signal")
			entity.bind_node_path_property("target",
				"targetname", "_target")
			entity.bind_node_path_array_property("target",
				"targetname", "_targets")


static func build_base_class_killtarget(map: MapperMap) -> void:
	var scripts := _get_build_scripts(map)
	for script_name in scripts:
		var script: GDScript = scripts[script_name]
		if typeof(script.get("BASE_CLASS_KILLTARGET")) == TYPE_BOOL:
			if not script.BASE_CLASS_KILLTARGET: continue
			_bind_killtarget_base(map, script_name)


static func _bind_killtarget_base(map: MapperMap, classname: String) -> void:
	for name in map.classnames:
		if not name.matchn(classname): continue
		for entity in map.classnames.get(name, []):
			entity.bind_signal_property("killtarget",
				"targetname", "generic_free", "queue_free")
			entity.bind_node_path_property("killtarget",
				"targetname", "_kill_target")
			entity.bind_node_path_array_property("killtarget",
				"targetname", "_kill_targets")


static func build_base_class_parent(map: MapperMap) -> void:
	var scripts := _get_build_scripts(map)
	for script_name in scripts:
		var script: GDScript = scripts[script_name]
		if typeof(script.get("BASE_CLASS_PARENT")) == TYPE_BOOL:
			if not script.BASE_CLASS_PARENT: continue
			_bind_parent_base(map, script_name)
		else: _bind_parent_base(map, script_name)


static func _bind_parent_base(map: MapperMap, classname: String) -> void:
	for name in map.classnames:
		if not name.matchn(classname): continue
		for entity in map.classnames.get(name, []):
			if not entity.node: continue
			if not entity.node is Node3D: continue
			var target := map.get_first_entity_target(
				entity, "parent", "parentname")
			if not (target and target.node): continue
			if not target.node is Node3D: continue

			var node: Node3D = target.node
			var children := target.node.find_children("*",
				"AnimatableBody3D", false, false)
			if children.size(): node = children[0]

			var entity_node: Node3D = entity.node
			if entity.get_classname_property() == "func_door":
				if entity.node is AnimatableBody3D:
					entity_node = entity.node.get_parent()

			var remote_transform := RemoteTransform3D.new()
			remote_transform.transform = entity_node.transform
			add_global_child(remote_transform, node, map.settings)

			remote_transform.remote_path = (
				remote_transform.get_path_to(entity_node))
			remote_transform.use_global_coordinates = true
			remote_transform.update_position = true
			remote_transform.update_rotation = true
			remote_transform.update_scale = false

			# BUG: AnimatableBody3D needs special synchronization
			for child in entity_node.find_children(
				"*", "AnimatableBody3D", true, false):
					child.sync_to_physics = false


static func build_base_class_targetname(map: MapperMap) -> void:
	var scripts := _get_build_scripts(map)
	for script_name in scripts:
		var script: GDScript = scripts[script_name]
		if typeof(script.get("BASE_CLASS_TARGETNAME")) == TYPE_BOOL:
			if not script.BASE_CLASS_TARGETNAME: continue
			_bind_targetname_base(map, script_name)


static func _bind_targetname_base(map: MapperMap, classname: String) -> void:
	for name in map.classnames:
		if not name.matchn(classname): continue
		for entity in map.classnames.get(name, []):
			var node: String = entity.get_string_property("targetname", "")
			node = node.validate_node_name().strip_edges()
			if not node.is_empty() and entity.node:
				entity.node.set("name", node)


static func build_mesh_properties(map: MapperMap) -> void:
	var scripts := _get_build_scripts(map)
	for script_name in scripts:
		var script: GDScript = scripts[script_name]
		if typeof(script.get("MESH_PROPERTIES")) == TYPE_DICTIONARY:
			_set_mesh_properties(map, script_name, script.MESH_PROPERTIES,
				script.MESH_PROPERTIES.get("__recursive", false))


static func _set_mesh_properties(map: MapperMap, classname: String, properties: Dictionary, recursive: bool) -> void:
	for name in map.classnames:
		if not name.matchn(classname): continue
		for entity in map.classnames.get(name, []):
			if not entity.node: continue
			var children: Array[Node] = entity.node.find_children(
				"*", "MeshInstance3D", recursive, false)
			for child in children:
				for property in properties:
					child.set(property, properties[property])


static func build_mesh_gi_modes(map: MapperMap) -> void:
	if map.settings.prefer_static_lighting: return
	for node in map.node.find_children("*", "AnimatableBody3D", true, false):
		for child in node.find_children("*", "MeshInstance3D", false, false):
			if child.gi_mode == MeshInstance3D.GI_MODE_STATIC:
				child.gi_mode = MeshInstance3D.GI_MODE_DYNAMIC


static func build_safe_timers(map: MapperMap) -> void:
	for node in map.node.find_children("*", "Timer", true, false):
		node.process_callback = Timer.TIMER_PROCESS_PHYSICS
		node.wait_time = clampf(node.wait_time, 0.05, INF)


static func build_animation_players(map: MapperMap) -> void:
	for node in map.node.find_children("*", "AnimationPlayer", true, false):
		node.callback_mode_process = (
			AnimationPlayer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS)
		create_reset_animation(node, node.get_animation_library(""))


static func build_sound_players(map: MapperMap) -> void:
	for node in map.node.find_children("*", "AudioStreamPlayer3D", true, false):
		node.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		LAYERS.set_audio_stream_player_area_mask(node)


static func build_render_layers(map: MapperMap) -> void:
	for node in map.node.find_children("*", "VisualInstance3D", true, false):
		var path := map.node.get_path_to(node, false)

		var node_path: String = ""
		var layer_name: String = ""
		for index in range(path.get_name_count()):
			var path_name := path.get_name(index)
			node_path = node_path.path_join(path_name)

			if index == 0:
				layer_name = layer_name.path_join(path_name)
			elif index > 0:
				var path_node := map.node.get_node(node_path)
				layer_name = layer_name.path_join(path_node.get_class())

		var map_layers := _get_layers(map, true)
		if not map_layers.RENDER_3D.has(layer_name): continue
		var layers: int = map_layers.RENDER_3D[layer_name]
		if node.layers != 1: continue
		node.layers = layers


static func build_collision_layers(map: MapperMap) -> void:
	for node in map.node.find_children("*", "CollisionObject3D", true, false):
		var path := map.node.get_path_to(node, false)

		var node_path: String = ""
		var layer_name: String = ""
		for index in range(path.get_name_count()):
			var path_name := path.get_name(index)
			node_path = node_path.path_join(path_name)

			if index == 0:
				layer_name = layer_name.path_join(path_name)
			elif index > 0:
				var path_node := map.node.get_node(node_path)
				layer_name = layer_name.path_join(path_node.get_class())

		var map_layers := _get_layers(map, true)
		if not map_layers.PHYSICS_3D.has(layer_name): continue
		var layers: Array = map_layers.PHYSICS_3D[layer_name]
		if node.collision_layer != 1: continue
		if node.collision_mask != 1: continue
		node.collision_layer = layers[0]
		node.collision_mask = layers[1]


static func build_forge_game_data(map: MapperMap, with_alternative: bool = true) -> void:
	var entities := FileAccess.open(
		map.settings.game_directory.path_join(
			"entities.fgd"), FileAccess.WRITE)
	if not entities: return

	entities.store_string("// Game definition file (.fgd)\n\n")
	for script in _get_build_scripts(map, with_alternative).values():
		if script and script.has_method("build_forge_game_data"):
			script.build_forge_game_data(entities)
			entities.store_string("\n")


static func post_build_path_to_follow(map: MapperMap, classname: String, paths: Dictionary) -> void:
	for entity in map.classnames.get(classname, []):
		if not entity.node: continue
		var target := map.get_first_entity_target(
			entity, "target", "targetname", "path_corner")
		if not paths.get(target, []).size() > 0: continue
		var first_path: Dictionary = paths[target][0]

		entity.node.set("_path_to_follow",
			entity.node.get_path_to(first_path["path_node"]))
		entity.node.set("path_follow_progress", first_path["path_length"])

@warning_ignore("unused_parameter")
static func build_faces_colors(face: MapperFace, colors: PackedColorArray) -> void:
	if not face.parameters.size() >= 3: return
	var source_colors := colors.duplicate()
	var face_value := face.parameters[2]

	# barycentric wireframes mode can be adjusted via special face flags
	# colors.a = (16.0 - flags) / 16.0, where flags are [1], [2], [4], [8]
	# [8] is the sign of face value distinguishing triangles from n-gons
	# [1] will disable red vertex, [2] - green, [4] - blue
	var ngon_flag: int = (8 if int(face_value) < 0 else 0)
	face_value = str(absi(int(face_value)))

	# face colors array can be resized to triangulate the face
	colors.clear()
	for index in range(1, source_colors.size() - 1):
		colors.append(source_colors[0])
		colors.append(source_colors[index])
		colors.append(source_colors[index + 1])

	# barycentric wireframes mode can be applied per triangle in the face
	for index in range(mini(face_value.length(), source_colors.size() - 2)):
		var vertex_flags := int(face_value[index]) % 8
		var flags := (16.0 - float(vertex_flags | ngon_flag)) / 16.0
		colors[index * 3 + 0].a = flags
		colors[index * 3 + 1].a = flags
		colors[index * 3 + 2].a = flags


static func clear_empty_nodes(map: MapperMap) -> void:
	for child in map.node.get_children():
		if child.name in map.classnames:
			if child.get_child_count() == 0:
				child.free()
