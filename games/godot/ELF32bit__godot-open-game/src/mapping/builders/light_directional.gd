extends MapperUtilities

const BASE_CLASS_TARGET := false
const BASE_CLASS_KILLTARGET := false
const BASE_CLASS_TARGETNAME := true

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var light := build_directional_light(map, entity)
	var light_energy := float(entity.get_float_property("light_energy", 4.0))

	light.light_energy = absf(light_energy)
	light.light_color = entity.get_color_property("light_color", Color.WHITE)
	light.light_indirect_energy = clampf(entity.get_float_property(
		"light_indirect_energy", 1.0), 0.0, 16.0)
	light.light_volumetric_fog_energy = 0.0

	light.light_angular_distance = 0.0
	light.light_negative = bool(light_energy < 0.0)
	light.light_specular = 0.0

	light.shadow_enabled = false
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	light.light_bake_mode = entity.get_int_property(
		"light_bake_mode", Light3D.BAKE_STATIC)

	var animation_player := AnimationPlayer.new()
	light.add_child(animation_player, map.settings.readable_node_names)
	var animations: Array[Animation] = map.loader.load_script(
		"builders/light").build_animations(entity, [light, ])

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

	light.set_script(map.loader.load_script("scripts/light_directional"))
	if entity.get_int_property("spawnflags", 0) & 1: # start off
		light.visible = false

	return light


static func build_directional_light(map: MapperMap, entity: MapperEntity) -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	var world_entity := map.get_first_world_entity()
	if world_entity and world_entity.brushes.size():
		entity.parent = world_entity

	if entity.get_mangle_property(null) != null:
		entity.bind_mangle_property("rotation", "YpR")
		return light

	var target := map.get_first_entity_target(entity,
		"target", "targetname", "info_null")
	if not target: return light

	var origin := Vector3(entity.get_origin_property(entity.center))
	var target_origin := Vector3(target.get_origin_property(target.center))

	var direction := Vector3(target_origin - origin)
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

	light.rotation = light_rotation.get_euler()
	entity.node_properties.erase("rotation")

	return light


static func build_forge_game_data(entities: FileAccess) -> void:
	entities.store_string(" ".join([
		"@PointClass",
		"color(255 255 40)",
		"=", "light_directional", ":",
		'"invisible light source"',
		"[",
			"\n\tmangle(string)", ":", '"light angles"',
			"\n\ttargetname(target_source)", ":", '"entity name"',
			"\n\ttarget(target_destination)", ":", '"light target"',
			"\n\tspawnflags(flags)", "=",
			"[",
				"\n\t\t1", ":", '"start off"', ":", "0",
			"\n\t]",

			"\n\tlight_color(string)", ":", '"color (rgb)"', ":", '"255 255 255"',
			"\n\tlight_energy(float)", ":", '"brightness (float)"', ":", '"4.0"',
			"\n\tlight_indirect_energy(float)", ":", '"indirect energy (float)"', ":", '"1.0"',
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
