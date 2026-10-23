extends MapperUtilities

const BASE_CLASS_TARGET := true
const BASE_CLASS_KILLTARGET := true
const BASE_CLASS_TARGETNAME := true
const ANIMATE_ROTATIONS := true

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node: AnimatableBody3D = null
	node = create_merged_brush_entity(entity, "AnimatableBody3D")
	if not node: return null

	var root := Node3D.new()
	root.transform = node.transform
	add_global_child(node, root, map.settings)

	var animation_library := AnimationLibrary.new()
	var animation := build_path_follow_animation(map, entity, node)
	animation_library.add_animation("move", animation)

	if animation.length > 0.001:
		var move_sound_player := AudioStreamPlayer3D.new()
		node.add_child(move_sound_player, map.settings.readable_node_names)
		move_sound_player.stream = map.loader.load_sound("sounds/func_train-move")
		var noise1: AudioStream = entity.get_sound_property("noise1", null)
		_build_sound_player_track(root, animation, move_sound_player)
		if noise1 != null: move_sound_player.stream = noise1
		move_sound_player.playing = false

		var track := animation.get_track_count() - 1
		animation.track_insert_key(track, 0.0, true)
		if animation.loop_mode == animation.LOOP_NONE:
			animation.track_insert_key(track, animation.length, false)

	if animation.length > 0.001 and animation.loop_mode == animation.LOOP_NONE:
		var stop_sound_player := AudioStreamPlayer3D.new()
		node.add_child(stop_sound_player, map.settings.readable_node_names)
		stop_sound_player.stream = map.loader.load_sound("sounds/func_train-stop")
		var noise2: AudioStream = entity.get_sound_property("noise2", null)
		_build_sound_player_track(root, animation, stop_sound_player)
		if noise2 != null: stop_sound_player.stream = noise2
		stop_sound_player.playing = false

		var track := animation.get_track_count() - 1
		animation.track_insert_key(track, animation.length, true)

	var animation_player := AnimationPlayer.new()
	root.add_child(animation_player, map.settings.readable_node_names)
	animation_player.add_animation_library("", animation_library)
	animation_player.autoplay = "move"

	root.set_script(map.loader.load_script("scripts/func_train"))
	root.set("_animation_player", root.get_path_to(animation_player))
	animation_player.animation_finished.connect(Callable(root,
		"_on_animation_finished"), CONNECT_PERSIST)

	if not entity.get_string_property("targetname", "").is_empty():
		animation_player.autoplay = ""

	return root


static func build_path_follow_animation(map: MapperMap, entity: MapperEntity, node: Node3D) -> Animation:
	var animation := Animation.new()
	animation.loop_mode = Animation.LOOP_NONE
	animation.length = 0.0

	animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(0, NodePath(node.name))
	animation.track_set_interpolation_type(0, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(0, false)
	animation.track_set_imported(0, true)

	var targets := map.get_first_entity_target_recursively(
		entity, "target", "targetname", "path_corner")
	if targets.size() == 0: return animation

	for target in targets:
		if target.get_origin_property(null) == null:
			return animation

	var default_angles := map.settings.get_forward_rotation().get_euler()
	var first_origin := Vector3(targets[0].get_origin_property())
	var first_angles := Vector3(targets[0].node_properties.get(
		"rotation", default_angles))

	var has_rotation_track := false
	if ANIMATE_ROTATIONS:
		for target in targets:
			var angles := Vector3(
				target.node_properties.get(
					"rotation", default_angles))
			if angles != first_angles:
				has_rotation_track = true
				break

	# BUG: rotation track interferes with position track in game
	if has_rotation_track:
		animation.remove_track(0)
		animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(0, NodePath(node.name + ":transform"))
		animation.value_track_set_update_mode(0, Animation.UPDATE_CONTINUOUS)
		animation.track_set_interpolation_type(0, Animation.INTERPOLATION_LINEAR)
		animation.track_set_interpolation_loop_wrap(0, false)
		animation.track_set_imported(0, true)

	var root: Node3D = node.get_parent()
	var transform := root.transform.affine_inverse()

	var position := Vector3(root.position)
	var position_offset := position - first_origin
	var speed: float = entity.get_unit_property("speed", 64.0)
	var is_looping := bool(targets[-1] == targets[0])

	var rotation := Quaternion.from_euler(root.rotation)
	var rotation_offset := Quaternion.from_euler(first_angles)
	rotation_offset = rotation_offset * rotation.inverse()

	if speed == 0.0: return animation
	elif speed < 0.0 and is_looping:
		speed = absf(speed)
		targets.reverse()
	elif speed < 0.0:
		return animation

	for index in range(targets.size()):
		var target := targets[index]
		var origin: Vector3 = target.get_origin_property()
		var wait: float = target.get_float_property("wait", 0.0)
		if wait < 0.0: is_looping = false

		var next_position := origin + position_offset
		var distance := position.distance_to(next_position)
		position = Vector3(next_position)

		var next_rotation := Quaternion.IDENTITY
		if has_rotation_track:
			var angles := Vector3(
				target.node_properties.get(
					"rotation", default_angles))
			next_rotation = Quaternion.from_euler(angles)
			next_rotation = rotation_offset * next_rotation

		animation.length += distance / speed
		if not has_rotation_track:
			animation.position_track_insert_key(0,
				animation.length, transform * next_position)
		elif has_rotation_track:
			animation.track_insert_key(0,
				animation.length, transform * Transform3D(
					Basis(next_rotation), next_position))

		if is_looping:
			if index == (targets.size() - 1):
				wait = 0.0
		if wait < 0.0: break

		animation.length += wait
		if not has_rotation_track:
			animation.position_track_insert_key(0,
				animation.length, transform * next_position)
		elif has_rotation_track:
			animation.track_insert_key(0,
				animation.length, transform * Transform3D(
					Basis(next_rotation), next_position))

	if is_looping:
		animation.loop_mode = Animation.LOOP_LINEAR
	return animation


static func _build_sound_player_track(node: Node, animation: Animation, player: AudioStreamPlayer3D) -> void:
	var track := animation.get_track_count()
	animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath(
		str(node.get_path_to(player)) + ":playing"))

	animation.value_track_set_update_mode(track, Animation.UPDATE_DISCRETE)
	animation.track_set_interpolation_type(track, Animation.INTERPOLATION_NEAREST)
	animation.track_set_interpolation_loop_wrap(track, false)

	animation.track_set_imported(track, true)
	return


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@SolidClass",
		"=", "func_train", ":",
		'"moving platform"',
		"[",
			"\n\tspeed(integer)", ":", '"speed (units per second)"', ":", "64",
			"\n\ttarget(target_destination)", ":", '"target to start at"',
			"\n\tkilltarget(target_destination)", ":", '"target to destroy"',
			"\n\ttargetname(target_source)", ":", '"entity name"',
			"\n\tnoise1(string)", ":", '"move sound name"',
			"\n\tnoise2(string)", ":", '"stop sound name"',
		"\n]\n",
	]).replace(" \n", "\n"))
