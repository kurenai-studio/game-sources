extends SceneTree
## Bootstrap for the simulation's first-slice content (Cave Age, with the turn into the Settled
## Age). Writes the config and content library under res://resources/sim/. Run once with:
##   & $env:GODOT --headless --path game --script res://tools/build_sim_content.gd
## The generated .tres files are ordinary resources: after this, edit them in the Godot
## inspector. Re-running overwrites them, so treat this script as a seed, not the source of truth.

const ROOT: String = "res://resources/sim"
const CAVE: int = 0
const SETTLED: int = 1
const BRONZE: int = 2
const IRON: int = 3
const CLASSICAL: int = 4
## Game days (72 per real day, see SimConfig) before each Cave Age milestone can happen, so the
## five-day age is spread out instead of finished in an afternoon. Fire is not staged: it is the
## opening. This is one table so the pace can be retuned in one place.
const UNLOCK_DAY: Dictionary = {
	&"stone_tools": 18,
	&"reliable_food": 54,
	&"shared_stories": 108,
	&"bigger_group": 162,
	&"seed_chain": 216,
}
## Game day each story decision becomes possible. They fill the stretches between the milestone
## unlocks above so something is waiting every few real hours (docs/gameplay.md P3, P10).
const STORY_DAY: Dictionary = {
	&"wolf": 4, &"hungry": 6, &"flint_edge": 24, &"frost": 32, &"prints": 42, &"feast": 60,
	&"hearth": 72, &"mammoth": 88, &"song": 115, &"wall": 126, &"ridge_smoke": 140,
	&"shelter": 172, &"river": 192, &"grain": 232, &"deer": 252, &"trader": 272, &"stars": 294,
	&"smoke": 316, &"tools_pile": 342,
	&"floors": 11, &"lost_flint": 80, &"night_noises": 98, &"ford": 152, &"feather": 182,
	&"bats": 204, &"honey": 227, &"fish_run": 246, &"drum": 265, &"first_snow": 285,
	&"echo": 307, &"sky_stone": 331, &"warm_pool": 350, &"low_tide": 215,
}
## Days into the Settled Age (not since the start) before each of its milestones can happen. The
## age is paced like the Cave Age: five hidden milestones spread over about the same five real
## days (docs/ages.md). `reeds` is the third, late route to woven cloth, open to every group.
const SETTLED_DAY: Dictionary = {
	&"first_roof": 18,
	&"first_harvest": 54,
	&"fired_clay": 108,
	&"woven_cloth": 162,
	&"reeds": 198,
	&"a_village": 216,
	&"green_stone": 252,
}
## Days into the Settled Age when each small story decision becomes possible, filling the stretches
## between the milestones above (the same idea as STORY_DAY). Paired entries (`furrows`/`pasture`,
## `scarecrow`/`dog`) are the farmers' and the herders' version of one beat.
const SETTLED_STORY_DAY: Dictionary = {
	&"cave": 2, &"ground": 8, &"furrows": 14, &"pasture": 14, &"roof": 38, &"well": 46,
	&"scarecrow": 58, &"dog": 58, &"store": 70, &"quarrel": 82, &"festival": 92, &"voice": 100,
	&"kiln": 118, &"wet": 130, &"fowl": 142, &"dye": 172, &"loom": 184, &"flood": 196,
	&"neighbours": 208, &"salt": 226, &"count": 238, &"beads": 262, &"wall": 286,
	&"looking_back": 312, &"threshold": 28, &"midsummer": 152, &"children": 274, &"fog": 298,
	&"evenings": 322, &"canoe": 160, &"weir": 218,
	# The two forks that end the Settled Age's quiet stretch before the gate opens at day 360.
	&"loads": 330, &"marks": 346,
}
## Days into the Bronze Age before each milestone can happen (docs/ages.md, "Bronze Age"): the same
## pace as the Settled Age's, five real days. `rollers` and `tally` are the late roads open to every
## group; `watch` is the late road to the last milestone.
const BRONZE_DAY: Dictionary = {
	&"first_casting": 18,
	&"bronze_alloy": 54,
	&"panning": 90,
	&"mud_brick_walls": 108,
	&"ditch": 144,
	&"wheel_and_road": 162,
	&"rollers": 198,
	&"a_town": 216,
	&"tally": 246,
	&"beyond_the_water": 252,
	&"watch": 288,
}
## Days into the Bronze Age when each small story decision becomes possible.
const BRONZE_STORY_DAY: Dictionary = {
	&"bellows": 2, &"charcoal": 8, &"hearth": 14, &"moulds": 24, &"bright": 32, &"night_hammer": 40,
	&"blade": 66, &"bricks": 90, &"coast_trader": 98, &"gate": 112, &"name": 120, &"wall_water": 130,
	&"weights": 140, &"smith_stays": 150, &"toll": 170, &"trader": 174, &"goods": 186,
	&"marked_pots": 228, &"sea_look": 262, &"night_light": 286, &"ringing_stone": 312,
	&"cracked_mould": 78, &"ruts": 198, &"quay": 204,
	# The two forks that end the Bronze Age's quiet stretch before the gate opens at day 360.
	&"red_water": 330, &"long_burn": 346,
}
## Chance per tick of a Bronze Age one-line moment; the earlier ages' lines keep happening too.
const BRONZE_AMBIENT_CHANCE: float = 0.002
## The Bronze Age opens after the Settled Age's five days (8640 ticks).
const BRONZE_MIN_TICKS: int = 8640
## Days into the Iron Age before each milestone can happen (docs/ages.md, "Iron Age"): the same pace
## as the Bronze Age's, five real days. `iron_axe`, `gate_iron`, `press_mark`, `copy_tablet` and
## `name_stone` are the late roads open to every group.
const IRON_DAY: Dictionary = {
	&"first_bloom": 18,
	&"fuller_harvest": 54,
	&"iron_axe": 90,
	&"hill_fort": 108,
	&"gate_iron": 144,
	&"silver_by_weight": 162,
	&"press_mark": 198,
	&"written_word": 216,
	&"copy_tablet": 246,
	&"name_abroad": 252,
	&"name_stone": 288,
}
## Days into the Iron Age when each small story decision becomes possible. The last three (`envoy`,
## `guest_table`, and the stone with a name before them) lead into the next age.
const IRON_STORY_DAY: Dictionary = {
	&"hotter_hearth": 2, &"downwind": 8, &"slow_work": 14, &"slag": 24, &"first_iron": 32,
	&"nails": 40, &"iron_pot": 66, &"rust": 78, &"frost": 90, &"tin_trader": 98, &"timber": 112,
	&"fort_name": 120, &"ditch_water": 130, &"bank_crop": 140, &"bank_crop_herd": 140,
	&"hands": 150, &"coin_face": 170, &"counter": 174, &"bad_silver": 186, &"gate_coin": 198,
	&"door_name": 228, &"hill_stone": 240, &"words": 262, &"sea_fire": 286, &"named_stone": 312,
	&"envoy": 330, &"guest_table": 346,
}
## Chance per tick of an Iron Age one-line moment; the earlier ages' lines keep happening too.
const IRON_AMBIENT_CHANCE: float = 0.002
## The Iron Age opens after the Bronze Age's five days (8640 ticks).
const IRON_MIN_TICKS: int = 8640
## Days into the Classical Age before each milestone can happen (docs/ages.md, "Classical Age"): the
## same pace as the Iron Age's, five real days. `shared_steps`, `rain_basin`, `promises`, `shade`,
## `reading_bench` and `teachers_abroad` are the late roads open to every group.
const CLASSICAL_DAY: Dictionary = {
	&"paved_streets": 18,
	&"shared_steps": 54,
	&"water_from_afar": 54,
	&"rain_basin": 90,
	&"written_law": 108,
	&"promises": 144,
	&"the_square": 162,
	&"shade": 198,
	&"lamp_and_stage": 216,
	&"reading_bench": 246,
	&"wider_world": 252,
	&"teachers_abroad": 288,
}
## Days into the Classical Age when each small story decision becomes possible. The last three look
## ahead to what a later age could inherit (docs/ages.md, "Medieval: the direction").
const CLASSICAL_STORY_DAY: Dictionary = {
	&"guest_ground": 2, &"street_turns": 8, &"mason_apprentice": 14, &"paving_rain": 24,
	&"courtyard": 32, &"baths": 66, &"channel_keepers": 72, &"shaded_basin": 84,
	&"readers": 114, &"seal": 126, &"newcomers": 138, &"lamplight": 168, &"craft_visitors": 178,
	&"book_copy": 222, &"play": 232, &"teaching": 242, &"harbour_signal": 266,
	&"words_home": 278, &"water_keepers": 312, &"journey_book": 326, &"market_returns": 340,
}
## Chance per tick of a Classical Age one-line moment; the earlier ages' lines keep happening too.
const CLASSICAL_AMBIENT_CHANCE: float = 0.002
## The Classical Age opens after the Iron Age's five days (8640 ticks).
const CLASSICAL_MIN_TICKS: int = 8640
## Chance per tick of a small journal line, and how long before the same one can repeat. About one
## line every quarter hour of real time across all of them.
const AMBIENT_CHANCE: float = 0.0045
## The Settled Age adds its own lines to the Cave Age's, which keep happening, so each is rarer.
const SETTLED_AMBIENT_CHANCE: float = 0.002
const AMBIENT_COOLDOWN: int = 360
## Units a villager gathers per tick of work; the starting stock is a few units, so early choices
## wait a little (docs/simulation.md, pacing).
const GATHER_RATE: float = 0.06
## Chance per tick that an eligible story decision is asked. Higher means it arrives close to its
## day instead of trailing it by several game days, which keeps the waits between questions even.
const STORY_CHANCE: float = 0.05
## Days later that a Lookout milestone still happens for a group that never built one. The Lookout
## makes the strangers and the scout come sooner; nothing depends on having it (docs/gameplay.md P13).
const NO_LOOKOUT_DELAY: int = 30


func _init() -> void:
	for folder: String in ["events", "buildings", "plants", "eras", "weathers"]:
		var path: String = ProjectSettings.globalize_path("%s/%s" % [ROOT, folder])
		DirAccess.make_dir_recursive_absolute(path)
	var config: SimConfig = SimConfig.new()
	config.gather_rate = GATHER_RATE
	_save(config, "%s/sim_config.tres" % ROOT)

	var library: ContentLibrary = ContentLibrary.new()
	library.eras.assign(_eras())
	library.buildings.assign(_buildings())
	library.plants.assign(_plants())
	library.weathers.assign(_weathers())
	library.events.assign(_events())
	_set_starting_group(library)
	library.starting_resources = _ints({&"wood": 2, &"food": 12})
	library.flag_housing = _ints({
		&"lean_to": 2, &"extra_roofs": 3, &"town_wall": 4, &"palisade": 3, &"dug_in": 2,
		&"hill_fort": 4,
	})
	for era: EraDef in library.eras:
		_save(era, "%s/eras/%s.tres" % [ROOT, era.id])
	for building: BuildingDef in library.buildings:
		_save(building, "%s/buildings/%s.tres" % [ROOT, building.id])
	for plant: PlantDef in library.plants:
		_save(plant, "%s/plants/%s.tres" % [ROOT, plant.id])
	for weather: WeatherDef in library.weathers:
		_save(weather, "%s/weathers/%s.tres" % [ROOT, weather.id])
	for event: EventDef in library.events:
		_save(event, "%s/events/%s.tres" % [ROOT, event.id])
	_save(library, "%s/content.tres" % ROOT)

	var problems: PackedStringArray = library.validate()
	for problem: String in problems:
		push_error("Content problem: %s" % problem)
	print("Wrote simulation content (%d problems)." % problems.size())
	quit(1 if not problems.is_empty() else 0)


func _eras() -> Array[EraDef]:
	var cave: EraDef = _era(&"cave", "Cave Age", CAVE)
	cave.description = "Hunter-gatherers sheltering in a cave, living by fire and flint."
	cave.housing = 4
	var settled: EraDef = _era(&"settled", "Settled Age", SETTLED)
	settled.description = "Farming and herding: people stay in one place and shape the land."
	settled.housing = 6
	settled.intro_text = "The group stayed by the field, and a new way of living began."
	# The hidden gate (docs/ages.md): every milestone, then a minimum of about five real days
	# (8640 ticks at 50 real seconds each). The player is never shown any of this.
	var milestones: Array[StringName] = [
		&"fire", &"stone_tools", &"reliable_food", &"shared_stories", &"bigger_group",
		&"unexpected_garden",
	]
	settled.required_achievements = milestones
	settled.min_ticks_in_previous_era = 8640
	settled.turn_event = &"seeds_of_a_new_life"
	var bronze: EraDef = _era(&"bronze", "Bronze Age", BRONZE)
	bronze.description = "Metal, roads and walls: villages grow into towns and look over the sea."
	bronze.housing = 8
	bronze.intro_text = "The green stone changed what the fire could do, and a new age began."
	# The gate: every Settled milestone, then another five real days (docs/ages.md B1).
	bronze.required_achievements = [
		&"first_roof", &"first_harvest", &"fired_clay", &"woven_cloth", &"a_village",
		&"green_stone",
	]
	bronze.min_ticks_in_previous_era = BRONZE_MIN_TICKS
	bronze.turn_event = &"the_metals_road"
	var iron: EraDef = _era(&"iron", "Iron Age", IRON)
	iron.description = "A harder metal, bigger fields and a fort on the hill: the town is known " \
			+ "beyond the water."
	iron.housing = 10
	iron.intro_text = "The dark stone would not melt in the bronze fire, so the fire was made " \
			+ "hotter, and a new age began."
	# The gate: every Bronze milestone, then another five real days (docs/ages.md I1).
	iron.required_achievements = [
		&"first_casting", &"bronze_alloy", &"mud_brick_walls", &"wheel_and_road", &"a_town",
		&"beyond_the_water",
	]
	iron.min_ticks_in_previous_era = IRON_MIN_TICKS
	iron.turn_event = &"a_harder_fire"
	var classical: EraDef = _era(&"classical", "Classical Age", CLASSICAL)
	classical.description = "Streets, water brought in, written law and a square: the town has " \
			+ "become a city among cities."
	classical.housing = 14
	classical.intro_text = "The strangers asked for a seat at the table, and the town became a " \
			+ "city, and a new age began."
	# The gate: every Iron milestone, then another five real days (docs/ages.md, "Classical Age").
	classical.required_achievements = [
		&"first_bloom", &"fuller_harvest", &"the_hill_fort", &"silver_by_weight",
		&"written_word", &"name_abroad",
	]
	classical.min_ticks_in_previous_era = CLASSICAL_MIN_TICKS
	classical.turn_event = &"a_seat_at_the_table"
	_set_profiles([cave, settled, bronze, iron, classical])
	return [cave, settled, bronze, iron, classical]


## What each age's villagers stand for (docs/ages.md, "How many people the strip shows"). A villager
## represents the settlement's people rather than counting them, so the ceiling stays small enough
## to read and cheap to run, and a later age's villager eats and brings in more to make up for it.
## `housing` is the age's own room; the ceiling is how far buildings and answers may stretch it.
## These are tuning profiles for the five ages, not rules for every future one.
const PROFILES: Array[Dictionary] = [
	{"id": &"cave", "limit": 6, "need": 1.0, "food": 1.0, "wood": 1.0},
	{"id": &"settled", "limit": 8, "need": 1.15, "food": 1.15, "wood": 1.1},
	{"id": &"bronze", "limit": 10, "need": 1.3, "food": 1.3, "wood": 1.2},
	{"id": &"iron", "limit": 12, "need": 1.5, "food": 1.5, "wood": 1.35},
	{"id": &"classical", "limit": 14, "need": 1.7, "food": 1.7, "wood": 1.5},
]


func _set_profiles(eras: Array[EraDef]) -> void:
	for era: EraDef in eras:
		for profile: Dictionary in PROFILES:
			if profile["id"] == era.id:
				era.max_villagers = int(profile["limit"])
				era.food_need_scale = float(profile["need"])
				era.food_yield_scale = float(profile["food"])
				era.wood_yield_scale = float(profile["wood"])


func _set_starting_group(library: ContentLibrary) -> void:
	library.villager_names.assign([
		"Mira", "Theo", "Wren", "Ash", "Bram", "Cora", "Dov", "Elm", "Fenn", "Gale", "Hale",
		"Ivo", "Juno", "Kest", "Lark", "Moss", "Nia", "Orin", "Pike", "Rue", "Sage", "Tarn",
		"Una", "Vale",
	])
	library.villager_traits.assign([
		VillagerState.TRAIT_CURIOUS, VillagerState.TRAIT_SOCIAL,
		VillagerState.TRAIT_INDUSTRIOUS, VillagerState.TRAIT_NATURE_LOVING,
	])
	library.villager_looks.assign([&"mira", &"theo", &"wren"])
	library.starting_villager_count = 3
	library.traits_per_villager = 2
	library.guaranteed_traits.assign([VillagerState.TRAIT_CURIOUS])


func _buildings() -> Array[BuildingDef]:
	var lookout: BuildingDef = _building(&"lookout", "Lookout", {&"wood": 8}, 36)
	lookout.tags = [&"exposed"]
	lookout.description = "A high place to watch the valleys for game, weather and what lies ahead."
	var rack: BuildingDef = _building(&"drying_rack", "Drying Rack", {&"wood": 10}, 30)
	rack.tags = [&"river", &"dry", &"exposed"]
	rack.description = "Racks for drying meat and berries so they keep through the cold."
	rack.daily_output = _floats({&"food": 1.0})
	rack.completion_achievement = &"reliable_food"
	rack.completion_achievement_title = "Enough to Eat"
	var knapping: BuildingDef = _building(&"knapping_spot", "Knapping Spot", {&"wood": 12}, 40)
	knapping.description = "A flat stone and a pile of flint: a place to make better tools."
	knapping.daily_output = _floats({&"wood": 0.5})
	knapping.completion_achievement = &"stone_tools"
	knapping.completion_achievement_title = "Stone Tools"
	var hut: BuildingDef = _building(&"hut", "Hut", {&"wood": 14}, 40)
	hut.description = "A proper shelter, built where the group means to stay."
	hut.completion_achievement = &"first_roof"
	hut.completion_achievement_title = "A Roof of Your Own"
	hut.housing = 3
	hut.tags = [&"exposed"]
	var field: BuildingDef = _building(&"field", "Field", {&"wood": 12}, 36)
	field.description = "Ground cleared and sown, feeding the group season after season."
	field.daily_output = _floats({&"food": 3.0})
	field.tags = [&"river", &"dry"]
	field.completion_achievement = &"first_harvest"
	field.completion_achievement_title = "The First Harvest"
	var smithy: BuildingDef = _building(&"smithy", "Smithy", {&"wood": 16}, 40)
	smithy.description = "A clay furnace, an anvil stone and a pile of charcoal: a place to work metal."
	smithy.daily_output = _floats({&"wood": 0.5})
	smithy.tags = [&"exposed"]
	smithy.completion_achievement = &"first_casting"
	smithy.completion_achievement_title = "The First Casting"
	var post: BuildingDef = _building(&"trading_post", "Trading Post", {&"wood": 14}, 36)
	post.description = "A stall by the road where whatever the group lacks changes hands."
	post.daily_output = _floats({&"food": 0.4, &"wood": 0.4})
	post.tags = [&"exposed"]
	var quay: BuildingDef = _building(&"quay", "Quay", {&"wood": 14}, 36)
	quay.description = "A timber pier where the boats tie up and the catch comes in."
	quay.daily_output = _floats({&"food": 0.5})
	quay.tags = [&"river", &"exposed"]
	quay.completion_flag = &"quay_built"
	var bloomery: BuildingDef = _building(&"bloomery", "Bloomery", {&"wood": 18}, 44)
	bloomery.description = "A tall clay furnace with a pair of bellows: a place to turn red ore " \
			+ "into iron."
	bloomery.daily_output = _floats({&"wood": 0.5})
	bloomery.tags = [&"exposed"]
	bloomery.completion_achievement = &"first_bloom"
	bloomery.completion_achievement_title = "The First Bloom"
	var granary: BuildingDef = _building(&"granary", "Granary", {&"wood": 14}, 40)
	granary.description = "A raised timber store on stone legs, where the grain keeps dry and the " \
			+ "mice keep out."
	granary.daily_output = _floats({&"food": 0.5})
	return [lookout, rack, knapping, hut, field, smithy, post, quay, bloomery, granary]


func _plants() -> Array[PlantDef]:
	var flower: PlantDef = PlantDef.new()
	flower.id = &"strange_flower"
	flower.display_name = "Strange flower"
	flower.seed_item = &"strange_seed"
	flower.ticks_to_flower = 72
	flower.flower_text = "The strange seed flowered by the cave mouth."
	flower.flower_flag = &"strange_flower_bloomed"
	flower.flower_achievement = &"unexpected_garden"
	flower.flower_achievement_title = "Unexpected Garden"
	return [flower]


func _events() -> Array[EventDef]:
	var events: Array[EventDef] = [
		_fire_from_storm(),
		_fire_from_sparks(),
		_embers_remain(),
		_cracking_nuts(),
		_hammerstone_splits(),
		_herds_nearby(),
		_baskets_keep(),
		_stories_by_the_fire(),
		_ochre_on_the_riverbank(),
		_strangers_on_the_ridge(),
		_strangers_at_the_edge(),
		_strangers_come(),
		_building_opportunity(),
		_settled_building_opportunity(),
		_curious_explorer(),
		_restless_explorer(),
		_explorer_returns(),
		_seed_in_pouch(),
		_seeds_of_a_new_life(),
		_rare_butterfly(),
		_heavy_rain(),
		_cold_night(),
	]
	events.append_array(_settled_milestones())
	events.append_array(_weather_events())
	events.append_array(_story_decisions())
	events.append_array(_settled_stories())
	events.append_array(_growth_decisions())
	events.append_array(_ambient_lines())
	events.append_array(_settled_ambient_lines())
	events.append_array(_bronze_events())
	events.append_array(_iron_events())
	events.append_array(_classical_events())
	return events


## The first milestone. The Cave Age starts cold and dark; fire is found by one of two routes,
## and a player who passes on either still gets it (the embers), only a little later.
func _fire_from_storm() -> EventDef:
	var event: EventDef = _event(&"fire_from_storm", "A burning tree", &"nature")
	event.body = "A storm rolled over the valley in the night. On the ridge a lone tree is " \
			+ "burning, and even from here its glow is warm."
	event.requires = _conds([
		_cond(SimCondition.Kind.FLAG_SET, &"fire_found", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", 1),
	])
	event.needs_subject = true
	event.subject_requires = _conds([
		_cond(SimCondition.Kind.SUBJECT_HAS_TRAIT, VillagerState.TRAIT_CURIOUS),
		_cond(SimCondition.Kind.SUBJECT_AT_HOME),
	])
	event.chance_per_tick = 0.04
	event.cooldown_ticks = 24
	var carry: ChoiceDef = _choice(&"carry_fire", "Carry a burning branch back to the cave")
	carry.effects = _effs(_fire_found_effects(
		"{subject} carried a burning branch back through the rain, and the cave was warm for the first time."
	))
	var avoid: ChoiceDef = _choice(&"wait_for_embers", "Wait for it to burn down, then take the embers")
	avoid.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"embers_waited"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The group watched the burning tree from a distance until it was ash and embers."
		),
		_eff(SimEffect.Kind.SCHEDULE_EVENT, &"embers_remain", 48),
	])
	event.choices = _choices([carry, avoid])
	return event


func _fire_from_sparks() -> EventDef:
	var event: EventDef = _event(&"fire_from_sparks", "Sparks", &"settlement")
	event.body = "{subject} was knocking two stones together when a spark caught in a nest " \
			+ "of dry moss."
	event.requires = _conds([
		_cond(SimCondition.Kind.FLAG_SET, &"fire_found", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", 1),
	])
	event.needs_subject = true
	event.subject_requires = _conds([
		_cond(SimCondition.Kind.SUBJECT_HAS_TRAIT, VillagerState.TRAIT_INDUSTRIOUS),
		_cond(SimCondition.Kind.SUBJECT_AT_HOME),
	])
	event.chance_per_tick = 0.03
	event.cooldown_ticks = 24
	var blow: ChoiceDef = _choice(&"blow_on_it", "Blow on the spark, gently")
	blow.effects = _effs(_fire_found_effects(
		"{subject} blew on the spark until the moss glowed, and the first fire of the camp was lit."
	))
	var brush: ChoiceDef = _choice(&"tend_the_spark", "Shelter it and tend it until morning")
	brush.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"embers_waited"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} cupped the spark in the moss all night, and by dawn it was a bed of embers."
		),
		_eff(SimEffect.Kind.SCHEDULE_EVENT, &"embers_remain", 72),
	])
	event.choices = _choices([blow, brush])
	return event


## Scheduled only: the slower road to fire for a group that waited instead of carrying it home.
func _embers_remain() -> EventDef:
	var event: EventDef = _event(&"embers_remain", "Embers", &"nature")
	event.requires = _conds([_cond(SimCondition.Kind.FLAG_SET, &"fire_found", 0, true)])
	event.effects = _effs(_fire_found_effects(
		"In the grey morning the group went back for the last glowing embers, and carried the first fire home."
	))
	return event


func _fire_found_effects(text: String) -> Array[SimEffect]:
	return [
		_eff(SimEffect.Kind.SET_FLAG, &"fire_found"),
		_eff(SimEffect.Kind.JOURNAL, &"", 0, text),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"fire", 0, "Fire"),
	]


## Milestone events pick anyone at home as the subject; a matching trait only makes the person
## likelier, so no random group can be locked out of a milestone.
func _milestone_event(
	event_id: StringName, title: String, category: StringName, favoured: StringName
) -> EventDef:
	var event: EventDef = _event(event_id, title, category)
	event.needs_subject = true
	event.subject_requires = _conds([_cond(SimCondition.Kind.SUBJECT_AT_HOME)])
	event.trait_weights[favoured] = 3.0
	event.chance_per_tick = 0.03
	event.cooldown_ticks = 48
	return event


## Stone Tools, second route (the first is building the Knapping Spot).
func _cracking_nuts() -> EventDef:
	var event: EventDef = _milestone_event(
		&"cracking_nuts", "A sharp stone", &"character", VillagerState.TRAIT_NATURE_LOVING
	)
	event.body = "{subject} was cracking nuts with a river stone when it split, leaving an " \
			+ "edge sharper than anything the group owns."
	event.requires = _conds([
		_cond(SimCondition.Kind.FLAG_SET, &"fire_found"),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"stone_tools", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", UNLOCK_DAY[&"stone_tools"]),
	])
	var keep: ChoiceDef = _choice(&"keep_the_stone", "Keep it, and try making more")
	keep.effects = _effs([
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} struck the split stone against another, and by evening everyone was making sharp edges."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"stone_tools", 0, "Stone Tools"),
	])
	var toss: ChoiceDef = _choice(&"keep_cracking", "Keep cracking nuts with it")
	toss.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"nut_hammer"),
		_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 3),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} kept cracking nuts with the split stone, and the others queued up to try it."
		),
		_eff(SimEffect.Kind.SCHEDULE_EVENT, &"hammerstone_splits", 96),
	])
	event.choices = _choices([keep, toss])
	return event


## Scheduled only: the stone that was kept for cracking nuts breaks, and the group learns the
## same thing the other way round.
func _hammerstone_splits() -> EventDef:
	var event: EventDef = _event(&"hammerstone_splits", "The hammerstone breaks", &"character")
	event.needs_subject = true
	event.requires = _conds([
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"stone_tools", 0, true),
	])
	event.effects = _effs([
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The old nut stone finally split clean across, and the edge it left was sharper than "
			+ "anything the group owned. By evening everyone was making edges."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"stone_tools", 0, "Stone Tools"),
	])
	return event


## Reliable Food, the first route (the second is building the Drying Rack). Either the group
## hunts, which counts at once, or it forages and the Drying Rack makes the food last.
func _herds_nearby() -> EventDef:
	var event: EventDef = _event(&"herds_nearby", "The herds are close", &"exploration")
	event.body = "A herd has wandered into the valley below the cave. Food has been uncertain " \
			+ "for days, and this might be the chance to change that."
	event.requires = _conds([
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"stone_tools"),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"reliable_food", 0, true),
		_cond(SimCondition.Kind.FLAG_SET, &"path_foraging", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", UNLOCK_DAY[&"reliable_food"]),
	])
	event.chance_per_tick = 0.03
	event.cooldown_ticks = 48
	var hunt: ChoiceDef = _choice(&"hunt", "Make spears and hunt together")
	hunt.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"path_hunting"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The group carved spears and brought down a deer together. There was meat for everyone."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"reliable_food", 0, "Enough to Eat"),
	])
	var forage: ChoiceDef = _choice(&"forage", "Weave baskets and gather instead")
	forage.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"path_foraging"),
		_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 6),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The group wove reed baskets and spent the day gathering along the river."
		),
		_eff(SimEffect.Kind.SCHEDULE_EVENT, &"baskets_keep", 96),
	])
	event.choices = _choices([hunt, forage])
	return event


## Scheduled only: the foragers' road to Reliable Food, a little slower than the hunters'. The
## Drying Rack still gets there first.
func _baskets_keep() -> EventDef:
	var event: EventDef = _event(&"baskets_keep", "Baskets that keep", &"settlement")
	event.requires = _conds([
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"reliable_food", 0, true),
	])
	event.effects = _effs([
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The baskets hung from the cave roof stayed full through the lean weeks, and nobody "
			+ "woke hungry."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"reliable_food", 0, "Enough to Eat"),
	])
	return event


## Shared Stories, first route.
func _stories_by_the_fire() -> EventDef:
	var event: EventDef = _milestone_event(
		&"stories_by_the_fire", "A story by the fire", &"character", VillagerState.TRAIT_SOCIAL
	)
	event.body = "{subject} has started telling the others about the day, and for once nobody " \
			+ "is eager to sleep."
	event.requires = _conds([
		_cond(SimCondition.Kind.FLAG_SET, &"fire_found"),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"shared_stories", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", UNLOCK_DAY[&"shared_stories"]),
	])
	var tell: ChoiceDef = _choice(&"tell_it", "Gather everyone to listen")
	tell.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"tales_told"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} told the story of the day, and soon everyone was adding to it. By the end they told it the same way each night."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"shared_stories", 0, "Shared Stories"),
	])
	var pass_on: ChoiceDef = _choice(&"sing_it", "Let them sing it instead")
	pass_on.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"songs_sung"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} sang the story of the day, and one by one the others found the tune. By the end they sang it the same way each night."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"shared_stories", 0, "Shared Stories"),
	])
	event.choices = _choices([tell, pass_on])
	return event


## Shared Stories, second route.
func _ochre_on_the_riverbank() -> EventDef:
	var event: EventDef = _milestone_event(
		&"ochre_on_the_riverbank", "Red earth", &"nature", VillagerState.TRAIT_NATURE_LOVING
	)
	event.body = "{subject} came back from the riverbank with hands stained deep red, and a " \
			+ "lump of the earth that did it."
	event.requires = _conds([
		_cond(SimCondition.Kind.FLAG_SET, &"fire_found"),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"shared_stories", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", UNLOCK_DAY[&"shared_stories"]),
	])
	var paint: ChoiceDef = _choice(&"paint_the_wall", "Let them mark the cave wall")
	paint.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"cave_art"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} pressed a red hand to the cave wall, and one by one the others added theirs."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"shared_stories", 0, "Shared Stories"),
	])
	var wash: ChoiceDef = _choice(&"paint_faces", "Let them paint faces and hands instead")
	wash.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"body_paint"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} painted a red line down a friend's cheek, and by dark the whole camp wore it."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"shared_stories", 0, "Shared Stories"),
	])
	event.choices = _choices([paint, wash])
	return event


## A Bigger Group. The lookout is how the strangers are seen at all.
func _strangers_on_the_ridge() -> EventDef:
	var event: EventDef = _event(&"strangers_on_the_ridge", "Strangers on the ridge", &"exploration")
	event.body = "From the lookout, two strangers can be seen on the ridge, watching the smoke " \
			+ "of the cave fire. They have kept their distance for two days."
	event.requires = _conds([
		_cond(SimCondition.Kind.HAS_BUILDING, &"lookout"),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"bigger_group", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", UNLOCK_DAY[&"bigger_group"]),
	])
	event.chance_per_tick = 0.02
	event.cooldown_ticks = 72
	event.choices = _strangers_choices()
	return event


## The same strangers for a group with no Lookout: nobody sees them coming, so they are noticed a
## month later at the edge of the firelight. The Lookout is only ever a faster road.
func _strangers_at_the_edge() -> EventDef:
	var event: EventDef = _event(&"strangers_at_the_edge", "Strangers at the edge", &"exploration")
	event.body = "Two strangers have been seen at dusk, just beyond the firelight, watching the " \
			+ "smoke of the cave fire. They have kept their distance for two days."
	event.requires = _conds([
		_cond(SimCondition.Kind.HAS_BUILDING, &"lookout", 0, true),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"bigger_group", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", UNLOCK_DAY[&"bigger_group"] + NO_LOOKOUT_DELAY),
	])
	event.chance_per_tick = 0.02
	event.cooldown_ticks = 72
	event.choices = _strangers_choices()
	return event


func _strangers_choices() -> Array[ChoiceDef]:
	var welcome: ChoiceDef = _choice(&"welcome_them", "Welcome them to the fire")
	welcome.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"strangers_welcomed"),
		_eff(SimEffect.Kind.ADD_VILLAGER, &"", 2),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The two strangers came down from the ridge, and the group grew."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"bigger_group", 0, "A Bigger Group"),
	])
	var court: ChoiceDef = _choice(&"leave_food", "Leave food at the edge of the light")
	court.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"strangers_courted"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"A bundle of food was left at the edge of the light, and the strangers watched it "
			+ "for a long time."
		),
		_eff(SimEffect.Kind.SCHEDULE_EVENT, &"strangers_come", 72),
	])
	return _choices([welcome, court])


## Scheduled only: the cautious road to A Bigger Group, where the strangers decide for themselves.
func _strangers_come() -> EventDef:
	var event: EventDef = _event(&"strangers_come", "The strangers come in", &"exploration")
	event.requires = _conds([
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"bigger_group", 0, true),
	])
	event.effects = _effs([
		_eff(SimEffect.Kind.ADD_VILLAGER, &"", 2),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The bundle was gone one morning, and that evening the two strangers walked in on "
			+ "their own and sat down at the edge of the fire."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"bigger_group", 0, "A Bigger Group"),
	])
	return event


func _building_opportunity() -> EventDef:
	var event: EventDef = _event(&"building_opportunity", "Ready to build", &"settlement")
	event.body = "The group has gathered enough to improve the camp."
	event.requires = _conds([
		_cond(SimCondition.Kind.FLAG_SET, &"fire_found"),
		_cond(SimCondition.Kind.CONSTRUCTION_IDLE),
		_cond(SimCondition.Kind.RESOURCE_AT_LEAST, &"wood", 8),
	])
	event.chance_per_tick = 0.5
	event.cooldown_ticks = 24
	event.choices = _choices([
		_build_choice(&"build_lookout", "Lookout", &"lookout", 8),
		_build_choice(
			&"build_drying_rack", "Drying Rack", &"drying_rack", 10, UNLOCK_DAY[&"reliable_food"]
		),
		_build_choice(
			&"build_knapping_spot", "Knapping Spot", &"knapping_spot", 12,
			UNLOCK_DAY[&"stone_tools"]
		),
	])
	return event


func _settled_building_opportunity() -> EventDef:
	var event: EventDef = _event(
		&"settled_building_opportunity", "Building a settlement", &"settlement"
	)
	event.body = "Staying in one place means building for it."
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", SETTLED),
		_cond(SimCondition.Kind.CONSTRUCTION_IDLE),
		_cond(SimCondition.Kind.RESOURCE_AT_LEAST, &"wood", 12),
	])
	event.chance_per_tick = 0.5
	event.cooldown_ticks = 24
	event.choices = _choices([
		_build_choice(&"build_hut", "Hut", &"hut", 14, 0, SETTLED_DAY[&"first_roof"]),
		_build_choice(&"build_field", "Field", &"field", 12, 0, SETTLED_DAY[&"first_roof"]),
	])
	return event


## The Settled Age's six hidden milestones, each with more than one route (docs/ages.md). A group
## that herds and a group that farms reach some by different roads, and one late route is open to
## everyone so no group is locked out. The last one looks outward, to what the next age is built
## on. Nothing here is shown to the player.
func _settled_milestones() -> Array[EventDef]:
	return [
		_thatched_roof(), _first_calves(), _clay_hardens(), _shaped_bowls(), _flax_in_the_field(),
		_wool_on_the_thorns(), _plaited_reeds(), _families_on_the_road(), _the_long_table(),
		_green_stone_found(), _green_stone_traded(), _green_stone_shown(), _village_gathers(),
	]


## Every Settled milestone event: Settled Age, far enough into it, and not yet earned.
func _settled_milestone(
	event_id: StringName, title: String, category: StringName, favoured: StringName,
	era_day: int, milestone: StringName
) -> EventDef:
	var event: EventDef = _milestone_event(event_id, title, category, favoured)
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", SETTLED),
		_cond(SimCondition.Kind.ERA_DAYS_AT_LEAST, &"", era_day),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, milestone, 0, true),
	])
	return event


func _earn(milestone: StringName, title: String) -> SimEffect:
	return _eff(SimEffect.Kind.ACHIEVEMENT, milestone, 0, title)


## A Roof of Your Own, second route (the first is building the Hut).
func _thatched_roof() -> EventDef:
	var event: EventDef = _settled_milestone(
		&"thatched_roof", "Rain through the hides", &"character",
		VillagerState.TRAIT_INDUSTRIOUS, SETTLED_DAY[&"first_roof"], &"first_roof"
	)
	event.body = "{subject} is tired of rain dripping through the hides. Bundles of river " \
			+ "reed, bound tight over the poles, might shed it."
	event.choices = _choices([
		_answer(
			&"thatch_it", "Bind reeds into a thatch",
			"{subject} lashed reed bundles over the poles, and that night the rain ran off "
			+ "the roof as if it had never been a problem.",
			[_set_flag(&"thatched_roofs"), _earn(&"first_roof", "A Roof of Your Own")],
		),
		_answer(
			&"make_do", "Lay turf over the poles",
			"{subject} cut turf from the meadow and laid it over the poles, grass side up, and by "
			+ "the next rain it had started to grow.",
			[_set_flag(&"turf_roofs"), _earn(&"first_roof", "A Roof of Your Own")],
		),
	])
	return event


## The First Harvest, the herders' route (the farmers' is building the Field).
func _first_calves() -> EventDef:
	var event: EventDef = _event(&"first_calves", "Calves in the spring", &"nature")
	event.body = "The herd that winters by the camp has calves this spring: small, unsteady " \
			+ "things, and their mothers watch the camp with suspicion."
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", SETTLED),
		_cond(SimCondition.Kind.ERA_DAYS_AT_LEAST, &"", SETTLED_DAY[&"first_harvest"]),
		_cond(SimCondition.Kind.FLAG_SET, &"path_herding"),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"first_harvest", 0, true),
		_season(Season.SPRING),
	])
	event.chance_per_tick = 0.03
	event.cooldown_ticks = 48
	event.choices = _choices([
		_answer(
			&"tend_the_calves", "Keep them close and tend the herd",
			"The group kept watch through the long nights of calving. By midsummer there was "
			+ "milk, and nobody had lost an animal.",
			[
				_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 4),
				_set_flag(&"calves_penned"),
				_earn(&"first_harvest", "The First Calves"),
			],
		),
		_answer(
			&"let_them_roam", "Let them graze the far meadow with a watcher",
			"A watcher took the calves out to the far meadow each morning, and the herd came home "
			+ "fat and unbothered.",
			[_set_flag(&"calves_grazing"), _earn(&"first_harvest", "The First Calves")],
		),
	])
	return event


## Fired Clay, first route.
func _clay_hardens() -> EventDef:
	var event: EventDef = _settled_milestone(
		&"clay_hardens", "Clay by the fire", &"character", VillagerState.TRAIT_CURIOUS,
		SETTLED_DAY[&"fired_clay"], &"fired_clay"
	)
	event.body = "{subject} left a basket smeared with river clay too close to the fire. The " \
			+ "basket burned away, but the clay did not melt. It stood there hard and red, and " \
			+ "rang when it was tapped."
	event.choices = _choices([
		_answer(
			&"fire_a_pot", "Shape some clay and fire it on purpose",
			"{subject} shaped a squat little pot and buried it in hot ashes. Next morning it "
			+ "held water, and everyone had to hold it.",
			[_set_flag(&"pot_fired"), _earn(&"fired_clay", "Fired Clay")],
		),
		_answer(
			&"leave_the_shell", "Bake a flat dish on hot stones",
			"{subject} shaped a flat dish and set it on stones heated in the fire, and by evening "
			+ "it was a plate that held a fish.",
			[_set_flag(&"dish_baked"), _earn(&"fired_clay", "Fired Clay")],
		),
	])
	return event


## Fired Clay, second route.
func _shaped_bowls() -> EventDef:
	var event: EventDef = _settled_milestone(
		&"shaped_bowls", "Bowls in the sun", &"character", VillagerState.TRAIT_INDUSTRIOUS,
		SETTLED_DAY[&"fired_clay"], &"fired_clay"
	)
	event.body = "{subject} has been shaping the soft clay of the riverbank into bowls and " \
			+ "setting them out in the sun. They crack, one after another."
	event.choices = _choices([
		_answer(
			&"bake_them", "Bake the bowls in the hot ashes",
			"{subject} buried the bowls in glowing ash overnight. In the morning they rang "
			+ "when they were tapped, and none of them leaked.",
			[_set_flag(&"bowls_in_ash"), _earn(&"fired_clay", "Fired Clay")],
		),
		_answer(
			&"keep_drying", "Bake them in a pit under the cook fire",
			"{subject} dug a pit under the cook fire, and the bowls that came out of it in the "
			+ "morning were the first that did not crack.",
			[_set_flag(&"bowls_in_pit"), _earn(&"fired_clay", "Fired Clay")],
		),
	])
	return event


## Woven Cloth, the farmers' route.
func _flax_in_the_field() -> EventDef:
	var event: EventDef = _settled_milestone(
		&"flax_in_the_field", "Something in the field", &"nature",
		VillagerState.TRAIT_NATURE_LOVING, SETTLED_DAY[&"woven_cloth"], &"woven_cloth"
	)
	event.requires.append(_cond(SimCondition.Kind.FLAG_SET, &"path_agriculture"))
	event.body = "Among the sown seeds, {subject} noticed a tall plant with pale blue flowers. " \
			+ "When the stems rot in the river, they peel into long, strong fibres."
	event.choices = _choices([
		_answer(
			&"twist_the_fibres", "Twist the fibres into thread",
			"{subject} twisted the fibres into thread, and the thread into a first rough strip "
			+ "of cloth. It was crooked, and everyone wanted a piece.",
			[_set_flag(&"flax_thread"), _earn(&"woven_cloth", "Woven Cloth")],
		),
		_answer(
			&"leave_it_standing", "Beat the fibres soft and weave them straight",
			"{subject} beat the fibres soft on a flat stone and wove them over and under, and "
			+ "the cloth that came out was coarse, and stood up by itself.",
			[_set_flag(&"flax_beaten"), _earn(&"woven_cloth", "Woven Cloth")],
		),
	])
	return event


## Woven Cloth, the herders' route.
func _wool_on_the_thorns() -> EventDef:
	var event: EventDef = _settled_milestone(
		&"wool_on_the_thorns", "Wool on the thorns", &"nature",
		VillagerState.TRAIT_NATURE_LOVING, SETTLED_DAY[&"woven_cloth"], &"woven_cloth"
	)
	event.requires.append(_cond(SimCondition.Kind.FLAG_SET, &"path_herding"))
	event.body = "Tufts of wool hang from every thorn bush along the herd's path. {subject} " \
			+ "has been gathering them in the hem of a tunic."
	event.choices = _choices([
		_answer(
			&"spin_the_wool", "Spin it into thread",
			"{subject} spun the wool on a stick weighted with a stone, and by the new moon "
			+ "there was cloth that kept the wind out.",
			[_set_flag(&"wool_spun"), _earn(&"woven_cloth", "Woven Cloth")],
		),
		_answer(
			&"stuff_the_bedding", "Comb it and press it into felt",
			"{subject} combed the wool and pressed it flat with wet hands, and the felt that "
			+ "dried was warm, and thick, and held its shape.",
			[_set_flag(&"wool_felted"), _earn(&"woven_cloth", "Woven Cloth")],
		),
	])
	return event


## Woven Cloth, the late route open to every group.
func _plaited_reeds() -> EventDef:
	var event: EventDef = _settled_milestone(
		&"plaited_reeds", "Mats of reed", &"character", VillagerState.TRAIT_SOCIAL,
		SETTLED_DAY[&"reeds"], &"woven_cloth"
	)
	event.body = "{subject} has been plaiting river reeds into mats, over and under, over and " \
			+ "under. The mat has begun to look like something softer than a mat."
	event.choices = _choices([
		_answer(
			&"show_the_others", "Show the others how it is done",
			"{subject} showed the others the over-and-under, and soon the whole camp was "
			+ "weaving, badly and happily.",
			[_set_flag(&"reed_teachers"), _earn(&"woven_cloth", "Woven Cloth")],
		),
		_answer(
			&"keep_it_a_mat", "Plait it finer, with a thread of grass through it",
			"{subject} plaited the reeds finer and finer, with a thread of dry grass through "
			+ "them, until the mat was something you could wear.",
			[_set_flag(&"fine_plaiting"), _earn(&"woven_cloth", "Woven Cloth")],
		),
	])
	return event


## Word from the Hills, first route. The green stone is copper ore; the flag is what the next age
## will read.
func _green_stone_found() -> EventDef:
	var event: EventDef = _settled_milestone(
		&"green_stone_found", "A green stone", &"exploration", VillagerState.TRAIT_CURIOUS,
		SETTLED_DAY[&"green_stone"], &"green_stone"
	)
	event.body = "{subject} brought back a stone from a stream in the hills, streaked bright " \
			+ "green. It sat in the cook fire all night, and in the morning there was a bead of " \
			+ "something red and gold in the ashes."
	event.choices = _choices([
		_answer(
			&"follow_the_stream", "Follow the stream to where it came from",
			"{subject} followed the stream up into the hills and found a cliff streaked green "
			+ "from top to bottom, and came back with a heavy bag.",
			[
				_eff(SimEffect.Kind.SET_FLAG, &"green_stone"),
				_earn(&"green_stone", "Word from the Hills"),
			],
		),
		_answer(
			&"keep_the_bead", "Show the bead to the elders, and ask where it is from",
			"{subject} showed the bead to the oldest in the camp, who turned it over for a long "
			+ "time and said they knew of a stream.",
			[_set_flag(&"bead_shown"), _eff(SimEffect.Kind.SCHEDULE_EVENT, &"green_stone_shown", 96)],
		),
	])
	return event


## Word from the Hills, second route: a traveller brings the same stone.
func _green_stone_traded() -> EventDef:
	var event: EventDef = _event(
		&"green_stone_traded", "A traveller with green beads", &"exploration"
	)
	event.body = "A traveller has come over the hills with a string of bright green stones. " \
			+ "They want grain, and will not say where the stones are from."
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", SETTLED),
		_cond(SimCondition.Kind.ERA_DAYS_AT_LEAST, &"", SETTLED_DAY[&"green_stone"]),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"first_harvest"),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"green_stone", 0, true),
	])
	event.chance_per_tick = 0.02
	event.cooldown_ticks = 72
	event.choices = _choices([
		_answer(
			&"trade_for_stones", "Trade food for a pouch of the stones",
			"The traveller left with a sack of grain, and the group had a pouch of green stones "
			+ "and a rumour of the hills they came from.",
			[
				_spend(&"food", 8), _eff(SimEffect.Kind.SET_FLAG, &"green_stone"),
				_earn(&"green_stone", "Word from the Hills"),
			],
			[_has(&"food", 8)],
		),
		_answer(
			&"send_them_on", "Send them on with bread, and ask them back with more",
			"The traveller was sent on with bread, and asked to come back by the same road with "
			+ "more of the stones, and a name for where they came from.",
			[
				_set_flag(&"traders_asked"),
				_eff(SimEffect.Kind.SCHEDULE_EVENT, &"green_stone_shown", 96),
			],
		),
	])
	return event


## A Village, first route: a roof to offer, and travellers who need one.
func _families_on_the_road() -> EventDef:
	var event: EventDef = _event(&"families_on_the_road", "Families on the road", &"exploration")
	event.body = "Two families have stopped at the edge of the fields. They have walked a " \
			+ "long way, and they look at the roofs the way hungry people look at bread."
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", SETTLED),
		_cond(SimCondition.Kind.ERA_DAYS_AT_LEAST, &"", SETTLED_DAY[&"a_village"]),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"first_roof"),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"a_village", 0, true),
	])
	event.chance_per_tick = 0.02
	event.cooldown_ticks = 72
	event.choices = _choices([
		_answer(
			&"make_room", "Make room for them",
			"The two families came in out of the road, and the camp became a village.",
			[
				_set_flag(&"families_taken_in"),
				_eff(SimEffect.Kind.ADD_VILLAGER, &"", 2),
				_earn(&"a_village", "A Village"),
			],
		),
		_answer(
			&"point_the_way", "Offer them the empty ground by the river",
			"The two families were shown the empty ground by the river, and by the next moon "
			+ "there was a roof there, and the camp had a neighbour that was also the camp.",
			[
				_set_flag(&"families_by_the_river"),
				_eff(SimEffect.Kind.ADD_VILLAGER, &"", 2),
				_earn(&"a_village", "A Village"),
			],
		),
	])
	return event


## A Village, second route: the harvest, shared.
func _the_long_table() -> EventDef:
	var event: EventDef = _settled_milestone(
		&"the_long_table", "The long table", &"character", VillagerState.TRAIT_SOCIAL,
		SETTLED_DAY[&"a_village"], &"a_village"
	)
	event.requires.append(_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"first_harvest"))
	event.body = "{subject} wants to put every board and bench in the camp end to end, and " \
			+ "invite everyone to eat at the same table. It will take a good deal of food."
	event.choices = _choices([
		_answer(
			&"lay_the_table", "Lay the long table for everyone",
			"The boards were laid end to end in the dusk. Nobody could say how many people "
			+ "sat down, but it was more than lived there.",
			[_spend(&"food", 10), _set_flag(&"long_table"), _earn(&"a_village", "A Village")],
			[_has(&"food", 10)],
		),
		_answer(
			&"eat_as_usual", "Ask every family to bring one dish to the old fire",
			"Every family brought one dish to the old fire, and nobody quite counted how many "
			+ "came to eat.",
			[
				_set_flag(&"dish_supper"),
				_eff(SimEffect.Kind.SCHEDULE_EVENT, &"village_gathers", 72),
			],
		),
	])
	return event


## Scheduled only: the slower road to Word from the Hills, once the elders have named the stream
## or the traveller has come back with more.
func _green_stone_shown() -> EventDef:
	var event: EventDef = _event(&"green_stone_shown", "Where the green comes from", &"exploration")
	event.requires = _conds([
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"green_stone", 0, true),
	])
	event.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"green_stone"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"In time the green stone was traced to a stream in the hills, and a party came back "
			+ "from it with a heavy bag and a good deal to say."
		),
		_earn(&"green_stone", "Word from the Hills"),
	])
	return event


## Scheduled only: the slower road to A Village, once every family has brought a dish.
func _village_gathers() -> EventDef:
	var event: EventDef = _event(&"village_gathers", "Supper at the old fire", &"settlement")
	event.requires = _conds([
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"a_village", 0, true),
	])
	event.effects = _effs([
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The dishes had been brought for one supper, and then another, and by the end of the "
			+ "month nobody called it anything but the village."
		),
		_earn(&"a_village", "A Village"),
	])
	return event


func _curious_explorer() -> EventDef:
	var event: EventDef = _event(&"curious_explorer", "A curious scout", &"exploration")
	event.body = "{subject} keeps climbing the lookout to stare at the ridge beyond the western forest."
	event.requires = _conds([
		_cond(SimCondition.Kind.HAS_BUILDING, &"lookout"),
		_cond(SimCondition.Kind.FLAG_SET, &"western_forest_explored", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", UNLOCK_DAY[&"seed_chain"]),
	])
	event.needs_subject = true
	event.subject_requires = _conds([
		_cond(SimCondition.Kind.SUBJECT_HAS_TRAIT, VillagerState.TRAIT_CURIOUS),
		_cond(SimCondition.Kind.SUBJECT_AT_HOME),
	])
	event.chance_per_tick = 0.06
	event.cooldown_ticks = 72
	event.choices = _scout_choices()
	return event


## The same restless villager for a group with no Lookout, a month later (NO_LOOKOUT_DELAY).
func _restless_explorer() -> EventDef:
	var event: EventDef = _curious_explorer()
	event.id = &"restless_explorer"
	event.body = "{subject} keeps wandering to the edge of the western forest to stare at the " \
			+ "ridge beyond it."
	event.requires = _conds([
		_cond(SimCondition.Kind.HAS_BUILDING, &"lookout", 0, true),
		_cond(SimCondition.Kind.FLAG_SET, &"western_forest_explored", 0, true),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", UNLOCK_DAY[&"seed_chain"] + NO_LOOKOUT_DELAY),
	])
	return event


func _scout_choices() -> Array[ChoiceDef]:
	var go: ChoiceDef = _choice(&"encourage", "Let them scout alone")
	go.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"scouted_alone"),
		_eff(SimEffect.Kind.SET_PROFESSION, &"scout"),
		_eff(SimEffect.Kind.SEND_AWAY, &"western_forest", 36),
		_eff(SimEffect.Kind.SCHEDULE_EVENT, &"explorer_returns", 36),
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "{subject} set off to scout the western forest."),
	])
	var together: ChoiceDef = _choice(&"walk_together", "Walk out there together")
	together.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"scouted_together"),
		_eff(SimEffect.Kind.SEND_AWAY, &"western_forest", 60),
		_eff(SimEffect.Kind.SCHEDULE_EVENT, &"explorer_returns", 60),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The group walked out to the western forest together, slowly, and {subject} led "
			+ "the way back."
		),
	])
	return _choices([go, together])


func _explorer_returns() -> EventDef:
	var event: EventDef = _event(&"explorer_returns", "A scout returns", &"exploration")
	event.body = "{subject} is back from the forest, carrying something unfamiliar."
	event.needs_subject = true
	event.effects = _effs([
		_eff(SimEffect.Kind.ADD_ITEM, &"strange_seed", 1),
		_eff(SimEffect.Kind.SET_FLAG, &"western_forest_explored"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} returned from the western forest carrying the seed of an unfamiliar plant."
		),
	])
	var seed_needed: Array[SimCondition] = [
		_cond(SimCondition.Kind.ITEM_AT_LEAST, &"strange_seed", 1)
	]
	var plant: ChoiceDef = _choice(&"plant_it", "Plant it in the sun at the cave mouth")
	plant.requires = _conds(seed_needed)
	plant.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"seed_in_sun"),
		_eff(SimEffect.Kind.PLANT, &"strange_seed"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} pressed the strange seed into the sunny soil by the cave mouth."
		),
	])
	var shade: ChoiceDef = 	_choice(&"plant_in_shade", "Plant it in the shade of the overhang")
	shade.requires = _conds(seed_needed)
	shade.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"seed_in_shade"),
		_eff(SimEffect.Kind.PLANT, &"strange_seed"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} pressed the strange seed into the cool soil under the overhang."
		),
	])
	event.choices = _choices([plant, shade])
	return event


func _seed_in_pouch() -> EventDef:
	var event: EventDef = _event(&"seed_in_pouch", "The seed in the pouch", &"exploration")
	event.body = "The strange seed in its hide pouch looks ready to be planted."
	event.requires = _conds([_cond(SimCondition.Kind.ITEM_AT_LEAST, &"strange_seed", 1)])
	event.chance_per_tick = 0.01
	event.cooldown_ticks = 96
	var plant: ChoiceDef = _choice(&"plant_it", "Plant it in the sun at the cave mouth")
	plant.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"seed_in_sun"),
		_eff(SimEffect.Kind.PLANT, &"strange_seed"),
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "The strange seed was planted in the sun at last."),
	])
	var shade: ChoiceDef = 	_choice(&"plant_in_shade", "Plant it in the shade of the overhang")
	shade.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"seed_in_shade"),
		_eff(SimEffect.Kind.PLANT, &"strange_seed"),
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "The strange seed was planted in the shade at last."),
	])
	event.choices = _choices([plant, shade])
	return event


## The turn from the Cave Age to the Settled Age. Fired by the era's hidden gate (not rolled), so
## the player is never asked *whether* to settle, only how.
func _seeds_of_a_new_life() -> EventDef:
	var event: EventDef = _event(&"seeds_of_a_new_life", "Seeds of a new life", &"settlement")
	event.body = "The plant by the cave has gone to seed: enough to sow a whole field. The " \
			+ "herds still move through the valley, and the group has learned enough to stay."
	var settle: ChoiceDef = _choice(&"settle_field", "Sow the seeds and settle by the field")
	settle.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"path_agriculture"),
		_eff(SimEffect.Kind.ADVANCE_ERA, &"settled"),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"the_first_field", 0, "The First Field"),
	])
	var herds: ChoiceDef = _choice(&"settle_herds", "Settle where the herds winter, and sow a small plot")
	herds.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"path_herding"),
		_eff(SimEffect.Kind.ADVANCE_ERA, &"settled"),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"a_place_to_stay", 0, "A Place to Stay"),
	])
	event.choices = _choices([settle, herds])
	return event


func _rare_butterfly() -> EventDef:
	var event: EventDef = _event(&"rare_butterfly", "A rare visitor", &"nature")
	event.requires = _conds([
		_cond(SimCondition.Kind.FLAG_SET, &"strange_flower_bloomed"),
		_cond(SimCondition.Kind.FLAG_SET, &"butterfly_seen", 0, true),
	])
	event.chance_per_tick = 0.02
	event.once = true
	event.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"butterfly_seen"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"A butterfly nobody had seen before landed on the strange flower."
		),
		_eff(SimEffect.Kind.ACHIEVEMENT, &"rare_visitor", 0, "A Rare Visitor"),
	])
	return event


func _heavy_rain() -> EventDef:
	var event: EventDef = _event(&"heavy_rain", "Heavy rain", &"nature")
	event.requires = _conds([_season(Season.SPRING), _clear_sky()])
	event.chance_per_tick = 0.004
	event.cooldown_ticks = 120
	event.effects = _effs([
		_eff(SimEffect.Kind.SET_WEATHER, &"rain"),
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "It rained heavily and everyone crowded in the cave."),
	])
	return event


func _cold_night() -> EventDef:
	var event: EventDef = _event(&"cold_night", "A cold night", &"nature")
	event.requires = _conds([
		_cond(SimCondition.Kind.FLAG_SET, &"fire_found"),
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", SETTLED, true),
	])
	event.chance_per_tick = 0.005
	event.cooldown_ticks = 120
	event.requires.append(_season(Season.WINTER))
	event.effects = _effs([
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "A cold night. Everyone drew close around the fire."),
	])
	return event


## Spells of weather: how long each lasts and what it slows while it does. Nobody is hurt; the
## group just brings in less (docs/gameplay.md P14).
func _weathers() -> Array[WeatherDef]:
	var rain: WeatherDef = _weather(&"rain", "Rain", 2.0, 4.0)
	var snow: WeatherDef = _weather(&"snow", "Snow", 2.0, 4.0)
	var storm: WeatherDef = _weather(&"storm", "Storm", 1.0, 2.0, 0.85, 0.8)
	var drought: WeatherDef = _weather(&"drought", "Drought", 8.0, 12.0, 0.65)
	var flood: WeatherDef = _weather(&"flood", "Flood", 3.0, 5.0, 0.7)
	var tornado: WeatherDef = _weather(&"tornado", "Tornado", 1.0, 1.0, 0.6)
	tornado.then = &"debris"
	var debris: WeatherDef = _weather(&"debris", "Wreckage", 4.0, 6.0, 0.6)
	return [rain, snow, storm, drought, flood, tornado, debris]


func _weather(
	weather_id: StringName, display_name: String, min_days: float, max_days: float,
	food: float = 1.0, wood: float = 1.0
) -> WeatherDef:
	var weather: WeatherDef = WeatherDef.new()
	weather.id = weather_id
	weather.display_name = display_name
	weather.min_days = min_days
	weather.max_days = max_days
	weather.food_multiplier = food
	weather.wood_multiplier = wood
	return weather


func _season(season: int, negate: bool = false) -> SimCondition:
	return _cond(SimCondition.Kind.SEASON_IS, &"", season, negate)


func _clear_sky() -> SimCondition:
	return _cond(SimCondition.Kind.WEATHER_IS, &"")


func _weather_is(weather_id: StringName) -> SimCondition:
	return _cond(SimCondition.Kind.WEATHER_IS, weather_id)


## A completed, undamaged building that weather of that kind can reach (&"": any).
func _reachable(tag: StringName, negate: bool = false) -> SimCondition:
	return _cond(SimCondition.Kind.HAS_BUILDING_TAG, tag, 0, negate)


## One of the quiet moments that belongs to the sea being out.
func _at_low_tide(event: EventDef) -> EventDef:
	event.requires.append(_cond(SimCondition.Kind.TIDE_LOW))
	return event


## One of the quiet moments that belongs to a season.
func _seasonal(event_id: StringName, season: int, line: String) -> EventDef:
	var event: EventDef = _ambient(event_id, line)
	event.requires.append(_season(season))
	return event


## Chances are per tick while eligible (24 ticks a day, 480 in a season). Every kind is bound to a
## season or to rain, and cooldowns are half a year, so a kind of weather fork comes about once a
## year at most and often not at all: roughly two forks a year across all of them. The ambient
## spells (rain, snow) are more frequent. Tune with tools/sim_timeline.gd.
const FLOOD_CHANCE: float = 0.012
const STORM_CHANCE: float = 0.0025
const DROUGHT_CHANCE: float = 0.002
const TORNADO_CHANCE: float = 0.0008
const YEAR_TICKS: int = 1920


## Seasons and weather (docs/gameplay.md P14). A fork is damage plus two ways to go on: set the
## damaged building right now with wood, or go another way and let the villagers mend it by hand
## in a few days. Without a building to reach, the weather is a quiet spell that only slows the
## foragers. An earlier answer that guards against it (a bank, a ledge, a well) turns a damaging
## spell into a calm journal line.
func _weather_events() -> Array[EventDef]:
	var events: Array[EventDef] = [
		_autumn_rain(), _snowfall(),
		_river_over_its_banks(), _river_over_the_reeds(), _ledge_stays_dry(), _bank_holds(),
		_thunder_storm(), _storm_passes(),
		_dry_summer(), _dry_summer_quiet(), _well_keeps_green(),
		_tornado(),
	]
	events.append_array(_seasonal_lines())
	return events


func _autumn_rain() -> EventDef:
	var event: EventDef = _event(&"autumn_rain", "Autumn rain", &"nature")
	event.requires = _conds([_season(Season.AUTUMN), _clear_sky()])
	event.chance_per_tick = 0.004
	event.cooldown_ticks = 120
	event.effects = _effs([
		_eff(SimEffect.Kind.SET_WEATHER, &"rain"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"Autumn rain came in off the hills, and the whole camp went quiet under it."
		),
	])
	return event


func _snowfall() -> EventDef:
	var event: EventDef = _event(&"snowfall", "Snowfall", &"nature")
	event.requires = _conds([_season(Season.WINTER), _clear_sky()])
	event.chance_per_tick = 0.004
	event.cooldown_ticks = 120
	event.effects = _effs([
		_eff(SimEffect.Kind.SET_WEATHER, &"snow"),
		_eff(SimEffect.Kind.JOURNAL, &"", 0, "Snow came down all day, soft and without wind."),
	])
	return event


## The fork shared by every damaging spell. `when` is what lets it happen; its effects start the
## weather and break one building that carries `tag`.
func _weather_fork(
	event_id: StringName, title: String, body: String, when: Array[SimCondition],
	weather: StringName, tag: StringName, damage_line: String, chance: float
) -> EventDef:
	var event: EventDef = _event(event_id, title, &"nature")
	event.body = body
	event.requires = _conds(when)
	event.requires.append(_reachable(tag))
	event.chance_per_tick = chance
	event.cooldown_ticks = YEAR_TICKS / 2
	event.effects = _effs([
		_eff(SimEffect.Kind.SET_WEATHER, weather),
		_eff(SimEffect.Kind.DAMAGE_BUILDING, tag, 0, damage_line),
	])
	return event


## An answer that sets the damage right now, for wood.
func _mend_now(choice_id: StringName, label: String, line: String, wood: int) -> ChoiceDef:
	return _answer(
		choice_id, label, line,
		[_spend(&"wood", wood), _eff(SimEffect.Kind.REPAIR_BUILDING), _set_flag(choice_id)],
		[_has(&"wood", wood)],
	)


## An answer that lets the villagers mend it in their own time, and brings in a little meanwhile.
func _mend_later(
	choice_id: StringName, label: String, line: String, resource: StringName, amount: int
) -> ChoiceDef:
	return _answer(
		choice_id, label, line,
		[_eff(SimEffect.Kind.ADD_RESOURCE, resource, amount), _set_flag(choice_id)],
	)


func _river_over_its_banks() -> EventDef:
	var event: EventDef = _weather_fork(
		&"river_over_its_banks", "The river is over its banks",
		"The rain has not let up, and the river has climbed out of its bed and into the low "
		+ "ground. Whatever stands by the water is standing in it.",
		[
			_weather_is(&"rain"),
			_cond(SimCondition.Kind.FLAG_SET, &"stores_on_ledge", 0, true),
			_cond(SimCondition.Kind.FLAG_SET, &"river_bank", 0, true),
		],
		&"flood", &"river", "The flood reached the {building} and left it battered.", FLOOD_CHANCE,
	)
	event.choices = _choices([
		_mend_now(
			&"raise_it_again", "Cut wood and set it right now",
			"Wood was cut and poles reset, and the damage was put right before the water was "
			+ "fully down.",
			8,
		),
		_mend_later(
			&"wait_for_the_water", "Wait for the water to drop",
			"They waited for the river to fall and gathered the fish it left in the grass. The "
			+ "damage would be mended by hand in time.",
			&"food", 3,
		),
	])
	return event


func _river_over_the_reeds() -> EventDef:
	var event: EventDef = _event(&"river_over_the_reeds", "The river spreads", &"nature")
	event.requires = _conds([
		_weather_is(&"rain"), _reachable(&"river", true),
		_cond(SimCondition.Kind.FLAG_SET, &"stores_on_ledge", 0, true),
		_cond(SimCondition.Kind.FLAG_SET, &"river_bank", 0, true),
	])
	event.chance_per_tick = FLOOD_CHANCE
	event.cooldown_ticks = YEAR_TICKS / 2
	event.effects = _effs([
		_eff(SimEffect.Kind.SET_WEATHER, &"flood"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The river came over its banks into the reeds, and the foragers went further up "
			+ "the valley to find dry ground."
		),
	])
	return event


func _ledge_stays_dry() -> EventDef:
	var event: EventDef = _remembered(
		&"ledge_stays_dry", &"stores_on_ledge",
		"The river came up the bank again in the rain, and the stores on the ledge never felt it."
	)
	event.requires.append(_weather_is(&"rain"))
	event.chance_per_tick = FLOOD_CHANCE
	event.cooldown_ticks = YEAR_TICKS / 2
	return event


func _bank_holds() -> EventDef:
	var event: EventDef = _remembered(
		&"bank_holds", &"river_bank",
		"The river climbed to the foot of the bank in the rain and went no further."
	)
	event.requires.append(_weather_is(&"rain"))
	event.chance_per_tick = FLOOD_CHANCE
	event.cooldown_ticks = YEAR_TICKS / 2
	return event


func _thunder_storm() -> EventDef:
	var event: EventDef = _weather_fork(
		&"thunder_storm", "A storm breaks",
		"The sky went the colour of a bruise, the wind got up, and then it all came down at "
		+ "once. Something has given way.",
		[_season(Season.SUMMER), _clear_sky()],
		&"storm", &"exposed", "A gust got under the {building} and tore it half apart.",
		STORM_CHANCE,
	)
	event.choices = _choices([
		_mend_now(
			&"cut_new_poles", "Cut new poles and mend it now",
			"New poles went in before the next squall, and the damage was set right.", 6,
		),
		_mend_later(
			&"gather_the_fallen_wood", "Wait it out, then gather what fell",
			"Everyone sheltered until it passed, and the fallen branches made a good pile. The "
			+ "damage would be mended by hand in time.",
			&"wood", 3,
		),
	])
	return event


func _storm_passes() -> EventDef:
	var event: EventDef = _event(&"storm_passes", "A storm passes", &"nature")
	event.requires = _conds([_season(Season.SUMMER), _clear_sky(), _reachable(&"exposed", true)])
	event.chance_per_tick = STORM_CHANCE
	event.cooldown_ticks = YEAR_TICKS / 2
	event.effects = _effs([
		_eff(SimEffect.Kind.SET_WEATHER, &"storm"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"A storm rolled over the valley and went away again. Nobody went far until it had."
		),
	])
	return event


func _dry_summer() -> EventDef:
	var event: EventDef = _weather_fork(
		&"dry_summer", "No rain for weeks",
		"The river has shrunk to a trickle and the ground has begun to crack. Everything that "
		+ "needs water is going without.",
		[
			_season(Season.SUMMER), _clear_sky(),
			_cond(SimCondition.Kind.FLAG_SET, &"well_dug", 0, true),
		],
		&"drought", &"dry", "The ground cracked in the heat, and the {building} split and curled.",
		DROUGHT_CHANCE,
	)
	event.choices = _choices([
		_mend_now(
			&"carry_water", "Carry water up from the river",
			"Water came up from the river in yokes and jars all week, and the damage was put right.",
			6,
		),
		_mend_later(
			&"follow_the_fish", "Follow the river down to the fish pools",
			"The baskets went down to the pools where the fish were trapped, and came back full. "
			+ "The damage would be mended by hand in time.",
			&"food", 4,
		),
	])
	return event


func _dry_summer_quiet() -> EventDef:
	var event: EventDef = _event(&"dry_summer_quiet", "A dry summer", &"nature")
	event.requires = _conds([
		_season(Season.SUMMER), _clear_sky(), _reachable(&"dry", true),
		_cond(SimCondition.Kind.FLAG_SET, &"well_dug", 0, true),
	])
	event.chance_per_tick = DROUGHT_CHANCE
	event.cooldown_ticks = YEAR_TICKS / 2
	event.effects = _effs([
		_eff(SimEffect.Kind.SET_WEATHER, &"drought"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"The rain held off for weeks and the river sank to its stones. Foraging took "
			+ "everyone further afield."
		),
	])
	return event


func _well_keeps_green() -> EventDef:
	var event: EventDef = _remembered(
		&"well_keeps_green", &"well_dug",
		"No rain fell for weeks, but the well never failed and the ground around it stayed green."
	)
	event.requires.append(_season(Season.SUMMER))
	event.chance_per_tick = DROUGHT_CHANCE
	event.cooldown_ticks = YEAR_TICKS / 2
	return event


## The rarest and the roughest: it can break any building, and the wreckage slows the foragers
## for days. Settled villages only, since the Cave Age has so little to break.
func _tornado() -> EventDef:
	var event: EventDef = _weather_fork(
		&"tornado", "A wind from the ridge",
		"A black funnel of wind came down off the ridge, tore across the village and was gone. "
		+ "It left a trail of wreckage and scattered stores.",
		[
			_cond(SimCondition.Kind.ERA_AT_LEAST, &"", SETTLED),
			_season(Season.AUTUMN), _clear_sky(),
		],
		&"tornado", &"", "The wind took hold of the {building} and left it in pieces.",
		TORNADO_CHANCE,
	)
	event.cooldown_ticks = YEAR_TICKS
	event.choices = _choices([
		_mend_now(
			&"rebuild_at_once", "Rebuild it at once",
			"Every hand turned out to rebuild, and the damage was put right in a day.", 10,
		),
		_mend_later(
			&"salvage_and_mend", "Salvage the wreckage and mend it by hand",
			"Timber and thatch were sorted out of the wreckage, and a good deal was kept. The "
			+ "damage would be mended by hand in time.",
			&"wood", 4,
		),
	])
	return event


## Quiet moments that mark the turn of the seasons.
func _seasonal_lines() -> Array[EventDef]:
	return [
		_seasonal(
			&"spring_green", Season.SPRING,
			"Green shoots were coming up through last year's dead grass."
		),
		_seasonal(
			&"spring_thaw", Season.SPRING,
			"The stream ran loud with meltwater, and the children were forbidden from it."
		),
		_seasonal(
			&"summer_haze", Season.SUMMER,
			"Heat shimmered over the grass by midday, and everyone found a shady place to be useful in."
		),
		_seasonal(
			&"summer_long_light", Season.SUMMER,
			"The light lasted so long tonight that nobody wanted to go in."
		),
		_seasonal(
			&"autumn_leaves", Season.AUTUMN,
			"The leaves went red and gold overnight, and the whole valley looked lit from inside."
		),
		_seasonal(
			&"autumn_nights", Season.AUTUMN,
			"The nights are drawing in, and the fire was fed earlier today."
		),
		_seasonal(
			&"winter_breath", Season.WINTER,
			"Breath hung in the air this morning, and the ground rang underfoot."
		),
		_seasonal(
			&"winter_quiet", Season.WINTER,
			"Not a bird sang all day. The valley was very still under its frost."
		),
	]


## The decisions that fill the Cave Age between its milestones. Each is a small, one-time question
## with two harmless answers: nothing fails, and the answer shows up in the journal and sometimes in
## a later line (a flag). Costs are shown on the choice and only gate it, never punish.
func _story_decisions() -> Array[EventDef]:
	return [
		_wolf_at_the_edge(), _hungry_mornings(), _flint_edge(), _first_hard_frost(),
		_strange_prints(), _prints_end(), _too_much_food(), _second_hearth(), _mammoth_neighbour(),
		_work_song(), _crowded_wall(), _living_story(), _smoke_on_the_ridge(), _ridge_empty(),
		_newcomers_shelter(), _rising_river(), _wild_grain(), _hurt_deer(), _trader(),
		_star_watching(), _smoke_in_the_cave(), _tools_pile(), _cold_floors(), _lost_flint(),
		_night_noises(), _the_ford(), _bright_feather(), _bats_in_the_back(), _bee_tree(),
		_fish_run(), _hollow_log(), _first_snow(), _echo_in_the_cave(), _sky_stone(), _warm_pool(),
		_low_tide(&"stepping_stones", &"low_tide_stones"),
		_low_tide(&"log_bridge", &"low_tide_log"),
	]


func _wolf_at_the_edge() -> EventDef:
	var event: EventDef = _story(
		&"wolf_at_the_edge", "A wolf at the edge", &"nature", STORY_DAY[&"wolf"],
		"A thin grey wolf has begun appearing at dusk, sitting just outside the firelight. "
		+ "It watches the camp and never comes closer."
	)
	event.choices = _choices([
		_answer(
			&"feed_the_wolf", "Leave scraps at the edge of the light",
			"A bone was left at the edge of the light. By morning it was gone.",
			[_spend(&"food", 2), _eff(SimEffect.Kind.SET_FLAG, &"wolf_fed")],
			[_has(&"food", 2)],
		),
		_answer(
			&"drive_it_off", "Drive it off with a torch",
			"The group waved torches until the wolf slipped back into the dark.",
			[_eff(SimEffect.Kind.SET_FLAG, &"wolf_driven_off")],
		),
	])
	return event


## Scarcity told as a question (gameplay.md P2): it only appears when the food pile is low.
func _hungry_mornings() -> EventDef:
	var event: EventDef = _story(
		&"hungry_mornings", "Hungry mornings", &"settlement", STORY_DAY[&"hungry"],
		"The food pile is low and the mornings have gone quiet. Nobody has complained, but "
		+ "everyone has noticed.",
		0.03
	)
	event.once = false
	event.cooldown_ticks = 240
	event.requires.append(_cond(SimCondition.Kind.RESOURCE_AT_LEAST, &"food", 4, true))
	event.choices = _choices([
		_answer(
			&"forage_together", "Spend the day foraging together",
			"The whole group worked the river bank and came back with full baskets.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 6)],
		),
		_answer(
			&"set_snares", "Set snares in the long grass",
			"Snares went into the long grass, and by evening there was a rabbit.",
			[
				_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 4),
				_eff(SimEffect.Kind.SET_FLAG, &"snares"),
			],
		),
	])
	return event


func _flint_edge() -> EventDef:
	var event: EventDef = _story_about(
		&"flint_edge", "What the edge is for", &"character", STORY_DAY[&"flint_edge"],
		"{subject} keeps turning a sharp stone over in their hands. It could be an axe for "
		+ "the wood, or a scraper for the hides.",
		VillagerState.TRAIT_INDUSTRIOUS
	)
	event.requires.append(_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"stone_tools"))
	event.choices = _choices([
		_answer(
			&"make_axes", "Shape hand axes for the wood",
			"{subject} knapped a heavy wedge and felled a small tree before noon.",
			[
				_eff(SimEffect.Kind.ADD_RESOURCE, &"wood", 6),
				_eff(SimEffect.Kind.SET_FLAG, &"hand_axes"),
			],
		),
		_answer(
			&"make_scrapers", "Shape scrapers for the hides",
			"{subject} scraped a hide clean, and by evening it was soft enough to wear.",
			[_eff(SimEffect.Kind.SET_FLAG, &"hide_scrapers")],
		),
	])
	return event


func _first_hard_frost() -> EventDef:
	var event: EventDef = _story(
		&"first_hard_frost", "The first hard frost", &"nature", STORY_DAY[&"frost"],
		"The first hard frost has come. The river is edged with ice, and the wood pile is "
		+ "shrinking faster than it grows."
	)
	event.requires.append(_season(Season.WINTER))
	event.choices = _choices([
		_answer(
			&"keep_fire_high", "Keep the fire high all night",
			"The fire burned high until dawn, and nobody woke shivering.",
			[_spend(&"wood", 8), _eff(SimEffect.Kind.SET_FLAG, &"warm_winter")],
			[_has(&"wood", 8)],
		),
		_answer(
			&"huddle_close", "Ration the wood and huddle close",
			"They rationed the wood and slept in a heap, grumbling and warm enough.",
			[_eff(SimEffect.Kind.SET_FLAG, &"huddled")],
		),
	])
	return event


func _strange_prints() -> EventDef:
	var event: EventDef = _story_about(
		&"strange_prints", "Strange prints", &"exploration", STORY_DAY[&"prints"],
		"{subject} found a line of strange prints at the edge of the western forest, and "
		+ "wants to follow them.",
		VillagerState.TRAIT_CURIOUS
	)
	event.subject_requires.append(
		_cond(SimCondition.Kind.SUBJECT_HAS_TRAIT, VillagerState.TRAIT_CURIOUS)
	)
	event.choices = _choices([
		_answer(
			&"follow_the_prints", "Let them follow the prints",
			"{subject} set off into the western forest after the prints.",
			[
				_eff(SimEffect.Kind.SEND_AWAY, &"western_forest", 18),
				_eff(SimEffect.Kind.SCHEDULE_EVENT, &"prints_end", 18),
			],
		),
		_answer(
			&"read_the_prints", "Wait for daylight and read the prints together",
			"The group pressed ash over the prints at dawn and read them together: a bear, "
			+ "and an old one.",
			[_set_flag(&"prints_read")],
		),
	])
	return event


## Scheduled only: where the prints led.
func _prints_end() -> EventDef:
	var event: EventDef = _event(&"prints_end", "The prints end", &"exploration")
	event.needs_subject = true
	event.effects = _effs([
		_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 5),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} came home at dusk. The prints were a bear's, days old, but there were "
			+ "pine nuts beneath the tree where it had sat."
		),
	])
	return event


## A food sink for when the pile gets big: a choice about plenty instead of a number to watch.
func _too_much_food() -> EventDef:
	var event: EventDef = _story(
		&"too_much_food", "More than enough", &"settlement", STORY_DAY[&"feast"],
		"There is more food in the cave than the group can eat before it turns.", 0.03
	)
	event.once = true
	event.requires.append(_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"reliable_food"))
	event.requires.append(_cond(SimCondition.Kind.RESOURCE_AT_LEAST, &"food", 16))
	event.choices = _choices([
		_answer(
			&"hold_a_feast", "Hold a feast by the fire",
			"The fire was loud that night. Everyone ate until they laughed.",
			[_spend(&"food", 12), _set_flag(&"feast_held")],
			[_has(&"food", 12)],
		),
		_answer(
			&"dry_the_rest", "Dry the rest for lean days",
			"The extra was split thin and hung to dry along the cave wall.",
			[_set_flag(&"food_dried")],
		),
	])
	return event


func _second_hearth() -> EventDef:
	var event: EventDef = _story_about(
		&"second_hearth", "The warm spot", &"character", STORY_DAY[&"hearth"],
		"Two of the group both want the warm place by the fire, and {subject} has taken to "
		+ "sitting at the edge of the light, alone.",
		VillagerState.TRAIT_SOCIAL
	)
	event.choices = _choices([
		_answer(
			&"build_second_hearth", "Lay a second small fire",
			"A second ring of stones was laid, and the evenings got louder.",
			[_spend(&"wood", 6), _eff(SimEffect.Kind.SET_FLAG, &"second_hearth")],
			[_has(&"wood", 6)],
		),
		_answer(
			&"take_turns", "Take turns by the fire",
			"They agreed to take turns, mostly.",
			[_set_flag(&"fire_turns")],
		),
	])
	return event


func _work_song() -> EventDef:
	var event: EventDef = _story_about(
		&"work_song", "A rhythm to work to", &"character", STORY_DAY[&"song"],
		"{subject} has made up a rhythm to chop to, and keeps humming it. Others have begun "
		+ "to tap along.",
		VillagerState.TRAIT_SOCIAL
	)
	event.requires.append(_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"shared_stories"))
	event.choices = _choices([
		_answer(
			&"join_in", "Let everyone join in",
			"By evening the whole camp worked to {subject}'s rhythm, and nobody could stop "
			+ "humming it.",
			[_eff(SimEffect.Kind.SET_FLAG, &"work_song")],
		),
		_answer(
			&"keep_it_quiet", "Ask for quiet while they work",
			"{subject} kept the rhythm in their head, and tapped it on their knee.",
			[_set_flag(&"work_quiet")],
		),
	])
	return event


func _crowded_wall() -> EventDef:
	var event: EventDef = _story_about(
		&"crowded_wall", "The crowded wall", &"character", STORY_DAY[&"wall"],
		"The red hands on the cave wall are crowded now. {subject} wants to add something "
		+ "more than a hand.",
		VillagerState.TRAIT_CURIOUS
	)
	event.requires.append(_cond(SimCondition.Kind.FLAG_SET, &"cave_art"))
	event.choices = _choices([
		_answer(
			&"paint_the_herd", "Paint the herd and the hunters",
			"A line of deer ran across the cave wall that night, with small figures behind them.",
			[_eff(SimEffect.Kind.SET_FLAG, &"art_herd")],
		),
		_answer(
			&"paint_the_sky", "Paint the sun and the moon",
			"A pale moon and a ring of sun now hang over the hands on the cave wall.",
			[_eff(SimEffect.Kind.SET_FLAG, &"art_sky")],
		),
	])
	return event


func _mammoth_neighbour() -> EventDef:
	var event: EventDef = _story_about(
		&"mammoth_neighbour", "The neighbour", &"nature", STORY_DAY[&"mammoth"],
		"A woolly mammoth has been grazing at the edge of camp for days, ignoring everyone. "
		+ "{subject} has started talking to it.",
		VillagerState.TRAIT_NATURE_LOVING
	)
	event.choices = _choices([
		_answer(
			&"offer_greens", "Offer it a bundle of greens",
			"{subject} left greens at the edge of the grass. The mammoth considered them for "
			+ "most of the afternoon, and ate them.",
			[_spend(&"food", 3), _eff(SimEffect.Kind.SET_FLAG, &"mammoth_fed")],
			[_has(&"food", 3)],
		),
		_answer(
			&"keep_distance", "Keep a respectful distance",
			"Everyone kept a careful distance, and the mammoth kept its own.",
			[_set_flag(&"mammoth_distant")],
		),
	])
	return event


## Shared Stories told rather than painted: the crowded wall's moment, for the other route.
func _living_story() -> EventDef:
	var event: EventDef = _story(
		&"living_story", "The long story", &"character", STORY_DAY[&"wall"],
		"The story told by the fire has grown long. Everyone has added a piece, and they no "
		+ "longer agree on how it goes."
	)
	event.requires.append(_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"shared_stories"))
	event.requires.append(_cond(SimCondition.Kind.FLAG_SET, &"cave_art", 0, true))
	event.choices = _choices([
		_answer(
			&"one_telling", "Agree on one way to tell it",
			"They argued until it had one shape, and from then on it was told the same way "
			+ "every night.",
			[_eff(SimEffect.Kind.SET_FLAG, &"fixed_tale")],
		),
		_answer(
			&"let_it_change", "Let it change with every telling",
			"The story grew a new piece every night, and someone swore it had always had a "
			+ "giant bird in it.",
			[_eff(SimEffect.Kind.SET_FLAG, &"living_tale")],
		),
	])
	return event


## Foreshadows the strangers (A Bigger Group) without being part of it.
func _smoke_on_the_ridge() -> EventDef:
	var event: EventDef = _story_about(
		&"smoke_on_the_ridge", "Smoke on the ridge", &"exploration", STORY_DAY[&"ridge_smoke"],
		"A thin line of smoke has been rising from the far ridge, where nobody has lived.",
		VillagerState.TRAIT_CURIOUS
	)
	event.requires.append(_cond(SimCondition.Kind.HAS_BUILDING, &"lookout"))
	event.requires.append(_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"bigger_group", 0, true))
	event.choices = _choices([
		_answer(
			&"climb_up", "Send them up to look",
			"{subject} set off up the ridge to find out who was making the smoke.",
			[
				_eff(SimEffect.Kind.SEND_AWAY, &"western_ridge", 14),
				_eff(SimEffect.Kind.SCHEDULE_EVENT, &"ridge_empty", 14),
			],
		),
		_answer(
			&"keep_watching", "Keep watching from the lookout",
			"The smoke came and went. Someone was always at the lookout that week.",
			[_set_flag(&"ridge_watched")],
		),
	])
	return event


## Scheduled only: what was found up on the ridge.
func _ridge_empty() -> EventDef:
	var event: EventDef = _event(&"ridge_empty", "The cold fire", &"exploration")
	event.needs_subject = true
	event.effects = _effs([
		_eff(SimEffect.Kind.SET_FLAG, &"ridge_footprints"),
		_eff(
			SimEffect.Kind.JOURNAL, &"", 0,
			"{subject} found a cold ring of stones and many footprints on the ridge, and came "
			+ "home thoughtful."
		),
	])
	return event


func _newcomers_shelter() -> EventDef:
	var event: EventDef = _story(
		&"newcomers_shelter", "Room for the newcomers", &"settlement", STORY_DAY[&"shelter"],
		"The two newcomers have been sleeping in the cave mouth, as close to the fire as they dare."
	)
	event.requires.append(_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"bigger_group"))
	event.choices = _choices([
		_answer(
			&"build_a_shelter", "Make them a shelter of hides and poles",
			"A shelter of hides and poles went up beside the cave, and the newcomers moved in.",
			[_spend(&"wood", 8), _eff(SimEffect.Kind.SET_FLAG, &"newcomer_shelter")],
			[_has(&"wood", 8)],
		),
		_answer(
			&"share_the_cave", "Make room for them in the cave",
			"The group shuffled along the wall and made room.",
			[_set_flag(&"shared_cave")],
		),
	])
	return event


func _rising_river() -> EventDef:
	var event: EventDef = _story(
		&"rising_river", "The river is rising", &"nature", STORY_DAY[&"river"],
		"Snowmelt has the river high, and it is creeping up the bank towards the cave mouth."
	)
	event.requires.append(_season(Season.SPRING))
	event.choices = _choices([
		_answer(
			&"move_up", "Carry the stores up to the ledge",
			"Everything went up to the ledge, and the river reached the old fire pit and "
			+ "no further.",
			[_spend(&"wood", 6), _set_flag(&"stores_on_ledge")],
			[_has(&"wood", 6)],
		),
		_answer(
			&"trust_the_bank", "Trust the bank",
			"The river rose to the edge of the camp, thought about it, and went back.",
			[_set_flag(&"trusted_bank")],
		),
	])
	return event


func _wild_grain() -> EventDef:
	var event: EventDef = _story(
		&"wild_grain", "Heavy grass", &"nature", STORY_DAY[&"grain"],
		"In the western meadow the wild grass is heavy with seed."
	)
	event.choices = _choices([
		_answer(
			&"gather_it_all", "Gather every seed head",
			"The group stripped the meadow, and the cave smelled of toasted grain for days.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 10)],
		),
		_answer(
			&"leave_some", "Gather half, and leave the rest to scatter",
			"They gathered half and shook the rest loose over the ground for next year.",
			[
				_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 5),
				_eff(SimEffect.Kind.SET_FLAG, &"left_seed"),
			],
		),
	])
	return event


func _hurt_deer() -> EventDef:
	var event: EventDef = _story(
		&"hurt_deer", "A limping deer", &"nature", STORY_DAY[&"deer"],
		"A young deer with a hurt leg has been limping near the camp, always at the edge of sight."
	)
	event.choices = _choices([
		_answer(
			&"tend_the_deer", "Tend its leg",
			"The deer let someone near. The leg was bound with reeds and moss, and by the new "
			+ "moon it was gone.",
			[_spend(&"food", 3), _eff(SimEffect.Kind.SET_FLAG, &"deer_tended")],
			[_has(&"food", 3)],
		),
		_answer(
			&"leave_it_be", "Let nature take its course",
			"The deer limped on out of sight, and nobody mentioned it.",
			[_set_flag(&"deer_left")],
		),
	])
	return event


func _star_watching() -> EventDef:
	var event: EventDef = _story_about(
		&"star_watching", "Counting stars", &"character", STORY_DAY[&"stars"],
		"{subject} has taken to lying awake outside, counting the stars, and losing count.",
		VillagerState.TRAIT_CURIOUS
	)
	event.choices = _choices([
		_answer(
			&"name_the_shapes", "Stay up together and name the shapes",
			"They lay on the cold ground and named what they saw: the Hunter, the River, the "
			+ "Long Road.",
			[_eff(SimEffect.Kind.SET_FLAG, &"star_names")],
		),
		_answer(
			&"keep_it_theirs", "Let them keep the sky to themselves",
			"{subject} kept the stars private, and seemed happier for it.",
			[_set_flag(&"stars_private")],
		),
	])
	return event


func _trader() -> EventDef:
	var event: EventDef = _story(
		&"trader", "A traveller with dark stone", &"exploration", STORY_DAY[&"trader"],
		"A traveller from beyond the ridge has come to the edge of the camp with a bag of dark, "
		+ "glassy stone, and a hungry look."
	)
	event.requires.append(_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"bigger_group"))
	event.choices = _choices([
		_answer(
			&"trade_food", "Trade food for the stone",
			"The dark stone took an edge sharper than flint, and the traveller left full.",
			[_spend(&"food", 8), _eff(SimEffect.Kind.SET_FLAG, &"glassy_stone")],
			[_has(&"food", 8)],
		),
		_answer(
			&"share_a_meal", "Share a meal and send them on",
			"The traveller ate by the fire, said a few words nobody understood, and went on.",
			[_set_flag(&"meal_shared")],
		),
	])
	return event


func _tools_pile() -> EventDef:
	var event: EventDef = _story_about(
		&"tools_pile", "The pile by the cave", &"character", STORY_DAY[&"tools_pile"],
		"The heap of blunt and broken stone tools by the cave mouth has grown tall. "
		+ "{subject} wants to do something about it.",
		VillagerState.TRAIT_INDUSTRIOUS
	)
	event.requires.append(_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, &"stone_tools"))
	event.choices = _choices([
		_answer(
			&"sort_it", "Sort the good stone from the rest",
			"{subject} sorted the pile by evening, and half of it turned out to be good for "
			+ "something.",
			[_eff(SimEffect.Kind.SET_FLAG, &"sorted_tools")],
		),
		_answer(
			&"bury_it", "Bury it in the river bank",
			"The heap went into the river bank, and the bank is a little higher there now.",
			[_eff(SimEffect.Kind.SET_FLAG, &"buried_tools")],
		),
	])
	return event


## Ten small forks added so a workday is never without a question (docs/gameplay.md P10): they
## sit in the longest stretches between the others. Each answer does something and sets a flag
## that a quiet line remembers later.
func _cold_floors() -> EventDef:
	var event: EventDef = _story(
		&"cold_floors", "The cold floor", &"settlement", STORY_DAY[&"floors"],
		"The cave floor is bare rock, and the nights have been cold underneath."
	)
	event.choices = _choices([
		_answer(
			&"hang_hides", "Spread the spare hides over the floor",
			"The hides went down in rows, and the cave smelled of animals and was a good deal warmer.",
			[_set_flag(&"hide_floor")],
		),
		_answer(
			&"cut_reeds", "Cut reeds from the river for bedding",
			"Armfuls of reeds were carried up from the river, and everyone slept on a rustling bed.",
			[_set_flag(&"reed_beds")],
		),
	])
	return event


func _lost_flint() -> EventDef:
	var event: EventDef = _story(
		&"lost_flint", "The missing flint", &"character", STORY_DAY[&"lost_flint"],
		"The best flint in the cave has gone missing, and two of the group are each sure the "
		+ "other has it."
	)
	event.choices = _choices([
		_answer(
			&"wrestle_it_out", "Let them settle it with a wrestle by the fire",
			"They wrestled in the firelight until both were laughing, and the flint turned up in "
			+ "a boot.",
			[_set_flag(&"wrestled")],
		),
		_answer(
			&"search_together", "Turn the whole cave over, everyone together",
			"The whole group searched the cave, and found the flint, and a good many other lost "
			+ "things.",
			[_set_flag(&"searched_together")],
		),
	])
	return event


func _night_noises() -> EventDef:
	var event: EventDef = _story(
		&"night_noises", "Scratching in the night", &"nature", STORY_DAY[&"night_noises"],
		"Something has been scratching at the cave wall after dark, always just out of sight."
	)
	event.choices = _choices([
		_answer(
			&"keep_a_torch", "Keep a torch burning at the cave mouth",
			"A torch burned at the cave mouth all night, and the scratching stopped.",
			[_spend(&"wood", 3), _set_flag(&"torch_at_mouth")],
			[_has(&"wood", 3)],
		),
		_answer(
			&"sleep_deeper", "Move the beds deeper into the cave",
			"The beds were moved to the back of the cave, where the sound could not reach.",
			[_set_flag(&"deep_sleepers")],
		),
	])
	return event


func _the_ford() -> EventDef:
	var event: EventDef = _story(
		&"the_ford", "The hard crossing", &"settlement", STORY_DAY[&"ford"],
		"The river is easiest to cross at one place, and everyone has begun to slip there."
	)
	event.choices = _choices([
		_answer(
			&"lay_stepping_stones", "Lay a line of flat stones across it",
			"A line of flat stones was laid across the shallows, each one carried from the bank.",
			[_set_flag(&"stepping_stones")],
		),
		_answer(
			&"fell_a_log", "Fell a tree to lie across it",
			"A tree came down across the river with a crack, and by dusk everyone had walked over it.",
			[_spend(&"wood", 6), _set_flag(&"log_bridge")],
			[_has(&"wood", 6)],
		),
	])
	return event


func _bright_feather() -> EventDef:
	var event: EventDef = _story_about(
		&"bright_feather", "A bright feather", &"character", STORY_DAY[&"feather"],
		"{subject} found a long blue feather by the river, and has been carrying it about all day.",
		VillagerState.TRAIT_NATURE_LOVING
	)
	event.choices = _choices([
		_answer(
			&"wear_the_feather", "Let them keep it, tied in their hair",
			"{subject} tied the feather into their hair, and walked about as if nobody noticed.",
			[_set_flag(&"feather_worn")],
		),
		_answer(
			&"share_the_feather", "Pin it up in the cave for everyone",
			"The feather was pinned above the fire, where everyone could see it.",
			[_set_flag(&"feather_shared")],
		),
	])
	return event


func _bats_in_the_back() -> EventDef:
	var event: EventDef = _story(
		&"bats_in_the_back", "Bats in the back", &"nature", STORY_DAY[&"bats"],
		"Bats have moved into the back of the cave, and hang from the roof all day in a "
		+ "twitching row."
	)
	event.choices = _choices([
		_answer(
			&"smoke_them_out", "Smoke them out with a green fire",
			"A green fire at the back of the cave sent the bats out in a long dark stream.",
			[_spend(&"wood", 3), _set_flag(&"bats_smoked")],
			[_has(&"wood", 3)],
		),
		_answer(
			&"keep_the_bats", "Leave them, and be glad of the quiet midges",
			"The bats stayed, and the cave stopped being full of midges at dusk.",
			[_set_flag(&"bats_kept")],
		),
	])
	return event


func _bee_tree() -> EventDef:
	var event: EventDef = _story(
		&"bee_tree", "The bee tree", &"nature", STORY_DAY[&"honey"],
		"A hollow tree in the western wood hums with bees, and the comb inside is heavy with honey."
	)
	event.choices = _choices([
		_answer(
			&"take_the_comb", "Take the whole comb, and put up with the stings",
			"They took the whole comb, and sticky, swollen, everyone ate until they ached.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 6), _set_flag(&"honey_taken")],
		),
		_answer(
			&"take_a_little", "Take a little and leave the hive standing",
			"They took one small piece of comb and left the tree humming, and the bees stayed.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 3), _set_flag(&"honey_shared")],
		),
	])
	return event


func _fish_run() -> EventDef:
	var event: EventDef = _story(
		&"fish_run", "The run of fish", &"nature", STORY_DAY[&"fish_run"],
		"The river is full of fish, thick in the shallows, all heading the same way."
	)
	event.choices = _choices([
		_answer(
			&"wade_in", "Wade in with spears and bare hands",
			"Half the camp ended up in the river, and came out soaked, laughing, and carrying fish.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 5), _set_flag(&"fish_by_hand")],
		),
		_answer(
			&"weave_a_trap", "Weave a trap across the narrow channel",
			"A trap of woven willow went across the channel, and by morning it was heavy with fish.",
			[
				_spend(&"wood", 4),
				_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 9),
				_set_flag(&"fish_trap"),
			],
			[_has(&"wood", 4)],
		),
	])
	return event


func _hollow_log() -> EventDef:
	var event: EventDef = _story_about(
		&"hollow_log", "A hollow log", &"character", STORY_DAY[&"drum"],
		"{subject} found a hollow log, and found it made a sound when struck.",
		VillagerState.TRAIT_SOCIAL
	)
	event.choices = _choices([
		_answer(
			&"beat_a_drum", "Stretch a hide over the end, and beat it",
			"{subject} stretched a hide across the log, and the whole valley heard the first drum.",
			[_set_flag(&"log_drum")],
		),
		_answer(
			&"carve_a_flute", "Carve a bone into a pipe instead",
			"{subject} bored holes in a bird bone, and by dusk it was a small clear voice.",
			[_set_flag(&"bone_pipe")],
		),
	])
	return event


func _first_snow() -> EventDef:
	var event: EventDef = _story(
		&"first_snow", "The first snow", &"nature", STORY_DAY[&"first_snow"],
		"Snow fell in the night, and the whole valley is white and silent."
	)
	event.requires.append(_season(Season.WINTER))
	event.choices = _choices([
		_answer(
			&"build_a_snow_figure", "Build something in the snow at the cave mouth",
			"A snow figure with a stick for an arm stood at the cave mouth, and nobody would "
			+ "say who had made it.",
			[_set_flag(&"snow_figure")],
		),
		_answer(
			&"read_the_tracks", "Walk out and read what has crossed the snow",
			"They followed the tracks of a hare, a fox, and one that nobody could name.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 3), _set_flag(&"snow_tracks")],
		),
	])
	return event


func _echo_in_the_cave() -> EventDef:
	var event: EventDef = _story(
		&"echo_in_the_cave", "The cave answers", &"character", STORY_DAY[&"echo"],
		"Someone shouted into the deep back of the cave, and it shouted back, a moment later."
	)
	event.choices = _choices([
		_answer(
			&"shout_questions", "Shout questions into it, all together",
			"The whole group shouted questions into the dark, and the cave answered every one "
			+ "with the last word.",
			[_set_flag(&"echo_games")],
		),
		_answer(
			&"whisper_and_listen", "Whisper, and listen to what comes back",
			"They whispered into the cave, one at a time, and held their breath for the reply.",
			[_set_flag(&"echo_whispers")],
		),
	])
	return event


func _sky_stone() -> EventDef:
	var event: EventDef = _story(
		&"sky_stone", "A stone from the sky", &"nature", STORY_DAY[&"sky_stone"],
		"A streak of light crossed the sky in the night, and in the morning there is a heavy "
		+ "black stone in the meadow, still warm."
	)
	event.choices = _choices([
		_answer(
			&"keep_the_sky_stone", "Carry it back and keep it by the fire",
			"Four of them carried the black stone to the cave, and it sat by the fire like a guest.",
			[_set_flag(&"sky_stone_kept")],
		),
		_answer(
			&"mark_the_sky_stone", "Leave it where it fell, and ring it with white stones",
			"They ringed the black stone with white pebbles, and left it to the sky.",
			[_set_flag(&"sky_stone_marked")],
		),
	])
	return event


func _warm_pool() -> EventDef:
	var event: EventDef = _story(
		&"warm_pool", "The warm pool", &"nature", STORY_DAY[&"warm_pool"],
		"A pool up the valley steams in the cold, and the water is warm to the hand."
	)
	event.choices = _choices([
		_answer(
			&"bathe_in_it", "Go and bathe in it on the coldest days",
			"They walked up the valley in the frost and sat in the warm pool up to their chins.",
			[_set_flag(&"warm_pool_used")],
		),
		_answer(
			&"carry_the_warmth", "Fill hide bags and carry the warmth home",
			"Hide bags of warm water were carried home, and everyone slept with one at their feet.",
			[_set_flag(&"warm_bags")],
		),
	])
	return event


func _smoke_in_the_cave() -> EventDef:
	var event: EventDef = _story(
		&"smoke_in_the_cave", "Smoke in the cave", &"settlement", STORY_DAY[&"smoke"],
		"Years of fire have blackened the cave roof, and the smoke lingers every evening."
	)
	event.choices = _choices([
		_answer(
			&"dig_a_smoke_hole", "Open a gap in the roof above the fire",
			"A gap in the roof drew the smoke up, and the stars showed through it.",
			[_spend(&"wood", 8), _set_flag(&"smoke_hole")],
			[_has(&"wood", 8)],
		),
		_answer(
			&"live_with_it", "Live with the smoke",
			"Everyone coughed a little less each year, or said so.",
			[_set_flag(&"smoky_cave")],
		),
	])
	return event


## Small lines for the journal, with nothing asked of the player (gameplay.md P3): some about a
## villager with a trait, some about the world, some that remember an earlier answer.
## Small story decisions that fill the Settled Age between its milestones (docs/ages.md). Like the
## Cave Age's, each has two harmless answers and a journal line, and an answer may set a flag that
## later lines and the next age can read. Costs are bigger than the Cave Age's: by now the stores
## are fuller, and these are what they are for.
func _settled_stories() -> Array[EventDef]:
	return [
		_what_the_cave_is_for(), _marking_the_ground(), _first_furrows(), _pasture_gate(),
		_mending_the_roof(), _the_well(), _the_scarecrow(), _the_herd_dog(), _a_dry_store(),
		_the_quarrel(), _harvest_festival(), _the_oldest_voice(), _the_kiln_pit(), _a_wet_summer(),
		_wild_fowl(), _dyed_cloth(), _the_loom_frame(), _the_flood(), _smoke_in_the_next_valley(),
		_pots_for_salt(), _winter_count(), _green_beads(), _the_low_wall(), _looking_back(),
		_the_threshold(), _midsummer(), _children_in_the_field(), _the_fog(), _long_evenings(),
		_a_boat_for_the_river(), _tide_weir(&"stepping_stones", &"fish_on_the_turn_stones"),
		_tide_weir(&"log_bridge", &"fish_on_the_turn_log"), _heavy_loads(), _whose_pot(),
	]


## A Settled Age story decision: needs the age and the day into it, is asked once, is not about
## anyone.
func _settled_story(
	event_id: StringName, title: String, category: StringName, era_day: int, body: String,
	chance: float = STORY_CHANCE
) -> EventDef:
	var event: EventDef = _event(event_id, title, category)
	event.body = body
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", SETTLED),
		_cond(SimCondition.Kind.ERA_DAYS_AT_LEAST, &"", era_day),
	])
	event.chance_per_tick = chance
	event.once = true
	return event


func _settled_story_about(
	event_id: StringName, title: String, category: StringName, era_day: int, body: String,
	favoured: StringName
) -> EventDef:
	var event: EventDef = _settled_story(event_id, title, category, era_day, body)
	event.needs_subject = true
	event.subject_requires = _conds([_cond(SimCondition.Kind.SUBJECT_AT_HOME)])
	event.trait_weights[favoured] = 3.0
	return event


func _flag_set(flag: StringName) -> SimCondition:
	return _cond(SimCondition.Kind.FLAG_SET, flag)


func _earned(milestone: StringName) -> SimCondition:
	return _cond(SimCondition.Kind.ACHIEVEMENT_EARNED, milestone)


func _set_flag(flag: StringName) -> SimEffect:
	return _eff(SimEffect.Kind.SET_FLAG, flag)


func _what_the_cave_is_for() -> EventDef:
	var event: EventDef = _settled_story(
		&"what_the_cave_is_for", "What the cave is for", &"settlement", SETTLED_STORY_DAY[&"cave"],
		"The cave is still there, dry and deep, and the group has begun to wonder what it is now for."
	)
	event.choices = _choices([
		_answer(
			&"cave_for_stores", "Make it the winter store",
			"Baskets and jars were carried up to the cave, where the cool dark kept them all winter.",
			[_set_flag(&"cave_store")],
		),
		_answer(
			&"cave_for_elders", "Keep it for sleeping and for the old stories",
			"The cave stayed a place to sleep and to tell the old stories, and the huts filled "
			+ "with the young.",
			[_set_flag(&"cave_kept")],
		),
	])
	return event


func _marking_the_ground() -> EventDef:
	var event: EventDef = _settled_story(
		&"marking_the_ground", "Whose ground", &"settlement", SETTLED_STORY_DAY[&"ground"],
		"Everyone has begun to say \"my plot\" and \"your plot\", and nobody can say where one ends."
	)
	event.choices = _choices([
		_answer(
			&"set_boundary_stones", "Set a stone at every corner",
			"A stone went into every corner, and for a week people walked the lines to look at them.",
			[_spend(&"wood", 4), _set_flag(&"boundary_stones")],
			[_has(&"wood", 4)],
		),
		_answer(
			&"leave_it_open", "Leave the ground open and sort it out as it comes",
			"The ground stayed open, and every dispute was settled over a meal.",
			[_set_flag(&"open_ground")],
		),
	])
	return event


func _first_furrows() -> EventDef:
	var event: EventDef = _settled_story(
		&"first_furrows", "The digging sticks", &"settlement", SETTLED_STORY_DAY[&"furrows"],
		"The seed is sown, but the ground fights back, and another digging stick has snapped."
	)
	event.requires.append(_flag_set(&"path_agriculture"))
	event.choices = _choices([
		_answer(
			&"drag_a_branch", "Drag a forked branch through the soil together",
			"Six people dragged a forked branch across the field, and the furrow ran almost straight.",
			[_set_flag(&"forked_plough")],
		),
		_answer(
			&"dig_by_hand", "Keep digging by hand",
			"The digging went on by hand, slowly, and everyone's back knew about it.",
			[_set_flag(&"hand_dug")],
		),
	])
	return event


func _pasture_gate() -> EventDef:
	var event: EventDef = _settled_story(
		&"pasture_gate", "Into the sown ground", &"settlement", SETTLED_STORY_DAY[&"pasture"],
		"The herd keeps wandering into the small sown plot, and the plot keeps losing."
	)
	event.requires.append(_flag_set(&"path_herding"))
	event.choices = _choices([
		_answer(
			&"build_a_gate", "Weave a hurdle gate",
			"A hurdle of woven withies went up across the gap, and the herd stood and looked at it.",
			[_spend(&"wood", 6), _set_flag(&"hurdle_gate")],
			[_has(&"wood", 6)],
		),
		_answer(
			&"post_a_watcher", "Post someone to watch the plot",
			"Someone sat by the plot all day, and had a very good view of the herd.",
			[_set_flag(&"herd_watch")],
		),
	])
	return event


func _mending_the_roof() -> EventDef:
	var event: EventDef = _settled_story(
		&"mending_the_roof", "Rain through the thatch", &"settlement", SETTLED_STORY_DAY[&"roof"],
		"Rain has found the thatch again, and the dark patch on the ceiling grows every night."
	)
	event.requires.append(_earned(&"first_roof"))
	event.choices = _choices([
		_answer(
			&"patch_it_now", "Patch it while the weather holds",
			"Fresh reed went over the worn thatch, and the next storm drummed on it harmlessly.",
			[_spend(&"wood", 6), _set_flag(&"tight_roofs")],
			[_has(&"wood", 6)],
		),
		_answer(
			&"wait_for_dry", "Wait for dry weather",
			"They waited for dry weather, and put a pot under the drip in the meantime.",
			[_set_flag(&"leaky_roofs")],
		),
	])
	return event


func _the_well() -> EventDef:
	var event: EventDef = _settled_story(
		&"the_well", "A place to fetch water", &"settlement", SETTLED_STORY_DAY[&"well"],
		"Carrying water from the river twice a day is starting to feel like a way of life."
	)
	event.choices = _choices([
		_answer(
			&"dig_a_well", "Dig a well, and line it with stones",
			"The well went down past the roots of the old tree, and the water that came up tasted of stone.",
			[_spend(&"wood", 8), _set_flag(&"well_dug")],
			[_has(&"wood", 8)],
		),
		_answer(
			&"keep_carrying", "Keep carrying water from the river",
			"They kept carrying water from the river, and everybody grew a good pair of shoulders.",
			[_set_flag(&"well_carriers")],
		),
	])
	return event


func _the_scarecrow() -> EventDef:
	var event: EventDef = _settled_story(
		&"the_scarecrow", "Birds in the field", &"nature", SETTLED_STORY_DAY[&"scarecrow"],
		"The birds have found the field, and they are very pleased with it."
	)
	event.requires.append(_flag_set(&"path_agriculture"))
	event.choices = _choices([
		_answer(
			&"dress_a_scarecrow", "Dress a scarecrow in an old hide tunic",
			"A scarecrow went up in an old tunic. The birds were wary for two days, then sat on its head.",
			[_set_flag(&"scarecrow")],
		),
		_answer(
			&"take_turns", "Take turns chasing them off",
			"They took turns chasing the birds, and by evening everyone was hoarse.",
			[_set_flag(&"field_watchers")],
		),
	])
	return event


func _the_herd_dog() -> EventDef:
	var event: EventDef = _settled_story(
		&"the_herd_dog", "A dog at the fold", &"nature", SETTLED_STORY_DAY[&"dog"],
		"A half-tame dog has taken to following the herd, keeping the stragglers from straying."
	)
	event.requires.append(_flag_set(&"path_herding"))
	event.choices = _choices([
		_answer(
			&"feed_the_dog", "Feed it, and let it stay",
			"The dog was fed, and it stayed, and by the end of the week it had opinions about the herd.",
			[_spend(&"food", 2), _set_flag(&"herd_dog")],
			[_has(&"food", 2)],
		),
		_answer(
			&"shoo_it_off", "Leave it to its own business",
			"The dog was left to its own business, and went on doing it, at a distance, with the herd.",
			[_set_flag(&"dog_at_a_distance")],
		),
	])
	return event


func _a_dry_store() -> EventDef:
	var event: EventDef = _settled_story(
		&"a_dry_store", "Damp grain", &"settlement", SETTLED_STORY_DAY[&"store"],
		"The grain in the baskets is going damp at the bottom, and something has been at the rest."
	)
	event.requires.append(_earned(&"first_harvest"))
	event.choices = _choices([
		_answer(
			&"dig_a_store_pit", "Line a pit with clay",
			"A pit lined with clay and capped with a flat stone kept the grain dry and the mice hungry.",
			[_spend(&"wood", 6), _set_flag(&"store_pit")],
			[_has(&"wood", 6)],
		),
		_answer(
			&"hang_the_baskets", "Hang the baskets from the rafters",
			"The baskets were hung from the rafters, out of reach of everything but the swallows.",
			[_set_flag(&"hanging_baskets")],
		),
	])
	return event


func _the_quarrel() -> EventDef:
	var event: EventDef = _settled_story_about(
		&"the_quarrel", "Over the fence", &"character", SETTLED_STORY_DAY[&"quarrel"],
		"{subject} and a neighbour are not speaking, over a handspan of ground that both of them "
		+ "are sure is theirs.",
		VillagerState.TRAIT_SOCIAL
	)
	event.choices = _choices([
		_answer(
			&"talk_it_through", "Sit them down by the fire together",
			"{subject} and the neighbour were sat by the fire, and by the third pot they were laughing.",
			[_set_flag(&"peacemaking")],
		),
		_answer(
			&"let_it_cool", "Let it cool by itself",
			"It cooled by itself, slowly, and the handspan of ground was never mentioned again.",
			[_set_flag(&"cooled_off")],
		),
	])
	return event


func _harvest_festival() -> EventDef:
	var event: EventDef = _settled_story(
		&"harvest_festival", "More than enough", &"settlement", SETTLED_STORY_DAY[&"festival"],
		"The stores are full for the first time, and nobody can remember a year like it."
	)
	event.requires.append(_earned(&"first_harvest"))
	event.choices = _choices([
		_answer(
			&"hold_the_festival", "Hold a harvest festival",
			"A festival ran from noon to the small hours. There was a lot of dancing and a little singing.",
			[_spend(&"food", 20), _set_flag(&"festival")],
			[_has(&"food", 20)],
		),
		_answer(
			&"lay_it_by", "Lay it by for the lean months",
			"Everything was laid by for the lean months, and the lean months were noticeably less lean.",
			[_set_flag(&"laid_by")],
		),
	])
	return event


func _the_oldest_voice() -> EventDef:
	var event: EventDef = _settled_story_about(
		&"the_oldest_voice", "Before the huts", &"character", SETTLED_STORY_DAY[&"voice"],
		"{subject} has noticed that the youngest cannot remember the cave, or the cold, or the "
		+ "first fire. They think the camp was always like this.",
		VillagerState.TRAIT_SOCIAL
	)
	event.choices = _choices([
		_answer(
			&"tell_the_whole_story", "Tell it all, from the cold to the first fire",
			"{subject} told it all, from the cold to the first fire, and the youngest listened "
			+ "with their mouths open.",
			[_set_flag(&"cave_tale")],
		),
		_answer(
			&"keep_it_short", "Tell them a short version, and let the rest come later",
			"{subject} told a short version, and said there would be more when they were older.",
			[_set_flag(&"short_tale")],
		),
	])
	return event


func _the_kiln_pit() -> EventDef:
	var event: EventDef = _settled_story(
		&"the_kiln_pit", "A pit for the pots", &"settlement", SETTLED_STORY_DAY[&"kiln"],
		"Baking pots in hot ashes loses one in three. A proper pit, with a roof and a draught, "
		+ "might lose far fewer."
	)
	event.requires.append(_earned(&"fired_clay"))
	event.choices = _choices([
		_answer(
			&"build_a_kiln", "Build a kiln pit",
			"The kiln pit was lit for the first time at dusk, and nothing came out of it cracked.",
			[_spend(&"wood", 15), _set_flag(&"kiln")],
			[_has(&"wood", 15)],
		),
		_answer(
			&"bake_in_ashes", "Keep baking in the ashes",
			"They went on baking in the ashes, and made a few more pots to cover the cracked ones.",
			[_set_flag(&"ash_baking")],
		),
	])
	return event


func _a_wet_summer() -> EventDef:
	var event: EventDef = _settled_story(
		&"a_wet_summer", "Nine days of rain", &"nature", SETTLED_STORY_DAY[&"wet"],
		"The rain has not stopped for nine days, and the low ground by the river has become a pond."
	)
	event.requires.append(_season(Season.SUMMER))
	event.choices = _choices([
		_answer(
			&"dig_a_ditch", "Dig a ditch to carry the water away",
			"A ditch carried the water off to the river, and the pond sulked and shrank.",
			[_spend(&"wood", 8), _set_flag(&"ditch")],
			[_has(&"wood", 8)],
		),
		_answer(
			&"wait_it_out", "Wait for the rain to stop",
			"The rain stopped on the eleventh day, and the pond took a week to leave.",
			[_set_flag(&"waited_out_rain")],
		),
	])
	return event


func _wild_fowl() -> EventDef:
	var event: EventDef = _settled_story(
		&"wild_fowl", "Small brown birds", &"nature", SETTLED_STORY_DAY[&"fowl"],
		"A flock of small brown fowl has begun nesting by the huts, as if it had been invited."
	)
	event.choices = _choices([
		_answer(
			&"tempt_them_with_grain", "Scatter a little grain for them",
			"A little grain was scattered each dawn, and by the new moon the birds came when called.",
			[_spend(&"food", 3), _set_flag(&"hens")],
			[_has(&"food", 3)],
		),
		_answer(
			&"let_them_be", "Let them be",
			"The birds were let be, and carried on arguing on the roofs.",
			[_set_flag(&"wild_fowl_left")],
		),
	])
	return event


func _dyed_cloth() -> EventDef:
	var event: EventDef = _settled_story(
		&"dyed_cloth", "A colour for the cloth", &"character", SETTLED_STORY_DAY[&"dye"],
		"The cloth is soft and strong and exactly the colour of a sheep, and someone has started to mind."
	)
	event.requires.append(_earned(&"woven_cloth"))
	event.choices = _choices([
		_answer(
			&"dye_with_berries", "Boil it with berries and bark",
			"The cloth came out of the pot a deep red, and its owner wore it all week.",
			[_spend(&"food", 6), _set_flag(&"dyed_cloth")],
			[_has(&"food", 6)],
		),
		_answer(
			&"keep_it_plain", "Keep it plain",
			"The cloth was kept plain, and was said to be none the worse for it.",
			[_set_flag(&"plain_cloth")],
		),
	])
	return event


func _the_loom_frame() -> EventDef:
	var event: EventDef = _settled_story_about(
		&"the_loom_frame", "Two posts and some thread", &"character",
		SETTLED_STORY_DAY[&"loom"],
		"{subject} has propped a frame between two posts and wound thread from end to end. It "
		+ "might weave faster than hands alone.",
		VillagerState.TRAIT_INDUSTRIOUS
	)
	event.requires.append(_earned(&"woven_cloth"))
	event.choices = _choices([
		_answer(
			&"build_a_loom", "Build the loom properly",
			"The loom went up by the door, and the first cloth off it was the widest anyone had seen.",
			[_spend(&"wood", 8), _set_flag(&"loom")],
			[_has(&"wood", 8)],
		),
		_answer(
			&"keep_the_spindle", "Stay with the spindle",
			"They stayed with the spindle, and the frame leaned against a wall and was used for drying.",
			[_set_flag(&"spindle_only")],
		),
	])
	return event


func _the_flood() -> EventDef:
	var event: EventDef = _settled_story(
		&"the_flood", "The river is rising", &"nature", SETTLED_STORY_DAY[&"flood"],
		"The river has risen to the edge of the fields, and the low plots are under a finger of water."
	)
	event.requires.append(_season(Season.SPRING))
	event.choices = _choices([
		_answer(
			&"build_a_bank", "Raise a bank of earth and stone",
			"A bank of earth and stone went up along the river, and the water stopped at its foot.",
			[_spend(&"wood", 20), _set_flag(&"river_bank")],
			[_has(&"wood", 20)],
		),
		_answer(
			&"move_what_you_can", "Move what you can to higher ground",
			"They moved what they could to higher ground, and the river went down on its own.",
			[_set_flag(&"moved_to_high_ground")],
		),
	])
	return event


func _smoke_in_the_next_valley() -> EventDef:
	var event: EventDef = _settled_story(
		&"smoke_in_the_next_valley", "Smoke beyond the ridge", &"exploration",
		SETTLED_STORY_DAY[&"neighbours"],
		"A thin column of smoke rises beyond the ridge, where there was never smoke before."
	)
	event.choices = _choices([
		_answer(
			&"send_a_gift", "Send a gift of grain over the ridge",
			"A sack of grain went over the ridge. A string of shells came back, and a message "
			+ "nobody could read.",
			[_spend(&"food", 12), _set_flag(&"good_neighbours")],
			[_has(&"food", 12)],
		),
		_answer(
			&"watch_and_wait", "Watch, and wait to be visited",
			"They watched the smoke for three days, and the smoke, presumably, watched them.",
			[_set_flag(&"waited_for_visitors")],
		),
	])
	return event


func _pots_for_salt() -> EventDef:
	var event: EventDef = _settled_story(
		&"pots_for_salt", "Salt", &"exploration", SETTLED_STORY_DAY[&"salt"],
		"A trader from the coast has offered a bag of grey salt for a load of fired pots."
	)
	event.requires.append(_earned(&"fired_clay"))
	event.choices = _choices([
		_answer(
			&"trade_pots_for_salt", "Trade a load of pots for the salt",
			"The pots went off on a donkey, and the salt made the winter meat last until spring.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 6), _set_flag(&"salt")],
		),
		_answer(
			&"keep_the_pots", "Keep the pots",
			"The pots were kept, and the trader went away with a polite face and no pots.",
			[_set_flag(&"pots_kept")],
		),
	])
	return event


func _winter_count() -> EventDef:
	var event: EventDef = _settled_story(
		&"winter_count", "Before winter", &"settlement", SETTLED_STORY_DAY[&"count"],
		"The leaves are turning. Somebody has counted the stores twice, and got two different answers."
	)
	event.requires.append(_season(Season.AUTUMN))
	event.choices = _choices([
		_answer(
			&"lay_in_more", "Lay in more firewood and set it dry",
			"Firewood was stacked along every wall, and the winter looked at it and thought better of it.",
			[_spend(&"wood", 15), _set_flag(&"winter_ready")],
			[_has(&"wood", 15)],
		),
		_answer(
			&"trust_the_stores", "Trust the stores",
			"The stores were trusted, and held, and nobody said anything about the counting.",
			[_set_flag(&"trusted_stores")],
		),
	])
	return event


func _green_beads() -> EventDef:
	var event: EventDef = _settled_story_about(
		&"green_beads", "What the stone does", &"exploration", SETTLED_STORY_DAY[&"beads"],
		"{subject} has been turning the green stone over for days. It is soft enough to scratch, "
		+ "and it does something strange in a hot fire.",
		VillagerState.TRAIT_CURIOUS
	)
	event.requires.append(_earned(&"green_stone"))
	event.choices = _choices([
		_answer(
			&"shape_beads", "Shape it into beads for everyone",
			"{subject} shaped a bead for everyone in the camp, and wearing one became a way of belonging.",
			[_set_flag(&"green_beads")],
		),
		_answer(
			&"try_the_fire", "Put more in the fire, and see what it does",
			"{subject} put more of the green stone in the fire, and at the bottom of the ash there was "
			+ "a bright dribble of metal.",
			[_set_flag(&"copper_tried")],
		),
	])
	return event


func _the_low_wall() -> EventDef:
	var event: EventDef = _settled_story(
		&"the_low_wall", "How far the village goes", &"settlement", SETTLED_STORY_DAY[&"wall"],
		"The village has grown past the edge of anyone's idea of it. Someone has asked where, "
		+ "exactly, it stops."
	)
	event.choices = _choices([
		_answer(
			&"build_a_low_wall", "Raise a low wall of fieldstones",
			"A low wall of fieldstones went up round the village, and everyone sat on it at least once.",
			[_spend(&"wood", 25), _set_flag(&"low_wall")],
			[_has(&"wood", 25)],
		),
		_answer(
			&"keep_it_open", "Leave it open",
			"The village was left open, and the paths went out from it like the spokes of a wheel.",
			[_set_flag(&"open_village")],
		),
	])
	return event


func _looking_back() -> EventDef:
	var event: EventDef = _settled_story_about(
		&"looking_back", "Up at the cave", &"character", SETTLED_STORY_DAY[&"looking_back"],
		"{subject} climbed up to the cave this evening, and sat in the mouth of it for a long while, "
		+ "looking down at the roofs.",
		VillagerState.TRAIT_NATURE_LOVING
	)
	event.choices = _choices([
		_answer(
			&"light_the_cave", "Light a fire in the cave, once every year",
			"A small fire was lit in the cave, and it was agreed that it would be lit again next year.",
			[_set_flag(&"cave_remembered")],
		),
		_answer(
			&"let_it_be", "Let the cave be",
			"The cave was let be, dark and dry, and there were bats in it by spring.",
			[_set_flag(&"cave_left_alone")],
		),
	])
	return event


## Five small forks added so no stretch of the Settled Age goes long without a question
## (docs/gameplay.md P10).
func _the_threshold() -> EventDef:
	var event: EventDef = _settled_story(
		&"the_threshold", "Mud at the door", &"settlement", SETTLED_STORY_DAY[&"threshold"],
		"Everyone comes in from the fields with half the field on their feet, and the new floors are suffering."
	)
	event.choices = _choices([
		_answer(
			&"lay_door_stones", "Lay a flat stone at every door",
			"A flat stone went down at every door, and the mud stayed outside for nearly a week.",
			[_set_flag(&"door_stones")],
		),
		_answer(
			&"weave_door_mats", "Plait a reed mat for every door",
			"A reed mat lay at every door, and each one was plaited a little differently.",
			[_set_flag(&"door_mats")],
		),
	])
	return event


func _midsummer() -> EventDef:
	var event: EventDef = _settled_story(
		&"midsummer", "The longest day", &"settlement", SETTLED_STORY_DAY[&"midsummer"],
		"The sun has barely set, and someone has pointed out that tomorrow it will rise nearly "
		+ "where it set."
	)
	event.requires.append(_season(Season.SUMMER))
	event.choices = _choices([
		_answer(
			&"fire_on_the_hill", "Light a fire on the hill and watch it from the huts",
			"A fire burned on the hill all night, and everyone watched it from their doors.",
			[_set_flag(&"midsummer_hill")],
		),
		_answer(
			&"dance_round_the_hearth", "Sit up round the village hearth until it is light again",
			"The whole village sat up round the hearth, and the sun came back before anyone slept.",
			[_set_flag(&"midsummer_hearth")],
		),
	])
	return event


func _children_in_the_field() -> EventDef:
	var event: EventDef = _settled_story(
		&"children_in_the_field", "Small hands", &"character", SETTLED_STORY_DAY[&"children"],
		"The children follow the harvest from field to field, getting under every foot."
	)
	event.choices = _choices([
		_answer(
			&"give_them_jobs", "Give each of them a small job",
			"Each child was given a job, and took it with such seriousness that it was nearly "
			+ "useful.",
			[_set_flag(&"young_helpers")],
		),
		_answer(
			&"let_them_play", "Let them make a game of the sheaves",
			"The children built a fort of sheaves at the field's edge, and defended it all afternoon.",
			[_set_flag(&"sheaf_fort")],
		),
	])
	return event


func _the_fog() -> EventDef:
	var event: EventDef = _settled_story(
		&"the_fog", "Three days of fog", &"nature", SETTLED_STORY_DAY[&"fog"],
		"Fog has lain over the valley for three days, so thick that people have started to "
		+ "call out when they cross the yard."
	)
	event.choices = _choices([
		_answer(
			&"strike_a_gong", "Hang a flat stone and strike it every hour",
			"A flat stone was hung from a post and struck on the hour, and the fog gave the "
			+ "sound back from every side.",
			[_set_flag(&"fog_gong")],
		),
		_answer(
			&"run_a_rope", "Run a rope from hut to hut",
			"A rope ran from door to door, and everyone learned to walk with a hand on it.",
			[_set_flag(&"fog_rope")],
		),
	])
	return event


func _long_evenings() -> EventDef:
	var event: EventDef = _settled_story(
		&"long_evenings", "The long evenings", &"character", SETTLED_STORY_DAY[&"evenings"],
		"The evenings have grown long, and nobody quite knows what to do with them."
	)
	event.choices = _choices([
		_answer(
			&"tell_in_turns", "Tell a story each, in turns, round the hearth",
			"Each person told one story in turn round the hearth, and the oldest ones had "
			+ "never been told aloud before.",
			[_set_flag(&"evening_tales")],
		),
		_answer(
			&"work_by_the_fire", "Bring the mending to the fire and work together",
			"Everyone brought their mending to the fire, and the talk went along with the needles.",
			[_set_flag(&"evening_work")],
		),
	])
	return event


## ---- The river and the sea (docs/ages.md V13, issue #9): what the east page's water gives. The
## tide is low only part of the time (`SimConfig.tide_at`), so these are asked in that window.

## The Cave Age's low tide, asked once a crossing to the spit is open (one copy per answer to "The
## hard crossing", so saves that already answered it work). The sea is out for hours at a time.
func _low_tide(crossing: StringName, event_id: StringName) -> EventDef:
	var event: EventDef = _story(
		event_id, "The sea has gone out", &"nature", STORY_DAY[&"low_tide"],
		"The sea has gone a long way out beyond the spit, and the wet sand ticks and glitters. "
		+ "It will not stay out for long."
	)
	event.requires.append(_flag_set(crossing))
	event.requires.append(_cond(SimCondition.Kind.TIDE_LOW))
	event.choices = _choices([
		_answer(
			&"gather_shellfish", "Go out onto the flats for shellfish",
			"Everyone went out onto the flats with baskets, and came back before the water did, "
			+ "heavy and wet.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 5), _set_flag(&"shellfish_gathered")],
		),
		_answer(
			&"comb_the_tideline", "Walk the tideline for driftwood",
			"The tideline was littered with pale, salt-dry wood, and it was carried back by the "
			+ "armful.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"wood", 5), _set_flag(&"driftwood_gathered")],
		),
	])
	return event


## The Settled Age's low tide: what to do with the flats, asked once a crossing is open.
func _tide_weir(crossing: StringName, event_id: StringName) -> EventDef:
	var event: EventDef = _settled_story(
		event_id, "Fish on the turn of the tide", &"nature", SETTLED_STORY_DAY[&"weir"],
		"Fish are left in the pools on the flats each time the sea goes out, and the gulls "
		+ "know it."
	)
	event.requires.append(_flag_set(crossing))
	event.requires.append(_cond(SimCondition.Kind.TIDE_LOW))
	event.choices = _choices([
		_answer(
			&"build_a_weir", "Pile a weir of stones to hold the fish",
			"A curved weir of stones went up on the flats, and the next tide left it full.",
			[
				_spend(&"wood", 6),
				_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 8),
				_set_flag(&"tide_weir"),
			],
			[_has(&"wood", 6)],
		),
		_answer(
			&"wade_out_with_baskets", "Wade out with baskets at the turn",
			"They waded out with baskets as the water turned, and took what the pools held.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 4), _set_flag(&"tide_baskets")],
		),
	])
	return event


func _a_boat_for_the_river() -> EventDef:
	var event: EventDef = _settled_story(
		&"a_boat_for_the_river", "A boat for the river", &"settlement",
		SETTLED_STORY_DAY[&"canoe"],
		"The river is wide, and the fish are in the middle of it. Someone has been looking at it "
		+ "for a long time."
	)
	event.choices = _choices([
		_answer(
			&"hollow_a_dugout", "Hollow a log into a dugout canoe",
			"A log was burned and scraped hollow, and the canoe went into the river with "
			+ "everyone watching. It floated.",
			[
				_spend(&"wood", 6),
				_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 6),
				_set_flag(&"dugout_canoe"),
			],
			[_has(&"wood", 6)],
		),
		_answer(
			&"bind_a_raft", "Bind a raft of reeds",
			"Reeds were bound in great bundles into a raft, which rode low, wobbled, and carried "
			+ "three people across and back.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 3), _set_flag(&"reed_raft")],
		),
	])
	return event


## ---- Growth and food (docs/gameplay.md P5, P13): arrivals while there is room and food, and the
## forks that ease a crowded or hungry camp. Nobody dies or starves: a family may leave to live
## elsewhere, and a shortage only moves what the group does with its days.

## Days (Cave: since the start; Settled: into the age) from which each can be asked.
const GROWTH_DAY: Dictionary = {&"traveller": 200, &"crowded": 196, &"foraging": 204}
const SETTLED_GROWTH_DAY: Dictionary = {&"door": 232, &"crowded": 236, &"lean": 224}


func _growth_decisions() -> Array[EventDef]:
	return [
		_traveller_at_dusk(), _too_many_for_the_cave(), _who_leads_the_foraging(),
		_family_at_the_door(), _too_many_for_the_village(), _a_lean_spring(),
	]


## Only while the cave is not the Settled Age's.
func _cave_only() -> SimCondition:
	return _cond(SimCondition.Kind.ERA_AT_LEAST, &"", SETTLED, true)


func _room_for(villagers: int) -> SimCondition:
	return _cond(SimCondition.Kind.HAS_ROOM, &"", villagers)


func _no_room() -> SimCondition:
	return _cond(SimCondition.Kind.HAS_ROOM, &"", 1, true)


func _food_below(amount: int) -> SimCondition:
	return _cond(SimCondition.Kind.RESOURCE_AT_LEAST, &"food", amount, true)


func _traveller_at_dusk() -> EventDef:
	var event: EventDef = _story(
		&"traveller_at_dusk", "A traveller at dusk", &"exploration", GROWTH_DAY[&"traveller"],
		"Someone walking alone has stopped at the edge of the firelight, with the look of a "
		+ "person who has come a long way and would like to be asked in."
	)
	event.requires.append_array([
		_cave_only(), _earned(&"bigger_group"), _room_for(1), _has(&"food", 12),
	])
	event.choices = _choices([
		_answer(
			&"offer_a_place", "Offer them a place by the fire",
			"The traveller sat down by the fire, ate, and stayed, and the group grew.",
			[_eff(SimEffect.Kind.ADD_VILLAGER, &"", 1), _set_flag(&"traveller_stayed")],
		),
		_answer(
			&"feed_and_send_on", "Feed them and send them on with a story to tell",
			"The traveller ate what was offered, told a long story of the valleys beyond, and "
			+ "went on in the morning.",
			[_spend(&"food", 4), _set_flag(&"traveller_fed")],
			[_has(&"food", 4)],
		),
	])
	return event


func _too_many_for_the_cave() -> EventDef:
	var event: EventDef = _story(
		&"too_many_for_the_cave", "Too many for the cave", &"settlement", GROWTH_DAY[&"crowded"],
		"There is no more room by the fire. People sleep with their feet in each other's "
		+ "hair, and the mornings are loud."
	)
	event.requires.append_array([
		_cave_only(), _earned(&"bigger_group"), _no_room(), _has(&"wood", 8),
	])
	event.choices = _choices([
		_answer(
			&"raise_a_lean_to", "Raise a lean-to against the cave mouth",
			"A lean-to of poles and hides went up against the cave mouth, and there was room again.",
			[_spend(&"wood", 8), _set_flag(&"lean_to")],
			[_has(&"wood", 8)],
		),
		_answer(
			&"a_family_goes", "Let a family go and make their own camp by the river",
			"A family took what was theirs and went down to the river to make their own camp. "
			+ "Their smoke could be seen from the cave mouth on still evenings.",
			[_eff(SimEffect.Kind.REMOVE_VILLAGER, &"", 2), _set_flag(&"kin_by_the_river")],
		),
	])
	return event


func _who_leads_the_foraging() -> EventDef:
	var event: EventDef = _story_about(
		&"who_leads_the_foraging", "Who leads the foraging", &"character",
		GROWTH_DAY[&"foraging"],
		"The food pile is thinner than it was, and the baskets come back later. {subject} "
		+ "knows where the best of the river bank is.",
		VillagerState.TRAIT_NATURE_LOVING
	)
	event.requires.append_array([_cave_only(), _earned(&"bigger_group"), _food_below(30)])
	event.choices = _choices([
		_answer(
			&"lead_the_baskets", "Let {subject} lead the foraging parties",
			"{subject} took the baskets down the river bank, and everyone came back with more.",
			[
				_eff(SimEffect.Kind.SET_PROFESSION, &"forager"), _set_flag(&"forager_chosen"),
				_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 6),
			],
		),
		_answer(
			&"share_the_baskets", "Share the foraging out evenly",
			"Everyone took a turn with the baskets, and the work went round the fire like a story.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 4), _set_flag(&"foraging_shared")],
		),
	])
	return event


func _family_at_the_door() -> EventDef:
	var event: EventDef = _settled_story(
		&"family_at_the_door", "Another family at the door", &"exploration",
		SETTLED_GROWTH_DAY[&"door"],
		"A family has come up the road with everything they own on their backs. They have "
		+ "heard there is bread here."
	)
	event.requires.append_array([
		_earned(&"a_village"), _room_for(2), _has(&"food", 16), _has(&"wood", 10),
	])
	event.choices = _choices([
		_answer(
			&"take_them_in", "Take them in",
			"The family was taken in, and the village grew by two more mouths and two more pairs "
			+ "of hands.",
			[_eff(SimEffect.Kind.ADD_VILLAGER, &"", 2), _set_flag(&"door_open")],
		),
		_answer(
			&"raise_them_a_roof", "Help them raise a roof of their own by the river",
			"The whole village turned out for a day to raise a roof by the river, and the family "
			+ "moved in before dark.",
			[_spend(&"wood", 10), _set_flag(&"roof_by_the_river")],
			[_has(&"wood", 10)],
		),
	])
	return event


func _too_many_for_the_village() -> EventDef:
	var event: EventDef = _settled_story(
		&"too_many_for_the_village", "Too many for the village", &"settlement",
		SETTLED_GROWTH_DAY[&"crowded"],
		"The huts are full, and the paths between them are never quiet. Everyone agrees "
		+ "something has to give."
	)
	event.requires.append_array([_earned(&"a_village"), _no_room(), _has(&"wood", 12)])
	event.choices = _choices([
		_answer(
			&"raise_another_roof", "Raise another roof",
			"Another roof went up at the end of the row, and the village had room again.",
			[_spend(&"wood", 12), _set_flag(&"extra_roofs")],
			[_has(&"wood", 12)],
		),
		_answer(
			&"a_family_moves_on", "Let a family go and start a village of their own",
			"A family loaded a cart and went to start a village of their own, a good day's walk "
			+ "down the river. They promised to send word.",
			[_eff(SimEffect.Kind.REMOVE_VILLAGER, &"", 2), _set_flag(&"kin_moved_on")],
		),
	])
	return event


func _a_lean_spring() -> EventDef:
	var event: EventDef = _settled_story(
		&"a_lean_spring", "A lean spring", &"settlement", SETTLED_GROWTH_DAY[&"lean"],
		"The stores are low and the new grain is not yet up. The village is bigger than it "
		+ "has ever been, and everyone is counting."
	)
	event.requires.append_array([_earned(&"a_village"), _food_below(24), _season(Season.SPRING)])
	event.choices = _choices([
		_answer(
			&"work_the_river_and_fields", "Send everyone out to the river and the fields for a day",
			"Everyone went out to the river and the fields, and the baskets came home heavy.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 8), _set_flag(&"lean_spring_worked")],
		),
		_answer(
			&"open_the_winter_store", "Open the winter store and ration it",
			"The winter store was opened and every portion was counted out, and nobody went to "
			+ "bed hungry.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 6), _set_flag(&"lean_spring_rationed")],
		),
	])
	return event


func _ambient_lines() -> Array[EventDef]:
	var lines: Array[EventDef] = [
		_ambient(
			&"morning_mist", "Mist lay on the river until midday, and the camp was very quiet."
		),
		_ambient(
			&"heron", "A heron stood in the shallows all afternoon, as if it had business there."
		),
		_seasonal(
			&"frost_glitter", Season.WINTER,
			"The grass glittered with frost this morning, and then it was gone."
		),
		_seasonal(
			&"geese", Season.AUTUMN, "A long line of geese went over, calling, bound somewhere warmer."
		),
		_ambient(
			&"far_thunder",
			"Thunder grumbled far off, and everyone looked up and nobody was afraid."
		),
		_ambient(
			&"warm_wind",
			"A warm wind came up the valley, and for a day everyone sat outside.", 10
		),
		_ambient_about(
			&"watching_ants", VillagerState.TRAIT_CURIOUS,
			"{subject} lay in the grass all morning watching ants, and could not say why."
		),
		_ambient_about(
			&"shiny_pebble", VillagerState.TRAIT_CURIOUS,
			"{subject} found a pebble that flashed in the water, and keeps it in a pouch."
		),
		_ambient_about(
			&"humming", VillagerState.TRAIT_SOCIAL,
			"{subject} hummed while working, and before long someone hummed back."
		),
		_ambient_about(
			&"a_joke", VillagerState.TRAIT_SOCIAL,
			"{subject} told a joke by the fire. Nobody remembers the joke; everybody "
			+ "remembers the laughing."
		),
		_ambient_about(
			&"sharpened_everything", VillagerState.TRAIT_INDUSTRIOUS,
			"{subject} sharpened every tool in the camp before breakfast, and looked for more."
		),
		_ambient_about(
			&"woodpile", VillagerState.TRAIT_INDUSTRIOUS,
			"{subject} stacked the firewood into a neat wall, and seemed very pleased with it."
		),
		_ambient_about(
			&"crocuses", VillagerState.TRAIT_NATURE_LOVING,
			"{subject} came back from the meadow with crocuses, and set them in the cave mouth."
		),
		_ambient_about(
			&"bird_call", VillagerState.TRAIT_NATURE_LOVING,
			"{subject} followed a bird's call to the river and back, and could answer it."
		),
		_remembered(
			&"wolf_waits", &"wolf_fed",
			"The grey wolf was back at the edge of the light, and nobody minded."
		),
		_remembered(
			&"wolf_howl", &"wolf_driven_off",
			"Far off in the night, a lone wolf howled, and was not answered."
		),
		_remembered(
			&"song_again", &"work_song",
			"The work song drifted across the camp again, a little faster than before."
		),
		_remembered(
			&"herd_on_the_wall", &"art_herd",
			"Someone stood before the painted herd for a long time, and said nothing."
		),
		_remembered(
			&"moon_on_the_wall", &"art_sky",
			"At dusk the painted moon caught the firelight, and for a moment glowed from inside."
		),
		_remembered(
			&"two_fires", &"second_hearth",
			"Two fires burned in the camp that evening, and each had a story going."
		),
		_remembered(
			&"snare_rabbit", &"snares",
			"A rabbit was found in one of the snares, and the group ate well that night."
		),
		_remembered(
			&"mammoth_stays", &"mammoth_fed",
			"The mammoth was in the same place at dawn. It seems to have decided to stay."
		),
		_remembered(
			&"deer_returns", &"deer_tended",
			"A deer with a faint crooked step watched the camp from the meadow, then wasn't there."
		),
		_remembered(
			&"hunter_overhead", &"star_names",
			"Someone showed the Hunter to a sleepy neighbour, and it was exactly where they said."
		),
		_remembered(
			&"tale_told_again", &"living_tale",
			"The long story was told again tonight. It had a new river in it."
		),
		_remembered(
			&"hunters_home", &"path_hunting",
			"The hunters came back at dusk with a deer slung between two poles."
		),
		_remembered(
			&"one_that_got_away", &"path_hunting",
			"The hunters talked all evening about the one that got away."
		),
		_remembered(
			&"baskets_full", &"path_foraging",
			"The baskets came back heavy with roots and berries from along the river."
		),
		_remembered(
			&"fire_banked", &"embers_waited",
			"Someone banked the fire for the night with ash, the way you do with something "
			+ "that was waited for."
		),
		_remembered(
			&"nut_stone_again", &"nut_hammer",
			"The round river stone was cracking nuts again, and still as good as ever."
		),
		_remembered(
			&"tale_by_the_fire", &"tales_told",
			"The story was told again by the fire, everyone in their usual place."
		),
		_remembered(
			&"fire_song", &"songs_sung",
			"Someone started the fire-song, and the whole cave knew the words."
		),
		_remembered(
			&"red_cheek", &"body_paint",
			"A red handprint dried on someone's cheek, and nobody wiped it off."
		),
		_remembered(
			&"newcomer_laughs", &"strangers_welcomed",
			"One of the newcomers laughed by the fire, and the others turned round in surprise."
		),
		_remembered(
			&"food_at_dusk", &"strangers_courted",
			"A bundle of food was set out at dusk again, though the strangers had long since come in."
		),
		_remembered(
			&"scout_boots", &"scouted_alone",
			"The scout's boots stood by the cave mouth, still muddy from the forest."
		),
		_remembered(
			&"walk_to_the_forest", &"scouted_together",
			"Someone told the story of the day the whole camp walked to the western forest."
		),
		_remembered(
			&"sunny_seed", &"seed_in_sun",
			"Someone checked the strange seed in the sun at the cave mouth, for the third time today."
		),
		_remembered(
			&"shady_seed", &"seed_in_shade",
			"Someone crouched under the overhang to look at the strange seed, and said nothing."
		),
		_remembered(
			&"private_sky", &"stars_private",
			"Someone lay awake outside, and nobody asked what they were looking at."
		),
		_remembered(
			&"bear_in_ash", &"prints_read",
			"A bear's paw was drawn in the ash by the fire, to show how big they get."
		),
		_remembered(
			&"feast_song", &"feast_held",
			"Someone was still humming the feast song while scraping out the bowls."
		),
		_remembered(
			&"dried_food", &"food_dried",
			"Dried meat hung along the cave wall, and the whole cave smelled of smoke and berries."
		),
		_remembered(
			&"seat_by_the_fire", &"fire_turns",
			"The best seat by the fire went to someone new tonight, as agreed."
		),
		_remembered(
			&"mammoth_far_edge", &"mammoth_distant",
			"The mammoth watched the camp from the far edge of the grass, and the camp watched back."
		),
		_remembered(
			&"knee_rhythm", &"work_quiet",
			"Someone tapped a rhythm on their knee while they worked, and it was nobody's but theirs."
		),
		_remembered(
			&"ridge_in_the_rain", &"ridge_watched",
			"Someone at the lookout was looking at the ridge again, even in the rain."
		),
		_remembered(
			&"warm_and_crowded", &"shared_cave",
			"It was crowded in the cave tonight, and warm, and nobody minded."
		),
		_remembered(
			&"bank_held", &"trusted_bank",
			"The river was high again. Everyone looked at the bank, and the bank held."
		),
		_remembered(
			&"ledge_stores", &"stores_on_ledge",
			"The stores on the ledge were dry and in easy reach, and everyone was quietly pleased."
		),
		_remembered(
			&"limp_on_the_far_bank", &"deer_left",
			"A deer was seen on the far bank, favouring one leg, and then it was not."
		),
		_remembered(
			&"traveller_word", &"meal_shared",
			"Someone used a word the traveller had said, and was understood by nobody."
		),
		_remembered(
			&"red_eyes", &"smoky_cave",
			"Everyone's eyes were red from the smoke, and everyone laughed about it."
		),
		_remembered(
			&"stars_through_the_roof", &"smoke_hole",
			"The stars showed through the gap in the roof, and the smoke went up to meet them."
		),
		_remembered(
			&"hide_floor_warm", &"hide_floor",
			"Bare feet came down warm on the hide floor, and someone said how good it felt."
		),
		_remembered(
			&"reeds_rustle", &"reed_beds",
			"The reed beds rustled all night, and someone swore they could hear the river in them."
		),
		_remembered(
			&"wrestle_again", &"wrestled",
			"Two of the group wrestled by the fire again, for nothing at all, and both won."
		),
		_remembered(
			&"lost_things", &"searched_together",
			"Somebody turned up another thing that had been lost since the big search."
		),
		_remembered(
			&"torch_at_the_mouth", &"torch_at_mouth",
			"The torch at the cave mouth burned low, and someone got up to trim it."
		),
		_remembered(
			&"back_of_the_cave", &"deep_sleepers",
			"It was very quiet at the back of the cave, and everyone slept late."
		),
		_remembered(
			&"stones_in_the_river", &"stepping_stones",
			"Someone crossed the stepping stones with a full basket, not looking down once."
		),
		_remembered(
			&"log_bridge_creaks", &"log_bridge",
			"The log over the river creaked under three people at once, and held."
		),
		_remembered(
			&"feather_in_hair", &"feather_worn",
			"The blue feather in someone's hair caught the light, and they stood a little taller."
		),
		_remembered(
			&"feather_over_the_fire", &"feather_shared",
			"The blue feather above the fire turned in the warm air, and everyone looked up."
		),
		_remembered(
			&"bats_leave_dusk", &"bats_kept",
			"The bats went out at dusk in a long stream, and the midges did not come."
		),
		_remembered(
			&"smoked_cave", &"bats_smoked",
			"The back of the cave smelled of green smoke for days, and was quiet."
		),
		_remembered(
			&"honey_again", &"honey_taken",
			"Someone was still picking wax out of their hair, and refused to regret it."
		),
		_remembered(
			&"bees_still_there", &"honey_shared",
			"The bee tree hummed on in the western wood, and someone nodded to it passing."
		),
		_remembered(
			&"wet_and_laughing", &"fish_by_hand",
			"Someone was still telling the story of the day everyone went into the river."
		),
		_remembered(
			&"trap_in_the_channel", &"fish_trap",
			"The willow trap in the channel was checked at dawn, and was not empty."
		),
		_remembered(
			&"shells_in_pockets", &"shellfish_gathered",
			"Someone was still finding small shells in their sleeves, and not minding."
		),
		_remembered(
			&"salt_in_the_fire", &"driftwood_gathered",
			"The driftwood burned blue and green at the edges, and everyone watched it."
		),
		_at_low_tide(_ambient(
			&"tide_out", "The tide was out, and the far sand shone wet to the edge of the sky.", 60
		)),
		_remembered(
			&"drum_in_the_valley", &"log_drum",
			"The drum sounded across the valley at dusk, and something answered far off."
		),
		_remembered(
			&"pipe_at_night", &"bone_pipe",
			"A thin pipe tune drifted over the camp, and everyone pretended not to listen."
		),
		_remembered(
			&"snow_figure_stands", &"snow_figure",
			"The snow figure at the cave mouth was still standing, a little lopsided."
		),
		_remembered(
			&"unknown_tracks", &"snow_tracks",
			"Someone drew the unnamed track in the dirt, and nobody could say what made it."
		),
		_remembered(
			&"echo_game", &"echo_games",
			"Someone shouted a nonsense word into the back of the cave, and the cave shouted it back."
		),
		_remembered(
			&"echo_whisper", &"echo_whispers",
			"A whisper came out of the back of the cave, and everyone looked round to see whose."
		),
		_remembered(
			&"stone_by_the_fire", &"sky_stone_kept",
			"The black stone by the fire was warm to the touch long after the fire had burned low."
		),
		_remembered(
			&"ring_of_white", &"sky_stone_marked",
			"Someone walked out to the ring of white stones in the meadow, and stood a while."
		),
		_remembered(
			&"steam_up_the_valley", &"warm_pool_used",
			"A column of steam stood over the pool up the valley, and somebody was already walking to it."
		),
		_remembered(
			&"warm_feet", &"warm_bags",
			"Everyone slept with a bag of warm water at their feet, and not one was cold."
		),
	]
	return lines


## A story decision: needs the fire and the day, is asked once, and is not about anyone.
func _story(
	event_id: StringName, title: String, category: StringName, day: int, body: String,
	chance: float = STORY_CHANCE
) -> EventDef:
	var event: EventDef = _event(event_id, title, category)
	event.body = body
	event.requires = _conds([
		_cond(SimCondition.Kind.FLAG_SET, &"fire_found"),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", day),
	])
	event.chance_per_tick = chance
	event.once = true
	return event


## A story decision about one villager at home; anyone can be it, a trait makes a villager likelier.
func _story_about(
	event_id: StringName, title: String, category: StringName, day: int, body: String,
	favoured: StringName
) -> EventDef:
	var event: EventDef = _story(event_id, title, category, day, body)
	event.needs_subject = true
	event.subject_requires = _conds([_cond(SimCondition.Kind.SUBJECT_AT_HOME)])
	event.trait_weights[favoured] = 3.0
	return event


## One answer to a story decision. The journal line is always written; `effects` come first.
func _answer(
	choice_id: StringName, label: String, line: String, effects: Array[SimEffect] = [],
	needs: Array[SimCondition] = []
) -> ChoiceDef:
	var choice: ChoiceDef = _choice(choice_id, label)
	choice.requires = needs
	var all: Array[SimEffect] = []
	all.append_array(effects)
	all.append(_eff(SimEffect.Kind.JOURNAL, &"", 0, line))
	choice.effects = all
	return choice


func _has(resource: StringName, amount: int) -> SimCondition:
	return _cond(SimCondition.Kind.RESOURCE_AT_LEAST, resource, amount)


func _spend(resource: StringName, amount: int) -> SimEffect:
	return _eff(SimEffect.Kind.ADD_RESOURCE, resource, -amount)


func _ambient(event_id: StringName, line: String, from_day: int = 0) -> EventDef:
	var event: EventDef = _event(event_id, "A quiet moment", &"nature")
	event.requires = _conds([_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", from_day)])
	event.chance_per_tick = AMBIENT_CHANCE
	event.cooldown_ticks = AMBIENT_COOLDOWN
	event.effects = _effs([_eff(SimEffect.Kind.JOURNAL, &"", 0, line)])
	return event


func _ambient_about(event_id: StringName, trait_name: StringName, line: String) -> EventDef:
	var event: EventDef = _ambient(event_id, line)
	event.category = &"character"
	event.needs_subject = true
	event.subject_requires = _conds([
		_cond(SimCondition.Kind.SUBJECT_HAS_TRAIT, trait_name),
		_cond(SimCondition.Kind.SUBJECT_AT_HOME),
		_cond(SimCondition.Kind.SUBJECT_AWAKE),
	])
	return event


## A line that only happens once an earlier answer set `flag`.
func _remembered(event_id: StringName, flag: StringName, line: String) -> EventDef:
	var event: EventDef = _ambient(event_id, line)
	event.requires.append(_cond(SimCondition.Kind.FLAG_SET, flag))
	return event


## The Settled Age's one-line moments. They carry the age's feel (roofs, fields and herds, pots and
## cloth), several only for the group's path or an earlier answer, and each is a little rarer than
## the Cave Age's because those keep happening too.
func _settled_ambient_lines() -> Array[EventDef]:
	var roofs: Array[SimCondition] = [_earned(&"first_roof")]
	var farmers: Array[SimCondition] = [_flag_set(&"path_agriculture")]
	var herders: Array[SimCondition] = [_flag_set(&"path_herding")]
	return [
		_settled_ambient(
			&"smoke_from_roofs",
			"On still mornings the smoke stood straight up from every roof, each in its own thread.",
			roofs
		),
		_settled_ambient(
			&"swallows",
			"The swallows came back to the eaves, as if the roofs had been built for them.", roofs
		),
		_settled_ambient(
			&"dogs_at_dusk", "The dogs barked at dusk, and somebody answered from the next roof."
		),
		_settled_ambient(
			&"harvest_moon",
			"The moon came up huge and orange over the fields, and work went on by its light."
		),
		_settled_ambient(
			&"worn_path",
			"A path has worn itself between the huts and the river, deep enough to hold the rain."
		),
		_settled_ambient(
			&"smell_of_bread",
			"The smell of flat bread on hot stones drifted over the camp, and people found reasons "
			+ "to pass by.",
			[_earned(&"first_harvest")]
		),
		_settled_ambient(
			&"pots_ring",
			"Someone tapped a pot to hear it ring, and then every pot in the camp had to be tapped.",
			[_earned(&"fired_clay")]
		),
		_settled_ambient(
			&"spindle_turns",
			"A spindle turned in the shade, and the thread grew longer than anyone had noticed.",
			[_earned(&"woven_cloth")]
		),
		_settled_ambient(
			&"rain_on_the_field",
			"Rain came soft and steady all day, and everyone stood in a doorway to watch it fall "
			+ "on the field.",
			farmers
		),
		_settled_ambient(
			&"bleating_at_night",
			"Bleating came across the fold all night. Nobody minded; it meant the herd was there.",
			herders
		),
		_settled_ambient_about(
			&"counting_roofs", VillagerState.TRAIT_CURIOUS,
			"{subject} counted the roofs twice and got two different answers, and counted them "
			+ "a third time."
		),
		_settled_ambient_about(
			&"everyones_business", VillagerState.TRAIT_SOCIAL,
			"{subject} knew everyone's business by noon, and shared it generously."
		),
		_settled_ambient_about(
			&"same_fence", VillagerState.TRAIT_INDUSTRIOUS,
			"{subject} mended the same fence three times in a week, and was not satisfied."
		),
		_settled_ambient_about(
			&"flower_corner", VillagerState.TRAIT_NATURE_LOVING,
			"{subject} sowed one corner of the field with flowers, and nobody had the heart to say "
			+ "anything."
		),
		_settled_ambient_about(
			&"with_the_herd", VillagerState.TRAIT_NATURE_LOVING,
			"{subject} sat with the herd until dark, and said that they were good company.",
			herders
		),
		_settled_remembered(
			&"stores_in_the_cave", &"cave_store",
			"Someone went up to the cave for the winter store, and came back sneezing from the dust."
		),
		_settled_remembered(
			&"well_water", &"well_dug",
			"The water from the new well tasted of stone, and everyone agreed it was better."
		),
		_settled_remembered(
			&"scarecrow_hat", &"scarecrow",
			"The scarecrow was wearing a different hat this morning, and nobody owned up."
		),
		_settled_remembered(
			&"festival_tune", &"festival",
			"Someone began humming the festival tune, and was joined within a bar."
		),
		_settled_remembered(
			&"kiln_night", &"kiln",
			"The kiln was lit, and for a night the whole camp smelled of hot clay."
		),
		_settled_remembered(
			&"red_tunic", &"dyed_cloth",
			"A red tunic crossed the field, and everyone stopped to watch it go."
		),
		_settled_remembered(
			&"wall_at_dusk", &"low_wall",
			"Someone leaned on the low wall at dusk and looked toward the hills for a long time."
		),
		_settled_remembered(
			&"beads_clicking", &"green_beads",
			"Green beads clicked softly as people walked, a small sound the whole camp shared."
		),
		_settled_remembered(
			&"hands_in_the_soil", &"hand_dug",
			"Someone straightened up from the digging with a hand on their back, and groaned."
		),
		_settled_remembered(
			&"pot_under_the_drip", &"leaky_roofs",
			"A pot sat under the drip again, and someone said it was time to see about the roof."
		),
		_settled_remembered(
			&"water_carriers", &"well_carriers",
			"Two people came up from the river with full pots, arguing about whose turn it was."
		),
		_settled_remembered(
			&"birds_scattered", &"field_watchers",
			"A flock of birds went up from the field, and so did a shout."
		),
		_settled_remembered(
			&"dog_on_the_hill", &"dog_at_a_distance",
			"A dog sat on the hill above the fold, watching the herd, and did not come closer."
		),
		_settled_remembered(
			&"swallows_in_the_rafters", &"hanging_baskets",
			"A swallow flew in and out of the rafters, past the hanging baskets, as if it owned them."
		),
		_settled_remembered(
			&"quiet_neighbours", &"cooled_off",
			"Two neighbours nodded to each other over the fence, and nothing at all was said."
		),
		_settled_remembered(
			&"full_stores", &"laid_by",
			"Somebody checked the stores again, found them full, and was visibly cheered."
		),
		_settled_remembered(
			&"short_story", &"short_tale",
			"One of the youngest asked for the rest of the story, and was told, \"Later.\""
		),
		_settled_remembered(
			&"cracked_pot", &"ash_baking",
			"A pot cracked in the ashes, and was turned into a very good lid."
		),
		_settled_remembered(
			&"pond_remembered", &"waited_out_rain",
			"Someone mentioned the pond of the wet summer, and everyone looked at the low ground."
		),
		_settled_remembered(
			&"hens_on_the_roofs", &"wild_fowl_left",
			"The small brown birds argued on a roof all morning, and nobody could say about what."
		),
		_settled_remembered(
			&"undyed_cloth", &"plain_cloth",
			"A plain tunic hung on the line, pale as milk, and entirely satisfied with itself."
		),
		_settled_remembered(
			&"spindle_whirr", &"spindle_only",
			"A spindle whirred by a doorway, and the thread coming off it was very even."
		),
		_settled_remembered(
			&"high_ground_stores", &"moved_to_high_ground",
			"The stores sat a little higher than before, and everyone had remembered why."
		),
		_settled_remembered(
			&"smoke_watchers", &"waited_for_visitors",
			"Someone looked toward the ridge for the smoke again, and then for visitors."
		),
		_settled_remembered(
			&"pots_on_the_shelf", &"pots_kept",
			"The best pots stood in a row on the shelf, and were taken down only for guests."
		),
		_settled_remembered(
			&"stores_trusted", &"trusted_stores",
			"The stores were counted, found enough, and left alone."
		),
		_settled_remembered(
			&"bats_in_the_cave", &"cave_left_alone",
			"Bats went out of the old cave at dusk, in a long dark stream over the roofs."
		),
		_settled_remembered(
			&"thatch_dry", &"thatched_roofs",
			"The rain drummed on the thatch, and the thatch said nothing, and stayed dry."
		),
		_settled_remembered(
			&"turf_in_flower", &"turf_roofs",
			"A small flower had come up on one of the turf roofs, and nobody wanted to pull it."
		),
		_settled_remembered(
			&"calves_in_the_pen", &"calves_penned",
			"The calves in the pen leaned against the rails and watched the camp go by."
		),
		_settled_remembered(
			&"calves_on_the_meadow", &"calves_grazing",
			"The watcher brought the calves home from the far meadow, singing something tuneless."
		),
		_settled_remembered(
			&"pot_rings", &"pot_fired",
			"Someone tapped the first pot with a fingernail, just to hear it ring."
		),
		_settled_remembered(
			&"dish_on_the_stones", &"dish_baked",
			"A flat dish of baked clay held the fish, and was washed in the river after."
		),
		_settled_remembered(
			&"ash_bowls", &"bowls_in_ash",
			"Bowls came out of the ashes with a grey bloom on them, and rang when they were tapped."
		),
		_settled_remembered(
			&"pit_bowls", &"bowls_in_pit",
			"The bowls from under the cook fire came out whole, every one, and nobody said a word."
		),
		_settled_remembered(
			&"flax_thread_spun", &"flax_thread",
			"A long grey thread of flax came off a stick, finer than yesterday's."
		),
		_settled_remembered(
			&"stiff_cloth", &"flax_beaten",
			"The coarse flax cloth stood up by itself in the corner, and was somehow admired."
		),
		_settled_remembered(
			&"wool_spun_fine", &"wool_spun",
			"Wool thread twisted down a spindle, and a ball of it grew in somebody's lap."
		),
		_settled_remembered(
			&"felt_boots", &"wool_felted",
			"Someone tried on a pair of felt boots, stamped, and refused to take them off."
		),
		_settled_remembered(
			&"reed_lessons", &"reed_teachers",
			"Over and under, over and under: someone was teaching a younger child to plait."
		),
		_settled_remembered(
			&"fine_plait", &"fine_plaiting",
			"A band of fine plaiting went round someone's wrist, with a grass thread through it."
		),
		_settled_remembered(
			&"elders_remember", &"bead_shown",
			"One of the elders turned a green bead in her fingers, and said she knew a stream."
		),
		_settled_remembered(
			&"traders_return", &"traders_asked",
			"Someone looked down the road for the traveller, and then looked again."
		),
		_settled_remembered(
			&"families_inside", &"families_taken_in",
			"The new families laughed loudly in the hut, and the old ones laughed back."
		),
		_settled_remembered(
			&"river_roof", &"families_by_the_river",
			"Smoke rose from the roof by the river, and a child ran between the two camps with a message."
		),
		_settled_remembered(
			&"long_table_set", &"long_table",
			"The long boards were set out again in the dusk, and the whole village found a seat."
		),
		_settled_remembered(
			&"one_dish_each", &"dish_supper",
			"A dozen different dishes came to the old fire, and every one was tasted by every one."
		),
		_settled_remembered(
			&"flat_stone_door", &"door_stones",
			"Someone scraped their feet on the flat stone at the door, out of habit, and went in."
		),
		_settled_remembered(
			&"mat_at_the_door", &"door_mats",
			"A reed mat at the door had worn a little in the middle, in the shape of a foot."
		),
		_settled_remembered(
			&"hill_fire_remembered", &"midsummer_hill",
			"Someone looked up at the hill and remembered the fire that had burned there all night."
		),
		_settled_remembered(
			&"hearth_all_night", &"midsummer_hearth",
			"Someone yawned at the hearth and said that they had sat up for the sun once."
		),
		_settled_remembered(
			&"small_helpers", &"young_helpers",
			"A small child carried a very large basket, very seriously, across the yard."
		),
		_settled_remembered(
			&"sheaf_fort", &"sheaf_fort",
			"The children's fort of sheaves had been rebuilt, bigger, in the corner of the field."
		),
		_settled_remembered(
			&"gong_stone", &"fog_gong",
			"The hanging stone rang once on the wind, with nobody near it."
		),
		_settled_remembered(
			&"rope_between_huts", &"fog_rope",
			"The old rope still hung between two huts, and children swung on it."
		),
		_settled_remembered(
			&"told_in_turns", &"evening_tales",
			"Someone asked for the story the oldest one told in the long evenings."
		),
		_settled_remembered(
			&"mending_evening", &"evening_work",
			"A pile of mending sat by the fire, half done, and talk was going over it like water."
		),
		_settled_remembered(
			&"dugout_at_the_bank", &"dugout_canoe",
			"The dugout rocked at the bank, and every child had been told twice to stay out of it."
		),
		_settled_remembered(
			&"raft_poled_over", &"reed_raft",
			"The reed raft was poled across and back, low in the water, with a lot of laughing."
		),
		_settled_remembered(
			&"weir_full", &"tide_weir",
			"The stone weir on the flats held a silver heap of fish, and the gulls complained."
		),
		_settled_remembered(
			&"baskets_at_the_turn", &"tide_baskets",
			"Somebody waded out at the turn of the tide with a basket, and came back wet to the "
			+ "waist."
		),
		_at_low_tide(_settled_ambient(
			&"gulls_on_the_flats",
			"Gulls stood in rows on the wet flats, all facing the water, all waiting for it."
		)),
	]


## A Settled Age line: only in the age, rarer than a Cave Age line, and only when every one of
## `needs` holds.
func _settled_ambient(
	event_id: StringName, line: String, needs: Array[SimCondition] = []
) -> EventDef:
	var event: EventDef = _ambient(event_id, line)
	event.requires = _conds([_cond(SimCondition.Kind.ERA_AT_LEAST, &"", SETTLED)])
	event.requires.append_array(needs)
	event.chance_per_tick = SETTLED_AMBIENT_CHANCE
	return event


func _settled_ambient_about(
	event_id: StringName, trait_name: StringName, line: String, needs: Array[SimCondition] = []
) -> EventDef:
	var event: EventDef = _settled_ambient(event_id, line, needs)
	event.category = &"character"
	event.needs_subject = true
	event.subject_requires = _conds([
		_cond(SimCondition.Kind.SUBJECT_HAS_TRAIT, trait_name),
		_cond(SimCondition.Kind.SUBJECT_AT_HOME),
		_cond(SimCondition.Kind.SUBJECT_AWAKE),
	])
	return event


func _settled_remembered(event_id: StringName, flag: StringName, line: String) -> EventDef:
	return _settled_ambient(event_id, line, [_flag_set(flag)])


## ---- The Bronze Age (docs/ages.md, "Bronze Age: design proposal") ---------------------------------
## Metal, trade, walls and the first towns. Like the Settled Age: six hidden milestones staged over
## the age (`BRONZE_DAY`), each with more than one road and one road open to every group, small forks
## between them and quiet lines. Every decision is a fork (docs/gameplay.md P13). The path chosen at
## the turn decides which roads to the first milestone come first; later ones read what the group
## answered in the Settled Age (`low_wall`, `open_village`, `good_neighbours`, `salt`, `kiln`...).
## Nothing here is shown to the player as a goal.

const BRONZE_TITLES: Dictionary = {
	&"first_casting": "The First Casting",
	&"bronze_alloy": "Bronze",
	&"mud_brick_walls": "Mud-brick Walls",
	&"wheel_and_road": "The Wheel and the Road",
	&"a_town": "A Town",
	&"beyond_the_water": "Beyond the Water",
}


func _bronze_events() -> Array[EventDef]:
	var events: Array[EventDef] = [_the_metals_road(), _bronze_building_opportunity()]
	events.append_array(_bronze_milestones())
	events.append_array(_bronze_stories())
	events.append_array(_bronze_ambient_lines())
	events.append(_the_quay())
	return events


## The turn from the Settled Age to the Bronze Age. Fired by the era's hidden gate, so the player is
## never asked whether to go on, only how to work the green stone.
func _the_metals_road() -> EventDef:
	var event: EventDef = _event(&"the_metals_road", "The metal's road", &"settlement")
	event.body = "The green stone has been in the fire so often that nobody is surprised by what " \
			+ "comes out of it any more. The only question left is where to take it from here."
	event.choices = _choices([
		_answer(
			&"work_it_here", "Work it here, at a hearth by the old kiln",
			"A hearth was built beside the kiln, and the first thing it made was smoke, a great "
			+ "deal of it.",
			[_set_flag(&"path_smithing"), _eff(SimEffect.Kind.ADVANCE_ERA, &"bronze")],
		),
		_answer(
			&"follow_it_to_the_source", "Follow the stone to where it comes from",
			"Two villagers went up the stream with empty sacks and came back a week later with "
			+ "full ones and a great many opinions.",
			[_set_flag(&"path_trading"), _eff(SimEffect.Kind.ADVANCE_ERA, &"bronze")],
		),
	])
	return event


func _bronze_building_opportunity() -> EventDef:
	var event: EventDef = _event(&"bronze_building_opportunity", "Building a town", &"settlement")
	event.body = "The old workshops are too small for what the group has in mind."
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", BRONZE),
		_cond(SimCondition.Kind.CONSTRUCTION_IDLE),
		_cond(SimCondition.Kind.RESOURCE_AT_LEAST, &"wood", 14),
	])
	event.chance_per_tick = 0.5
	event.cooldown_ticks = 24
	event.choices = _choices([
		_build_choice(
			&"build_smithy", "Smithy", &"smithy", 16, 0, BRONZE_DAY[&"first_casting"]
		),
		_build_choice(
			&"build_trading_post", "Trading Post", &"trading_post", 14, 0,
			BRONZE_DAY[&"first_casting"]
		),
	])
	return event


## Every Bronze milestone event: Bronze Age, far enough into it, and not yet earned.
func _bronze_milestone(
	event_id: StringName, title: String, category: StringName, favoured: StringName,
	era_day: int, milestone: StringName
) -> EventDef:
	var event: EventDef = _milestone_event(event_id, title, category, favoured)
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", BRONZE),
		_cond(SimCondition.Kind.ERA_DAYS_AT_LEAST, &"", era_day),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, milestone, 0, true),
	])
	return event


## One road to a Bronze milestone: the answer sets its own flag, may do something else, and earns it.
func _route(
	choice_id: StringName, label: String, line: String, flag: StringName,
	milestone: StringName, extra: Array[SimEffect] = [], needs: Array[SimCondition] = []
) -> ChoiceDef:
	var effects: Array[SimEffect] = [_set_flag(flag)]
	effects.append_array(extra)
	effects.append(_earn(milestone, BRONZE_TITLES[milestone]))
	return _answer(choice_id, label, line, effects, needs)


## A decision that is a road to a milestone; `needs` are further requirements on the event.
func _bronze_road(
	event_id: StringName, title: String, body: String, milestone: StringName, era_day: int,
	favoured: StringName, answers: Array[ChoiceDef], needs: Array[SimCondition] = [],
	category: StringName = &"settlement"
) -> EventDef:
	var event: EventDef = _bronze_milestone(event_id, title, category, favoured, era_day, milestone)
	event.body = body
	event.requires.append_array(needs)
	event.choices = _choices(answers)
	return event


func _bronze_milestones() -> Array[EventDef]:
	var events: Array[EventDef] = []
	events.append_array(_first_casting_roads())
	events.append_array(_bronze_alloy_roads())
	events.append_array(_mud_brick_wall_roads())
	events.append_array(_wheel_and_road_roads())
	events.append_array(_town_roads())
	events.append_array(_beyond_the_water_roads())
	return events


## The First Casting. The Smithy is one road (it earns it on completion); a mould at the kiln is the
## smithing path's, a smith who comes by the road the trading path's, and beating the stone flat is
## open to every group. The path not taken still gets its road, a little later.
func _first_casting_roads() -> Array[EventDef]:
	var day: int = BRONZE_DAY[&"first_casting"]
	var milestone: StringName = &"first_casting"
	return [
		_first_pour(&"first_pour", day, &"path_smithing"),
		_first_pour(&"first_pour_slow", day + 30, &"path_trading"),
		_bronze_road(
			&"smith_over_the_ridge", "A stranger with a leather roll",
			"A stranger has come over the ridge with a roll of tools and a great deal of interest "
			+ "in the green stone. Where they come from, they say, metal has been cast for years.",
			milestone, day, VillagerState.TRAIT_SOCIAL, [
				_route(
					&"let_them_work", "Let them work at the kiln",
					"The stranger worked at the kiln for two days and talked the whole time. "
					+ "By the second night there was a blade, and everyone had held it.",
					&"visiting_smith", milestone,
				),
				_route(
					&"copy_the_smith", "Watch from a distance, and copy what they do",
					"The group watched from a polite distance, and by the end of the week was "
					+ "casting things a little worse than the stranger and a good deal prouder.",
					&"copied_the_smith", milestone,
				),
			], [_flag_set(&"good_neighbours")]
		),
		_bronze_road(
			&"smith_on_the_road", "A traveller from the coast",
			"A woman following the road up from the coast says she can make bright metal from "
			+ "the green stone, if there is a hot fire and a clay mould.",
			milestone, day + 12, VillagerState.TRAIT_SOCIAL, [
				_route(
					&"lend_the_kiln", "Give her the kiln for a day",
					"The kiln was hers for a day. The smoke was green, then black, then gone, and "
					+ "she walked out holding a blade by the wrong end, which she said was the "
					+ "right end.",
					&"road_smith", milestone,
				),
				_route(
					&"pay_to_be_taught", "Pay her in food, and ask her to teach",
					"She was paid in food and taught the whole group in an afternoon, and left "
					+ "before anyone had thought of a good question.",
					&"taught_by_the_road", milestone, [_spend(&"food", 6)],
					[_has(&"food", 6)],
				),
			], [_flag_set(&"path_trading")]
		),
		_bronze_road(
			&"hammered_flat", "Beaten thin as a leaf",
			"{subject} has been beating a lump of the green stone flat on a river cobble. It does "
			+ "not crack. It gets as thin as a leaf, and shines.",
			milestone, day + 36, VillagerState.TRAIT_CURIOUS, [
				_route(
					&"keep_beating", "Keep beating, and see how thin it goes",
					"{subject} beat it until it was thin enough to see the fire through, and "
					+ "then, to everyone's alarm, folded it.",
					&"beaten_thin", milestone,
				),
				_route(
					&"cut_a_charm", "Cut a shape from it, and wear it",
					"{subject} cut a small bright leaf from the sheet and hung it on a cord, and "
					+ "for a week nobody could look anywhere else.",
					&"cut_a_charm", milestone,
				),
			], [], &"character"
		),
	]


func _first_pour(event_id: StringName, era_day: int, path: StringName) -> EventDef:
	var milestone: StringName = &"first_casting"
	return _bronze_road(
		event_id, "A mould in the kiln",
		"{subject} has pressed a hollow into a block of clay and baked it hard. It is shaped, "
		+ "roughly, like an axe. All it needs is the green stone, made liquid.",
		milestone, era_day, VillagerState.TRAIT_CURIOUS, [
			_route(
				&"pour_while_hot", "Pour while the kiln is still hot",
				"{subject} poured the bright liquid into the mould while the whole village held "
				+ "its breath. It came out a blade, a little lopsided and entirely beautiful.",
				&"cast_hot", milestone,
			),
			_route(
				&"let_it_cool", "Let it cool, then break the mould open",
				"The mould sat overnight. In the morning {subject} broke it open and there it "
				+ "was, a blade, with the print of the clay still on it.",
				&"cast_cool", milestone,
			),
		], [_flag_set(path)], &"character"
	)


## Bronze. Tin has to come from somewhere else (needs the First Casting): the Trading Post's first
## load, a trip to the hills, a gift from the neighbours, the coast trader, or, late and for every
## group, panning the stream.
func _bronze_alloy_roads() -> Array[EventDef]:
	var day: int = BRONZE_DAY[&"bronze_alloy"]
	var milestone: StringName = &"bronze_alloy"
	return [
		_bronze_road(
			&"first_load", "The first load up the road",
			"The first load of grey sand has come up the road in sacks, and the carrier is sure "
			+ "it is the missing half of the metal.",
			milestone, day, VillagerState.TRAIT_SOCIAL, [
				_route(
					&"pay_the_carrier", "Pay the carrier in food",
					"The carrier was paid in food and the sand was mixed into the next pour. What "
					+ "came out was harder, and the colour of a warm autumn.",
					&"tin_bought", milestone, [_spend(&"food", 8)], [_has(&"food", 8)],
				),
				_route(
					&"promise_a_load", "Promise a load of the next harvest",
					"A load of next harvest was promised, and the carrier wrote it down on a "
					+ "stick. The metal that came out of the pour was hard, and slightly in debt.",
					&"tin_owed", milestone,
				),
			], [_earned(&"first_casting"), _cond(SimCondition.Kind.HAS_BUILDING, &"trading_post")]
		),
		_bronze_road(
			&"tin_in_the_hills", "Heavy grey sand",
			"There is a place in the hills where the stream runs over heavy grey sand, and "
			+ "{subject} thinks it is what the metal has been missing.",
			milestone, day, VillagerState.TRAIT_CURIOUS, [
				_route(
					&"go_up_together", "Go up together, with baskets",
					"They went up together with baskets, and came down singing, and a great deal "
					+ "heavier.",
					&"tin_dug", milestone,
				),
				_route(
					&"go_up_alone", "Let them go alone, and wait",
					"{subject} went alone and was gone for six days. The sand was heavy, and the "
					+ "stories were heavier.",
					&"tin_alone", milestone,
				),
			], [_earned(&"first_casting")], &"exploration"
		),
		_bronze_road(
			&"neighbours_bring_tin", "The neighbours come back",
			"The neighbours from beyond the ridge have come back, and this time they have brought "
			+ "a bag of heavy grey sand and a clear idea of what to do with it.",
			milestone, day, VillagerState.TRAIT_SOCIAL, [
				_route(
					&"sit_by_the_fire", "Ask them to stay by the fire",
					"They stayed by the fire and mixed the sand into the pour themselves, "
					+ "explaining every step twice.",
					&"neighbours_stayed", milestone,
				),
				_route(
					&"send_them_home_fed", "Send them home with food",
					"They went home fed, and left the sand and the instructions behind.",
					&"neighbours_fed", milestone, [_spend(&"food", 4)], [_has(&"food", 4)],
				),
			], [_earned(&"first_casting"), _flag_set(&"good_neighbours")]
		),
		_bronze_road(
			&"coast_trader_tin", "The coast trader, with something heavy",
			"The trader from the coast is back, and the sacks on her donkey are small and "
			+ "surprisingly heavy.",
			milestone, day, VillagerState.TRAIT_SOCIAL, [
				_route(
					&"tin_for_grain", "Trade grain for it",
					"The grain went off on the donkey and the heavy sacks stayed. The trader "
					+ "looked like someone who had improved on the arrangement.",
					&"tin_for_grain", milestone, [_spend(&"food", 6)], [_has(&"food", 6)],
				),
				_route(
					&"tin_for_cloth", "Trade a bolt of cloth for it",
					"The cloth was unrolled in the road and measured twice. The sacks were "
					+ "handed over with a bow.",
					&"tin_for_cloth", milestone,
				),
			], [_earned(&"first_casting"), _flag_set(&"salt")]
		),
		_bronze_road(
			&"panned_in_the_stream", "Heavy grains in the stream",
			"Somebody has been washing the stream sand in a flat dish, and keeps finding the same "
			+ "heavy grey grains at the bottom of it.",
			milestone, BRONZE_DAY[&"panning"], VillagerState.TRAIT_NATURE_LOVING, [
				_route(
					&"wash_all_day", "Wash a whole day's sand",
					"A whole day's sand was washed, and the dish at the end of it held a spoonful "
					+ "of heavy grains and a great many damp feet.",
					&"panned_all_day", milestone,
				),
				_route(
					&"wash_each_morning", "Wash a little every morning",
					"A little sand was washed every morning before anyone was properly awake, and "
					+ "by the end of the month there was enough.",
					&"panned_each_morning", milestone,
				),
			], [_earned(&"first_casting")]
		),
	]


## Mud-brick Walls. A wall in the spirit of the Settled Age's answer to how far the village goes
## (heightened if it is low already, raised new if it is not), a ditch and a bank for everyone.
func _mud_brick_wall_roads() -> Array[EventDef]:
	var day: int = BRONZE_DAY[&"mud_brick_walls"]
	var milestone: StringName = &"mud_brick_walls"
	return [
		_bronze_road(
			&"heighten_the_wall", "Higher than a child",
			"The low wall of fieldstones is exactly as high as a child, and that has proved to be "
			+ "a bad height for a wall.",
			milestone, day, VillagerState.TRAIT_INDUSTRIOUS, [
				_route(
					&"raise_it_in_brick", "Raise it in mud-brick",
					"Mud-brick went up on the old stones, row on row, and the wall stopped being "
					+ "something to sit on.",
					&"town_wall", milestone, [_spend(&"wood", 12)], [_has(&"wood", 12)],
				),
				_route(
					&"top_it_with_stakes", "Top it with a palisade",
					"Sharpened stakes went along the top, each one a little different, and the "
					+ "wall bristled like a hedgehog.",
					&"palisade", milestone, [_spend(&"wood", 8)], [_has(&"wood", 8)],
				),
			], [_flag_set(&"low_wall")]
		),
		_bronze_road(
			&"ring_the_village", "A line round the houses",
			"The village is open on every side, and the paths go out from it like the spokes of a "
			+ "wheel. Someone would like to know where it stops.",
			milestone, day, VillagerState.TRAIT_INDUSTRIOUS, [
				_route(
					&"raise_a_new_wall", "Raise a wall of mud-brick",
					"A wall of mud-brick went round the village, and for the first time it had an "
					+ "inside.",
					&"town_wall", milestone, [_spend(&"wood", 24)], [_has(&"wood", 24)],
				),
				_route(
					&"plant_a_palisade", "Plant a palisade with a gate",
					"A palisade of split trunks went round the village, with a gate that took "
					+ "four people to open and three to agree about.",
					&"palisade", milestone, [_spend(&"wood", 14)], [_has(&"wood", 14)],
				),
			], [_cond(SimCondition.Kind.FLAG_SET, &"low_wall", 0, true)]
		),
		_bronze_road(
			&"ditch_and_bank", "A ditch and a bank",
			"Nobody has the wood for a wall just now, but everybody has a spade.",
			milestone, BRONZE_DAY[&"ditch"], VillagerState.TRAIT_INDUSTRIOUS, [
				_route(
					&"dig_it_deep", "Dig it deep, and heap the earth inside",
					"The ditch went down as deep as a tall person, and the bank grew behind it. "
					+ "The first rain filled it, and the children were thrilled.",
					&"dug_deep", milestone, [_set_flag(&"dug_in")],
				),
				_route(
					&"dig_it_wide", "Dig it wide, and let the water in",
					"The ditch was dug wide and let the river in at one end, and the village sat "
					+ "on an island that no one had planned.",
					&"dug_wide", milestone, [_set_flag(&"dug_in")],
				),
			]
		),
	]


## The Wheel and the Road. A cart, pack animals, a hard road toward the hills, and, late for every
## group, rollers and rope.
func _wheel_and_road_roads() -> Array[EventDef]:
	var day: int = BRONZE_DAY[&"wheel_and_road"]
	var milestone: StringName = &"wheel_and_road"
	return [
		_bronze_road(
			&"a_cart", "Something that rolls",
			"{subject} has been rolling a cut section of trunk down the hill and chasing it. It "
			+ "occurs to {subject} that something could sit on it.",
			milestone, day, VillagerState.TRAIT_INDUSTRIOUS, [
				_route(
					&"solid_wheels", "Cut solid wheels from a trunk",
					"Two heavy discs were cut from a trunk and an axle run through them. It "
					+ "creaked, and it rolled, and it was carrying firewood before it was finished.",
					&"cart_solid", milestone, [_set_flag(&"cart")],
				),
				_route(
					&"spoked_wheels", "Try spokes, the way the smith draws them",
					"The wheels were made of spokes and a rim, and weighed a third as much. "
					+ "Everyone took a turn at pushing the cart, and then at being pushed in it.",
					&"cart_spoked", milestone, [_spend(&"wood", 6), _set_flag(&"cart")],
					[_has(&"wood", 6)],
				),
			], [], &"character"
		),
		_bronze_road(
			&"donkeys_to_the_pack", "The trader's donkey",
			"The donkey that carried the salt is back, and it has taken a strong dislike to being "
			+ "led and a stronger liking for the herd.",
			milestone, day, VillagerState.TRAIT_NATURE_LOVING, [
				_route(
					&"train_two_donkeys", "Train two donkeys to the pack",
					"Two donkeys were trained to the pack, a process that mostly consisted of "
					+ "being patient, and carrots.",
					&"pack_donkeys", milestone, [_set_flag(&"donkeys")],
				),
				_route(
					&"borrow_the_string", "Borrow the trader's string of donkeys",
					"The trader's string of donkeys was borrowed for a season, and returned "
					+ "with a note, which nobody could read, and an extra donkey.",
					&"borrowed_donkeys", milestone, [_set_flag(&"donkeys")],
				),
			], [_flag_set(&"path_herding")], &"nature"
		),
		_bronze_road(
			&"a_hard_road", "A road toward the hills",
			"The way to the hills is a different bog every spring. Someone has said that it "
			+ "doesn't need to be.",
			milestone, day, VillagerState.TRAIT_INDUSTRIOUS, [
				_route(
					&"lay_a_stone_road", "Lay a road of flat stones",
					"Flat stones were laid one beside the next, and for the first time the whole "
					+ "road could be walked in wet shoes without regretting it.",
					&"stone_road", milestone, [_spend(&"wood", 10), _set_flag(&"road_laid")],
					[_has(&"wood", 10)],
				),
				_route(
					&"beat_a_gravel_track", "Beat a hard track of gravel",
					"A track of gravel was beaten hard by a great many feet over a great many "
					+ "evenings, and was exactly as good as the evenings.",
					&"gravel_track", milestone, [_set_flag(&"road_laid")],
				),
			]
		),
		_bronze_road(
			&"rollers_and_rope", "Poles and rope",
			"The load is too heavy to carry and too light to be worth the argument. Somebody has "
			+ "found a stack of straight poles.",
			milestone, BRONZE_DAY[&"rollers"], VillagerState.TRAIT_INDUSTRIOUS, [
				_route(
					&"drag_on_rollers", "Drag it on rollers",
					"The load rode on poles that had to be carried round from the back to the "
					+ "front as it went, and the line of walking poles was oddly graceful.",
					&"rollers", milestone,
				),
				_route(
					&"carry_in_relays", "Carry it in relays",
					"The load went from hand to hand along the road, a few steps each, and "
					+ "arrived before any of them had worked out how tired they were.",
					&"relays", milestone,
				),
			]
		),
	]


## A Town. A market where the road meets the gate (needs the Wheel and the Road), a council at the
## gate (needs Mud-brick Walls) and, late and for every group, a tally of what is kept where.
func _town_roads() -> Array[EventDef]:
	var day: int = BRONZE_DAY[&"a_town"]
	var milestone: StringName = &"a_town"
	return [
		_bronze_road(
			&"market_day", "A day for the road to come in",
			"Strangers come up the road at all hours, and the village never knows whether to "
			+ "feed them or sell them something. A day, someone says, would settle it.",
			milestone, day, VillagerState.TRAIT_SOCIAL, [
				_route(
					&"market_at_the_gate", "Set it by the gate",
					"Market day was set by the gate, and by noon there were more people in the "
					+ "lane than the lane had been built for.",
					&"market_gate", milestone, [_set_flag(&"market_day")],
				),
				_route(
					&"market_at_the_crossing", "Set it at the crossing",
					"Market day was set at the crossing, and the river got used to a great deal of "
					+ "shouting.",
					&"market_crossing", milestone, [_set_flag(&"market_day")],
				),
			], [_earned(&"wheel_and_road")]
		),
		_bronze_road(
			&"council_at_the_gate", "Who decides",
			"There are twice as many households as there were, and three different opinions about "
			+ "where the new gate should open. Somebody says someone should decide.",
			milestone, day, VillagerState.TRAIT_SOCIAL, [
				_route(
					&"council_of_elders", "Let the elders decide",
					"The elders met at the gate and decided, at length, and the decision was "
					+ "announced with some ceremony and one cough.",
					&"council_of_elders", milestone, [_set_flag(&"council")],
				),
				_route(
					&"council_of_households", "A voice from every household",
					"Every household sent someone, and the council lasted until dark. Nobody was "
					+ "happy, which was agreed to be fair.",
					&"council_of_households", milestone, [_set_flag(&"council")],
				),
			], [_earned(&"mud_brick_walls")]
		),
		_bronze_road(
			&"the_tally", "What is kept where",
			"There is more in the stores than anyone can remember, and a good deal of it is "
			+ "owed to someone. A way of keeping count is needed.",
			milestone, BRONZE_DAY[&"tally"], VillagerState.TRAIT_CURIOUS, [
				_route(
					&"press_marks_in_clay", "Press marks into a slab of wet clay",
					"Marks were pressed into wet clay with a reed, and the slab baked in the kiln. "
					+ "It was, everyone agreed, a remarkably stubborn way of remembering.",
					&"clay_tablets", milestone, [_set_flag(&"tally")],
				),
				_route(
					&"knot_a_cord", "Knot the count into a cord",
					"A cord was knotted for each store, a knot for each tally, and the keeper "
					+ "could read it with her eyes shut.",
					&"knot_cords", milestone, [_set_flag(&"tally")],
				),
			]
		),
	]


## Beyond the Water. A plank boat, a reed ship, a sail from over the sea or, late for every group,
## watching the water. Each sets `far_shore`, which a later age reads (docs/ages.md B7, B9).
func _beyond_the_water_roads() -> Array[EventDef]:
	var day: int = BRONZE_DAY[&"beyond_the_water"]
	var milestone: StringName = &"beyond_the_water"
	return [
		_bronze_road(
			&"planks_for_the_dugout", "More than a river",
			"The dugout is as good a boat as a log can be. It has also begun to look at the "
			+ "mouth of the river in a way that boats sometimes do.",
			milestone, day, VillagerState.TRAIT_CURIOUS, [
				_route(
					&"plank_and_sail", "Add planks and a square sail",
					"Planks were pegged along the sides and a square of woven cloth went up a "
					+ "pole. The boat leaned, thought about it, and went.",
					&"plank_boat", milestone, _far([_spend(&"wood", 8)]), [_has(&"wood", 8)],
				),
				_route(
					&"paddle_the_coast", "Pitch it, and paddle along the coast",
					"The dugout was pitched and paddled along the coast, and was home by dark "
					+ "with a full account of what lay beyond the second headland.",
					&"coast_paddling", milestone, _far(),
				),
			], [_flag_set(&"dugout_canoe")], &"exploration"
		),
		_bronze_road(
			&"reed_ship", "The raft wants to go further",
			"The reed raft has been dried and re-bound so often that it has started to look like a "
			+ "small ship. It is only waiting to be told.",
			milestone, day, VillagerState.TRAIT_CURIOUS, [
				_route(
					&"bind_a_reed_ship", "Bind a reed ship under a square sail",
					"Reeds were bound into a ship with a high prow and a cloth sail, and it rode "
					+ "the swell like a swan that had been told something confidential.",
					&"reed_ship", milestone, _far(),
				),
				_route(
					&"keel_the_raft", "Lash the raft to a keel of poles",
					"A keel of poles was lashed beneath it, and the raft went out into the "
					+ "channel with its nose in the air and a look of deep concentration.",
					&"keeled_raft", milestone, _far(),
				),
			], [_flag_set(&"reed_raft")], &"exploration"
		),
		_bronze_road(
			&"a_sail_puts_in", "A sail from over the sea",
			"A ship with a square sail has put in at the beach, the first anyone has seen, and "
			+ "its crew are all looking at the village with polite alarm.",
			milestone, day, VillagerState.TRAIT_SOCIAL, [
				_route(
					&"row_out_to_meet_them", "Row out to meet them",
					"A boat went out to meet them, and the two crews spent an hour being "
					+ "polite across a gap of water.",
					&"rowed_out", milestone, _far(),
				),
				_route(
					&"wait_on_the_shore", "Wait for them on the shore",
					"The villagers waited on the shore with bread and a great many questions, and "
					+ "the visitors came up the beach with a bundle of gifts and the same.",
					&"waited_on_shore", milestone, _far(),
				),
			], [_earned(&"wheel_and_road")], &"exploration"
		),
		_bronze_road(
			&"watch_the_water", "Smoke on the water",
			"Something has been moving on the horizon at dusk. It might be a bird, or a boat, "
			+ "or the end of someone's patience.",
			milestone, BRONZE_DAY[&"watch"], VillagerState.TRAIT_NATURE_LOVING, [
				_route(
					&"watch_from_the_dune", "Watch from the dune",
					"They watched from the dune for three evenings, and on the third something "
					+ "watched back.",
					&"watched_the_dune", milestone, _far(),
				),
				_route(
					&"fire_on_the_spit", "Light a fire on the spit",
					"A fire was lit on the spit, and in the morning there was a thread of smoke "
					+ "from the other side of the water, answering.",
					&"spit_fire", milestone, _far(),
				),
			], [], &"exploration"
		),
	]


## The effect every road to the last milestone shares: the far shore is seen, which a later age
## reads as `green_stone` was read here.
func _far(more: Array[SimEffect] = []) -> Array[SimEffect]:
	var effects: Array[SimEffect] = [_set_flag(&"far_shore")]
	effects.append_array(more)
	return effects


## Small story decisions that fill the Bronze Age between its milestones, paced by
## `BRONZE_STORY_DAY`. Like the Settled Age's, each has two answers that do something, a journal
## line each, and a flag a later line or age remembers.
func _bronze_story(
	event_id: StringName, title: String, category: StringName, day_key: StringName, body: String
) -> EventDef:
	var event: EventDef = _event(event_id, title, category)
	event.body = body
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", BRONZE),
		_cond(SimCondition.Kind.ERA_DAYS_AT_LEAST, &"", BRONZE_STORY_DAY[day_key]),
	])
	event.chance_per_tick = STORY_CHANCE
	event.once = true
	return event


func _bronze_story_about(
	event_id: StringName, title: String, category: StringName, day_key: StringName, body: String,
	favoured: StringName
) -> EventDef:
	var event: EventDef = _bronze_story(event_id, title, category, day_key, body)
	event.needs_subject = true
	event.subject_requires = _conds([_cond(SimCondition.Kind.SUBJECT_AT_HOME)])
	event.trait_weights[favoured] = 3.0
	return event


## A fork with two answers, each setting a flag and perhaps spending or giving something.
func _fork(event: EventDef, first: ChoiceDef, second: ChoiceDef, needs: Array[SimCondition] = []) \
		-> EventDef:
	event.requires.append_array(needs)
	event.choices = _choices([first, second])
	return event


func _bronze_stories() -> Array[EventDef]:
	var events: Array[EventDef] = [
		_how_to_get_it_hot(), _charcoal(), _who_tends_the_hearth(), _moulds(), _a_bright_thing(),
		_hammering_at_night(), _a_blade_for_what(), _rain_on_the_bricks(), _salt_again(),
		_which_way_the_gate_faces(), _a_name_for_the_place(), _water_against_the_wall(),
		_stones_for_weights(), _a_smith_who_stays(), _who_owns_the_road(), _who_walks_the_road(),
		_a_strangers_goods(), _a_name_on_the_pot(), _looking_at_the_sea(), _light_on_the_water(),
		_a_stone_that_rings(), _a_cracked_mould(), _ruts_in_the_lane(), _red_water(),
		_fuel_for_the_long_burn(),
	]
	return events


func _a_cracked_mould() -> EventDef:
	return _fork(
		_bronze_story(
			&"a_cracked_mould", "A cracked mould", &"settlement", &"cracked_mould",
			"The best mould has a crack down one side, and everyone has been very careful not to "
			+ "mention whose elbow it was."
		),
		_answer(
			&"patch_the_mould", "Patch it with wet clay",
			"The crack was patched with wet clay and the mould went back to work, with a thin "
			+ "line down every blade like a signature.",
			[_set_flag(&"mould_patched")],
		),
		_answer(
			&"break_and_remake", "Break it, and make a better one",
			"The mould was broken with some ceremony and a new one made, a little bigger and a "
			+ "great deal more careful.",
			[_set_flag(&"mould_remade")],
		),
		[_earned(&"first_casting")]
	)


func _ruts_in_the_lane() -> EventDef:
	return _fork(
		_bronze_story(
			&"ruts_in_the_lane", "Ruts in the lane", &"settlement", &"ruts",
			"The cart has worn two deep ruts into the lane, and the children have discovered "
			+ "that they are exactly the right depth for racing sticks."
		),
		_answer(
			&"lay_planks", "Lay planks in the ruts",
			"Planks were laid along the ruts, and the cart ran on them with a hollow drumming "
			+ "that could be heard from the field.",
			[_spend(&"wood", 6), _set_flag(&"planked_ruts")],
			[_has(&"wood", 6)],
		),
		_answer(
			&"let_the_cart_find_a_line", "Let the cart find a new line",
			"The cart was left to find a new line, and wore two new ruts beside the old ones, "
			+ "which the children were delighted about.",
			[_set_flag(&"new_ruts")],
		),
		[_earned(&"wheel_and_road")]
	)


func _how_to_get_it_hot() -> EventDef:
	return _fork(
		_bronze_story(
			&"how_to_get_it_hot", "How to get it hot", &"settlement", &"bellows",
			"The hearth is hot, but not hot enough, and everyone has an opinion about the air."
		),
		_answer(
			&"make_a_bellows", "Make a bellows from a hide bag and a clay pipe",
			"A hide bag and a clay pipe made a bellows, and the hearth breathed in and out like "
			+ "something alive.",
			[_set_flag(&"bellows")],
		),
		_answer(
			&"raise_a_chimney", "Raise a tall clay chimney",
			"A tall clay chimney went up behind the hearth and pulled the air through it like a "
			+ "long cold drink.",
			[_set_flag(&"chimney")],
		),
	)


func _charcoal() -> EventDef:
	return _fork(
		_bronze_story(
			&"charcoal", "Charcoal", &"settlement", &"charcoal",
			"Green wood smokes, and dry wood burns out too fast. Somebody has said that charcoal "
			+ "would do neither."
		),
		_answer(
			&"burn_a_pit", "Burn a covered pit of charcoal",
			"A pit of wood was burned under a skin of turf for three days, and came out black, "
			+ "light and astonishingly hot.",
			[_spend(&"wood", 8), _set_flag(&"charcoal_pit")],
			[_has(&"wood", 8)],
		),
		_answer(
			&"gather_dead_wood", "Send the children for dead wood",
			"The children came back with armfuls of grey, dry wood and were extremely proud of "
			+ "every stick.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"wood", 4), _set_flag(&"dead_wood")],
		),
	)


func _who_tends_the_hearth() -> EventDef:
	return _fork(
		_bronze_story_about(
			&"who_tends_the_hearth", "Who tends the hearth", &"character", &"hearth",
			"{subject} has been at the hearth every day for a week, and has begun to know it the "
			+ "way you know a stubborn animal.",
			VillagerState.TRAIT_INDUSTRIOUS
		),
		_answer(
			&"one_keeps_it", "Let them keep it, and call them the smith",
			"{subject} was given the hearth, and the title, and a leather apron that came down to "
			+ "the ankles.",
			[_eff(SimEffect.Kind.SET_PROFESSION, &"smith"), _set_flag(&"smith_chosen")],
		),
		_answer(
			&"everyone_learns", "Have every household learn a little",
			"Every household took a turn at the bellows, and for a month the whole village "
			+ "smelled of singed hair.",
			[_set_flag(&"hearth_shared")],
		),
	)


func _moulds() -> EventDef:
	return _fork(
		_bronze_story(
			&"moulds", "Moulds", &"settlement", &"moulds",
			"Every blade so far has been cast in a mould that broke. Somebody wants to know if "
			+ "there's a mould that doesn't."
		),
		_answer(
			&"carve_stone_moulds", "Carve moulds from stone",
			"Moulds were carved from river stone, and lasted for years, and took nearly as long "
			+ "to make.",
			[_set_flag(&"stone_moulds")],
		),
		_answer(
			&"bake_clay_moulds", "Bake them from clay",
			"Moulds were baked from clay by the dozen, and broke by the dozen, and were made "
			+ "again with some enthusiasm.",
			[_set_flag(&"clay_moulds")],
		),
		[_earned(&"first_casting")]
	)


func _a_bright_thing() -> EventDef:
	return _fork(
		_bronze_story(
			&"a_bright_thing", "A bright thing", &"settlement", &"bright",
			"The first metal is a surprise every time, and everyone wants to hold it."
		),
		_answer(
			&"a_bracelet_for_everyone", "Make a bracelet for everyone",
			"A bracelet was made for everyone in the village, and every wrist flashed in the sun "
			+ "like a small signal.",
			[_set_flag(&"bracelets")],
		),
		_answer(
			&"a_blade_first", "Make a blade first",
			"The first thing the smith made was a blade, and the second thing was a sheath, "
			+ "because the blade had to go somewhere.",
			[_set_flag(&"first_blade")],
		),
		[_earned(&"first_casting")]
	)


func _hammering_at_night() -> EventDef:
	return _fork(
		_bronze_story_about(
			&"hammering_at_night", "The hammering at night", &"character", &"night_hammer",
			"{subject} has been woken three nights running by the hammer, and has said so, in "
			+ "the nicest possible way.",
			VillagerState.TRAIT_SOCIAL
		),
		_answer(
			&"move_the_hearth", "Move the hearth to the edge of the village",
			"The hearth moved to the edge of the village, and the hammer moved with it, and "
			+ "everyone slept very well and felt slightly neglected.",
			[_spend(&"wood", 6), _set_flag(&"hearth_moved")],
			[_has(&"wood", 6)],
		),
		_answer(
			&"hang_hides", "Hang hides over the nearest walls",
			"Hides were hung over the nearest walls, and the hammering went on softly, as if it "
			+ "were under a blanket.",
			[_set_flag(&"hides_hung")],
		),
	)


func _a_blade_for_what() -> EventDef:
	return _fork(
		_bronze_story(
			&"a_blade_for_what", "A blade for what", &"settlement", &"blade",
			"There is now enough bronze for a single good blade, and an argument about what "
			+ "shape it should be."
		),
		_answer(
			&"an_axe", "An axe for the forest",
			"The bronze went into an axe, and the forest edge retreated by a little more every "
			+ "evening.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"wood", 6), _set_flag(&"bronze_axe")],
		),
		_answer(
			&"a_sickle", "A sickle for the field",
			"The bronze went into a curved sickle, and the harvest was cut in half the time and "
			+ "twice the singing.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 6), _set_flag(&"bronze_sickle")],
		),
		[_earned(&"bronze_alloy")]
	)


func _rain_on_the_bricks() -> EventDef:
	var event: EventDef = _bronze_story(
		&"rain_on_the_bricks", "Rain on the new bricks", &"settlement", &"bricks",
		"The sky has gone grey, and the new bricks are still soft."
	)
	event.requires.append(_season(Season.AUTUMN))
	return _fork(
		event,
		_answer(
			&"roof_the_bricks", "Roof them over with reeds",
			"The bricks were roofed with reeds, and the rain drummed on the reeds, and the "
			+ "bricks stayed exactly as they were.",
			[_set_flag(&"bricks_roofed")],
		),
		_answer(
			&"turn_the_bricks", "Turn them as they dry",
			"The bricks were turned one by one, and by the end every hand was the colour of "
			+ "the bricks.",
			[_set_flag(&"bricks_turned")],
		),
		[_earned(&"mud_brick_walls")]
	)


func _salt_again() -> EventDef:
	return _fork(
		_bronze_story(
			&"salt_again", "Salt again", &"settlement", &"coast_trader",
			"The salt is nearly gone, and the winter meat is nearly here."
		),
		_answer(
			&"buy_salt_for_winter", "Buy salt for the winter meat",
			"A sack of grey salt came up the road on a donkey, and the winter meat went in under "
			+ "it, layer by layer.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 4), _set_flag(&"salt_laid_in")],
		),
		_answer(
			&"smoke_the_meat", "Hang it in the smoke over the hearth",
			"The meat was hung in the hearth smoke and came out dark and leathery and "
			+ "remarkably good.",
			[_set_flag(&"smoked_meat")],
		),
		[_flag_set(&"salt")]
	)


func _which_way_the_gate_faces() -> EventDef:
	return _fork(
		_bronze_story(
			&"which_way_the_gate_faces", "Which way the gate faces", &"settlement", &"gate",
			"The gate is built, and now it has to face somewhere."
		),
		_answer(
			&"gate_to_the_river", "Toward the river",
			"The gate was hung facing the river, and every morning the first thing anyone saw "
			+ "was water.",
			[_set_flag(&"river_gate")],
		),
		_answer(
			&"gate_to_the_road", "Toward the road",
			"The gate was hung facing the road, and every morning the first thing anyone saw "
			+ "was whoever was coming.",
			[_set_flag(&"road_gate")],
		),
		[_earned(&"mud_brick_walls")]
	)


func _a_name_for_the_place() -> EventDef:
	return _fork(
		_bronze_story_about(
			&"a_name_for_the_place", "A name for the place", &"character", &"name",
			"Strangers keep asking what the village is called, and {subject} has run out of ways "
			+ "to say that it isn't.",
			VillagerState.TRAIT_SOCIAL
		),
		_answer(
			&"after_the_river", "Name it after the river",
			"The village was named for the river, and the river, as far as anyone could tell, "
			+ "didn't mind.",
			[_set_flag(&"named_for_river")],
		),
		_answer(
			&"after_the_cave", "Name it after the cave",
			"The village was named for the cave, and somebody climbed up and said the name into "
			+ "it, and it came back.",
			[_set_flag(&"named_for_cave")],
		),
	)


func _water_against_the_wall() -> EventDef:
	return _fork(
		_bronze_story(
			&"water_against_the_wall", "Water against the new wall", &"settlement",
			&"wall_water",
			"After the rain the water has collected against the foot of the wall, and the wall "
			+ "looks worried."
		),
		_answer(
			&"open_a_channel", "Open a channel through the bank",
			"A channel was opened through the bank and the water ran off down it, grumbling.",
			[_spend(&"wood", 12), _set_flag(&"wall_channel")],
			[_has(&"wood", 12)],
		),
		_answer(
			&"let_it_find_its_way", "Let the water find its own way",
			"The water found its own way, which was under the gate, and the gate learned to "
			+ "live with it.",
			[_set_flag(&"wall_left_wet")],
		),
		[_earned(&"mud_brick_walls")]
	)


func _stones_for_weights() -> EventDef:
	return _fork(
		_bronze_story(
			&"stones_for_weights", "Stones for weights", &"settlement", &"weights",
			"Two people have swapped a bag of grain for a lump of bronze, and are both sure that "
			+ "they were cheated."
		),
		_answer(
			&"weigh_by_the_stone", "Weigh by the stone",
			"A set of river stones was picked out, one for each size of argument, and the "
			+ "arguments, to everyone's surprise, got smaller.",
			[_set_flag(&"stone_weights")],
		),
		_answer(
			&"weigh_by_the_handful", "Weigh by the handful",
			"The village weighed by the handful, and the size of the hand became a matter of "
			+ "some delicacy.",
			[_set_flag(&"handful_weights")],
		),
		[_earned(&"bronze_alloy")]
	)


func _a_smith_who_stays() -> EventDef:
	return _fork(
		_bronze_story(
			&"a_smith_who_stays", "A smith who wants to stay", &"character", &"smith_stays",
			"A smith from beyond the ridge has been working at the hearth for a week, and has "
			+ "begun to ask what the winters are like."
		),
		_answer(
			&"take_the_smith_in", "Take them in",
			"The smith was taken in, and brought tools, opinions and a number of better ways to "
			+ "hold a hammer.",
			[_eff(SimEffect.Kind.ADD_VILLAGER, &"", 1), _set_flag(&"smith_stayed")],
			[_cond(SimCondition.Kind.HAS_ROOM, &"", 1)],
		),
		_answer(
			&"send_them_on", "Send them on with a gift of food",
			"The smith was sent on with a gift of food, and a good name, and a small hammer "
			+ "left behind by accident.",
			[_spend(&"food", 4), _set_flag(&"smith_sent_on")],
			[_has(&"food", 4)],
		),
		[_earned(&"first_casting")]
	)


func _who_owns_the_road() -> EventDef:
	return _fork(
		_bronze_story(
			&"who_owns_the_road", "Who owns the road", &"settlement", &"toll",
			"The road has become so well used that somebody has asked, in a small voice, whose "
			+ "it is."
		),
		_answer(
			&"ask_a_toll", "Ask a toll at the gate",
			"A toll was asked at the gate, in small bundles, and the collector became the "
			+ "village's most polite person.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 3), _set_flag(&"toll")],
		),
		_answer(
			&"let_everyone_pass", "Let everyone pass",
			"The road stayed open to everyone, and the village became known on the road for it.",
			[_set_flag(&"open_road")],
		),
		[_earned(&"wheel_and_road")]
	)


func _who_walks_the_road() -> EventDef:
	return _fork(
		_bronze_story_about(
			&"who_walks_the_road", "Who walks the road", &"character", &"trader",
			"{subject} has been to the end of the road and back three times this month, and "
			+ "comes home each time with a new word.",
			VillagerState.TRAIT_SOCIAL
		),
		_answer(
			&"make_a_trader", "Make them the village's trader",
			"{subject} was made the trader, and given a good strong bag and a very long list.",
			[_eff(SimEffect.Kind.SET_PROFESSION, &"trader"), _set_flag(&"trader_chosen")],
		),
		_answer(
			&"share_the_road", "Let everyone take a turn at the road",
			"Everyone took a turn, and the village learned a great many ways to be cheated, and "
			+ "a few to cheat back.",
			[_set_flag(&"road_shared")],
		),
		[_earned(&"wheel_and_road")]
	)


func _a_strangers_goods() -> EventDef:
	return _fork(
		_bronze_story(
			&"a_strangers_goods", "A stranger's goods", &"settlement", &"goods",
			"A stranger has spread a blanket in the lane with a heap of things on it, and is "
			+ "looking at the village as if it might be useful."
		),
		_answer(
			&"take_beads_and_cloth", "Take beads and cloth",
			"Beads and bright cloth were taken, and the lane looked, for a week, like a "
			+ "festival.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 3), _set_flag(&"beads_and_cloth")],
		),
		_answer(
			&"take_tools", "Take tools",
			"A set of tools was taken, and by evening the lane was full of people trying them "
			+ "and putting them down with respect.",
			[_set_flag(&"stranger_tools")],
		),
		[_earned(&"wheel_and_road")]
	)


func _a_name_on_the_pot() -> EventDef:
	return _fork(
		_bronze_story(
			&"a_name_on_the_pot", "A name on the pot", &"settlement", &"marked_pots",
			"A pot has been carried off by the wrong family twice this month, with real "
			+ "conviction both times."
		),
		_answer(
			&"press_the_mark", "Press a mark into the clay",
			"Every pot got its mark pressed into the clay before it was fired, and some of the "
			+ "marks looked remarkably like faces.",
			[_set_flag(&"pressed_marks")],
		),
		_answer(
			&"tie_a_cord", "Tie a cord round the neck",
			"Every pot got a cord, and the cords got knots, and the knots got names.",
			[_set_flag(&"knotted_marks")],
		),
		[_flag_set(&"pot_marks")]
	)


func _looking_at_the_sea() -> EventDef:
	return _fork(
		_bronze_story_about(
			&"looking_at_the_sea", "Looking at the sea", &"exploration", &"sea_look",
			"{subject} has been walking out to the dunes in the evenings, and standing there a "
			+ "long time with one hand over the eyes.",
			VillagerState.TRAIT_CURIOUS
		),
		_answer(
			&"climb_the_dune", "Climb the highest dune",
			"{subject} climbed the highest dune and saw, very far off, a thin dark line that "
			+ "might have been land.",
			[_set_flag(&"far_dune")],
		),
		_answer(
			&"follow_the_coast", "Follow the coast",
			"{subject} followed the coast for two days and came back with a pocket of strange "
			+ "shells and nothing to say about any of them.",
			[_set_flag(&"followed_coast")],
		),
		[_flag_set(&"far_shore")]
	)


func _light_on_the_water() -> EventDef:
	return _fork(
		_bronze_story(
			&"light_on_the_water", "A different light on the water", &"settlement",
			&"night_light",
			"The boats come home later than they used to, and the river mouth is very dark."
		),
		_answer(
			&"fish_by_night", "Fish by torchlight from the boat",
			"The boats went out with torches and came back low in the water, and the river was "
			+ "full of small gold lights.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 5), _set_flag(&"night_fishing")],
		),
		_answer(
			&"a_lamp_at_the_mouth", "Set a lamp at the river mouth",
			"A lamp of oil and a wick was set on a pole at the river mouth, and every boat that "
			+ "came home that month steered for it.",
			[_spend(&"wood", 4), _set_flag(&"river_lamp")],
			[_has(&"wood", 4)],
		),
		[_flag_set(&"far_shore")]
	)


func _a_stone_that_rings() -> EventDef:
	return _fork(
		_bronze_story_about(
			&"a_stone_that_rings", "A stone that rings", &"exploration", &"ringing_stone",
			"{subject} has brought back a dark, heavy stone from the far shore that rings like a "
			+ "bell when struck, and does something odd to the fire.",
			VillagerState.TRAIT_CURIOUS
		),
		_answer(
			&"hang_it_as_a_bell", "Hang it up as a bell",
			"The dark stone was hung from a beam, and struck at dusk, and the sound went a long "
			+ "way out over the water.",
			[_set_flag(&"dark_stone_bell")],
		),
		_answer(
			&"put_it_in_the_fire", "Put it in the fire, and see",
			"The dark stone went into the fire and came out a different colour, much harder, "
			+ "and very difficult to cut.",
			[_set_flag(&"dark_stone_tried")],
		),
		[_flag_set(&"far_shore")]
	)


## Where the boats tie up: raise a quay (a building) or drive mooring posts into the bank.
func _the_quay() -> EventDef:
	var event: EventDef = _bronze_story(
		&"the_quay", "Where the boats tie up", &"settlement", &"quay",
		"The boats are pulled up the bank every evening, and every evening somebody gets wet "
		+ "to the knees."
	)
	event.requires.append(_cond(SimCondition.Kind.CONSTRUCTION_IDLE))
	event.chance_per_tick = 0.5
	event.cooldown_ticks = 24
	event.choices = _choices([
		_build_choice(&"build_quay", "Quay", &"quay", 14),
		_answer(
			&"drive_mooring_posts", "Drive mooring posts into the bank",
			"Three stout posts went into the bank, and the boats were tied to them with a great "
			+ "deal of rope and a certain amount of pride.",
			[_spend(&"wood", 4), _set_flag(&"mooring_posts")],
			[_has(&"wood", 4)],
		),
	])
	return event


## The two forks that end the Settled Age's quiet stretch before the gate opens (docs/ages.md B2).
## They expire with the age.
func _heavy_loads() -> EventDef:
	var event: EventDef = _settled_story(
		&"heavy_loads", "Heavy loads", &"settlement", SETTLED_STORY_DAY[&"loads"],
		"The loads have grown, the village has grown, and the backs have stayed exactly as they "
		+ "were."
	)
	event.requires.append(_cond(SimCondition.Kind.ERA_AT_LEAST, &"", BRONZE, true))
	return _fork(
		event,
		_answer(
			&"build_a_sledge", "Build a sledge",
			"A sledge was built from two curved branches and a plank, and was dragged up the "
			+ "lane by four villagers and a dog.",
			[_set_flag(&"sledge")],
		),
		_answer(
			&"carry_in_packs", "Carry it in baskets on the back",
			"Baskets with straps were made for the back, and the villagers walked the lane bent "
			+ "like a row of question marks.",
			[_set_flag(&"pack_baskets")],
		),
	)


func _whose_pot() -> EventDef:
	var event: EventDef = _settled_story(
		&"whose_pot", "Whose pot is whose", &"settlement", SETTLED_STORY_DAY[&"marks"],
		"The pots in the lane all look alike, and the argument about whose is whose has gone on "
		+ "since breakfast."
	)
	event.requires.append(_cond(SimCondition.Kind.ERA_AT_LEAST, &"", BRONZE, true))
	event.requires.append(_earned(&"fired_clay"))
	return _fork(
		event,
		_answer(
			&"mark_each_pot", "Scratch a mark on each pot",
			"Every pot was scratched with a mark before it went in the kiln, and the marks "
			+ "became the first thing the children learned to read.",
			[_set_flag(&"pot_marks")],
		),
		_answer(
			&"leave_them_plain", "Leave them plain",
			"The pots were left plain, and the argument was settled, as arguments are, by "
			+ "whoever was loudest.",
			[_set_flag(&"pots_plain")],
		),
	)


## The Bronze Age's one-line moments: the age's feel (hearth smoke, hammers, bricks, carts, markets,
## sails), several only after a milestone, a few about a trait and several that remember an answer.
func _bronze_ambient_lines() -> Array[EventDef]:
	return [
		_bronze_ambient(
			&"smoke_of_the_hearth",
			"The hearth smoked all morning, a thick green smoke that nobody ever got used to.",
			[_earned(&"first_casting")]
		),
		_bronze_ambient(
			&"ring_of_hammers",
			"From the edge of the village came the sound of a small hammer, over and over, like "
			+ "a very patient woodpecker.",
			[_earned(&"first_casting")]
		),
		_bronze_ambient(
			&"bright_in_the_ash",
			"Somebody found a bead of bright metal in the ashes, put it in a pocket, and could not "
			+ "stop touching it all day.",
			[_earned(&"first_casting")]
		),
		_bronze_ambient(
			&"ingots_by_the_hearth",
			"Ingots of bronze were stacked by the hearth like small loaves, and every passer-by "
			+ "lifted one to feel how heavy it was.",
			[_earned(&"bronze_alloy")]
		),
		_bronze_ambient_about(
			&"watching_the_pour", VillagerState.TRAIT_CURIOUS,
			"{subject} stood at the hearth with a wet cloth over their face, watching the metal run, "
			+ "and had to be called three times for supper.",
			[_earned(&"first_casting")]
		),
		_bronze_ambient_about(
			&"stacking_bricks", VillagerState.TRAIT_INDUSTRIOUS,
			"{subject} stacked bricks in rows so straight that they looked drawn.",
			[_earned(&"mud_brick_walls")]
		),
		_bronze_ambient_about(
			&"counting_birds_from_the_wall", VillagerState.TRAIT_NATURE_LOVING,
			"{subject} sat on the wall at dusk and counted birds, lost count, and started "
			+ "again.",
			[_earned(&"mud_brick_walls")]
		),
		_bronze_ambient_about(
			&"telling_the_market", VillagerState.TRAIT_SOCIAL,
			"{subject} told everyone about the road, and then told them again, in better order.",
			[_earned(&"wheel_and_road")]
		),
		_bronze_remembered(
			&"dribble_remembered", &"copper_tried",
			"Somebody remembered the first bright dribble of metal in the ash, and said it had "
			+ "been a good deal smaller than they thought."
		),
		_bronze_remembered(
			&"beads_remembered", &"green_beads",
			"The green beads were worn at every neck, and the question of where the stone came "
			+ "from was discussed more than ever."
		),
		_bronze_remembered(
			&"bellows_breathing", &"bellows",
			"The bellows breathed in and out all afternoon, and the hearth breathed back."
		),
		_bronze_remembered(
			&"chimney_smoke", &"chimney",
			"The clay chimney drew the smoke straight up, and the village smelled, for once, of "
			+ "something else."
		),
		_bronze_remembered(
			&"bracelets_glint", &"bracelets",
			"Light flashed from every wrist, and the children had learned to signal across the "
			+ "lane with them."
		),
		_bronze_remembered(
			&"first_blade_on_the_wall", &"first_blade",
			"The first blade hung by the door, and was taken down, admired and put back so often "
			+ "that the cord wore thin."
		),
		_bronze_remembered(
			&"gate_at_dusk", &"town_wall",
			"The gate was shut at dusk with a sound that had not existed before, and everyone "
			+ "slept a little differently."
		),
		_bronze_remembered(
			&"palisade_creaks", &"palisade",
			"The palisade creaked in the wind like a very large ship that had been told to wait."
		),
		_bronze_remembered(
			&"cart_creak", &"cart",
			"The cart creaked down the lane, and every dog in the village followed it for a "
			+ "while, out of principle."
		),
		_bronze_remembered(
			&"donkey_bells", &"pack_donkeys",
			"The donkeys came in at evening with their bells ringing, and the children raced them "
			+ "to the gate."
		),
		_bronze_remembered(
			&"market_noise", &"market_gate",
			"On market day the lane was so loud that the herons left."
		),
		_bronze_remembered(
			&"scales_on_a_pole", &"stone_weights",
			"A pair of scales hung from a pole, and the argument about who should hold the stones "
			+ "was the best in years."
		),
		_bronze_remembered(
			&"clay_slab_passed_round", &"clay_tablets",
			"A slab of baked clay was passed from hand to hand, and everyone made a different face "
			+ "at it."
		),
		_bronze_remembered(
			&"toll_collected", &"toll",
			"The toll was collected at the gate in small bundles, and the collector was extremely "
			+ "civil about it."
		),
		_bronze_remembered(
			&"strangers_wipe_their_feet", &"open_road",
			"Strangers walked in through the open gate and, out of politeness, wiped their feet."
		),
		_bronze_remembered(
			&"named_for_the_river", &"named_for_river",
			"Somebody said the name of the village to a stranger, and the stranger said it back, "
			+ "carefully, like a gift."
		),
		_bronze_remembered(
			&"named_for_the_cave", &"named_for_cave",
			"A child shouted the village's name into the cave, and the cave said it back a "
			+ "little slower."
		),
		_bronze_remembered(
			&"boats_at_the_posts", &"mooring_posts",
			"The boats nodded at their posts all night, and the posts, to be fair, nodded back."
		),
		_bronze_remembered(
			&"lantern_on_the_quay", &"quay_built",
			"A lantern was lit at the end of the quay, and the boats came in towards it like "
			+ "moths, only slower."
		),
		_bronze_remembered(
			&"sail_on_the_horizon", &"far_shore",
			"A sail crossed the horizon at noon, small and white, and half the village stopped "
			+ "and watched it go."
		),
		_bronze_remembered(
			&"dark_stone_ringing", &"dark_stone_bell",
			"The dark stone was struck at dusk, and the sound went a long way out over the water "
			+ "and did not come back."
		),
	]


## A Bronze Age line: only in the age, rarer than the Cave Age's, and only when every one of
## `needs` holds.
func _bronze_ambient(
	event_id: StringName, line: String, needs: Array[SimCondition] = []
) -> EventDef:
	var event: EventDef = _ambient(event_id, line)
	event.requires = _conds([_cond(SimCondition.Kind.ERA_AT_LEAST, &"", BRONZE)])
	event.requires.append_array(needs)
	event.chance_per_tick = BRONZE_AMBIENT_CHANCE
	return event


func _bronze_ambient_about(
	event_id: StringName, trait_name: StringName, line: String, needs: Array[SimCondition] = []
) -> EventDef:
	var event: EventDef = _bronze_ambient(event_id, line, needs)
	event.category = &"character"
	event.needs_subject = true
	event.subject_requires = _conds([
		_cond(SimCondition.Kind.SUBJECT_HAS_TRAIT, trait_name),
		_cond(SimCondition.Kind.SUBJECT_AT_HOME),
		_cond(SimCondition.Kind.SUBJECT_AWAKE),
	])
	return event


func _bronze_remembered(event_id: StringName, flag: StringName, line: String) -> EventDef:
	return _bronze_ambient(event_id, line, [_flag_set(flag)])


## ---- The Iron Age (docs/ages.md, "Iron Age") -----------------------------------------------------
## A harder metal, farming that feeds a bigger town, a fort, coin, writing and a name abroad. Like
## Bronze: six hidden milestones staged over the age (`IRON_DAY`), each with more than one road and
## one road open to every group, small forks between them and quiet lines. Every decision is a fork
## (docs/gameplay.md P13). The turn asks *how* to work the dark stone the Bronze Age's last fork
## left; later roads read what the group answered in the Bronze Age (the wall, the weights, the
## tally, the boats). The age has no gate out yet (G7), but its last forks lead into the next one.

const IRON_TITLES: Dictionary = {
	&"first_bloom": "The First Bloom",
	&"fuller_harvest": "A Fuller Harvest",
	&"the_hill_fort": "The Hill-fort",
	&"silver_by_weight": "Silver by Weight",
	&"written_word": "The Written Word",
	&"name_abroad": "A Name Abroad",
}


func _iron_events() -> Array[EventDef]:
	var events: Array[EventDef] = [_a_harder_fire(), _iron_building_opportunity()]
	events.append_array(_iron_milestones())
	events.append_array(_iron_stories())
	events.append_array(_iron_ambient_lines())
	return events


## The turn from the Bronze Age to the Iron Age. Fired by the era's hidden gate, so the player is
## never asked whether to go on, only how to work the dark stone. It reads nothing the group may
## lack: the stone is told about in two quiet lines afterwards.
func _a_harder_fire() -> EventDef:
	var event: EventDef = _event(&"a_harder_fire", "A harder fire", &"settlement")
	event.body = "The dark stone will not melt in the bronze fire, however hot the bellows make it. " \
			+ "It glows, and sulks, and rings when it is struck, which is more than most stones do."
	event.choices = _choices([
		_answer(
			&"work_it_at_home", "Dig the red mud from the flats, and build a hotter furnace",
			"The red mud of the river flats was dug out in baskets, and a furnace went up taller "
			+ "than the smithy, and everyone stood well back from it.",
			[_set_flag(&"path_bloomery"), _eff(SimEffect.Kind.ADVANCE_ERA, &"iron")],
		),
		_answer(
			&"follow_it_to_the_hills", "Follow the stone back to the dark hills",
			"A few people walked up into the dark hills with empty sacks, and came back with "
			+ "full ones, a limp, and a very clear idea of where the stone had come from.",
			[_set_flag(&"path_ore"), _eff(SimEffect.Kind.ADVANCE_ERA, &"iron")],
		),
	])
	return event


func _iron_building_opportunity() -> EventDef:
	var event: EventDef = _event(&"iron_building_opportunity", "Building in iron", &"settlement")
	event.body = "The new metal wants a furnace of its own, and the new harvest wants somewhere to go."
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", IRON),
		_cond(SimCondition.Kind.CONSTRUCTION_IDLE),
		_cond(SimCondition.Kind.RESOURCE_AT_LEAST, &"wood", 14),
	])
	event.chance_per_tick = 0.5
	event.cooldown_ticks = 24
	event.choices = _choices([
		_build_choice(&"build_bloomery", "Bloomery", &"bloomery", 18, 0, IRON_DAY[&"first_bloom"]),
		_build_choice(&"build_granary", "Granary", &"granary", 14, 0, IRON_DAY[&"first_bloom"]),
	])
	return event


## Every Iron milestone event: Iron Age, far enough into it, and not yet earned.
func _iron_milestone(
	event_id: StringName, title: String, category: StringName, favoured: StringName,
	era_day: int, milestone: StringName
) -> EventDef:
	var event: EventDef = _milestone_event(event_id, title, category, favoured)
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", IRON),
		_cond(SimCondition.Kind.ERA_DAYS_AT_LEAST, &"", era_day),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, milestone, 0, true),
	])
	return event


## One road to an Iron milestone: the answer sets its own flag, may do something else, and earns it.
func _iron_route(
	choice_id: StringName, label: String, line: String, flag: StringName,
	milestone: StringName, extra: Array[SimEffect] = [], needs: Array[SimCondition] = []
) -> ChoiceDef:
	var effects: Array[SimEffect] = [_set_flag(flag)]
	effects.append_array(extra)
	effects.append(_earn(milestone, IRON_TITLES[milestone]))
	return _answer(choice_id, label, line, effects, needs)


## A decision that is a road to a milestone; `needs` are further requirements on the event.
func _iron_road(
	event_id: StringName, title: String, body: String, milestone: StringName, era_day: int,
	favoured: StringName, answers: Array[ChoiceDef], needs: Array[SimCondition] = [],
	category: StringName = &"settlement"
) -> EventDef:
	var event: EventDef = _iron_milestone(event_id, title, category, favoured, era_day, milestone)
	event.body = body
	event.requires.append_array(needs)
	event.choices = _choices(answers)
	return event


func _iron_milestones() -> Array[EventDef]:
	var events: Array[EventDef] = []
	events.append_array(_first_bloom_roads())
	events.append_array(_fuller_harvest_roads())
	events.append_array(_hill_fort_roads())
	events.append_array(_silver_by_weight_roads())
	events.append_array(_written_word_roads())
	events.append_array(_name_abroad_roads())
	return events


## The First Bloom. The Bloomery is one road (it earns it on completion); a night's burn is the home
## path's, a trader with red lumps the ore path's, a smith who comes over the ridge a neighbour's,
## and hammering a lump of slag is open to every group. The path not taken still gets its road,
## a little later.
func _first_bloom_roads() -> Array[EventDef]:
	var day: int = IRON_DAY[&"first_bloom"]
	var milestone: StringName = &"first_bloom"
	return [
		_first_burn(&"first_burn", day, &"path_bloomery"),
		_first_burn(&"first_burn_slow", day + 30, &"path_ore"),
		_iron_road(
			&"ironsmith_over_the_ridge", "A smith with dark hands",
			"A smith has come over the ridge whose hands are black to the wrist, and who looks at "
			+ "the new furnace the way a cook looks at someone else's soup.",
			milestone, day, VillagerState.TRAIT_SOCIAL, [
				_iron_route(
					&"let_them_burn_a_bloom", "Let them burn a bloom in the furnace",
					"The smith burned a bloom in the furnace overnight, and in the morning "
					+ "pulled out a grey sponge of iron, and everyone was allowed to hit it.",
					&"visiting_ironsmith", milestone,
				),
				_iron_route(
					&"copy_their_furnace", "Watch closely, and build the same furnace",
					"The group watched every move and built the same furnace, a little crooked "
					+ "and a little prouder, and it drew exactly as well as the original.",
					&"copied_ironsmith", milestone,
				),
			], [_flag_set(&"good_neighbours")]
		),
		_iron_road(
			&"ore_on_the_road", "A trader with red lumps",
			"A trader on the road has a sack of heavy red lumps and a story about the dark hills, "
			+ "and says that, with a hot enough fire, they turn into something remarkable.",
			milestone, day + 12, VillagerState.TRAIT_SOCIAL, [
				_iron_route(
					&"lend_the_furnace", "Lend the trader the furnace for a night",
					"The furnace was the trader's for a night. By morning there was a lump of grey "
					+ "iron in the ashes, and the trader was already explaining how it was done.",
					&"road_ironsmith", milestone,
				),
				_iron_route(
					&"pay_for_the_secret", "Pay in food, and ask to be shown",
					"Food was paid, and the whole group was shown in an afternoon, and the trader "
					+ "left with a full belly and an air of having given nothing away.",
					&"taught_the_bloom", milestone, [_spend(&"food", 6)], [_has(&"food", 6)],
				),
			], [_flag_set(&"path_ore")]
		),
		_iron_road(
			&"a_lump_in_the_slag", "A black lump in the slag",
			"{subject} has found a black lump in the heap of old slag behind the smithy. It is "
			+ "heavier than it should be, and it does not break.",
			milestone, day + 36, VillagerState.TRAIT_CURIOUS, [
				_iron_route(
					&"hammer_it_till_it_rings", "Hammer it until it rings",
					"{subject} hammered it for an afternoon, and it grew from a lump into a bar "
					+ "and rang like a small, annoyed bell.",
					&"lump_hammered", milestone,
				),
				_iron_route(
					&"quench_it_and_see", "Heat it, and quench it in the river",
					"The lump went into the fire red and into the river white, with a noise "
					+ "like a goose, and came out a good deal harder than it went in.",
					&"lump_quenched", milestone,
				),
			], [], &"character"
		),
	]


func _first_burn(event_id: StringName, era_day: int, path: StringName) -> EventDef:
	var milestone: StringName = &"first_bloom"
	return _iron_road(
		event_id, "A night's burn",
		"{subject} has packed the new furnace with red ore and charcoal in layers, and sealed the "
		+ "top with clay. All it wants now is the bellows, and a very long night.",
		milestone, era_day, VillagerState.TRAIT_CURIOUS, [
			_iron_route(
				&"blow_all_night", "Work the bellows all night, in turns",
				"The bellows were worked in turns until dawn. When the furnace was broken open "
				+ "there was a bloom in it, glowing, ugly and exactly what was wanted.",
				&"bloom_blown", milestone,
			),
			_iron_route(
				&"let_it_burn_down", "Let it burn down on its own, and open it in the morning",
				"The furnace was left to burn down by itself. In the morning there was a lump in "
				+ "the ashes, still warm, and {subject} was seen to hug it.",
				&"bloom_cooled", milestone,
			),
		], [_flag_set(path)], &"character"
	)


## A Fuller Harvest (needs the First Bloom). A full granary, an iron share on the farmers' digging
## stick, iron shears for the herders, or, late and for every group, an iron axe at the pines.
func _fuller_harvest_roads() -> Array[EventDef]:
	var day: int = IRON_DAY[&"fuller_harvest"]
	var milestone: StringName = &"fuller_harvest"
	return [
		_iron_road(
			&"the_first_full_granary", "Up to the rafters",
			"The granary is nearly full, and the last baskets are being passed up a ladder by "
			+ "people who are enjoying the problem.",
			milestone, day, VillagerState.TRAIT_INDUSTRIOUS, [
				_iron_route(
					&"fill_it_to_the_roof", "Fill it to the roof",
					"It was filled to the roof, and the door was shut on a heap of grain so large "
					+ "that the mice held a meeting.",
					&"granary_full", milestone,
				),
				_iron_route(
					&"leave_it_roomy", "Leave a third of it empty, for the bad year",
					"A third was left empty, and was looked at all winter with the quiet pride "
					+ "of people who have been sensible.",
					&"granary_roomy", milestone,
				),
			], [_earned(&"first_bloom"), _cond(SimCondition.Kind.HAS_BUILDING, &"granary")]
		),
		_iron_road(
			&"a_share_of_iron", "A point that does not wear",
			"The digging sticks wear to a stub by midsummer. {subject} thinks an iron tip would "
			+ "outlast the field.",
			milestone, day, VillagerState.TRAIT_INDUSTRIOUS, [
				_iron_route(
					&"tip_the_stick", "Tip the stick with iron",
					"The sticks got iron tips, and went through the ground like a knife through "
					+ "bread, and nobody mentioned the blisters.",
					&"iron_tipped_sticks", milestone, [_set_flag(&"iron_share")],
				),
				_iron_route(
					&"fit_a_share", "Fit a proper share to a plough",
					"A share was fitted to the plough, and the ox was introduced to it, and "
					+ "between them they turned the longest furrow anyone had ever seen.",
					&"plough_share", milestone, [_spend(&"wood", 6), _set_flag(&"iron_share")],
					[_has(&"wood", 6)],
				),
			], [_earned(&"first_bloom"), _flag_set(&"path_agriculture")], &"character"
		),
		_iron_road(
			&"sharper_shears", "A sharper edge for the flock",
			"The flock is bigger than the shears can bear. {subject} has been looking at the iron "
			+ "knife and then at the sheep, and the sheep have noticed.",
			milestone, day, VillagerState.TRAIT_NATURE_LOVING, [
				_iron_route(
					&"iron_shears", "Make iron shears",
					"Iron shears were made, and the flock was clipped in a morning, and the sheep "
					+ "went about for days looking surprised and cold.",
					&"iron_shears_made", milestone, [_set_flag(&"iron_shears")],
				),
				_iron_route(
					&"iron_knife_and_patience", "Keep to a knife, and take it slowly",
					"The knife was kept sharp and the flock was done sheep by sheep, and the "
					+ "wool came away cleaner than it ever had.",
					&"iron_knife_clip", milestone, [_set_flag(&"iron_shears")],
				),
			], [_earned(&"first_bloom"), _flag_set(&"path_herding")], &"nature"
		),
		_iron_road(
			&"an_axe_at_the_pines", "The edge of the pines",
			"The pines come right up to the edge of the field, and an iron axe has made it very "
			+ "clear that they do not have to.",
			milestone, IRON_DAY[&"iron_axe"], VillagerState.TRAIT_INDUSTRIOUS, [
				_iron_route(
					&"clear_the_edge", "Clear a strip, and sow it",
					"A strip of pines came down in a week, and the sown ground grew by a "
					+ "tenth, and the squirrels moved out in protest.",
					&"edge_cleared", milestone,
				),
				_iron_route(
					&"burn_the_stumps", "Burn the stumps, and plant between the ashes",
					"The stumps were burned and the field planted in their ashes, and the first "
					+ "crop was greener than anything the village had grown.",
					&"stumps_burned", milestone,
				),
			], [_earned(&"first_bloom")]
		),
	]


## The Hill-fort. The Bronze wall is heightened in the spirit of what it was (a brick wall, a
## palisade, a ditch), a ring of bank and ditch is open to every group, and, late and for every
## group, the gate is bound in iron. Each sets `hill_fort`, which a later age reads.
func _hill_fort_roads() -> Array[EventDef]:
	var day: int = IRON_DAY[&"hill_fort"]
	var milestone: StringName = &"the_hill_fort"
	return [
		_iron_road(
			&"raise_the_rampart", "Higher than a ladder",
			"The mud-brick wall is as high as a ladder is long, and the ladder has proved to be "
			+ "a bad thing to have been measured against.",
			milestone, day, VillagerState.TRAIT_INDUSTRIOUS, [
				_iron_route(
					&"lace_it_with_timber", "Lace the wall with oak timbers",
					"Oak timbers were laid through the brick every few courses, and the wall "
					+ "stopped being a wall and became a rampart.",
					&"rampart_laced", milestone, _hill([_spend(&"wood", 14)]), [_has(&"wood", 14)],
				),
				_iron_route(
					&"bank_it_with_earth", "Heap a bank of earth behind it",
					"A bank of earth was heaped behind the wall until it could be walked along, "
					+ "and the sentries learned the pleasure of a view.",
					&"rampart_banked", milestone, _hill([_spend(&"wood", 8)]), [_has(&"wood", 8)],
				),
			], [_flag_set(&"town_wall")]
		),
		_iron_road(
			&"oak_for_the_palisade", "Stakes that stay put",
			"The palisade leans a little more every winter, and one section has begun to lean "
			+ "on its neighbour in a way that looks like gossip.",
			milestone, day, VillagerState.TRAIT_INDUSTRIOUS, [
				_iron_route(
					&"oak_posts_and_nails", "Replace it with oak posts and iron nails",
					"Oak posts went in, nailed with long iron nails, and the palisade stood up "
					+ "straight for the first time and seemed a little embarrassed.",
					&"palisade_oak", milestone, _hill([_spend(&"wood", 10)]), [_has(&"wood", 10)],
				),
				_iron_route(
					&"nail_the_stakes", "Nail the old stakes together where they lean",
					"The old stakes were nailed together in pairs, and the palisade stood a good "
					+ "deal better, and looked exactly as before.",
					&"palisade_nailed", milestone, _hill(),
				),
			], [_flag_set(&"palisade")]
		),
		_iron_road(
			&"deepen_the_ditch", "A ditch to be proud of",
			"The old ditch has silted until a child could step across it, and a child has.",
			milestone, day, VillagerState.TRAIT_INDUSTRIOUS, [
				_iron_route(
					&"dig_it_out", "Dig it out with iron spades",
					"Iron spades went through the silt like it was cream, and the ditch was "
					+ "deeper by a man's height before the week was out.",
					&"ditch_dug_out", milestone, _hill([_spend(&"wood", 8)]), [_has(&"wood", 8)],
				),
				_iron_route(
					&"raise_the_bank_higher", "Throw the spoil up into a bank",
					"The spoil was thrown up into a bank, and the ditch got deeper as the bank "
					+ "got higher, which everyone agreed was the proper way round.",
					&"ditch_banked", milestone, _hill(),
				),
			], [_flag_set(&"dug_in")]
		),
		_iron_road(
			&"ring_the_ridge", "The ridge above the town",
			"Above the town the ridge stands up like an upturned bowl. Somebody has pointed out "
			+ "that anyone standing on it can see everything, and so can anyone else.",
			milestone, day, VillagerState.TRAIT_INDUSTRIOUS, [
				_iron_route(
					&"bank_and_ditch_the_ridge", "Throw a bank and ditch round the top",
					"A bank and a ditch went round the top of the ridge, and for the first time "
					+ "the town had somewhere to go when it wanted to feel safe.",
					&"ridge_ringed", milestone, _hill([_spend(&"wood", 12)]), [_has(&"wood", 12)],
				),
				_iron_route(
					&"a_stockade_on_the_ridge", "Set a stockade along the crest",
					"A stockade of split oak went along the crest, and from the town below it "
					+ "looked like a crown on a rather surprised hill.",
					&"ridge_stockade", milestone, _hill([_spend(&"wood", 10)]), [_has(&"wood", 10)],
				),
			]
		),
		_iron_road(
			&"bind_the_gate_in_iron", "A gate that holds",
			"The gate has been shut and opened so many times that the hinges have started to "
			+ "complain in two voices.",
			milestone, IRON_DAY[&"gate_iron"], VillagerState.TRAIT_INDUSTRIOUS, [
				_iron_route(
					&"hang_it_in_iron", "Hang it on iron hinges, and bind it with straps",
					"Iron hinges and straps went on the gate, and it swung shut with a sound like "
					+ "a very large decision being made.",
					&"iron_gate", milestone, _hill(),
				),
				_iron_route(
					&"bar_it_with_a_beam", "Bar it with a single great beam",
					"A single great beam went across the gate, and took four people to lift, "
					+ "which was agreed to be a feature.",
					&"barred_gate", milestone, _hill(),
				),
			]
		),
	]


## The effect every road to the Hill-fort shares, which a later age reads as the town's upper part.
func _hill(more: Array[SimEffect] = []) -> Array[SimEffect]:
	var effects: Array[SimEffect] = [_set_flag(&"hill_fort")]
	effects.append_array(more)
	return effects


## Silver by Weight (needs a Fuller Harvest). Silver cut to the town's weights (the stones or the
## handful, as the Bronze answer went), a stranger's coin copied, or, late and for every group, a
## mark pressed into a lump. Each sets `coin_struck`.
func _silver_by_weight_roads() -> Array[EventDef]:
	var day: int = IRON_DAY[&"silver_by_weight"]
	var milestone: StringName = &"silver_by_weight"
	var needs: Array[SimCondition] = [_earned(&"fuller_harvest")]
	return [
		_iron_road(
			&"silver_to_the_stones", "A lump of silver",
			"A trader has left a lump of silver in payment for a debt, and now the village has a "
			+ "lump of silver and the problem of what it is worth.",
			milestone, day, VillagerState.TRAIT_SOCIAL, [
				_iron_route(
					&"cut_it_to_the_stones", "Cut it to the weight stones",
					"The silver was cut into pieces that balanced against the river stones, and "
					+ "the pieces were stamped so they could not be mistaken for anything else.",
					&"coin_to_stones", milestone, _coin(),
				),
				_iron_route(
					&"stamp_it_flat", "Beat it flat and stamp the town's mark",
					"The silver was beaten flat and stamped, and for the first time a thing was "
					+ "worth what the town said it was worth.",
					&"coin_stamped", milestone, _coin(),
				),
			], _plus(needs, [_flag_set(&"stone_weights")])
		),
		_iron_road(
			&"silver_to_the_hand", "A handful of silver",
			"A trader has paid in silver, and the village has weighed it, as it weighs everything, "
			+ "by the handful, and the handful has begun to get larger.",
			milestone, day, VillagerState.TRAIT_SOCIAL, [
				_iron_route(
					&"cut_a_handful", "Cut it into handfuls, and mark each one",
					"The silver was cut into handfuls, and each one was marked, and the size of a "
					+ "hand was finally written down in metal.",
					&"coin_handfuls", milestone, _coin(),
				),
				_iron_route(
					&"stamp_the_hand", "Press a hand into each piece",
					"A hand was pressed into each soft piece, and the village had a coin that "
					+ "nobody could argue with, because everyone had been in it.",
					&"coin_handprint", milestone, _coin(),
				),
			], _plus(needs, [_flag_set(&"handful_weights")])
		),
		_iron_road(
			&"copy_a_strangers_coin", "A coin from far away",
			"A stranger has paid for bread with a small round piece of silver, stamped with a "
			+ "picture, and the baker has been looking at it all afternoon.",
			milestone, day, VillagerState.TRAIT_CURIOUS, [
				_iron_route(
					&"copy_it_exactly", "Copy it exactly, picture and all",
					"The coin was copied down to the last scratch, and for a month nobody could "
					+ "tell the real one from the copy, least of all the stranger.",
					&"coin_copied", milestone, _coin(),
				),
				_iron_route(
					&"copy_it_smaller", "Copy it a little smaller, with a mark of our own",
					"The copy was a little smaller and a little more honest, and carried a tiny "
					+ "mark that the baker could find with her eyes shut.",
					&"coin_made_small", milestone, _coin(),
				),
			], _plus(needs, [_cond(SimCondition.Kind.HAS_BUILDING, &"trading_post")]), &"exploration"
		),
		_iron_road(
			&"a_mark_in_a_lump", "A day's grain",
			"There is more silver about than there are names for it, and a good deal of grain "
			+ "changing hands for it. Somebody thinks it should be agreed, once, what it is worth.",
			milestone, IRON_DAY[&"press_mark"], VillagerState.TRAIT_SOCIAL, [
				_iron_route(
					&"press_a_mark_in_it", "Press a mark in a lump, and agree its worth",
					"A mark was pressed into a lump of silver, and it was agreed, loudly, to be "
					+ "worth a day's grain, and after that it was.",
					&"coin_lump_marked", milestone, _coin(),
				),
				_iron_route(
					&"keep_a_standard_lump", "Keep a standard lump by the gate",
					"A single lump was set in a niche by the gate as the standard, and "
					+ "everything was weighed against it, and it grew shiny from being touched.",
					&"coin_standard", milestone, _coin(),
				),
			], needs
		),
	]


## The effect every road to Silver by Weight shares: the coin, which a later age reads.
func _coin(more: Array[SimEffect] = []) -> Array[SimEffect]:
	var effects: Array[SimEffect] = [_set_flag(&"coin_struck")]
	effects.append_array(more)
	return effects


## The Written Word (needs Silver by Weight). Signs pressed in clay or cut in a stick, as the
## Bronze tally went; a name over the gate (needs the Hill-fort); or, late and for every group, a
## trader's tablet copied sign by sign. Each sets `letters`.
func _written_word_roads() -> Array[EventDef]:
	var day: int = IRON_DAY[&"written_word"]
	var milestone: StringName = &"written_word"
	var needs: Array[SimCondition] = [_earned(&"silver_by_weight")]
	return [
		_iron_road(
			&"signs_in_the_clay", "A sign for a sound",
			"The marks on the old clay slabs have begun to be used for the sounds in words, and "
			+ "nobody is sure who started it.",
			milestone, day, VillagerState.TRAIT_CURIOUS, [
				_iron_route(
					&"press_the_signs", "Press a sign for every sound",
					"A sign was pressed for every sound the village made, and the first thing "
					+ "anyone wrote was a name, and then, at once, a complaint.",
					&"signs_pressed", milestone, _letters(),
				),
				_iron_route(
					&"read_the_slab_aloud", "Read the old slabs aloud, and fit signs to them",
					"The old slabs were read aloud while someone drew the signs, and for the "
					+ "first time the tally of last year's grain said something about the year.",
					&"slabs_read", milestone, _letters(),
				),
			], _plus(needs, [_flag_set(&"clay_tablets")]), &"character"
		),
		_iron_road(
			&"signs_on_a_stick", "A sign for a knot",
			"The keeper of the cords has begun to cut small signs into a stick beside each knot, "
			+ "so that nobody has to ask her what they mean.",
			milestone, day, VillagerState.TRAIT_CURIOUS, [
				_iron_route(
					&"cut_the_signs", "Cut the signs into the stick",
					"The signs were cut into a stick, one for every sound, and the stick was "
					+ "passed round and read by people who had never seen a stick read.",
					&"signs_cut", milestone, _letters(),
				),
				_iron_route(
					&"read_the_cord_aloud", "Read the cord aloud, and cut as you go",
					"The cord was read aloud, knot by knot, while someone cut each sound into a "
					+ "stick, and it took all night and was worth it.",
					&"cord_read", milestone, _letters(),
				),
			], _plus(needs, [_flag_set(&"knot_cords")]), &"character"
		),
		_iron_road(
			&"a_name_over_the_gate", "Over the gate",
			"The new gate stands with a good deal of blank beam above it, and the town, which "
			+ "has a name and a tablet, has noticed.",
			milestone, day, VillagerState.TRAIT_SOCIAL, [
				_iron_route(
					&"cut_it_in_the_beam", "Cut it deep in the beam",
					"The name was cut deep in the beam, and a child was lifted up to touch it, "
					+ "and read it out, and was applauded.",
					&"gate_beam_cut", milestone, _letters(),
				),
				_iron_route(
					&"paint_it_in_lime", "Paint it in limewash, large",
					"The name was painted in limewash, each sign as tall as a child, and could "
					+ "be read from the far side of the river.",
					&"gate_lime_painted", milestone, _letters(),
				),
			], [_earned(&"the_hill_fort"), _earned(&"silver_by_weight")]
		),
		_iron_road(
			&"copy_the_traders_tablet", "A trader's tablet",
			"A trader has left a tablet covered in small neat signs, and a very strong "
			+ "impression that they mean something.",
			milestone, IRON_DAY[&"copy_tablet"], VillagerState.TRAIT_CURIOUS, [
				_iron_route(
					&"copy_it_sign_by_sign", "Copy it sign by sign",
					"The tablet was copied sign by sign, and the copy was checked against it, "
					+ "and by the end three people could read it aloud, and did.",
					&"tablet_copied", milestone, _letters(),
				),
				_iron_route(
					&"learn_it_by_heart", "Learn the signs by heart, and write them from memory",
					"The signs were learned by heart, and written from memory, and only a few "
					+ "were backwards, and nobody minded.",
					&"signs_by_heart", milestone, _letters(),
				),
			], needs
		),
	]


## The effect every road to the Written Word shares: letters, which a later age reads.
func _letters(more: Array[SimEffect] = []) -> Array[SimEffect]:
	var effects: Array[SimEffect] = [_set_flag(&"letters")]
	effects.append_array(more)
	return effects


## A Name Abroad (needs Silver by Weight). A boat of goods to the far shore (a planked boat or a
## reed ship, as the Settled boat went), a ship that asks the name, a rider by the road or, late
## and for every group, a name cut where travellers will read it. Each sets `known_abroad`, which a
## later age reads as `far_shore` is read here.
func _name_abroad_roads() -> Array[EventDef]:
	var day: int = IRON_DAY[&"name_abroad"]
	var milestone: StringName = &"name_abroad"
	var needs: Array[SimCondition] = [_earned(&"silver_by_weight")]
	return [
		_iron_road(
			&"cargo_by_plank_boat", "Goods for the far shore",
			"The planked boat has been loaded and unloaded so often that it has begun to know "
			+ "the way, and the load this time is meant for someone who has never seen it.",
			milestone, day, VillagerState.TRAIT_CURIOUS, [
				_iron_route(
					&"sail_it_over", "Sail it over, and ask for the market",
					"The boat crossed in two days and came home in three, low with strange "
					+ "goods and high with news, and the far shore had been told the name.",
					&"cargo_sailed", milestone, _abroad(),
				),
				_iron_route(
					&"send_it_with_a_guide", "Send it with someone who has the words",
					"The boat went with a guide who had the words, and the market on the far "
					+ "shore was found at once, and so was a friend.",
					&"cargo_guided", milestone, _abroad(),
				),
			], _plus(needs, [_flag_set(&"dugout_canoe")]), &"exploration"
		),
		_iron_road(
			&"cargo_by_reed_ship", "A cargo for the reed ship",
			"The reed ship has been dried, re-bound and stacked with goods, and is plainly "
			+ "waiting for somebody to say where.",
			milestone, day, VillagerState.TRAIT_CURIOUS, [
				_iron_route(
					&"sail_the_reed_ship", "Sail it over on a fair wind",
					"The reed ship crossed on a fair wind and came back on a foul one, and "
					+ "was greeted at the quay as if it had been to the moon.",
					&"reed_cargo_sailed", milestone, _abroad(),
				),
				_iron_route(
					&"send_it_in_a_string", "Send it in company with the planked boats",
					"The reed ship went in company, with two others, and the three came home "
					+ "together, which is the best way to come home.",
					&"reed_cargo_company", milestone, _abroad(),
				),
			], _plus(needs, [_flag_set(&"reed_raft")]), &"exploration"
		),
		_iron_road(
			&"a_ship_asks_the_name", "A ship up the river",
			"A ship with a deep keel has come up the river, a thing the river was not built for, "
			+ "and the captain has asked, very politely, what the town is called.",
			milestone, day, VillagerState.TRAIT_SOCIAL, [
				_iron_route(
					&"say_it_slowly", "Say it slowly, and have them say it back",
					"The name was said slowly, three times, and the captain said it back each "
					+ "time a little more wrongly, and wrote it down anyway.",
					&"name_said", milestone, _abroad(),
				),
				_iron_route(
					&"write_it_in_the_sand", "Write it in the sand for them",
					"The name was written in the sand, and the captain copied it onto a tablet, "
					+ "and the tide came in on the original.",
					&"name_written", milestone, _abroad(),
				),
			], _plus(needs, [_flag_set(&"far_shore")]), &"exploration"
		),
		_iron_road(
			&"a_rider_on_the_road", "A rider on the hard road",
			"Someone is riding up the hard road on a horse, which nobody here has seen close "
			+ "to, and a number of people have taken a step back and a number a step forward.",
			milestone, day, VillagerState.TRAIT_SOCIAL, [
				_iron_route(
					&"ride_out_to_meet_them", "Go out along the road to meet them",
					"A few went out along the road, and the rider got down and walked the last "
					+ "mile with them, leading the horse, and asking about the town.",
					&"rider_met", milestone, _abroad(),
				),
				_iron_route(
					&"wait_at_the_gate", "Wait for them at the gate, with water",
					"The town waited at the gate with a bucket, and the horse drank first, and "
					+ "the rider, afterwards, said that she had heard good things.",
					&"rider_waited", milestone, _abroad(),
				),
			], _plus(needs, [_flag_set(&"road_laid")]), &"exploration"
		),
		_iron_road(
			&"a_name_for_the_traveller", "Where the road meets the river",
			"Travellers keep stopping at the crossing and asking whose town it is, and there is "
			+ "nothing there to tell them.",
			milestone, IRON_DAY[&"name_stone"], VillagerState.TRAIT_SOCIAL, [
				_iron_route(
					&"cut_the_name_deep", "Cut the name deep in a rock by the crossing",
					"The name was cut deep in a rock by the crossing, and the first traveller "
					+ "to read it stood there so long that they were offered a meal.",
					&"name_cut_deep", milestone, _abroad(),
				),
				_iron_route(
					&"hang_a_painted_board", "Hang a painted board at the crossing",
					"A painted board went up at the crossing, and was repainted every spring, "
					+ "and was, to everyone's surprise, quite handsome.",
					&"name_board", milestone, _abroad(),
				),
			], needs
		),
	]


## The effect every road to the last milestone shares: the town is known abroad, which a later age
## reads as `far_shore` is read here (docs/ages.md I10).
func _abroad(more: Array[SimEffect] = []) -> Array[SimEffect]:
	var effects: Array[SimEffect] = [_set_flag(&"known_abroad")]
	effects.append_array(more)
	return effects


## `base` and `more`, as one list (a typed array cannot be added to a plain literal).
func _plus(base: Array[SimCondition], more: Array[SimCondition]) -> Array[SimCondition]:
	var all: Array[SimCondition] = []
	all.append_array(base)
	all.append_array(more)
	return all


## Small story decisions that fill the Iron Age between its milestones, paced by `IRON_STORY_DAY`.
## Like the Bronze Age's, each has two answers that do something, a journal line each, and a flag a
## later line or age remembers. The last three lead into the next age (docs/ages.md I10).
func _iron_story(
	event_id: StringName, title: String, category: StringName, day_key: StringName, body: String
) -> EventDef:
	var event: EventDef = _event(event_id, title, category)
	event.body = body
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", IRON),
		_cond(SimCondition.Kind.ERA_DAYS_AT_LEAST, &"", IRON_STORY_DAY[day_key]),
	])
	event.chance_per_tick = STORY_CHANCE
	event.once = true
	return event


func _iron_story_about(
	event_id: StringName, title: String, category: StringName, day_key: StringName, body: String,
	favoured: StringName
) -> EventDef:
	var event: EventDef = _iron_story(event_id, title, category, day_key, body)
	event.needs_subject = true
	event.subject_requires = _conds([_cond(SimCondition.Kind.SUBJECT_AT_HOME)])
	event.trait_weights[favoured] = 3.0
	return event


func _iron_stories() -> Array[EventDef]:
	return [
		_a_hotter_hearth(), _downwind(), _who_learns_the_slow_work(), _slag(), _the_first_iron(),
		_nails_over_the_door(), _a_pot_that_does_not_break(), _rust(), _frost_in_the_furnace(),
		_the_tin_trader(), _timber_for_the_rampart(), _a_name_for_the_fort(),
		_water_in_the_ditch(), _beans_on_the_bank(), _sheep_on_the_bank(),
		_hands_for_the_field(), _what_goes_on_the_coin(), _who_counts(), _bad_silver(),
		_who_pays_at_the_gate(), _a_name_over_the_door(), _stone_from_the_hill(),
		_strangers_words(), _a_fire_the_sea_can_see(), _a_stone_with_a_name(),
		_a_rider_with_a_sash(), _a_table_for_strangers(),
	]


func _a_hotter_hearth() -> EventDef:
	return _fork(
		_iron_story(
			&"a_hotter_hearth", "A hotter hearth", &"settlement", &"hotter_hearth",
			"The bronze fire was hot, and the iron fire has to be hotter, and everyone has "
			+ "opinions about where the heat goes."
		),
		_answer(
			&"build_a_tall_furnace", "Build a tall clay furnace",
			"A tall furnace of clay and stone went up, as high as two people, and drew so hard "
			+ "that it roared like something in a cave.",
			[_spend(&"wood", 8), _set_flag(&"tall_furnace")],
			[_has(&"wood", 8)],
		),
		_answer(
			&"dig_it_into_the_bank", "Dig a furnace into the bank",
			"A furnace was dug into the side of the bank, where the earth held the heat in, and "
			+ "the smoke came out of the hill as if it were smoking a pipe.",
			[_set_flag(&"bank_furnace")],
		),
	)


func _downwind() -> EventDef:
	return _fork(
		_iron_story_about(
			&"downwind", "Downwind", &"character", &"downwind",
			"{subject} lives downwind of the furnace, and has begun to describe every dinner as "
			+ "'a little smoky'.",
			VillagerState.TRAIT_SOCIAL
		),
		_answer(
			&"move_the_furnace_out", "Move the furnace out of the smoke's way",
			"The furnace was moved a little way off, and the smoke went the other way, and "
			+ "{subject}'s dinners tasted of dinner.",
			[_spend(&"wood", 6), _set_flag(&"furnace_moved")],
			[_has(&"wood", 6)],
		),
		_answer(
			&"ask_everyone_to_keep_clear", "Ask everyone to keep clear on burning days",
			"Burning days became days when nobody went near the furnace who did not have to, and "
			+ "a sort of holiday atmosphere, with soot.",
			[_set_flag(&"burning_days")],
		),
	)


func _who_learns_the_slow_work() -> EventDef:
	return _fork(
		_iron_story_about(
			&"who_learns_the_slow_work", "Who learns the slow work", &"character",
			&"slow_work",
			"Iron is slow work, and the smith is not getting any younger, and {subject} has "
			+ "been standing near the furnace a good deal lately, doing nothing in particular.",
			VillagerState.TRAIT_INDUSTRIOUS
		),
		_answer(
			&"take_an_apprentice", "Take them as an apprentice",
			"{subject} was taken as an apprentice, and spent the first month carrying "
			+ "charcoal and the second carrying more.",
			[_set_flag(&"apprentice_taken")],
		),
		_answer(
			&"every_household_learns", "Let every household learn a little",
			"Every household learned a little, and a good deal of what they learned was how "
			+ "much there was to learn.",
			[_set_flag(&"slow_work_shared")],
		),
	)


func _slag() -> EventDef:
	return _fork(
		_iron_story(
			&"slag", "Slag", &"settlement", &"slag",
			"Every burn leaves a heap of black glassy slag behind the furnace, and the heap is "
			+ "now taller than the furnace."
		),
		_answer(
			&"pave_the_lane_with_it", "Pave the lane with it",
			"The lane was paved with crushed slag, and glittered after rain, and was slippery "
			+ "in exactly the places nobody expected.",
			[_set_flag(&"slag_lane")],
		),
		_answer(
			&"heap_it_behind", "Heap it behind the furnace, and let it grow",
			"The slag was heaped behind the furnace, and grew, and became a place where the "
			+ "children went to be dramatic.",
			[_set_flag(&"slag_heaped")],
		),
		[_earned(&"first_bloom")]
	)


func _the_first_iron() -> EventDef:
	return _fork(
		_iron_story(
			&"the_first_iron", "The first iron", &"settlement", &"first_iron",
			"There is enough iron for a first thing, and the first thing is a matter of some "
			+ "debate."
		),
		_answer(
			&"a_knife_for_everyone", "A knife for everyone",
			"Every household got a knife, and for a week the whole village cut things that did "
			+ "not need cutting.",
			[_set_flag(&"iron_knives")],
		),
		_answer(
			&"one_good_axe_head", "One good axe head, for the forest",
			"One good axe head was made, and was passed from hand to hand, and the pines "
			+ "retreated with a kind of dignity.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"wood", 6), _set_flag(&"iron_axehead")],
		),
		[_earned(&"first_bloom")]
	)


func _nails_over_the_door() -> EventDef:
	return _fork(
		_iron_story_about(
			&"nails_over_the_door", "Nails over the door", &"character", &"nails",
			"Somebody has driven an iron nail into the beam over their door, for luck, and "
			+ "{subject} has noticed that it is working.",
			VillagerState.TRAIT_SOCIAL
		),
		_answer(
			&"a_nail_over_every_door", "One nail over every door",
			"Every door got a nail, and every nail got touched on the way in and out until it "
			+ "shone like a very small star.",
			[_set_flag(&"door_nails")],
		),
		_answer(
			&"keep_the_nails_for_timbers", "Keep the nails for the timbers",
			"The nails were kept for the timbers, where they held the roofs to the walls, and "
			+ "nobody needed to touch them for luck.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"wood", 3), _set_flag(&"nails_kept")],
		),
		[_earned(&"first_bloom")]
	)


func _a_pot_that_does_not_break() -> EventDef:
	return _fork(
		_iron_story(
			&"a_pot_that_does_not_break", "A pot that does not break", &"settlement",
			&"iron_pot",
			"The clay pots crack in the cold and the iron one has never cracked, and everyone "
			+ "has been looking at the iron one."
		),
		_answer(
			&"hang_an_iron_cauldron", "Hang an iron cauldron over the fire",
			"An iron cauldron hung from a hook over the fire, black as a beetle, and the soup "
			+ "was never quite the same, or at all bad.",
			[_spend(&"wood", 5), _set_flag(&"iron_cauldron")],
			[_has(&"wood", 5)],
		),
		_answer(
			&"keep_the_clay_pots", "Keep to the clay pots",
			"The clay pots were kept, because they were what the soup was used to, and "
			+ "because the cauldron would cost.",
			[_set_flag(&"clay_pots_kept")],
		),
		[_earned(&"first_bloom")]
	)


func _rust() -> EventDef:
	return _fork(
		_iron_story(
			&"rust", "Rust", &"settlement", &"rust",
			"The first tools have started to turn brown at the edges, and nobody can think "
			+ "what they have done to deserve it."
		),
		_answer(
			&"grease_the_tools", "Grease the tools every evening",
			"The tools were greased every evening with fat, and the cooking suffered, and the "
			+ "tools did not.",
			[_spend(&"food", 3), _set_flag(&"tools_greased")],
			[_has(&"food", 3)],
		),
		_answer(
			&"keep_them_dry_in_the_cave", "Keep them dry in the cave",
			"The tools were carried to the cave each night and brought back each morning, and "
			+ "the walk became part of the day.",
			[_set_flag(&"tools_in_the_cave")],
		),
		[_earned(&"first_bloom")]
	)


func _frost_in_the_furnace() -> EventDef:
	var event: EventDef = _iron_story(
		&"frost_in_the_furnace", "Frost in the furnace", &"settlement", &"frost",
		"The first hard frost has come, and the furnace is cold at the edges, and iron does "
		+ "not like a cold furnace."
	)
	event.requires.append(_season(Season.WINTER))
	return _fork(
		event,
		_answer(
			&"keep_it_lit_all_winter", "Keep it lit all winter",
			"The furnace was kept lit all winter, fed a little at a time, and was the warmest "
			+ "place in the village and, for that reason, the busiest.",
			[_spend(&"wood", 10), _set_flag(&"furnace_kept_lit")],
			[_has(&"wood", 10)],
		),
		_answer(
			&"bank_it_and_wait", "Bank it, and wait for the spring",
			"The furnace was banked under clay and straw, and sat all winter like a sleeping "
			+ "animal, and woke up grumpy in the spring.",
			[_set_flag(&"furnace_banked")],
		),
		[_earned(&"first_bloom")]
	)


func _the_tin_trader() -> EventDef:
	return _fork(
		_iron_story(
			&"the_tin_trader", "The tin trader", &"settlement", &"tin_trader",
			"The tin trader is back, with her donkeys and a long face, and has noticed that "
			+ "she is being asked a good deal less than she used to be."
		),
		_answer(
			&"offer_iron_for_tin", "Offer iron in place of tin",
			"Iron was offered in place of tin, and the trader looked at it for a long time and "
			+ "then went away to think about her prices.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"wood", 4), _set_flag(&"iron_for_tin")],
		),
		_answer(
			&"keep_buying_bronze", "Keep buying bronze for the fine work",
			"Tin was bought for the fine work, a little at a time, and the trader left "
			+ "happier than she had arrived.",
			[_spend(&"food", 4), _set_flag(&"bronze_for_fine_work")],
			[_has(&"food", 4)],
		),
		[_earned(&"first_bloom")]
	)


func _timber_for_the_rampart() -> EventDef:
	return _fork(
		_iron_story(
			&"timber_for_the_rampart", "Timber for the rampart", &"settlement", &"timber",
			"The rampart wants a great deal of timber, and there is not a great deal of "
			+ "timber about."
		),
		_answer(
			&"oak_from_the_far_wood", "Fell oak in the far wood",
			"Oak was felled in the far wood and dragged home by every beast the village could "
			+ "borrow, and the rampart smelled of fresh timber for a year.",
			[_spend(&"wood", 12), _set_flag(&"far_oak")],
			[_has(&"wood", 12)],
		),
		_answer(
			&"the_old_gate_timbers", "Use the old gate's timbers",
			"The old gate's timbers were used, and they carried a great many scratches and one "
			+ "child's name, which stayed.",
			[_set_flag(&"old_timbers")],
		),
		[_earned(&"the_hill_fort")]
	)


func _a_name_for_the_fort() -> EventDef:
	return _fork(
		_iron_story_about(
			&"a_name_for_the_fort", "A name for the fort", &"character", &"fort_name",
			"The strangers on the road have started calling the town 'the fort', and {subject} "
			+ "feels it deserves better.",
			VillagerState.TRAIT_SOCIAL
		),
		_answer(
			&"after_the_hill", "After the hill",
			"The fort was named for the hill, and the hill, for a moment, looked slightly "
			+ "smug.",
			[_set_flag(&"fort_named_for_hill")],
		),
		_answer(
			&"after_the_first_family", "After the first family",
			"The fort was named for the first family to have lived here, and their grandchildren "
			+ "pretended not to be pleased.",
			[_set_flag(&"fort_named_for_family")],
		),
		[_earned(&"the_hill_fort")]
	)


func _water_in_the_ditch() -> EventDef:
	return _fork(
		_iron_story(
			&"water_in_the_ditch", "Water in the ditch", &"settlement", &"ditch_water",
			"The deep ditch has filled after the rain, and a frog has moved in, and the question "
			+ "is whether it should be allowed to."
		),
		_answer(
			&"cut_a_channel", "Cut a channel from the river",
			"A channel was cut from the river, and the ditch filled to the brim and stayed "
			+ "full, and the frog was joined by a great many relatives.",
			[_spend(&"wood", 12), _set_flag(&"ditch_channel")],
			[_has(&"wood", 12)],
		),
		_answer(
			&"let_it_fill", "Let it fill when it likes",
			"The ditch filled when it liked and drained when it liked, and was a pond in "
			+ "spring and a dry gully by autumn.",
			[_set_flag(&"ditch_left_to_fill")],
		),
		[_earned(&"the_hill_fort")]
	)


func _beans_on_the_bank() -> EventDef:
	return _fork(
		_iron_story(
			&"beans_on_the_bank", "Beans on the bank", &"settlement", &"bank_crop",
			"The bank round the fort is bare earth, and somebody has pointed out that nothing "
			+ "grows on bare earth except resentment."
		),
		_answer(
			&"plant_the_bank_with_beans", "Plant the bank with beans",
			"The bank was planted with beans, and in July it was a green wall, and in September "
			+ "it was dinner.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 3), _set_flag(&"bank_beans")],
		),
		_answer(
			&"leave_it_to_the_grass", "Leave it to the grass",
			"The bank was left to the grass, which came up thick and green and was visited by "
			+ "every cricket in the valley.",
			[_set_flag(&"bank_grass")],
		),
		[_earned(&"the_hill_fort"), _flag_set(&"path_agriculture")]
	)


func _sheep_on_the_bank() -> EventDef:
	return _fork(
		_iron_story(
			&"sheep_on_the_bank", "Sheep on the bank", &"settlement", &"bank_crop_herd",
			"The bank round the fort is grass, and the flock has noticed."
		),
		_answer(
			&"graze_the_bank", "Let the flock graze it",
			"The flock grazed the bank clean, and the bank was never so tidy, and the sheep "
			+ "looked like a procession.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 3), _set_flag(&"bank_grazed")],
		),
		_answer(
			&"keep_the_flock_off", "Keep the flock off it",
			"The flock was kept off the bank, which grew tall, and nested with larks.",
			[_set_flag(&"bank_left")],
		),
		[_earned(&"the_hill_fort"), _flag_set(&"path_herding")]
	)


func _hands_for_the_field() -> EventDef:
	return _fork(
		_iron_story(
			&"hands_for_the_field", "Hands for the field", &"settlement", &"hands",
			"The new fields are wide, and there are not enough hands, and a family on the road "
			+ "has stopped to look at the gate."
		),
		_answer(
			&"take_a_family_in", "Take the family in",
			"The family was taken in, and given a patch at the edge, and within a month they "
			+ "had opinions about everything.",
			[_eff(SimEffect.Kind.ADD_VILLAGER, &"", 1), _set_flag(&"family_taken_in")],
			[_cond(SimCondition.Kind.HAS_ROOM, &"", 1)],
		),
		_answer(
			&"send_them_on_with_grain", "Send them on with a sack of grain",
			"The family was sent on with a sack of grain and good wishes, and were seen a "
			+ "month later a little way down the road, settled and waving.",
			[_spend(&"food", 4), _set_flag(&"family_sent_on")],
			[_has(&"food", 4)],
		),
		[_earned(&"fuller_harvest")]
	)


func _what_goes_on_the_coin() -> EventDef:
	return _fork(
		_iron_story(
			&"what_goes_on_the_coin", "What goes on the coin", &"settlement", &"coin_face",
			"Every coin needs a picture, and every household has a view on what it should be."
		),
		_answer(
			&"a_tree", "A tree",
			"A tree went on the coin, and the tree was recognisably the old pine by the cave, "
			+ "and the cave was quietly flattered.",
			[_set_flag(&"coin_tree")],
		),
		_answer(
			&"a_face", "A face",
			"A face went on the coin, and every household was convinced it was theirs, and the "
			+ "mint kept very quiet.",
			[_set_flag(&"coin_face")],
		),
		[_earned(&"silver_by_weight")]
	)


func _who_counts() -> EventDef:
	return _fork(
		_iron_story_about(
			&"who_counts", "Who counts", &"character", &"counter",
			"The silver has to be counted, and {subject} has been counting it already, out of "
			+ "habit, in a murmur.",
			VillagerState.TRAIT_SOCIAL
		),
		_answer(
			&"a_keeper_of_the_count", "Let them keep the count",
			"{subject} kept the count, in a small room with a small door, and came out with "
			+ "ink on one finger, and a new look.",
			[_set_flag(&"keeper_of_the_count")],
		),
		_answer(
			&"count_aloud_together", "Count aloud, all together",
			"The count was done aloud in the lane, all together, every month, and became the "
			+ "closest thing the village had to a song.",
			[_set_flag(&"count_aloud")],
		),
		[_earned(&"silver_by_weight")]
	)


func _bad_silver() -> EventDef:
	return _fork(
		_iron_story(
			&"bad_silver", "Bad silver", &"settlement", &"bad_silver",
			"A coin has turned up that is not quite silver, and everybody agrees it must have "
			+ "come from someone else."
		),
		_answer(
			&"test_it_on_a_touchstone", "Set up a touchstone by the market",
			"A black touchstone was set up by the market, and rubbed so bright that it caught "
			+ "the light, and the trader who first failed it left in a hurry.",
			[_spend(&"food", 3), _set_flag(&"touchstone")],
			[_has(&"food", 3)],
		),
		_answer(
			&"trust_the_trader", "Trust the trader's word",
			"The trader's word was trusted, and the trader was visibly a little hurt, and "
			+ "honest for the rest of the season.",
			[_set_flag(&"trusted_the_trader")],
		),
		[_earned(&"silver_by_weight")]
	)


func _who_pays_at_the_gate() -> EventDef:
	return _fork(
		_iron_story(
			&"who_pays_at_the_gate", "Who pays at the gate", &"settlement", &"gate_coin",
			"Now there is coin, the gate has the chance to ask for it, and the gatekeeper has "
			+ "been thinking about this a great deal."
		),
		_answer(
			&"coin_at_the_gate", "Take a coin from every cart",
			"A coin was taken from every cart, and the gate became a place where people stood "
			+ "and had a quiet word with their purses.",
			[_eff(SimEffect.Kind.ADD_RESOURCE, &"food", 3), _set_flag(&"coin_at_the_gate")],
		),
		_answer(
			&"waive_it_for_neighbours", "Waive it for neighbours",
			"The gate waved neighbours through, and the neighbours, to the gatekeeper's "
			+ "surprise, remembered it.",
			[_set_flag(&"neighbours_waved_through")],
		),
		[_earned(&"silver_by_weight")]
	)


func _a_name_over_the_door() -> EventDef:
	return _fork(
		_iron_story(
			&"a_name_over_the_door", "A name over the door", &"settlement", &"door_name",
			"The signs are good enough now to put on a door, and every household would like "
			+ "theirs to be the first."
		),
		_answer(
			&"cut_it_in_wood", "Cut it in the lintel",
			"Names were cut into lintels, and the carpenter did a thriving trade in curly "
			+ "letters for a month.",
			[_set_flag(&"names_in_wood")],
		),
		_answer(
			&"press_it_in_clay", "Press it into a clay plaque",
			"Names were pressed into clay plaques and set by each door, and the potters "
			+ "became quietly proud of their alphabet.",
			[_set_flag(&"names_in_clay")],
		),
		[_earned(&"written_word")]
	)


func _stone_from_the_hill() -> EventDef:
	return _fork(
		_iron_story(
			&"stone_from_the_hill", "Stone from the hill", &"settlement", &"hill_stone",
			"The gate's feet are timber, and timber rots, and the hill above the town is "
			+ "entirely stone."
		),
		_answer(
			&"wedge_out_blocks", "Wedge out a few blocks with iron, and set them at the gate",
			"A few blocks were wedged out of the hill with iron and set at the gate's foot, "
			+ "pale and square, and every passer-by stopped to pat them.",
			[_spend(&"wood", 10), _set_flag(&"cut_stone")],
			[_has(&"wood", 10)],
		),
		_answer(
			&"keep_to_timber_and_earth", "Keep to timber and earth",
			"The gate stayed timber and earth, and was mended every spring, and was, in a sense, "
			+ "always new.",
			[_set_flag(&"timber_town")],
		),
		[_earned(&"the_hill_fort")]
	)


func _strangers_words() -> EventDef:
	return _fork(
		_iron_story_about(
			&"strangers_words", "Strangers' words", &"exploration", &"words",
			"{subject} has been talking with the people from the far shore, in a great many "
			+ "gestures and a few words, and has begun to dream in both.",
			VillagerState.TRAIT_CURIOUS
		),
		_answer(
			&"learn_theirs", "Learn their words",
			"{subject} learned their words, a few every evening, and came to the market one "
			+ "morning and said something that made a stranger laugh and clap.",
			[_set_flag(&"learned_words")],
		),
		_answer(
			&"teach_them_ours", "Teach them ours",
			"{subject} taught them the village's words, and for a month the market was full of "
			+ "visitors saying 'good morning' at all hours.",
			[_set_flag(&"taught_words")],
		),
		[_flag_set(&"known_abroad")]
	)


func _a_fire_the_sea_can_see() -> EventDef:
	return _fork(
		_iron_story(
			&"a_fire_the_sea_can_see", "A fire the sea can see", &"settlement", &"sea_fire",
			"The ships that come to the town come late, and the coast has no light to steer "
			+ "them by, and the captains have mentioned it."
		),
		_answer(
			&"light_the_headland", "Light a fire on the headland every night",
			"A fire was built on the headland, and fed every night, and the first ship to "
			+ "steer by it sent a gift of oil.",
			[_spend(&"wood", 4), _set_flag(&"beacon_lit")],
			[_has(&"wood", 4)],
		),
		_answer(
			&"trust_the_stars", "Trust the stars",
			"The captains were told to trust the stars, and a few did, and the rest were seen "
			+ "arriving in the morning, looking relieved.",
			[_set_flag(&"trust_the_stars")],
		),
		[_flag_set(&"known_abroad")]
	)


func _a_stone_with_a_name() -> EventDef:
	return _fork(
		_iron_story_about(
			&"a_stone_with_a_name", "A stone with a name", &"exploration", &"named_stone",
			"{subject} has found a long flat stone at the quarry, and a good deal of "
			+ "enthusiasm for having something say who we are.",
			VillagerState.TRAIT_CURIOUS
		),
		_answer(
			&"stand_it_at_the_crossing", "Stand it up at the crossing",
			"The stone was stood up at the crossing and the name was cut into it, and "
			+ "travellers stopped to read it with an expression of someone who has arrived.",
			[_set_flag(&"standing_stone")],
		),
		_answer(
			&"cut_it_over_the_gate", "Cut it into the stone over the gate",
			"The stone was set over the gate and the name was cut into it, and the gate "
			+ "was suddenly much more of a gate.",
			[_set_flag(&"gate_name")],
		),
		[_flag_set(&"known_abroad"), _not_yet_classical()]
	)


func _a_rider_with_a_sash() -> EventDef:
	return _fork(
		_iron_story(
			&"a_rider_with_a_sash", "A rider with a sash", &"settlement", &"envoy",
			"A rider in a bright sash has come up the road with word from beyond the sea: the "
			+ "town has been talked about, and somebody would like to come and look."
		),
		_answer(
			&"send_a_guide", "Send a guide to meet them on the road",
			"A guide was sent out to meet the rider, and the two came in together, talking, "
			+ "and the rider's horse was given the best stall in the village.",
			[_set_flag(&"envoy_guided")],
		),
		_answer(
			&"wait_at_the_gate_for_them", "Wait for them at the gate",
			"The village waited at the gate, and the rider arrived a day late, and was "
			+ "greeted as if she had been exactly on time.",
			[_set_flag(&"envoy_waited")],
		),
		[_flag_set(&"known_abroad"), _not_yet_classical()]
	)


func _a_table_for_strangers() -> EventDef:
	return _fork(
		_iron_story(
			&"a_table_for_strangers", "A table for strangers", &"settlement", &"guest_table",
			"The guests will arrive within a week, and the question of where they will sit is "
			+ "already causing a great deal of feeling."
		),
		_answer(
			&"lay_a_long_table", "Lay a long table in the lane",
			"A long table went down the lane, and the whole town sat at it, and the guests were "
			+ "put in the middle, which was agreed to be the safest place.",
			[_spend(&"food", 10), _set_flag(&"long_table")],
			[_has(&"food", 10)],
		),
		_answer(
			&"keep_a_night_watch", "Keep a watch on the gate by night",
			"A watch was kept on the gate by night, and was friendly, and a little puzzled by "
			+ "its own friendliness.",
			[_set_flag(&"night_watch")],
		),
		[_flag_set(&"known_abroad"), _not_yet_classical()]
	)


## The two forks that end the Bronze Age's quiet stretch before the gate opens (docs/ages.md I2).
## They expire with the age.
func _red_water() -> EventDef:
	var event: EventDef = _bronze_story(
		&"red_water", "Red water", &"settlement", &"red_water",
		"The marsh pools have gone a rusty red, and the children are wearing it on their feet "
		+ "and will not be told."
	)
	event.requires.append(_cond(SimCondition.Kind.ERA_AT_LEAST, &"", IRON, true))
	return _fork(
		event,
		_answer(
			&"skim_the_scum", "Skim the red scum off the pools into a pot",
			"The red scum was skimmed into a pot and dried in the sun, and became a red powder "
			+ "that stained everything and was, for that reason, interesting.",
			[_set_flag(&"red_scum")],
		),
		_answer(
			&"dig_the_red_mud", "Dig where the mud is thickest",
			"A pit was dug where the mud was thickest, and filled with red, and the first "
			+ "person to put a hand in it looked at it for a long time.",
			[_spend(&"wood", 4), _set_flag(&"red_mud")],
			[_has(&"wood", 4)],
		),
	)


func _fuel_for_the_long_burn() -> EventDef:
	var event: EventDef = _bronze_story(
		&"fuel_for_the_long_burn", "Fuel for the long burn", &"settlement", &"long_burn",
		"Whatever is coming will want a great deal more charcoal than the pit has ever made."
	)
	event.requires.append(_cond(SimCondition.Kind.ERA_AT_LEAST, &"", IRON, true))
	return _fork(
		event,
		_answer(
			&"stack_a_second_pit", "Stack a second charcoal pit",
			"A second pit was stacked beside the first, and the two burned together under a "
			+ "single skin of turf, like twins.",
			[_spend(&"wood", 8), _set_flag(&"second_charcoal_pit")],
			[_has(&"wood", 8)],
		),
		_answer(
			&"wait_for_a_windy_day", "Wait for a day with a good wind",
			"A day with a good wind was waited for, and came, and the pit burned as if it had "
			+ "been listening.",
			[_set_flag(&"waited_for_wind")],
		),
	)


## The Iron Age's one-line moments: the age's feel (furnace smoke, sparks, ploughed lines, ramparts,
## coin, signs, ships), several only after a milestone, a few about a trait and many that remember
## an answer.
func _iron_ambient_lines() -> Array[EventDef]:
	return [
		_iron_ambient(
			&"bloom_in_the_ash",
			"A grey sponge of iron came out of the furnace, glowing, ugly and astonishingly "
			+ "heavy, and was hit by everyone who could reach it.",
			[_earned(&"first_bloom")]
		),
		_iron_ambient(
			&"sparks_at_dusk",
			"Sparks went up from the furnace at dusk in a long orange fountain, and the children "
			+ "counted them until they lost count.",
			[_earned(&"first_bloom")]
		),
		_iron_ambient(
			&"smell_of_hot_iron",
			"The village smelled of charcoal and hot iron for a week, and then stopped noticing.",
			[_earned(&"first_bloom")]
		),
		_iron_ambient(
			&"grain_up_the_ladder",
			"The grain went up the granary ladder in baskets, so full that every climber left a "
			+ "little trail.",
			[_earned(&"fuller_harvest")]
		),
		_iron_ambient(
			&"a_straight_furrow",
			"A line of turned earth ran the whole length of the field, so straight that a "
			+ "stranger took it for a road.",
			[_earned(&"fuller_harvest")]
		),
		_iron_ambient(
			&"shade_of_the_rampart",
			"The shadow of the rampart reached the lane by afternoon, and the dogs moved into it.",
			[_earned(&"the_hill_fort")]
		),
		_iron_ambient(
			&"a_coin_on_a_stone",
			"Somebody dropped a piece of silver on a stone, and a dozen heads turned at the sound.",
			[_earned(&"silver_by_weight")]
		),
		_iron_ambient(
			&"signs_in_the_dust",
			"A child drew the signs in the dust with a stick, and was very cross when somebody "
			+ "read them out.",
			[_earned(&"written_word")]
		),
		_iron_ambient(
			&"a_ship_stays_three_days",
			"A ship put in at dusk and stayed three days, and the village learned some words it "
			+ "would rather not have.",
			[_earned(&"name_abroad")]
		),
		_iron_ambient_about(
			&"watching_the_bloom", VillagerState.TRAIT_CURIOUS,
			"{subject} stood at the furnace until the hammering started, and then stood a little "
			+ "closer.",
			[_earned(&"first_bloom")]
		),
		_iron_ambient_about(
			&"trying_the_edge", VillagerState.TRAIT_INDUSTRIOUS,
			"{subject} tried the new edge on every piece of wood in reach, and was forgiven only "
			+ "by the firewood pile.",
			[_earned(&"first_bloom")]
		),
		_iron_ambient_about(
			&"swallows_in_the_rampart", VillagerState.TRAIT_NATURE_LOVING,
			"{subject} watched swallows nest in the rampart's timbers, and said nothing, and "
			+ "neither did the swallows.",
			[_earned(&"the_hill_fort")]
		),
		_iron_ambient_about(
			&"telling_the_coin", VillagerState.TRAIT_SOCIAL,
			"{subject} told the market that a coin was worth exactly what the market would agree "
			+ "it was, and was applauded.",
			[_earned(&"silver_by_weight")]
		),
		_iron_remembered(
			&"dark_stone_blackened", &"dark_stone_tried",
			"The lump that had blackened in the fire sat by the furnace, and was looked at now "
			+ "and then like a question."
		),
		_iron_remembered(
			&"bell_stone_by_the_furnace", &"dark_stone_bell",
			"The bell-stone was taken down from its beam and set beside the furnace. It rang, "
			+ "now, only when somebody was thinking about it."
		),
		_iron_remembered(
			&"tall_furnace_at_night", &"tall_furnace",
			"The tall furnace glowed at night like a small, angry sunset."
		),
		_iron_remembered(
			&"smoke_from_the_bank", &"bank_furnace",
			"Smoke rose out of the bank itself, as if the hill had taken up a pipe."
		),
		_iron_remembered(
			&"knives_at_dinner", &"iron_knives",
			"Knives came out at every meal, and every one was held up to the light first."
		),
		_iron_remembered(
			&"the_axe_head_goes_round", &"iron_axehead",
			"The one good axe head went from hand to hand like a borrowed hat."
		),
		_iron_remembered(
			&"touching_the_nail", &"door_nails",
			"Every door had its nail, and every nail had been touched for luck."
		),
		_iron_remembered(
			&"soup_in_the_cauldron", &"iron_cauldron",
			"The iron pot hung over the fire all day, and nobody could remember what the soup had "
			+ "been like before."
		),
		_iron_remembered(
			&"glass_in_the_lane", &"slag_lane",
			"The lane glittered like wet glass after the rain."
		),
		_iron_remembered(
			&"fresh_oak_on_the_wind", &"far_oak",
			"The new rampart smelled of fresh oak, and the smell reached the field."
		),
		_iron_remembered(
			&"cut_stone_patted", &"cut_stone",
			"Cut stone stood at the foot of the gate, pale and square, and was patted by "
			+ "everyone who passed."
		),
		_iron_remembered(
			&"the_coin_with_a_tree", &"coin_tree",
			"A small tree was stamped on every coin, and the coin was known all along the road "
			+ "as the Tree."
		),
		_iron_remembered(
			&"the_coin_with_a_face", &"coin_face",
			"A face was stamped on every coin, and everyone was sure it was somebody else's."
		),
		_iron_remembered(
			&"the_touchstone_shines", &"touchstone",
			"The black touchstone by the market had been rubbed so bright that it threw light."
		),
		_iron_remembered(
			&"a_word_in_a_stranger_tongue", &"learned_words",
			"Someone said good morning in a stranger's tongue, and a dog looked up."
		),
		_iron_remembered(
			&"the_stone_at_the_crossing", &"standing_stone",
			"The standing stone threw a long shadow across the crossing, and the children "
			+ "measured themselves against it."
		),
		_iron_remembered(
			&"the_beacon_burns", &"beacon_lit",
			"The beacon on the headland burned all night, and the sea had somewhere to look."
		),
		_iron_remembered(
			&"the_guests_long_table", &"long_table",
			"The long table stood in the lane all evening, and the last guest left with a loaf "
			+ "under each arm."
		),
	]


## An Iron Age line: only in the age, rarer than the Cave Age's, and only when every one of `needs`
## holds.
func _iron_ambient(
	event_id: StringName, line: String, needs: Array[SimCondition] = []
) -> EventDef:
	var event: EventDef = _ambient(event_id, line)
	event.requires = _conds([_cond(SimCondition.Kind.ERA_AT_LEAST, &"", IRON)])
	event.requires.append_array(needs)
	event.chance_per_tick = IRON_AMBIENT_CHANCE
	return event


func _iron_ambient_about(
	event_id: StringName, trait_name: StringName, line: String, needs: Array[SimCondition] = []
) -> EventDef:
	var event: EventDef = _iron_ambient(event_id, line, needs)
	event.category = &"character"
	event.needs_subject = true
	event.subject_requires = _conds([
		_cond(SimCondition.Kind.SUBJECT_HAS_TRAIT, trait_name),
		_cond(SimCondition.Kind.SUBJECT_AT_HOME),
		_cond(SimCondition.Kind.SUBJECT_AWAKE),
	])
	return event


func _iron_remembered(event_id: StringName, flag: StringName, line: String) -> EventDef:
	return _iron_ambient(event_id, line, [_flag_set(flag)])


## ---- The Classical Age (docs/ages.md, "Classical Age") ------------------------------------------
## Streets, water brought in, written law, a square, learning and a stage, and a wider world. Like
## Iron: six hidden milestones staged over the age (`CLASSICAL_DAY`), each with more than one road
## and one road open to every group, small forks between them and quiet lines. Every decision is a
## fork (docs/gameplay.md P13). The turn asks *how* the town takes its place among cities; the
## roads read what the group answered in the Iron Age, but only the guaranteed flags (`letters`,
## `hill_fort`, `coin_struck`, `known_abroad`) are ever required. The age has no gate out (G7);
## its last forks only look toward what a later age could inherit.

const CLASSICAL_TITLES: Dictionary = {
	&"paved_streets": "Paved Streets",
	&"water_from_afar": "Water from Afar",
	&"written_law": "The Law",
	&"the_square": "The Square",
	&"lamp_and_stage": "The Lamp and the Stage",
	&"wider_world": "The Wider World",
}


func _classical_events() -> Array[EventDef]:
	var events: Array[EventDef] = [_a_seat_at_the_table()]
	events.append_array(_classical_milestones())
	events.append_array(_classical_stories())
	events.append_array(_classical_ambient_lines())
	return events


## An Iron fork that only matters while the Iron Age lasts: it is not asked once the next age opens.
func _not_yet_classical() -> SimCondition:
	return _cond(SimCondition.Kind.ERA_AT_LEAST, &"", CLASSICAL, true)


## The turn from the Iron Age to the Classical Age. Fired by the era's hidden gate, so the player is
## never asked whether to go on, only how the town takes its seat. It reads nothing the group may
## lack: the Iron answers are remembered in quiet lines afterwards.
func _a_seat_at_the_table() -> EventDef:
	var event: EventDef = _event(&"a_seat_at_the_table", "A seat at the table", &"settlement")
	event.body = "The strangers who asked the town's name have sent word: the town is big " \
			+ "enough now to be asked to be a city, with a seat at the table of cities, and a " \
			+ "great deal of discussion about who sits where."
	event.choices = _choices([
		_answer(
			&"keep_our_own_ways", "Gather at the stone, and agree how we mean to live",
			"The whole town gathered where everyone could see, and agreed, over a long afternoon "
			+ "and a longer evening, how they meant to live, and the strangers were asked to "
			+ "listen and found they did not mind.",
			[_set_flag(&"path_assembly"), _eff(SimEffect.Kind.ADVANCE_ERA, &"classical")],
		),
		_answer(
			&"take_a_place_among_theirs", "Send for their laws, and take a place among theirs",
			"A ship went out for the far shore's laws, and came back with a great deal of "
			+ "writing and a few people who wanted to see how the town did it, and the town "
			+ "was a city before the ink was dry.",
			[_set_flag(&"path_league"), _eff(SimEffect.Kind.ADVANCE_ERA, &"classical")],
		),
	])
	return event


## Every Classical milestone event: Classical Age, far enough into it, and not yet earned.
func _classical_milestone(
	event_id: StringName, title: String, category: StringName, favoured: StringName,
	era_day: int, milestone: StringName
) -> EventDef:
	var event: EventDef = _milestone_event(event_id, title, category, favoured)
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", CLASSICAL),
		_cond(SimCondition.Kind.ERA_DAYS_AT_LEAST, &"", era_day),
		_cond(SimCondition.Kind.ACHIEVEMENT_EARNED, milestone, 0, true),
	])
	return event


## One road to a Classical milestone: the answer sets its own flag, may do something else, and
## earns it.
func _classical_route(
	choice_id: StringName, label: String, line: String, flag: StringName,
	milestone: StringName, extra: Array[SimEffect] = [], needs: Array[SimCondition] = []
) -> ChoiceDef:
	var effects: Array[SimEffect] = [_set_flag(flag)]
	effects.append_array(extra)
	effects.append(_earn(milestone, CLASSICAL_TITLES[milestone]))
	return _answer(choice_id, label, line, effects, needs)


## A decision that is a road to a milestone; `needs` are further requirements on the event.
func _classical_road(
	event_id: StringName, title: String, body: String, milestone: StringName, era_day: int,
	favoured: StringName, answers: Array[ChoiceDef], needs: Array[SimCondition] = [],
	category: StringName = &"settlement"
) -> EventDef:
	var event: EventDef = _classical_milestone(
		event_id, title, category, favoured, era_day, milestone
	)
	event.body = body
	event.requires.append_array(needs)
	event.choices = _choices(answers)
	return event


func _classical_milestones() -> Array[EventDef]:
	var events: Array[EventDef] = []
	events.append_array(_paved_streets_roads())
	events.append_array(_water_from_afar_roads())
	events.append_array(_written_law_roads())
	events.append_array(_the_square_roads())
	events.append_array(_lamp_and_stage_roads())
	events.append_array(_wider_world_roads())
	return events


## Paved Streets. Dressed stone for a town that cut its own (`cut_stone`), stone against timber for
## one that did not (`timber_town`), and, late and for every group, the doorsteps and a common walk.
func _paved_streets_roads() -> Array[EventDef]:
	var day: int = CLASSICAL_DAY[&"paved_streets"]
	var milestone: StringName = &"paved_streets"
	return [
		_classical_road(
			&"stone_for_the_street", "Stone for the street",
			"The masons who cut the hill's stone have noticed that the lane is still mud, and "
			+ "have offered, with the air of people making a casual remark, to do something about it.",
			milestone, day, VillagerState.TRAIT_INDUSTRIOUS, [
				_classical_route(
					&"lay_broad_slabs", "Lay broad slabs down the middle",
					"Broad slabs went down the middle of the lane, and the first wet morning "
					+ "everyone walked up and down it for no reason except that their feet were dry.",
					&"streets_slabbed", milestone, [_spend(&"wood", 10)], [_has(&"wood", 10)],
				),
				_classical_route(
					&"lay_small_setts", "Set small stones close, in curves",
					"Small stones were set close in curves, a whole street of them, and a mason "
					+ "was seen kneeling in the lane in the evening, admiring it.",
					&"streets_setted", milestone,
				),
			], [_flag_set(&"cut_stone")]
		),
		_classical_road(
			&"timber_meets_stone", "Timber meets stone",
			"The town has always been timber, and the street is the one place where timber "
			+ "does not last, and there is a pile of good stone at the quarry.",
			milestone, day, VillagerState.TRAIT_INDUSTRIOUS, [
				_classical_route(
					&"stone_along_the_lane", "Edge the lane in stone, and leave the middle",
					"The lane was edged in stone, and the middle was left to be walked firm, "
					+ "and the town agreed that it looked like a street at last.",
					&"lane_edged", milestone, [_spend(&"wood", 8)], [_has(&"wood", 8)],
				),
				_classical_route(
					&"pave_the_courtyards", "Pave the courtyards between the houses first",
					"The courtyards between the houses were paved before the lane was, so that "
					+ "every household had a dry place to stand and complain about the lane.",
					&"courtyards_paved", milestone,
				),
			], [_flag_set(&"timber_town")]
		),
		_classical_road(
			&"shared_doorsteps", "Doorsteps",
			"Every house has a doorstep of some kind, and no two of them agree, and the lane "
			+ "has begun to look like an argument.",
			milestone, CLASSICAL_DAY[&"shared_steps"], VillagerState.TRAIT_SOCIAL, [
				_classical_route(
					&"pave_every_step", "Pave every doorstep alike",
					"Every doorstep was paved alike, and the lane stopped looking like an "
					+ "argument and started looking like a town.",
					&"doorsteps_paved", milestone,
				),
				_classical_route(
					&"lay_a_common_walk", "Lay a common walk past all the doors",
					"A common walk was laid past all the doors, and the doorsteps were left to "
					+ "their owners, and the walk made the whole lane look finished.",
					&"common_walk", milestone,
				),
			]
		),
	]


## Water from Afar. A well grown into a cistern or a channel (`well_dug`), a spring brought in on
## arches or in a covered channel (`well_carriers`), and, late and for every group, the rain.
func _water_from_afar_roads() -> Array[EventDef]:
	var day: int = CLASSICAL_DAY[&"water_from_afar"]
	var milestone: StringName = &"water_from_afar"
	return [
		_classical_road(
			&"the_old_well_grows", "The old well",
			"The well is deep and cold and reliable, and the town has outgrown it, and a long "
			+ "queue has begun to form at it each morning.",
			milestone, day, VillagerState.TRAIT_INDUSTRIOUS, [
				_classical_route(
					&"deepen_into_a_cistern", "Deepen it into a cistern with a vaulted roof",
					"The well was widened and deepened and roofed in stone, and the first "
					+ "bucket drawn from the cistern was passed round like a prize.",
					&"cistern_dug", milestone, [_spend(&"wood", 10)], [_has(&"wood", 10)],
				),
				_classical_route(
					&"lead_a_channel_from_it", "Lead a channel out from it into the lane",
					"A narrow channel was led out from the well along the lane, and children "
					+ "followed the first trickle of water all the way to the end.",
					&"well_channel", milestone,
				),
			], [_flag_set(&"well_dug")], &"nature"
		),
		_classical_road(
			&"water_by_the_carriers", "Water by the carriers",
			"The water-carriers have carried water to the town for years, and have begun to "
			+ "mention, in passing, how far the spring is, and how heavy a bucket is.",
			milestone, day, VillagerState.TRAIT_INDUSTRIOUS, [
				_classical_route(
					&"raise_arches_from_the_spring", "Raise arches and bring the spring in",
					"Arches marched down from the spring toward the town, one a day, and the "
					+ "carriers stood under them and looked up, slightly lost.",
					&"spring_arches", milestone, [_spend(&"wood", 12)], [_has(&"wood", 12)],
				),
				_classical_route(
					&"lay_a_covered_channel", "Lay a low covered channel along the ground",
					"A covered channel was laid along the ground from the spring, so quiet "
					+ "that on the first day half the town stood over it listening.",
					&"covered_channel", milestone,
				),
			], [_flag_set(&"well_carriers")], &"nature"
		),
		_classical_road(
			&"rain_into_a_basin", "Rain into a basin",
			"It rains a great deal, and none of it is kept, and a few people have begun to "
			+ "look upward in a speculative way.",
			milestone, CLASSICAL_DAY[&"rain_basin"], VillagerState.TRAIT_NATURE_LOVING, [
				_classical_route(
					&"roofs_feed_a_basin", "Let the roofs feed a stone basin",
					"The roofs were set to feed a stone basin, and after the next rain it "
					+ "was full, and a heron came and stood in it with an owner's air.",
					&"roof_basin", milestone,
				),
				_classical_route(
					&"line_a_ditch", "Line the old ditch with clay and fill it",
					"The old ditch was lined with clay and filled, and became, almost "
					+ "overnight, the place where everyone met.",
					&"lined_channel", milestone,
				),
			], [], &"nature"
		),
	]


## The Law (needs Paved Streets). Agreements cut in stone or kept by readers for a town that gathered
## (`path_assembly`), a neighbour's code or a charter for a town that joined (`path_league`), and,
## late and for every group, the promises people already make to each other.
func _written_law_roads() -> Array[EventDef]:
	var day: int = CLASSICAL_DAY[&"written_law"]
	var milestone: StringName = &"written_law"
	var needs: Array[SimCondition] = [_earned(&"paved_streets")]
	return [
		_classical_road(
			&"words_for_the_household", "What the households agreed",
			"The town agreed a great deal in one long afternoon, and has begun to disagree "
			+ "about what it agreed, and the writing is the obvious answer.",
			milestone, day, VillagerState.TRAIT_SOCIAL, [
				_classical_route(
					&"cut_the_agreements", "Cut the agreements into stone, where all can read",
					"The agreements were cut into a wall of stone in the square, and a small "
					+ "crowd gathered to check that they were as they remembered.",
					&"agreements_cut", milestone,
				),
				_classical_route(
					&"appoint_readers", "Appoint readers, by turns, to say them aloud",
					"Readers were appointed by turns, and each took the job very seriously, "
					+ "and one added a pause that everyone now expects.",
					&"rotating_readers", milestone,
				),
			], _plus(needs, [_flag_set(&"path_assembly")]), &"character"
		),
		_classical_road(
			&"a_neighbours_code", "A neighbour's code",
			"The far shore's laws are long and thorough, and some of them are plainly meant "
			+ "for a different sort of town, and somebody has to choose.",
			milestone, day, VillagerState.TRAIT_CURIOUS, [
				_classical_route(
					&"adapt_their_code", "Adapt their code to the town's ways",
					"The code was adapted line by line, and a good many lines were crossed out "
					+ "with a flourish, and the town found it liked its own handwriting.",
					&"code_adapted", milestone,
				),
				_classical_route(
					&"write_a_charter", "Write a charter of what the towns owe each other",
					"A charter was written of what the towns owed each other, and signed by "
					+ "people who had never seen each other, and it held.",
					&"charter_written", milestone,
				),
			], _plus(needs, [_flag_set(&"path_league")]), &"character"
		),
		_classical_road(
			&"a_promise_worth_keeping", "A promise worth keeping",
			"People have always made promises to each other, and most were kept, and the few "
			+ "that were not are remembered in great detail.",
			milestone, CLASSICAL_DAY[&"promises"], VillagerState.TRAIT_SOCIAL, [
				_classical_route(
					&"record_it_in_stone", "Record the promises in stone, in the square",
					"The promises were recorded in stone, and the first person to break one "
					+ "was gently walked to the stone and asked to read it.",
					&"promises_in_stone", milestone,
				),
				_classical_route(
					&"keep_it_on_tablets", "Keep them on tablets, in the care of a keeper",
					"The promises were kept on tablets, and a keeper was found who loved "
					+ "tablets, and the town made a note never to lose her.",
					&"promises_on_tablets", milestone,
				),
			], needs
		),
	]


## The Square (needs The Law). The market that grew (`market_day`), the council that needs somewhere to
## sit (`council`), and, late and for every group, shade and a place to meet.
func _the_square_roads() -> Array[EventDef]:
	var day: int = CLASSICAL_DAY[&"the_square"]
	var milestone: StringName = &"the_square"
	var needs: Array[SimCondition] = [_earned(&"written_law")]
	return [
		_classical_road(
			&"the_market_grows", "The market grows",
			"The market day has outgrown the lane it began in, and the stalls have begun to "
			+ "spill into the street, and the street has opinions.",
			milestone, day, VillagerState.TRAIT_SOCIAL, [
				_classical_route(
					&"stalls_under_awnings", "Give the stalls awnings and a paved floor",
					"The stalls were given awnings and a paved floor, and the market became a "
					+ "place with a roof of coloured cloth that glowed on bright days.",
					&"awning_market", milestone, [_spend(&"wood", 8)], [_has(&"wood", 8)],
				),
				_classical_route(
					&"a_shared_meal_day", "Make the market day a day of shared meals",
					"The market day became a day when everyone brought a dish, and a table "
					+ "ran down the middle of the market, and nobody left hungry.",
					&"shared_meal_day", milestone,
				),
			], _plus(needs, [_flag_set(&"market_day")])
		),
		_classical_road(
			&"where_the_council_sits", "Where the council sits",
			"The council meets in whatever place is dry, and has twice been rained on in the "
			+ "middle of a decision, and has noticed the pattern.",
			milestone, day, VillagerState.TRAIT_SOCIAL, [
				_classical_route(
					&"open_the_meeting_to_all", "Open the meetings to anyone who comes",
					"The meetings were opened to anyone who came, and the first one was so "
					+ "crowded that the roof of a nearby house was used as a gallery.",
					&"open_meeting", milestone,
				),
				_classical_route(
					&"hold_hearings_by_turns", "Hold hearings by turns, with a bench for each",
					"Hearings were held by turns, with a bench for each, and a person was "
					+ "found whose job was to say when a turn was over.",
					&"hearing_turns", milestone,
				),
			], _plus(needs, [_flag_set(&"council")])
		),
		_classical_road(
			&"a_shaded_place", "A shaded place",
			"The middle of the town is a hot, bare, busy place, and everyone meets in it, and "
			+ "nobody lingers.",
			milestone, CLASSICAL_DAY[&"shade"], VillagerState.TRAIT_NATURE_LOVING, [
				_classical_route(
					&"raise_a_colonnade", "Raise a colonnade along one side",
					"A colonnade was raised along one side, and by noon the whole town was "
					+ "in its shade, and by evening so were the dogs.",
					&"colonnade", milestone,
				),
				_classical_route(
					&"pave_an_open_court", "Pave an open court, and plant it",
					"An open court was paved and planted with a few trees, which were "
					+ "watered by a rota and admired by everyone.",
					&"paved_court", milestone,
				),
			], needs
		),
	]


## The Lamp and the Stage (needs The Square). Strangers' words kept (`learned_words`) or taught
## (`taught_words`), a festival of the whole town (`festival`), and, late and for every group, a
## bench to read on and a table to learn at.
func _lamp_and_stage_roads() -> Array[EventDef]:
	var day: int = CLASSICAL_DAY[&"lamp_and_stage"]
	var milestone: StringName = &"lamp_and_stage"
	var needs: Array[SimCondition] = [_earned(&"the_square")]
	return [
		_classical_road(
			&"their_words_in_ink", "Their words, in ink",
			"The words of the far shore, learned a few at a time, are now long enough to want "
			+ "writing down, and somebody has to decide where they should live.",
			milestone, day, VillagerState.TRAIT_CURIOUS, [
				_classical_route(
					&"keep_them_in_a_library", "Keep them in a room with shelves",
					"A room was set aside, with shelves, and a lamp that was lit each evening, "
					+ "and a rule about not eating near the shelves.",
					&"library_kept", milestone, [_spend(&"wood", 8)], [_has(&"wood", 8)],
				),
				_classical_route(
					&"teach_them_in_a_school", "Teach them to children, in a school",
					"A school was begun, with a few benches and a teacher who was both "
					+ "patient and wrong about a number of things, and the children loved it.",
					&"school_started", milestone,
				),
			], _plus(needs, [_flag_set(&"learned_words")]), &"character"
		),
		_classical_road(
			&"ours_for_their_ears", "Ours, for their ears",
			"The visitors have learned the town's words, and are asking whether they could "
			+ "have them written down, and the town has realised that it could.",
			milestone, day, VillagerState.TRAIT_CURIOUS, [
				_classical_route(
					&"write_ours_for_visitors", "Write a primer of the town's words",
					"A primer of the town's words was written, with pictures, and the first "
					+ "copy was borrowed and returned with two pages of questions.",
					&"primer_written", milestone,
				),
				_classical_route(
					&"host_a_teaching_court", "Host a court where anyone may come and learn",
					"A court was set aside where anyone might come and learn, and it was so "
					+ "full on the first day that the lesson moved outside.",
					&"teaching_court", milestone,
				),
			], _plus(needs, [_flag_set(&"taught_words")]), &"character"
		),
		_classical_road(
			&"a_festival_for_the_whole_town", "A festival for the whole town",
			"The festival has become too large for the lane it was held in, and has gathered "
			+ "so many songs that the older ones have begun to be forgotten.",
			milestone, day, VillagerState.TRAIT_SOCIAL, [
				_classical_route(
					&"build_a_stage", "Build a stage, so that everyone can see",
					"A stage of planks went up, and the first thing anyone did on it was "
					+ "stand still in silence, to see how it felt.",
					&"stage_built", milestone, [_spend(&"wood", 8)], [_has(&"wood", 8)],
				),
				_classical_route(
					&"tell_it_in_the_court", "Tell it in the court, one voice at a time",
					"The stories were told in the court, one voice at a time, with the rest "
					+ "seated in rings, and the best teller was carried home.",
					&"told_in_court", milestone,
				),
			], _plus(needs, [_flag_set(&"festival")])
		),
		_classical_road(
			&"a_bench_for_reading", "A bench for reading",
			"A lot has been written, and nobody has anywhere comfortable to read it, and a few "
			+ "people have begun to read standing up, reproachfully.",
			milestone, CLASSICAL_DAY[&"reading_bench"], VillagerState.TRAIT_CURIOUS, [
				_classical_route(
					&"a_reading_bench", "Put a long bench under the colonnade or a tree",
					"A long bench was put in the shade, and was occupied from morning to "
					+ "evening by people reading very slowly, and nodding.",
					&"reading_bench", milestone,
				),
				_classical_route(
					&"an_open_teaching_table", "Set out a table where anyone may ask",
					"A table was set out with a lamp and a few tablets, and anyone might sit "
					+ "and ask, and the questions were better than the answers.",
					&"teaching_table", milestone,
				),
			], needs, &"character"
		),
	]


## The Wider World (needs The Square and Water from Afar). Visiting towns hosted or delegates
## exchanged for a town that gathered, harbours linked or roads kept for one that joined, and, late
## and for every group, craftspeople on the road. Each sets `towns_connected`, which a later age
## reads as `far_shore` and `known_abroad` were read here.
func _wider_world_roads() -> Array[EventDef]:
	var day: int = CLASSICAL_DAY[&"wider_world"]
	var milestone: StringName = &"wider_world"
	var needs: Array[SimCondition] = [_earned(&"the_square"), _earned(&"water_from_afar")]
	return [
		_classical_road(
			&"visitors_at_the_gate", "Visitors at the gate",
			"More towns than one have heard that the town has a square and a law, and some "
			+ "of their people have turned up at the gate with the air of having been invited.",
			milestone, day, VillagerState.TRAIT_SOCIAL, [
				_classical_route(
					&"host_the_visiting_towns", "Host the visiting towns, a few days each",
					"Visiting towns were hosted in turn, a few days each, and the town learned "
					+ "how many ways there are of cooking the same bean.",
					&"hosts_welcomed", milestone, _connected(),
				),
				_classical_route(
					&"exchange_delegates", "Exchange delegates, who live in each other's homes",
					"Delegates were exchanged, and lived in each other's houses for a season, "
					+ "and came home with new words for the weather.",
					&"delegates_exchanged", milestone, _connected(),
				),
			], _plus(needs, [_flag_set(&"path_assembly")]), &"exploration"
		),
		_classical_road(
			&"the_web_of_towns", "The web of towns",
			"The towns that share the far shore's laws have begun to ask the town to hold up "
			+ "its end of things, in a friendly way, with a great many ships.",
			milestone, day, VillagerState.TRAIT_CURIOUS, [
				_classical_route(
					&"link_the_harbour_towns", "Link the harbours, with lights and a shared tide-table",
					"The harbours were linked, with lights on every headland and a shared "
					+ "table of the tides, and a ship from three towns away arrived on time.",
					&"harbours_linked", milestone, _connected(),
				),
				_classical_route(
					&"keep_the_shared_roads", "Keep the shared roads, a stretch each",
					"The roads between the towns were shared out, a stretch each, and the town "
					+ "took its stretch very seriously, and mended it in the first week.",
					&"shared_roads", milestone, _connected(),
				),
			], _plus(needs, [_flag_set(&"path_league")]), &"exploration"
		),
		_classical_road(
			&"craftspeople_on_the_road", "Craftspeople on the road",
			"The town's craftspeople are better than they were, and have begun to be asked "
			+ "for, in other towns, by name.",
			milestone, CLASSICAL_DAY[&"teachers_abroad"], VillagerState.TRAIT_CURIOUS, [
				_classical_route(
					&"send_teachers_abroad", "Send some to teach for a season, and come home",
					"Some of the craftspeople went abroad for a season to teach, and came "
					+ "home with their hands slightly changed and a good many apprentices.",
					&"teachers_abroad", milestone, _connected(),
				),
				_classical_route(
					&"join_the_market_circuit", "Join the circuit of markets, a day at each",
					"The town joined the circuit of markets, a day at each, and the carts "
					+ "went round in a great slow wheel that nobody had planned.",
					&"market_circuit", milestone, _connected(),
				),
			], needs, &"exploration"
		),
	]


## The effect every road to the last milestone shares: the towns are connected, which a later age
## reads as `known_abroad` is read here.
func _connected(more: Array[SimEffect] = []) -> Array[SimEffect]:
	var effects: Array[SimEffect] = [_set_flag(&"towns_connected")]
	effects.append_array(more)
	return effects


## Small story decisions that fill the Classical Age between its milestones, paced by
## `CLASSICAL_STORY_DAY`. Like the Iron Age's, each has two answers that do something, a journal line
## each, and a flag a later line remembers. The last three look toward what a later age could inherit.
func _classical_story(
	event_id: StringName, title: String, category: StringName, day_key: StringName, body: String
) -> EventDef:
	var event: EventDef = _event(event_id, title, category)
	event.body = body
	event.requires = _conds([
		_cond(SimCondition.Kind.ERA_AT_LEAST, &"", CLASSICAL),
		_cond(SimCondition.Kind.ERA_DAYS_AT_LEAST, &"", CLASSICAL_STORY_DAY[day_key]),
	])
	event.chance_per_tick = STORY_CHANCE
	event.once = true
	return event


func _classical_story_about(
	event_id: StringName, title: String, category: StringName, day_key: StringName, body: String,
	favoured: StringName
) -> EventDef:
	var event: EventDef = _classical_story(event_id, title, category, day_key, body)
	event.needs_subject = true
	event.subject_requires = _conds([_cond(SimCondition.Kind.SUBJECT_AT_HOME)])
	event.trait_weights[favoured] = 3.0
	return event


func _classical_stories() -> Array[EventDef]:
	return [
		_where_guests_meet(), _who_sweeps_the_streets(), _a_masons_apprentice(),
		_rain_on_the_paving(), _whose_courtyard(), _the_bathhouse(), _who_keeps_the_channel(),
		_a_shaded_basin(), _whose_words_are_read(), _a_seal_for_the_charter(),
		_newcomers_and_the_agreements(), _by_daylight_or_lamplight(), _visiting_craftspeople(),
		_a_visiting_book(), _a_play(), _where_to_teach(), _a_harbour_signal(), _words_brought_home(),
		_who_keeps_the_water_running(), _a_book_for_the_journey(), _when_the_market_returns(),
	]


func _where_guests_meet() -> EventDef:
	return _fork(
		_classical_story(
			&"where_guests_meet", "Where guests meet", &"settlement", &"guest_ground",
			"The town is a city now, and guests arrive daily, and nobody has agreed where "
			+ "they should be received."
		),
		_answer(
			&"receive_them_at_the_gate", "Receive them in the court inside the gate",
			"Guests were received in the court inside the gate, under the old hill-fort's "
			+ "wall, and were visibly impressed by it, and by being offered a seat.",
			[_set_flag(&"guests_at_the_gate")],
		),
		_answer(
			&"receive_them_at_the_lane_end", "Receive them at the end of the lane, by the water",
			"Guests were received where the lane met the water, and were handed a cup before "
			+ "they were asked their business, which turned out to be a very good order.",
			[_set_flag(&"guests_at_the_water")],
		),
	)


func _who_sweeps_the_streets() -> EventDef:
	return _fork(
		_classical_story_about(
			&"who_sweeps_the_streets", "Who sweeps the first streets", &"character",
			&"street_turns",
			"A street that is paved is a street that can be swept, and {subject} has noticed "
			+ "that nobody has said who sweeps it.",
			VillagerState.TRAIT_SOCIAL
		),
		_answer(
			&"neighbours_take_turns", "Let the neighbours take turns, a day each",
			"The neighbours took turns, a day each, and the sweeping was done with a great "
			+ "deal of conversation and not much sweeping.",
			[_set_flag(&"street_turns")],
		),
		_answer(
			&"share_to_a_sweeper", "Give a share of food to someone who will do it every day",
			"Someone was found who would sweep every day for a share of food, and the lane "
			+ "became so clean that people began to remove their shoes.",
			[_spend(&"food", 3), _set_flag(&"street_sweeper")],
			[_has(&"food", 3)],
		),
		[_earned(&"paved_streets")]
	)


func _a_masons_apprentice() -> EventDef:
	return _fork(
		_classical_story_about(
			&"a_masons_apprentice", "A mason's apprentice", &"character", &"mason_apprentice",
			"{subject} has been following the masons about, handing them things before they "
			+ "ask, and has begun to explain to others how the stone wants to be cut.",
			VillagerState.TRAIT_INDUSTRIOUS
		),
		_answer(
			&"take_them_on", "Take them on as the masons' apprentice",
			"{subject} became the masons' apprentice, and for the first month did nothing "
			+ "but sweep, and for the second month, polish, and was happier than anyone.",
			[_set_flag(&"mason_apprentice")],
		),
		_answer(
			&"every_household_learns_stone", "Let every household learn a little stonework",
			"Every household learned a little stonework, mostly how not to drop a block on a "
			+ "foot, and the town's doorsteps improved sharply.",
			[_set_flag(&"stonework_shared")],
		),
	)


func _rain_on_the_paving() -> EventDef:
	return _fork(
		_classical_story(
			&"rain_on_the_paving", "Rain on the paving", &"nature", &"paving_rain",
			"The first heavy rain on the new paving made a river of the lane, which was "
			+ "paved, and so ran very fast."
		),
		_answer(
			&"cut_a_gutter", "Cut a gutter along the lane's edge",
			"A gutter was cut along the lane's edge, and the next rain ran neatly into it, "
			+ "and the children floated sticks down it, and held races.",
			[_spend(&"wood", 6), _set_flag(&"street_gutters")],
			[_has(&"wood", 6)],
		),
		_answer(
			&"let_it_run_to_the_water", "Let it run, and tilt the lane toward the river",
			"The lane was tilted toward the river a little more each week, and the rain "
			+ "learned the way, and the lane was dry by noon.",
			[_set_flag(&"street_tilted")],
		),
		[_earned(&"paved_streets")]
	)


func _whose_courtyard() -> EventDef:
	return _fork(
		_classical_story_about(
			&"whose_courtyard", "Whose courtyard stays open", &"character", &"courtyard",
			"The paved courtyard between the houses has become the best place in town, and "
			+ "{subject} has noticed that the weavers want a roof over it, and the children do not.",
			VillagerState.TRAIT_SOCIAL
		),
		_answer(
			&"keep_it_open", "Keep it open to the sky",
			"The courtyard was kept open to the sky, and the children were let in at once, and "
			+ "the weavers took their looms out on bright days and said it was an improvement.",
			[_set_flag(&"courtyard_open")],
		),
		_answer(
			&"roof_it_for_the_weavers", "Roof one half of it for the weavers",
			"One half was roofed for the weavers, and the other left open, and the children "
			+ "were seen to be playing under the roof and not the sky, to everyone's surprise.",
			[_spend(&"wood", 6), _set_flag(&"courtyard_roofed")],
			[_has(&"wood", 6)],
		),
		[_earned(&"paved_streets")]
	)


func _the_bathhouse() -> EventDef:
	return _fork(
		_classical_story(
			&"the_bathhouse", "Warm water", &"settlement", &"baths",
			"Water is coming into the town, and the question of what to do with it has "
			+ "become, overnight, a matter of strong feeling."
		),
		_answer(
			&"raise_a_bathhouse", "Raise a bathhouse by the basin, for everyone",
			"A bathhouse went up by the basin, with a hot room and a cool one, and the whole "
			+ "town went in on the first evening and came out looking amazed.",
			[_spend(&"wood", 12), _set_flag(&"bathhouse")],
			[_has(&"wood", 12)],
		),
		_answer(
			&"heat_water_at_home", "Let each household heat its own water",
			"Every household heated its own water, and the smoke of a hundred little fires "
			+ "went up on bath day, and the whole town smelled of herbs.",
			[_set_flag(&"home_baths")],
		),
		[_earned(&"water_from_afar")]
	)


func _who_keeps_the_channel() -> EventDef:
	return _fork(
		_classical_story_about(
			&"who_keeps_the_channel", "Who keeps the channel clear", &"character",
			&"channel_keepers",
			"The water runs, and leaves collect in it, and {subject} has been seen fishing "
			+ "them out in a martyred way.",
			VillagerState.TRAIT_INDUSTRIOUS
		),
		_answer(
			&"a_keeper_by_turns", "A keeper by turns, a month each",
			"A keeper was named by turns, a month each, and the channel was never clearer, "
			+ "and each keeper's month was remembered for its particular leaf.",
			[_set_flag(&"channel_turns")],
		),
		_answer(
			&"every_house_clears_its_own", "Every house clears its own stretch",
			"Every house cleared its own stretch, and the stretches were kept with different "
			+ "degrees of care, and the town ran a friendly competition.",
			[_set_flag(&"channel_stretches")],
		),
		[_earned(&"water_from_afar")]
	)


func _a_shaded_basin() -> EventDef:
	return _fork(
		_classical_story(
			&"a_shaded_basin", "A place by the basin", &"nature", &"shaded_basin",
			"The basin is the coolest place in town, and the whole town has noticed, and "
			+ "there is nowhere to sit."
		),
		_answer(
			&"plant_it_with_shade", "Plant it round with shade trees",
			"Shade trees were planted round the basin, and for a few years looked like "
			+ "twigs, and then, suddenly, like a grove.",
			[_set_flag(&"basin_trees")],
		),
		_answer(
			&"build_it_a_bench", "Set a bench of stone beside it",
			"A bench of stone was set beside the basin, and was occupied from the first "
			+ "morning, and a small queue formed for the best end.",
			[_spend(&"wood", 4), _set_flag(&"basin_bench")],
			[_has(&"wood", 4)],
		),
		[_earned(&"water_from_afar")]
	)


func _whose_words_are_read() -> EventDef:
	return _fork(
		_classical_story_about(
			&"whose_words_are_read", "Whose words are read aloud", &"character", &"readers",
			"The written laws are read aloud, and {subject} has noticed that the voice that "
			+ "reads them shapes how they sound.",
			VillagerState.TRAIT_SOCIAL
		),
		_answer(
			&"the_clearest_voice", "Let the clearest voice read, always",
			"The clearest voice was asked to read, and read so well that people came from "
			+ "other streets to listen, and some of them even heard the laws.",
			[_set_flag(&"one_reader")],
		),
		_answer(
			&"everyone_reads_a_line", "Let everyone read a line, in turn",
			"Everyone read a line in turn, and the laws were read with a variety of voices, "
			+ "and a child read the longest word and was applauded.",
			[_set_flag(&"everyone_reads")],
		),
		[_earned(&"written_law")]
	)


func _a_seal_for_the_charter() -> EventDef:
	return _fork(
		_classical_story(
			&"a_seal_for_the_charter", "A seal for the charter", &"settlement", &"seal",
			"The laws have been written, and a great many of them need a mark to show that "
			+ "they are the town's, and somebody has suggested the old coin."
		),
		_answer(
			&"the_trees_seal", "Cut the seal as a tree",
			"The seal was cut as a tree, and the first law sealed with it was a law about "
			+ "trees, which was thought to be funny.",
			[_set_flag(&"seal_tree")],
		),
		_answer(
			&"the_faces_seal", "Cut the seal as a face",
			"The seal was cut as a face, and the first law sealed with it was one about "
			+ "faces, and nobody thought it was funny at all.",
			[_set_flag(&"seal_face")],
		),
		[_earned(&"written_law")]
	)


func _newcomers_and_the_agreements() -> EventDef:
	return _fork(
		_classical_story(
			&"newcomers_and_the_agreements", "Newcomers and the agreements", &"settlement",
			&"newcomers",
			"New people keep arriving along the road, and the town's laws are not theirs, "
			+ "and someone has asked how long the old ones have to wait to be read."
		),
		_answer(
			&"read_them_at_the_gate", "Read the town's words to them at the gate",
			"The town's words were read to every newcomer at the gate, in a voice that grew "
			+ "weary and warm, and the newcomers listened with great seriousness.",
			[_set_flag(&"read_at_the_gate")],
		),
		_answer(
			&"give_them_a_neighbour", "Give each newcomer a neighbour to explain it",
			"Every newcomer was given a neighbour, who explained the laws at some length "
			+ "and with some editing, and the neighbours became fast friends.",
			[_set_flag(&"neighbour_guides")],
		),
		[_earned(&"written_law")]
	)


func _by_daylight_or_lamplight() -> EventDef:
	return _fork(
		_classical_story(
			&"by_daylight_or_lamplight", "By daylight or by lamplight", &"settlement",
			&"lamplight",
			"The square is busy all day, and the evening is when people have time to meet, "
			+ "and the council has been asked whether it ought to sit later."
		),
		_answer(
			&"meet_by_daylight", "Meet by daylight, when the square is full",
			"The council kept to daylight, when the square was full, and decisions were "
			+ "made in the presence of a great many onlookers, who sometimes helped.",
			[_set_flag(&"daylight_meetings")],
		),
		_answer(
			&"meet_by_lamplight", "Meet by lamplight, when the day's work is done",
			"The council met by lamplight, with the day's work done, and a good many people "
			+ "arrived with their dinners, and the meetings ran long and warm.",
			[_spend(&"wood", 4), _set_flag(&"lamplight_meetings")],
			[_has(&"wood", 4)],
		),
		[_earned(&"the_square")]
	)


func _visiting_craftspeople() -> EventDef:
	return _fork(
		_classical_story_about(
			&"visiting_craftspeople", "Room for visiting craftspeople", &"character",
			&"craft_visitors",
			"Craftspeople from other towns are asking for room in the square, and {subject} "
			+ "has noticed that the square is the one place that cannot grow.",
			VillagerState.TRAIT_INDUSTRIOUS
		),
		_answer(
			&"give_them_the_colonnade", "Give them a bay each, in the colonnade",
			"Each visiting craftsperson was given a bay in the colonnade, and the square "
			+ "filled with the sound of other towns' tools.",
			[_set_flag(&"colonnade_crafts")],
		),
		_answer(
			&"give_them_a_yard", "Give them a yard behind the square",
			"A yard behind the square was cleared for them, and a gate made, and it became "
			+ "the place where people went to see things being made.",
			[_spend(&"wood", 6), _set_flag(&"craft_yard")],
			[_has(&"wood", 6)],
		),
		[_earned(&"the_square")]
	)


func _a_visiting_book() -> EventDef:
	return _fork(
		_classical_story_about(
			&"a_visiting_book", "A visiting book", &"character", &"book_copy",
			"A traveller has left a book behind, overnight, with a note asking that it be "
			+ "looked after, and {subject} has already read the first page and is not sleeping.",
			VillagerState.TRAIT_CURIOUS
		),
		_answer(
			&"copy_the_book", "Copy it, page by page, before it goes on",
			"The book was copied, page by page, by lamplight, and the copy was bound in "
			+ "leather and set on the shelf with great ceremony.",
			[_spend(&"food", 3), _set_flag(&"book_copied")],
			[_has(&"food", 3)],
		),
		_answer(
			&"gather_the_towns_stories", "Gather the town's own stories instead, and bind those",
			"The town's own stories were gathered and bound, and the first reader found a "
			+ "story about their grandmother and had to sit down.",
			[_set_flag(&"stories_bound")],
		),
		[_earned(&"lamp_and_stage")]
	)


func _a_play() -> EventDef:
	return _fork(
		_classical_story(
			&"a_play", "A play", &"settlement", &"play",
			"Someone has proposed a play, with parts for everyone, and the only question is "
			+ "what it is about."
		),
		_answer(
			&"a_play_about_the_cave", "A play about the cave, and the first fire",
			"The play about the cave was performed by people dressed in furs, and a very "
			+ "small person was a mammoth, and was the best thing in it.",
			[_set_flag(&"play_cave")],
		),
		_answer(
			&"a_play_about_the_voyage", "A play about the first ship across",
			"The play about the voyage was performed with a ship made of chairs, and the "
			+ "audience leaned with it in every wave.",
			[_set_flag(&"play_voyage")],
		),
		[_earned(&"lamp_and_stage")]
	)


func _where_to_teach() -> EventDef:
	return _fork(
		_classical_story_about(
			&"where_to_teach", "Where to teach", &"character", &"teaching",
			"{subject} has begun to teach whoever comes, and has noticed that they teach "
			+ "better in one sort of place than another.",
			VillagerState.TRAIT_SOCIAL
		),
		_answer(
			&"teach_in_a_workshop", "Teach in the workshop, with hands full",
			"The teaching moved into the workshop, where a lesson came with a task, and by "
			+ "the end of the month a dozen people could do the thing.",
			[_set_flag(&"teach_in_workshops")],
		),
		_answer(
			&"teach_in_the_court", "Teach in the open court, with everyone listening",
			"The teaching stayed in the court, where everyone could hear, and a crowd "
			+ "formed, and the lessons were attended by people who had no business learning.",
			[_set_flag(&"teach_in_the_court")],
		),
		[_earned(&"lamp_and_stage")]
	)


func _a_harbour_signal() -> EventDef:
	return _fork(
		_classical_story(
			&"a_harbour_signal", "A sign for the ships", &"settlement", &"harbour_signal",
			"The ships that arrive are many now, and have nothing to tell them which is the "
			+ "town's harbour, apart from the smell of bread."
		),
		_answer(
			&"raise_a_tall_mark", "Raise a tall white mark on the headland",
			"A tall white mark was raised on the headland, and could be seen from far out, "
			+ "and captains began to describe the town as 'the one with the pillar'.",
			[_spend(&"wood", 6), _set_flag(&"tall_mark")],
			[_has(&"wood", 6)],
		),
		_answer(
			&"fly_a_cloth", "Fly a coloured cloth from the old gate",
			"A coloured cloth was flown from the old gate, and was visible only on windy "
			+ "days, and the captains learned to read it.",
			[_set_flag(&"cloth_signal")],
		),
		[_earned(&"wider_world")]
	)


func _words_brought_home() -> EventDef:
	return _fork(
		_classical_story_about(
			&"words_brought_home", "Words brought home", &"exploration", &"words_home",
			"{subject} has come back from the other towns with a head full of words that "
			+ "nobody at home has, and a worrying tendency to use them.",
			VillagerState.TRAIT_CURIOUS
		),
		_answer(
			&"write_the_words_down", "Write them down, with what they mean",
			"The new words were written down, with what they meant, and the town's word-list "
			+ "grew by a page, and then, in an unfortunate week, by three.",
			[_set_flag(&"words_written")],
		),
		_answer(
			&"let_them_spread", "Let them spread by use, and see which stay",
			"The new words were let spread by use, and some stayed, and some did not, and "
			+ "the ones that stayed turned out to be the rude ones.",
			[_set_flag(&"words_spread")],
		),
		[_earned(&"wider_world")]
	)


## The last three look toward what a later age could inherit (docs/ages.md, "Medieval: the
## direction"): who keeps the water running, what travels with a book, and what a market's return
## is owed. They promise nothing; they only set a flag.
func _who_keeps_the_water_running() -> EventDef:
	return _fork(
		_classical_story(
			&"who_keeps_the_water_running", "Who keeps the water running", &"settlement",
			&"water_keepers",
			"The water has run for a long time now, and people have begun to ask who will "
			+ "keep it running when the ones who built it are old."
		),
		_answer(
			&"stewards_by_neighbourhood", "Name a steward for every neighbourhood",
			"A steward was named for every neighbourhood, and each took up a staff and the "
			+ "job, and the water ran as it always had, only with more opinions.",
			[_set_flag(&"water_stewards")],
		),
		_answer(
			&"a_craft_of_the_water", "Let those who build the channels form a craft",
			"The builders of the channels formed a craft, with its own tools and its own "
			+ "habits, and took on apprentices from the first week.",
			[_set_flag(&"water_craft")],
		),
		[_earned(&"water_from_afar")]
	)


func _a_book_for_the_journey() -> EventDef:
	return _fork(
		_classical_story(
			&"a_book_for_the_journey", "A book for the journey", &"settlement", &"journey_book",
			"The books are good and heavy, and the people who travel have begun to ask for "
			+ "one that can go with them."
		),
		_answer(
			&"a_copying_room", "Set a room aside where books are copied",
			"A room was set aside where books were copied, and a smell of ink and warm "
			+ "wax settled over it, and nobody was allowed to hurry.",
			[_set_flag(&"copying_room")],
		),
		_answer(
			&"travelling_teachers", "Train teachers who carry their lessons with them",
			"Teachers were trained to carry their lessons with them, and set off in pairs "
			+ "with satchels, and returned with more lessons than they had left with.",
			[_set_flag(&"travelling_teachers")],
		),
		[_earned(&"lamp_and_stage")]
	)


func _when_the_market_returns() -> EventDef:
	return _fork(
		_classical_story(
			&"when_the_market_returns", "When the market returns", &"settlement",
			&"market_returns",
			"The markets of the other towns come round on a rota, and the town's own comes "
			+ "round on its own, and someone has asked how the rota should be shared."
		),
		_answer(
			&"a_shared_charter", "Write the rota into a charter the towns share",
			"The rota was written into a charter, and signed by all the towns, and the market "
			+ "days fell into a kind of music.",
			[_set_flag(&"market_charter")],
		),
		_answer(
			&"hospitality_on_the_round", "Host each market with a meal, and stay as friends",
			"Each market was met with a meal, and the visitors stayed as friends, and the "
			+ "rota was kept by custom and kindness.",
			[_set_flag(&"market_hospitality")],
		),
		[_earned(&"the_square")]
	)


## The Classical Age's one-line moments: the age's feel (paving, water, the square, lamps, ships),
## several only after a milestone, a few about a trait and many that remember an answer.
func _classical_ambient_lines() -> Array[EventDef]:
	return [
		_classical_ambient(
			&"feet_on_the_paving",
			"The first dry morning on the new paving, the whole town walked up and down it "
			+ "for no reason, listening to its own feet.",
			[_earned(&"paved_streets")]
		),
		_classical_ambient(
			&"a_cart_on_the_stones",
			"A cart went down the paved lane with a noise like a small thunderstorm, and "
			+ "everyone came to the doors to see who had made it.",
			[_earned(&"paved_streets")]
		),
		_classical_ambient(
			&"water_in_the_morning",
			"The water came down the channel at dawn, so clear that the town's reflection "
			+ "ran along it upside-down.",
			[_earned(&"water_from_afar")]
		),
		_classical_ambient(
			&"children_at_the_basin",
			"The children floated bark boats on the basin until the water ran off them, and "
			+ "then, in a stunned silence, they started again.",
			[_earned(&"water_from_afar")]
		),
		_classical_ambient(
			&"the_law_read_at_noon",
			"A line of the law was read aloud at noon in the square, and a small crowd "
			+ "nodded as if it had been said about them personally.",
			[_earned(&"written_law")]
		),
		_classical_ambient(
			&"a_dispute_settled",
			"Two neighbours argued over a fence, and went to the readers, and came home "
			+ "talking, and the fence was moved a hand's breadth.",
			[_earned(&"written_law")]
		),
		_classical_ambient(
			&"noon_in_the_square",
			"At noon the square was full of people, none of whom had a reason to be there "
			+ "except the square.",
			[_earned(&"the_square")]
		),
		_classical_ambient(
			&"pigeons_on_the_stones",
			"Pigeons walked about the square with a proprietary air, and took off all at "
			+ "once when a child ran at them, and landed in the same place.",
			[_earned(&"the_square")]
		),
		_classical_ambient(
			&"a_lamp_in_the_window",
			"A lamp burned late in a window of the learning room, and a second joined it, "
			+ "and a third, and the street was lit in the oddest way.",
			[_earned(&"lamp_and_stage")]
		),
		_classical_ambient(
			&"a_line_forgotten",
			"A player forgot a line on the stage, and the whole audience supplied it, in "
			+ "unison, and the play went on better than before.",
			[_earned(&"lamp_and_stage")]
		),
		_classical_ambient(
			&"a_ship_from_three_towns",
			"A ship came in carrying people from three towns who had never met, and they "
			+ "walked up the lane together arguing cheerfully about directions.",
			[_earned(&"wider_world")]
		),
		_classical_ambient(
			&"a_letter_arrived",
			"A letter arrived from a town nobody had heard of, written in a hand so careful "
			+ "that it was read three times before anyone noticed what it said.",
			[_earned(&"wider_world")]
		),
		_classical_ambient_about(
			&"a_mason_admiring",
			VillagerState.TRAIT_INDUSTRIOUS,
			"{subject} stood at the end of the paved lane at dusk and looked along it, and "
			+ "looked for some time, and did not say what for."
		),
		_classical_ambient_about(
			&"a_listener_at_the_court",
			VillagerState.TRAIT_SOCIAL,
			"{subject} sat in the court in the evening and listened to people arguing "
			+ "politely, and seemed to find it better than any song."
		),
		_classical_ambient_about(
			&"a_reader_at_the_lamp",
			VillagerState.TRAIT_CURIOUS,
			"{subject} was found at the lamp long after everyone else had gone to bed, "
			+ "reading something with a faintly alarmed expression."
		),
		_classical_ambient_about(
			&"a_walker_by_the_channel",
			VillagerState.TRAIT_NATURE_LOVING,
			"{subject} walked along the channel at dawn, and told the water, quietly, where "
			+ "it was going."
		),
		_classical_remembered(
			&"slabs_in_the_rain", &"streets_slabbed",
			"Rain ran off the broad slabs in sheets, and the lane gleamed, and a child "
			+ "wrote a name on it with a wet finger."
		),
		_classical_remembered(
			&"setts_at_dusk", &"streets_setted",
			"The small stones of the street caught the last of the light in a thousand "
			+ "little curves, and a visitor stopped to stare at the ground."
		),
		_classical_remembered(
			&"cistern_echo", &"cistern_dug",
			"A child leaned into the cistern and called, and the cistern called back a "
			+ "good deal more deeply, and the child ran."
		),
		_classical_remembered(
			&"arches_at_sunset", &"spring_arches",
			"The arches stood in a long gold line at sunset, and somebody counted them aloud, "
			+ "and got a different number each time."
		),
		_classical_remembered(
			&"the_agreement_stone", &"agreements_cut",
			"Someone ran a finger down a line of the agreements in the stone, slowly, as if "
			+ "tracing a road."
		),
		_classical_remembered(
			&"the_charter_copied", &"charter_written",
			"A copy of the charter was carried to a far town, and read aloud there, and "
			+ "somebody said it sounded very like home."
		),
		_classical_remembered(
			&"awnings_in_the_wind", &"awning_market",
			"The market awnings filled in the wind like sails, and the stalls beneath them "
			+ "tugged gently at their pegs."
		),
		_classical_remembered(
			&"the_open_meeting", &"open_meeting",
			"The meeting was so open that a goat wandered in and was asked its view, to "
			+ "general approval."
		),
		_classical_remembered(
			&"the_library_lamp", &"library_kept",
			"The library lamp was lit, and a very small boy was found asleep on the lowest "
			+ "shelf, with a scroll for a pillow."
		),
		_classical_remembered(
			&"the_first_night_on_the_stage", &"stage_built",
			"The first night on the stage, a stranger in the crowd wept at the right moment, "
			+ "and was thanked."
		),
		_classical_remembered(
			&"the_harbour_lights", &"harbours_linked",
			"The linked harbours lit their lamps in turn along the coast at dusk, and the "
			+ "town watched the line of light go out to sea."
		),
		_classical_remembered(
			&"the_market_wheel", &"market_circuit",
			"The cart that had gone round the circuit of markets came home with a bell on it "
			+ "that nobody had put there, and a story to go with the bell."
		),
		_classical_remembered(
			&"the_seal_in_the_wax", &"seal_tree",
			"The seal with the tree was pressed into the wax, and the tree came out so clear "
			+ "that a leaf could be counted."
		),
		_classical_remembered(
			&"the_bathhouse_steam", &"bathhouse",
			"Steam rose from the bathhouse into the evening, and the whole street smelled of "
			+ "warm stone and a little of thyme."
		),
		_classical_remembered(
			&"the_standing_stone_seen_again", &"standing_stone",
			"The standing stone at the crossing was found to be wearing a garland, and no "
			+ "one would say who had put it there."
		),
		_classical_remembered(
			&"the_gate_name_in_the_light", &"gate_name",
			"The name over the gate caught the evening sun, and its letters stood out in "
			+ "gold, and a child read them off, one by one, with pride."
		),
		_classical_remembered(
			&"the_long_table_again", &"long_table",
			"Somebody laid the long table in the square for no reason, and by evening the "
			+ "whole town was sitting at it."
		),
		_classical_remembered(
			&"the_guide_remembered", &"envoy_guided",
			"The guide who had met the first rider on the road was asked to meet the next "
			+ "one, and set off with a pleased look and a better cloak."
		),
	]


## A Classical Age line: only in the age, rarer than the earlier ages', and only when every one of
## `needs` holds.
func _classical_ambient(
	event_id: StringName, line: String, needs: Array[SimCondition] = []
) -> EventDef:
	var event: EventDef = _ambient(event_id, line)
	event.requires = _conds([_cond(SimCondition.Kind.ERA_AT_LEAST, &"", CLASSICAL)])
	event.requires.append_array(needs)
	event.chance_per_tick = CLASSICAL_AMBIENT_CHANCE
	return event


func _classical_ambient_about(
	event_id: StringName, trait_name: StringName, line: String, needs: Array[SimCondition] = []
) -> EventDef:
	var event: EventDef = _classical_ambient(event_id, line, needs)
	event.category = &"character"
	event.needs_subject = true
	event.subject_requires = _conds([
		_cond(SimCondition.Kind.SUBJECT_HAS_TRAIT, trait_name),
		_cond(SimCondition.Kind.SUBJECT_AT_HOME),
		_cond(SimCondition.Kind.SUBJECT_AWAKE),
	])
	return event


func _classical_remembered(event_id: StringName, flag: StringName, line: String) -> EventDef:
	return _classical_ambient(event_id, line, [_flag_set(flag)])


func _build_choice(
	choice_id: StringName, label: String, building: StringName, wood: int, from_day: int = 0,
	from_era_day: int = 0
) -> ChoiceDef:
	var choice: ChoiceDef = _choice(choice_id, label)
	choice.requires = _conds([
		_cond(SimCondition.Kind.HAS_BUILDING, building, 0, true),
		_cond(SimCondition.Kind.RESOURCE_AT_LEAST, &"wood", wood),
		_cond(SimCondition.Kind.DAYS_AT_LEAST, &"", from_day),
	])
	if from_era_day > 0:
		choice.requires.append(_cond(SimCondition.Kind.ERA_DAYS_AT_LEAST, &"", from_era_day))
	choice.effects = _effs([_eff(SimEffect.Kind.START_BUILD, building)])
	return choice


func _era(era_id: StringName, display_name: String, order: int) -> EraDef:
	var era: EraDef = EraDef.new()
	era.id = era_id
	era.display_name = display_name
	era.order = order
	return era


func _building(
	building_id: StringName, display_name: String, cost: Dictionary, work_required: int
) -> BuildingDef:
	var building: BuildingDef = BuildingDef.new()
	building.id = building_id
	building.display_name = display_name
	building.cost = _ints(cost)
	building.work_required = work_required
	return building


func _event(event_id: StringName, title: String, category: StringName) -> EventDef:
	var event: EventDef = EventDef.new()
	event.id = event_id
	event.title = title
	event.category = category
	return event


func _choice(choice_id: StringName, label: String) -> ChoiceDef:
	var choice: ChoiceDef = ChoiceDef.new()
	choice.id = choice_id
	choice.label = label
	return choice


func _cond(
	kind: SimCondition.Kind, key: StringName = &"", amount: int = 0, negate: bool = false
) -> SimCondition:
	var condition: SimCondition = SimCondition.new()
	condition.kind = kind
	condition.key = key
	condition.amount = amount
	condition.negate = negate
	return condition


func _eff(
	kind: SimEffect.Kind, key: StringName = &"", amount: int = 0, text: String = ""
) -> SimEffect:
	var effect: SimEffect = SimEffect.new()
	effect.kind = kind
	effect.key = key
	effect.amount = amount
	effect.text = text
	return effect


func _conds(items: Array[SimCondition]) -> Array[SimCondition]:
	return items


func _effs(items: Array[SimEffect]) -> Array[SimEffect]:
	return items


func _choices(items: Array[ChoiceDef]) -> Array[ChoiceDef]:
	return items


func _ints(pairs: Dictionary) -> Dictionary[StringName, int]:
	var typed: Dictionary[StringName, int] = {}
	for key: StringName in pairs:
		typed[key] = int(pairs[key])
	return typed


func _floats(pairs: Dictionary) -> Dictionary[StringName, float]:
	var typed: Dictionary[StringName, float] = {}
	for key: StringName in pairs:
		typed[key] = float(pairs[key])
	return typed


func _save(resource: Resource, path: String) -> void:
	var error: Error = ResourceSaver.save(resource, path, ResourceSaver.FLAG_CHANGE_PATH)
	if error != OK:
		push_error("Could not save %s (error %d)" % [path, error])
