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

	node.set_script(map.loader.load_script(
		"scripts/trigger_once"))

	var sound_player := AudioStreamPlayer3D.new()
	node.add_child(sound_player, map.settings.readable_node_names)
	sound_player.stream = map.loader.load_sound("sounds/trigger_once")
	var noise: AudioStream = entity.get_sound_property("noise", null)
	node.set("_sound_player", node.get_path_to(sound_player))
	if noise != null: sound_player.stream = noise
	sound_player.playing = false

	var delay_timer := preload("func_button.gd"
		)._build_timer(map, entity, node, "delay", 0.0)

	if delay_timer:
		node.set("_delay_timer", node.get_path_to(delay_timer))
		delay_timer.timeout.connect(Callable(node,
			"_on_delay_timer_timeout"), CONNECT_PERSIST)

	node.monitorable = false
	node.body_entered.connect(Callable(node,
		"_on_body_entered"), CONNECT_PERSIST)

	return node


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@SolidClass",
		"=", "trigger_once", ":",
		'"trigger: once"',
		"[",
			"\n\ttarget(target_destination)", ":", '"target to activate"',
			"\n\tkilltarget(target_destination)", ":", '"target to destroy"',
			"\n\ttargetname(target_source)", ":", '"entity name"',
			"\n\tdelay(float)", ":", '"delay time"', ":", '"0.0"',
			"\n\tnoise(string)", ":", '"trigger sound name"',
		"\n]\n",
	]).replace(" \n", "\n"))
