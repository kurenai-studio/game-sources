# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The real data/runs/run.json and data/cards/cards.json (docs/ARCHITECTURE.md 2.10, 2.11, 14.8),
## against the real stats. The real segments and packs come from the level designer. Most tests
## here pair the real plan and cards with fixture segments and packs: the regions 1 to 4 fixtures
## plus the tier stand-ins of tier_fixtures.gd. The last ones use the real files.

const Fx: GDScript = preload("res://tests/run/fixtures/run_fixtures.gd")
const Tx: GDScript = preload("res://tests/run/fixtures/tier_fixtures.gd")
const Golden: GDScript = preload("res://tests/run/fixtures/run_golden.gd")
const RUN_PATH: String = "res://data/runs/run.json"
const CARDS_PATH: String = "res://data/cards/cards.json"
const SEGMENT_DIR: String = "res://data/segments/"

## The 22 base cards then the 12 unlockable ones, in the order of 2.11. Each is
## [id, kind, tower, once, counter, at].
const CARDS: Array = [
	["tower_pumpkin_catapult", "tower", "pumpkin_catapult", true, "", 0],
	["tower_lullaby_bell", "tower", "lullaby_bell", true, "", 0],
	["tower_longbow_loft", "tower", "longbow_loft", true, "", 0],
	["tower_firework_tower", "tower", "firework_tower", true, "", 0],
	["tower_bakery", "tower", "bakery", true, "", 0],
	["sharp_pebbles", "perk", "sling_post", true, "", 0],
	["wide_splash", "perk", "pumpkin_catapult", true, "", 0],
	["deep_lullaby", "perk", "lullaby_bell", true, "", 0],
	["steady_aim", "perk", "longbow_loft", true, "", 0],
	["bigger_bangs", "perk", "firework_tower", true, "", 0],
	["warm_ovens", "perk", "bakery", true, "", 0],
	["spare_gate", "gate", "", false, "", 0],
	["gold_purse", "economy", "", false, "", 0],
	["fat_bounties", "economy", "", true, "", 0],
	["feast_days", "economy", "", true, "", 0],
	["fair_trade", "economy", "", true, "", 0],
	["tea_break", "economy", "", false, "", 0],
	["crowded_night", "risk", "", false, "", 0],
	["thick_hides", "risk", "", false, "", 0],
	["hurry_night", "risk", "", false, "", 0],
	["gateless_night", "risk", "", false, "", 0],
	["flock", "risk", "", false, "", 0],
	["twin_pebbles", "perk", "sling_post", true, "best_run_wave", 6],
	["heavy_pumpkins", "perk", "pumpkin_catapult", true, "best_run_wave", 12],
	["frost_chime", "perk", "lullaby_bell", true, "dailies_finished", 1],
	["volley", "perk", "longbow_loft", true, "runs_won", 1],
	["long_fuse", "perk", "firework_tower", true, "runs_won_normal", 1],
	["spice_rack", "perk", "bakery", true, "stars", 24],
	["piggy_bank", "economy", "", true, "stars", 36],
	["bargain", "economy", "", true, "stars", 48],
	["iron_gate", "gate", "", true, "twists_cleared", 1],
	["moonlit_wager", "risk", "", false, "stars", 60],
	["crasher_escort", "risk", "", false, "risky_wins", 1],
	["pip_parade", "risk", "", false, "stars", 72],
]

## The tier 1 cards of E5.1 (the tower card and the base perk of Bramble Cottage).
const TIER_1_CARDS: Array = ["tower_bramble_cottage", "thorn_tips"]
## The tier 2 cards of E6.1b (the tower card and the base perk of the Scarecrow).
const TIER_2_CARDS: Array = ["tower_scarecrow", "big_hat"]
## The tier 2 creatures: what only a tier 2 player meets (Old Hayrick is the tier 2 boss).
const TIER_2_CREATURES: Array = [&"gleamer", &"sleepyhead"]
## The tier 3 cards of E7.1b (the tower card and the base perk of the Snow Fort).
const TIER_3_CARDS: Array = ["tower_snow_fort", "packed_snow"]
## The tier 3 creatures: what only a tier 3 player meets (Snowsnore is the tier 3 boss).
const TIER_3_CREATURES: Array = [&"snowroller", &"yawner"]
## The tier 4 cards of E8.1b (the tower card and the base perk of the Moth Lantern).
const TIER_4_CARDS: Array = ["tower_moth_lantern", "bright_wick"]
## The tier 4 creatures: what only a tier 4 player meets (Glimmertoad is the tier 4 boss).
const TIER_4_CREATURES: Array = [&"blinker", &"hootling"]

var catalog: Catalog = null


func before_each() -> void:
	catalog = Golden.catalog()


func _read(path: String, cap: int) -> Variant:
	var got: Dictionary = JsonFile.read(path, cap)
	assert_eq(got["status"], JsonFile.OK_STATUS, path + " reads through the JSON reader")
	return got["data"]


## The real run plan and cards, with fixture segments and packs: the regions 1 to 4 fixtures
## and the stand-ins of the four tiers (tunnel, bridge, slide and stump segments, packs for the new
## creatures and one for each boss). The real run.json lists the tiers.
func _files() -> Dictionary:
	var files: Dictionary = Tx.files()
	files["runs/run.json"] = _read(RUN_PATH, 16384)
	files["cards/cards.json"] = _read(CARDS_PATH, 262144)
	return files


## _files() with the fixture build spot range, because the fixture segments have fewer than the
## 11 or 12 build spots the real run.json asks of a map. For tests that assemble maps.
func _playable_files() -> Dictionary:
	var files: Dictionary = _files()
	files["runs/run.json"]["spots"] = [8, 12]
	return files


func test_the_real_run_plan_and_cards_pass_the_check() -> void:
	var found: PackedStringArray = RunData.check(_files(), catalog)
	assert_eq(found, PackedStringArray(), "\n".join(found))
	assert_not_null(RunData.from_data(_files(), catalog))


func test_the_real_run_plan_is_the_one_in_the_contract() -> void:
	var data: RunData = RunData.from_data(_files(), catalog)
	assert_eq(data.strength_start, 100)
	assert_eq(data.strength_step, 10)
	assert_eq(data.start_gold, 300)
	assert_eq(data.gates, 1)
	assert_eq(data.towers, [&"sling_post"])
	assert_eq(data.rows, {"top": 4, "middle": 5, "bottom": 4})
	assert_eq([data.spots_min, data.spots_max, data.sockets_min, data.sockets_max], [11, 12, 2, 5])
	assert_eq(data.bands[0], [&"scamp", &"pip"])
	# Each band starts with the creatures of regions 1 to 4, then the tier creatures in tier order.
	assert_eq(data.bands[1].slice(0, 5), [&"skitter", &"flitter", &"shellback", &"mossbud", &"sleepyhead"])
	assert_eq(data.bands[2].slice(0, 5), [&"bubbler", &"puffball", &"gleamer", &"snowroller", &"blinker"])
	assert_eq(data.bands[3].slice(0, 4), [&"mender", &"dusk_moth", &"mistwisp", &"yawner"])
	assert_eq(data.bands[4], [&"gatecrasher", &"hootling"])
	assert_eq(data.bands[5].size(), 0)
	assert_eq([data.weights[&"tower"], data.weights[&"perk"], data.weights[&"gate"], data.weights[&"economy"], data.weights[&"risk"]], [30, 25, 10, 20, 15])


func test_wave_17_has_strength_260() -> void:
	var data: RunData = RunData.from_data(_files(), catalog)
	assert_eq(data.strength_start + data.strength_step * 16, 260)


func test_the_real_cards_are_the_34_of_the_contract_in_order() -> void:
	var data: RunData = RunData.from_data(_files(), catalog)
	assert_eq(data.cards.size(), CARDS.size() + TIER_1_CARDS.size() + TIER_2_CARDS.size() + TIER_3_CARDS.size() + TIER_4_CARDS.size(), "the 34 of tier 0, then 2 for each of tiers 1 to 4")
	var ids: Array[StringName] = data.card_ids()
	for i: int in CARDS.size():
		var want: Array = CARDS[i]
		assert_eq(ids[i], StringName(want[0]), "card %d" % i)
		var card: Dictionary = data.card(StringName(want[0]))
		assert_eq(card["kind"], StringName(want[1]), want[0])
		assert_eq(card["tower"], StringName(want[2]), want[0])
		assert_eq(card["once"], want[3], "once of %s" % want[0])
		if want[4] == "":
			assert_eq(card["unlock"], {}, "%s is a base card" % want[0])
		else:
			assert_eq(card["unlock"], {"counter": want[4], "at": want[5]}, "unlock of %s" % want[0])


func test_the_base_pool_is_the_22_base_cards() -> void:
	var data: RunData = RunData.from_data(_files(), catalog)
	var base: Array[StringName] = data.pool({})
	assert_eq(base.size(), 22)
	for i: int in 22:
		assert_eq(base[i], StringName(CARDS[i][0]))
	assert_eq(data.card_ids().size(), 34, "the daily uses all 34")
	var every: Dictionary = {
		&"best_run_wave": 12, &"runs_won": 1, &"runs_won_normal": 1, &"dailies_finished": 1,
		&"risky_wins": 1, &"stars": 72, &"twists_cleared": 1,
	}
	assert_eq(data.pool(every), data.card_ids())


func test_tier_1_adds_the_bramble_cottage_card_and_perk() -> void:
	var data: RunData = RunData.from_data(_files(), catalog)
	assert_eq(data.card_ids(1).size(), 36, "a tier 1 player does not see the Scarecrow cards")
	assert_eq(data.card_ids(0).size(), 34, "tier 0 keeps its 34")
	assert_eq(data.pool({}, 1).size(), 24)
	assert_eq(data.pool({}, 0).size(), 22, "tier 0 keeps its 22")
	for id: StringName in TIER_1_CARDS:
		assert_eq(data.card(id)["tier"], 1, "%s is tier 1" % id)
		assert_false(data.card_ids(0).has(id), "%s is not in the tier 0 daily" % id)
		assert_false(data.pool({}, 0).has(id), "%s is not in the tier 0 pool" % id)
		assert_true(data.pool({}, 1).has(id), "%s is in the tier 1 base pool" % id)
	var tower_card: Dictionary = data.card(&"tower_bramble_cottage")
	assert_eq(tower_card["kind"], &"tower")
	assert_eq(tower_card["tower"], &"bramble_cottage")
	assert_eq(tower_card["name"], "Bramble Cottage")
	assert_eq(tower_card["text"], "You can build Bramble Cottages for the rest of the run.")
	assert_true(tower_card["once"])
	assert_eq(tower_card["unlock"], {})
	assert_eq(tower_card["effects"].size(), 1)
	assert_eq(tower_card["effects"][0]["type"], "add_tower")
	var perk: Dictionary = data.card(&"thorn_tips")
	assert_eq(perk["kind"], &"perk")
	assert_eq(perk["tower"], &"bramble_cottage")
	assert_eq(perk["name"], "Thorn Tips")
	assert_eq(perk["text"], "Bramble Cottages deal 2 more damage per hit.")
	assert_true(perk["once"])
	assert_eq(perk["unlock"], {}, "a base perk")
	assert_eq(perk["effects"].size(), 1)
	assert_eq([perk["effects"][0]["type"], perk["effects"][0]["stat"], perk["effects"][0]["amount"]], ["tower_add", "damage", 2])
	var ids: Array[StringName] = data.card_ids(1)
	assert_eq(ids.find(&"tower_bramble_cottage"), 5, "after the five tower cards")
	assert_eq(ids.find(&"thorn_tips"), 12, "after the six base perks")


func test_tier_2_adds_the_scarecrow_card_and_perk() -> void:
	var data: RunData = RunData.from_data(_files(), catalog)
	assert_eq(data.card_ids(2).size(), 38, "tier 2 does not see the Snow Fort cards")
	assert_eq(data.card_ids(1).size(), 36, "tier 1 keeps its 36")
	assert_eq(data.card_ids(0).size(), 34, "tier 0 keeps its 34")
	assert_eq(data.pool({}, 2).size(), 26)
	assert_eq(data.pool({}, 1).size(), 24, "tier 1 keeps its 24")
	assert_eq(data.pool({}, 0).size(), 22, "tier 0 keeps its 22")
	var every: Dictionary = {"stars": 1000, "best_run_wave": 1000}
	for id: StringName in TIER_2_CARDS:
		assert_eq(data.card(id)["tier"], 2, "%s is tier 2" % id)
		assert_false(data.card_ids(0).has(id), "%s is not in the tier 0 daily" % id)
		assert_false(data.card_ids(1).has(id), "%s is not in the tier 1 daily" % id)
		assert_false(data.pool(every, 0).has(id), "%s is not in a tier 0 pool" % id)
		assert_false(data.pool(every, 1).has(id), "%s is not in a tier 1 pool" % id)
		assert_true(data.pool({}, 2).has(id), "%s is in the tier 2 base pool" % id)
		assert_true(data.card_ids(2).has(id), "%s is in the tier 2 daily" % id)
	var tower_card: Dictionary = data.card(&"tower_scarecrow")
	assert_eq(tower_card["kind"], &"tower")
	assert_eq(tower_card["tower"], &"scarecrow")
	assert_eq(tower_card["name"], "Scarecrow")
	assert_eq(tower_card["text"], "You can build Scarecrows for the rest of the run.")
	assert_true(tower_card["once"])
	assert_eq(tower_card["unlock"], {})
	assert_eq(tower_card["effects"].size(), 1)
	assert_eq(tower_card["effects"][0]["type"], "add_tower")
	assert_eq(tower_card["effects"][0]["tower"], "scarecrow")
	var perk: Dictionary = data.card(&"big_hat")
	assert_eq(perk["kind"], &"perk")
	assert_eq(perk["tower"], &"scarecrow")
	assert_eq(perk["name"], "Big Hat")
	assert_eq(perk["text"], "Scarecrows reach 0.5 tiles further.")
	assert_true(perk["once"])
	assert_eq(perk["unlock"], {}, "a base perk")
	assert_eq(perk["effects"].size(), 1)
	assert_eq([perk["effects"][0]["type"], perk["effects"][0]["stat"], perk["effects"][0]["amount"]], ["tower_add", "reach", 50])
	var ids: Array[StringName] = data.card_ids(2)
	assert_eq(ids.find(&"tower_scarecrow"), ids.find(&"tower_bramble_cottage") + 1, "after the Bramble Cottage card")
	assert_eq(ids.find(&"big_hat"), ids.find(&"thorn_tips") + 1, "after Thorn Tips")
	for id: StringName in TIER_3_CARDS + TIER_4_CARDS:
		assert_false(ids.has(id), "%s is not in the tier 2 daily" % id)


func test_tier_3_adds_the_snow_fort_card_and_perk() -> void:
	var data: RunData = RunData.from_data(_files(), catalog)
	assert_eq(data.card_ids(3).size(), 40, "tier 3 does not see the Moth Lantern cards")
	assert_eq(data.card_ids(2).size(), 38, "tier 2 keeps its 38")
	assert_eq(data.pool({}, 3).size(), 28)
	assert_eq(data.pool({}, 2).size(), 26, "tier 2 keeps its 26")
	var every: Dictionary = {"stars": 1000, "best_run_wave": 1000}
	for id: StringName in TIER_3_CARDS:
		assert_eq(data.card(id)["tier"], 3, "%s is tier 3" % id)
		for tier: int in 3:
			assert_false(data.card_ids(tier).has(id), "%s is not in the tier %d daily" % [id, tier])
			assert_false(data.pool(every, tier).has(id), "%s is not in a tier %d pool" % [id, tier])
		assert_true(data.pool({}, 3).has(id), "%s is in the tier 3 base pool" % id)
		assert_true(data.card_ids(3).has(id), "%s is in the tier 3 daily" % id)
	var tower_card: Dictionary = data.card(&"tower_snow_fort")
	assert_eq(tower_card["kind"], &"tower")
	assert_eq(tower_card["tower"], &"snow_fort")
	assert_eq(tower_card["name"], "Snow Fort")
	assert_eq(tower_card["text"], "You can build Snow Forts for the rest of the run.")
	assert_true(tower_card["once"])
	assert_eq(tower_card["unlock"], {})
	assert_eq(tower_card["effects"].size(), 1)
	assert_eq(tower_card["effects"][0]["type"], "add_tower")
	assert_eq(tower_card["effects"][0]["tower"], "snow_fort")
	var perk: Dictionary = data.card(&"packed_snow")
	assert_eq(perk["kind"], &"perk")
	assert_eq(perk["tower"], &"snow_fort")
	assert_eq(perk["name"], "Packed Snow")
	assert_eq(perk["text"], "Snow Forts deal 6 more damage per hit.")
	assert_true(perk["once"])
	assert_eq(perk["unlock"], {}, "a base perk")
	assert_eq(perk["effects"].size(), 1)
	assert_eq([perk["effects"][0]["type"], perk["effects"][0]["stat"], perk["effects"][0]["amount"]], ["tower_add", "damage", 6])
	var ids: Array[StringName] = data.card_ids(3)
	assert_eq(ids.find(&"tower_snow_fort"), ids.find(&"tower_scarecrow") + 1, "after the Scarecrow card")
	assert_eq(ids.find(&"packed_snow"), ids.find(&"big_hat") + 1, "after Big Hat")
	for id: StringName in TIER_4_CARDS:
		assert_false(ids.has(id), "%s is not in the tier 3 daily" % id)


func test_tier_4_adds_the_moth_lantern_card_and_perk() -> void:
	var data: RunData = RunData.from_data(_files(), catalog)
	assert_eq(data.card_ids(4).size(), 42)
	assert_eq(data.card_ids(3).size(), 40, "tier 3 keeps its 40")
	assert_eq(data.card_ids().size(), 34, "tier 0 keeps its 34")
	assert_eq(data.pool({}, 4).size(), 30)
	assert_eq(data.pool({}, 3).size(), 28, "tier 3 keeps its 28")
	var every: Dictionary = {"stars": 1000, "best_run_wave": 1000}
	for id: StringName in TIER_4_CARDS:
		assert_eq(data.card(id)["tier"], 4, "%s is tier 4" % id)
		for tier: int in 4:
			assert_false(data.card_ids(tier).has(id), "%s is not in the tier %d daily" % [id, tier])
			assert_false(data.pool(every, tier).has(id), "%s is not in a tier %d pool" % [id, tier])
		assert_true(data.pool({}, 4).has(id), "%s is in the tier 4 base pool" % id)
		assert_true(data.card_ids(4).has(id), "%s is in the tier 4 daily" % id)
	var tower_card: Dictionary = data.card(&"tower_moth_lantern")
	assert_eq(tower_card["kind"], &"tower")
	assert_eq(tower_card["tower"], &"moth_lantern")
	assert_eq(tower_card["name"], "Moth Lantern")
	assert_eq(tower_card["text"], "You can build Moth Lanterns for the rest of the run.")
	assert_true(tower_card["once"])
	assert_eq(tower_card["unlock"], {})
	assert_eq(tower_card["effects"].size(), 1)
	assert_eq(tower_card["effects"][0]["type"], "add_tower")
	assert_eq(tower_card["effects"][0]["tower"], "moth_lantern")
	var perk: Dictionary = data.card(&"bright_wick")
	assert_eq(perk["kind"], &"perk")
	assert_eq(perk["tower"], &"moth_lantern")
	assert_eq(perk["name"], "Bright Wick")
	assert_eq(perk["text"], "Moth Lanterns reach 1 tile further.")
	assert_true(perk["once"])
	assert_eq(perk["unlock"], {}, "a base perk")
	assert_eq(perk["effects"].size(), 1)
	assert_eq([perk["effects"][0]["type"], perk["effects"][0]["stat"], perk["effects"][0]["amount"]], ["tower_add", "reach", 100])
	var ids: Array[StringName] = data.card_ids(4)
	assert_eq(ids.find(&"tower_moth_lantern"), ids.find(&"tower_snow_fort") + 1, "after the Snow Fort card")
	assert_eq(ids.find(&"bright_wick"), ids.find(&"packed_snow") + 1, "after Packed Snow")


func test_packed_snow_adds_damage_to_the_snow_fort_only() -> void:
	var data: RunData = RunData.from_data(_files(), catalog)
	var fort: TowerType = catalog.tower(&"snow_fort")
	assert_eq(fort.kind, &"attack")
	assert_true(RunCards.has_stat(fort, "damage"), "a line tower takes a damage perk")
	var effects: Array[Dictionary] = []
	for effect: Dictionary in data.card(&"packed_snow")["effects"]:
		effects.append(effect)
	var base: TowerStats = fort.stats(1, -1)
	var packed: TowerStats = Modifiers.tower_stats(base, &"snow_fort", Modifiers.normalize_all(effects), true)
	assert_eq(packed.damage, base.damage + 6)
	assert_eq(packed.line, base.line, "the line is unchanged")
	var late: TowerStats = Modifiers.tower_stats(fort.stats(3, 0), &"snow_fort", Modifiers.normalize_all(effects), true)
	assert_eq(late.damage, fort.stats(3, 0).damage + 6, "a path tier gets it too (tier 3 of a path)")
	var plain: TowerStats = catalog.tower(&"scarecrow").stats(1, -1)
	var other: TowerStats = Modifiers.tower_stats(plain, &"scarecrow", Modifiers.normalize_all(effects), true)
	assert_eq(other.damage, plain.damage, "it names the Snow Fort only")


func test_bright_wick_adds_reach_to_the_moth_lantern_only() -> void:
	var data: RunData = RunData.from_data(_files(), catalog)
	var lantern: TowerType = catalog.tower(&"moth_lantern")
	assert_eq(lantern.kind, &"attack")
	assert_true(RunCards.has_stat(lantern, "reach"), "a lure tower takes a reach perk")
	var effects: Array[Dictionary] = []
	for effect: Dictionary in data.card(&"bright_wick")["effects"]:
		effects.append(effect)
	var normal: Array[Dictionary] = Modifiers.normalize_all(effects)
	var base: TowerStats = lantern.stats(1, -1)
	var lit: TowerStats = Modifiers.tower_stats(base, &"moth_lantern", normal, true)
	assert_eq(lit.reach, base.reach + 100)
	assert_eq(lit.reach, 400)
	assert_eq(lit.lure_ms, base.lure_ms, "the lure time is unchanged")
	assert_eq(lit.damage, base.damage, "the damage is unchanged")
	assert_eq(Modifiers.tower_stats(lantern.stats(2, -1), &"moth_lantern", normal, true).reach, 450, "tier 2")
	assert_eq(Modifiers.tower_stats(lantern.stats(3, 0), &"moth_lantern", normal, true).reach, 550, "Beacon Lantern")
	assert_eq(Modifiers.tower_stats(lantern.stats(3, 1), &"moth_lantern", normal, true).reach, 450, "Lantern Garland")
	var plain: TowerStats = catalog.tower(&"scarecrow").stats(1, -1)
	var other: TowerStats = Modifiers.tower_stats(plain, &"scarecrow", normal, true)
	assert_eq(other.reach, plain.reach, "it names the Moth Lantern only")


func test_the_big_hat_adds_half_a_tile_of_reach_to_the_scarecrow() -> void:
	var data: RunData = RunData.from_data(_files(), catalog)
	var scarecrow: TowerType = catalog.tower(&"scarecrow")
	var bramble: TowerType = catalog.tower(&"bramble_cottage")
	assert_eq(scarecrow.kind, &"fright")
	var effects: Array[Dictionary] = []
	for effect: Dictionary in data.card(&"big_hat")["effects"]:
		effects.append(effect)
	var base: TowerStats = scarecrow.stats(1, -1)
	var hatted: TowerStats = Modifiers.tower_stats(base, &"scarecrow", Modifiers.normalize_all(effects), true)
	assert_eq(hatted.reach, base.reach + 50)
	assert_eq(hatted.fright_pct, base.fright_pct, "the fright itself is unchanged")
	var plain: TowerStats = bramble.stats(1, -1)
	var other: TowerStats = Modifiers.tower_stats(plain, &"bramble_cottage", Modifiers.normalize_all(effects), true)
	assert_eq(other.reach, plain.reach, "it names the Scarecrow only")


func test_the_real_tier_2_in_run_json() -> void:
	var data: RunData = RunData.from_data(_files(), catalog)
	assert_true(data.tiers.size() >= 2)
	assert_eq(data.tiers[1]["level"], &"r6_l6")
	assert_eq(data.tiers[1]["towers"], [&"scarecrow"])
	assert_eq(data.tiers[1]["creatures"], TIER_2_CREATURES)
	assert_eq(data.tiers[1]["bosses"], [&"old_hayrick"])
	assert_eq(data.tiers[1]["grid"], "X")
	assert_eq(data.bands[1].find(&"sleepyhead"), data.bands[1].find(&"mossbud") + 1, "Sleepyhead sits after Mossbud in band 2 (RULES 14.3)")
	assert_true(data.bands[2].has(&"gleamer"), "band 3 lists Gleamer")
	for b: int in [0, 3, 4, 5]:
		assert_false(data.bands[b].has(&"gleamer") or data.bands[b].has(&"sleepyhead"), "band %d adds no tier 2 creature" % (b + 1))
	assert_eq(data.boss_ids(2).size(), 6)
	assert_true(data.boss_ids(2).has(&"old_hayrick"))
	assert_false(data.boss_ids(1).has(&"old_hayrick"))
	assert_false(data.boss_ids(0).has(&"old_hayrick"))


func test_the_real_tier_3_in_run_json() -> void:
	var data: RunData = RunData.from_data(_files(), catalog)
	assert_true(data.tiers.size() >= 3)
	assert_eq(data.tiers[2]["level"], &"r7_l6")
	assert_eq(data.tiers[2]["towers"], [&"snow_fort"])
	assert_eq(data.tiers[2]["creatures"], TIER_3_CREATURES)
	assert_eq(data.tiers[2]["bosses"], [&"snowsnore"])
	assert_eq(data.tiers[2]["grid"], "^v<>")
	assert_true(data.bands[2].has(&"snowroller"), "band 3 lists Snowroller")
	assert_eq(data.bands[2].find(&"snowroller"), data.bands[2].find(&"gleamer") + 1, "after Gleamer (RULES 14.3)")
	assert_true(data.bands[3].has(&"yawner"), "band 4 lists Yawner")
	assert_eq(data.bands[3].find(&"yawner"), data.bands[3].find(&"mistwisp") + 1, "after Mistwisp")
	for b: int in [0, 1, 4, 5]:
		assert_false(data.bands[b].has(&"snowroller") or data.bands[b].has(&"yawner"), "band %d adds no tier 3 creature" % (b + 1))
	assert_false(data.bands[3].has(&"snowroller") or data.bands[2].has(&"yawner"), "each in its own band only")
	assert_eq(data.boss_ids(3).size(), 7)
	assert_true(data.boss_ids(3).has(&"snowsnore"))
	assert_false(data.boss_ids(2).has(&"snowsnore"))
	assert_false(data.boss_ids(0).has(&"snowsnore"))


func test_the_real_tier_4_in_run_json() -> void:
	var data: RunData = RunData.from_data(_files(), catalog)
	assert_eq(data.tiers.size(), 4)
	assert_eq(data.tiers[3]["level"], &"r8_l6")
	assert_eq(data.tiers[3]["towers"], [&"moth_lantern"])
	assert_eq(data.tiers[3]["creatures"], TIER_4_CREATURES)
	assert_eq(data.tiers[3]["bosses"], [&"glimmertoad"])
	assert_eq(data.tiers[3]["grid"], "PQ")
	assert_true(data.bands[2].has(&"blinker"), "band 3 lists Blinker")
	assert_eq(data.bands[2].find(&"blinker"), data.bands[2].find(&"snowroller") + 1, "after Snowroller (RULES 14.3)")
	assert_true(data.bands[4].has(&"hootling"), "band 5 lists Hootling")
	assert_eq(data.bands[4].find(&"hootling"), data.bands[4].find(&"gatecrasher") + 1, "after Gatecrasher")
	for b: int in [0, 1, 3, 5]:
		assert_false(data.bands[b].has(&"blinker") or data.bands[b].has(&"hootling"), "band %d adds no tier 4 creature" % (b + 1))
	assert_false(data.bands[4].has(&"blinker") or data.bands[2].has(&"hootling"), "each in its own band only")
	assert_eq(data.boss_ids(4).size(), 8)
	assert_true(data.boss_ids(4).has(&"glimmertoad"))
	assert_false(data.boss_ids(3).has(&"glimmertoad"))
	assert_false(data.boss_ids(0).has(&"glimmertoad"))


func test_the_real_tier_1_in_run_json() -> void:
	var data: RunData = RunData.from_data(_files(), catalog)
	assert_true(data.tiers.size() >= 2)
	assert_eq(data.tiers[0]["level"], &"r5_l6")
	assert_eq(data.tiers[0]["towers"], [&"bramble_cottage"])
	assert_eq(data.tiers[0]["creatures"], [&"mossbud", &"mistwisp"])
	assert_eq(data.tiers[0]["bosses"], [&"burrowbelly"])
	assert_eq(data.tiers[0]["grid"], "T")
	assert_true(data.bands[1].has(&"mossbud"), "band 2 gains Mossbud (RULES 14.3)")
	assert_true(data.bands[3].has(&"mistwisp"), "band 4 gains Mistwisp")
	for b: int in [0, 2, 4, 5]:
		assert_false(data.bands[b].has(&"mossbud") or data.bands[b].has(&"mistwisp"), "band %d adds no tier 1 creature" % (b + 1))
	assert_eq(data.boss_ids(0).size(), 4)
	assert_eq(data.boss_ids(1).size(), 5)
	assert_true(data.boss_ids(1).has(&"burrowbelly"))


func test_each_unlock_opens_at_its_number_and_not_before() -> void:
	var data: RunData = RunData.from_data(_files(), catalog)
	for want: Array in CARDS:
		if want[4] == "":
			continue
		var id: StringName = StringName(want[0])
		assert_false(data.pool({StringName(want[4]): want[5] - 1}).has(id), "%s before %d" % [want[0], want[5]])
		assert_true(data.pool({StringName(want[4]): want[5]}).has(id), "%s at %d" % [want[0], want[5]])
		assert_true(data.pool({StringName(want[4]): want[5] + 100}).has(id), "%s past %d" % [want[0], want[5]])


func test_unlocks_are_sidegrades_with_a_cost() -> void:
	# RULES 14.6: every unlockable perk carries a cost, so it adds variety and no raw power.
	var data: RunData = RunData.from_data(_files(), catalog)
	for want: Array in CARDS:
		if want[4] == "" or want[1] != "perk":
			continue
		var card: Dictionary = data.card(StringName(want[0]))
		assert_eq(card["effects"].size(), 2, "%s gives and takes" % want[0])


func test_card_words_follow_the_writing_rules() -> void:
	var data: RunData = RunData.from_data(_files(), catalog)
	for id: StringName in data.card_ids():
		var card: Dictionary = data.card(id)
		for field: String in ["name", "text"]:
			var text: String = card[field]
			assert_false(text.contains("--"), "%s %s has a double hyphen" % [id, field])
			assert_false(text.contains(char(8212)), "%s %s has an em dash" % [id, field])
			assert_false(text.begins_with(" ") or text.ends_with(" "), "%s %s has stray spaces" % [id, field])
		assert_true(card["text"].ends_with("."), "%s ends its text with a full stop" % id)


func test_risk_cards_name_a_reward_and_gate_the_next_wave_only() -> void:
	var data: RunData = RunData.from_data(_files(), catalog)
	var amounts: Dictionary = {
		&"crowded_night": 100, &"thick_hides": 120, &"hurry_night": 60, &"gateless_night": 60, &"flock": 80,
		&"moonlit_wager": 250, &"crasher_escort": 150, &"pip_parade": 120,
	}
	for id: StringName in amounts.keys():
		var card: Dictionary = data.card(id)
		var rewards: Array = []
		for effect: Dictionary in card["effects"]:
			if effect["type"] == "reward_gold":
				rewards.append(effect["amount"])
		assert_eq(rewards, [amounts[id]], "reward of %s" % id)
		assert_true(card["text"].contains(str(amounts[id])), "%s says its reward" % id)


## The six cards TUNING_RUNS 3.3 changes, pinned word for word.
func test_the_run_tuning_cards_are_as_set_in_g3() -> void:
	var data: RunData = RunData.from_data(_files(), catalog)
	assert_eq(data.card(&"tea_break")["text"], "Gain 5 lives, but never more than you started with.")
	assert_eq(data.card(&"tea_break")["effects"][0]["amount"], 5)
	var pebbles: Dictionary = data.card(&"sharp_pebbles")
	assert_eq(pebbles["text"], "Sling Posts deal 1 more damage per hit.")
	assert_eq(pebbles["effects"].size(), 1)
	assert_eq([pebbles["effects"][0]["stat"], pebbles["effects"][0]["amount"]], ["damage", 1])
	var hurry: Dictionary = data.card(&"hurry_night")
	assert_eq(hurry["text"], "Next wave: creatures move 50% faster. Reward: 60 gold, more later.")
	assert_eq([hurry["effects"][0]["type"], hurry["effects"][0]["pct"]], ["speed_pct", 150])
	assert_eq(data.card(&"gateless_night")["text"], "Next wave: your gates stand open. Reward: 60 gold, more later.")
	var parade: Dictionary = data.card(&"pip_parade")
	assert_eq(parade["text"], "Next wave: 16 more Pips. Reward: 120 gold, more in later waves.")
	var group: Dictionary = parade["effects"][0]
	assert_eq([group["type"], group["enemy"], group["count"], group["entrance"], group["at_ms"], group["every_ms"], group["after_last"]], ["add_group", "pip", 16, 1, 1000, 300, false])
	var volley: Dictionary = data.card(&"volley")
	assert_eq(volley["text"], "Longbow Lofts hit 1 more target, but deal 15% less damage.")
	assert_eq([volley["effects"][0]["stat"], volley["effects"][0]["amount"]], ["targets", 1])
	assert_eq([volley["effects"][1]["type"], volley["effects"][1]["stat"], volley["effects"][1]["pct"]], ["tower_pct", "damage", 85])


func test_every_real_card_is_accepted_by_a_battle() -> void:
	var data: RunData = RunData.from_data(_playable_files(), catalog)
	var level: LevelData = MapAssembler.assemble(1, data, catalog)
	assert_not_null(level)
	for id: StringName in data.card_ids(data.tiers.size()):
		var card: Dictionary = data.card(id)
		var battle: Battle = Battle.create(level, catalog, false, [])
		var effects: Array[Dictionary] = card["effects"]
		assert_eq(battle.add_effects(effects, card["kind"] == &"risk"), Battle.DONE, String(id))


## Every real file: run plan, cards, segments and packs.
func _real_files() -> Dictionary:
	var files: Dictionary = {
		"runs/run.json": _read(RUN_PATH, 16384), "cards/cards.json": _read(CARDS_PATH, 262144),
		"segments/index.json": _read(SEGMENT_DIR + "index.json", 16384),
		"segments/packs.json": _read(SEGMENT_DIR + "packs.json", 262144),
	}
	var index: Variant = files["segments/index.json"]
	if typeof(index) == TYPE_DICTIONARY and typeof((index as Dictionary).get("segments", null)) == TYPE_ARRAY:
		for id: Variant in (index as Dictionary)["segments"]:
			if DataCheck.is_id(id):
				files["segments/%s.json" % id] = _read(SEGMENT_DIR + "%s.json" % id, 16384)
	return files


func test_the_real_segments_and_packs_pass() -> void:
	var files: Dictionary = _real_files()
	var found: PackedStringArray = RunData.check(files, catalog)
	assert_eq(found, PackedStringArray(), "
".join(found))
	var data: RunData = RunData.from_data(files, catalog)
	assert_not_null(data)
	if data == null:
		return
	# Every stack of the real segments is a valid map (2.9), and a run from a seed builds.
	var packs: Array[StringName] = []
	for band: int in range(1, 7):
		packs.append(data.packs_of(band)[0]["id"])
	var stacks: int = 0
	for top: Dictionary in data.segments_of(&"top"):
		for middle: Dictionary in data.segments_under(top["id"]):
			for bottom: Dictionary in data.segments_under(middle["id"]):
				var level: LevelData = MapAssembler.build(data, catalog, top["id"], middle["id"], bottom["id"], packs)
				assert_not_null(level, "%s / %s / %s" % [top["id"], middle["id"], bottom["id"]])
				stacks += 1
	assert_true(stacks > 0, "the real segments make at least one stack")
	for run_seed: int in 50:
		assert_not_null(MapAssembler.assemble(run_seed, data, catalog), "seed %d" % run_seed)


## Real runs start from the real pools, and the real pools can always fill a draft.
func test_real_runs_start_with_the_real_pools() -> void:
	var data: RunData = RunData.from_data(_real_files(), catalog)
	assert_not_null(data)
	if data == null:
		return
	for id: StringName in [&"gold_purse", &"tea_break"]:
		assert_false(bool(data.card(id)["once"]), "%s can be taken again" % id)
		assert_eq(data.card(id)["kind"], &"economy")
		assert_true(data.pool({}).has(id), "%s is in the base pool" % id)
	for run_seed: int in [0, 1, 2, 12345, 4294967295]:
		var s: RunSession = RunSession.start(run_seed, "", false, data.pool({}), data, catalog)
		assert_not_null(s, "seed %d, base pool" % run_seed)
		assert_not_null(RunSession.start(run_seed, "", true, data.card_ids(), data, catalog), "seed %d, every card, Relaxed" % run_seed)
	var day: String = "2026-10-24"
	var daily: RunSession = RunSession.start(RunSeeds.daily_seed(day), day, false, data.card_ids(), data, catalog)
	assert_not_null(daily)
	if daily != null:
		assert_eq(daily.card(&"gold_purse")["kind"], &"economy")
		assert_eq(daily.drafts_owed(), 0)


## TUNING_RUNS 1.2: each band 6 pack's boss wave sets its own strength, and no other wave does.
func test_the_real_boss_waves_set_the_strengths_of_g3() -> void:
	var data: RunData = RunData.from_data(_real_files(), catalog)
	assert_not_null(data)
	if data == null:
		return
	var want: Dictionary = {
		&"b6_grumble_hill": 290, &"b6_grumble_march": 270, &"b6_iron_road": 150, &"b6_iron_gate": 150,
		&"b6_moon_rise": 150, &"b6_moon_tide": 140, &"b6_tusk_charge": 200, &"b6_tusk_night": 180,
	}
	var seen: int = 0
	for pack: Dictionary in data.packs:
		for k: int in 3:
			var wave: Dictionary = pack["waves"][k]
			if pack["band"] == 6 and k == 2 and pack["tier"] > 0:
				# The level designer tunes the bosses of regions 5 to 8 (RULES 14.3).
				assert_true(wave.has("strength"), "boss wave of %s sets a strength" % pack["id"])
			elif pack["band"] == 6 and k == 2:
				assert_eq(wave["strength"], want.get(pack["id"], -1), "boss wave of %s" % pack["id"])
				seen += 1
			else:
				assert_false(wave.has("strength"), "%s wave %d has no strength" % [pack["id"], k + 1])
	assert_eq(seen, want.size())


## A real run's wave 18 takes the strength of the band 6 pack its seed picked.
func test_a_real_runs_wave_18_takes_its_packs_strength() -> void:
	var data: RunData = RunData.from_data(_real_files(), catalog)
	assert_not_null(data)
	if data == null:
		return
	for run_seed: int in [1, 2, 3, 12345, 20261023]:
		var level: LevelData = MapAssembler.assemble(run_seed, data, catalog)
		var picks: Dictionary = MapAssembler.plan(run_seed, data)
		var pack: Dictionary = {}
		for item: Dictionary in data.packs:
			if item["id"] == picks["packs"][5]:
				pack = item
		assert_eq(level.waves[17].strength, pack["waves"][2]["strength"], "seed %d" % run_seed)
		assert_eq(level.waves[16].strength, 260, "wave 17 keeps the step")


## A tier 1 run with the real plan and cards (and tier 1 stand-in segments and packs) starts from
## the tier 1 pool, and its tier is saved.
func test_a_tier_1_run_starts_from_the_tier_1_pool() -> void:
	var data: RunData = RunData.from_data(_playable_files(), catalog)
	assert_not_null(data)
	if data == null:
		return
	var pool: Array[StringName] = data.pool({}, 1)
	assert_true(pool.has(&"tower_bramble_cottage") and pool.has(&"thorn_tips"))
	for run_seed: int in range(1, 41):
		var s: RunSession = RunSession.start(run_seed, "", false, pool, data, catalog, 1)
		assert_not_null(s, "seed %d at tier 1" % run_seed)
		if s == null:
			return
		assert_eq(s.tier, 1)
		assert_eq(s.to_data()["tier"], 1)
	assert_not_null(RunSession.start(1, "", false, data.pool({}, 0), data, catalog), "a tier 0 pool at tier 0")
	assert_null(RunSession.start(1, "", false, pool, data, catalog, 0), "a tier 1 pool is refused at tier 0")
	assert_false(MapAssembler.plan(7, data, 1).is_empty())


# What each tier meets, over the real files (the level designer's real packs and segments)

const Player: GDScript = preload("res://tests/run/fixtures/run_player.gd")
## Everything of tier 2 a tier 0 or tier 1 player must never meet: the creatures and the boss.
const TIER_2_UNITS: Array = [&"gleamer", &"sleepyhead", &"old_hayrick"]
## Everything of tier 3 a player of a lower tier must never meet.
const TIER_3_UNITS: Array = [&"snowroller", &"yawner", &"snowsnore"]
## Everything of tier 4 a player of a lower tier must never meet.
const TIER_4_UNITS: Array = [&"blinker", &"hootling", &"glimmertoad"]


## Every creature type the waves of a level send, as {id: true}.
func _creatures_in(level: LevelData) -> Dictionary:
	var out: Dictionary = {}
	for wave: WaveData in level.waves:
		for group: WaveGroup in wave.groups:
			out[group.enemy] = true
	return out


## The creatures seen over the runs of seeds 1 to count at a tier.
func _seen_at_tier(data: RunData, tier: int, count: int) -> Dictionary:
	var seen: Dictionary = {}
	for run_seed: int in range(1, count + 1):
		var level: LevelData = MapAssembler.assemble(run_seed, data, catalog, tier)
		assert_not_null(level, "seed %d at tier %d" % [run_seed, tier])
		if level != null:
			seen.merge(_creatures_in(level))
	return seen


func test_a_tier_2_player_meets_the_tier_2_creatures_and_the_others_do_not() -> void:
	var data: RunData = RunData.from_data(_real_files(), catalog)
	assert_not_null(data)
	if data == null:
		return
	for tier: int in 2:
		var seen: Dictionary = _seen_at_tier(data, tier, 120)
		for id: StringName in TIER_2_UNITS:
			assert_false(seen.has(id), "%s never shows to a tier %d player" % [id, tier])
	var seen_two: Dictionary = _seen_at_tier(data, 2, 120)
	for id: StringName in TIER_2_UNITS:
		assert_true(seen_two.has(id), "%s shows to a tier 2 player" % id)
	# The tier 1 things are still there for tier 2.
	for id: StringName in [&"mossbud", &"mistwisp", &"burrowbelly"]:
		assert_true(seen_two.has(id), "%s still shows at tier 2" % id)


func test_a_tier_3_player_meets_the_tier_3_creatures_and_the_others_do_not() -> void:
	var data: RunData = RunData.from_data(_real_files(), catalog)
	assert_not_null(data)
	if data == null:
		return
	for tier: int in 3:
		var seen: Dictionary = _seen_at_tier(data, tier, 120)
		for id: StringName in TIER_3_UNITS:
			assert_false(seen.has(id), "%s never shows to a tier %d player" % [id, tier])
	var seen_three: Dictionary = _seen_at_tier(data, 3, 160)
	for id: StringName in TIER_3_UNITS:
		assert_true(seen_three.has(id), "%s shows to a tier 3 player" % id)
	# The older tiers' things are still there for tier 3.
	for id: StringName in TIER_2_UNITS + [&"mossbud", &"mistwisp", &"burrowbelly"]:
		assert_true(seen_three.has(id), "%s still shows at tier 3" % id)


func test_a_tier_4_player_meets_the_tier_4_creatures_and_the_others_do_not() -> void:
	var data: RunData = RunData.from_data(_real_files(), catalog)
	assert_not_null(data)
	if data == null:
		return
	for tier: int in 4:
		var seen: Dictionary = _seen_at_tier(data, tier, 120)
		for id: StringName in TIER_4_UNITS:
			assert_false(seen.has(id), "%s never shows to a tier %d player" % [id, tier])
	var seen_four: Dictionary = _seen_at_tier(data, 4, 200)
	for id: StringName in TIER_4_UNITS:
		assert_true(seen_four.has(id), "%s shows to a tier 4 player" % id)
	# The older tiers things are still there for tier 4.
	for id: StringName in TIER_3_UNITS + TIER_2_UNITS + [&"mossbud", &"mistwisp", &"burrowbelly"]:
		assert_true(seen_four.has(id), "%s still shows at tier 4" % id)


func test_a_tier_2_plan_can_end_on_old_hayrick_and_a_tier_1_plan_cannot() -> void:
	var data: RunData = RunData.from_data(_real_files(), catalog)
	assert_not_null(data)
	if data == null:
		return
	var bosses: Dictionary = {}
	for run_seed: int in range(1, 201):
		assert_ne(MapAssembler.plan(run_seed, data, 1)["boss"], &"old_hayrick", "seed %d at tier 1" % run_seed)
		bosses[MapAssembler.plan(run_seed, data, 2)["boss"]] = true
	assert_true(bosses.has(&"old_hayrick"))
	assert_eq(bosses.size(), 6, "all six bosses at tier 2")


func test_a_tier_3_plan_can_end_on_snowsnore_and_a_tier_2_plan_cannot() -> void:
	var data: RunData = RunData.from_data(_real_files(), catalog)
	assert_not_null(data)
	if data == null:
		return
	var bosses: Dictionary = {}
	for run_seed: int in range(1, 241):
		assert_ne(MapAssembler.plan(run_seed, data, 2)["boss"], &"snowsnore", "seed %d at tier 2" % run_seed)
		bosses[MapAssembler.plan(run_seed, data, 3)["boss"]] = true
	assert_true(bosses.has(&"snowsnore"))
	assert_eq(bosses.size(), 7, "all seven bosses at tier 3")


func test_a_tier_4_plan_can_end_on_glimmertoad_and_a_tier_3_plan_cannot() -> void:
	var data: RunData = RunData.from_data(_real_files(), catalog)
	assert_not_null(data)
	if data == null:
		return
	var bosses: Dictionary = {}
	for run_seed: int in range(1, 281):
		assert_ne(MapAssembler.plan(run_seed, data, 3)["boss"], &"glimmertoad", "seed %d at tier 3" % run_seed)
		bosses[MapAssembler.plan(run_seed, data, 4)["boss"]] = true
	assert_true(bosses.has(&"glimmertoad"))
	assert_eq(bosses.size(), 8, "all eight bosses at tier 4")


## The cards offered over the first drafts of a few runs at a tier.
func _offers_seen(data: RunData, tier: int, seeds: int) -> Dictionary:
	var seen: Dictionary = {}
	for run_seed: int in range(1, seeds + 1):
		var s: RunSession = RunSession.start(run_seed, "", false, data.pool({}, tier), data, catalog, tier)
		assert_not_null(s)
		if s == null:
			continue
		var player: RefCounted = Player.new(run_seed, 0, true)
		player.rich = true
		var guard: int = 0
		while s.battle.waves_started < 5 and guard < 200000:
			for id: StringName in s.offers():
				seen[id] = true
			if not player.advance(s):
				break
			guard += 1
	return seen


func test_a_tier_2_player_is_offered_the_scarecrow_cards_and_a_tier_1_player_is_not() -> void:
	var data: RunData = RunData.from_data(_real_files(), catalog)
	assert_not_null(data)
	if data == null:
		return
	var tier_one: Dictionary = _offers_seen(data, 1, 10)
	var tier_two: Dictionary = _offers_seen(data, 2, 10)
	for id: StringName in TIER_2_CARDS:
		assert_false(tier_one.has(id), "%s is never offered at tier 1" % id)
	assert_true(tier_one.has(&"tower_bramble_cottage"), "tier 1 still offers the Bramble Cottage")
	assert_true(tier_two.has(&"tower_scarecrow"), "tier 2 offers the Scarecrow")
	assert_true(tier_two.has(&"big_hat"), "tier 2 offers the Big Hat")
	assert_true(tier_two.has(&"tower_bramble_cottage"), "and keeps the Bramble Cottage")
	for id: StringName in TIER_3_CARDS:
		assert_false(tier_two.has(id), "%s is never offered at tier 2" % id)


func test_a_tier_3_player_is_offered_the_snow_fort_cards_and_a_tier_2_player_is_not() -> void:
	var data: RunData = RunData.from_data(_real_files(), catalog)
	assert_not_null(data)
	if data == null:
		return
	var tier_two: Dictionary = _offers_seen(data, 2, 10)
	var tier_three: Dictionary = _offers_seen(data, 3, 12)
	for id: StringName in TIER_3_CARDS:
		assert_false(tier_two.has(id), "%s is never offered at tier 2" % id)
		assert_true(tier_three.has(id), "%s is offered at tier 3" % id)
	for id: StringName in TIER_2_CARDS + TIER_1_CARDS:
		assert_true(tier_three.has(id), "tier 3 still offers %s" % id)


func test_a_tier_4_player_is_offered_the_moth_lantern_cards_and_a_tier_3_player_is_not() -> void:
	var data: RunData = RunData.from_data(_real_files(), catalog)
	assert_not_null(data)
	if data == null:
		return
	var tier_three: Dictionary = _offers_seen(data, 3, 10)
	var tier_four: Dictionary = _offers_seen(data, 4, 30)
	for id: StringName in TIER_4_CARDS:
		assert_false(tier_three.has(id), "%s is never offered at tier 3" % id)
		assert_true(tier_four.has(id), "%s is offered at tier 4" % id)
	for id: StringName in TIER_3_CARDS + TIER_2_CARDS + TIER_1_CARDS:
		assert_true(tier_four.has(id), "tier 4 still offers %s" % id)


func test_a_tier_2_run_starts_from_the_tier_2_pool() -> void:
	var data: RunData = RunData.from_data(_real_files(), catalog)
	assert_not_null(data)
	if data == null:
		return
	var pool: Array[StringName] = data.pool({}, 2)
	for run_seed: int in range(1, 21):
		var s: RunSession = RunSession.start(run_seed, "", false, pool, data, catalog, 2)
		assert_not_null(s, "seed %d at tier 2" % run_seed)
		if s == null:
			return
		assert_eq(s.tier, 2)
		assert_eq(s.to_data()["tier"], 2)
	assert_null(RunSession.start(1, "", false, pool, data, catalog, 1), "a tier 2 pool is refused at tier 1")
	assert_null(RunSession.start(1, "", false, pool, data, catalog, 0), "and at tier 0")
	assert_not_null(RunSession.start(1, "", false, pool, data, catalog, 3), "a smaller pool is fine at tier 3")
	assert_null(RunSession.start(1, "", false, pool, data, catalog, data.tiers.size() + 1), "a tier beyond the data's tiers")


func test_a_tier_3_run_starts_from_the_tier_3_pool() -> void:
	var data: RunData = RunData.from_data(_real_files(), catalog)
	assert_not_null(data)
	if data == null:
		return
	var pool: Array[StringName] = data.pool({}, 3)
	assert_true(pool.has(&"tower_snow_fort") and pool.has(&"packed_snow"))
	for run_seed: int in range(1, 21):
		var s: RunSession = RunSession.start(run_seed, "", false, pool, data, catalog, 3)
		assert_not_null(s, "seed %d at tier 3" % run_seed)
		if s == null:
			return
		assert_eq(s.tier, 3)
		assert_eq(s.to_data()["tier"], 3)
	assert_null(RunSession.start(1, "", false, pool, data, catalog, 2), "a tier 3 pool is refused at tier 2")
	assert_null(RunSession.start(1, "", false, pool, data, catalog, 0), "and at tier 0")


func test_a_tier_4_run_starts_from_the_tier_4_pool() -> void:
	var data: RunData = RunData.from_data(_real_files(), catalog)
	assert_not_null(data)
	if data == null:
		return
	var pool: Array[StringName] = data.pool({}, 4)
	assert_true(pool.has(&"tower_moth_lantern") and pool.has(&"bright_wick"))
	for run_seed: int in range(1, 21):
		var s: RunSession = RunSession.start(run_seed, "", false, pool, data, catalog, 4)
		assert_not_null(s, "seed %d at tier 4" % run_seed)
		if s == null:
			return
		assert_eq(s.tier, 4)
		assert_eq(s.to_data()["tier"], 4)
	assert_null(RunSession.start(1, "", false, pool, data, catalog, 3), "a tier 4 pool is refused at tier 3")
	assert_null(RunSession.start(1, "", false, pool, data, catalog, 0), "and at tier 0")
	assert_null(RunSession.start(1, "", false, pool, data, catalog, data.tiers.size() + 1), "a tier beyond the data tiers")


## The daily follows tiers (docs/ARCHITECTURE.md 14.8): the day's seed and the day's tier give the
## run, so players at the same tier share it, and tier 0 is exactly the daily of regions 1 to 4.
func test_the_daily_follows_its_tier() -> void:
	var data: RunData = RunData.from_data(_real_files(), catalog)
	assert_not_null(data)
	if data == null:
		return
	var tiers: int = data.tiers.size() + 1
	var differs: Array[int] = []
	differs.resize(tiers)
	differs.fill(0)
	for day: String in Golden.days():
		var daily_seed: int = RunSeeds.daily_seed(day)
		var runs: Array[RunSession] = []
		for tier: int in tiers:
			var s: RunSession = RunSession.start(daily_seed, day, false, data.card_ids(tier), data, catalog, tier)
			assert_not_null(s, "%s at tier %d" % [day, tier])
			if s == null:
				return
			assert_true(s.daily)
			assert_eq(s.tier, tier)
			assert_eq(s.day, day)
			var again: RunSession = RunSession.start(daily_seed, day, false, data.card_ids(tier), data, catalog, tier)
			assert_eq(JSON.stringify(again.to_data()), JSON.stringify(s.to_data()), "same inputs, same daily (%s, tier %d)" % [day, tier])
			assert_eq(JSON.stringify(again.battle.level.to_data()), JSON.stringify(s.battle.level.to_data()))
			var pool: Array = s.to_data()["pool"]
			assert_eq(pool.has("tower_bramble_cottage"), tier >= 1, "the Bramble Cottage card from tier 1 (%s)" % day)
			assert_eq(pool.has("tower_scarecrow"), tier >= 2, "the Scarecrow card from tier 2 (%s)" % day)
			assert_eq(pool.has("tower_snow_fort"), tier >= 3, "the Snow Fort card from tier 3 (%s)" % day)
			assert_eq(pool.has("packed_snow"), tier >= 3, "Packed Snow from tier 3 (%s)" % day)
			assert_eq(pool.has("tower_moth_lantern"), tier >= 4, "the Moth Lantern card from tier 4 (%s)" % day)
			assert_eq(pool.has("bright_wick"), tier >= 4, "Bright Wick from tier 4 (%s)" % day)
			runs.append(s)
		var zero: RunSession = RunSession.start(daily_seed, day, false, data.card_ids(), data, catalog)
		assert_eq(JSON.stringify(zero.battle.level.to_data()), JSON.stringify(runs[0].battle.level.to_data()), "the default tier is tier 0")
		assert_eq(JSON.stringify(zero.to_data()), JSON.stringify(runs[0].to_data()))
		for tier: int in range(1, tiers):
			if JSON.stringify(runs[tier].battle.level.to_data()) != JSON.stringify(runs[tier - 1].battle.level.to_data()):
				differs[tier] += 1
		# A daily holds nothing of a higher tier: tier 1 nothing of tiers 2 to 4, and so on up.
		for tier: int in tiers:
			var seen: Dictionary = _creatures_in(runs[tier].battle.level)
			if tier < 4:
				for id: StringName in TIER_4_UNITS:
					assert_false(seen.has(id), "%s in the tier %d daily of %s" % [id, tier, day])
			if tier < 3:
				for id: StringName in TIER_3_UNITS:
					assert_false(seen.has(id), "%s in the tier %d daily of %s" % [id, tier, day])
			if tier < 2:
				for id: StringName in TIER_2_UNITS:
					assert_false(seen.has(id), "%s in the tier %d daily of %s" % [id, tier, day])
			if tier < 1:
				for id: StringName in [&"mossbud", &"mistwisp", &"burrowbelly"]:
					assert_false(seen.has(id), "%s in the tier 0 daily of %s" % [id, day])
	for tier: int in range(1, tiers):
		assert_true(differs[tier] > 0, "a tier %d daily is not always the tier %d daily" % [tier, tier - 1])
