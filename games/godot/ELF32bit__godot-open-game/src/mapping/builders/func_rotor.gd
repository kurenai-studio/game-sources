extends MapperUtilities

const BASE_CLASS_TARGETNAME := true

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node: AnimatableBody3D = null
	node = create_merged_brush_entity(entity, "AnimatableBody3D")
	if not node: return null

	var root := Node3D.new()
	root.transform = node.transform
	add_global_child(node, root, map.settings)

	var move_sound_player := AudioStreamPlayer3D.new()
	node.add_child(move_sound_player, map.settings.readable_node_names)
	move_sound_player.stream = map.loader.load_sound("sounds/func_rotor-move")
	var noise1: AudioStream = entity.get_sound_property("noise1", null)
	if noise1 != null: move_sound_player.stream = noise1
	move_sound_player.playing = false

	var stop_sound_player := AudioStreamPlayer3D.new()
	node.add_child(stop_sound_player, map.settings.readable_node_names)
	stop_sound_player.stream = map.loader.load_sound("sounds/func_rotor-stop")
	var noise2: AudioStream = entity.get_sound_property("noise2", null)
	if noise2 != null: stop_sound_player.stream = noise2
	stop_sound_player.playing = false

	var animation_player := AnimationPlayer.new()
	root.add_child(animation_player, map.settings.readable_node_names)
	var animations := build_animations(entity,
		[root, node, move_sound_player, stop_sound_player, ])

	var animation_library := AnimationLibrary.new()
	animation_player.add_animation_library("", animation_library)
	animation_library.add_animation("move", animations[0])
	animation_library.add_animation("move_back", animations[1])
	animation_library.add_animation("stop", animations[2])
	animation_player.autoplay = "move"

	root.set_script(map.loader.load_script("scripts/func_rotor"))
	root.set("_animation_player", root.get_path_to(animation_player))

	if not entity.get_string_property("targetname", "").is_empty():
		animation_player.autoplay = ""

	return root


static func build_animations(entity: MapperEntity, nodes: Array) -> Array[Animation]:
	var root: Node3D = nodes[0]
	var transform := root.transform.affine_inverse()
	var quaternion := transform.basis.get_rotation_quaternion()
	var move_sound_player: AudioStreamPlayer3D = nodes[2]
	var stop_sound_player: AudioStreamPlayer3D = nodes[3]
	var node: AnimatableBody3D = nodes[1]

	# animation parameters
	var speed := float(entity.get_float_property("speed", 90.0))
	var move_clockwise := bool(speed > 0.0)
	speed = clampf(absf(speed), 0.001, INF)

	var move_count := float(entity.get_float_property("turns", -1.0))
	if move_count == 0.0: move_count = -1.0

	# preparing to create animation key frames
	var axis := quaternion * (-root.basis.z)
	var rotation1 := Quaternion(axis, PI)
	var rotation2 := Quaternion(axis, -PI)

	if not move_clockwise:
		var swap := rotation1
		rotation1 = rotation2
		rotation2 = swap

	# calculating rotations
	var move_start_rotation := quaternion * root.quaternion
	var move1_mid_rotation := rotation1 * move_start_rotation
	var move1_end_rotation := rotation1 * rotation1 * move_start_rotation
	var move2_mid_rotation := rotation2 * move_start_rotation
	var move2_end_rotation := rotation2 * rotation2 * move_start_rotation

	var frames := [
		0.0,
		180.0 / absf(speed),
		360.0 / absf(speed),
	]

	var parameters: Dictionary = {
		"rotor_track":
			NodePath(node.name),
		"move_sound_player_track":
			NodePath(node.name.path_join(
				move_sound_player.name) + ":playing"),
		"stop_sound_player_track":
			NodePath(node.name.path_join(
				stop_sound_player.name) + ":playing"),
		"move_start_rotation": move_start_rotation,
		"move_mid_rotation": move1_mid_rotation,
		"move_end_rotation": move1_end_rotation,
		"move_count": move_count,
		"rotation": rotation1,
		"frames": frames,
	}

	var move1_animation := _build_move_animation(parameters)
	parameters["move_mid_rotation"] = move2_mid_rotation
	parameters["move_end_rotation"] = move2_end_rotation
	parameters["rotation"] = rotation2

	return [
		move1_animation,
		_build_move_animation(parameters),
		_build_stop_animation(parameters),
	]


static func _build_move_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	if p.move_count < 0.0:
		animation.loop_mode = Animation.LOOP_LINEAR

	animation.add_track(Animation.TYPE_ROTATION_3D)
	animation.track_set_path(0, p.rotor_track)
	animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(1, p.move_sound_player_track)
	if p.move_count > 0.0:
		animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(2, p.stop_sound_player_track)

	if p.move_count < 0.0:
		animation.length = p.frames[2]
		animation.rotation_track_insert_key(0, p.frames[0], p.move_start_rotation)
		animation.rotation_track_insert_key(0, p.frames[1], p.move_mid_rotation)
		animation.rotation_track_insert_key(0, p.frames[2], p.move_end_rotation)
		animation.track_insert_key(1, p.frames[0], true)
		animation.track_insert_key(1, p.frames[2], true)

	elif p.move_count > 0.0:
		var rotation: Quaternion = p.move_start_rotation
		var move_count := maxi(1, int(ceilf(p.move_count)))
		var move_progress := float(p.move_count - floorf(p.move_count))

		animation.length = p.frames[2] * p.move_count
		for index in range(move_count):
			var offset := float((p.frames[2] * index))

			animation.rotation_track_insert_key(0,
				offset + p.frames[0], rotation)

			if index == move_count - 1:
				if move_progress > 0.0 and move_progress < 0.5:
					animation.rotation_track_insert_key(0,
						animation.length, Quaternion.IDENTITY.slerp(
							p.rotation, move_progress * 2.0)
							* rotation)
					break

			animation.rotation_track_insert_key(0,
				offset + p.frames[1], p.rotation * rotation)

			if index == move_count - 1:
				if move_progress == 0.5:
					break

			if index == move_count - 1:
				if move_progress > 0.5 and move_progress < 1.0:
					animation.rotation_track_insert_key(0,
						animation.length, Quaternion.IDENTITY.slerp(
							p.rotation, (move_progress - 0.5) * 2.0)
							* p.rotation * rotation)
					break

			animation.rotation_track_insert_key(0,
				offset + p.frames[2], p.rotation * p.rotation * rotation)

			rotation = p.rotation * p.rotation * rotation
		p["move_start_rotation"] = animation.track_get_key_value(0,
			animation.track_get_key_count(0) - 1)

		animation.track_insert_key(1, p.frames[0], true)
		animation.track_insert_key(1, animation.length, false)
		animation.track_insert_key(2, animation.length, true)

	animation.track_set_interpolation_type(0, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(0, false)

	animation.value_track_set_update_mode(1, Animation.UPDATE_CONTINUOUS)
	animation.track_set_interpolation_type(1, Animation.INTERPOLATION_NEAREST)
	animation.track_set_interpolation_loop_wrap(1, false)

	if p.move_count > 0.0:
		animation.value_track_set_update_mode(2, Animation.UPDATE_DISCRETE)
		animation.track_set_interpolation_type(2, Animation.INTERPOLATION_NEAREST)
		animation.track_set_interpolation_loop_wrap(2, false)

	animation.track_set_imported(0, true)
	animation.track_set_imported(1, true)
	if p.move_count > 0.0:
		animation.track_set_imported(2, true)
	return animation


static func _build_stop_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(0, p.move_sound_player_track)
	animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(1, p.stop_sound_player_track)

	animation.length = p.frames[0]
	animation.track_insert_key(0, p.frames[0], false)
	animation.track_insert_key(1, p.frames[0], true)

	animation.value_track_set_update_mode(0, Animation.UPDATE_DISCRETE)
	animation.track_set_interpolation_type(0, Animation.INTERPOLATION_NEAREST)
	animation.track_set_interpolation_loop_wrap(0, false)

	animation.value_track_set_update_mode(1, Animation.UPDATE_DISCRETE)
	animation.track_set_interpolation_type(1, Animation.INTERPOLATION_NEAREST)
	animation.track_set_interpolation_loop_wrap(1, false)

	animation.track_set_imported(0, true)
	animation.track_set_imported(1, true)
	return animation


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@SolidClass",
		"=", "func_rotor", ":",
		'"rotating mechanism"',
		"[",
			"\n\tangle(float)", ":", '"direction of rotation"',
			"\n\tspeed(float)", ":", '"speed (degrees)"', ":", '"90.0"',
			"\n\tturns(float)", ":", '"turns count"', ":", '"-1.0"',
			"\n\ttargetname(target_source)", ":", '"entity name"',
			"\n\tnoise1(string)", ":", '"move sound name"',
			"\n\tnoise2(string)", ":", '"stop sound name"',
		"\n]\n",
	]).replace(" \n", "\n"))
