extends MapperUtilities

const BASE_CLASS_TARGET := false
const BASE_CLASS_KILLTARGET := false
const BASE_CLASS_TARGETNAME := true
const SPOT_LIGHT_MIN_RANGE_UNITS: float = 32.0

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var light: Light3D = null
	var light_prefix: String = "spot_"
	light = build_spot_light(map, entity)
	if not light:
		light = OmniLight3D.new()
		light_prefix = "omni_"

	var light_energy := float(entity.get_unit_property("light", 300.0))
	light_energy = float(entity.get_float_property("light_energy", light_energy))
	var light_color := Color(entity.get_color_property("_color", Color.WHITE))
	light_color = Color(entity.get_color_property("light_color", light_color))
	var wait := float(entity.get_float_property("wait", 1.0))

	if light is OmniLight3D:
		light.omni_range = absf(light_energy)
	elif entity.get_mangle_property(null) != null:
		light.spot_range = absf(light_energy) * 1.0

	# handling light delay property
	match entity.get_int_property("delay", 0):
		0: # linear falloff (default)
			light.set(light_prefix + "attenuation", 1.0)
		1: # inverse distance falloff
			light.set(light_prefix + "attenuation", 0.5)
		2: # inverse distance squared
			light.set(light_prefix + "attenuation", 0.25)
		3: # no falloff
			light.set(light_prefix + "attenuation", 0.01)
		4: # local minlight
			light.set(light_prefix + "attenuation", 0.01)
		5: # inverse distance squared B
			light.set(light_prefix + "attenuation", 2.0)
		_: light.set(light_prefix + "attenuation", 1.0)

	if light is SpotLight3D:
		light.spot_attenuation = entity.get_float_property(
			"light_attenuation", light.spot_attenuation)
	elif light is OmniLight3D:
		light.omni_attenuation = entity.get_float_property(
			"light_attenuation", light.omni_attenuation)

	# handling light wait property
	if light is SpotLight3D:
		light.spot_attenuation *= wait
	else: light.omni_attenuation *= wait

	if light is SpotLight3D:
		light.spot_angle = clampf(entity.get_float_property(
			"light_spot_angle", 45.0), 0.0, 180.0)
		light.spot_angle_attenuation = maxf(entity.get_float_property(
			"light_spot_angle_attenuation", 1.0), 0.0)

	light.light_color = light_color
	light.light_energy = absf(light_energy)
	light.light_indirect_energy = clampf(entity.get_float_property(
		"light_indirect_energy", 1.0), 0.0, 16.0)
	light.light_volumetric_fog_energy = 0.0

	light.light_size = maxf(
		entity.get_unit_property("light_size", 16.0), 0.0)
	light.light_negative = bool(light_energy < 0.0)
	light.light_specular = 0.0

	light.shadow_enabled = false
	light.set("omni_shadow_mode",
		OmniLight3D.SHADOW_DUAL_PARABOLOID)
	light.light_bake_mode = entity.get_int_property(
		"light_bake_mode", Light3D.BAKE_STATIC)

	light.distance_fade_enabled = true
	light.distance_fade_begin = 40.0
	light.distance_fade_length = 10.0

	var animation_player := AnimationPlayer.new()
	light.add_child(animation_player, map.settings.readable_node_names)
	var animations := build_animations(entity,
		[light, ])

	var animation_library := AnimationLibrary.new()
	animation_library.add_animation("00-normal", animations[0])
	animation_library.add_animation("01-flicker_A", animations[1])
	animation_library.add_animation("02-slow_strong_pulse", animations[2])
	animation_library.add_animation("03-candle_A", animations[3])
	animation_library.add_animation("04-fast_strobe", animations[4])
	animation_library.add_animation("05-gentle_pulse", animations[5])
	animation_library.add_animation("06-flicker_B", animations[6])
	animation_library.add_animation("07-candle_B", animations[7])
	animation_library.add_animation("08-candle_C", animations[8])
	animation_library.add_animation("09-slow_strobe", animations[9])
	animation_library.add_animation("10-fluorescent_flicker", animations[10])
	animation_library.add_animation("11-slow_pulse_noblack", animations[11])
	animation_player.add_animation_library("", animation_library)
	var animation_list := animation_library.get_animation_list()
	animation_list.sort_custom(func(a, b):
		return a.naturalcasecmp_to(b))
	animation_list.reverse()

	var light_style := int(entity.get_int_property("style", 0))
	if light_style > 0 and light_style <= 11:
		animation_player.autoplay = animation_list[light_style]
	else: animation_player.free()

	light.set_script(map.loader.load_script("scripts/light"))
	if entity.get_int_property("spawnflags", 0) & 1: # start off
		light.visible = false

	return light


static func build_spot_light(map: MapperMap, entity: MapperEntity) -> SpotLight3D:
	# lights with mangle property are spot lights
	if entity.get_mangle_property(null) != null:
		entity.bind_mangle_property("rotation", "YpR")
		return SpotLight3D.new()

	# lights that target info_null are spot lights
	var target := map.get_first_entity_target(entity,
		"target", "targetname", "info_null")
	if not target:
		return null

	var light := SpotLight3D.new()
	var origin := Vector3(entity.get_origin_property(entity.center))
	var target_origin := Vector3(target.get_origin_property(target.center))

	var direction := Vector3(target_origin - origin)
	var spot_range := direction.length()
	direction = direction.normalized()

	var entity_rotation := Vector3(
		entity.node_properties.get("rotation", Vector3.ZERO))
	var entity_basis := Basis.from_euler(entity_rotation)
	var entity_forward := -entity_basis.z
	var entity_up := entity_basis.y

	var light_rotation := Quaternion()
	if not direction.is_equal_approx(-entity_forward):
		light_rotation = Quaternion(entity_forward, direction)
	else: light_rotation = Quaternion(entity_up, PI)

	light.spot_range = (spot_range +
		SPOT_LIGHT_MIN_RANGE_UNITS / map.settings.unit_size)
	light.rotation = light_rotation.get_euler()
	entity.node_properties.erase("rotation")

	return light


@warning_ignore("unused_parameter")
static func build_animations(entity: MapperEntity, nodes: Array) -> Array[Animation]:
	var light: Light3D = nodes[0]

	# animation parameters
	var animation_offset: int = 0
	var animation_speed: float = 10.0
	var rng := RandomNumberGenerator.new()
	rng.seed = entity.get_int_property("style_seed", 0)
	if rng.seed != 0: animation_offset = rng.randi() % 256

	var animation_table: Dictionary = {
		1: "mmnmmommommnonmmonqnmmo",
		2: "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba",
		3: "mmmmmaaaaammmmmaaaaaabcdefgabcdefg",
		4: "mamamamamama",
		5: "jklmnopqrstuvwxyzyxwvutsrqponmlkj",
		6: "nmonqnmomnmomomno",
		7: "mmmaaaabcdefgmmmmaaaammmaamm",
		8: "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa",
		9: "aaaaaaaazzzzzzzz",
		10: "mmamammmmammamamaaamammma",
		11: "abcdefghijklmnopqrrqponmlkjihgfedcba",
	}

	var parameters: Dictionary = {
		"light_energy_track":
			NodePath("." + ":light_energy"),
		"light_indirect_energy_track":
			NodePath("." + ":light_indirect_energy"),
		"light_volumetric_fog_energy_track":
			NodePath("." + ":light_volumetric_fog_energy"),
		"light_energy": light.light_energy,
		"light_indirect_energy": light.light_indirect_energy,
		"light_volumetric_fog_energy": light.light_volumetric_fog_energy,
		"animation_speed": animation_speed,
		"animation_offset": animation_offset,
		"animation_table": animation_table,
		"current_animation": 1,
	}

	return [
		_build_normal_animation(parameters),
		_build_flicker_animation(parameters),
		_build_flicker_animation(parameters),
		_build_flicker_animation(parameters),
		_build_flicker_animation(parameters),
		_build_flicker_animation(parameters),
		_build_flicker_animation(parameters),
		_build_flicker_animation(parameters),
		_build_flicker_animation(parameters),
		_build_flicker_animation(parameters),
		_build_flicker_animation(parameters),
		_build_flicker_animation(parameters),
	]


static func _build_normal_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	animation.loop_mode = Animation.LOOP_NONE

	var index := animation.get_track_count()
	animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(index + 0, p.light_energy_track)
	animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(index + 1, p.light_indirect_energy_track)
	animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(index + 2, p.light_volumetric_fog_energy_track)

	animation.length = 0.0
	animation.track_insert_key(index + 0, 0.0, p.light_energy)
	animation.track_insert_key(index + 1, 0.0, p.light_indirect_energy)
	animation.track_insert_key(index + 2, 0.0, p.light_volumetric_fog_energy)

	for i in range(3):
		animation.value_track_set_update_mode(index + i, Animation.UPDATE_DISCRETE)
		animation.track_set_interpolation_type(index + i, Animation.INTERPOLATION_NEAREST)
		animation.track_set_interpolation_loop_wrap(index + i, false)

	animation.track_set_imported(index + 0, true)
	animation.track_set_imported(index + 1, true)
	animation.track_set_imported(index + 2, true)

	if p.light_volumetric_fog_energy == 0.0:
		animation.remove_track(index + 2)
	if p.light_indirect_energy == 0.0:
		animation.remove_track(index + 1)
	return animation


static func _build_flicker_animation(p: Dictionary) -> Animation:
	var animation := Animation.new()
	animation.loop_mode = Animation.LOOP_LINEAR

	var index := animation.get_track_count()
	animation.add_track(Animation.TYPE_VALUE)
	animation.add_track(Animation.TYPE_VALUE)
	animation.add_track(Animation.TYPE_VALUE)

	animation.track_set_path(index + 0, p.light_energy_track)
	animation.track_set_path(index + 1, p.light_indirect_energy_track)
	animation.track_set_path(index + 2, p.light_volumetric_fog_energy_track)

	var table: String = (
		p.animation_table[p.current_animation])
	var table_size := int(table.length())
	p.current_animation += 1

	animation.length = float(table_size)
	animation.length /= p.animation_speed
	for table_index in range(table_size + 1):
		var multiplier := float(table.unicode_at(int((table_index +
			p.animation_offset) % table_size)) - 97) * (2.0 / 25.0)
		var time := float(table_index / p.animation_speed)

		animation.track_insert_key(index + 0, time,
			p.light_energy * multiplier)
		animation.track_insert_key(index + 1, time,
			p.light_indirect_energy * multiplier)
		animation.track_insert_key(index + 2, time,
			p.light_volumetric_fog_energy * multiplier)

	for i in range(3):
		animation.value_track_set_update_mode(index + i, Animation.UPDATE_CONTINUOUS)
		animation.track_set_interpolation_type(index + i, Animation.INTERPOLATION_LINEAR)
		animation.track_set_interpolation_loop_wrap(index + i, false)

	animation.track_set_imported(index + 0, true)
	animation.track_set_imported(index + 1, true)
	animation.track_set_imported(index + 2, true)

	if p.light_volumetric_fog_energy == 0.0:
		animation.remove_track(index + 2)
	if p.light_indirect_energy == 0.0:
		animation.remove_track(index + 1)
	return animation


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@PointClass",
		"color(255 255 40)",
		"=", "light", ":",
		'"invisible light source"',
		"[",
			"\n\tmangle(string)", ":", '"spotlight angles"',
			"\n\ttargetname(target_source)", ":", '"entity name"',
			"\n\ttarget(target_destination)", ":", '"spotlight target"',
			"\n\tlight(integer)", ":", '"brightness (units)"', ":", "300",
			"\n\t_color(string)", ":", '"color (rgb)"', ":", '"255 255 255"',
			"\n\twait(float)", ":", '"fade distance multiplier"', ":", '"1.0"',
			"\n\tdelay(choices)", ":", '"attenuation"', ":", "0", "=",
			"[",
				"\n\t\t0", ":", '"linear falloff (default)"',
				"\n\t\t1", ":", '"inverse distance falloff"',
				"\n\t\t2", ":", '"inverse distance squared"',
				"\n\t\t3", ":", '"no falloff"',
				"\n\t\t4", ":", '"local minlight"',
				"\n\t\t5", ":", '"inverse distance squared B"',
			"\n\t]",
			"\n\tspawnflags(flags)", "=",
			"[",
				"\n\t\t1", ":", '"start off"', ":", "0",
			"\n\t]",

			"\n\tlight_attenuation(float)", ":", '"attenuation (float)"', ":", '"1.0"',
			"\n\tlight_spot_angle(float)", ":", '"angle (degrees)"', ":", '"45.0"',
			"\n\tlight_spot_angle_attenuation(float)", ":", '"spot attenuation (float)"', ":", '"1.0"',
			"\n\tlight_color(string)", ":", '"color (rgb)"', ":", '"255 255 255"',
			"\n\tlight_energy(float)", ":", '"brightness (float)"', ":", '"9.375"',
			"\n\tlight_indirect_energy(float)", ":", '"indirect energy (float)"', ":", '"1.0"',
			"\n\tlight_size(integer)", ":", '"size (units)"', ":", "16",
			"\n\tlight_bake_mode(choices)", ":", '"bake mode"', ":", "1", "=",
			"[",
				"\n\t\t0", ":", '"disabled"',
				"\n\t\t1", ":", '"enabled"',
			"\n\t]",

			"\n\tstyle_seed(integer)", ":", '"random seed"', ":", "0",
			"\n\tstyle(choices)", ":", '"appearance"', ":", "0", "=",
			"[",
				"\n\t\t0", ":", '"normal"',
				"\n\t\t1", ":", '"flicker A"',
				"\n\t\t2", ":", '"slow, strong pulse"',
				"\n\t\t3", ":", '"candle A"',
				"\n\t\t4", ":", '"fast strobe"',
				"\n\t\t5", ":", '"gentle pulse"',
				"\n\t\t6", ":", '"flicker B"',
				"\n\t\t7", ":", '"candle B"',
				"\n\t\t8", ":", '"candle C"',
				"\n\t\t9", ":", '"slow strobe"',
				"\n\t\t10", ":", '"fluorescent flicker"',
				"\n\t\t11", ":", '"slow pulse, noblack"',
			"\n\t]",
		"\n]\n",
	]).replace(" \n", "\n"))
