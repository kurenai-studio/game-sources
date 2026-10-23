extends MapperUtilities

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	return null


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@PointClass",
		"=", "info_animation", ":",
		'"helper for the animation system"',
		"[",
			"\n\tANIMATION(string)", ":", '"animation parameters"', ":",
			'"{',
				"\'loop_mode\': 1,",
				"\'frame_duration\': 0.2,",
				"\'fade\': [0.5, 0.7, 0.9],",
				"\'fade_loop\': false,",
				"\'fade_before\': true,",
				"\'fade_after\': false,",
				"\'fade_mode\': 1",
			'}"',
			"\n\tautoplay(string)", ":", '"default animation"',
			"\n\tfade_visibility_end(float)", ":", '"for after-images"', ":", '"0.0"',
			"\n\tvisibility_end(float)", ":", '"for meshes"', ":", '"0.0"',
			"\n\tcast_shadow(choices)", ":", '"shadow mode"', ":", "0", "=",
			"[",
				"\n\t\t0", ":", '"disabled"',
				"\n\t\t1", ":", '"on"',
				"\n\t\t2", ":", '"double sided"',
			"\n\t]",
		"\n]\n",
	]).replace(" \n", "\n"))
