extends MapperUtilities

const BASE_CLASS_TARGET := true
const BASE_CLASS_KILLTARGET := true
const BASE_CLASS_TARGETNAME := true
const AREA_MIN_HEIGHT_UNITS: float = 8.0

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node: AnimatableBody3D = null
	node = create_merged_brush_entity(entity, "AnimatableBody3D")
	if not node: return null

	var root := Node3D.new()
	root.transform = node.transform
	add_global_child(node, root, map.settings)

	var area_data := _build_area(map, entity, root)
	var area_shape: CollisionShape3D = area_data[1]
	var area_extra_height: float = area_data[2]
	var area: Area3D = area_data[0]

	var move_sound_player := AudioStreamPlayer3D.new()
	node.add_child(move_sound_player, map.settings.readable_node_names)
	move_sound_player.stream = map.loader.load_sound("sounds/func_plat-move")
	var noise1: AudioStream = entity.get_sound_property("noise1", null)
	if noise1 != null: move_sound_player.stream = noise1
	move_sound_player.playing = false

	var stop_sound_player := AudioStreamPlayer3D.new()
	node.add_child(stop_sound_player, map.settings.readable_node_names)
	stop_sound_player.stream = map.loader.load_sound("sounds/func_plat-stop")
	var noise2: AudioStream = entity.get_sound_property("noise2", null)
	if noise2 != null: stop_sound_player.stream = noise2
	stop_sound_player.playing = false

	var animation_player := AnimationPlayer.new()
	root.add_child(animation_player, map.settings.readable_node_names)
	var animations := build_animations(entity,
		[root, node, area, area_shape, ],
		area_extra_height)

	preload("func_door_secret.gd")._build_sound_tracks(animations,
		[root, move_sound_player, stop_sound_player])

	var animation_library := AnimationLibrary.new()
	animation_library.add_animation("extend", animations[0])
	animation_library.add_animation("extended", animations[1])
	animation_library.add_animation("retract", animations[2])
	animation_library.add_animation("retracted", animations[3])
	animation_player.add_animation_library("", animation_library)
	animation_player.autoplay = "retracted"

	root.set_script(map.loader.load_script("scripts/func_plat"))
	root.set("_animation_player", root.get_path_to(animation_player))
	root.set("_area", root.get_path_to(area))

	area.body_entered.connect(Callable(root,
		"_on_body_entered"), CONNECT_PERSIST)
	animation_player.animation_finished.connect(Callable(root,
		"_on_animation_finished"), CONNECT_PERSIST)

	var wait_timer := preload("func_button.gd"
		)._build_timer(map, entity, root, "wait", 1.0)

	if wait_timer:
		root.set("_wait_timer", root.get_path_to(wait_timer))
		wait_timer.timeout.connect(Callable(root,
			"_on_wait_timer_timeout"), CONNECT_PERSIST)

	if not entity.get_string_property("targetname", "").is_empty():
		animation_player.autoplay = "extended"
		area.monitoring = false

	return root


static func _build_area(map: MapperMap, entity: MapperEntity, parent: Node3D) -> Array:
	var area := Area3D.new()
	parent.add_child(area, map.settings.readable_node_names)
	area.monitorable = false

	var up_axis := map.settings.get_up_axis()
	var up_axis_index := map.settings.get_up_axis_index()
	var extra_height := AREA_MIN_HEIGHT_UNITS / map.settings.unit_size

	var shape := CollisionShape3D.new()
	var height := entity.aabb.size[up_axis_index]
	area.add_child(shape, map.settings.readable_node_names)
	var shape_offset := (height + extra_height) / 2.0
	area.position = up_axis * shape_offset

	shape.shape = BoxShape3D.new()
	shape.shape.size = entity.aabb.size
	shape.shape.size[up_axis_index] = extra_height

	parent.move_child(area, 0)
	return [area, shape, extra_height]


static func build_animations(entity: MapperEntity, nodes: Array, area_extra_height: float) -> Array[Animation]:
	var transform: Transform3D = nodes[0].transform.affine_inverse()
	var area_shape: CollisionShape3D = nodes[3]
	var node: AnimatableBody3D = nodes[1]
	var area: Area3D = nodes[2]

	# animation parameters
	var animation_delay: float = 0.15
	var height: float = entity.get_unit_property("height", 0.0)
	var speed: float = entity.get_unit_property("speed", 150.0)
	speed = clampf(speed, 0.001, INF)

	# preparing to create animation key frames
	var up_axis := entity.factory.settings.get_up_axis()
	var up_axis_index := entity.factory.settings.get_up_axis_index()

	# calculating positions
	var offset := float(height)
	if height == 0.0:
		offset = entity.aabb.size[up_axis_index]
		offset -= area_extra_height

	var platform_extend_position := entity.center
	var platform_retract_position := entity.center - up_axis * offset
	var area_shape_extend_size: Vector3 = area_shape.shape.size
	var area_shape_retract_size := entity.aabb.size
	var area_extend_position := area.position
	var area_retract_position: Vector3

	if height == 0.0:
		area_retract_position = up_axis * area_extra_height

	elif height > 0.0:
		var area_offset := entity.aabb.size[up_axis_index]
		area_offset += area_extra_height - height
		area_offset /= 2.0

		area_retract_position = up_axis * area_offset
		area_shape_retract_size[up_axis_index] = (
			absf(height) + area_extra_height)

	elif height < 0.0:
		var area_offset := entity.aabb.size[up_axis_index]
		area_offset += area_extra_height + height
		area_offset /= 2.0

		area_retract_position = area.position - up_axis * offset
		area_shape_retract_size = area_shape_extend_size

		area_extend_position = up_axis * (area_offset - offset)
		area_shape_extend_size[up_axis_index] = (
			absf(height) + area_extra_height)

	var frames := [
		0.0,
		animation_delay,
		absf(offset) / speed + animation_delay,
		absf(offset) / speed + 2.0 * animation_delay
	]

	var parameters: Dictionary = {
		"platform_track":
			NodePath(node.name),
		"area_position_track":
			NodePath(area.name),
		"area_shape_size_track":
			NodePath(area.name.path_join(area_shape.name) + ":shape:size"),
		"platform_extend_position": transform * platform_extend_position,
		"platform_retract_position": transform * platform_retract_position,
		"area_extend_position": area_extend_position,
		"area_retract_position": area_retract_position,
		"area_shape_extend_size": area_shape_extend_size,
		"area_shape_retract_size": area_shape_retract_size,
		"frames": frames,
	}

	return [
		_build_extend_animation(parameters),
		_build_extended_animation(parameters),
		_build_retract_animation(parameters),
		_build_retracted_animation(parameters),
	]


static func _build_extend_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	animation.add_track(Animation.TYPE_POSITION_3D)
	animation.add_track(Animation.TYPE_POSITION_3D)
	animation.add_track(Animation.TYPE_VALUE)

	animation.track_set_path(0, p.platform_track)
	animation.track_set_path(1, p.area_position_track)
	animation.track_set_path(2, p.area_shape_size_track)

	animation.length = p.frames[3]
	animation.position_track_insert_key(0, p.frames[1], p.platform_retract_position)
	animation.position_track_insert_key(1, p.frames[1], p.area_retract_position)
	animation.track_insert_key(2, p.frames[1], p.area_shape_retract_size)

	animation.position_track_insert_key(0, p.frames[2], p.platform_extend_position)
	animation.position_track_insert_key(1, p.frames[2], p.area_extend_position)
	animation.track_insert_key(2, p.frames[2], p.area_shape_extend_size)

	animation.track_set_interpolation_type(0, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(0, false)

	animation.track_set_interpolation_type(1, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(1, false)

	animation.value_track_set_update_mode(2, Animation.UPDATE_CONTINUOUS)
	animation.track_set_interpolation_type(2, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(2, false)

	animation.track_set_imported(0, true)
	animation.track_set_imported(1, true)
	animation.track_set_imported(2, true)
	return animation


static func _build_extended_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	animation.add_track(Animation.TYPE_POSITION_3D)
	animation.add_track(Animation.TYPE_POSITION_3D)
	animation.add_track(Animation.TYPE_VALUE)

	animation.track_set_path(0, p.platform_track)
	animation.track_set_path(1, p.area_position_track)
	animation.track_set_path(2, p.area_shape_size_track)

	animation.length = 0.0
	animation.position_track_insert_key(0, p.frames[0], p.platform_extend_position)
	animation.position_track_insert_key(1, p.frames[0], p.area_extend_position)
	animation.track_insert_key(2, p.frames[0], p.area_shape_extend_size)

	animation.track_set_interpolation_type(0, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(0, false)

	animation.track_set_interpolation_type(1, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(1, false)

	animation.value_track_set_update_mode(2, Animation.UPDATE_DISCRETE)
	animation.track_set_interpolation_type(2, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(2, false)

	animation.track_set_imported(0, true)
	animation.track_set_imported(1, true)
	animation.track_set_imported(2, true)
	return animation


static func _build_retract_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	animation.add_track(Animation.TYPE_POSITION_3D)
	animation.add_track(Animation.TYPE_POSITION_3D)
	animation.add_track(Animation.TYPE_VALUE)

	animation.track_set_path(0, p.platform_track)
	animation.track_set_path(1, p.area_position_track)
	animation.track_set_path(2, p.area_shape_size_track)

	animation.length = p.frames[3]
	animation.position_track_insert_key(0, p.frames[1], p.platform_extend_position)
	animation.position_track_insert_key(1, p.frames[1], p.area_extend_position)
	animation.track_insert_key(2, p.frames[1], p.area_shape_extend_size)

	animation.position_track_insert_key(0, p.frames[2], p.platform_retract_position)
	animation.position_track_insert_key(1, p.frames[2], p.area_retract_position)
	animation.track_insert_key(2, p.frames[2], p.area_shape_retract_size)

	animation.track_set_interpolation_type(0, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(0, false)

	animation.track_set_interpolation_type(1, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(1, false)

	animation.value_track_set_update_mode(2, Animation.UPDATE_CONTINUOUS)
	animation.track_set_interpolation_type(2, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(2, false)

	animation.track_set_imported(0, true)
	animation.track_set_imported(1, true)
	animation.track_set_imported(2, true)
	return animation


static func _build_retracted_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	animation.add_track(Animation.TYPE_POSITION_3D)
	animation.add_track(Animation.TYPE_POSITION_3D)
	animation.add_track(Animation.TYPE_VALUE)

	animation.track_set_path(0, p.platform_track)
	animation.track_set_path(1, p.area_position_track)
	animation.track_set_path(2, p.area_shape_size_track)

	animation.length = 0.0
	animation.position_track_insert_key(0, p.frames[0], p.platform_retract_position)
	animation.position_track_insert_key(1, p.frames[0], p.area_retract_position)
	animation.track_insert_key(2, p.frames[0], p.area_shape_retract_size)

	animation.track_set_interpolation_type(0, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(0, false)

	animation.track_set_interpolation_type(1, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(1, false)

	animation.value_track_set_update_mode(2, Animation.UPDATE_DISCRETE)
	animation.track_set_interpolation_type(2, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(2, false)

	animation.track_set_imported(0, true)
	animation.track_set_imported(1, true)
	animation.track_set_imported(2, true)
	return animation


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@SolidClass",
		"=", "func_plat", ":",
		'"elevator"',
		"[",
			"\n\tspeed(integer)", ":", '"speed (units)"', ":", "150",
			"\n\theight(integer)", ":", '"travel altitude"', ":", "0",
			"\n\ttarget(target_destination)", ":", '"target to activate"',
			"\n\tkilltarget(target_destination)", ":", '"target to destroy"',
			"\n\ttargetname(target_source)", ":", '"entity name"',
			"\n\twait(float)", ":", '"reset time"', ":", '"1.0"',
			"\n\tnoise1(string)", ":", '"move sound name"',
			"\n\tnoise2(string)", ":", '"stop sound name"',
		"\n]\n",
	]).replace(" \n", "\n"))
