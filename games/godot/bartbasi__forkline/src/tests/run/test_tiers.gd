# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Content tiers in src/run/ (docs/ARCHITECTURE.md 14.8, RULES 14.9): run.json `tiers`, the
## tier of cards, packs and segments, every filter, the plans at every tier and the tier of a
## run session and its save. Stand-in towers, creatures and bosses come from
## tests/run/fixtures/tier_fixtures.gd. The tier 0 golden test is test_tier_zero.gd.

const Fx: GDScript = preload("res://tests/run/fixtures/run_fixtures.gd")
const Tx: GDScript = preload("res://tests/run/fixtures/tier_fixtures.gd")
const Player: GDScript = preload("res://tests/run/fixtures/run_player.gd")
const Golden: GDScript = preload("res://tests/run/fixtures/run_golden.gd")

var catalog: Catalog = null
var data: RunData = null


func before_each() -> void:
	catalog = Tx.catalog()
	data = Tx.run_data()


## A stand-in for a stat block, so has_stat's reading of pulse and line is tested before
## the real fields exist.
class FakeBlock extends RefCounted:
	var pulse: bool = false
	var line: int = 0


## Breaks one thing in a copy of the tier fixtures and expects a problem naming it.
func _expect(label: String, mutate: Callable, needle: String) -> void:
	var files: Dictionary = Tx.files()
	mutate.call(files)
	var found: PackedStringArray = RunData.check(files, catalog)
	assert_true(found.size() > 0, "%s: no problem found" % label)
	assert_true("\n".join(found).contains(needle), "%s: expected '%s' in:\n%s" % [label, needle, "\n".join(found)])
	assert_null(RunData.from_data(files, catalog), "%s: from_data must refuse" % label)


func _tiers(files: Dictionary) -> Array:
	return files["runs/run.json"]["tiers"]


## The pool with every unlock reached, at a tier.
func _pool(tier: int) -> Array[StringName]:
	return data.pool({"stars": 1000, "best_run_wave": 1000}, tier)


## The highest tier of the fixture data.
func _top() -> int:
	return data.tiers.size()


func _stack_ids(plan: Dictionary) -> Array:
	return [plan["top"], plan["middle"], plan["bottom"]]


func _many(count: int, id: String) -> Array:
	var out: Array = []
	for i: int in count:
		out.append(id)
	return out


## Adds count tiers that list nothing. Their levels continue the region numbers (r8_l6 for the fourth tier).
func _empty_tiers(f: Dictionary, count: int) -> void:
	for i: int in count:
		_tiers(f).append({"level": "r%d_l6" % (_tiers(f).size() + 5), "towers": [], "creatures": [], "bosses": [], "grid": ""})


func _pack_in(f: Dictionary, id: String) -> Dictionary:
	for item: Variant in f["segments/packs.json"]["packs"]:
		if (item as Dictionary)["id"] == id:
			return item
	return {}


func _use_in_wave_2(f: Dictionary, pack_id: String, enemy: String) -> void:
	_pack_in(f, pack_id)["waves"][1]["groups"][0]["enemy"] = enemy


func _give_boss(f: Dictionary, pack_id: String, boss: String) -> void:
	var pack: Dictionary = _pack_in(f, pack_id)
	pack["boss"] = boss
	pack["waves"][2]["groups"][0]["enemy"] = boss


func _three_boss_packs_to_tier_1(f: Dictionary) -> void:
	for id: String in ["band6_pack1", "band6_pack4", "band6_pack5"]:
		_give_boss(f, id, "burrowbelly")


func _drop_pack(f: Dictionary, id: String) -> void:
	f["segments/packs.json"]["packs"].erase(_pack_in(f, id))


func _add_risk(f: Dictionary, id: String, enemy: String) -> void:
	var risk: Dictionary = Fx.risk_card(id, [
		{"type": "add_group", "enemy": enemy, "count": 1, "entrance": 1, "at_ms": 1000, "every_ms": 300, "after_last": false},
		{"type": "reward_gold", "amount": 80},
	])
	f["cards/cards.json"]["cards"].append(JSON.parse_string(JSON.stringify(risk)))


func _road_to_tunnel(f: Dictionary, id: String) -> void:
	var grid: Array = f["segments/%s.json" % id]["grid"]
	grid[0] = (grid[0] as String).replace("#", "T")


func _card_in(f: Dictionary, id: String) -> Dictionary:
	for item: Variant in f["cards/cards.json"]["cards"]:
		if (item as Dictionary)["id"] == id:
			return item
	return {}


## The stat changes for the pack tier test: three creatures now bring a tier 1 creature (a gate
## breaker can release only flyers, so Old Tusk brings the flying Mistwisp).
func _bring_mossbud(all: Dictionary) -> void:
	for item: Dictionary in all["enemies"]["enemies"]:
		if item["id"] == "puffball":
			item["split_into"] = "mossbud"
		elif item["id"] == "grumblesack":
			item["summon"]["enemy"] = "mossbud"
		elif item["id"] == "old_tusk":
			item["release"]["enemy"] = "mistwisp"  # a gate breaker releases only flyers


# run.json tiers

func test_the_fixtures_pass_and_the_real_run_json_lists_tiers_1_to_4() -> void:
	assert_eq(RunData.check(Tx.files(), catalog), PackedStringArray())
	assert_not_null(data)
	assert_eq(Fx.run_data().tiers.size(), 0, "the plain fixtures have no tiers")
	var real: Dictionary = JsonFile.read("res://data/runs/run.json", 16384)
	assert_eq(real["status"], JsonFile.OK_STATUS)
	# The first four tiers are pinned. A tier added later leaves them as they are.
	assert_eq((real["data"]["tiers"] as Array).slice(0, 4), [
		{"level": "r5_l6", "towers": ["bramble_cottage"], "creatures": ["mossbud", "mistwisp"], "bosses": ["burrowbelly"], "grid": "T"},
		{"level": "r6_l6", "towers": ["scarecrow"], "creatures": ["gleamer", "sleepyhead"], "bosses": ["old_hayrick"], "grid": "X"},
		{"level": "r7_l6", "towers": ["snow_fort"], "creatures": ["snowroller", "yawner"], "bosses": ["snowsnore"], "grid": "^v<>"},
		{"level": "r8_l6", "towers": ["moth_lantern"], "creatures": ["blinker", "hootling"], "bosses": ["glimmertoad"], "grid": "PQ"},
	], "tier 1 of E5.1, tier 2 of E6.1b, tier 3 of E7.1b and tier 4 of E8.1b")
	var bands: Array = real["data"]["bands"]
	assert_eq((bands[1] as Array).slice(0, 5), ["skitter", "flitter", "shellback", "mossbud", "sleepyhead"], "band 2 gains Mossbud and Sleepyhead")
	assert_eq((bands[2] as Array).slice(0, 5), ["bubbler", "puffball", "gleamer", "snowroller", "blinker"], "band 3 gains Gleamer, Snowroller and Blinker")
	assert_eq((bands[3] as Array).slice(0, 4), ["mender", "dusk_moth", "mistwisp", "yawner"], "band 4 gains Mistwisp and Yawner")
	assert_eq((bands[4] as Array).slice(0, 2), ["gatecrasher", "hootling"], "band 5 gains Hootling")


func test_the_tiers_are_read_in_order() -> void:
	assert_eq(RunData.MAX_TIERS, 4)
	assert_eq(data.tiers.size(), 4)
	assert_eq(data.tiers[0], {
		"level": &"r5_l6", "towers": [&"bramble_cottage"], "creatures": [&"mossbud", &"mistwisp"],
		"bosses": [&"burrowbelly"], "grid": "T",
	})
	assert_eq(data.tiers[1]["level"], &"r6_l6")
	assert_eq(data.tiers[1]["grid"], "X")
	assert_eq(data.tiers[1]["bosses"], [&"old_hayrick"])
	assert_eq(data.tiers[2], {
		"level": &"r7_l6", "towers": [&"snow_fort"], "creatures": [&"snowroller", &"yawner"],
		"bosses": [&"snowsnore"], "grid": "^v<>",
	})
	assert_eq(data.tiers[3], {
		"level": &"r8_l6", "towers": [&"moth_lantern"], "creatures": [&"blinker", &"hootling"],
		"bosses": [&"glimmertoad"], "grid": "PQ",
	})


## Takes tier 4 out of the fixtures: its tier entry, cards, segment and packs.
func _drop_tier_4(f: Dictionary) -> void:
	_tiers(f).resize(3)
	var cards: Array = f["cards/cards.json"]["cards"]
	cards.erase(_card_in(f, "tower_moth_lantern"))
	cards.erase(_card_in(f, "bright_wick"))
	f["segments/index.json"]["segments"].erase("mid_stumps")
	f.erase("segments/mid_stumps.json")
	for id: String in ["band3_blinker", "band4_blinker", "band5_hootling", "band6_glimmertoad"]:
		_drop_pack(f, id)


func test_the_fixtures_hold_the_most_tiers() -> void:
	assert_eq(_tiers(Tx.files()).size(), RunData.MAX_TIERS)


func test_a_tier_may_list_nothing() -> void:
	var files: Dictionary = Tx.files()
	_drop_tier_4(files)
	# The stats lose the tier 4 stand-ins too, so no tower is left without its card.
	var three: Catalog = Tx.catalog(func(all: Dictionary) -> void:
		var gone: Array = ["moth_lantern", "blinker", "hootling", "glimmertoad"]
		all["towers"]["towers"] = (all["towers"]["towers"] as Array).filter(func(item: Dictionary) -> bool: return not gone.has(item["id"]))
		all["enemies"]["enemies"] = (all["enemies"]["enemies"] as Array).filter(func(item: Dictionary) -> bool: return not gone.has(item["id"]))
	)
	var listed: int = _tiers(files).size()
	assert_eq(RunData.check(files, three), PackedStringArray(), "three tiers pass")
	_empty_tiers(files, RunData.MAX_TIERS - listed)
	assert_eq(RunData.check(files, three), PackedStringArray())
	var four: RunData = RunData.from_data(files, three)
	assert_eq(four.tiers.size(), RunData.MAX_TIERS)
	assert_eq(four.tiers[3], {"level": &"r8_l6", "towers": [], "creatures": [], "bosses": [], "grid": ""})
	# Tiers that list nothing add nothing, so their plans are the plans of the last tier that does.
	for run_seed: int in [1, 2, 3]:
		for tier: int in range(listed + 1, RunData.MAX_TIERS + 1):
			assert_eq(MapAssembler.plan(run_seed, four, tier), MapAssembler.plan(run_seed, four, listed))


func test_run_json_needs_the_tiers_key() -> void:
	_expect("no tiers key", func(f: Dictionary) -> void: f["runs/run.json"].erase("tiers"), "tiers")


func test_hostile_tiers_lists_are_refused() -> void:
	_expect("not a list", func(f: Dictionary) -> void: f["runs/run.json"]["tiers"] = "none", "tiers")
	_expect("not a list (object)", func(f: Dictionary) -> void: f["runs/run.json"]["tiers"] = {}, "tiers")
	_expect("one tier over the most", func(f: Dictionary) -> void: _empty_tiers(f, RunData.MAX_TIERS + 1 - _tiers(f).size()), "tiers")
	_expect("an entry that is not an object", func(f: Dictionary) -> void: _tiers(f)[0] = 7, "tiers[0]")
	for key: String in ["level", "towers", "creatures", "bosses", "grid"]:
		_expect("missing " + key, func(f: Dictionary) -> void: _tiers(f)[0].erase(key), "tiers[0]")
	_expect("an extra key", func(f: Dictionary) -> void: _tiers(f)[0]["rating"] = 1, "tiers[0]")


func test_hostile_tier_levels_are_refused() -> void:
	_expect("level is a number", func(f: Dictionary) -> void: _tiers(f)[0]["level"] = 5, "level")
	_expect("level is empty", func(f: Dictionary) -> void: _tiers(f)[0]["level"] = "", "level")
	_expect("level has a space", func(f: Dictionary) -> void: _tiers(f)[0]["level"] = "r5 l6", "level")


func test_hostile_tier_towers_are_refused() -> void:
	_expect("unknown tower", func(f: Dictionary) -> void: _tiers(f)[0]["towers"] = ["nothing"], "tiers[0].towers[0]: names no tower")
	_expect("a tower the run starts with", func(f: Dictionary) -> void: _tiers(f)[0]["towers"] = ["sling_post"], "starts with")
	_expect("a tower twice in one tier", func(f: Dictionary) -> void: _tiers(f)[0]["towers"] = ["bramble_cottage", "bramble_cottage"], "more than one tier")
	_expect("a tower in two tiers", func(f: Dictionary) -> void: _tiers(f)[1]["towers"] = ["bramble_cottage"], "more than one tier")
	_expect("a tower id that is a number", func(f: Dictionary) -> void: _tiers(f)[0]["towers"] = [4], "towers[0]")
	_expect("towers is not a list", func(f: Dictionary) -> void: _tiers(f)[0]["towers"] = "bramble_cottage", "towers")
	_expect("eleven towers", func(f: Dictionary) -> void: _tiers(f)[0]["towers"] = _many(11, "bramble_cottage"), "towers")


func test_hostile_tier_creatures_are_refused() -> void:
	_expect("unknown creature", func(f: Dictionary) -> void: _tiers(f)[0]["creatures"] = ["nothing"], "tiers[0].creatures[0]: names no creature")
	_expect("a boss as a creature", func(f: Dictionary) -> void: _tiers(f)[0]["creatures"] = ["burrowbelly"], "cannot be listed")
	_expect("puff", func(f: Dictionary) -> void: _tiers(f)[0]["creatures"] = ["puff"], "cannot be listed")
	_expect("a creature twice", func(f: Dictionary) -> void: _tiers(f)[0]["creatures"] = ["mossbud", "mossbud"], "more than one tier")
	_expect("a creature in two tiers", func(f: Dictionary) -> void: _tiers(f)[1]["creatures"] = ["mossbud"], "more than one tier")
	_expect("creatures is not a list", func(f: Dictionary) -> void: _tiers(f)[0]["creatures"] = {}, "creatures")
	_expect("sixty five creatures", func(f: Dictionary) -> void: _tiers(f)[0]["creatures"] = _many(65, "mossbud"), "creatures")


func test_hostile_tier_bosses_are_refused() -> void:
	_expect("unknown boss", func(f: Dictionary) -> void: _tiers(f)[0]["bosses"] = ["nothing"], "tiers[0].bosses[0]: names no boss")
	_expect("a creature as a boss", func(f: Dictionary) -> void: _tiers(f)[0]["bosses"] = ["scamp"], "names no boss")
	_expect("a boss twice", func(f: Dictionary) -> void: _tiers(f)[0]["bosses"] = ["burrowbelly", "burrowbelly"], "more than one tier")
	_expect("a boss in two tiers", func(f: Dictionary) -> void: _tiers(f)[1]["bosses"] = ["burrowbelly"], "more than one tier")
	_expect("bosses is not a list", func(f: Dictionary) -> void: _tiers(f)[0]["bosses"] = 3, "bosses")
	_expect("nine bosses", func(f: Dictionary) -> void: _tiers(f)[0]["bosses"] = _many(9, "burrowbelly"), "bosses")


func test_hostile_tier_grids_are_refused() -> void:
	_expect("a plain road character", func(f: Dictionary) -> void: _tiers(f)[0]["grid"] = "#", "not a map feature")
	_expect("scenery", func(f: Dictionary) -> void: _tiers(f)[0]["grid"] = ".", "not a map feature")
	_expect("a lower case letter", func(f: Dictionary) -> void: _tiers(f)[0]["grid"] = "t", "not a map feature")
	_expect("a character repeated", func(f: Dictionary) -> void: _tiers(f)[0]["grid"] = "TT", "repeated")
	_expect("a character in two tiers", func(f: Dictionary) -> void: _tiers(f)[1]["grid"] = "T", "more than one tier")
	_expect("grid is a number", func(f: Dictionary) -> void: _tiers(f)[0]["grid"] = 7, "grid")
	_expect("grid is a list", func(f: Dictionary) -> void: _tiers(f)[0]["grid"] = ["T"], "grid")
	_expect("nine characters", func(f: Dictionary) -> void: _tiers(f)[0]["grid"] = "TX^v<>PQT", "grid")


func test_all_eight_feature_characters_are_accepted() -> void:
	var files: Dictionary = Tx.files()
	_tiers(files)[0]["grid"] = "T^<P"
	_tiers(files)[1]["grid"] = "Xv>Q"
	_tiers(files)[2]["grid"] = ""
	_tiers(files)[3]["grid"] = ""
	assert_eq(RunData.check(files, catalog), PackedStringArray())
	assert_eq(RunData.TIER_FEATURES, "TX^v<>PQ")


func test_a_broken_run_json_does_not_hide_the_other_files_checks() -> void:
	var files: Dictionary = Tx.files()
	_tiers(files)[0]["towers"] = ["nothing"]
	files["segments/packs.json"]["packs"][0]["id"] = "bad id"
	var found: String = "\n".join(RunData.check(files, catalog))
	assert_true(found.contains("tiers[0].towers[0]"))
	assert_true(found.contains("packs"), "the pack problem is reported too")


# the tier of things

func test_cards_take_their_towers_tier() -> void:
	assert_eq(data.card(&"tower_bramble_cottage")["tier"], 1)
	assert_eq(data.card(&"thorn_tips")["tier"], 1)
	assert_eq(data.card(&"tower_scarecrow")["tier"], 2)
	assert_eq(data.card(&"straw_hats")["tier"], 2)
	assert_eq(data.card(&"tower_snow_fort")["tier"], 3)
	assert_eq(data.card(&"packed_snow")["tier"], 3)
	assert_eq(data.card(&"tower_moth_lantern")["tier"], 4)
	assert_eq(data.card(&"bright_wick")["tier"], 4)
	for id: StringName in [&"tower_pumpkin_catapult", &"sharp_pebbles", &"spare_gate", &"gold_purse", &"flock", &"piggy_bank"]:
		assert_eq(data.card(id)["tier"], 0, String(id))
	assert_eq(Fx.run_data().card(&"sharp_pebbles")["tier"], 0, "with no tiers every card is tier 0")


func test_segments_take_the_highest_tier_of_their_features() -> void:
	assert_eq(data.segment(&"mid_tunnel")["tier"], 1)
	assert_eq(data.segment(&"mid_bridge")["tier"], 2)
	assert_eq(data.segment(&"mid_slide")["tier"], 3)
	assert_eq(data.segment(&"mid_stumps")["tier"], 4)
	for id: StringName in [&"top_one", &"mid_split", &"bot_home", &"mid_merge"]:
		assert_eq(data.segment(id)["tier"], 0, String(id))
	# The unit rule: the highest tier among the characters, and 0 without a feature.
	var table: Dictionary = {"T": 1, "X": 2, "v": 3, "P": 4}
	assert_eq(RunSegments.tier_of(PackedStringArray(["...#...", ".T.#.X."]), table), 2)
	assert_eq(RunSegments.tier_of(PackedStringArray(["...#...", ".v.#.X."]), table), 3)
	assert_eq(RunSegments.tier_of(PackedStringArray(["...#...", ".P.#.T."]), table), 4)
	assert_eq(RunSegments.tier_of(PackedStringArray(["...#...", "o.G#B.."]), table), 0)
	assert_eq(RunSegments.tier_of(PackedStringArray(["..^>."]), table), 0, "a feature no tier lists is tier 0")
	assert_eq(RunSegments.tier_of(PackedStringArray(["..T.."]), {}), 0)


func test_packs_take_the_highest_tier_of_creatures_and_boss() -> void:
	var by_id: Dictionary = {}
	for pack: Dictionary in data.packs:
		by_id[pack["id"]] = pack
	assert_eq(by_id["band2_mossbud"]["tier"], 1)
	assert_eq(by_id["band3_gleamer"]["tier"], 2)
	assert_eq(by_id["band6_burrowbelly"]["tier"], 1)
	assert_eq(by_id["band6_hayrick"]["tier"], 2)
	assert_eq(by_id["band3_snowroller"]["tier"], 3)
	assert_eq(by_id["band4_yawner"]["tier"], 3)
	assert_eq(by_id["band6_snowsnore"]["tier"], 3)
	assert_eq(by_id["band3_blinker"]["tier"], 4)
	assert_eq(by_id["band4_blinker"]["tier"], 4)
	assert_eq(by_id["band5_hootling"]["tier"], 4)
	assert_eq(by_id["band6_glimmertoad"]["tier"], 4)
	assert_eq(by_id["band2_pack0"]["tier"], 0)
	assert_eq(by_id["band6_pack0"]["tier"], 0)
	for pack: Dictionary in Fx.run_data().packs:
		assert_eq(pack["tier"], 0, "with no tiers every pack is tier 0: " + String(pack["id"]))


func _one_group_pack(enemy: String, boss: String = "") -> Dictionary:
	var groups: Array = [{"enemy": enemy, "count": 1, "entrance": 1, "at_ms": 0, "every_ms": 50}]
	return {"boss": StringName(boss), "waves": [{"groups": groups}, {"groups": groups}, {"groups": groups}]}


func test_a_pack_counts_what_its_creatures_summon_split_into_or_release() -> void:
	var table: Dictionary = {&"mossbud": 1, &"mistwisp": 1}
	assert_eq(RunPacks.pack_tier(_one_group_pack("puffball"), catalog, table), 0, "a Puffball splits into a Puff: tier 0")
	assert_eq(RunPacks.pack_tier(_one_group_pack("mossbud"), catalog, table), 1)
	var changed: Catalog = Tx.catalog(_bring_mossbud)
	assert_not_null(changed)
	assert_eq(RunPacks.pack_tier(_one_group_pack("puffball"), changed, table), 1, "split into")
	assert_eq(RunPacks.pack_tier(_one_group_pack("scamp", "grumblesack"), changed, table), 1, "a boss's summon")
	assert_eq(RunPacks.pack_tier(_one_group_pack("scamp", "old_tusk"), changed, table), 1, "a boss's release")
	assert_eq(RunPacks.pack_tier(_one_group_pack("scamp", "ironshell"), changed, table), 0)
	assert_eq(RunPacks.pack_tier(_one_group_pack("grumblesack"), changed, table), 1, "a boss in a group")
	var deep: Dictionary = {&"mossbud": 1, &"gleamer": 2}
	var mixed: Dictionary = _one_group_pack("gleamer", "burrowbelly")
	assert_eq(RunPacks.pack_tier(mixed, catalog, deep), 2, "the highest of creature and boss")


# map feature characters in segments

func test_segments_take_the_feature_characters_as_road() -> void:
	assert_eq(RunSegments.ROAD_CHARS, LevelData.ROAD_CHARS, "one list of road characters")
	assert_eq(RunSegments.ROAD_CHARS, "#G1234BTX^v<>PQ")
	assert_eq(data.segment(&"mid_stumps")["bottom_ports"], [3], "a stump counts as road too")
	# A feature in the port rows counts as a road cell there.
	assert_eq(data.segment(&"mid_tunnel")["bottom_ports"], [3])
	assert_eq(data.segment(&"mid_bridge")["top_ports"], [3])
	assert_eq(data.segment(&"mid_bridge")["bottom_ports"], [3])
	assert_eq(data.segment(&"mid_slide")["bottom_ports"], [3], "a slide arrow counts as road in a port row")


func test_a_feature_counts_in_the_road_rules_of_a_segment() -> void:
	# A tunnel in a 2 x 2 block of road is refused like any road.
	var files: Dictionary = Tx.files()
	files["segments/mid_tunnel.json"]["grid"][2] = ".GTo.G."
	var found: String = "\n".join(RunData.check(files, catalog))
	assert_true(found.contains("roads must be one tile wide"), found)
	# Two feature cells side by side in a port row are two road cells side by side.
	var files2: Dictionary = Tx.files()
	files2["segments/mid_bridge.json"]["grid"][0] = "..XT..."
	assert_true("\n".join(RunData.check(files2, catalog)).contains("two road cells side by side"))
	# A feature character no tier lists is allowed and is tier 0.
	var files3: Dictionary = Tx.files()
	_tiers(files3)[1]["grid"] = ""
	assert_eq(RunData.check(files3, catalog), PackedStringArray())
	assert_eq(RunData.from_data(files3, catalog).segment(&"mid_bridge")["tier"], 0)


# the new RunData checks

func test_a_card_may_not_name_a_creature_of_a_higher_tier() -> void:
	_expect("a risk card brings a tier 1 creature", func(f: Dictionary) -> void: _add_risk(f, "mossbud_march", "mossbud"), "mossbud is of a higher tier than the card")
	_expect("a risk card brings a tier 2 boss", func(f: Dictionary) -> void: _add_risk(f, "hayrick_night", "old_hayrick"), "old_hayrick is of a higher tier")


func test_a_risk_card_naming_a_tier_0_creature_still_passes() -> void:
	var files: Dictionary = Tx.files()
	assert_eq(_card_in(files, "flock")["effects"][0]["enemy"], "flitter")
	assert_eq(RunData.check(files, catalog), PackedStringArray())


func test_every_band_needs_four_packs_of_tier_0() -> void:
	_expect("a tier 1 pack does not count", func(f: Dictionary) -> void: _use_in_wave_2(f, "band2_pack3", "mossbud"), "band 2 needs at least 4 packs of tier 0; it has 3")
	_expect("band 6 with three boss packs of tier 1", func(f: Dictionary) -> void: _three_boss_packs_to_tier_1(f), "band 6 needs at least 4 packs of tier 0; it has 3")


func test_every_boss_still_needs_a_band_6_pack() -> void:
	_expect("no pack for the tier 2 boss", func(f: Dictionary) -> void: _drop_pack(f, "band6_hayrick"), "no band 6 pack for the boss old_hayrick")
	_expect("no pack for the tier 4 boss", func(f: Dictionary) -> void: _drop_pack(f, "band6_glimmertoad"), "no band 6 pack for the boss glimmertoad")


func test_a_pack_may_use_a_tier_creature_in_any_band_but_not_an_unlisted_one() -> void:
	var files: Dictionary = Tx.files()
	_use_in_wave_2(files, "band2_mossbud", "gleamer")
	assert_eq(RunData.check(files, catalog), PackedStringArray(), "a tier creature in band 2")
	# A creature no band and no tier lists is still refused (2.9).
	var plain: Dictionary = Fx.files_from_json()
	plain["segments/packs.json"]["packs"][0]["waves"][1]["groups"][0]["enemy"] = "puffball"
	assert_true("\n".join(RunData.check(plain, Fx.catalog())).contains("is not added by bands"))


func test_the_coverage_holds_at_tier_0() -> void:
	# Both bottoms get a tunnel, so they are tier 1 and tier 0 has none.
	_expect("tier 0 has no bottom segment", func(f: Dictionary) -> void: _both_bottoms_get_tunnels(f), "need at least one top, one middle and one bottom")


func _both_bottoms_get_tunnels(f: Dictionary) -> void:
	_road_to_tunnel(f, "bot_home")
	_road_to_tunnel(f, "bot_edge")


func test_the_coverage_holds_at_every_higher_tier_too() -> void:
	# A tier 2 middle that no bottom fits under breaks tier 2 only.
	var files: Dictionary = Tx.files()
	files["segments/mid_bridge.json"]["grid"][4] = ".#....."
	var joined: String = "\n".join(RunData.check(files, catalog))
	assert_true(joined.contains("tier 2: mid_bridge.json: no bottom segment fits under this middle segment"), joined)
	assert_false(joined.contains("tier 1:"), "tier 1 is fine")
	assert_null(RunData.from_data(files, catalog))
	# With the bridge at tier 1 instead, it breaks tier 1 and is named once, not again at tier 2.
	_tiers(files)[0]["grid"] = "TX"
	_tiers(files)[1]["grid"] = ""
	var again: String = "\n".join(RunData.check(files, catalog))
	assert_true(again.contains("tier 1: mid_bridge.json"), again)
	assert_false(again.contains("tier 2:"), again)


func test_a_problem_found_at_tier_0_is_named_once() -> void:
	var files: Dictionary = Tx.files()
	files["segments/mid_split.json"]["grid"][4] = "......#"
	var count: int = 0
	var found: PackedStringArray = RunData.check(files, catalog)
	for line: String in found:
		if line.contains("mid_split.json"):
			count += 1
	assert_eq(count, 1, "\n".join(found))
	assert_true("\n".join(found).contains("mid_split.json: no bottom segment fits"))
	assert_false("\n".join(found).contains("tier 1: mid_split"))


# the filters

func test_pool_and_card_ids_leave_out_cards_above_the_tier() -> void:
	var every: Array[StringName] = data.card_ids(4)
	assert_eq(every.size(), 23)
	assert_eq(data.card_ids(_top()), every, "the top tier sees every card")
	var three: Array[StringName] = data.card_ids(3)
	assert_eq(three.size(), 21, "tier 3 does not see the Moth Lantern cards")
	assert_false(three.has(&"tower_moth_lantern"))
	assert_false(three.has(&"bright_wick"))
	assert_true(every.has(&"tower_moth_lantern"))
	assert_true(every.has(&"bright_wick"))
	var all: Array[StringName] = data.card_ids(2)
	assert_eq(all.size(), 19, "tier 2 does not see the Snow Fort cards")
	var zero: Array[StringName] = data.card_ids()
	assert_eq(zero.size(), 15, "the default is tier 0")
	assert_eq(zero, Fx.run_data().card_ids(), "tier 0 is exactly the plain fixtures' cards, in their order")
	assert_false(zero.has(&"tower_bramble_cottage"))
	assert_false(zero.has(&"straw_hats"))
	var one: Array[StringName] = data.card_ids(1)
	assert_eq(one.size(), 17)
	assert_true(one.has(&"tower_bramble_cottage"))
	assert_true(one.has(&"thorn_tips"))
	assert_false(one.has(&"tower_scarecrow"))
	assert_true(all.has(&"straw_hats"))
	assert_false(all.has(&"tower_snow_fort"))
	assert_false(all.has(&"packed_snow"))
	assert_true(every.has(&"tower_snow_fort"))
	assert_true(every.has(&"packed_snow"))
	# File order: a filtered list is the full list with things removed.
	var at: int = -1
	for id: StringName in zero:
		var next: int = all.find(id)
		assert_true(next > at, "%s keeps its place" % id)
		at = next


func test_pool_respects_unlocks_and_tiers_together() -> void:
	assert_false(data.pool({}, 2).has(&"straw_hats"), "its unlock is not reached")
	assert_true(data.pool({"stars": 10}, 2).has(&"straw_hats"))
	assert_false(data.pool({"stars": 10}, 1).has(&"straw_hats"), "reached, but above the tier")
	assert_true(data.pool({}, 1).has(&"thorn_tips"))
	assert_false(data.pool({}, 2).has(&"packed_snow"))
	assert_true(data.pool({}, 3).has(&"packed_snow"))
	assert_false(data.pool({}).has(&"thorn_tips"))
	assert_eq(data.pool({"stars": 1000}), Fx.run_data().pool({"stars": 1000}), "tier 0 pool equals today's")
	assert_false(data.pool({}, 3).has(&"bright_wick"))
	assert_true(data.pool({}, 4).has(&"bright_wick"))
	assert_eq(_pool(4), data.card_ids(4))
	assert_eq(_pool(3), data.card_ids(3))
	assert_eq(_pool(2), data.card_ids(2))
	assert_eq(_pool(1), data.card_ids(1))
	assert_eq(_pool(0), data.card_ids(0))


func test_segment_filters_keep_index_order_and_leave_out_higher_tiers() -> void:
	var ids: Callable = func(list: Array[Dictionary]) -> Array:
		return list.map(func(s: Dictionary) -> StringName: return s["id"])
	var plain: Array = ids.call(Fx.run_data().segments_of(&"middle"))
	assert_eq(ids.call(data.segments_of(&"middle")), plain, "tier 0: today's middles")
	assert_eq(ids.call(data.segments_of(&"middle", 0)), plain)
	var one: Array = ids.call(data.segments_of(&"middle", 1))
	assert_true(one.has(&"mid_tunnel"))
	assert_false(one.has(&"mid_bridge"))
	assert_true(one.find(&"mid_tunnel") == one.find(&"mid_split") + 1, "it sits where the index puts it")
	var two: Array = ids.call(data.segments_of(&"middle", 2))
	assert_true(two.has(&"mid_bridge"))
	assert_false(two.has(&"mid_slide"))
	assert_eq(two.size(), plain.size() + 2)
	var three: Array = ids.call(data.segments_of(&"middle", 3))
	assert_true(three.has(&"mid_slide"))
	assert_false(three.has(&"mid_stumps"))
	assert_eq(three.size(), plain.size() + 3)
	assert_true(three.find(&"mid_slide") == three.find(&"mid_side") + 1, "it sits where the index puts it")
	var four: Array = ids.call(data.segments_of(&"middle", 4))
	assert_true(four.has(&"mid_stumps"))
	assert_eq(four.size(), plain.size() + 4)
	assert_true(four.find(&"mid_stumps") == four.find(&"mid_merge") + 1, "it sits where the index puts it")
	assert_eq(ids.call(data.segments_of(&"top", 2)), ids.call(Fx.run_data().segments_of(&"top")), "the tops have no features")


func test_segments_under_filter_by_tier() -> void:
	var ids: Callable = func(list: Array[Dictionary]) -> Array:
		return list.map(func(s: Dictionary) -> StringName: return s["id"])
	var base: Array = ids.call(Fx.run_data().segments_under(&"top_one"))
	assert_eq(ids.call(data.segments_under(&"top_one")), base)
	assert_false(ids.call(data.segments_under(&"top_one", 1)).has(&"mid_bridge"))
	assert_true(ids.call(data.segments_under(&"top_one", 1)).has(&"mid_tunnel"))
	assert_true(ids.call(data.segments_under(&"top_one", 2)).has(&"mid_bridge"))
	assert_false(ids.call(data.segments_under(&"top_one", 2)).has(&"mid_slide"))
	assert_true(ids.call(data.segments_under(&"top_one", 3)).has(&"mid_slide"))
	assert_false(ids.call(data.segments_under(&"top_one", 3)).has(&"mid_stumps"))
	assert_true(ids.call(data.segments_under(&"top_one", 4)).has(&"mid_stumps"))
	# Bottoms under a middle have no features here: the filter changes nothing for them.
	assert_eq(ids.call(data.segments_under(&"mid_split", 2)), ids.call(data.segments_under(&"mid_split")))
	assert_eq(data.segments_under(&"nothing", 2), [])


func test_pack_and_boss_filters_by_tier() -> void:
	var ids: Callable = func(list: Array[Dictionary]) -> Array:
		return list.map(func(s: Dictionary) -> StringName: return s["id"])
	var base: RunData = Fx.run_data()
	for band: int in range(1, 7):
		assert_eq(ids.call(data.packs_of(band)), ids.call(base.packs_of(band)), "band %d at tier 0" % band)
	assert_true(ids.call(data.packs_of(2, &"", 1)).has(&"band2_mossbud"))
	assert_false(ids.call(data.packs_of(2)).has(&"band2_mossbud"))
	assert_false(ids.call(data.packs_of(3, &"", 1)).has(&"band3_gleamer"))
	assert_true(ids.call(data.packs_of(3, &"", 2)).has(&"band3_gleamer"))
	assert_eq(ids.call(data.packs_of(2, &"", 1))[0], &"band2_mossbud", "file order: it is first in the file")
	assert_eq(ids.call(data.packs_of(6, &"burrowbelly", 1)), [&"band6_burrowbelly"])
	assert_eq(ids.call(data.packs_of(6, &"burrowbelly")), [], "not at tier 0")
	assert_eq(ids.call(data.packs_of(6, &"old_hayrick", 1)), [])
	assert_eq(ids.call(data.packs_of(6, &"old_hayrick", 2)), [&"band6_hayrick"])
	assert_eq(ids.call(data.packs_of(6, &"snowsnore", 2)), [], "not at tier 2")
	assert_eq(ids.call(data.packs_of(6, &"snowsnore", 3)), [&"band6_snowsnore"])
	assert_false(ids.call(data.packs_of(3, &"", 2)).has(&"band3_snowroller"))
	assert_true(ids.call(data.packs_of(3, &"", 3)).has(&"band3_snowroller"))
	assert_false(ids.call(data.packs_of(4, &"", 2)).has(&"band4_yawner"))
	assert_true(ids.call(data.packs_of(4, &"", 3)).has(&"band4_yawner"))
	assert_eq(ids.call(data.packs_of(6, &"glimmertoad", 3)), [], "not at tier 3")
	assert_eq(ids.call(data.packs_of(6, &"glimmertoad", 4)), [&"band6_glimmertoad"])
	assert_false(ids.call(data.packs_of(3, &"", 3)).has(&"band3_blinker"))
	assert_true(ids.call(data.packs_of(3, &"", 4)).has(&"band3_blinker"))
	assert_false(ids.call(data.packs_of(4, &"", 3)).has(&"band4_blinker"))
	assert_true(ids.call(data.packs_of(4, &"", 4)).has(&"band4_blinker"))
	assert_false(ids.call(data.packs_of(5, &"", 3)).has(&"band5_hootling"))
	assert_true(ids.call(data.packs_of(5, &"", 4)).has(&"band5_hootling"))
	assert_eq(data.boss_ids(), base.boss_ids(), "tier 0: today's bosses")
	assert_eq(data.boss_ids(0), [&"grumblesack", &"ironshell", &"moon_moth", &"old_tusk"])
	assert_eq(data.boss_ids(1).size(), 5)
	assert_true(data.boss_ids(1).has(&"burrowbelly"))
	assert_false(data.boss_ids(1).has(&"old_hayrick"))
	assert_eq(data.boss_ids(2).size(), 6)
	assert_eq(data.boss_ids(2)[5], &"old_hayrick", "enemies.json order")
	assert_eq(data.boss_ids(3).size(), 7)
	assert_eq(data.boss_ids(3)[6], &"snowsnore")
	assert_false(data.boss_ids(2).has(&"snowsnore"))
	assert_eq(data.boss_ids(4).size(), 8)
	assert_eq(data.boss_ids(4)[7], &"glimmertoad")
	assert_false(data.boss_ids(3).has(&"glimmertoad"))


# plans at every tier

func test_tier_0_plans_equal_the_plans_without_any_tier_content() -> void:
	var base: RunData = Fx.run_data()
	var cat: Catalog = Tx.catalog()
	for run_seed: int in range(1, 61):
		assert_eq(MapAssembler.plan(run_seed, data), MapAssembler.plan(run_seed, base), "seed %d" % run_seed)
		assert_eq(MapAssembler.plan(run_seed, data, 0), MapAssembler.plan(run_seed, base, 0), "seed %d, tier 0" % run_seed)
	for run_seed: int in [1, 7, 20261028]:
		var a: LevelData = MapAssembler.assemble(run_seed, data, cat)
		var b: LevelData = MapAssembler.assemble(run_seed, base, cat)
		assert_not_null(a)
		assert_eq(JSON.stringify(a.to_data()), JSON.stringify(b.to_data()), "level of seed %d" % run_seed)


func test_plans_use_only_things_of_the_tier_or_below() -> void:
	var packs: Dictionary = {}
	for pack: Dictionary in data.packs:
		packs[pack["id"]] = pack
	for tier: int in _top() + 1:
		for run_seed: int in range(1, 121):
			var plan: Dictionary = MapAssembler.plan(run_seed, data, tier)
			assert_false(plan.is_empty(), "seed %d tier %d" % [run_seed, tier])
			for id: StringName in _stack_ids(plan):
				assert_true(data.segment(id)["tier"] <= tier, "%s at tier %d" % [id, tier])
			for id: StringName in plan["packs"]:
				assert_true(packs[id]["tier"] <= tier, "%s at tier %d" % [id, tier])
			assert_true(data.boss_ids(tier).has(plan["boss"]))
			var last: Dictionary = packs[plan["packs"][5]]
			assert_eq(last["boss"], plan["boss"], "the band 6 pack is the boss's")


func test_higher_tiers_bring_the_new_things_in() -> void:
	var seen: Array[Dictionary] = []
	for tier: int in [2, 3, 4]:
		var boss: Dictionary = {}
		var segment: Dictionary = {}
		var pack: Dictionary = {}
		for run_seed: int in range(1, 401):
			var plan: Dictionary = MapAssembler.plan(run_seed, data, tier)
			boss[plan["boss"]] = true
			for id: StringName in _stack_ids(plan):
				segment[id] = true
			for id: StringName in plan["packs"]:
				pack[id] = true
		seen.append({"boss": boss, "segment": segment, "pack": pack})
	for id: StringName in [&"burrowbelly", &"old_hayrick"]:
		assert_true(seen[0]["boss"].has(id), "tier 2: %s" % id)
	for id: StringName in [&"mid_tunnel", &"mid_bridge"]:
		assert_true(seen[0]["segment"].has(id), "tier 2: %s" % id)
	for id: StringName in [&"band2_mossbud", &"band3_gleamer", &"band6_burrowbelly", &"band6_hayrick"]:
		assert_true(seen[0]["pack"].has(id), "tier 2: %s" % id)
	# Tier 3 brings its own and keeps the older ones.
	assert_true(seen[1]["boss"].has(&"snowsnore"))
	assert_true(seen[1]["boss"].has(&"old_hayrick"))
	assert_true(seen[1]["segment"].has(&"mid_slide"))
	assert_true(seen[1]["segment"].has(&"mid_bridge"))
	for id: StringName in [&"band3_snowroller", &"band4_yawner", &"band6_snowsnore", &"band3_gleamer", &"band6_hayrick"]:
		assert_true(seen[1]["pack"].has(id), "tier 3: %s" % id)
	# Tier 2 never meets them.
	assert_false(seen[0]["boss"].has(&"snowsnore"))
	assert_false(seen[0]["segment"].has(&"mid_slide"))
	for id: StringName in [&"band3_snowroller", &"band4_yawner", &"band6_snowsnore"]:
		assert_false(seen[0]["pack"].has(id), "tier 2: %s" % id)
	# Tier 4 brings its own and keeps the older ones.
	assert_true(seen[2]["boss"].has(&"glimmertoad"))
	assert_true(seen[2]["boss"].has(&"snowsnore"))
	assert_true(seen[2]["segment"].has(&"mid_stumps"))
	assert_true(seen[2]["segment"].has(&"mid_slide"))
	for id: StringName in [&"band3_blinker", &"band4_blinker", &"band5_hootling", &"band6_glimmertoad", &"band6_snowsnore"]:
		assert_true(seen[2]["pack"].has(id), "tier 4: %s" % id)
	# Tier 3 never meets them.
	assert_false(seen[1]["boss"].has(&"glimmertoad"))
	assert_false(seen[1]["segment"].has(&"mid_stumps"))
	for id: StringName in [&"band3_blinker", &"band4_blinker", &"band5_hootling", &"band6_glimmertoad"]:
		assert_false(seen[1]["pack"].has(id), "tier 3: %s" % id)


func test_plans_are_the_same_for_the_same_seed_and_tier() -> void:
	for tier: int in _top() + 1:
		for run_seed: int in [3, 99, 20261028]:
			assert_eq(MapAssembler.plan(run_seed, data, tier), MapAssembler.plan(run_seed, Tx.run_data(), tier))
			var a: LevelData = MapAssembler.assemble(run_seed, data, catalog, tier)
			var b: LevelData = MapAssembler.assemble(run_seed, Tx.run_data(), Tx.catalog(), tier)
			assert_not_null(a, "seed %d tier %d builds" % [run_seed, tier])
			assert_eq(JSON.stringify(a.to_data()), JSON.stringify(b.to_data()))


func test_every_plan_at_every_tier_builds_a_level() -> void:
	for tier: int in _top() + 1:
		for run_seed: int in range(1, 41):
			assert_not_null(MapAssembler.assemble(run_seed, data, catalog, tier), "seed %d tier %d" % [run_seed, tier])


func test_a_tier_outside_the_range_gives_no_plan() -> void:
	assert_eq(MapAssembler.plan(1, data, _top() + 1), {})
	assert_eq(MapAssembler.plan(1, data, -1), {})
	assert_null(MapAssembler.assemble(1, data, catalog, _top() + 1))
	assert_null(MapAssembler.assemble(1, data, catalog, -1))
	assert_eq(MapAssembler.plan(1, Fx.run_data(), 1), {}, "no tiers in the data")
	assert_not_null(MapAssembler.assemble(1, data, catalog, _top()))


# RunCards.has_stat

func test_splash_and_targets_are_for_attacking_towers_without_pulse_or_line() -> void:
	for id: StringName in catalog.tower_ids():
		var tower: TowerType = catalog.tower(id)
		var attacks: bool = tower.kind == &"attack"
		assert_eq(RunCards.has_stat(tower, "splash"), attacks, "splash of %s" % id)
		assert_eq(RunCards.has_stat(tower, "targets"), attacks, "targets of %s" % id)
		assert_eq(RunCards.has_stat(tower, "damage"), attacks, "damage of %s" % id)
		assert_eq(RunCards.has_stat(tower, "reload_ms"), attacks, "reload_ms of %s" % id)
		assert_true(RunCards.has_stat(tower, "reach"), "reach of %s" % id)
	assert_false(RunCards.has_stat(catalog.tower(&"lullaby_bell"), "splash"))


## Towers cloned from the Sling Post with one way of attacking on every stat block.
func _way_catalog() -> Catalog:
	return Tx.catalog(func(all: Dictionary) -> void:
		var sling: Dictionary = {}
		for item: Dictionary in all["towers"]["towers"]:
			if item["id"] == "sling_post":
				sling = item
		for way: Array in [["pulse_post", "pulse", true, "ground"], ["line_post", "line", 100, "ground"], ["lure_post", "lure_ms", 500, "air"]]:
			var copy: Dictionary = sling.duplicate(true)
			copy["id"] = way[0]
			copy["name"] = way[0]
			copy["plural"] = way[0] + "s"
			var blocks: Array = copy["tiers"].duplicate()
			for i: int in 2:
				copy["specs"][i]["id"] = "%s_path_%d" % [way[0], i]
				blocks.append(copy["specs"][i])
			for block: Dictionary in blocks:
				block[way[1]] = way[2]
				block["hits"] = way[3]
			all["towers"]["towers"].append(copy)
	)


func test_area_and_lure_towers_have_no_splash_and_area_towers_no_targets() -> void:
	var made: Catalog = _way_catalog()
	assert_not_null(made, "the clones pass the stat checks")
	if made == null:
		return
	for id: StringName in [&"pulse_post", &"line_post", &"lure_post"]:
		var tower: TowerType = made.tower(id)
		assert_not_null(tower, String(id))
		assert_false(RunCards.has_stat(tower, "splash"), "splash of %s" % id)
		assert_true(RunCards.has_stat(tower, "damage"), "damage of %s" % id)
		assert_true(RunCards.has_stat(tower, "reload_ms"), "reload_ms of %s" % id)
		assert_true(RunCards.has_stat(tower, "reach"), "reach of %s" % id)
	assert_false(RunCards.has_stat(made.tower(&"pulse_post"), "targets"))
	assert_false(RunCards.has_stat(made.tower(&"line_post"), "targets"))
	assert_true(RunCards.has_stat(made.tower(&"lure_post"), "targets"), "a lure tower may hit more targets")
	assert_true(RunCards.has_stat(made.tower(&"sling_post"), "splash"), "a plain attacker is unchanged")
	assert_true(RunCards.has_stat(made.tower(&"sling_post"), "targets"))


func test_a_perk_for_splash_or_targets_on_those_towers_is_refused() -> void:
	var made: Catalog = _way_catalog()
	var lure_splash: Callable = func(f: Dictionary) -> void:
		var card: Dictionary = JSON.parse_string(JSON.stringify(_card_in(f, "sharp_pebbles")))
		card["id"] = "lure_perk"
		card["tower"] = "lure_post"
		card["effects"] = [{"type": "tower_add", "tower": "lure_post", "stat": "splash", "amount": 25}]
		f["cards/cards.json"]["cards"].append(card)
	var files: Dictionary = Tx.files()
	lure_splash.call(files)
	var found: PackedStringArray = RunData.check(files, made)
	assert_true("\n".join(found).contains("lure_post has no splash"), "\n".join(found))
	var pulse_targets: Callable = func(f: Dictionary) -> void:
		var card: Dictionary = JSON.parse_string(JSON.stringify(_card_in(f, "sharp_pebbles")))
		card["id"] = "pulse_perk"
		card["tower"] = "pulse_post"
		card["effects"] = [{"type": "tower_add", "tower": "pulse_post", "stat": "targets", "amount": 1}]
		f["cards/cards.json"]["cards"].append(card)
	files = Tx.files()
	pulse_targets.call(files)
	found = RunData.check(files, made)
	assert_true("\n".join(found).contains("pulse_post has no targets"), "\n".join(found))


func test_the_real_bramble_cottage_takes_damage_perks_only() -> void:
	var real: Catalog = Golden.catalog()
	var bramble: TowerType = real.tower(&"bramble_cottage")
	assert_not_null(bramble)
	if bramble == null:
		return
	assert_false(RunCards.has_stat(bramble, "splash"))
	assert_false(RunCards.has_stat(bramble, "targets"))
	for stat: String in ["damage", "reload_ms", "reach"]:
		assert_true(RunCards.has_stat(bramble, stat), stat)


func test_a_stat_block_with_pulse_or_line_is_an_area_block() -> void:
	var plain: FakeBlock = FakeBlock.new()
	assert_false(RunCards.is_area_block(plain))
	var pulse: FakeBlock = FakeBlock.new()
	pulse.pulse = true
	assert_true(RunCards.is_area_block(pulse))
	var line: FakeBlock = FakeBlock.new()
	line.line = 50
	assert_true(RunCards.is_area_block(line))
	assert_false(RunCards.is_area_block(RefCounted.new()), "an object with neither field")
	for id: StringName in catalog.tower_ids():
		var block: TowerStats = catalog.tower(id).stats(1, -1)
		assert_false(RunCards.is_area_block(block), "%s has neither pulse nor line today" % id)


func test_the_card_check_uses_has_stat_for_perks() -> void:
	# A perk for a stat the tower lacks is refused, as before.
	_expect("splash on a Bell", func(f: Dictionary) -> void: _card_in(f, "deep_lullaby")["effects"][0]["stat"] = "splash", "has no splash")


# RunSession

func _start(run_seed: int, tier: int, day: String = "") -> RunSession:
	var pool: Array[StringName] = data.card_ids(tier) if day != "" else data.pool({}, tier)
	return RunSession.start(run_seed, day, false, pool, data, catalog, tier)


func _restore(s: RunSession, raw_run: Variant = null) -> RunSession:
	var run_raw: Variant = JSON.parse_string(JSON.stringify(s.to_data())) if raw_run == null else raw_run
	var loaded: Battle = Battle.from_data(JSON.parse_string(JSON.stringify(s.battle.to_data())), catalog)
	assert_not_null(loaded, "the battle loads")
	return RunSession.from_data(run_raw, loaded, data)


func test_a_session_keeps_its_tier() -> void:
	for tier: int in _top() + 1:
		var s: RunSession = _start(5, tier)
		assert_not_null(s, "tier %d" % tier)
		assert_eq(s.tier, tier)
		assert_eq(s.to_data()["tier"], tier)
	assert_eq(RunSession.start(5, "", false, data.pool({}), data, catalog).tier, 0, "tier 0 by default")


func test_a_session_builds_its_map_from_its_tier() -> void:
	for tier: int in _top() + 1:
		var s: RunSession = _start(9, tier)
		var level: LevelData = MapAssembler.assemble(9, data, catalog, tier)
		assert_eq(JSON.stringify(s.battle.level.to_data()), JSON.stringify(level.to_data()), "tier %d" % tier)


func test_a_session_refuses_a_tier_outside_the_range() -> void:
	assert_null(_start(5, _top() + 1))
	assert_null(RunSession.start(5, "", false, data.pool({}), data, catalog, -1))
	assert_null(RunSession.start(5, "", false, Fx.run_data().pool({}), Fx.run_data(), catalog, 1), "no tiers in the data")


func test_a_session_refuses_a_pool_with_a_card_above_its_tier() -> void:
	assert_null(RunSession.start(5, "", false, data.pool({}, 2), data, catalog, 1), "a tier 2 card in a tier 1 run")
	assert_null(RunSession.start(5, "", false, data.pool({}, 1), data, catalog, 0))
	assert_not_null(RunSession.start(5, "", false, data.pool({}, 1), data, catalog, 1))
	assert_not_null(RunSession.start(5, "", false, data.pool({}, 0), data, catalog, 2), "a smaller pool is fine")


func test_a_daily_has_a_tier_too() -> void:
	var day: String = "2026-10-28"
	var seed_value: int = RunSeeds.daily_seed(day)
	for tier: int in _top() + 1:
		var s: RunSession = RunSession.start(seed_value, day, false, data.card_ids(tier), data, catalog, tier)
		assert_not_null(s, "tier %d" % tier)
		assert_eq(s.tier, tier)
		assert_true(s.daily)
		assert_eq(s.to_data()["tier"], tier)
	assert_null(RunSession.start(seed_value, day, false, data.card_ids(2), data, catalog, 1))


func test_the_tier_is_saved_and_comes_back() -> void:
	for tier: int in _top() + 1:
		var s: RunSession = _start(11, tier)
		var back: RunSession = _restore(s)
		assert_not_null(back, "tier %d" % tier)
		if back == null:
			continue
		assert_eq(back.tier, tier)
		assert_eq(back.to_data(), s.to_data())


func test_a_daily_save_keeps_its_tier() -> void:
	var day: String = "2026-10-29"
	for tier: int in [2, _top()]:
		var s: RunSession = RunSession.start(RunSeeds.daily_seed(day), day, false, data.card_ids(tier), data, catalog, tier)
		var back: RunSession = _restore(s)
		assert_not_null(back, "tier %d" % tier)
		if back == null:
			return
		assert_eq(back.tier, tier)
		assert_eq(back.day, day)


func test_a_save_without_tier_is_a_tier_0_run() -> void:
	var s: RunSession = _start(12, 0)
	var raw: Dictionary = JSON.parse_string(JSON.stringify(s.to_data()))
	raw.erase("tier")
	var back: RunSession = _restore(s, raw)
	assert_not_null(back, "a save from before the expansion loads")
	assert_eq(back.tier, 0)
	assert_eq(back.to_data()["tier"], 0, "and is saved with its tier from then on")
	# It loads against run data with no tiers too.
	var plain: Dictionary = JSON.parse_string(JSON.stringify(Player.session(12).to_data()))
	plain.erase("tier")
	var s2: RunSession = Player.session(12)
	var loaded: Battle = Battle.from_data(JSON.parse_string(JSON.stringify(s2.battle.to_data())), Fx.catalog())
	var old: RunSession = RunSession.from_data(plain, loaded, Fx.run_data())
	assert_not_null(old)
	assert_eq(old.tier, 0)


func test_a_bad_tier_in_a_save_is_refused() -> void:
	var s: RunSession = _start(13, 1)
	for bad: Variant in [-1, _top() + 1, _top() + 2, 1000000, 1.5, "1", true, null, [1], {}, 1e30]:
		var raw: Dictionary = JSON.parse_string(JSON.stringify(s.to_data()))
		raw["tier"] = bad
		assert_null(_restore(s, raw), "tier %s" % str(bad))
	var ok: Dictionary = JSON.parse_string(JSON.stringify(s.to_data()))
	ok["tier"] = _top()
	assert_not_null(_restore(s, ok), "a tier up to the tier count is read (the pool is then smaller than the tier allows)")
	var raw_extra: Dictionary = JSON.parse_string(JSON.stringify(s.to_data()))
	raw_extra["level"] = 3
	assert_null(_restore(s, raw_extra), "an unknown key is still refused")


func test_a_save_whose_pool_has_a_card_above_its_tier_is_refused() -> void:
	var s: RunSession = _start(14, 1)
	var raw: Dictionary = JSON.parse_string(JSON.stringify(s.to_data()))
	raw["tier"] = 0
	assert_null(_restore(s, raw), "a tier 1 pool in a tier 0 run")
	var missing: Dictionary = JSON.parse_string(JSON.stringify(s.to_data()))
	missing.erase("tier")
	assert_null(_restore(s, missing), "a save without tier is tier 0, and the pool has tier 1 cards")
	var up: Dictionary = JSON.parse_string(JSON.stringify(s.to_data()))
	up["pool"].append("straw_hats")
	assert_null(_restore(s, up), "a tier 2 card in a tier 1 run")
	up["pool"].append("packed_snow")
	up["tier"] = 2
	assert_null(_restore(s, up), "a tier 3 card in a tier 2 run")
	up["pool"].erase("packed_snow")
	assert_not_null(_restore(s, up), "a tier 2 card is fine in a tier 2 run")
	up["pool"].append("packed_snow")
	up["tier"] = 3
	assert_not_null(_restore(s, up), "and a tier 3 card in a tier 3 run")
	up["pool"].append("bright_wick")
	assert_null(_restore(s, up), "a tier 4 card in a tier 3 run")
	up["tier"] = 4
	assert_not_null(_restore(s, up), "and a tier 4 card in a tier 4 run")


func test_a_tier_run_plays_to_the_end_and_resumes_the_same() -> void:
	for tier: int in [2, _top()]:
		var s: RunSession = RunSession.start(21, "", false, data.pool({"stars": 1000}, tier), data, catalog, tier)
		var player: RefCounted = Player.new(21, 0, false)
		player.rich = true
		var guard: int = 0
		while s.battle.waves_started < 4 or s.battle.phase != Battle.Phase.WAVE:
			assert_true(player.advance(s))
			guard += 1
			if guard > 100000:
				break
		var back: RunSession = _restore(s)
		assert_not_null(back, "tier %d" % tier)
		if back == null:
			return
		assert_eq(back.tier, tier)
		var twin: RefCounted = player.fork()
		assert_true(player.play(s))
		assert_true(twin.play(back))
		assert_eq(Player.fingerprint(back), Player.fingerprint(s), "tier %d" % tier)
