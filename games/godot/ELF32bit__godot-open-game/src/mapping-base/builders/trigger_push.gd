extends MapperUtilities

const BASE_CLASS_TARGETNAME := true

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node: Area3D = null
	node = create_brush_entity(entity,
		"Area3D", "", false, true, false)
	if not node: return null

	node.set_script(map.loader.load_script("scripts/trigger_push"))
	node.set("push_speed", entity.get_unit_property("speed", 1000.0))
	if entity.get_int_property("spawnflags", 0) & 1: # push once
		node.set("push_once", true)

	var sound_player := AudioStreamPlayer3D.new()
	node.add_child(sound_player, map.settings.readable_node_names)
	sound_player.stream = map.loader.load_sound("sounds/trigger_push")
	var noise: AudioStream = entity.get_sound_property("noise", null)
	node.set("_sound_player", node.get_path_to(sound_player))
	if noise != null: sound_player.stream = noise
	sound_player.autoplay = true

	node.monitorable = false
	node.body_entered.connect(Callable(node,
		"_on_body_entered"), CONNECT_PERSIST)

	return node


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@SolidClass",
		"=", "trigger_push", ":",
		'"trigger: push"',
		"[",
			"\n\tangle(float)", ":", '"direction of push"',
			"\n\tspeed(integer)", ":", '"speed (units)"', ":", "1000",
			"\n\ttargetname(target_source)", ":", '"entity name"',
			"\n\tnoise(string)", ":", '"trigger sound name"',
			"\n\tspawnflags(flags)", "=",
			"[",
				"\n\t\t1", ":", '"push once"', ":", "0",
			"\n\t]",
		"\n]\n",
	]).replace(" \n", "\n"))
