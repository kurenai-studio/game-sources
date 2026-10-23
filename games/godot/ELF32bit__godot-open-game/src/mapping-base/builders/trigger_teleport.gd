extends MapperUtilities

const BASE_CLASS_TARGET := true
const BASE_CLASS_KILLTARGET := true
const BASE_CLASS_TARGETNAME := true

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node: Area3D = null
	node = create_brush_entity(entity,
		"Area3D", "", false, true, false)
	if not node: return null

	node.set_script(map.loader.load_script("scripts/trigger_teleport"))
	entity.bind_node_path_array_property("target", "targetname",
		"targets", "info_teleport_destination")

	var sounds: Array[AudioStream] = [
		map.loader.load_sound("sounds/trigger_teleport1"),
		map.loader.load_sound("sounds/trigger_teleport2"),
		map.loader.load_sound("sounds/trigger_teleport3"),
		map.loader.load_sound("sounds/trigger_teleport4"),
		map.loader.load_sound("sounds/trigger_teleport5"),
	]

	var noise1: AudioStream = entity.get_sound_property("noise1", null)
	var noise2: AudioStream = entity.get_sound_property("noise2", null)
	var noise3: AudioStream = entity.get_sound_property("noise3", null)
	var noise4: AudioStream = entity.get_sound_property("noise4", null)
	var noise5: AudioStream = entity.get_sound_property("noise5", null)
	if noise1 != null: sounds[0] = noise1
	if noise2 != null: sounds[1] = noise2
	if noise3 != null: sounds[2] = noise3
	if noise4 != null: sounds[3] = noise4
	if noise5 != null: sounds[4] = noise5

	sounds.filter(func(stream): return stream != null)
	node.set("teleport_sounds", sounds)

	node.monitorable = false
	node.body_entered.connect(Callable(node,
		"_on_body_entered"), CONNECT_PERSIST)

	return node


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@SolidClass",
		"=", "trigger_teleport", ":",
		'"trigger: teleport"',
		"[",
			"\n\ttarget(target_destination)", ":", '"target to activate"',
			"\n\tkilltarget(target_destination)", ":", '"target to destroy"',
			"\n\ttargetname(target_source)", ":", '"entity name"',
			"\n\tnoise1(string)", ":", '"trigger sound name"',
			"\n\tnoise2(string)", ":", '"trigger sound name"',
			"\n\tnoise3(string)", ":", '"trigger sound name"',
			"\n\tnoise4(string)", ":", '"trigger sound name"',
			"\n\tnoise5(string)", ":", '"trigger sound name"',
		"\n]\n",
	]).replace(" \n", "\n"))
