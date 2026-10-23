extends MapperUtilities

const BASE_CLASS_TARGET := true
const BASE_CLASS_KILLTARGET := true
const BASE_CLASS_TARGETNAME := true
const MERGE_SOUND_PLAYERS := false
const LINK_UNITS: float = 32.0

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node: AnimatableBody3D = null
	node = create_merged_brush_entity(entity, "AnimatableBody3D")
	if not node: return null

	if not MERGE_SOUND_PLAYERS:
		var move_sound_player := AudioStreamPlayer3D.new()
		node.add_child(move_sound_player, map.settings.readable_node_names)
		move_sound_player.stream = map.loader.load_sound("sounds/func_door-move")
		var noise1: AudioStream = entity.get_sound_property("noise1", null)
		if noise1 != null: move_sound_player.stream = noise1
		move_sound_player.playing = false

		var stop_sound_player := AudioStreamPlayer3D.new()
		node.add_child(stop_sound_player, map.settings.readable_node_names)
		stop_sound_player.stream = map.loader.load_sound("sounds/func_door-stop")
		var noise2: AudioStream = entity.get_sound_property("noise2", null)
		if noise2 != null: stop_sound_player.stream = noise2
		stop_sound_player.playing = false

	node.set_script(map.loader.load_script("scripts/func_door+"))

	return node


static func post_build(map: MapperMap) -> void:
	for entity in map.classnames.get("func_door", []):
		var data := _post_build_linking_data(map, entity)
		if not data.size(): continue
		post_build_linking_data(map, data)


static func _post_build_linking_data(map: MapperMap, entity: MapperEntity) -> Array:
	if not entity.node: return []
	if not entity.aabb.has_surface(): return []
	if entity.metadata.get("__is_linked", false):
		return []

	var aabb := AABB(entity.aabb)
	var entities: Array[MapperEntity] = [entity]
	if entity.get_int_property("spawnflags", 0) & 4: # don't link
		return [entities, aabb]

	entity.metadata["__is_linked"] = true
	var grow_by: float = LINK_UNITS / map.settings.unit_size
	for another_entity in map.classnames.get("func_door", []):
		if not another_entity.node: continue
		if not another_entity.aabb.has_surface(): continue
		if another_entity.metadata.get("__is_linked", false): continue
		if another_entity.get_int_property("spawnflags", 0) & 4: # don't link
			continue

		if aabb.grow(grow_by).intersects(another_entity.aabb.grow(grow_by)):
			another_entity.metadata["__is_linked"] = true
			aabb = aabb.merge(another_entity.aabb)
			entities.append(another_entity)

	return [entities, aabb]


static func post_build_linking_data(map: MapperMap, data: Array) -> void:
	var entities: Array[MapperEntity] = data[0]
	var entity := entities[0]
	var aabb: AABB = data[1]

	var node := Node3D.new()
	node.position = aabb.get_center()
	var class_root := entity.node.get_parent()
	add_global_child(node, class_root, map.settings)

	for index in range(entities.size() - 1, -1, -1):
		var linked_node := entities[index].node
		class_root.remove_child(linked_node)
		add_global_child(linked_node, node, map.settings)
		node.move_child(linked_node, 0)

	if entities.size() == 1:
		var name: String = entities[0].get_string_property("targetname", "")
		if not name.validate_node_name().strip_edges().is_empty():
			node.name = name

	var area_data := _post_build_area(map, node, data)
	var _area_shape: CollisionShape3D = area_data[1]
	var area: Area3D = area_data[0]

	if MERGE_SOUND_PLAYERS:
		var move_sound_player := AudioStreamPlayer3D.new()
		node.add_child(move_sound_player, map.settings.readable_node_names)
		move_sound_player.stream = map.loader.load_sound("sounds/func_door-move")
		var noise1: AudioStream = entity.get_sound_property("noise1", null)
		if noise1 != null: move_sound_player.stream = noise1
		move_sound_player.playing = false

		var stop_sound_player := AudioStreamPlayer3D.new()
		node.add_child(stop_sound_player, map.settings.readable_node_names)
		stop_sound_player.stream = map.loader.load_sound("sounds/func_door-stop")
		var noise2: AudioStream = entity.get_sound_property("noise2", null)
		if noise2 != null: stop_sound_player.stream = noise2
		stop_sound_player.playing = false

	var animation_player := AnimationPlayer.new()
	node.add_child(animation_player, map.settings.readable_node_names)
	var animations := post_build_animations([node, ], data)

	if MERGE_SOUND_PLAYERS:
		preload("func_door_secret.gd")._build_sound_tracks(animations,
			[node] + node.find_children("*", "AudioStreamPlayer3D",
				false, false))

	var animation_library := AnimationLibrary.new()
	animation_library.add_animation("open", animations[0])
	animation_library.add_animation("opened", animations[1])
	animation_library.add_animation("close", animations[2])
	animation_library.add_animation("closed", animations[3])
	animation_player.add_animation_library("", animation_library)
	animation_player.autoplay = "closed"

	node.set_script(map.loader.load_script("scripts/func_door"))
	node.set("_animation_player", node.get_path_to(animation_player))
	animation_player.animation_finished.connect(Callable(node,
		"_on_animation_finished"), CONNECT_PERSIST)

	node.set("_area", node.get_path_to(area))
	area.body_entered.connect(Callable(node,
		"_on_body_entered"), CONNECT_PERSIST)

	var is_toggled := false
	for linked_entity in entities:
		var spawnflags: int = linked_entity.get_int_property("spawnflags", 0)
		if spawnflags & 32: # toggle between opened and closed states
			is_toggled = true

	for linked_entity in entities:
		var linked_node: Node3D = linked_entity.node
		node.connect("opening", Callable(linked_node,
			"_on_opening_signal"), CONNECT_PERSIST)
		node.connect("closing", Callable(linked_node,
			"_on_closing_signal"), CONNECT_PERSIST)
		if not linked_entity.get_string_property("targetname", "").is_empty():
			linked_node.connect("activated", Callable(node,
				"_on_generic_signal"), CONNECT_PERSIST)
		linked_node.tree_exiting.connect(Callable(node,
			"queue_free"), CONNECT_PERSIST)

	var wait_timer: Timer = null
	if not is_toggled:
		wait_timer = preload("func_button.gd"
			)._build_timer(map, entity, node, "wait", 3.0)
	else: node.set("is_toggled", is_toggled)

	if wait_timer:
		node.set("_wait_timer", node.get_path_to(wait_timer))
		wait_timer.timeout.connect(Callable(node,
			"_on_wait_timer_timeout"), CONNECT_PERSIST)

	entity.node = node
	entity.bind_signal_property("target",
		"targetname", "opening", "_on_generic_signal")
	entity.bind_signal_property("killtarget",
		"targetname", "opening_free", "queue_free")


static func _post_build_area(map: MapperMap, node: Node3D, data: Array) -> Array:
	var area := Area3D.new()
	node.add_child(area, map.settings.readable_node_names)
	area.monitorable = false

	var shape := CollisionShape3D.new()
	shape.position = data[1].get_center()
	add_global_child(shape, area, map.settings)

	shape.shape = BoxShape3D.new()
	var grow_by: float = LINK_UNITS / map.settings.unit_size
	shape.shape.size = data[1].grow(grow_by).size

	for entity in data[0]:
		if not entity.get_string_property("targetname", "").is_empty():
			area.monitoring = false

	node.move_child(area, 0)
	return [area, shape]


static func post_build_animations(nodes: Array, data: Array) -> Array[Animation]:
	var transform: Transform3D = nodes[0].transform.affine_inverse()
	var entities: Array[MapperEntity] = data[0]

	var parameters: Dictionary = {}
	parameters["open"] = Animation.new()
	parameters["opened"] = Animation.new()
	parameters["close"] = Animation.new()
	parameters["closed"] = Animation.new()

	parameters["open"].length = 0.0
	parameters["opened"].length = 0.0
	parameters["close"].length = 0.0
	parameters["closed"].length = 0.0

	for index in range(entities.size()):
		var entity := entities[index]
		var node: Node3D = entity.node

		# animation parameters per door
		var lip: float = entity.get_unit_property("lip", 8.0)
		var speed: float = entity.get_unit_property("speed", 100.0)
		speed = clampf(speed, 0.001, INF)

		# preparing to create animation key frames
		var forward_axis := Vector3.ZERO
		var local_forwad_vector = -node.basis.z.normalized()
		var forward_vector: Vector3 = nodes[0].basis * local_forwad_vector
		forward_vector = forward_vector.normalized()

		var forward_axis_index := forward_vector.abs().max_axis_index()
		forward_axis[forward_axis_index] = signf(forward_vector[forward_axis_index])
		var offset := clampf(entity.aabb.size[forward_axis_index] - lip, 0.0, INF)
		offset /= forward_vector.project(forward_axis).length()

		# calculating positions
		var close_position := transform * entity.center
		var open_position := transform * (entity.center + forward_axis * offset)

		if entity.get_int_property("spawnflags", 0) & 1: # starts open
			var swap := open_position
			open_position = close_position
			close_position = swap

		parameters["index"] = index
		parameters["door_track"] = NodePath(node.name)
		parameters["close_position"] = close_position
		parameters["open_position"] = open_position
		parameters["frames"] = [0.0, offset / speed]

		_post_build_open_animation(parameters)
		_post_build_opened_animation(parameters)
		_post_build_close_animation(parameters)
		_post_build_closed_animation(parameters)

	if not MERGE_SOUND_PLAYERS:
		for index in range(entities.size()):
			var entity := entities[index]
			var node: Node3D = entity.node
			var sound_players := node.find_children("*",
				"AudioStreamPlayer3D", false, false)

			preload("func_door_secret.gd")._build_sound_tracks(
				[parameters["open"], parameters["opened"],
				parameters["close"], parameters["closed"]],
				[nodes[0], sound_players[0], sound_players[1]])

	return [
		parameters["open"],
		parameters["opened"],
		parameters["close"],
		parameters["closed"],
	]


static func _post_build_open_animation(p: Dictionary, N: int = 1) -> void:
	var index: int = N * p.index
	p.open.add_track(Animation.TYPE_POSITION_3D)
	p.open.track_set_path(index + 0, p.door_track)

	p.open.length = maxf(p.open.length, p.frames[1])
	p.open.position_track_insert_key(index + 0, p.frames[0], p.close_position)
	p.open.position_track_insert_key(index + 0, p.frames[1], p.open_position)

	p.open.track_set_interpolation_type(index + 0, Animation.INTERPOLATION_LINEAR)
	p.open.track_set_interpolation_loop_wrap(index + 0, false)

	p.open.track_set_imported(index + 0, true)
	return


static func _post_build_opened_animation(p: Dictionary, N: int = 1) -> void:
	var index: int = N * p.index
	p.opened.add_track(Animation.TYPE_POSITION_3D)
	p.opened.track_set_path(index + 0, p.door_track)

	p.opened.position_track_insert_key(index + 0, p.frames[0], p.open_position)

	p.opened.track_set_interpolation_type(index + 0, Animation.INTERPOLATION_LINEAR)
	p.opened.track_set_interpolation_loop_wrap(index + 0, false)

	p.opened.track_set_imported(index + 0, true)
	return


static func _post_build_close_animation(p: Dictionary, N: int = 1) -> void:
	var index: int = N * p.index
	p.close.add_track(Animation.TYPE_POSITION_3D)
	p.close.track_set_path(index + 0, p.door_track)

	p.close.length = maxf(p.close.length, p.frames[1])
	p.close.position_track_insert_key(index + 0, p.frames[0], p.open_position)
	p.close.position_track_insert_key(index + 0, p.frames[1], p.close_position)

	p.close.track_set_interpolation_type(index + 0, Animation.INTERPOLATION_LINEAR)
	p.close.track_set_interpolation_loop_wrap(index + 0, false)

	p.close.track_set_imported(index + 0, true)
	return


static func _post_build_closed_animation(p: Dictionary, N: int = 1) -> void:
	var index: int = N * p.index
	p.closed.add_track(Animation.TYPE_POSITION_3D)
	p.closed.track_set_path(index + 0, p.door_track)

	p.closed.position_track_insert_key(index + 0, p.frames[0], p.close_position)

	p.closed.track_set_interpolation_type(index + 0, Animation.INTERPOLATION_LINEAR)
	p.closed.track_set_interpolation_loop_wrap(index + 0, false)

	p.closed.track_set_imported(index + 0, true)
	return


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@SolidClass",
		"=", "func_door", ":",
		'"smart door"',
		"[",
			"\n\tangle(float)", ":", '"direction of move"',
			"\n\ttarget(target_destination)", ":", '"target to activate"',
			"\n\tkilltarget(target_destination)", ":", '"target to destroy"',
			"\n\ttargetname(target_source)", ":", '"entity name"',
			"\n\tspeed(integer)", ":", '"speed (units)"', ":", "100",
			"\n\tlip(integer)", ":", '"lip (units)"', ":", "8",
			"\n\twait(float)", ":", '"reset time"', ":", '"3.0"',
			"\n\tnoise1(string)", ":", '"move sound name"',
			"\n\tnoise2(string)", ":", '"stop sound name"',
			"\n\tspawnflags(flags)", "=",
			"[",
				"\n\t\t1", ":", '"starts open"', ":", "0",
				"\n\t\t4", ":", '"disable linking"', ":", "0",
				"\n\t\t32", ":", '"toggle"', ":", "0",
			"\n\t]",
		"\n]\n",
	]).replace(" \n", "\n"))
