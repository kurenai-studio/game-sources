# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## MapAssembler: the seeded picks and the level they build (docs/ARCHITECTURE.md 3.4).

const Fx: GDScript = preload("res://tests/run/fixtures/run_fixtures.gd")

var catalog: Catalog = null
var data: RunData = null


func before_each() -> void:
	catalog = Fx.catalog()
	data = Fx.run_data()


func _text(level: LevelData) -> String:
	return JSON.stringify(level.to_data(), "", true)


## The picks for fixed seeds, as [boss, top, middle, bottom, packs of bands 1 to 6].
## They depend on the fixtures and on the engine's generator. A change here is a change
## to every run a player has saved, so look before updating them.
func test_picks_are_pinned_for_fixed_seeds() -> void:
	var expected: Dictionary = {
		0: [&"moon_moth", &"top_side", &"mid_side", &"bot_home", [&"band1_pack3", &"band2_pack0", &"band3_pack0", &"band4_pack1", &"band5_pack2", &"band6_pack2"]],
		1: [&"grumblesack", &"top_one", &"mid_bend", &"bot_edge", [&"band1_pack3", &"band2_pack2", &"band3_pack0", &"band4_pack2", &"band5_pack3", &"band6_pack0"]],
		2: [&"old_tusk", &"top_side", &"mid_side", &"bot_home", [&"band1_pack0", &"band2_pack1", &"band3_pack2", &"band4_pack1", &"band5_pack3", &"band6_pack3"]],
		3: [&"grumblesack", &"top_side", &"mid_side", &"bot_home", [&"band1_pack3", &"band2_pack2", &"band3_pack0", &"band4_pack1", &"band5_pack1", &"band6_pack4"]],
		12345: [&"ironshell", &"top_pair", &"mid_bend", &"bot_edge", [&"band1_pack2", &"band2_pack1", &"band3_pack3", &"band4_pack2", &"band5_pack1", &"band6_pack5"]],
		20261023: [&"moon_moth", &"top_one", &"mid_bend", &"bot_edge", [&"band1_pack1", &"band2_pack2", &"band3_pack1", &"band4_pack1", &"band5_pack1", &"band6_pack2"]],
		4294967295: [&"old_tusk", &"top_twin", &"mid_merge", &"bot_home", [&"band1_pack1", &"band2_pack3", &"band3_pack3", &"band4_pack0", &"band5_pack2", &"band6_pack3"]],
	}
	for run_seed: int in expected.keys():
		var picks: Dictionary = MapAssembler.plan(run_seed, data)
		var want: Array = expected[run_seed]
		assert_eq(picks["boss"], want[0], "boss of seed %d" % run_seed)
		assert_eq(picks["top"], want[1], "top of seed %d" % run_seed)
		assert_eq(picks["middle"], want[2], "middle of seed %d" % run_seed)
		assert_eq(picks["bottom"], want[3], "bottom of seed %d" % run_seed)
		assert_eq(picks["packs"], want[4], "packs of seed %d" % run_seed)


func test_levels_are_pinned_for_fixed_seeds() -> void:
	var expected: Dictionary = {1: 4131946903, 12345: 3260186289, 20261023: 2150929963}
	for run_seed: int in expected.keys():
		var level: LevelData = MapAssembler.assemble(run_seed, data, catalog)
		assert_eq(_text(level).hash(), expected[run_seed], "level of seed %d" % run_seed)


## The draw order of 3.4, replayed by hand: the boss, then the top, middle and bottom on
## one generator, then each band's pack on a generator of its own.
func test_the_picks_follow_the_draw_order_of_the_contract() -> void:
	for run_seed: int in [5, 77, 4242, 99999, 20261024]:
		var boss_rng: RandomNumberGenerator = RandomNumberGenerator.new()
		boss_rng.seed = RunSeeds.derive(run_seed, "boss", 0)
		var map_rng: RandomNumberGenerator = RandomNumberGenerator.new()
		map_rng.seed = RunSeeds.derive(run_seed, "map", 0)
		var bosses: Array[StringName] = data.boss_ids()
		var boss: StringName = bosses[boss_rng.randi_range(0, bosses.size() - 1)]
		var tops: Array[Dictionary] = data.segments_of(&"top")
		var top: Dictionary = tops[map_rng.randi_range(0, tops.size() - 1)]
		var middles: Array[Dictionary] = data.segments_under(top["id"])
		var middle: Dictionary = middles[map_rng.randi_range(0, middles.size() - 1)]
		var bottoms: Array[Dictionary] = data.segments_under(middle["id"])
		var bottom: Dictionary = bottoms[map_rng.randi_range(0, bottoms.size() - 1)]
		var packs: Array[StringName] = []
		for band: int in range(1, 7):
			var rng: RandomNumberGenerator = RandomNumberGenerator.new()
			rng.seed = RunSeeds.derive(run_seed, "pack", band)
			var choices: Array[Dictionary] = data.packs_of(band, boss if band == 6 else &"")
			packs.append(choices[rng.randi_range(0, choices.size() - 1)]["id"])
		var picks: Dictionary = MapAssembler.plan(run_seed, data)
		assert_eq(picks["boss"], boss, "boss %d" % run_seed)
		assert_eq([picks["top"], picks["middle"], picks["bottom"]], [top["id"], middle["id"], bottom["id"]], "map %d" % run_seed)
		assert_eq(picks["packs"], packs, "packs %d" % run_seed)


## Every top, every stack, every pack and every boss comes up for some seed.
func test_every_choice_is_reachable() -> void:
	var tops: Dictionary = {}
	var stacks: Dictionary = {}
	var bosses: Dictionary = {}
	var packs: Dictionary = {}
	for run_seed: int in 300:
		var picks: Dictionary = MapAssembler.plan(run_seed, data)
		tops[picks["top"]] = true
		stacks["%s/%s/%s" % [picks["top"], picks["middle"], picks["bottom"]]] = true
		bosses[picks["boss"]] = true
		for id: StringName in picks["packs"]:
			packs[id] = true
	assert_eq(tops.size(), 4)
	assert_eq(stacks.size(), 6)
	assert_eq(bosses.size(), 4)
	assert_eq(packs.size(), data.packs.size())


func test_the_boss_pack_always_names_the_boss() -> void:
	for run_seed: int in 100:
		var picks: Dictionary = MapAssembler.plan(run_seed, data)
		var packs: Array = picks["packs"]
		var last: Dictionary = {}
		for pack: Dictionary in data.packs:
			if pack["id"] == packs[5]:
				last = pack
		assert_eq(last["boss"], picks["boss"], "seed %d" % run_seed)
		var level: LevelData = MapAssembler.assemble(run_seed, data, catalog)
		assert_eq(level.waves[17].groups[0].enemy, picks["boss"], "the boss opens wave 18")
		assert_eq(level.waves[17].groups[0].count, 1)


func test_the_boss_depends_only_on_the_seed_and_the_boss_list() -> void:
	var small: Dictionary = Fx.files_from_json()
	small["segments/index.json"]["segments"] = ["top_side", "mid_side", "bot_home"]
	for id: String in ["top_one", "mid_split", "bot_edge", "top_pair", "mid_bend", "top_twin", "mid_merge"]:
		small.erase("segments/%s.json" % id)
	var other: RunData = RunData.from_data(small, catalog)
	assert_not_null(other, "a smaller set of segments is still valid")
	for run_seed: int in 60:
		assert_eq(MapAssembler.plan(run_seed, other)["boss"], MapAssembler.plan(run_seed, data)["boss"], "boss of seed %d" % run_seed)
		assert_eq(MapAssembler.plan(run_seed, other)["packs"], MapAssembler.plan(run_seed, data)["packs"], "packs of seed %d" % run_seed)


func test_the_same_seed_gives_an_equal_level() -> void:
	for run_seed: int in [0, 1, 2, 12345, 20261023, 4294967295]:
		var first: LevelData = MapAssembler.assemble(run_seed, data, catalog)
		var second: LevelData = MapAssembler.assemble(run_seed, data, catalog)
		var fresh: LevelData = MapAssembler.assemble(run_seed, Fx.run_data(), Fx.catalog())
		assert_eq(_text(first), _text(second), "seed %d twice" % run_seed)
		assert_eq(_text(first), _text(fresh), "seed %d from freshly loaded data" % run_seed)


func test_different_seeds_give_different_levels() -> void:
	var seen: Dictionary = {}
	for run_seed: int in 40:
		seen[_text(MapAssembler.assemble(run_seed, data, catalog))] = true
	assert_true(seen.size() >= 30, "%d different levels from 40 seeds" % seen.size())


func test_the_level_is_the_run_map_of_the_contract() -> void:
	for run_seed: int in [1, 12345, 20261023]:
		var level: LevelData = MapAssembler.assemble(run_seed, data, catalog)
		assert_not_null(level)
		assert_eq(level.id, &"run")
		assert_eq(level.name, "Run")
		assert_eq(level.rows, 13)
		assert_eq(level.grid.size(), 13)
		assert_eq(level.grid[12], ".......", "a 13 row map keeps its bottom row scenery")
		assert_eq(level.start_gold, 300)
		assert_eq(level.gates, 1)
		assert_eq(level.strength, 100)
		assert_eq(level.towers, [&"sling_post"])
		assert_eq(level.star3["kind"], &"no_lives_lost")
		assert_eq(level.hint_text, "")
		assert_eq(level.twist_name, "")
		assert_eq(level.twist_effects.size(), 0)
		assert_eq(level.waves.size(), 18)
		assert_true(level.spots.size() >= 8 and level.spots.size() <= 12)
		assert_true(level.sockets.size() >= 2 and level.sockets.size() <= 5)
		assert_eq(LevelData.check(level.to_data(), catalog), PackedStringArray(), "it passes the level checks again")


func test_the_waves_come_from_the_packs_with_rising_strength() -> void:
	var level: LevelData = MapAssembler.assemble(12345, data, catalog)
	var picks: Dictionary = MapAssembler.plan(12345, data)
	for w: int in 17:
		assert_eq(level.waves[w].strength, 100 + 10 * w, "strength of wave %d" % (w + 1))
	assert_eq(level.waves[0].strength, 100)
	assert_eq(level.waves[16].strength, 260)
	assert_eq(level.waves[17].strength, 150 + 10 * 5, "wave 18 takes band6_pack5's own strength")
	for band: int in 6:
		var pack: Dictionary = {}
		for item: Dictionary in data.packs:
			if item["id"] == picks["packs"][band]:
				pack = item
		assert_eq(pack["band"], band + 1)
		for k: int in 3:
			var wave: WaveData = level.waves[band * 3 + k]
			var groups: Array = pack["waves"][k]["groups"]
			assert_eq(wave.groups.size(), groups.size())
			for g: int in groups.size():
				assert_eq(String(wave.groups[g].enemy), groups[g]["enemy"])
				assert_eq(wave.groups[g].count, groups[g]["count"])
				assert_eq(wave.groups[g].at_tick * 50, groups[g]["at_ms"])
				assert_eq(wave.groups[g].every_ticks * 50, groups[g]["every_ms"])


func test_wave_18_takes_the_strength_of_the_picked_boss_pack() -> void:
	var seen: Dictionary = {}
	for run_seed: int in 40:
		var level: LevelData = MapAssembler.assemble(run_seed, data, catalog)
		var pack_id: StringName = MapAssembler.plan(run_seed, data)["packs"][5]
		var want: int = 150 + 10 * int(String(pack_id).trim_prefix("band6_pack"))
		assert_eq(level.waves[17].strength, want, "seed %d, %s" % [run_seed, pack_id])
		assert_eq(level.waves[16].strength, 260, "seed %d: wave 17 keeps the step" % run_seed)
		seen[level.waves[17].strength] = true
	assert_true(seen.size() > 1, "different packs give different boss strengths")


func test_build_refuses_a_boss_wave_without_a_strength() -> void:
	var packs: Array[StringName] = [&"band1_pack0", &"band2_pack0", &"band3_pack0", &"band4_pack0", &"band5_pack0", &"band6_pack0"]
	assert_not_null(MapAssembler.build(data, catalog, &"top_one", &"mid_split", &"bot_home", packs))
	for pack: Dictionary in data.packs:
		if pack["id"] == &"band6_pack0":
			(pack["waves"][2] as Dictionary).erase("strength")
	assert_null(MapAssembler.build(data, catalog, &"top_one", &"mid_split", &"bot_home", packs))


func test_entrance_two_means_entrance_one_on_a_one_entrance_map() -> void:
	var one_seen: bool = false
	var two_seen: bool = false
	for run_seed: int in 80:
		var level: LevelData = MapAssembler.assemble(run_seed, data, catalog)
		var used: Dictionary = {}
		for wave: WaveData in level.waves:
			for group: WaveGroup in wave.groups:
				used[group.entrance] = true
		if level.entrances.size() == 1:
			one_seen = true
			assert_eq(used.keys(), [0], "seed %d: every group uses entrance A" % run_seed)
		else:
			two_seen = true
			assert_eq(used.size(), 2, "seed %d: both entrances are used" % run_seed)
	assert_true(one_seen and two_seen, "both kinds of map came up")


## Every stack of the fixtures builds a valid map within run.json's spots and sockets.
func test_every_stack_is_a_valid_map() -> void:
	var packs: Array[StringName] = [&"band1_pack0", &"band2_pack0", &"band3_pack0", &"band4_pack0", &"band5_pack0", &"band6_pack0"]
	var stacks: int = 0
	for top: Dictionary in data.segments_of(&"top"):
		for middle: Dictionary in data.segments_under(top["id"]):
			for bottom: Dictionary in data.segments_under(middle["id"]):
				var level: LevelData = MapAssembler.build(data, catalog, top["id"], middle["id"], bottom["id"], packs)
				stacks += 1
				assert_not_null(level, "%s / %s / %s" % [top["id"], middle["id"], bottom["id"]])
				if level != null:
					assert_eq(LevelData.check(level.to_data(), catalog), PackedStringArray())
	assert_eq(stacks, 6)


func test_a_built_run_can_be_played() -> void:
	var level: LevelData = MapAssembler.assemble(20261023, data, catalog)
	var battle: Battle = Battle.create(level, catalog, false, [])
	assert_not_null(battle)
	assert_eq(battle.phase, Battle.Phase.BUILD)
	assert_eq(battle.gold, 300)
	assert_eq(battle.gates_in_hand, 1)
	assert_eq(battle.wave_count(), 18)


func test_a_seed_outside_the_range_is_refused() -> void:
	assert_null(MapAssembler.assemble(-1, data, catalog))
	assert_null(MapAssembler.assemble(4294967296, data, catalog))
	assert_null(MapAssembler.assemble(9223372036854775807, data, catalog))
	assert_not_null(MapAssembler.assemble(0, data, catalog))
	assert_not_null(MapAssembler.assemble(4294967295, data, catalog))
	assert_eq(MapAssembler.plan(-1, data), {})


func test_a_data_bug_gives_null_and_never_a_crash() -> void:
	assert_null(MapAssembler.assemble(1, null, catalog))
	assert_eq(MapAssembler.plan(1, null), {})
	var no_packs: RunData = Fx.run_data()
	no_packs.packs = []
	assert_null(MapAssembler.assemble(1, no_packs, catalog))
	var no_bosses: RunData = Fx.run_data()
	no_bosses._bosses = []
	assert_null(MapAssembler.assemble(1, no_bosses, catalog))
	var no_segments: RunData = Fx.run_data()
	no_segments.segment_ids = []
	assert_null(MapAssembler.assemble(1, no_segments, catalog))
	var narrow: RunData = Fx.run_data()
	narrow.spots_max = 5
	assert_null(MapAssembler.assemble(1, narrow, catalog), "too many spots for the plan")
	var few_sockets: RunData = Fx.run_data()
	few_sockets.sockets_min = 3
	assert_null(MapAssembler.assemble(1, few_sockets, catalog), "too few sockets for the plan")
	var too_many_gates: RunData = Fx.run_data()
	too_many_gates.gates = 3
	assert_null(MapAssembler.assemble(1, too_many_gates, catalog), "3 gates on 2 sockets")


func test_build_refuses_wrong_pieces() -> void:
	var packs: Array[StringName] = [&"band1_pack0", &"band2_pack0", &"band3_pack0", &"band4_pack0", &"band5_pack0", &"band6_pack0"]
	assert_not_null(MapAssembler.build(data, catalog, &"top_one", &"mid_split", &"bot_home", packs))
	assert_null(MapAssembler.build(data, catalog, &"nothing", &"mid_split", &"bot_home", packs))
	assert_null(MapAssembler.build(data, catalog, &"mid_split", &"mid_split", &"bot_home", packs), "a middle used as a top")
	assert_null(MapAssembler.build(data, catalog, &"top_one", &"bot_home", &"bot_home", packs))
	assert_null(MapAssembler.build(data, catalog, &"top_one", &"mid_split", &"top_one", packs))
	assert_null(MapAssembler.build(data, catalog, &"top_one", &"mid_split", &"bot_edge", packs), "a bottom that does not join: no road to the base")
	var short: Array[StringName] = [&"band1_pack0"]
	assert_null(MapAssembler.build(data, catalog, &"top_one", &"mid_split", &"bot_home", short))
	var swapped: Array[StringName] = [&"band2_pack0", &"band1_pack0", &"band3_pack0", &"band4_pack0", &"band5_pack0", &"band6_pack0"]
	assert_null(MapAssembler.build(data, catalog, &"top_one", &"mid_split", &"bot_home", swapped), "a band 2 pack in band 1's place")
	var unknown: Array[StringName] = [&"nothing", &"band2_pack0", &"band3_pack0", &"band4_pack0", &"band5_pack0", &"band6_pack0"]
	assert_null(MapAssembler.build(data, catalog, &"top_one", &"mid_split", &"bot_home", unknown))
	assert_null(MapAssembler.build(null, catalog, &"top_one", &"mid_split", &"bot_home", packs))
	assert_null(MapAssembler.build(data, null, &"top_one", &"mid_split", &"bot_home", packs))
