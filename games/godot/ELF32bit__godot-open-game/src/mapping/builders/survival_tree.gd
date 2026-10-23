extends MapperUtilities # TODO!

const BASE_CLASS_TARGET := true
const BASE_CLASS_KILLTARGET := true
const BASE_CLASS_TARGETNAME := true

const AREA_GROW_UNITS: float = 32.0
const AREA_CLEANUP_WHEN_NO_TIMER := true
const ANIMATIONS := preload("mining_coal.gd")

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node: AnimatableBody3D = null
	node = create_merged_brush_entity(entity, "AnimatableBody3D")
	if not node: return null

	var root := Node3D.new()
	root.transform = node.transform
	add_global_child(node, root, map.settings)

	var scale_node := Node3D.new()
	var pivot_offset := Vector3.DOWN * entity.aabb.size.y / 2.0
	scale_node.transform = node.transform.translated(pivot_offset)
	for child in node.find_children("*", "MeshInstance3D", false, false):
		child.get_parent().remove_child(child)
		add_global_child(child, scale_node, map.settings)
	node.add_child(scale_node, map.settings.readable_node_names)
	node.move_child(scale_node, 0)

	var area_data := _build_area(map, entity, root)
	var _area_shape: CollisionShape3D = area_data[1]
	var area: Area3D = area_data[0]
	area.monitoring = false

	var animation_player := AnimationPlayer.new()
	root.add_child(animation_player, map.settings.readable_node_names)
	var animations := build_animations(entity,
		[node, scale_node, ])

	var animation_library := AnimationLibrary.new()
	animation_player.add_animation_library("", animation_library)
	animation_library.add_animation("enable", animations[0])
	animation_library.add_animation("enabled", animations[1])
	animation_library.add_animation("disable", animations[2])
	animation_library.add_animation("disabled", animations[3])
	animation_player.autoplay = "enabled"

	node.set_script(map.loader.load_script("scripts/survival_tree"))
	node.set("mouse_cursor_override", entity.get_int_property("cursor", 1))

	root.set_script(map.loader.load_script("scripts/classes/collectable"))
	root.set("_animation_player", root.get_path_to(animation_player))
	root.set("_animatable_body", root.get_path_to(node))
	root.set("_area", root.get_path_to(area))

	animation_player.animation_finished.connect(Callable(root,
		"_on_animation_finished"), CONNECT_PERSIST)

	var wait_timer: Timer = (
		map.loader.load_script("builders/func_button"
		)._build_timer(map, entity, root, "wait", -1.0))

	if wait_timer:
		root.set("_wait_timer", root.get_path_to(wait_timer))
		wait_timer.timeout.connect(Callable(root,
			"_on_wait_timer_timeout"), CONNECT_PERSIST)
	elif AREA_CLEANUP_WHEN_NO_TIMER:
		root.set("_area", "")
		area.free()

	if not entity.get_string_property("targetname", "").is_empty():
		animation_player.autoplay = "disabled"

	return root


static func _build_area(map: MapperMap, entity: MapperEntity, parent: Node3D) -> Array:
	var area := Area3D.new()
	parent.add_child(area, map.settings.readable_node_names)
	area.monitorable = false

	var shape := CollisionShape3D.new()
	area.add_child(shape, map.settings.readable_node_names)
	var grow_units := AREA_GROW_UNITS / map.settings.unit_size
	var size := entity.aabb.grow(grow_units).size

	shape.shape = CapsuleShape3D.new()
	shape.shape.radius = maxf(size.x, size.z) * 0.5
	shape.shape.height = size.y

	parent.move_child(area, 0)
	return [area, shape]

@warning_ignore("unused_parameter")
static func build_animations(entity: MapperEntity, nodes: Array) -> Array[Animation]:
	var node: AnimatableBody3D = nodes[0]
	var shapes := node.find_children("*",
		"CollisionShape3D", false, false)
	var occluders := node.find_children("*",
		"OccluderInstance3D", false, false)
	var scale_node: Node3D = nodes[1]

	# animation parameters
	var disable_offset := Vector3.DOWN * entity.aabb.size.y
	var disable_time: float = 1.5
	var enable_time: float = 0.5

	var parameters: Dictionary = {
		"node": node,
		"scale_node": scale_node,
		"shapes": shapes,
		"occluders": occluders,
		"disable_offset": disable_offset,
		"frames": [0.0, enable_time, disable_time],
	}

	return [
		_build_enable_animation(parameters),
		_build_enabled_animation(parameters),
		_build_disable_animation(parameters),
		_build_disabled_animation(parameters),
	]


static func _build_enable_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	ANIMATIONS.__build_bool_track(animation, p,
		NodePath(p.node.name + ":visible"), 1)

	ANIMATIONS.__build_bool_track(animation, p, NodePath(
		p.node.name.path_join(p.scale_node.name) + ":visible"), 1)
	__build_position_track(animation, p, 1)
	__build_scale_track(animation, p, 0)

	for shape in p.shapes:
		if shape.disabled: continue
		ANIMATIONS.__build_bool_track(animation, p, NodePath(
			p.node.name.path_join(shape.name) + ":disabled"), 3)

	for occluder in p.occluders:
		if not occluder.visible: continue
		ANIMATIONS.__build_bool_track(animation, p, NodePath(
			p.node.name.path_join(occluder.name) + ":visible"), 2)

	animation.length = p.frames[1]
	return animation


static func _build_enabled_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	ANIMATIONS.__build_bool_track(animation, p,
		NodePath(p.node.name + ":visible"), 1)

	ANIMATIONS.__build_bool_track(animation, p, NodePath(
		p.node.name.path_join(p.scale_node.name) + ":visible"), 1)
	__build_position_track(animation, p, 1)
	__build_scale_track(animation, p, 1)

	for shape in p.shapes:
		if shape.disabled: continue
		ANIMATIONS.__build_bool_track(animation, p, NodePath(
			p.node.name.path_join(shape.name) + ":disabled"), 0)

	for occluder in p.occluders:
		if not occluder.visible: continue
		ANIMATIONS.__build_bool_track(animation, p, NodePath(
			p.node.name.path_join(occluder.name) + ":visible"), 1)

	animation.length = p.frames[0]
	return animation


static func _build_disable_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	ANIMATIONS.__build_bool_track(animation, p,
		NodePath(p.node.name + ":visible"), 1)
	var swap := float(p.frames[1])
	p.frames[1] = p.frames[2]

	ANIMATIONS.__build_bool_track(animation, p, NodePath(
		p.node.name.path_join(p.scale_node.name) + ":visible"), 3)
	__build_position_track(animation, p, 0)
	__build_scale_track(animation, p, 1)

	for shape in p.shapes:
		if shape.disabled: continue
		ANIMATIONS.__build_bool_track(animation, p, NodePath(
			p.node.name.path_join(shape.name) + ":disabled"), 1)

	for occluder in p.occluders:
		if not occluder.visible: continue
		ANIMATIONS.__build_bool_track(animation, p, NodePath(
			p.node.name.path_join(occluder.name) + ":visible"), 0)

	p.frames[1] = swap
	animation.length = p.frames[2]
	return animation


static func _build_disabled_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	ANIMATIONS.__build_bool_track(animation, p,
		NodePath(p.node.name + ":visible"), 0)

	ANIMATIONS.__build_bool_track(animation, p, NodePath(
		p.node.name.path_join(p.scale_node.name) + ":visible"), 0)
	__build_position_track(animation, p, 1)
	__build_scale_track(animation, p, 1)

	for shape in p.shapes:
		if shape.disabled: continue
		ANIMATIONS.__build_bool_track(animation, p, NodePath(
			p.node.name.path_join(shape.name) + ":disabled"), 1)

	for occluder in p.occluders:
		if not occluder.visible: continue
		ANIMATIONS.__build_bool_track(animation, p, NodePath(
			p.node.name.path_join(occluder.name) + ":visible"), 0)

	animation.length = p.frames[0]
	return animation


static func __build_position_track(animation: Animation, p: Dictionary, mode: int) -> void:
	var index := animation.get_track_count()
	animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(index, NodePath(
		p.node.name.path_join(p.scale_node.name) + ":position"))

	var start: Vector3 = p.scale_node.position
	var end: Vector3 = p.scale_node.position + p.disable_offset

	if mode == 0:
		animation.track_insert_key(index, p.frames[0], start)
		animation.track_insert_key(index, p.frames[1], end)
	else:
		animation.track_insert_key(index, p.frames[0], start)

	animation.value_track_set_update_mode(index, Animation.UPDATE_CONTINUOUS)
	animation.track_set_interpolation_type(index, Animation.INTERPOLATION_CUBIC)
	animation.track_set_interpolation_loop_wrap(index, false)

	animation.track_set_imported(index, true)
	return


static func __build_scale_track(animation: Animation, p: Dictionary, mode: int) -> void:
	var index := animation.get_track_count()
	animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(index, NodePath(
		p.node.name.path_join(p.scale_node.name) + ":scale"))

	if mode == 0:
		animation.track_insert_key(index, p.frames[0], Vector3(1.0, 0.0, 1.0))
		animation.track_insert_key(index, p.frames[1], Vector3(1.0, 1.0, 1.0))
	else:
		animation.track_insert_key(index, p.frames[0], Vector3(1.0, 1.0, 1.0))

	animation.value_track_set_update_mode(index, Animation.UPDATE_CONTINUOUS)
	animation.track_set_interpolation_type(index, Animation.INTERPOLATION_CUBIC)
	animation.track_set_interpolation_loop_wrap(index, false)

	animation.track_set_imported(index, true)
	return


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@SolidClass",
		"=", "survival_tree", ":",
		'"animated tree collectable"',
		"[",
			"\n\ttarget(target_destination)", ":", '"target to activate"',
			"\n\tkilltarget(target_destination)", ":", '"target to destroy"',
			"\n\ttargetname(target_source)", ":", '"entity name"',
			"\n\twait(float)", ":", '"wait time"', ":", '"-1.0"',
		"\n]\n",
	]).replace(" \n", "\n"))
