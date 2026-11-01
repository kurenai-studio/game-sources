# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## RunData: the run plan and the cards, good and hostile (docs/ARCHITECTURE.md 2.10, 2.11).
## Segment and pack checks are in test_run_map_files.gd.

const Fx: GDScript = preload("res://tests/run/fixtures/run_fixtures.gd")

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


## Breaks one thing in a copy of the fixtures and expects a problem naming it.
func _expect(label: String, mutate: Callable, needle: String) -> void:
	var files: Dictionary = Fx.files_from_json()
	mutate.call(files)
	var found: PackedStringArray = RunData.check(files, catalog)
	assert_true(found.size() > 0, "%s: no problem found" % label)
	assert_true("\n".join(found).contains(needle), "%s: expected '%s' in:\n%s" % [label, needle, "\n".join(found)])
	assert_null(RunData.from_data(files, catalog), "%s: from_data must refuse" % label)


func _card(files: Dictionary, id: String) -> Dictionary:
	for item: Variant in files["cards/cards.json"]["cards"]:
		if (item as Dictionary)["id"] == id:
			return item
	return {}


# ---- good data ----

func test_the_fixtures_pass_as_plain_values_and_as_parsed_json() -> void:
	assert_eq(RunData.check(Fx.files(), catalog), PackedStringArray())
	assert_eq(RunData.check(Fx.files_from_json(), catalog), PackedStringArray())
	assert_not_null(RunData.from_data(Fx.files_from_json(), catalog))


func test_a_run_has_six_bands() -> void:
	assert_eq(RunData.BANDS, 6)
	assert_eq(RunPacks.BANDS, RunData.BANDS)
	assert_eq(RunPacks.WAVES, 3)


func test_the_run_plan_is_read() -> void:
	var data: RunData = Fx.run_data()
	assert_eq(data.strength_start, 100)
	assert_eq(data.strength_step, 10)
	assert_eq(data.start_gold, 300)
	assert_eq(data.gates, 1)
	assert_eq(data.towers, [&"sling_post"])
	assert_eq(data.rows, {"top": 4, "middle": 5, "bottom": 4})
	assert_eq([data.spots_min, data.spots_max, data.sockets_min, data.sockets_max], [8, 12, 2, 5])
	assert_eq(data.bands.size(), 6)
	assert_eq(data.bands[0], [&"scamp", &"pip"])
	assert_eq(data.bands[5].size(), 0)
	assert_eq(data.weights[&"tower"], 30)
	assert_eq(data.weights[&"risk"], 15)


func test_cards_keep_the_file_order_and_come_back_as_copies() -> void:
	var data: RunData = Fx.run_data()
	var ids: Array[StringName] = data.card_ids()
	assert_eq(ids.size(), 15)
	assert_eq(ids[0], &"tower_pumpkin_catapult")
	assert_eq(ids[ids.size() - 1], &"pip_parade")
	var card: Dictionary = data.card(&"flock")
	assert_eq(card["kind"], &"risk")
	assert_eq(card["tower"], &"")
	assert_eq(card["once"], false)
	assert_eq(card["unlock"], {})
	assert_eq(card["effects"].size(), 2)
	assert_eq(card["effects"][0]["type"], "add_group")
	assert_eq(card["effects"][0]["after_last"], true)
	assert_eq(card["effects"][0]["count"], 8, "a whole number, not a float")
	assert_eq(typeof(card["effects"][0]["count"]), TYPE_INT)
	card["effects"][0]["count"] = 99
	assert_eq(data.card(&"flock")["effects"][0]["count"], 8, "the data is not changed through a copy")
	var perk: Dictionary = data.card(&"sharp_pebbles")
	assert_eq(perk["tower"], &"sling_post")
	assert_eq(data.card(&"twin_pebbles")["unlock"], {"counter": "best_run_wave", "at": 6})
	assert_eq(data.card(&"no_such_card"), {})


func test_the_pool_is_the_base_cards_plus_reached_unlocks() -> void:
	var data: RunData = Fx.run_data()
	var base: Array[StringName] = data.pool({})
	assert_eq(base.size(), 12)
	assert_false(base.has(&"twin_pebbles"))
	assert_false(base.has(&"piggy_bank"))
	assert_false(base.has(&"pip_parade"))
	assert_true(base.has(&"flock"))
	assert_eq(data.pool({&"best_run_wave": 5}), base, "one wave short")
	var six: Array[StringName] = data.pool({&"best_run_wave": 6})
	assert_eq(six.size(), 13)
	assert_eq(six.find(&"twin_pebbles"), 12, "an unlocked card keeps its place in the file order")
	assert_eq(data.pool({&"best_run_wave": 600}), six)
	var stars: Array[StringName] = data.pool({&"stars": 36})
	assert_true(stars.has(&"piggy_bank"))
	assert_false(stars.has(&"pip_parade"))
	assert_false(stars.has(&"twin_pebbles"))
	var all: Array[StringName] = data.pool({&"best_run_wave": 6, &"stars": 72})
	assert_eq(all, data.card_ids(), "every counter reached gives every card")


func test_the_pool_reads_string_keys_and_ignores_junk() -> void:
	var data: RunData = Fx.run_data()
	assert_eq(data.pool({"best_run_wave": 6}), data.pool({&"best_run_wave": 6}))
	assert_eq(data.pool({&"best_run_wave": 6.0}), data.pool({}), "a float is not a counter value")
	assert_eq(data.pool({&"best_run_wave": "6"}), data.pool({}))
	assert_eq(data.pool({&"best_run_wave": -50, &"unknown": 99}), data.pool({}))
	assert_eq(data.pool({3: 6}), data.pool({}))


func test_the_pool_is_a_list_without_repeats_that_the_daily_can_use_whole() -> void:
	var data: RunData = Fx.run_data()
	var ids: Array[StringName] = data.card_ids()
	var seen: Dictionary = {}
	for id: StringName in ids:
		assert_false(seen.has(id), "no repeats")
		seen[id] = true
	assert_eq(data.pool({&"best_run_wave": 99, &"stars": 99, &"twists_cleared": 99}), ids)


func test_a_missing_catalog_is_one_problem() -> void:
	assert_eq(RunData.check(Fx.files(), null).size(), 1)
	assert_null(RunData.from_data(Fx.files(), null))


func test_an_empty_dictionary_reports_every_missing_file() -> void:
	var found: PackedStringArray = RunData.check({}, catalog)
	var text: String = "\n".join(found)
	for file_name: String in ["run.json", "cards.json", "index.json", "packs.json"]:
		assert_true(text.contains(file_name + ": is missing"), file_name)


# ---- run.json ----

func test_run_plan_hostile() -> void:
	_expect("format", func(f: Dictionary) -> void: f["runs/run.json"]["format"] = 2, "run.json: format")
	_expect("extra key", func(f: Dictionary) -> void: f["runs/run.json"]["extra"] = 1, "unknown key extra")
	_expect("missing key", func(f: Dictionary) -> void: f["runs/run.json"].erase("weights"), "weights: is missing")
	_expect("not an object", func(f: Dictionary) -> void: f["runs/run.json"] = [], "run.json")
	_expect("file missing", func(f: Dictionary) -> void: f.erase("runs/run.json"), "run.json: is missing")
	_expect("start too low", func(f: Dictionary) -> void: f["runs/run.json"]["strength_start"] = 49, "strength_start")
	_expect("start too high", func(f: Dictionary) -> void: f["runs/run.json"]["strength_start"] = 1001, "strength_start")
	_expect("step too high", func(f: Dictionary) -> void: f["runs/run.json"]["strength_step"] = 101, "strength_step")
	_expect("step negative", func(f: Dictionary) -> void: f["runs/run.json"]["strength_step"] = -1, "strength_step")
	_expect("wave 17 over 1000", func(f: Dictionary) -> void: f["runs/run.json"]["strength_step"] = 57, "at most 1000")
	_expect("fraction", func(f: Dictionary) -> void: f["runs/run.json"]["strength_start"] = 100.5, "whole number")
	_expect("string number", func(f: Dictionary) -> void: f["runs/run.json"]["strength_start"] = "100", "whole number")
	_expect("huge number", func(f: Dictionary) -> void: f["runs/run.json"]["strength_start"] = 1e30, "whole number")
	_expect("boolean number", func(f: Dictionary) -> void: f["runs/run.json"]["gates"] = true, "whole number")
	_expect("gold not a multiple of 10", func(f: Dictionary) -> void: f["runs/run.json"]["start_gold"] = 305, "multiple of 10")
	_expect("gold too high", func(f: Dictionary) -> void: f["runs/run.json"]["start_gold"] = 100010, "start_gold")
	_expect("gold negative", func(f: Dictionary) -> void: f["runs/run.json"]["start_gold"] = -10, "start_gold")
	_expect("too many gates", func(f: Dictionary) -> void: f["runs/run.json"]["gates"] = 4, "gates")
	_expect("no towers", func(f: Dictionary) -> void: f["runs/run.json"]["towers"] = [], "towers")
	_expect("seven towers", func(f: Dictionary) -> void: f["runs/run.json"]["towers"] = ["a", "b", "c", "d", "e", "f", "g"], "towers")
	_expect("unknown tower", func(f: Dictionary) -> void: f["runs/run.json"]["towers"] = ["moat"], "names no tower")
	_expect("repeated tower", func(f: Dictionary) -> void: f["runs/run.json"]["towers"] = ["sling_post", "sling_post"], "repeats")
	_expect("bad tower id", func(f: Dictionary) -> void: f["runs/run.json"]["towers"] = ["Sling Post"], "must be an id")
	_expect("rows missing key", func(f: Dictionary) -> void: f["runs/run.json"]["rows"].erase("middle"), "middle: is missing")
	_expect("rows extra key", func(f: Dictionary) -> void: f["runs/run.json"]["rows"]["side"] = 1, "unknown key side")
	_expect("rows 12 in one", func(f: Dictionary) -> void: f["runs/run.json"]["rows"]["top"] = 12, "rows.top")
	_expect("rows 0", func(f: Dictionary) -> void: f["runs/run.json"]["rows"]["top"] = 0, "rows.top")
	_expect("rows add to 14", func(f: Dictionary) -> void: f["runs/run.json"]["rows"]["middle"] = 6, "add up to")
	_expect("rows add to 7", func(f: Dictionary) -> void: f["runs/run.json"]["rows"] = {"top": 1, "middle": 2, "bottom": 4}, "add up to")
	_expect("spots reversed", func(f: Dictionary) -> void: f["runs/run.json"]["spots"] = [12, 8], "low end")
	_expect("spots zero", func(f: Dictionary) -> void: f["runs/run.json"]["spots"] = [0, 8], "spots")
	_expect("spots 25", func(f: Dictionary) -> void: f["runs/run.json"]["spots"] = [8, 25], "spots")
	_expect("spots one number", func(f: Dictionary) -> void: f["runs/run.json"]["spots"] = [8], "pair")
	_expect("spots not a list", func(f: Dictionary) -> void: f["runs/run.json"]["spots"] = 8, "pair")
	_expect("sockets reversed", func(f: Dictionary) -> void: f["runs/run.json"]["sockets"] = [3, 2], "low end")
	_expect("sockets 9", func(f: Dictionary) -> void: f["runs/run.json"]["sockets"] = [0, 9], "sockets")
	_expect("sockets negative", func(f: Dictionary) -> void: f["runs/run.json"]["sockets"] = [-1, 5], "sockets")
	_expect("five bands", func(f: Dictionary) -> void: f["runs/run.json"]["bands"].pop_back(), "bands")
	_expect("seven bands", func(f: Dictionary) -> void: f["runs/run.json"]["bands"].append([]), "bands")
	_expect("band not a list", func(f: Dictionary) -> void: f["runs/run.json"]["bands"][2] = "bubbler", "bands[2]")
	_expect("band names no creature", func(f: Dictionary) -> void: f["runs/run.json"]["bands"][5] = ["dragon"], "names no creature")
	_expect("band holds a boss", func(f: Dictionary) -> void: f["runs/run.json"]["bands"][5] = ["grumblesack"], "cannot be listed")
	_expect("band holds puff", func(f: Dictionary) -> void: f["runs/run.json"]["bands"][2].append("puff"), "cannot be listed")
	_expect("creature in two bands", func(f: Dictionary) -> void: f["runs/run.json"]["bands"][5] = ["scamp"], "more than one band")
	_expect("weights missing kind", func(f: Dictionary) -> void: f["runs/run.json"]["weights"].erase("risk"), "risk: is missing")
	_expect("weights extra kind", func(f: Dictionary) -> void: f["runs/run.json"]["weights"]["luck"] = 5, "unknown key luck")
	_expect("weight too high", func(f: Dictionary) -> void: f["runs/run.json"]["weights"]["tower"] = 1001, "weights.tower")
	_expect("weight negative", func(f: Dictionary) -> void: f["runs/run.json"]["weights"]["tower"] = -1, "weights.tower")
	_expect("all weights zero", func(f: Dictionary) -> void: f["runs/run.json"]["weights"] = {"tower": 0, "perk": 0, "gate": 0, "economy": 0, "risk": 0}, "above 0")
	_expect("economy weight zero", func(f: Dictionary) -> void: f["runs/run.json"]["weights"]["economy"] = 0, "weights.economy")


## Wave 18 takes its pack's strength, so only wave 17 is held to 1,000: 100 + 56 * 16 is 996.
func test_only_wave_17_is_limited_by_the_step() -> void:
	var files: Dictionary = Fx.files_from_json()
	files["runs/run.json"]["strength_step"] = 56
	assert_eq(RunData.check(files, catalog), PackedStringArray())
	files["runs/run.json"]["strength_step"] = 57
	assert_true("
".join(RunData.check(files, catalog)).contains("wave 17's strength must be at most 1000"))


func test_one_weight_above_zero_is_enough() -> void:
	var files: Dictionary = Fx.files_from_json()
	files["runs/run.json"]["weights"] = {"tower": 0, "perk": 0, "gate": 0, "economy": 1, "risk": 0}
	assert_eq(RunData.check(files, catalog), PackedStringArray())


func test_problems_name_the_file_and_the_field() -> void:
	var files: Dictionary = Fx.files_from_json()
	files["runs/run.json"]["gates"] = 4
	var found: PackedStringArray = RunData.check(files, catalog)
	assert_eq(found.size(), 1)
	assert_true(found[0].begins_with("run.json: gates: "), found[0])


# ---- cards.json ----

func test_cards_hostile() -> void:
	_expect("file missing", func(f: Dictionary) -> void: f.erase("cards/cards.json"), "cards.json: is missing")
	_expect("not an object", func(f: Dictionary) -> void: f["cards/cards.json"] = "text", "cards.json")
	_expect("format", func(f: Dictionary) -> void: f["cards/cards.json"]["format"] = 0, "cards.json: format")
	_expect("extra top key", func(f: Dictionary) -> void: f["cards/cards.json"]["more"] = [], "unknown key more")
	_expect("no cards", func(f: Dictionary) -> void: f["cards/cards.json"]["cards"] = [], "cards")
	_expect("cards not a list", func(f: Dictionary) -> void: f["cards/cards.json"]["cards"] = {}, "must be an array")
	_expect("card not an object", func(f: Dictionary) -> void: f["cards/cards.json"]["cards"][3] = 5, "cards[3]")
	_expect("duplicate id", func(f: Dictionary) -> void: f["cards/cards.json"]["cards"].append(_card(f, "spare_gate").duplicate(true)), "repeats spare_gate")
	_expect("bad id", func(f: Dictionary) -> void: _card(f, "spare_gate")["id"] = "Spare Gate", "must be an id")
	_expect("id with high character", func(f: Dictionary) -> void: _card(f, "spare_gate")["id"] = "spare" + char(233), "must be an id")
	_expect("unknown kind", func(f: Dictionary) -> void: _card(f, "spare_gate")["kind"] = "luck", "must be tower, perk, gate, economy or risk")
	_expect("kind not text", func(f: Dictionary) -> void: _card(f, "spare_gate")["kind"] = 4, "kind")
	_expect("extra key", func(f: Dictionary) -> void: _card(f, "spare_gate")["rarity"] = 3, "unknown key rarity")
	_expect("missing text", func(f: Dictionary) -> void: _card(f, "spare_gate").erase("text"), "text: is missing")
	_expect("missing effects", func(f: Dictionary) -> void: _card(f, "spare_gate").erase("effects"), "effects: is missing")
	_expect("gate card with a tower", func(f: Dictionary) -> void: _card(f, "spare_gate")["tower"] = "bakery", "unknown key tower")
	_expect("perk without a tower", func(f: Dictionary) -> void: _card(f, "sharp_pebbles").erase("tower"), "tower: is missing")
	_expect("perk unknown tower", func(f: Dictionary) -> void: _card(f, "sharp_pebbles")["tower"] = "moat", "names no tower")
	_expect("name empty", func(f: Dictionary) -> void: _card(f, "spare_gate")["name"] = "", "name")
	_expect("name 25 characters", func(f: Dictionary) -> void: _card(f, "spare_gate")["name"] = "a".repeat(25), "name")
	_expect("name with a tab", func(f: Dictionary) -> void: _card(f, "spare_gate")["name"] = "Spare\tGate", "name")
	_expect("name not ASCII", func(f: Dictionary) -> void: _card(f, "spare_gate")["name"] = "Sp" + char(228) + "re", "name")
	_expect("text 81 characters", func(f: Dictionary) -> void: _card(f, "spare_gate")["text"] = "a".repeat(81), "text")
	_expect("text with a line break", func(f: Dictionary) -> void: _card(f, "spare_gate")["text"] = "one\ntwo", "text")
	_expect("once not a boolean", func(f: Dictionary) -> void: _card(f, "spare_gate")["once"] = 1, "once")
	_expect("unlock not an object", func(f: Dictionary) -> void: _card(f, "spare_gate")["unlock"] = [], "unlock")
	_expect("unlock only a counter", func(f: Dictionary) -> void: _card(f, "spare_gate")["unlock"] = {"counter": "stars"}, "at: is missing")
	_expect("unlock unknown counter", func(f: Dictionary) -> void: _card(f, "spare_gate")["unlock"] = {"counter": "luck", "at": 3}, "known counter")
	_expect("unlock at 0", func(f: Dictionary) -> void: _card(f, "spare_gate")["unlock"] = {"counter": "stars", "at": 0}, "unlock.at")
	_expect("unlock at past 1,000,000", func(f: Dictionary) -> void: _card(f, "spare_gate")["unlock"] = {"counter": "stars", "at": 1000001}, "unlock.at")
	_expect("unlock extra key", func(f: Dictionary) -> void: _card(f, "spare_gate")["unlock"] = {"counter": "stars", "at": 3, "x": 1}, "unknown key x")
	_expect("effects not a list", func(f: Dictionary) -> void: _card(f, "spare_gate")["effects"] = {}, "effects")
	_expect("effects unknown type", func(f: Dictionary) -> void: _card(f, "spare_gate")["effects"] = [{"type": "teleport"}], "known effect type")
	_expect("effect missing field", func(f: Dictionary) -> void: _card(f, "spare_gate")["effects"] = [{"type": "add_gates"}], "count: is missing")
	_expect("effect extra field", func(f: Dictionary) -> void: _card(f, "spare_gate")["effects"] = [{"type": "add_gates", "count": 1, "x": 2}], "unknown key x")
	_expect("effect fraction", func(f: Dictionary) -> void: _card(f, "spare_gate")["effects"] = [{"type": "add_gates", "count": 1.5}], "whole number")
	_expect("effect pct 0", func(f: Dictionary) -> void: _card(f, "gold_purse")["effects"] = [{"type": "bounty_pct", "pct": 0}], "pct")
	_expect("effect for a twist", func(f: Dictionary) -> void: _card(f, "spare_gate")["effects"] = [{"type": "no_selling"}], "not allowed for a card")
	_expect("effect for a risk in a gate card", func(f: Dictionary) -> void: _card(f, "spare_gate")["effects"] = [{"type": "reward_gold", "amount": 5}], "not allowed for a card")
	_expect("effect names no tower", func(f: Dictionary) -> void: _card(f, "sharp_pebbles")["effects"] = [{"type": "tower_add", "tower": "moat", "stat": "damage", "amount": 1}], "names no tower")
	_expect("too many cards", func(f: Dictionary) -> void: _too_many_cards(f), "cards")


func _too_many_cards(files: Dictionary) -> void:
	var list: Array = files["cards/cards.json"]["cards"]
	for i: int in 250:
		var extra: Dictionary = _card(files, "spare_gate").duplicate(true)
		extra["id"] = "extra_%d" % i
		list.append(extra)


func test_tower_cards_hostile() -> void:
	_expect("two effects", func(f: Dictionary) -> void: _card(f, "tower_bakery")["effects"].append({"type": "add_gates", "count": 1}), "exactly one add_tower")
	_expect("no effect", func(f: Dictionary) -> void: _card(f, "tower_bakery")["effects"] = [], "exactly one add_tower")
	_expect("wrong effect", func(f: Dictionary) -> void: _card(f, "tower_bakery")["effects"] = [{"type": "add_gates", "count": 1}], "exactly one add_tower")
	_expect("another tower", func(f: Dictionary) -> void: _card(f, "tower_bakery")["effects"] = [{"type": "add_tower", "tower": "lullaby_bell"}], "exactly one add_tower")
	_expect("a tower card for a start tower", func(f: Dictionary) -> void: f["cards/cards.json"]["cards"].append(Fx.tower_card("sling_post", "Sling Post")), "sling_post needs 0 tower card")
	_expect("a missing tower card", func(f: Dictionary) -> void: f["cards/cards.json"]["cards"].erase(_card(f, "tower_bakery")), "bakery needs 1 tower card, it has 0")
	_expect("two tower cards for one tower", func(f: Dictionary) -> void: _second_bakery_card(f), "bakery needs 1 tower card, it has 2")


func _second_bakery_card(files: Dictionary) -> void:
	var extra: Dictionary = Fx.tower_card("bakery", "Bakery")
	extra["id"] = "tower_bakery_two"
	files["cards/cards.json"]["cards"].append(extra)


func test_the_tower_card_rule_follows_the_run_plan() -> void:
	var files: Dictionary = Fx.files_from_json()
	files["runs/run.json"]["towers"] = ["sling_post", "bakery"]
	var found: String = "\n".join(RunData.check(files, catalog))
	assert_true(found.contains("bakery needs 0 tower card, it has 1"), found)
	files["cards/cards.json"]["cards"].erase(_card(files, "tower_bakery"))
	assert_eq(RunData.check(files, catalog), PackedStringArray(), "no card for a tower the run starts with")


func test_perk_cards_hostile() -> void:
	_expect("no effects", func(f: Dictionary) -> void: _card(f, "sharp_pebbles")["effects"] = [], "1 to 3 effects")
	_expect("four effects", func(f: Dictionary) -> void: _card(f, "sharp_pebbles")["effects"] = [_add("sling_post", "damage", 1), _add("sling_post", "damage", 1), _add("sling_post", "damage", 1), _add("sling_post", "damage", 1)], "1 to 3 effects")
	_expect("not a perk effect", func(f: Dictionary) -> void: _card(f, "sharp_pebbles")["effects"] = [{"type": "add_gold", "amount": 5, "per_wave": 0}], "not a perk effect")
	_expect("another tower", func(f: Dictionary) -> void: _card(f, "sharp_pebbles")["effects"] = [_add("bakery", "reach", 100)], "own tower")
	_expect("splash on a Bell", func(f: Dictionary) -> void: _card(f, "deep_lullaby")["effects"] = [_add("lullaby_bell", "splash", 10)], "has no splash")
	_expect("damage on a Bell", func(f: Dictionary) -> void: _card(f, "deep_lullaby")["effects"] = [_add("lullaby_bell", "damage", 10)], "has no damage")
	_expect("boost on a Sling Post", func(f: Dictionary) -> void: _card(f, "sharp_pebbles")["effects"] = [_add("sling_post", "boost_pct", 10)], "has no boost_pct")
	_expect("slow on a Sling Post", func(f: Dictionary) -> void: _card(f, "sharp_pebbles")["effects"] = [_add("sling_post", "slow_pct", 10)], "has no slow_pct")
	_expect("damage on a Bakery", func(f: Dictionary) -> void: _card(f, "warm_ovens")["effects"] = [_add("bakery", "damage", 1)], "has no damage")
	_expect("percent of reach", func(f: Dictionary) -> void: _card(f, "sharp_pebbles")["effects"] = [{"type": "tower_pct", "tower": "sling_post", "stat": "reach", "pct": 50}], "damage or reload_ms")
	_expect("percent of damage on a Bell", func(f: Dictionary) -> void: _card(f, "deep_lullaby")["effects"] = [{"type": "tower_pct", "tower": "lullaby_bell", "stat": "damage", "pct": 50}], "has no damage")
	_expect("hits air on a Bakery", func(f: Dictionary) -> void: _card(f, "warm_ovens")["effects"] = [{"type": "tower_hits_air", "tower": "bakery"}], "flyers")


func _add(tower: String, stat: String, amount: int) -> Dictionary:
	return {"type": "tower_add", "tower": tower, "stat": stat, "amount": amount}


func test_perk_stats_follow_the_tower_kind() -> void:
	var sling: TowerType = catalog.tower(&"sling_post")
	var catapult: TowerType = catalog.tower(&"pumpkin_catapult")
	var bell: TowerType = catalog.tower(&"lullaby_bell")
	var bakery: TowerType = catalog.tower(&"bakery")
	for stat: String in ["damage", "reload_ms", "splash", "targets", "reach"]:
		assert_true(RunCards.has_stat(sling, stat), "sling " + stat)
	assert_true(RunCards.has_stat(catapult, "slow_pct"), "the Jam Pot slows, so the Catapult has a slow")
	assert_false(RunCards.has_stat(sling, "slow_pct"), "no tier of the Sling Post slows")
	assert_true(RunCards.has_stat(bell, "slow_pct"))
	assert_true(RunCards.has_stat(bell, "reach"))
	for stat: String in ["damage", "reload_ms", "splash", "targets", "boost_pct", "boost_damage"]:
		assert_false(RunCards.has_stat(bell, stat), "bell " + stat)
	assert_true(RunCards.has_stat(bakery, "boost_pct"))
	assert_true(RunCards.has_stat(bakery, "boost_damage"))
	assert_true(RunCards.has_stat(bakery, "reach"))
	assert_false(RunCards.has_stat(bakery, "damage"))
	assert_false(RunCards.has_stat(sling, "armor"), "an unknown stat")


func test_a_perk_may_hold_up_to_three_effects() -> void:
	var files: Dictionary = Fx.files_from_json()
	_card(files, "sharp_pebbles")["effects"] = [_add("sling_post", "damage", 2), _add("sling_post", "reach", 50),
		{"type": "tower_pct", "tower": "sling_post", "stat": "reload_ms", "pct": 90}]
	assert_eq(RunData.check(files, catalog), PackedStringArray())
	_card(files, "deep_lullaby")["effects"] = [{"type": "tower_hits_air", "tower": "lullaby_bell"}]
	assert_eq(RunData.check(files, catalog), PackedStringArray(), "a Bell can be made to slow flyers")


func test_gate_economy_and_risk_cards_hostile() -> void:
	_expect("gate card without add_gates", func(f: Dictionary) -> void: _card(f, "spare_gate")["effects"] = [{"type": "gates_stay"}], "one add_gates")
	_expect("gate card with two add_gates", func(f: Dictionary) -> void: _card(f, "spare_gate")["effects"] = [{"type": "add_gates", "count": 1}, {"type": "add_gates", "count": 1}], "one add_gates")
	_expect("gate card with another effect", func(f: Dictionary) -> void: _card(f, "spare_gate")["effects"] = [{"type": "add_gates", "count": 1}, {"type": "add_lives", "amount": 1}], "one add_gates")
	_expect("gate card with two gates_stay", func(f: Dictionary) -> void: _card(f, "spare_gate")["effects"] = [{"type": "add_gates", "count": 1}, {"type": "gates_stay"}, {"type": "gates_stay"}], "one add_gates")
	_expect("economy with no effect", func(f: Dictionary) -> void: _card(f, "gold_purse")["effects"] = [], "1 to 3 effects")
	_expect("economy with four effects", func(f: Dictionary) -> void: _card(f, "gold_purse")["effects"] = [_gold(), _gold(), _gold(), _gold()], "1 to 3 effects")
	_expect("economy with a gate effect", func(f: Dictionary) -> void: _card(f, "gold_purse")["effects"] = [{"type": "add_gates", "count": 1}], "not an economy effect")
	_expect("economy with a perk effect", func(f: Dictionary) -> void: _card(f, "gold_purse")["effects"] = [_add("sling_post", "damage", 1)], "not an economy effect")
	_expect("risk without a reward", func(f: Dictionary) -> void: _card(f, "crowded_night")["effects"].pop_back(), "exactly one reward_gold")
	_expect("risk with two rewards", func(f: Dictionary) -> void: _card(f, "crowded_night")["effects"].append({"type": "reward_gold", "amount": 5}), "exactly one reward_gold")
	_expect("risk with only a reward", func(f: Dictionary) -> void: _card(f, "crowded_night")["effects"] = [{"type": "reward_gold", "amount": 5}], "1 to 3 effects besides")
	_expect("risk with five effects", func(f: Dictionary) -> void: _card(f, "crowded_night")["effects"] = [{"type": "gates_open"}, {"type": "gates_open"}, {"type": "gates_open"}, {"type": "gates_open"}, {"type": "reward_gold", "amount": 5}], "1 to 3 effects besides")
	_expect("risk group from entrance 2", func(f: Dictionary) -> void: _card(f, "flock")["effects"][0]["entrance"] = 2, "entrance")
	_expect("risk with a card effect", func(f: Dictionary) -> void: _card(f, "crowded_night")["effects"][0] = {"type": "add_lives", "amount": 5}, "not allowed for a risk")
	_expect("risk with last_wave", func(f: Dictionary) -> void: _card(f, "crowded_night")["effects"][0]["last_wave"] = true, "for Twists only")
	_expect("risk group at a bad time", func(f: Dictionary) -> void: _card(f, "flock")["effects"][0]["at_ms"] = 2025, "multiple of 50")
	_expect("risk group count 0", func(f: Dictionary) -> void: _card(f, "flock")["effects"][0]["count"] = 0, "count")


func _gold() -> Dictionary:
	return {"type": "add_gold", "amount": 1, "per_wave": 0}


func test_every_economy_effect_is_allowed_and_a_gate_card_may_keep_gates() -> void:
	var files: Dictionary = Fx.files_from_json()
	_card(files, "gold_purse")["effects"] = [
		{"type": "add_lives", "amount": 5}, {"type": "refund_pct", "pct": 90},
		{"type": "cost_add", "build": 20, "upgrade": -20},
	]
	assert_eq(RunData.check(files, catalog), PackedStringArray())
	_card(files, "gold_purse")["effects"] = [{"type": "bounty_pct", "pct": 120}, {"type": "clear_bonus_pct", "pct": 150}, {"type": "interest", "pct": 10, "max": 50}]
	assert_eq(RunData.check(files, catalog), PackedStringArray())
	_card(files, "spare_gate")["effects"] = [{"type": "add_gates", "count": 2}, {"type": "gates_stay"}]
	assert_eq(RunData.check(files, catalog), PackedStringArray())


## 2.8: a negative gain is refused when the card loads, not counted as 0.
func test_a_negative_gain_in_a_card_is_refused_when_run_data_loads() -> void:
	_expect("add_gold amount -1", func(f: Dictionary) -> void: _card(f, "gold_purse")["effects"] = [{"type": "add_gold", "amount": -1, "per_wave": 0}], "amount")
	_expect("add_gold per_wave -1", func(f: Dictionary) -> void: _card(f, "gold_purse")["effects"] = [{"type": "add_gold", "amount": 100, "per_wave": -1}], "per_wave")
	_expect("add_lives amount -1", func(f: Dictionary) -> void: _card(f, "gold_purse")["effects"] = [{"type": "add_lives", "amount": -1}], "amount")
	_expect("interest max -1", func(f: Dictionary) -> void: _card(f, "gold_purse")["effects"] = [{"type": "interest", "pct": 10, "max": -1}], "max")
	_expect("reward_gold amount -1", func(f: Dictionary) -> void: _card(f, "crowded_night")["effects"][1]["amount"] = -1, "amount")
	var files: Dictionary = Fx.files_from_json()
	_card(files, "gold_purse")["effects"] = [{"type": "add_gold", "amount": 0, "per_wave": 0}]
	assert_eq(RunData.check(files, catalog), PackedStringArray(), "zero is still a whole number from 0 to 1,000")
