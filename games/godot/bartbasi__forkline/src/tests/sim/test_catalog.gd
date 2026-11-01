# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Catalog.check and from_data on the real data/stats/ files and on hostile copies
## (docs/ARCHITECTURE.md 2.6, 2.12).

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")

var files: Array = []


func before_each() -> void:
	files = Fx.stats_files()


func _problems() -> PackedStringArray:
	return Catalog.check(files[0], files[1], files[2])


func _tower(id: String) -> Dictionary:
	for item: Dictionary in files[0]["towers"]:
		if item["id"] == id:
			return item
	return {}


func _enemy(id: String) -> Dictionary:
	for item: Dictionary in files[1]["enemies"]:
		if item["id"] == id:
			return item
	return {}


func _expect_problem(what: String) -> void:
	var problems: PackedStringArray = _problems()
	assert_false(problems.is_empty(), what)
	assert_null(Catalog.from_data(files[0], files[1], files[2]), what + " gives no catalog")


func test_the_real_stat_files_load() -> void:
	var problems: PackedStringArray = _problems()
	assert_eq(problems.size(), 0, "problems: %s" % "; ".join(problems))
	var catalog: Catalog = Catalog.from_data(files[0], files[1], files[2])
	assert_not_null(catalog)
	assert_eq(catalog.tower_ids(), [&"sling_post", &"pumpkin_catapult", &"lullaby_bell", &"longbow_loft", &"firework_tower", &"bakery", &"bramble_cottage", &"scarecrow", &"snow_fort", &"moth_lantern"])
	assert_eq(catalog.enemy_ids().size(), 27)
	assert_null(catalog.tower(&"nope"))
	assert_null(catalog.enemy(&"nope"))


## A stat block as [field, value] pairs, in TowerStats order.
func _stat_values(stats: TowerStats) -> Array:
	return [
		["cost", stats.cost], ["reach", stats.reach], ["hits_ground", stats.hits_ground], ["hits_air", stats.hits_air],
		["damage", stats.damage], ["reload_ms", stats.reload_ms], ["splash", stats.splash], ["targets", stats.targets],
		["pierce", stats.pierce], ["slow_pct", stats.slow_pct], ["slow_ms", stats.slow_ms],
		["boost_pct", stats.boost_pct], ["boost_damage", stats.boost_damage],
	]


## What TowerStats must hold for one raw tier or path: a missing optional field is 0, false
## or empty, except targets, which is 1 (2.6).
func _raw_values(raw: Dictionary) -> Array:
	var hits: String = String(raw.get("hits", ""))
	return [
		["cost", int(raw["cost"])], ["reach", int(raw["reach"])],
		["hits_ground", hits == "ground" or hits == "both"], ["hits_air", hits == "air" or hits == "both"],
		["damage", int(raw.get("damage", 0))], ["reload_ms", int(raw.get("reload_ms", 0))],
		["splash", int(raw.get("splash", 0))], ["targets", int(raw.get("targets", 1))],
		["pierce", bool(raw.get("pierce", false))], ["slow_pct", int(raw.get("slow_pct", 0))],
		["slow_ms", int(raw.get("slow_ms", 0))], ["boost_pct", int(raw.get("boost_pct", 0))],
		["boost_damage", int(raw.get("boost_damage", 0))],
	]


func test_every_tower_field_of_2_6_is_read() -> void:
	# Every tier and path of every tower in the real files, field by field, so a retune
	# of data/stats/ never breaks this test but a field read into the wrong place does.
	var catalog: Catalog = Fx.catalog()
	var defaults: Array = _stat_values(TowerStats.new())
	var seen: Dictionary = {}
	for raw: Dictionary in files[0]["towers"]:
		var type: TowerType = catalog.tower(StringName(raw["id"]))
		assert_not_null(type, raw["id"])
		if type == null:
			continue
		assert_eq([type.name, type.plural, type.info, type.kind], [raw["name"], raw["plural"], raw["info"], StringName(raw["kind"])], raw["id"])
		var blocks: Array = []
		for t: int in 2:
			blocks.append([type.stats(t + 1, -1), raw["tiers"][t], "%s tier %d" % [raw["id"], t + 1]])
		for s: int in 2:
			var spec: Dictionary = raw["specs"][s]
			assert_eq([type.specs[s], type.spec_name(s), type.spec_info(s)], [StringName(spec["id"]), spec["name"], spec["info"]])
			blocks.append([type.stats(3, s), spec, "%s spec %d" % [raw["id"], s]])
		for block: Array in blocks:
			var stats: TowerStats = block[0]
			var raw_block: Dictionary = block[1]
			var expected: Array = _raw_values(raw_block)
			assert_eq(_stat_values(stats), expected, block[2])
			for i: int in expected.size():
				if expected[i][1] != defaults[i][1]:
					seen[expected[i][0]] = true
			if raw_block.has("hits"):
				seen["hits " + String(raw_block["hits"])] = true
	# Every field and every hits value differs from its default somewhere in the real files,
	# so a reader that skipped one would fail the loop above.
	for pair: Array in defaults:
		assert_true(seen.has(pair[0]), "some tower in data/stats/ sets " + String(pair[0]))
	for hits: String in ["ground", "air", "both"]:
		assert_true(seen.has("hits " + hits), "some tower in data/stats/ hits " + hits)
	# Tier and spec pairs outside 2.6 give nothing.
	var sling: TowerType = catalog.tower(&"sling_post")
	assert_null(sling.stats(3, -1), "tier 3 needs a spec")
	assert_null(sling.stats(2, 0), "tier 2 takes spec -1")
	assert_null(sling.stats(4, -1))
	# What each tower can hit is part of its job (RULES 5.1, 6.5).
	assert_true(sling.stats(1, -1).hits_ground and sling.stats(1, -1).hits_air, "Sling Post hits both")
	assert_false(catalog.tower(&"pumpkin_catapult").stats(1, -1).hits_air, "Catapult cannot hit flyers")
	assert_true(catalog.tower(&"lullaby_bell").stats(3, 1).hits_air, "Night Bell reaches flyers")
	var t1: TowerStats = sling.stats(1, -1)
	var numbers: Dictionary = t1.numbers()
	for key: String in ["damage", "reload_ms", "reach", "splash", "targets", "pierce", "slow_pct", "slow_ms", "hits_ground", "hits_air", "boost_pct", "boost_damage"]:
		assert_true(numbers.has(key), "numbers has " + key)


func test_every_creature_field_of_2_6_is_read() -> void:
	var catalog: Catalog = Fx.catalog()
	var scamp: EnemyType = catalog.enemy(&"scamp")
	assert_eq([scamp.health, scamp.armor, scamp.speed, scamp.lives, scamp.bounty], [40, 0, 100, 1, 5])
	assert_true(catalog.enemy(&"flitter").flying)
	assert_true(catalog.enemy(&"bubbler").bubble)
	var puffball: EnemyType = catalog.enemy(&"puffball")
	assert_eq([puffball.split_into, puffball.split_count, puffball.split_gap_ms], [&"puff", 3, 300])
	var mender: EnemyType = catalog.enemy(&"mender")
	assert_eq([mender.heal, mender.heal_reach, mender.heal_ms], [8, 150, 2000])
	assert_eq(catalog.enemy(&"gatecrasher").break_ms, 4000)
	var boss: EnemyType = catalog.enemy(&"grumblesack")
	assert_true(boss.boss)
	assert_eq(boss.summon, {"enemy": &"scamp", "count": 2, "every_ms": 6000, "gap_ms": 300})
	assert_eq(catalog.enemy(&"ironshell").speed_up["at_pct"], [75, 50, 25])
	assert_eq(catalog.enemy(&"ironshell").speed_up["add"], 10)
	assert_eq(catalog.enemy(&"old_tusk").release["enemy"], &"dusk_moth")
	assert_eq(catalog.enemy(&"old_tusk").release["at_pct"], 50)
	assert_eq(scamp.summon, {}, "no summon is {}")


func test_every_rule_key_is_read() -> void:
	var rules: GameRules = Fx.catalog().rules
	assert_eq([rules.start_lives, rules.relaxed_lives_pct, rules.relaxed_gold_pct, rules.refund_pct], [20, 200, 150, 70])
	assert_eq([rules.early_bonus_pct, rules.clear_bonus, rules.clear_bonus_per_wave, rules.star2_lives], [50, 20, 5, 15])
	assert_eq([rules.max_waves_running, rules.max_gates, rules.bubble_ms, rules.run_stars], [2, 3, 2000, 12])
	assert_eq(rules.region_stars, [0, 6, 12, 18, 24, 30, 36, 42])


func test_ints_and_whole_numbers_both_pass() -> void:
	_tower("sling_post")["tiers"][0]["cost"] = 100
	assert_eq(_problems().size(), 0, "an int is fine")
	_tower("sling_post")["tiers"][0]["cost"] = 100.0
	assert_eq(_problems().size(), 0, "a whole JSON number is fine")


func test_hostile_numbers_are_refused() -> void:
	for bad: Variant in [1.5, NAN, INF, -INF, "100", null, true, [], {}, 1e300, -100, 105]:
		files = Fx.stats_files()
		_tower("sling_post")["tiers"][0]["cost"] = bad
		_expect_problem("cost %s" % str(bad))


func test_unknown_and_missing_keys_are_refused() -> void:
	_tower("sling_post")["tiers"][0]["dmg"] = 6
	_expect_problem("unknown stat key")
	files = Fx.stats_files()
	_tower("sling_post")["tiers"][0].erase("reload_ms")
	_expect_problem("missing reload_ms")
	files = Fx.stats_files()
	_enemy("scamp")["colour"] = "red"
	_expect_problem("unknown creature key")
	files = Fx.stats_files()
	files[2].erase("bubble_ms")
	_expect_problem("missing rules key")
	files = Fx.stats_files()
	files[2]["extra"] = 1
	_expect_problem("unknown rules key")
	files = Fx.stats_files()
	_tower("bakery")["tiers"][0]["damage"] = 3
	_expect_problem("damage on a boost tower")


func test_ids_text_and_shapes_are_checked() -> void:
	var cases: Array[Callable] = [
		func() -> void: _tower("sling_post")["id"] = "Sling Post",
		func() -> void: _tower("sling_post")["id"] = "pumpkin_catapult",
		func() -> void: _tower("sling_post")["name"] = "",
		func() -> void: _tower("sling_post")["name"] = "A name that is far too long for it",
		func() -> void: _tower("sling_post")["info"] = "tab\there",
		func() -> void: _tower("sling_post")["info"] = "caf" + char(233),
		func() -> void: _tower("sling_post")["kind"] = "heal",
		func() -> void: _tower("sling_post")["tiers"].pop_back(),
		func() -> void: _tower("sling_post")["specs"].append({}),
		func() -> void: _tower("sling_post")["specs"][1]["id"] = "quickshot",
		func() -> void: _tower("sling_post")["tiers"][0]["hits"] = "water",
		func() -> void: _tower("sling_post")["tiers"][0]["targets"] = 4,
		func() -> void: _tower("sling_post")["tiers"][0]["reload_ms"] = 525,
		func() -> void: _tower("pumpkin_catapult")["specs"][1].erase("slow_ms"),
		func() -> void: _enemy("scamp")["health"] = 0,
		func() -> void: _enemy("scamp")["id"] = "pip",
		func() -> void: _enemy("puffball")["split_into"] = "nobody",
		func() -> void: _enemy("puffball").erase("split_gap_ms"),
		func() -> void: _enemy("grumblesack")["summon"]["enemy"] = "grumblesack",
		func() -> void: _enemy("grumblesack")["summon"]["enemy"] = "puffball",
		func() -> void: _enemy("grumblesack")["summon"]["extra"] = 1,
		func() -> void: _enemy("moon_moth")["summon"]["enemy"] = "scamp",
		func() -> void: _enemy("ironshell")["speed_up"]["at_pct"] = [50, 75],
		func() -> void: _enemy("old_tusk")["release"]["at_pct"] = 100,
		func() -> void: _enemy("mender").erase("heal_ms"),
		func() -> void: files[1]["format"] = 2,
		func() -> void: files[0]["towers"] = [],
		func() -> void: files[2]["region_stars"] = [6, 0],
		func() -> void: files[2]["star2_lives"] = 21,
		func() -> void: files[2]["refund_pct"] = 101,
	]
	for i: int in cases.size():
		files = Fx.stats_files()
		cases[i].call()
		_expect_problem("case %d" % i)


## Summons come for as long as the boss lives, so a save could not bound the healers
## they would bring (Battle.MAX_HEALERS).
func test_a_summoned_creature_cannot_heal() -> void:
	_enemy("grumblesack")["summon"]["enemy"] = "mender"
	var problems: PackedStringArray = _problems()
	assert_eq(problems.size(), 1)
	assert_eq(problems[0], "enemies.json: enemies[11].summon.enemy: a summoned creature cannot heal")
	assert_null(Catalog.from_data(files[0], files[1], files[2]))


func test_wrong_top_level_types_never_crash() -> void:
	for bad: Variant in [null, 1, "x", [], {}, [{}], {"format": 1}]:
		assert_false(Catalog.check(bad, files[1], files[2]).is_empty(), "towers %s" % str(bad))
		assert_false(Catalog.check(files[0], bad, files[2]).is_empty(), "enemies %s" % str(bad))
		assert_false(Catalog.check(files[0], files[1], bad).is_empty(), "rules %s" % str(bad))
		assert_null(Catalog.from_data(bad, bad, bad))


func test_problem_lines_name_the_file_and_field() -> void:
	_tower("sling_post")["tiers"][1]["damage"] = 0
	var problems: PackedStringArray = _problems()
	assert_eq(problems.size(), 1)
	assert_eq(problems[0], "towers.json: towers[0].tiers[1].damage: must be 1 to 100000")
