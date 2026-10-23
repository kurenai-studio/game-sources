extends MapperUtilities

const BASE_CLASS_TARGET := true
const BASE_CLASS_KILLTARGET := true

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node: Node3D = null
	node = preload("func_wall.gd").build(map, entity)
	if not node: return null

	node = _change_node_type(map, node)
	node.set("mouse_cursor_override", entity.get_int_property("cursor", 1))

	var root := Node3D.new()
	root.transform = node.transform
	add_global_child(node, root, map.settings)

	var move_sound_player := AudioStreamPlayer3D.new()
	node.add_child(move_sound_player, map.settings.readable_node_names)
	move_sound_player.stream = map.loader.load_sound("sounds/func_button-move")
	var noise1: AudioStream = entity.get_sound_property("noise1", null)
	if noise1 != null: move_sound_player.stream = noise1
	move_sound_player.playing = false

	var stop_sound_player := AudioStreamPlayer3D.new()
	node.add_child(stop_sound_player, map.settings.readable_node_names)
	stop_sound_player.stream = map.loader.load_sound("sounds/func_button-stop")
	var noise2: AudioStream = entity.get_sound_property("noise2", null)
	if noise2 != null: stop_sound_player.stream = noise2
	stop_sound_player.playing = false

	var animation_player := AnimationPlayer.new()
	root.add_child(animation_player, map.settings.readable_node_names)
	var animations := build_animations(entity,
		[root, node, ])

	preload("func_door_secret.gd")._build_sound_tracks(animations,
		[root, move_sound_player, stop_sound_player])

	var animation_library := AnimationLibrary.new()
	animation_library.add_animation("press", animations[0])
	animation_library.add_animation("pressed", animations[1])
	animation_library.add_animation("release", animations[2])
	animation_library.add_animation("released", animations[3])
	animation_player.add_animation_library("", animation_library)
	animation_player.autoplay = "released"

	root.set_script(map.loader.load_script("scripts/func_button"))
	root.set("_animation_player", root.get_path_to(animation_player))
	animation_player.animation_finished.connect(Callable(root,
		"_on_animation_finished"), CONNECT_PERSIST)

	var wait_timer := _build_timer(map, entity, root, "wait", 1.0)
	entity.bind_float_property("delay", "delay_time")

	if wait_timer:
		root.set("_wait_timer", root.get_path_to(wait_timer))
		wait_timer.timeout.connect(Callable(root,
			"_on_wait_timer_timeout"), CONNECT_PERSIST)

	return root


static func _change_node_type(map: MapperMap, node: Node3D) -> Node3D:
	var alternative_texture = node.get("alternative_texture")
	var alternative_speed_scale = node.get("alternative_speed_scale")
	var alternative_textures_size = node.get("alternative_textures_size")
	var affected_materials = node.get("affected_materials")

	node = change_node_type(node, "AnimatableBody3D")
	node.set_script(map.loader.load_script("scripts/func_button+"))

	node.set("alternative_texture", alternative_texture)
	node.set("alternative_speed_scale", alternative_speed_scale)
	node.set("alternative_textures_size", alternative_textures_size)
	node.set("affected_materials", affected_materials)
	return node


static func _build_timer(map: MapperMap, entity: MapperEntity, node: Node3D, property: String = "wait", time: float = 1.0) -> Timer:
	var wait_time: float = entity.get_float_property(property, time)
	if wait_time < 0.0: return null
	var timer := Timer.new()
	node.add_child(timer,
		map.settings.readable_node_names)
	timer.wait_time = clampf(wait_time, 0.001, INF)
	timer.one_shot = true
	return timer


static func build_animations(entity: MapperEntity, nodes: Array) -> Array[Animation]:
	var root: Node3D = nodes[0]
	var transform := root.transform.affine_inverse()
	var node: AnimatableBody3D = nodes[1]

	# animation parameters
	var lip: float = entity.get_unit_property("lip", 4.0)
	var speed: float = entity.get_unit_property("speed", 40.0)
	speed = clampf(speed, 0.001, INF)

	# preparing to create animation key frames
	var forward_vector := -root.basis.z.normalized()
	var forward_axis_index := forward_vector.abs().max_axis_index()

	# calculating positions
	var release_position := entity.center
	var offset := clampf(entity.aabb.size[forward_axis_index] - lip, 0.0, INF)
	var press_position := release_position + forward_vector * offset

	var parameters: Dictionary = {
		"button_track":
			NodePath(node.name),
		"button_alternative_texture_track":
			NodePath(node.name + ":alternative_texture"),
		"release_position": transform * release_position,
		"press_position": transform * press_position,
		"frames": [0.0, offset / speed],
	}

	return [
		_build_press_animation(parameters),
		_build_pressed_animation(parameters),
		_build_release_animation(parameters),
		_build_released_animation(parameters),
	]


static func _build_press_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(0, p.button_track)

	animation.length = p.frames[1]
	animation.position_track_insert_key(0, p.frames[0], p.release_position)
	animation.position_track_insert_key(0, p.frames[1], p.press_position)

	animation.track_set_interpolation_type(0, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(0, false)

	animation.track_set_imported(0, true)
	return animation


static func _build_pressed_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	animation.add_track(Animation.TYPE_POSITION_3D)
	animation.add_track(Animation.TYPE_VALUE)

	animation.track_set_path(0, p.button_track)
	animation.track_set_path(1, p.button_alternative_texture_track)

	animation.length = 0.0
	animation.position_track_insert_key(0, p.frames[0], p.press_position)
	animation.track_insert_key(1, p.frames[0], 1)

	animation.track_set_interpolation_type(0, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(0, false)

	animation.value_track_set_update_mode(1, Animation.UPDATE_DISCRETE)
	animation.track_set_interpolation_type(1, Animation.INTERPOLATION_NEAREST)
	animation.track_set_interpolation_loop_wrap(1, false)

	animation.track_set_imported(0, true)
	animation.track_set_imported(1, true)
	return animation


static func _build_release_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	animation.add_track(Animation.TYPE_POSITION_3D)
	animation.add_track(Animation.TYPE_VALUE)

	animation.track_set_path(0, p.button_track)
	animation.track_set_path(1, p.button_alternative_texture_track)

	animation.length = p.frames[1]
	animation.position_track_insert_key(0, p.frames[0], p.press_position)
	animation.position_track_insert_key(0, p.frames[1], p.release_position)
	animation.track_insert_key(1, p.frames[0], 0)

	animation.track_set_interpolation_type(0, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(0, false)

	animation.value_track_set_update_mode(1, Animation.UPDATE_DISCRETE)
	animation.track_set_interpolation_type(1, Animation.INTERPOLATION_NEAREST)
	animation.track_set_interpolation_loop_wrap(1, false)

	animation.track_set_imported(0, true)
	animation.track_set_imported(1, true)
	return animation


static func _build_released_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(0, p.button_track)

	animation.length = 0.0
	animation.position_track_insert_key(0, p.frames[0], p.release_position)

	animation.track_set_interpolation_type(0, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(0, false)

	animation.track_set_imported(0, true)
	return animation


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@SolidClass",
		"=", "func_button", ":",
		'"interactable button"',
		"[",
			"\n\tangle(float)", ":", '"direction of move"',
			"\n\ttarget(target_destination)", ":", '"target to activate"',
			"\n\tkilltarget(target_destination)", ":", '"target to destroy"',
			"\n\tspeed(integer)", ":", '"speed (units)"', ":", "40",
			"\n\tlip(integer)", ":", '"lip (units)"', ":", "4",
			"\n\twait(float)", ":", '"wait time"', ":", '"1.0"',
			"\n\tdelay(float)", ":", '"delay time"', ":", '"0.0"',
			"\n\tcursor(integer)", ":", '"mouse cursor override"', ":", "1",
			"\n\tnoise1(string)", ":", '"move sound name"',
			"\n\tnoise2(string)", ":", '"stop sound name"',
		"\n]\n",
	]).replace(" \n", "\n"))
