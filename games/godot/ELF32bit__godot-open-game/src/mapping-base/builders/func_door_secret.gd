extends MapperUtilities

const BASE_CLASS_TARGET := true
const BASE_CLASS_KILLTARGET := true
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
	move_sound_player.stream = map.loader.load_sound("sounds/func_door_secret-move")
	var noise1: AudioStream = entity.get_sound_property("noise1", null)
	if noise1 != null: move_sound_player.stream = noise1
	move_sound_player.playing = false

	var stop_sound_player := AudioStreamPlayer3D.new()
	node.add_child(stop_sound_player, map.settings.readable_node_names)
	stop_sound_player.stream = map.loader.load_sound("sounds/func_door_secret-stop")
	var noise2: AudioStream = entity.get_sound_property("noise2", null)
	if noise2 != null: stop_sound_player.stream = noise2
	stop_sound_player.playing = false

	var animation_player := AnimationPlayer.new()
	root.add_child(animation_player, map.settings.readable_node_names)
	var animations := build_animations(entity,
		[root, node, ])

	_build_sound_tracks(animations, [root,
		move_sound_player, stop_sound_player])

	var animation_library := AnimationLibrary.new()
	animation_library.add_animation("open", animations[0])
	animation_library.add_animation("opened", animations[1])
	animation_library.add_animation("close", animations[2])
	animation_library.add_animation("closed", animations[3])
	animation_player.add_animation_library("", animation_library)
	animation_player.autoplay = "closed"

	root.set_script(map.loader.load_script("scripts/func_door_secret"))
	root.set("_animation_player", root.get_path_to(animation_player))
	animation_player.animation_finished.connect(Callable(root,
		"_on_animation_finished"), CONNECT_PERSIST)

	var wait_timer := preload("func_button.gd"
		)._build_timer(map, entity, root, "wait", 2.0)

	if wait_timer:
		root.set("_wait_timer", root.get_path_to(wait_timer))
		wait_timer.timeout.connect(Callable(root,
			"_on_wait_timer_timeout"), CONNECT_PERSIST)

	if entity.get_int_property("spawnflags", 0) & 1: # open once
		root.set("opens_once", true)

	return root


static func build_animations(entity: MapperEntity, nodes: Array) -> Array[Animation]:
	var root: Node3D = nodes[0]
	var transform := root.transform.affine_inverse()
	var node: AnimatableBody3D = nodes[1]

	# animation parameters
	var animation_delay: float = 0.15
	var spawnflags: int = entity.get_int_property("spawnflags", 0)
	var t_width: Variant = entity.get_unit_property("t_width", null)
	var t_length: Variant = entity.get_unit_property("t_length", null)
	var speed: float = 100.0 / entity.factory.settings.unit_size
	speed = clampf(speed, 0.001, INF)

	# preparing to create animation key frames
	var right_vector := root.basis.x.normalized()
	var right_axis_index := right_vector.abs().max_axis_index()
	var right_offset := entity.aabb.size[right_axis_index]

	var forward_vector := -root.basis.z.normalized()
	var forward_axis_index := forward_vector.abs().max_axis_index()
	var forward_offset := entity.aabb.size[forward_axis_index]

	if spawnflags & 2: # move left first
		right_vector = -right_vector

	if spawnflags & 4: # move down first
		right_vector = -root.basis.y.normalized()
		var up_axis_index := right_vector.abs().max_axis_index()
		right_offset = entity.aabb.size[up_axis_index]

	if t_width != null: right_offset = clampf(t_width, 0.0, INF)
	if t_length != null: forward_offset = clampf(t_length, 0.0, INF)

	# calculating positions
	var close_position := entity.center
	var move_position1 := entity.center + right_vector * right_offset
	var move_position2 := move_position1 + forward_vector * forward_offset

	var frames := [
		0.0,
		right_offset / speed,
		right_offset / speed + animation_delay,
		forward_offset / speed,
		forward_offset / speed + animation_delay,
		(right_offset + forward_offset) / speed + animation_delay,
	]

	var parameters: Dictionary = {
		"door_track":
			NodePath(node.name),
		"close_position": transform * close_position,
		"move_position1": transform * move_position1,
		"move_position2": transform * move_position2,
		"frames": frames,
	}

	return [
		_build_open_animation(parameters),
		_build_opened_animation(parameters),
		_build_close_animation(parameters),
		_build_closed_animation(parameters),
	]


static func _build_open_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(0, p.door_track)

	animation.length = p.frames[5]
	animation.position_track_insert_key(0, p.frames[0], p.close_position)
	animation.position_track_insert_key(0, p.frames[1], p.move_position1)
	animation.position_track_insert_key(0, p.frames[2], p.move_position1)
	animation.position_track_insert_key(0, p.frames[5], p.move_position2)

	animation.track_set_interpolation_type(0, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(0, false)

	animation.track_set_imported(0, true)
	return animation


static func _build_opened_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(0, p.door_track)

	animation.length = 0.0
	animation.position_track_insert_key(0, p.frames[0], p.move_position2)

	animation.track_set_interpolation_type(0, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(0, false)

	animation.track_set_imported(0, true)
	return animation


static func _build_close_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(0, p.door_track)

	animation.length = p.frames[5]
	animation.position_track_insert_key(0, p.frames[0], p.move_position2)
	animation.position_track_insert_key(0, p.frames[3], p.move_position1)
	animation.position_track_insert_key(0, p.frames[4], p.move_position1)
	animation.position_track_insert_key(0, p.frames[5], p.close_position)

	animation.track_set_interpolation_type(0, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(0, false)

	animation.track_set_imported(0, true)
	return animation


static func _build_closed_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(0, p.door_track)

	animation.length = 0.0
	animation.position_track_insert_key(0, p.frames[0], p.close_position)

	animation.track_set_interpolation_type(0, Animation.INTERPOLATION_LINEAR)
	animation.track_set_interpolation_loop_wrap(0, false)

	animation.track_set_imported(0, true)
	return animation


static func _build_sound_tracks(animations: Array[Animation], nodes: Array) -> void:
	var move_sound_player: AudioStreamPlayer3D = nodes[1]
	var stop_sound_player: AudioStreamPlayer3D = nodes[2]
	var node: Node = nodes[0]

	const SOUNDS := preload("func_train.gd")
	SOUNDS._build_sound_player_track(node, animations[0], move_sound_player)
	SOUNDS._build_sound_player_track(node, animations[1], move_sound_player)
	SOUNDS._build_sound_player_track(node, animations[2], move_sound_player)
	SOUNDS._build_sound_player_track(node, animations[3], move_sound_player)
	SOUNDS._build_sound_player_track(node, animations[1], stop_sound_player)
	SOUNDS._build_sound_player_track(node, animations[3], stop_sound_player)

	var track := animations[0].get_track_count() - 1
	animations[0].track_insert_key(track, 0.0, true)
	animations[0].track_insert_key(track, animations[0].length, false)

	track = animations[1].get_track_count() - 2
	animations[1].track_insert_key(track + 0, 0.0, false)
	animations[1].track_insert_key(track + 1, 0.0, true)

	track = animations[2].get_track_count() - 1
	animations[2].track_insert_key(track, 0.0, true)
	animations[2].track_insert_key(track, animations[2].length, false)

	track = animations[3].get_track_count() - 2
	animations[3].track_insert_key(track + 0, 0.0, false)
	animations[3].track_insert_key(track + 1, 0.0, true)


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@SolidClass",
		"=", "func_door_secret", ":",
		'"secret door (activated by an entity)"',
		"[",
			"\n\tangle(float)", ":", '"direction of the second move"',
			"\n\ttarget(target_destination)", ":", '"target to activate"',
			"\n\tkilltarget(target_destination)", ":", '"target to destroy"',
			"\n\ttargetname(target_source)", ":", '"entity name"',
			"\n\tt_width(integer)", ":", '"first move length (units)"',
			"\n\tt_length(integer)", ":", '"second move length (units)"',
			"\n\twait(float)", ":", '"reset time"', ":", '"2.0"',
			"\n\tnoise1(string)", ":", '"move sound name"',
			"\n\tnoise2(string)", ":", '"stop sound name"',
			"\n\tspawnflags(flags)", "=",
			"[",
				"\n\t\t1", ":", '"opens once"', ":", "0",
				"\n\t\t2", ":", '"move left first"', ":", "0",
				"\n\t\t4", ":", '"move down first"', ":", "0",
			"\n\t]",
		"\n]\n",
	]).replace(" \n", "\n"))
