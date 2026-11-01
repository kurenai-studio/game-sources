# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Catalog checks for the expansion towers (docs/ARCHITECTURE.md 14.4): the fright kind,
## pulse, line and lure_ms with their limits and combinations, and that a gate breaker
## releases only flyers.

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Tx: GDScript = preload("res://tests/sim/fixtures/tower_fixtures.gd")


func _problems_with(id: String, index: int, changes: Dictionary, erase: Array = []) -> PackedStringArray:
	var files: Array = Tx.stats_files()
	for item: Dictionary in files[0]["towers"]:
		if item["id"] == id:
			var block: Dictionary = item["tiers"][index] if index < 2 else item["specs"][index - 2]
			block.merge(changes, true)
			for key: String in erase:
				block.erase(key)
	return Catalog.check(files[0], files[1], files[2])


func _ok(id: String, index: int, changes: Dictionary, what: String, erase: Array = []) -> void:
	var problems: PackedStringArray = _problems_with(id, index, changes, erase)
	assert_true(problems.is_empty(), "%s loads: %s" % [what, str(problems)])


func _bad(id: String, index: int, changes: Dictionary, what: String, erase: Array = []) -> void:
	assert_false(_problems_with(id, index, changes, erase).is_empty(), "%s is refused" % what)


func test_the_four_towers_load_with_their_numbers() -> void:
	var cat: Catalog = Tx.catalog()
	assert_not_null(cat, "the test catalog loads")
	if cat == null:
		return
	assert_eq(cat.tower(&"scarecrow").kind, &"fright")
	var bramble: TowerStats = cat.tower(&"bramble_cottage").stats(1, -1)
	assert_true(bramble.pulse)
	assert_eq(cat.tower(&"snow_fort").stats(3, 0).line, 100, "Big Snowball is 1.0 wide")
	assert_eq(cat.tower(&"moth_lantern").stats(3, 0).lure_ms, 4000, "Beacon Lantern holds flyers low 4 s")
	assert_eq(cat.tower(&"moth_lantern").stats(3, 1).targets, 3, "Lantern Garland lures 3")
	var crow: TowerStats = cat.tower(&"scarecrow").stats(3, 1)
	assert_eq([crow.fright_pct, crow.fright_ms, crow.hits_ground, crow.hits_air], [25, 1000, true, true], "Crow Keeper")
	var numbers: Dictionary = cat.tower(&"scarecrow").stats(3, 0).numbers()
	assert_eq([numbers["fright_pct"], numbers["fright_ms"]], [40, 1000], "Tall Scarecrow's numbers")
	var sling: Dictionary = cat.tower(&"sling_post").stats(1, -1).numbers()
	assert_eq([sling["pulse"], sling["line"], sling["lure_ms"], sling["fright_pct"], sling["fright_ms"]], [false, 0, 0, 0, 0],
		"an older tower's numbers hold the new fields at 0 or false")
	var copy: TowerStats = cat.tower(&"snow_fort").stats(1, -1).copy()
	assert_eq(copy.numbers(), cat.tower(&"snow_fort").stats(1, -1).numbers(), "copy() keeps every field")


func test_the_fright_kind_and_its_limits() -> void:
	_ok("scarecrow", 0, {"fright_pct": 1, "fright_ms": 50}, "the lowest fright")
	_ok("scarecrow", 0, {"fright_pct": 1000, "fright_ms": 60000}, "the highest fright")
	_bad("scarecrow", 0, {"fright_pct": 0}, "fright_pct 0")
	_bad("scarecrow", 0, {"fright_pct": 1001}, "fright_pct 1,001")
	_bad("scarecrow", 0, {"fright_ms": 0}, "fright_ms 0")
	_bad("scarecrow", 0, {"fright_ms": 60050}, "fright_ms 60,050")
	_bad("scarecrow", 0, {"fright_ms": 75}, "fright_ms not a multiple of 50")
	_bad("scarecrow", 0, {"fright_pct": 1.5}, "a fraction")
	for key: String in ["hits", "fright_pct", "fright_ms"]:
		_bad("scarecrow", 0, {}, "a fright tower without " + key, [key])
	for extra: Dictionary in [{"damage": 1}, {"reload_ms": 500}, {"slow_pct": 10, "slow_ms": 500}, {"pulse": true}, {"line": 10}, {"lure_ms": 500}]:
		_bad("scarecrow", 0, extra, "a fright tower with %s" % str(extra))
	_bad("sling_post", 0, {"fright_pct": 10, "fright_ms": 1000}, "fright on an attacking tower")
	_bad("lullaby_bell", 0, {"pulse": true}, "pulse on a Bell")
	_bad("bakery", 0, {"line": 50}, "line on a Bakery")


func test_pulse_line_and_lure_limits() -> void:
	_ok("snow_fort", 0, {"line": 1}, "line 1")
	_ok("snow_fort", 0, {"line": 500}, "line 500")
	_bad("snow_fort", 0, {"line": 0}, "line 0")
	_bad("snow_fort", 0, {"line": 501}, "line 501")
	_ok("moth_lantern", 0, {"lure_ms": 50}, "lure_ms 50")
	_ok("moth_lantern", 0, {"lure_ms": 60000}, "lure_ms 60,000")
	_bad("moth_lantern", 0, {"lure_ms": 0}, "lure_ms 0")
	_bad("moth_lantern", 0, {"lure_ms": 60050}, "lure_ms 60,050")
	_bad("moth_lantern", 0, {"lure_ms": 125}, "lure_ms not a multiple of 50")
	_bad("bramble_cottage", 0, {"pulse": 1}, "pulse not a bool")
	# false on every block is no pulse at all.
	var files: Array = Tx.stats_files()
	for item: Dictionary in files[0]["towers"]:
		if item["id"] == "sling_post":
			for block: Dictionary in (item["tiers"] as Array) + (item["specs"] as Array):
				block["pulse"] = false
	assert_true(Catalog.check(files[0], files[1], files[2]).is_empty(), "pulse false on every block")


func test_one_way_of_attacking_with_no_splash_contract_14_4() -> void:
	_bad("snow_fort", 0, {"pulse": true}, "pulse and line")
	_bad("moth_lantern", 0, {"line": 50}, "line and lure_ms")
	_bad("bramble_cottage", 0, {"lure_ms": 1000, "hits": "air"}, "pulse and lure_ms")
	_bad("bramble_cottage", 0, {"splash": 50}, "pulse with splash")
	_bad("snow_fort", 0, {"splash": 50}, "line with splash")
	_bad("moth_lantern", 0, {"splash": 50}, "lure with splash")
	_ok("snow_fort", 0, {"splash": 0}, "line with splash 0")
	_bad("bramble_cottage", 0, {"targets": 2}, "pulse with 2 targets")
	_bad("snow_fort", 0, {"targets": 2}, "line with 2 targets")
	_ok("snow_fort", 0, {"targets": 1}, "line with 1 target")
	_ok("moth_lantern", 0, {"targets": 3}, "lure with 3 targets")
	_bad("moth_lantern", 0, {"hits": "ground"}, "lure on a tower that hits ground")
	_bad("moth_lantern", 0, {"hits": "both"}, "lure on a tower that hits both")


func test_the_way_of_attacking_is_on_every_block_or_none_contract_14_4() -> void:
	var cases: Array = [
		["bramble_cottage", 1, {"pulse": false}, "pulse missing at tier 2"],
		["bramble_cottage", 3, {}, "pulse missing on spec 1", ["pulse"]],
		["snow_fort", 2, {}, "line missing on spec 0", ["line"]],
		["moth_lantern", 0, {}, "lure missing at tier 1", ["lure_ms"]],
		["sling_post", 3, {"line": 50}, "a line on one path only"],
		["firework_tower", 0, {"lure_ms": 500, "splash": 0}, "a lure on tier 1 only"],
	]
	for item: Array in cases:
		var erase: Array = item[4] if item.size() > 4 else []
		_bad(item[0], item[1], item[2], item[3], erase)
	_ok("snow_fort", 3, {"line": 20}, "a different width on one path")
	_ok("moth_lantern", 1, {"lure_ms": 9000}, "a different lure time at tier 2")


func test_a_gate_breaker_releases_only_flyers() -> void:
	assert_true(Catalog.check(Fx.stats_files()[0], Fx.stats_files()[1], Fx.stats_files()[2]).is_empty(), "today's data: Old Tusk releases Dusk Moths")
	var cases: Array = [
		["old_tusk", {"release": {"at_pct": 50, "enemy": "scamp", "count": 2, "gap_ms": 300}}, "a release of walkers"],
		["gatecrasher", {"split_into": "pip", "split_count": 2, "split_gap_ms": 300}, "a split into walkers"],
		["gatecrasher", {"summon": {"enemy": "scamp", "count": 1, "every_ms": 3000, "gap_ms": 300}}, "summoned walkers"],
	]
	for item: Array in cases:
		var files: Array = Fx.stats_files()
		for enemy: Dictionary in files[1]["enemies"]:
			if enemy["id"] == item[0]:
				enemy.merge(item[1], true)
		var problems: PackedStringArray = Catalog.check(files[0], files[1], files[2])
		assert_eq(problems.size(), 1, "%s from a gate breaker: %s" % [item[2], str(problems)])
		assert_true(problems.size() > 0 and problems[0].contains("gate breaker"), "named as a breaker problem")
	var flyers: Array = Fx.stats_files()
	for enemy: Dictionary in flyers[1]["enemies"]:
		if enemy["id"] == "gatecrasher":
			enemy["split_into"] = "flitter"
			enemy["split_count"] = 2
			enemy["split_gap_ms"] = 300
	assert_true(Catalog.check(flyers[0], flyers[1], flyers[2]).is_empty(), "a breaker that splits into flyers loads")


func test_cards_give_no_splash_or_targets_where_14_4_allows_none() -> void:
	var cat: Catalog = Tx.catalog()
	var effects: Array[Dictionary] = []
	for tower: String in ["bramble_cottage", "snow_fort", "moth_lantern", "sling_post"]:
		effects.append({"type": "tower_add", "tower": tower, "stat": "splash", "amount": 100})
		effects.append({"type": "tower_add", "tower": tower, "stat": "targets", "amount": 2})
	assert_true(Modifiers.check(effects, cat, &"card").is_empty())
	var clean: Array[Dictionary] = Modifiers.normalize_all(effects)
	var got: Dictionary = {}
	for tower: StringName in [&"bramble_cottage", &"snow_fort", &"moth_lantern", &"sling_post"]:
		var s: TowerStats = Modifiers.tower_stats(cat.tower(tower).stats(1, -1), tower, clean, true)
		got[tower] = [s.splash, s.targets]
	assert_eq(got[&"bramble_cottage"], [0, 1], "a pulse keeps no splash and one target")
	assert_eq(got[&"snow_fort"], [0, 1], "a line keeps no splash and one target")
	assert_eq(got[&"moth_lantern"], [0, 3], "a lure keeps no splash, but more targets")
	assert_eq(got[&"sling_post"], [100, 3], "other towers take both")
